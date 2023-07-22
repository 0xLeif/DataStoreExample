//
//  ContentView.swift
//  DataStoreExample
//
//  Created by Leif on 7/22/23.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var viewModel: ContentViewModel

    init(postLoader: PostLoader = PostLoader()) {
        _viewModel = ObservedObject(wrappedValue: ContentViewModel(postLoader: postLoader))
    }

    var body: some View {
        ZStack {
            List(viewModel.posts) { post in
                Text(post.title)
            }

            if viewModel.isLoading {
                ProgressView()
            }
        }
        .onAppear(perform: viewModel.load)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(postLoader: MockPostLoader())
    }
}
