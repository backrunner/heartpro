import AppKit

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()
NSGradient(starting: NSColor(srgbRed: 0.98, green: 0.43, blue: 0.47, alpha: 1), ending: NSColor(srgbRed: 0.79, green: 0.16, blue: 0.27, alpha: 1))!.draw(in: NSBezierPath(rect: NSRect(origin: .zero, size: size)), angle: -50)
let heart = NSBezierPath()
heart.move(to: NSPoint(x: 512, y: 232))
heart.curve(to: NSPoint(x: 235, y: 592), controlPoint1: NSPoint(x: 422, y: 330), controlPoint2: NSPoint(x: 235, y: 462))
heart.curve(to: NSPoint(x: 512, y: 710), controlPoint1: NSPoint(x: 235, y: 773), controlPoint2: NSPoint(x: 405, y: 822))
heart.curve(to: NSPoint(x: 789, y: 592), controlPoint1: NSPoint(x: 619, y: 822), controlPoint2: NSPoint(x: 789, y: 773))
heart.curve(to: NSPoint(x: 512, y: 232), controlPoint1: NSPoint(x: 789, y: 462), controlPoint2: NSPoint(x: 602, y: 330))
heart.close(); NSColor.white.withAlphaComponent(0.96).setFill(); heart.fill()
let line = NSBezierPath(); line.move(to: NSPoint(x: 200, y: 510))
for point in [(376,510),(420,554),(461,458),(505,643),(552,391),(604,510),(824,510)] { line.line(to: NSPoint(x: point.0, y: point.1)) }
line.lineWidth = 27; line.lineCapStyle = .round; line.lineJoinStyle = .round
NSColor(srgbRed: 0.86, green: 0.24, blue: 0.33, alpha: 1).setStroke(); line.stroke()
image.unlockFocus()
let source = image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
let context = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
context.draw(source, in: CGRect(origin: .zero, size: size))
let bitmap = NSBitmapImageRep(cgImage: context.makeImage()!)
let output = CommandLine.arguments[1]
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
