import SwiftUI

public struct GunPreviewCanvas: View {
    public let gunColor: Color
    public let backdropColor: Color
    public let outlineWidth: Float
    
    public init(gunColor: Color, backdropColor: Color, outlineWidth: Float) {
        self.gunColor = gunColor
        self.backdropColor = backdropColor
        self.outlineWidth = outlineWidth
    }
    
    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let cx = w / 2.0
            let cy = h / 2.0
            
            // 1. Background Grid & Radar
            var gridPath = Path()
            let step: CGFloat = 20.0
            var x: CGFloat = 0
            while x <= w {
                gridPath.move(to: CGPoint(x: x, y: 0))
                gridPath.addLine(to: CGPoint(x: x, y: h))
                x += step
            }
            var y: CGFloat = 0
            while y <= h {
                gridPath.move(to: CGPoint(x: 0, y: y))
                gridPath.addLine(to: CGPoint(x: w, y: y))
                y += step
            }
            context.stroke(gridPath, with: .color(Color.white.opacity(0.04)), lineWidth: 1)
            
            // 2. Backdrop Glow Rectangles (Mảng Nền Poster Phía Sau)
            let scale = CGFloat(max(0.6, min(2.5, outlineWidth / 2.0)))
            
            // Backdrop 1 (Upper Left Polygon)
            var b1 = Path()
            b1.move(to: CGPoint(x: cx - 110 * scale, y: cy - 65 * scale))
            b1.addLine(to: CGPoint(x: cx - 10 * scale, y: cy - 80 * scale))
            b1.addLine(to: CGPoint(x: cx - 25 * scale, y: cy - 20 * scale))
            b1.addLine(to: CGPoint(x: cx - 120 * scale, y: cy - 10 * scale))
            b1.closeSubpath()
            context.fill(b1, with: .color(backdropColor.opacity(0.85)))
            
            // Backdrop 2 (Upper Right Polygon)
            var b2 = Path()
            b2.move(to: CGPoint(x: cx + 15 * scale, y: cy - 75 * scale))
            b2.addLine(to: CGPoint(x: cx + 115 * scale, y: cy - 55 * scale))
            b2.addLine(to: CGPoint(x: cx + 95 * scale, y: cy - 15 * scale))
            b2.addLine(to: CGPoint(x: cx + 5 * scale, y: cy - 25 * scale))
            b2.closeSubpath()
            context.fill(b2, with: .color(backdropColor.opacity(0.90)))
            
            // Backdrop 3 (Lower Left Polygon)
            var b3 = Path()
            b3.move(to: CGPoint(x: cx - 115 * scale, y: cy + 10 * scale))
            b3.addLine(to: CGPoint(x: cx - 15 * scale, y: cy + 25 * scale))
            b3.addLine(to: CGPoint(x: cx - 35 * scale, y: cy + 70 * scale))
            b3.addLine(to: CGPoint(x: cx - 100 * scale, y: cy + 60 * scale))
            b3.closeSubpath()
            context.fill(b3, with: .color(backdropColor.opacity(0.80)))
            
            // Backdrop 4 (Lower Right Polygon)
            var b4 = Path()
            b4.move(to: CGPoint(x: cx + 10 * scale, y: cy + 20 * scale))
            b4.addLine(to: CGPoint(x: cx + 110 * scale, y: cy + 10 * scale))
            b4.addLine(to: CGPoint(x: cx + 120 * scale, y: cy + 65 * scale))
            b4.addLine(to: CGPoint(x: cx + 25 * scale, y: cy + 75 * scale))
            b4.closeSubpath()
            context.fill(b4, with: .color(backdropColor.opacity(0.88)))
            
            // 3. Central M4A1 Gun Silhouette
            var gunPath = Path()
            // Stock (Báng súng)
            gunPath.move(to: CGPoint(x: cx - 105, y: cy + 8))
            gunPath.addLine(to: CGPoint(x: cx - 75, y: cy + 5))
            gunPath.addLine(to: CGPoint(x: cx - 75, y: cy - 8))
            gunPath.addLine(to: CGPoint(x: cx - 105, y: cy - 12))
            gunPath.closeSubpath()
            
            // Receiver (Thân súng & Ổ khóa)
            var recPath = Path()
            recPath.move(to: CGPoint(x: cx - 75, y: cy - 10))
            recPath.addLine(to: CGPoint(x: cx + 10, y: cy - 10))
            recPath.addLine(to: CGPoint(x: cx + 10, y: cy + 6))
            recPath.addLine(to: CGPoint(x: cx - 75, y: cy + 6))
            recPath.closeSubpath()
            
            // Scope Rail & Sights (Kính ngắm)
            var sightPath = Path()
            sightPath.move(to: CGPoint(x: cx - 45, y: cy - 10))
            sightPath.addLine(to: CGPoint(x: cx - 40, y: cy - 18))
            sightPath.addLine(to: CGPoint(x: cx - 10, y: cy - 18))
            sightPath.addLine(to: CGPoint(x: cx - 5, y: cy - 10))
            sightPath.closeSubpath()
            
            // Barrel & Handguard (Nòng & Ốp lót tay)
            var barrelPath = Path()
            barrelPath.move(to: CGPoint(x: cx + 10, y: cy - 7))
            barrelPath.addLine(to: CGPoint(x: cx + 90, y: cy - 7))
            barrelPath.addLine(to: CGPoint(x: cx + 105, y: cy - 3))
            barrelPath.addLine(to: CGPoint(x: cx + 105, y: cy - 1))
            barrelPath.addLine(to: CGPoint(x: cx + 90, y: cy + 3))
            barrelPath.addLine(to: CGPoint(x: cx + 10, y: cy + 3))
            barrelPath.closeSubpath()
            
            // Grip (Tay cầm)
            var gripPath = Path()
            gripPath.move(to: CGPoint(x: cx - 48, y: cy + 6))
            gripPath.addLine(to: CGPoint(x: cx - 40, y: cy + 32))
            gripPath.addLine(to: CGPoint(x: cx - 30, y: cy + 30))
            gripPath.addLine(to: CGPoint(x: cx - 38, y: cy + 6))
            gripPath.closeSubpath()
            
            // Magazine (Hộp tiếp đạn cong)
            var magPath = Path()
            magPath.move(to: CGPoint(x: cx - 15, y: cy + 6))
            magPath.addLine(to: CGPoint(x: cx - 8, y: cy + 42))
            magPath.addLine(to: CGPoint(x: cx + 4, y: cy + 40))
            magPath.addLine(to: CGPoint(x: cx - 2, y: cy + 6))
            magPath.closeSubpath()
            
            // Combine and draw gun
            var fullGun = Path()
            fullGun.addPath(gunPath)
            fullGun.addPath(recPath)
            fullGun.addPath(sightPath)
            fullGun.addPath(barrelPath)
            fullGun.addPath(gripPath)
            fullGun.addPath(magPath)
            
            // Gun drop shadow/glow
            context.stroke(fullGun, with: .color(Color.black.opacity(0.8)), lineWidth: 3.5)
            context.fill(fullGun, with: .color(gunColor))
            context.stroke(fullGun, with: .color(gunColor.opacity(0.9)), lineWidth: 1.5)
            
            // 4. Center Crosshair Reticle
            var crosshair = Path()
            crosshair.move(to: CGPoint(x: cx - 15, y: cy))
            crosshair.addLine(to: CGPoint(x: cx + 15, y: cy))
            crosshair.move(to: CGPoint(x: cx, y: cy - 15))
            crosshair.addLine(to: CGPoint(x: cx, y: cy + 15))
            context.stroke(crosshair, with: .color(Color.red.opacity(0.6)), lineWidth: 1)
        }
        .frame(height: 220)
        .background(Color(red: 0.04, green: 0.05, blue: 0.08))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
