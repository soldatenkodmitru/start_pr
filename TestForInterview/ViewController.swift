//
//  ViewController.swift
//  TestForInterview
//
//  Created by Sam Titovskyi on 18.08.2025.
//

import UIKit
import SwiftUI

// MARK: - Favorites Persistence
final class FavoritesStore {
    private let key = "favorite_movie_ids"
    private let defaults = UserDefaults.standard

    func load() -> Set<Int> {
        let ids = defaults.array(forKey: key) as? [Int] ?? []
        return Set(ids)
    }

    func save(_ ids: Set<Int>) {
        defaults.set(Array(ids), forKey: key)
    }
}

// MARK: - ViewModel (MVVM)
final class MovieListViewModel {
    static let shared = MovieListViewModel()
    private let movieManager = MovieManager()

    // Pagination & concurrency state
    private var currentPage: Int = 1
    private var totalPages: Int? = nil
    private var isLoading: Bool = false
    private var inFlightPages: Set<Int> = []
    private let resultsLock = NSLock()
    private let concurrentQueue = DispatchQueue(label: "MovieListViewModel.fetch.queue", attributes: .concurrent)

    // Expose read-only list to the ViewController
    private(set) var movies: [MovieListItem] = [] { didSet { onUpdate?() } }

    private let favoritesStore = FavoritesStore()
    private(set) var favoriteIds: Set<Int>

    init() {
        self.favoriteIds = favoritesStore.load()
    }

    
    // Bindable callback for the View (ViewController)
    var onUpdate: (() -> Void)?
    
    func isFavorite(_ movie: MovieListItem) -> Bool {
        return favoriteIds.contains(movie.id)
    }

    func toggleFavorite(_ movie: MovieListItem) {
        if favoriteIds.contains(movie.id) {
            favoriteIds.remove(movie.id)
        } else {
            favoriteIds.insert(movie.id)
        }
        favoritesStore.save(favoriteIds)
        onUpdate?()
    }


    func fetchPopularMovies(reset: Bool = false) {
        if reset {
            currentPage = 1
            totalPages = nil
            movies.removeAll()
            inFlightPages.removeAll()
            isLoading = false
        }
        scheduleNextBatch()
    }
    
    private func scheduleNextBatch(batchSize: Int = 2) {
        guard !isLoading else { return }

        // Compute which pages to request next
        var pagesToLoad: [Int] = []
        for offset in 0..<batchSize {
            let p = currentPage + offset
            if let tp = totalPages, p > tp { break }
            if inFlightPages.contains(p) { continue }
            pagesToLoad.append(p)
        }
        guard !pagesToLoad.isEmpty else { return }

        isLoading = true
        pagesToLoad.forEach { inFlightPages.insert($0) }

        let group = DispatchGroup()
        var collected: [(page: Int, items: [MovieListItem], total: Int?)] = []

        for page in pagesToLoad {
            group.enter()
            movieManager.fetchMovies(page: page) { [weak self] response in
                // Try to read `page` and `total_pages` if present in the decoded model
                let total = response.total_pages
                let pageValue = response.page

                self?.resultsLock.lock()
                collected.append((page: pageValue, items: response.results, total: total))
                self?.resultsLock.unlock()

                self?.concurrentQueue.async(flags: .barrier) {
                    self?.inFlightPages.remove(page)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.isLoading = false

            if self.totalPages == nil, let tp = collected.compactMap({ $0.total }).first {
                self.totalPages = tp
            }

            // Merge in ascending page order
            collected.sort { $0.page < $1.page }
            let newItems = collected.flatMap { $0.items }
            if self.movies.isEmpty && self.currentPage == 1 {
                self.movies = newItems
            } else {
                self.movies.append(contentsOf: newItems)
                self.onUpdate?()
            }

            self.currentPage += pagesToLoad.count
        }
    }
    
    func loadNextPagesIfNeeded(currentIndex: Int) {
        // When within last 5 items, trigger next 2 pages concurrently
        let threshold = max(0, movies.count - 5)
        if currentIndex >= threshold {
            scheduleNextBatch()
        }
    }

    func search(query: String) {
        movieManager.searchMovies(query: query) { [weak self] (moviesResponse) in
            DispatchQueue.main.async {
                self?.movies = moviesResponse.results
            }
        }
    }

    func movie(at index: Int) -> MovieListItem { movies[index] }
    var count: Int { movies.count }
}

fileprivate let kDefaultCellId = "MovieCellId"

class ViewController: UIViewController {

    // MARK: - IBOutlets
    
    @IBOutlet private weak var collectionView: UICollectionView!
    
    // Center loader for initial load
    private let loadingIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .large)
        v.hidesWhenStopped = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let viewModel = MovieListViewModel.shared

    // Pull to Refresh
    private lazy var refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return rc
    }()
    
    // MARK: - Search
    private let searchController = UISearchController(searchResultsController: nil)
    private var searchDebounceTimer: Timer?
    private var isSearchVisible = false
    
    // MARK: - Filtering (All / Favorites)
    public enum FilterMode { case all, favorites }
    private var filterMode: FilterMode = .all
    private lazy var filterButton: UIBarButtonItem = {
        let btn = UIBarButtonItem(title: "All", style: .plain, target: self, action: #selector(toggleFilter))
        return btn
    }()

    private var currentMovies: [MovieListItem] {
        switch filterMode {
        case .all:
            return viewModel.movies
        case .favorites:
            return viewModel.movies.filter { viewModel.isFavorite($0) }
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        navigationItem.title = "Average rating: —"
        
        // MVVM: bind updates and fetch
        viewModel.onUpdate = { [weak self] in
            self?.collectionView.reloadData()
            self?.refreshControl.endRefreshing()
            self?.updateAverageTitle()
            self?.setLoading(false)
        }
        setLoading(true)
        viewModel.fetchPopularMovies()
        
        let themeButton = UIBarButtonItem(
            image: UIImage(systemName: ThemeManager.current == .dark ? "sun.max.fill" : "moon.fill"),
            style: .plain,
            target: self,
            action: #selector(toggleTheme)
        )
        let searchButton = UIBarButtonItem(
            image: UIImage(systemName: "magnifyingglass"),
            style: .plain,
            target: self,
            action: #selector(toggleSearchBar)
        )
        navigationItem.rightBarButtonItems = [themeButton, filterButton, searchButton]
        
        // Search Controller
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search movies (minimum 3 symbols)"
        navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true

        title = "Movies"
        tabBarItem = UITabBarItem(title: "Movies", image: UIImage(systemName: "film"), selectedImage: UIImage(systemName: "film.fill"))
        
        if let tbc = self.tabBarController {
            // Append Favorites tab if it's not already present
            let alreadyHasFavorites = (tbc.viewControllers ?? []).contains { vc in
                if let nav = vc as? UINavigationController {
                    return nav.topViewController is FavoritesViewController
                }
                return vc is FavoritesViewController
            }
            if !alreadyHasFavorites {
                let favVC = FavoritesViewController()
                favVC.title = "Favorites"
                favVC.tabBarItem = UITabBarItem(title: "Favorites", image: UIImage(systemName: "star"), selectedImage: UIImage(systemName: "star.fill"))
                let favNav = UINavigationController(rootViewController: favVC)
                var vcs = tbc.viewControllers ?? []
                vcs.append(favNav)
                tbc.setViewControllers(vcs, animated: false)
            }
        }
    }

    // MARK: - UI Setup
    
    private func setupUI() {
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        collectionView.refreshControl = refreshControl
     
        collectionView.reloadData()
    }

    @objc private func handleRefresh() {
        viewModel.fetchPopularMovies(reset: true)
    }
    
    @objc private func toggleTheme() {
           // Compute the next theme
           let next: ThemeSetting = (ThemeManager.current == .dark) ? .light : .dark

           // Persist + apply immediately
           ThemeManager.set(next, for: ThemeManager.keyWindow)

           // Update button icon to reflect new state
           navigationItem.rightBarButtonItem?.image = UIImage(
               systemName: next == .dark ? "sun.max.fill" : "moon.fill"
           )
       }
    
    @objc private func toggleFilter() {
        filterMode = (filterMode == .all) ? .favorites : .all
        filterButton.title = (filterMode == .all) ? "All" : "Favs"
        collectionView.reloadData()
    }
    
    @objc private func toggleSearchBar() {
        isSearchVisible.toggle()
        if isSearchVisible {
            // Attach to nav bar and show immediately
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.searchController.isActive = true
                self.searchController.searchBar.becomeFirstResponder()
            }
        } else {
            // Deactivate and remove
            searchController.isActive = false
            searchController.searchBar.resignFirstResponder()
            navigationItem.searchController = nil
        }
    }

    func applyFilterMode(_ mode: FilterMode) {
        filterMode = mode
        filterButton.title = (mode == .all) ? "All" : "Favs"
        collectionView?.reloadData()
    }

    private func updateAverageTitle() {
        let ratings = viewModel.movies.map { $0.vote_average }
        let avg = ratings.isEmpty ? 0.0 : (ratings.reduce(0.0, +) / Double(ratings.count))
        navigationItem.title = String(format: "Average rating: ⭐ %.1f", avg)
    }
    
    private func setLoading(_ loading: Bool) {
        if loading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 5
        let availableWidth = collectionView.bounds.width - padding * 4
        let width = availableWidth / 2
        return CGSize(width: width, height: width * 1.8)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top:5, left: 5, bottom: 5, right: 5)
    }
}

// MARK: - UICollectionViewDataSource


extension ViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCellId", for: indexPath) as? MovieCell else {
            return UICollectionViewCell()
        }
        
        let movieItem = viewModel.movie(at: indexPath.row)
        cell.configure(with: movieItem)
        
        return cell
    }


    
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let movie = currentMovies[indexPath.row]
        let isFav = viewModel.isFavorite(movie)
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let title = isFav ? "Remove from Favorites" : "Add to Favorites"
            let imageName = isFav ? "star.slash" : "star"
            let toggle = UIAction(title: title, image: UIImage(systemName: imageName)) { [weak self] _ in
                self?.viewModel.toggleFavorite(movie)
            }
            return UIMenu(title: "", children: [toggle])
        }
    }
    
}

// MARK: - UICollectionViewDelegate

extension ViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let selectedMovie = currentMovies[indexPath.row]
        
        let detailView = MovieDetailView(movie: selectedMovie)
        let controller = UIHostingController(rootView: detailView)
        
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Only prefetch when showing the full catalog (not filtered favorites or active )
        let isShowingAll = (filterMode == .all)
        let isSearching = !(searchController.searchBar.text?.isEmpty ?? true)
        if isShowingAll && !isSearching {
            viewModel.loadNextPagesIfNeeded(currentIndex: indexPath.row)
        }
    }
}

// MARK: - UISearchResultsUpdating & UISearchBarDelegate
extension ViewController: UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        let text = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        searchDebounceTimer?.invalidate()
        if text.count >= 3 {
            searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                self?.viewModel.search(query: text)
            }
        } else if text.isEmpty {
            viewModel.fetchPopularMovies()
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        viewModel.fetchPopularMovies()
        isSearchVisible = false
            UIView.animate(withDuration: 0.25) { [weak self] in
                guard let self = self else { return }
                self.navigationItem.searchController = nil
                self.view.layoutIfNeeded()
            }
    }
}


// MARK: - Favorites as Collection (inherits ViewController)
final class FavoritesViewController: ViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Favorites"
        applyFilterMode(.favorites)
    }
}

    
