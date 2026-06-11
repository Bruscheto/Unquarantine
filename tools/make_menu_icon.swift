import AppKit

// Renders the Finder menu icon as a monochrome black+alpha TEMPLATE image (1x/2x)
// from the lock.slash.fill SF Symbol, into the extension's asset catalog. A bundled
// template image adapts to light/dark reliably across the extension→Finder process
// boundary, where a runtime SF Symbol's template flag can be lost.
// Run: swift tools/make_menu_icon.swift

let outDir = "Extension/Assets.xcassets/MenuIcon.imageset"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func render(canvas: Int, point: CGFloat, file: String) {
    // Outline (hollow) variant, semibold weight — a touch thicker than medium.
    let cfg = NSImage.SymbolConfiguration(pointSize: point, weight: .semibold)
    guard let base = NSImage(systemSymbolName: "lock.slash", accessibilityDescription: nil),
          let sym = base.withSymbolConfiguration(cfg) else {
        FileHandle.standardError.write("symbol unavailable\n".data(using: .utf8)!); exit(1)
    }
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: canvas, pixelsHigh: canvas,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = ctx
    let s = sym.size
    let scale = min(CGFloat(canvas) / s.width, CGFloat(canvas) / s.height) * 0.92
    let w = s.width * scale, h = s.height * scale
    let r = NSRect(x: (CGFloat(canvas) - w) / 2, y: (CGFloat(canvas) - h) / 2, width: w, height: h)
    sym.draw(in: r, from: NSRect(origin: .zero, size: s), operation: .sourceOver, fraction: 1)
    NSColor.black.set()
    NSRect(x: 0, y: 0, width: canvas, height: canvas).fill(using: .sourceAtop)
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: file))
}

render(canvas: 16, point: 13, file: "\(outDir)/MenuIcon.png")
render(canvas: 32, point: 26, file: "\(outDir)/MenuIcon@2x.png")

let contents = """
{
  "images" : [
    { "idiom" : "mac", "scale" : "1x", "filename" : "MenuIcon.png" },
    { "idiom" : "mac", "scale" : "2x", "filename" : "MenuIcon@2x.png" }
  ],
  "info" : { "author" : "xcode", "version" : 1 },
  "properties" : { "template-rendering-intent" : "template" }
}
"""
try! contents.write(toFile: "\(outDir)/Contents.json", atomically: true, encoding: .utf8)
print("ok")
