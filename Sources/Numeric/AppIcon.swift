import SwiftUI
import AppKit
import CoreGraphics

public enum AppIcon {
    /// Exact vector artwork from `icon.svg` (`viewBox="0 0 480 480"`).
    public static let iconSVG = """
    <svg width="480" height="480" viewBox="0 0 480 480" fill="none" xmlns="http://www.w3.org/2000/svg">
    <g clip-path="url(#clip0_1_3)">
    <rect width="480" height="480" fill="white"/>
    <rect width="480" height="240" fill="#432B7A"/>
    <rect y="240" width="240" height="240" fill="#F85ACB"/>
    <rect x="240" y="240" width="240" height="240" fill="#6441B3"/>
    <path d="M331.784 165L368.264 97.288C368.691 96.52 368.904 95.88 368.904 95.368C368.904 94.9413 368.733 94.5573 368.392 94.216C368.051 93.8747 367.581 93.704 366.984 93.704H328.2V75.4H371.592C375.091 75.4 378.248 76.2107 381.064 77.832C383.88 79.4533 386.141 81.5867 387.848 84.232C389.555 86.8773 390.408 89.8213 390.408 93.064C390.408 94.856 390.195 96.648 389.768 98.44C389.341 100.147 388.744 101.725 387.976 103.176L355.208 165H331.784Z" fill="white"/>
    <path d="M110.776 390.024V368.52H88.888V351.88H110.776V330.376H128.696V351.88H150.584V368.52H128.696V390.024H110.776Z" fill="white"/>
    <path d="M328.888 352.776V336.008H390.584V352.776H328.888ZM328.888 384.392V367.624H390.584V384.392H328.888Z" fill="white"/>
    </g>
    <defs>
    <clipPath id="clip0_1_3">
    <rect width="480" height="480" fill="white"/>
    </clipPath>
    </defs>
    </svg>
    """

    public static let sevenPathD = "M331.784 165L368.264 97.288C368.691 96.52 368.904 95.88 368.904 95.368C368.904 94.9413 368.733 94.5573 368.392 94.216C368.051 93.8747 367.581 93.704 366.984 93.704H328.2V75.4H371.592C375.091 75.4 378.248 76.2107 381.064 77.832C383.88 79.4533 386.141 81.5867 387.848 84.232C389.555 86.8773 390.408 89.8213 390.408 93.064C390.408 94.856 390.195 96.648 389.768 98.44C389.341 100.147 388.744 101.725 387.976 103.176L355.208 165H331.784Z"
    public static let plusPathD = "M110.776 390.024V368.52H88.888V351.88H110.776V330.376H128.696V351.88H150.584V368.52H128.696V390.024H110.776Z"
    public static let equalsPathD = "M328.888 352.776V336.008H390.584V352.776H328.888ZM328.888 384.392V367.624H390.584V384.392H328.888Z"

    public static func renderPNGData(pixelSize: Int) -> Data? {
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(
                  data: nil,
                  width: pixelSize,
                  height: pixelSize,
                  bitsPerComponent: 8,
                  bytesPerRow: 0,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return nil
        }

        draw(in: ctx, pixelSize: pixelSize)

        guard let cgImage = ctx.makeImage() else { return nil }
        let rep = NSBitmapImageRep(cgImage: cgImage)
        return rep.representation(using: .png, properties: [:])
    }

    public static func renderNSImage(pointSize: CGFloat = 512) -> NSImage {
        let image = NSImage(size: NSSize(width: pointSize, height: pointSize))
        for scale in [1, 2] {
            let pixelSize = Int(pointSize) * scale
            if let data = renderPNGData(pixelSize: pixelSize),
               let rep = NSBitmapImageRep(data: data) {
                rep.size = NSSize(width: pointSize, height: pointSize)
                image.addRepresentation(rep)
            }
        }
        return image
    }

    public static func loadOrRenderImage() -> NSImage {
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let image = NSImage(contentsOf: url) {
            return image
        }
        return renderNSImage()
    }

    public static func writeIconset(to directoryURL: URL) throws {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let specs: [(name: String, pixels: Int)] = [
            ("icon_16x16.png", 16),
            ("icon_16x16@2x.png", 32),
            ("icon_32x32.png", 32),
            ("icon_32x32@2x.png", 64),
            ("icon_128x128.png", 128),
            ("icon_128x128@2x.png", 256),
            ("icon_256x256.png", 256),
            ("icon_256x256@2x.png", 512),
            ("icon_512x512.png", 512),
            ("icon_512x512@2x.png", 1024)
        ]
        for spec in specs {
            guard let pngData = renderPNGData(pixelSize: spec.pixels) else {
                throw CocoaError(.fileWriteUnknown)
            }
            try pngData.write(to: directoryURL.appendingPathComponent(spec.name))
        }
    }

    private static func draw(in ctx: CGContext, pixelSize: Int) {
        let size = CGFloat(pixelSize)
        let scale = size / 1024.0

        ctx.saveGState()
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        ctx.interpolationQuality = .high
        // Flip vertically so (0, 0) is top-left matching `icon.svg` coordinates
        ctx.translateBy(x: 0, y: size)
        ctx.scaleBy(x: scale, y: -scale)

        let iconRect = CGRect(x: 100, y: 100, width: 824, height: 824)
        let cornerRadius: CGFloat = 185.4
        let squirclePath = Path(
            roundedRect: iconRect,
            cornerRadius: cornerRadius,
            style: .continuous
        ).cgPath

        let topPurple = CGColor(srgbRed: 0x43 / 255.0, green: 0x2B / 255.0, blue: 0x7A / 255.0, alpha: 1.0)
        let bottomLeftPink = CGColor(srgbRed: 0xF8 / 255.0, green: 0x5A / 255.0, blue: 0xCB / 255.0, alpha: 1.0)
        let bottomRightPurple = CGColor(srgbRed: 0x64 / 255.0, green: 0x41 / 255.0, blue: 0xB3 / 255.0, alpha: 1.0)
        let white = CGColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

        // Outer macOS icon drop shadow
        ctx.saveGState()
        ctx.setShadow(
            offset: CGSize(width: 0, height: -10.0 * scale),
            blur: 24.0 * scale,
            color: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.28)
        )
        ctx.addPath(squirclePath)
        ctx.setFillColor(topPurple)
        ctx.fillPath()
        ctx.restoreGState()

        // Clip to squircle and map 480x480 `icon.svg` viewBox into 824x824 squircle
        ctx.saveGState()
        ctx.addPath(squirclePath)
        ctx.clip()

        ctx.translateBy(x: iconRect.minX, y: iconRect.minY)
        let svgScale: CGFloat = 824.0 / 480.0
        ctx.scaleBy(x: svgScale, y: svgScale)

        // Background rects from `icon.svg` (with 0.5pt overlap to prevent seam hairline)
        ctx.setFillColor(white)
        ctx.fill(CGRect(x: 0, y: 0, width: 480, height: 480))

        ctx.setFillColor(topPurple)
        ctx.fill(CGRect(x: 0, y: 0, width: 480, height: 240.5))

        ctx.setFillColor(bottomLeftPink)
        ctx.fill(CGRect(x: 0, y: 240, width: 240.5, height: 240))

        ctx.setFillColor(bottomRightPurple)
        ctx.fill(CGRect(x: 240, y: 240, width: 240, height: 240))

        // White glyphs ('7', '+', '=') from `icon.svg`
        ctx.setFillColor(white)
        for pathD in [sevenPathD, plusPathD, equalsPathD] {
            ctx.addPath(parseSVGPath(pathD))
            ctx.fillPath()
        }

        ctx.restoreGState()
        ctx.restoreGState()
    }

    /// Parses SVG path commands (`M`, `L`, `H`, `V`, `C`, `Z`) into a `CGPath`.
    public static func parseSVGPath(_ d: String) -> CGPath {
        let path = CGMutablePath()
        var index = d.startIndex
        var currentPoint = CGPoint.zero
        var subpathStart = CGPoint.zero
        var currentCommand: Character = " "

        func skipSeparators() {
            while index < d.endIndex && (d[index].isWhitespace || d[index] == ",") {
                index = d.index(after: index)
            }
        }

        func readNumber() -> CGFloat? {
            skipSeparators()
            guard index < d.endIndex else { return nil }
            let start = index
            if d[index] == "-" || d[index] == "+" {
                index = d.index(after: index)
            }
            var hasDigits = false
            while index < d.endIndex && d[index].isNumber {
                hasDigits = true
                index = d.index(after: index)
            }
            if index < d.endIndex && d[index] == "." {
                index = d.index(after: index)
                while index < d.endIndex && d[index].isNumber {
                    hasDigits = true
                    index = d.index(after: index)
                }
            }
            guard hasDigits, let val = Double(d[start..<index]) else { return nil }
            return CGFloat(val)
        }

        while index < d.endIndex {
            skipSeparators()
            guard index < d.endIndex else { break }

            let ch = d[index]
            if ch.isLetter {
                currentCommand = ch
                index = d.index(after: index)
            }

            switch currentCommand {
            case "M":
                if let x = readNumber(), let y = readNumber() {
                    currentPoint = CGPoint(x: x, y: y)
                    subpathStart = currentPoint
                    path.move(to: currentPoint)
                    currentCommand = "L"
                }
            case "L":
                if let x = readNumber(), let y = readNumber() {
                    currentPoint = CGPoint(x: x, y: y)
                    path.addLine(to: currentPoint)
                }
            case "H":
                if let x = readNumber() {
                    currentPoint = CGPoint(x: x, y: currentPoint.y)
                    path.addLine(to: currentPoint)
                }
            case "V":
                if let y = readNumber() {
                    currentPoint = CGPoint(x: currentPoint.x, y: y)
                    path.addLine(to: currentPoint)
                }
            case "C":
                if let x1 = readNumber(), let y1 = readNumber(),
                   let x2 = readNumber(), let y2 = readNumber(),
                   let x = readNumber(), let y = readNumber() {
                    let end = CGPoint(x: x, y: y)
                    path.addCurve(
                        to: end,
                        control1: CGPoint(x: x1, y: y1),
                        control2: CGPoint(x: x2, y: y2)
                    )
                    currentPoint = end
                }
            case "Z", "z":
                path.closeSubpath()
                currentPoint = subpathStart
                currentCommand = " "
            default:
                index = d.index(after: index)
            }
        }

        return path
    }
}
