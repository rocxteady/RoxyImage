//
//  RoxyImage.swift
//  PressReader
//
//  Created by Ulaş Sancak on 8.07.2024.
//

import SwiftUI

@MainActor
public struct RoxyImage<Content: View>: View {
    private let imageLoader = ImageLoader.shared
    private let url: URL?
    private let state: ((ImageState) -> Content)?
    @State private var currentState: ImageState = .loading

    public init(url: URL?, @ViewBuilder state: @escaping (ImageState) -> Content) {
        self.url = url
        self.state = state
    }

    public init(url: URL?) where Content == EmptyView {
        self.url = url
        self.state = nil
    }

    public var body: some View {
        ZStack {
            content
        }
        .task {
            if case .loaded(let image, let url) = currentState {
                if self.url == url && image != nil {
                    return
                }
            }
            do {
                if let url,
                   let image = try await imageLoader.load(url: url) {
                    Task { @MainActor in
                        currentState = .loaded(Image(commonImage: image), url)
                    }
                } else {
                    currentState = .loaded(nil, url)
                }
            } catch {
                currentState = .failed(error)
            }
        }
        .onDisappear {
            guard let url else { return }
            Task {
                await imageLoader.cancel(url: url)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let state {
            state(currentState)
        } else {
            switch currentState {
            case .loaded(let image, _):
                image
            default:
                EmptyView()
            }
        }
    }
}

#if DEBUG
#Preview {
    RoxyImage(
        url: URL(string: "https://fastly.picsum.photos/id/212/200/200.jpg?hmac=U4JUx4PJyTuKdZEPAk2Cw01YZM8rOypF8fTTO39POko")!,
        state: {
            switch $0 {
            case .loaded(let image, _):
                if let image {
                    image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                } else {
                    EmptyView()
                }
            default:
                EmptyView()
            }
        }
    )
    .frame(height: 100)
}
#endif
