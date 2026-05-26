import SwiftUI

/// Canvas placeholder emblem — replaced when a real .png is dropped in.
/// Usage: EmblemView(name: "heatblast", size: 60, color: .orange)
public struct EmblemView: View {
    public let name: String
    public var size: CGFloat = 60
    public var color: Color = .green

    public init(name: String, size: CGFloat = 60, color: Color = .green) {
        self.name = name
        self.size = size
        self.color = color
    }

    public var body: some View {
        let asset = AssetLoader.emblem(name)
        // If it resolved to a named image (not systemName), show it
        asset
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .foregroundColor(color)
    }
}
