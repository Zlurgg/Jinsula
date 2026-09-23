//
//  GenerateAppIcon.swift
//  Jinsula — app icon generator (Session 12 plan → built)
//
//  Standalone Swift + CoreGraphics script. NOT a member of any Xcode target.
//  Draws one flat, fully OPAQUE 1024×1024 PNG of the app mark: a bold blood
//  droplet (Theme.emergency red) on a calm neutral background, with a
//  red/amber/green traffic-light accent inside it — tying the icon to the
//  guidance-band metaphor. No text, high contrast, no rounded corners (iOS
//  applies its own mask), no alpha (the App Store rejects it).
//
//  Palette is Theme.swift exactly — no invented colours.
//
//  Run:  swift Scripts/GenerateAppIcon.swift [output.png]
//  Default output: Jinsula/Assets.xcassets/AppIcon.appiconset/icon-1024.png
//

import Foundation
import CoreGraphics
import ImageIO

// MARK: - Output path

let defaultOut = "Jinsula/Assets.xcassets/AppIcon.appiconset/icon-1024.png"
let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultOut

// MARK: - Palette (Theme.swift, verbatim)

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGColor {
    CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [r, g, b, 1])!
}

let background = rgb(0.96, 0.96, 0.94)   // soft off-white / light grey
let emergency  = rgb(0.85, 0.11, 0.09)   // Theme.emergency (red) — the droplet
let high       = rgb(0.64, 0.40, 0.02)   // Theme.high (amber)
let inRange     = rgb(0.18, 0.68, 0.28)  // Theme.inRange (green)

// MARK: - Canvas (opaque, no alpha)

let side = 1024
guard let ctx = CGContext(
    data: nil,
    width: side, height: side,
    bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else {
    fatalError("Could not create bitmap context")
}

// Flip to a top-left origin so the geometry below reads like screen coords.
ctx.translateBy(x: 0, y: CGFloat(side))
ctx.scaleBy(x: 1, y: -1)

// Opaque background fill.
ctx.setFillColor(background)
ctx.fill(CGRect(x: 0, y: 0, width: side, height: side))

// MARK: - Blood droplet (four cubic Béziers: pointed tip, round bulb)

let droplet = CGMutablePath()
droplet.move(to: CGPoint(x: 512, y: 180))                              // tip (top)
droplet.addCurve(to: CGPoint(x: 812, y: 660),                          // → right waist
                 control1: CGPoint(x: 575, y: 300),
                 control2: CGPoint(x: 812, y: 480))
droplet.addCurve(to: CGPoint(x: 512, y: 960),                          // → bottom
                 control1: CGPoint(x: 812, y: 800),
                 control2: CGPoint(x: 700, y: 940))
droplet.addCurve(to: CGPoint(x: 212, y: 660),                          // → left waist
                 control1: CGPoint(x: 324, y: 940),
                 control2: CGPoint(x: 212, y: 800))
droplet.addCurve(to: CGPoint(x: 512, y: 180),                          // → back to tip
                 control1: CGPoint(x: 212, y: 480),
                 control2: CGPoint(x: 449, y: 300))
droplet.closeSubpath()

ctx.setFillColor(emergency)
ctx.addPath(droplet)
ctx.fillPath()

// MARK: - Traffic-light accent (neutral housing + three lights, inside the bulb)

// Vertical rounded "housing" in the background colour so the lights read as a
// traffic light sitting within the droplet.
let housing = CGPath(
    roundedRect: CGRect(x: 437, y: 470, width: 150, height: 380),
    cornerWidth: 75, cornerHeight: 75, transform: nil
)
ctx.setFillColor(background)
ctx.addPath(housing)
ctx.fillPath()

// Three lights, top→bottom: red, amber, green.
let lightRadius: CGFloat = 50
let lights: [(CGFloat, CGColor)] = [
    (555, emergency),   // red   (top)
    (660, high),        // amber (middle)
    (765, inRange),     // green (bottom)
]
for (cy, colour) in lights {
    ctx.setFillColor(colour)
    ctx.fillEllipse(in: CGRect(x: 512 - lightRadius, y: cy - lightRadius,
                               width: lightRadius * 2, height: lightRadius * 2))
}

// MARK: - Export PNG

guard let image = ctx.makeImage() else { fatalError("Could not render image") }
let url = URL(fileURLWithPath: outPath)
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
    fatalError("Could not create PNG destination at \(outPath)")
}
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("Could not write PNG") }

print("Wrote \(side)×\(side) icon → \(outPath)")
