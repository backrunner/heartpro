import AppKit

// HeartPro — Pulse Fold. Coordinates use a 1024 pt, top-left-origin canvas.
let edge = 1024
let scale = 3
let srgb = CGColorSpace(name: CGColorSpace.sRGB)!
let context = CGContext(data: nil, width: edge * scale, height: edge * scale,
    bitsPerComponent: 8, bytesPerRow: 0, space: srgb,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
context.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
context.translateBy(x: 0, y: CGFloat(edge))
context.scaleBy(x: 1, y: -1)

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: srgb, components: [CGFloat((hex >> 16) & 255) / 255,
        CGFloat((hex >> 8) & 255) / 255, CGFloat(hex & 255) / 255, alpha])!
}
func gradient(_ path: CGPath, colors: [UInt32], from: CGPoint, to: CGPoint) {
    context.saveGState()
    context.addPath(path)
    context.clip()
    context.drawLinearGradient(CGGradient(colorsSpace: srgb,
        colors: colors.map { color($0) } as CFArray, locations: nil)!,
        start: from, end: to, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    context.restoreGState()
}
func band(_ path: CGPath, width: CGFloat = 122) -> CGPath {
    path.copy(strokingWithWidth: width, lineCap: .round, lineJoin: .round, miterLimit: 10)
}
let canvas = CGPath(rect: CGRect(x: 0, y: 0, width: edge, height: edge), transform: nil)
gradient(canvas, colors: [0x36202A, 0x21141D, 0x160F18],
         from: CGPoint(x: 150, y: 0), to: CGPoint(x: 840, y: 1024))

let rear = CGMutablePath()
rear.move(to: CGPoint(x: 482, y: 746))
rear.addCurve(to: CGPoint(x: 259, y: 398), control1: CGPoint(x: 386, y: 672), control2: CGPoint(x: 243, y: 535))
rear.addCurve(to: CGPoint(x: 445, y: 363), control1: CGPoint(x: 270, y: 265), control2: CGPoint(x: 398, y: 279))
rear.addCurve(to: CGPoint(x: 560, y: 618), control1: CGPoint(x: 477, y: 420), control2: CGPoint(x: 516, y: 539))
let rearShape = band(rear)

let front = CGMutablePath()
front.move(to: CGPoint(x: 482, y: 746))
front.addCurve(to: CGPoint(x: 762, y: 434), control1: CGPoint(x: 574, y: 679), control2: CGPoint(x: 732, y: 552))
front.addCurve(to: CGPoint(x: 623, y: 314), control1: CGPoint(x: 790, y: 318), control2: CGPoint(x: 692, y: 267))
front.addCurve(to: CGPoint(x: 534, y: 479), control1: CGPoint(x: 573, y: 348), control2: CGPoint(x: 558, y: 418))
front.addLine(to: CGPoint(x: 454, y: 667))
let frontShape = band(front)

// A soft cast shadow gives the mark a physical presence without a tile or border.
context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: 24), blur: 46, color: color(0x0A0408, 0.42))
context.setFillColor(color(0x9C213F))
context.addPath(rearShape); context.fillPath()
context.addPath(frontShape); context.fillPath()
context.restoreGState()

gradient(rearShape, colors: [0xFF7C72, 0xEE405C, 0xAC163C],
         from: CGPoint(x: 290, y: 272), to: CGPoint(x: 575, y: 715))
// The returning ribbon casts a small contact shadow onto the back face only.
context.saveGState()
context.addPath(rearShape); context.clip()
context.setShadow(offset: CGSize(width: -5, height: 13), blur: 22, color: color(0x600B26, 0.5))
context.addPath(frontShape); context.setFillColor(color(0xC5314E)); context.fillPath()
context.restoreGState()
gradient(frontShape, colors: [0xFFD3AD, 0xFF9A80, 0xFF5C67, 0xE83557],
         from: CGPoint(x: 674, y: 247), to: CGPoint(x: 429, y: 811))

// Deliberately keep the App Store source square and opaque: iOS applies its mask.
let output = CommandLine.arguments[1]
let target = CGContext(data: nil, width: edge, height: edge, bitsPerComponent: 8,
    bytesPerRow: 0, space: srgb, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
target.interpolationQuality = .high
target.draw(context.makeImage()!, in: CGRect(x: 0, y: 0, width: edge, height: edge))
let bitmap = NSBitmapImageRep(cgImage: target.makeImage()!)
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
print("Wrote \(output) — 1024 × 1024, opaque sRGB")
