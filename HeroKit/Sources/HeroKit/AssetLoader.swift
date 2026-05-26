import SwiftUI

/// Loads named .png images from the app bundle.
/// Falls back to a tinted circle so nothing is ever blank.
public struct AssetLoader {
    public static func emblem(_ name: String, fallbackColor: Color = .green) -> Image {
        // Check if a .png asset exists in the bundle (drop-in replacement)
        if Bundle.main.url(forResource: name, withExtension: "png") != nil {
            return Image(name)
        }
        return Image(systemName: "circle.fill")
    }
}
