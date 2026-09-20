import AppKit

// HeartPro / Cardiac Imprint. One continuous heart with an inset ECG.
// Source artwork is square and opaque; the operating system owns its corner mask.
let srgb = CGColorSpace(name: CGColorSpace.sRGB)!
let size = 1024
let scale = 3

func color(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: srgb, components: [CGFloat(hex >> 16 & 255) / 255,
        CGFloat(hex >> 8 & 255) / 255, CGFloat(hex & 255) / 255, alpha])!
}

func linear(_ context: CGContext, colors: [UInt32], from: CGPoint, to: CGPoint) {
    context.drawLinearGradient(CGGradient(colorsSpace: srgb,
        colors: colors.map { color($0) } as CFArray, locations: nil)!,
        start: from, end: to, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
}

let heart = CGMutablePath()
heart.move(to: CGPoint(x: 512, y: 315))
heart.addCurve(to: CGPoint(x: 342, y: 241), control1: CGPoint(x: 463, y: 261), control2: CGPoint(x: 413, y: 241))
heart.addCurve(to: CGPoint(x: 207, y: 411), control1: CGPoint(x: 254, y: 241), control2: CGPoint(x: 207, y: 313))
heart.addCurve(to: CGPoint(x: 354, y: 661), control1: CGPoint(x: 207, y: 511), control2: CGPoint(x: 286, y: 595))
heart.addCurve(to: CGPoint(x: 491, y: 779), control1: CGPoint(x: 409, y: 713), control2: CGPoint(x: 462, y: 757))
heart.addQuadCurve(to: CGPoint(x: 533, y: 779), control: CGPoint(x: 512, y: 796))
heart.addCurve(to: CGPoint(x: 670, y: 661), control1: CGPoint(x: 562, y: 757), control2: CGPoint(x: 615, y: 713))
heart.addCurve(to: CGPoint(x: 817, y: 411), control1: CGPoint(x: 738, y: 595), control2: CGPoint(x: 817, y: 511))
heart.addCurve(to: CGPoint(x: 682, y: 241), control1: CGPoint(x: 817, y: 313), control2: CGPoint(x: 770, y: 241))
heart.addCurve(to: CGPoint(x: 512, y: 315), control1: CGPoint(x: 611, y: 241), control2: CGPoint(x: 561, y: 261))
heart.closeSubpath()

// Keep both ends inside the silhouette so the heart reads as a single form.
// Rounded P/T shoulders and a taller R peak retain a clear ECG rhythm at small sizes.
let trace = CGMutablePath()
trace.move(to: CGPoint(x: 284, y: 510))
trace.addLine(to: CGPoint(x: 305, y: 510))
trace.addCurve(to: CGPoint(x: 338, y: 484), control1: CGPoint(x: 321, y: 510), control2: CGPoint(x: 321, y: 484))
trace.addCurve(to: CGPoint(x: 371, y: 510), control1: CGPoint(x: 355, y: 484), control2: CGPoint(x: 355, y: 510))
trace.addLine(to: CGPoint(x: 406, y: 510))
trace.addQuadCurve(to: CGPoint(x: 430, y: 537), control: CGPoint(x: 415, y: 510))
trace.addLine(to: CGPoint(x: 475, y: 398))
trace.addQuadCurve(to: CGPoint(x: 484, y: 398), control: CGPoint(x: 480, y: 382))
trace.addLine(to: CGPoint(x: 535, y: 582))
trace.addQuadCurve(to: CGPoint(x: 544, y: 582), control: CGPoint(x: 539, y: 600))
trace.addLine(to: CGPoint(x: 581, y: 522))
trace.addQuadCurve(to: CGPoint(x: 598, y: 510), control: CGPoint(x: 586, y: 510))
trace.addLine(to: CGPoint(x: 614, y: 510))
trace.addCurve(to: CGPoint(x: 662, y: 472), control1: CGPoint(x: 636, y: 510), control2: CGPoint(x: 634, y: 472))
trace.addCurve(to: CGPoint(x: 710, y: 510), control1: CGPoint(x: 689, y: 472), control2: CGPoint(x: 687, y: 510))
trace.addLine(to: CGPoint(x: 740, y: 510))
let channel = trace.copy(strokingWithWidth: 34, lineCap: .round, lineJoin: .round, miterLimit: 10)

// Reuse the app icon's exact geometry and colors for the in-app wordmark.
// Both the canvas and inset ECG remain transparent, without an icon tile.
if CommandLine.arguments.count == 3, CommandLine.arguments[1] == "--brand-mark" {
    let directory = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let bounds = heart.boundingBoxOfPath
    let factor = 60 / bounds.width
    for dark in [false, true] {
        let output = directory.appendingPathComponent(dark ? "BrandMarkDark.pdf" : "BrandMark.pdf")
        var page = CGRect(x: 0, y: 0, width: 64, height: 64)
        let context = CGContext(output as CFURL, mediaBox: &page, nil)!
        context.beginPDFPage(nil)
        context.translateBy(x: 0, y: 64)
        context.scaleBy(x: 1, y: -1)
        context.translateBy(x: 2, y: (64 - bounds.height * factor) / 2)
        context.scaleBy(x: factor, y: factor)
        context.translateBy(x: -bounds.minX, y: -bounds.minY)
        context.addPath(heart)
        context.addPath(channel)
        context.clip(using: .evenOdd)
        linear(context, colors: dark ? [0xFF797D, 0xF4495C, 0xCF2945] : [0xF26569, 0xDD384D, 0xBF233D],
            from: CGPoint(x: 320, y: 241), to: CGPoint(x: 681, y: 800))
        context.endPDFPage()
        context.closePDF()
        print(output.path)
    }
    exit(0)
}

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: swift Tools/GenerateIcon.swift <AppIcon.png>\nAlso exports a sibling AppIconDark.png.\nOr: swift Tools/GenerateIcon.swift --brand-mark <imageset directory>\n", stderr)
    exit(1)
}
let lightOutput = URL(fileURLWithPath: CommandLine.arguments[1])
let darkOutput = lightOutput.deletingLastPathComponent()
    .appendingPathComponent(lightOutput.deletingPathExtension().lastPathComponent + "Dark.png")
try FileManager.default.createDirectory(at: lightOutput.deletingLastPathComponent(), withIntermediateDirectories: true)
for dark in [false, true] {
    let context = CGContext(data: nil, width: size * scale, height: size * scale,
        bitsPerComponent: 8, bytesPerRow: 0, space: srgb,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    context.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
    context.translateBy(x: 0, y: CGFloat(size)); context.scaleBy(x: 1, y: -1)
    let backdrop: [UInt32] = dark ? [0x252527, 0x151517] : [0xFFFDFA, 0xF0EAE4]
    let origin = CGPoint(x: 180, y: 80), end = CGPoint(x: 900, y: 1000)
    linear(context, colors: backdrop, from: origin, to: end)

    context.saveGState()
    context.addPath(heart); context.clip()
    linear(context, colors: dark ? [0xFF797D, 0xF4495C, 0xCF2945] : [0xF26569, 0xDD384D, 0xBF233D],
        from: CGPoint(x: 320, y: 241), to: CGPoint(x: 681, y: 800))
    context.saveGState()
    context.addPath(channel); context.clip()
    linear(context, colors: backdrop, from: origin, to: end)
    context.restoreGState()
    context.restoreGState()

    let output = dark ? darkOutput : lightOutput
    let target = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
        bytesPerRow: 0, space: srgb, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    target.interpolationQuality = .high
    target.draw(context.makeImage()!, in: CGRect(x: 0, y: 0, width: size, height: size))
    let bitmap = NSBitmapImageRep(cgImage: target.makeImage()!)
    try bitmap.representation(using: .png, properties: [:])!.write(to: output)
    print(output.path)
}
