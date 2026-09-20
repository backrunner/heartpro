import AppKit

let srgb = CGColorSpace(name: CGColorSpace.sRGB)!
func ink(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: srgb, components: [CGFloat(hex >> 16 & 255) / 255,
        CGFloat(hex >> 8 & 255) / 255, CGFloat(hex & 255) / 255, alpha])!
}
func polygon(_ points: [CGPoint], radius: CGFloat) -> CGPath {
    let path = CGMutablePath()
    for i in points.indices {
        let before = points[(i + points.count - 1) % points.count]
        let point = points[i]
        let after = points[(i + 1) % points.count]
        let a = hypot(before.x - point.x, before.y - point.y)
        let b = hypot(after.x - point.x, after.y - point.y)
        let d = min(radius, a * 0.45, b * 0.45)
        let enter = CGPoint(x: point.x + (before.x - point.x) * d / a,
                            y: point.y + (before.y - point.y) * d / a)
        let leave = CGPoint(x: point.x + (after.x - point.x) * d / b,
                            y: point.y + (after.y - point.y) * d / b)
        if i == 0 { path.move(to: enter) } else { path.addLine(to: enter) }
        path.addQuadCurve(to: leave, control: point)
    }
    path.closeSubpath()
    return path
}

let coordinates: [(CGFloat, CGFloat)] = [
    (240, 774), (343, 250), (488, 250), (449, 451),
    (596, 380), (622, 250), (767, 250), (664, 774),
    (519, 774), (560, 565), (412, 637), (385, 774)
]
let mark = polygon(coordinates.map { CGPoint(x: $0.0, y: $0.1) }, radius: 29)

let directory = CommandLine.arguments[1]
for (name, background, foreground) in [
    ("signal-h-red", UInt32(0xCC3C37), UInt32(0xFFF3DF)),
    ("signal-h-paper", UInt32(0xF4F0E8), UInt32(0xD8453D)),
    ("signal-h-ink", UInt32(0x202827), UInt32(0xE6EECF))
] {
    let scale = 3
    let context = CGContext(data: nil, width: 1024 * scale, height: 1024 * scale,
        bitsPerComponent: 8, bytesPerRow: 0, space: srgb,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    context.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
    context.translateBy(x: 0, y: 1024)
    context.scaleBy(x: 1, y: -1)
    context.setFillColor(ink(background))
    context.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
    context.setFillColor(ink(foreground))
    context.addPath(mark); context.fillPath()
    let target = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8,
        bytesPerRow: 0, space: srgb, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    target.interpolationQuality = .high
    target.draw(context.makeImage()!, in: CGRect(x: 0, y: 0, width: 1024, height: 1024))
    let bitmap = NSBitmapImageRep(cgImage: target.makeImage()!)
    try bitmap.representation(using: .png, properties: [:])!.write(to:
        URL(fileURLWithPath: directory).appendingPathComponent("\(name).png"))
}
