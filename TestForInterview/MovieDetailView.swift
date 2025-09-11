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

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                WebImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(movie.poster_path)"))
                    .resizable()
                    .indicator(.activity) // activity indicator while loading
                    .scaledToFit()
                    .cornerRadius(10)

                Text(movie.original_title)
                    .font(.title)
                    .bold()
                    .padding(.horizontal)

                Text(movie.overview)
                    .font(.body)
                    .padding(.horizontal)
            }
        }
        .navigationBarTitle("Details", displayMode: .inline)
    }
}
