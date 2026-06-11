import AppKit
import CoreGraphics
import Foundation

// Generates the Unquarantine app icon (open padlock on a blue squircle) at every
// macOS AppIcon size, plus the asset-catalog Contents.json. Pure CoreGraphics — no
// external image tooling. Run: swift tools/make_icon.swift [appiconset-dir]

let outDir = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "App/Assets.xcassets/AppIcon.appiconset"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: a)
}

func render(_ size: Int) -> Data {
    let S = CGFloat(size)
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                        bytesPerRow: 0, space: cs,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.interpolationQuality = .high

    // Work in a top-left-origin 1024 design grid, scaled to the target size.
    ctx.translateBy(x: 0, y: S)
    ctx.scaleBy(x: 1, y: -1)
    ctx.scaleBy(x: S / 1024, y: S / 1024)

    let inset: CGFloat = 100
    let sq = CGRect(x: inset, y: inset, width: 1024 - 2 * inset, height: 1024 - 2 * inset)
    let squircle = CGPath(roundedRect: sq, cornerWidth: 184, cornerHeight: 184, transform: nil)

    // Soft drop shadow (skip at tiny sizes where it just muddies the pixels).
    ctx.saveGState()
    if size >= 128 {
        ctx.setShadow(offset: CGSize(width: 0, height: 22), blur: 46, color: rgb(0, 0, 0, 0.28))
    }
    ctx.addPath(squircle)
    ctx.setFillColor(rgb(29, 79, 215))
    ctx.fillPath()
    ctx.restoreGState()

    // Blue gradient + subtle top sheen, clipped to the squircle.
    ctx.saveGState()
    ctx.addPath(squircle)
    ctx.clip()
    let grad = CGGradient(colorsSpace: cs, colors: [rgb(79, 157, 247), rgb(29, 79, 215)] as CFArray,
                          locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: 170, y: 150), end: CGPoint(x: 880, y: 900), options: [])
    let sheen = CGGradient(colorsSpace: cs, colors: [rgb(255, 255, 255, 0.16), rgb(255, 255, 255, 0)] as CFArray,
                           locations: [0, 1])!
    ctx.drawLinearGradient(sheen, start: CGPoint(x: 512, y: 120), end: CGPoint(x: 512, y: 560), options: [])
    ctx.restoreGState()

    let cx: CGFloat = 512
    let leftX = cx - 112
    let rightX = cx + 112

    // Open shackle: left leg attached into the body, arc over the top, right leg
    // raised with a clear gap above the body (reads as "unlocked").
    let shackle = CGMutablePath()
    shackle.move(to: CGPoint(x: leftX, y: 470))
    shackle.addLine(to: CGPoint(x: leftX, y: 360))
    shackle.addCurve(to: CGPoint(x: rightX, y: 360),
                     control1: CGPoint(x: leftX, y: 211),
                     control2: CGPoint(x: rightX, y: 211))
    shackle.addLine(to: CGPoint(x: rightX, y: 430))
    ctx.saveGState()
    ctx.setStrokeColor(rgb(255, 255, 255))
    ctx.setLineWidth(78)
    ctx.setLineCap(.round)
    ctx.addPath(shackle)
    ctx.strokePath()
    ctx.restoreGState()

    // Lock body (drawn on top so the left leg looks seated in it).
    let body = CGPath(roundedRect: CGRect(x: cx - 190, y: 470, width: 380, height: 300),
                      cornerWidth: 64, cornerHeight: 64, transform: nil)
    ctx.addPath(body)
    ctx.setFillColor(rgb(255, 255, 255))
    ctx.fillPath()

    // Keyhole: circle + tapered slot, a subtle dark inset on the white body.
    let keyhole = CGMutablePath()
    keyhole.addEllipse(in: CGRect(x: cx - 34, y: 566, width: 68, height: 68))
    keyhole.move(to: CGPoint(x: cx - 14, y: 600))
    keyhole.addLine(to: CGPoint(x: cx + 14, y: 600))
    keyhole.addLine(to: CGPoint(x: cx + 26, y: 700))
    keyhole.addLine(to: CGPoint(x: cx - 26, y: 700))
    keyhole.closeSubpath()
    ctx.addPath(keyhole)
    ctx.setFillColor(rgb(20, 70, 150, 0.32))
    ctx.fillPath()

    let img = ctx.makeImage()!
    return NSBitmapImageRep(cgImage: img).representation(using: .png, properties: [:])!
}

let entries: [(Int, String)] = [
    (16, "icon_16.png"), (32, "icon_16@2x.png"),
    (32, "icon_32.png"), (64, "icon_32@2x.png"),
    (128, "icon_128.png"), (256, "icon_128@2x.png"),
    (256, "icon_256.png"), (512, "icon_256@2x.png"),
    (512, "icon_512.png"), (1024, "icon_512@2x.png"),
]

var cache: [Int: Data] = [:]
for (size, name) in entries {
    let data = cache[size] ?? render(size)
    cache[size] = data
    try! data.write(to: URL(fileURLWithPath: "\(outDir)/\(name)"))
}

func entry(_ sizePt: String, _ scale: String, _ file: String) -> [String: String] {
    ["idiom": "mac", "size": sizePt, "scale": scale, "filename": file]
}
let contents: [String: Any] = [
    "images": [
        entry("16x16", "1x", "icon_16.png"),
        entry("16x16", "2x", "icon_16@2x.png"),
        entry("32x32", "1x", "icon_32.png"),
        entry("32x32", "2x", "icon_32@2x.png"),
        entry("128x128", "1x", "icon_128.png"),
        entry("128x128", "2x", "icon_128@2x.png"),
        entry("256x256", "1x", "icon_256.png"),
        entry("256x256", "2x", "icon_256@2x.png"),
        entry("512x512", "1x", "icon_512.png"),
        entry("512x512", "2x", "icon_512@2x.png"),
    ],
    "info": ["version": 1, "author": "xcode"],
]
let json = try! JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try! json.write(to: URL(fileURLWithPath: "\(outDir)/Contents.json"))

print("Wrote \(entries.count) icon files + Contents.json to \(outDir)")
