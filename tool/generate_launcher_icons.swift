import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent()
let sourceURL = root.appendingPathComponent("assets/branding/app_icon.png")
guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    fatalError("Cannot load \(sourceURL.path)")
}

func writeIcon(size: Int, to destination: URL) throws {
    guard let context = CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else {
        fatalError("Cannot create \(size)-pixel icon")
    }
    context.interpolationQuality = .high
    let bounds = CGRect(x: 0, y: 0, width: size, height: size)
    context.setFillColor(CGColor(gray: 1, alpha: 1))
    context.fill(bounds)
    context.draw(image, in: bounds)
    guard let output = context.makeImage(),
          let encoder = CGImageDestinationCreateWithURL(
              destination as CFURL, UTType.png.identifier as CFString, 1, nil
          ) else {
        fatalError("Cannot encode \(destination.path)")
    }
    CGImageDestinationAddImage(encoder, output, nil)
    guard CGImageDestinationFinalize(encoder) else {
        fatalError("Cannot write \(destination.path)")
    }
}

let catalog = root.appendingPathComponent("ios/Runner/Assets.xcassets/AppIcon.appiconset")
let manifest = try JSONDecoder().decode(
    IconCatalog.self, from: Data(contentsOf: catalog.appendingPathComponent("Contents.json"))
)
var written = Set<String>()
for icon in manifest.images where written.insert(icon.filename).inserted {
    guard let points = Double(icon.size.components(separatedBy: "x")[0]),
          let scale = Double(icon.scale.replacingOccurrences(of: "x", with: "")) else {
        fatalError("Invalid size or scale for \(icon.filename)")
    }
    try writeIcon(size: Int((points * scale).rounded()),
                  to: catalog.appendingPathComponent(icon.filename))
}
for (density, size) in [
    ("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192),
] {
    try writeIcon(size: size, to: root.appendingPathComponent(
        "android/app/src/main/res/mipmap-\(density)/ic_launcher.png"
    ))
}
print("Generated \(written.count) iOS icons and 5 Android icons.")

struct IconCatalog: Decodable {
    let images: [Icon]
    struct Icon: Decodable {
        let filename: String
        let size: String
        let scale: String
    }
}
