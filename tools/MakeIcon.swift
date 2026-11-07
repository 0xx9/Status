import AppKit

let size = 1024
let side = CGFloat(size)
guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: size,
    pixelsHigh: size,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("bitmap failed\n", stderr)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
defer { NSGraphicsContext.restoreGraphicsState() }

guard let ctx = NSGraphicsContext.current?.cgContext else {
    fputs("context failed\n", stderr)
    exit(1)
}

let canvas = CGRect(x: 0, y: 0, width: side, height: side)
ctx.setFillColor(NSColor(srgbRed: 0.07, green: 0.11, blue: 0.10, alpha: 1).cgColor)
ctx.fill(canvas)

let colors = [
    NSColor(srgbRed: 0.20, green: 0.40, blue: 0.34, alpha: 1).cgColor,
    NSColor(srgbRed: 0.06, green: 0.10, blue: 0.09, alpha: 1).cgColor
] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
ctx.drawRadialGradient(
    gradient,
    startCenter: CGPoint(x: side * 0.42, y: side * 0.62),
    startRadius: 20,
    endCenter: CGPoint(x: side * 0.5, y: side * 0.42),
    endRadius: side * 0.72,
    options: []
)

let center = CGPoint(x: side / 2, y: side / 2)
let radius = side * 0.29
let line = side * 0.052

ctx.setLineWidth(line)
ctx.setLineCap(.round)
ctx.setStrokeColor(NSColor(white: 1, alpha: 0.14).cgColor)
ctx.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
ctx.strokePath()

ctx.setStrokeColor(NSColor(srgbRed: 0.55, green: 0.89, blue: 0.76, alpha: 1).cgColor)
ctx.setLineWidth(line)
ctx.setLineCap(.round)
ctx.addArc(center: center, radius: radius, startAngle: .pi * 0.62, endAngle: .pi * 2.22, clockwise: false)
ctx.strokePath()

let dot = side * 0.034
ctx.setFillColor(NSColor(srgbRed: 0.55, green: 0.89, blue: 0.76, alpha: 1).cgColor)
ctx.fillEllipse(in: CGRect(x: center.x - dot, y: center.y - dot, width: dot * 2, height: dot * 2))

guard let png = rep.representation(using: .png, properties: [:]) else {
    fputs("png failed\n", stderr)
    exit(1)
}

let destination = URL(fileURLWithPath: CommandLine.arguments[1])
try png.write(to: destination)
print(destination.path)
