import Cocoa
import Foundation

let iconsetName = "AppIcon.iconset"
let outputName = "AppIcon.icns"

let fileManager = FileManager.default
let root = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let iconsetURL = root.appendingPathComponent(iconsetName)
let outputURL = root.appendingPathComponent(outputName)

try? fileManager.removeItem(at: iconsetURL)
try? fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

struct IconSize {
    let points: Int
    let scale: Int

    var pixels: Int { points * scale }
    var filename: String {
        if scale == 1 {
            return "icon_\(points)x\(points).png"
        }
        return "icon_\(points)x\(points)@\(scale)x.png"
    }
}

let sizes = [
    IconSize(points: 16, scale: 1),
    IconSize(points: 16, scale: 2),
    IconSize(points: 32, scale: 1),
    IconSize(points: 32, scale: 2),
    IconSize(points: 128, scale: 1),
    IconSize(points: 128, scale: 2),
    IconSize(points: 256, scale: 1),
    IconSize(points: 256, scale: 2),
    IconSize(points: 512, scale: 1),
    IconSize(points: 512, scale: 2)
]

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

func scaledPath(points: [CGPoint], in rect: CGRect) -> NSBezierPath {
    let path = NSBezierPath()
    for (index, point) in points.enumerated() {
        let p = CGPoint(
            x: rect.minX + point.x * rect.width,
            y: rect.minY + point.y * rect.height
        )
        if index == 0 {
            path.move(to: p)
        } else {
            path.line(to: p)
        }
    }
    return path
}

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    NSGraphicsContext.current?.imageInterpolation = .high
    NSGraphicsContext.current?.shouldAntialias = true

    let bounds = CGRect(x: 0, y: 0, width: size, height: size)
    NSColor.clear.setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()

    let outerInset = size * 0.055
    let iconRect = bounds.insetBy(dx: outerInset, dy: outerInset)
    let radius = size * 0.205
    let background = NSBezierPath(roundedRect: iconRect, xRadius: radius, yRadius: radius)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.32)
    shadow.shadowBlurRadius = size * 0.07
    shadow.shadowOffset = NSSize(width: 0, height: -size * 0.025)
    shadow.set()

    let gradient = NSGradient(colors: [
        color(31, 43, 69),
        color(13, 17, 28),
        color(8, 11, 19)
    ])!
    gradient.draw(in: background, angle: -90)

    NSGraphicsContext.restoreGraphicsState()

    let rim = NSBezierPath(roundedRect: iconRect.insetBy(dx: size * 0.012, dy: size * 0.012),
                           xRadius: radius * 0.92,
                           yRadius: radius * 0.92)
    color(118, 145, 194, 0.34).setStroke()
    rim.lineWidth = max(size * 0.014, 1)
    rim.stroke()

    let highlight = NSBezierPath()
    highlight.move(to: CGPoint(x: iconRect.minX + size * 0.17, y: iconRect.maxY - size * 0.14))
    highlight.line(to: CGPoint(x: iconRect.maxX - size * 0.17, y: iconRect.maxY - size * 0.14))
    color(255, 255, 255, 0.16).setStroke()
    highlight.lineWidth = max(size * 0.01, 1)
    highlight.lineCapStyle = .round
    highlight.stroke()

    let chartRect = iconRect.insetBy(dx: size * 0.18, dy: size * 0.23)

    let grid = NSBezierPath()
    for fraction in [0.24, 0.50, 0.76] as [CGFloat] {
        let y = chartRect.minY + chartRect.height * fraction
        grid.move(to: CGPoint(x: chartRect.minX, y: y))
        grid.line(to: CGPoint(x: chartRect.maxX, y: y))
    }
    color(255, 255, 255, 0.09).setStroke()
    grid.lineWidth = max(size * 0.006, 0.75)
    grid.stroke()

    let chartPoints = [
        CGPoint(x: 0.02, y: 0.20),
        CGPoint(x: 0.24, y: 0.34),
        CGPoint(x: 0.41, y: 0.28),
        CGPoint(x: 0.58, y: 0.56),
        CGPoint(x: 0.76, y: 0.48),
        CGPoint(x: 0.98, y: 0.82)
    ]
    let line = scaledPath(points: chartPoints, in: chartRect)
    line.lineJoinStyle = .round
    line.lineCapStyle = .round

    let glow = line.copy() as! NSBezierPath
    color(54, 238, 177, 0.25).setStroke()
    glow.lineWidth = max(size * 0.07, 3)
    glow.stroke()

    let under = line.copy() as! NSBezierPath
    color(37, 161, 225, 0.55).setStroke()
    under.lineWidth = max(size * 0.034, 2)
    under.stroke()

    color(82, 255, 184, 1).setStroke()
    line.lineWidth = max(size * 0.024, 1.8)
    line.stroke()

    let finalPoint = CGPoint(
        x: chartRect.minX + chartPoints.last!.x * chartRect.width,
        y: chartRect.minY + chartPoints.last!.y * chartRect.height
    )
    let dotSize = max(size * 0.08, 4)
    let dotRect = CGRect(
        x: finalPoint.x - dotSize / 2,
        y: finalPoint.y - dotSize / 2,
        width: dotSize,
        height: dotSize
    )
    color(10, 14, 24, 1).setFill()
    NSBezierPath(ovalIn: dotRect).fill()
    color(82, 255, 184, 1).setStroke()
    let dot = NSBezierPath(ovalIn: dotRect.insetBy(dx: size * 0.006, dy: size * 0.006))
    dot.lineWidth = max(size * 0.012, 1)
    dot.stroke()

    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "CryptoFloatIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to encode PNG"])
    }
    try png.write(to: url)
}

for size in sizes {
    let image = drawIcon(size: CGFloat(size.pixels))
    try writePNG(image, to: iconsetURL.appendingPathComponent(size.filename))
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetURL.path, "-o", outputURL.path]
try process.run()
process.waitUntilExit()

if process.terminationStatus != 0 {
    throw NSError(domain: "CryptoFloatIcon", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "iconutil failed"])
}

print("Generated \(outputName)")
