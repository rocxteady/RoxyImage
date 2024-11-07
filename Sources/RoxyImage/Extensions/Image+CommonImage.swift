//
//  File.swift
//  RoxyImage
//
//  Created by Ulaş Sancak on 6.11.2024.
//

import SwiftUI

extension Image {
    init(commonImage: MyImage) {
        #if os(macOS)
        self.init(nsImage: commonImage)
        #else
        self.init(uiImage: commonImage)
        #endif
    }
}

