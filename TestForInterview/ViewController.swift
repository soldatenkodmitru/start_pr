//
//  ViewController.swift
//  TestForInterview
//
//  Created by Sam Titovskyi on 18.08.2025.
//

import UIKit
import SwiftUI

// MARK: - ViewModel (MVVM)
final class MovieListViewModel {
    private let movieManager = MovieManager()

    // Expose read-only list to the ViewController
    private(set) var movies: [Movies] = [] { didSet { onUpdate?() } }

    // Bindable callback for the View (ViewController)
    var onUpdate: (() -> Void)?

    func fetchPopularMovies() {
        movieManager.fetchMovies { [weak self] (moviesResponse) in
            DispatchQueue.main.async {
                self?.movies = moviesResponse.results
            }
        }
    }

    func movie(at index: Int) -> Movies { movies[index] }
    var count: Int { movies.count }
}

fileprivate let kDefaultCellId = "MovieCellId"

class ViewController: UIViewController {

    // MARK: - IBOutlets
    
    @IBOutlet private weak var collectionView: UICollectionView!
    
    private let viewModel = MovieListViewModel()

    // Pull to Refresh
    private lazy var refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return rc
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        // MVVM: bind updates and fetch
        viewModel.onUpdate = { [weak self] in
            self?.collectionView.reloadData()
            self?.refreshControl.endRefreshing()
        }
        viewModel.fetchPopularMovies()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
                    image: UIImage(systemName: ThemeManager.current == .dark ? "sun.max.fill" : "moon.fill"),
                    style: .plain,
                    target: self,
                    action: #selector(toggleTheme)
                )
    }

    // MARK: - UI Setup
    
    private func setupUI() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.refreshControl = refreshControl
     
        collectionView.reloadData()
    }

    @objc private func handleRefresh() {
        viewModel.fetchPopularMovies()
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

}

// MARK: - UICollectionViewDataSource

extension ViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kDefaultCellId, for: indexPath) as! MovieCell
        
        cell.backgroundColor = indexPath.item % 2 == 0 ? .lightGray : .red.withAlphaComponent(0.3)
        
        let movie = viewModel.movie(at: indexPath.row)
        cell.movieTitleLabel.text = "\(movie.original_title)"
    
        
        return cell
    }
    
}

// MARK: - UICollectionViewDelegate

extension ViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let selectedMovie = viewModel.movie(at: indexPath.row)
        
        let detailView = MovieDetailView(movie: selectedMovie)
        let controller = UIHostingController(rootView: detailView)
        
        navigationController?.pushViewController(controller, animated: true)
    }
    
}
