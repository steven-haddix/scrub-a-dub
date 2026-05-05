import AppKit
import SwiftUI

struct MenuBarIcon: View {
    var size: CGFloat = 22

    var body: some View {
        if let image = Self.makeTemplate(size: size) {
            Image(nsImage: image)
        } else {
            Text("🦆")
        }
    }

    private static func makeTemplate(size: CGFloat) -> NSImage? {
        guard
            let url = Self.duckImageURL,
            let original = NSImage(contentsOf: url),
            let mask = Self.makeAlphaMask(from: original)
        else { return nil }

        let target = NSSize(width: size, height: size)
        let resized = NSImage(size: target, flipped: false) { rect in
            let sourceRect = NSRect(origin: .zero, size: mask.size)
            let scale = min(rect.width / mask.size.width, rect.height / mask.size.height)
            let drawSize = NSSize(width: mask.size.width * scale, height: mask.size.height * scale)
            let drawRect = NSRect(
                x: rect.midX - drawSize.width / 2,
                y: rect.midY - drawSize.height / 2,
                width: drawSize.width,
                height: drawSize.height
            )

            mask.draw(
                in: drawRect,
                from: sourceRect,
                operation: .sourceOver,
                fraction: 1.0,
                respectFlipped: true,
                hints: [.interpolation: NSImageInterpolation.high.rawValue]
            )
            return true
        }
        resized.isTemplate = true
        return resized
    }

    private static var duckImageURL: URL? {
        Bundle.main.url(forResource: "Duck", withExtension: "png")
            ?? Bundle.module.url(forResource: "Duck", withExtension: "png")
    }

    private static func makeAlphaMask(from image: NSImage) -> NSImage? {
        var proposedRect = NSRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
            return nil
        }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue

        var sourcePixels = [UInt8](repeating: 0, count: height * bytesPerRow)
        guard let context = CGContext(
            data: &sourcePixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Menu bar template images use alpha as their shape; the bundled duck currently has an opaque checkerboard.
        let hasUsableAlpha = stride(from: 3, to: sourcePixels.count, by: bytesPerPixel)
            .contains { sourcePixels[$0] < 250 }
        let threshold = hasUsableAlpha ? 0 : Self.backgroundLuminanceThreshold(
            in: sourcePixels,
            width: width,
            height: height,
            bytesPerRow: bytesPerRow
        )

        var maskPixels = [UInt8](repeating: 0, count: sourcePixels.count)
        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0

        for y in 0..<height {
            for x in 0..<width {
                let index = y * bytesPerRow + x * bytesPerPixel
                let alpha: UInt8

                if hasUsableAlpha {
                    alpha = sourcePixels[index + 3]
                } else {
                    let luminance = Self.luminance(
                        red: sourcePixels[index],
                        green: sourcePixels[index + 1],
                        blue: sourcePixels[index + 2]
                    )
                    let denominator = max(1, 255 - threshold)
                    let opacity = max(0, min(255, (luminance - threshold) * 255 / denominator))
                    alpha = UInt8(opacity)
                }

                maskPixels[index] = alpha
                maskPixels[index + 1] = alpha
                maskPixels[index + 2] = alpha
                maskPixels[index + 3] = alpha

                if alpha > 8 {
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }

        guard minX <= maxX, minY <= maxY else { return nil }

        let padding = max(2, min(width, height) / 80)
        minX = max(0, minX - padding)
        minY = max(0, minY - padding)
        maxX = min(width - 1, maxX + padding)
        maxY = min(height - 1, maxY + padding)

        return Self.makeImage(
            from: maskPixels,
            sourceBytesPerRow: bytesPerRow,
            crop: CGRect(
                x: CGFloat(minX),
                y: CGFloat(minY),
                width: CGFloat(maxX - minX + 1),
                height: CGFloat(maxY - minY + 1)
            ),
            colorSpace: colorSpace,
            bitmapInfo: bitmapInfo
        )
    }

    private static func makeImage(
        from pixels: [UInt8],
        sourceBytesPerRow: Int,
        crop: CGRect,
        colorSpace: CGColorSpace,
        bitmapInfo: UInt32
    ) -> NSImage? {
        let bytesPerPixel = 4
        let cropX = Int(crop.origin.x)
        let cropY = Int(crop.origin.y)
        let cropWidth = Int(crop.width)
        let cropHeight = Int(crop.height)
        let cropBytesPerRow = cropWidth * bytesPerPixel
        var croppedPixels = [UInt8](repeating: 0, count: cropHeight * cropBytesPerRow)

        for row in 0..<cropHeight {
            let sourceStart = (cropY + row) * sourceBytesPerRow + cropX * bytesPerPixel
            let sourceEnd = sourceStart + cropBytesPerRow
            let targetStart = row * cropBytesPerRow
            croppedPixels[targetStart..<(targetStart + cropBytesPerRow)] = pixels[sourceStart..<sourceEnd]
        }

        let data = Data(croppedPixels)
        guard
            let provider = CGDataProvider(data: data as CFData),
            let image = CGImage(
                width: cropWidth,
                height: cropHeight,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: cropBytesPerRow,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
            )
        else {
            return nil
        }

        let nsImage = NSImage(cgImage: image, size: NSSize(width: cropWidth, height: cropHeight))
        nsImage.isTemplate = true
        return nsImage
    }

    private static func backgroundLuminanceThreshold(
        in pixels: [UInt8],
        width: Int,
        height: Int,
        bytesPerRow: Int
    ) -> Int {
        let sampleSize = max(8, min(width, height) / 10)
        let bytesPerPixel = 4
        var samples: [Int] = []
        samples.reserveCapacity(sampleSize * sampleSize * 4)

        for yRange in [0..<sampleSize, (height - sampleSize)..<height] {
            for xRange in [0..<sampleSize, (width - sampleSize)..<width] {
                for y in yRange {
                    for x in xRange {
                        let index = y * bytesPerRow + x * bytesPerPixel
                        samples.append(Self.luminance(
                            red: pixels[index],
                            green: pixels[index + 1],
                            blue: pixels[index + 2]
                        ))
                    }
                }
            }
        }

        samples.sort()
        let percentileIndex = min(samples.count - 1, Int(Double(samples.count - 1) * 0.95))
        return min(252, samples[percentileIndex] + 10)
    }

    private static func luminance(red: UInt8, green: UInt8, blue: UInt8) -> Int {
        (Int(red) * 299 + Int(green) * 587 + Int(blue) * 114) / 1000
    }
}
