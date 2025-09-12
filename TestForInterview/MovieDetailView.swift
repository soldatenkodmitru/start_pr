//
//  Untitled.swift
//  TestForInterview
//
//  Created by Dmytro Soldatenko on 10.09.2025.
//

import SwiftUI
import SDWebImageSwiftUI

struct MovieDetailView: View {
    let movie: MovieListItem
    @State private var isFavorite = false
    private let viewModel = MovieListViewModel.shared

    var body: some View {
        VStack(spacing: 20) {
            ZStack(alignment: .topTrailing) {
                WebImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(movie.poster_path)"))
                    .resizable()
                    .indicator(.activity)
                     .transition(.fade(duration: 0.5))
                     .scaledToFit()
                     .frame(maxHeight: 400)
                     .cornerRadius(16)
                     .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)

                Button(action: toggleFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundColor(isFavorite ? .red : .white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.7))
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding()
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            
            Text(movie.original_title)
                .font(.title)
                .bold()
                .padding(.horizontal)
            
            Text(movie.overview)
                .font(.body)
                .padding(.horizontal)
            
            
            Text("Release Date: \(movie.release_date)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .navigationBarTitle("Details", displayMode: .inline)
    }
    
    private func toggleFavorite() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Toggle state with animation
        withAnimation(.easeInOut(duration: 0.2)) {
            isFavorite.toggle()
        }
        
        // Update the view model
        var updatedMovie = movie
        updatedMovie.isFavorite = isFavorite
        viewModel.updateMovieWithFavoriteStatus(updatedMovie)
    }
}
