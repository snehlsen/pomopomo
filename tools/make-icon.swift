// Draws the app icon, a kitchen-timer tomato, into the asset catalog's AppIcon set.
// Run with `make icon`.
import AppKit
import SwiftUI

struct Calyx: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = rect.width / 2, inner = outer * 0.45
        var path = Path()
        for index in 0..<10 {
            let radius = index.isMultiple(of: 2) ? outer : inner
            let angle = Double(index) * .pi / 5 - .pi / 2
            let point = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle) * 0.55)
            index == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

struct Icon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 185, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 1, green: 0.97, blue: 0.93), Color(red: 0.97, green: 0.87, blue: 0.78)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 824, height: 824)
                .shadow(color: .black.opacity(0.3), radius: 12, y: 10)
            ZStack {
                Ellipse()
                    .fill(RadialGradient(colors: [Color(red: 1, green: 0.45, blue: 0.33), Color(red: 0.89, green: 0.2, blue: 0.13), Color(red: 0.66, green: 0.1, blue: 0.07)],
                                         center: UnitPoint(x: 0.38, y: 0.32), startRadius: 20, endRadius: 400))
                    .frame(width: 600, height: 540)
                    .shadow(color: Color(red: 0.5, green: 0.15, blue: 0.05).opacity(0.35), radius: 18, y: 14)
                // The timer's dial, with the hand at 25 minutes: one Pomodoro.
                ForEach(0..<12) { index in
                    Capsule()
                        .fill(.white.opacity(index.isMultiple(of: 3) ? 0.95 : 0.6))
                        .frame(width: index.isMultiple(of: 3) ? 16 : 10, height: index.isMultiple(of: 3) ? 52 : 34)
                        .offset(y: -190)
                        .rotationEffect(.degrees(Double(index) * 30))
                }
                .scaleEffect(x: 1, y: 0.9)
                Capsule()
                    .fill(.white)
                    .frame(width: 22, height: 150)
                    .offset(y: -62)
                    .rotationEffect(.degrees(150), anchor: .center)
                Circle().fill(.white).frame(width: 44, height: 44)
                Ellipse()
                    .fill(.white.opacity(0.28))
                    .frame(width: 150, height: 80)
                    .rotationEffect(.degrees(-35))
                    .offset(x: -170, y: -140)
                    .blur(radius: 6)
                Calyx()
                    .fill(LinearGradient(colors: [Color(red: 0.36, green: 0.72, blue: 0.3), Color(red: 0.16, green: 0.5, blue: 0.2)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 280, height: 170)
                    .offset(y: -262)
                Capsule()
                    .fill(Color(red: 0.2, green: 0.5, blue: 0.2))
                    .frame(width: 26, height: 70)
                    .rotationEffect(.degrees(12))
                    .offset(x: 6, y: -300)
            }
            .offset(y: 30)
        }
        .frame(width: 1024, height: 1024)
    }
}

let folder = URL(fileURLWithPath: CommandLine.arguments[1])
let sizes = [16, 32, 64, 128, 256, 512, 1024]
MainActor.assumeIsolated {
    let renderer = ImageRenderer(content: Icon())
    renderer.scale = 1
    let full = renderer.cgImage!
    for size in sizes {
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
                                   samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current!.imageInterpolation = .high
        NSGraphicsContext.current!.cgContext.draw(full, in: CGRect(x: 0, y: 0, width: size, height: size))
        NSGraphicsContext.current = nil
        try! rep.representation(using: .png, properties: [:])!.write(to: folder.appending(path: "icon_\(size).png"))
    }
}
