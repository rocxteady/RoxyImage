//
//  File.swift
//  RoxyImage
//
//  Created by Ulaş Sancak on 7.11.2024.
//

import SwiftUI

public enum ImageState {
    case loading
    case loaded(Image?, URL?)
    case failed(Error)

    var image: Image? {
        if case .loaded(let image, _) = self {
            return image
        }
        return nil
    }
}
