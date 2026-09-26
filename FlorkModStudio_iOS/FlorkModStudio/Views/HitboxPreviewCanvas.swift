import SwiftUI

public struct HitboxPreviewCanvas: View {
    public let headRadius: Float
    public let headCenterX: Float
    public let headCenterY: Float
    public let spineRadius: Float
    public let spineHeight: Float
    
    @State private var viewMode: Int = 0 // 0: Hình ảnh 3D, 1: Radar 2D
    
    public init(headRadius: Float, headCenterX: Float, headCenterY: Float, spineRadius: Float, spineHeight: Float) {
        self.headRadius = headRadius
        self.headCenterX = headCenterX
        self.headCenterY = headCenterY
        self.spineRadius = spineRadius
        self.spineHeight = spineHeight
    }
    
    // Helper to safely load image from bundle or assets
    private var mannequinImage: UIImage? {
        if let img = UIImage(named: "hitbox_mannequin") {
            return img
        }
        if let path = Bundle.main.path(forResource: "hitbox_mannequin", ofType: "jpg") {
            return UIImage(contentsOfFile: path)
        }
        return nil
    }
    
    public var body: some View {
        VStack(spacing: 10) {
            HStack {
                Picker("Chế độ xem trước", selection: $viewMode) {
                    Text("Nhân vật").tag(0)
                    Text("Sơ đồ 2D").tag(1)
                }.pickerStyle(.segmented)
                // Status badge
                Text(headCenterX > 0.08 ? "BẮN BỤNG=HEAD" : (headRadius > 0.09 ? "ĐẦU TO +68%" : (spineRadius > 0.5 ? "MAGIC BULLET" : "CHUẨN GỐC")))
                    .font(.system(size: 9, weight: .heavy))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.yellow.opacity(0.18))
                    .foregroundColor(.yellow)
                    .cornerRadius(6)
            }
            
            // Canvas / Character View Frame
            ZStack {
                // Background Container
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.04, green: 0.05, blue: 0.08))
                
                // Background Grid Lines
                Canvas { context, size in
                    let step: CGFloat = 20.0
                    var gp = Path()
                    var x: CGFloat = 0
                    while x <= size.width {
                        gp.move(to: CGPoint(x: x, y: 0))
                        gp.addLine(to: CGPoint(x: x, y: size.height))
                        x += step
                    }
                    var y: CGFloat = 0
                    while y <= size.height {
                        gp.move(to: CGPoint(x: 0, y: y))
                        gp.addLine(to: CGPoint(x: size.width, y: y))
                        y += step
                    }
                    context.stroke(gp, with: .color(Color.white.opacity(0.03)), lineWidth: 1)
                }
                
                // LAYER 1: Real Mannequin Character Image or 2D Wireframe
                if viewMode == 0 {
                    // Real high-tech mannequin image
                    if let uiImg = mannequinImage {
                        Image(uiImage: uiImg)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 260)
                            .opacity(0.88)
                            .overlay(
                                // Subtle vignette
                                RadialGradient(
                                    gradient: Gradient(colors: [Color.clear, Color(red: 0.04, green: 0.05, blue: 0.08).opacity(0.6)]),
                                    center: .center,
                                    startRadius: 80,
                                    endRadius: 180
                                )
                            )
                    } else {
                        // Fallback silhouette if image file is missing
                        wireframeCharacterView()
                    }
                } else {
                    // Pure wireframe radar
                    wireframeCharacterView()
                }
                
                // LAYER 2: DYNAMIC INTERACTIVE HITBOX OVERLAY
                GeometryReader { geo in
                    let w = geo.size.width
                    let cx = w / 2.0
                    
                    // Mannequin character exact anatomical anchor points
                    let baseHeadY: CGFloat = 36.0
                    let chestY: CGFloat = 86.0
                    
                    // 1. Spine / Magic Bullet Forcefield
                    let isMagicActive = spineRadius > 0.15
                    let rSpineScaled: CGFloat = {
                        if spineRadius <= 0.15 {
                            return CGFloat(26.0 * (spineRadius / 0.070349))
                        } else {
                            return CGFloat(26.0 + (spineRadius - 0.070349) * 48.0)
                        }
                    }()
                    let spineCenterY = chestY
                    
                    // Magic Bullet sphere
                    Circle()
                        .fill(isMagicActive ? Color.purple.opacity(0.28) : Color.blue.opacity(0.12))
                        .frame(width: rSpineScaled * 2, height: rSpineScaled * 2)
                        .overlay(
                            Circle()
                                .stroke(isMagicActive ? Color.purple : Color.blue.opacity(0.5), lineWidth: isMagicActive ? 2.5 : 1.2)
                        )
                        .overlay(
                            Group {
                                if isMagicActive {
                                    Circle()
                                        .stroke(Color.purple.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                                        .frame(width: rSpineScaled * 2 + 14, height: rSpineScaled * 2 + 14)
                                }
                            }
                        )
                        .position(x: cx, y: spineCenterY)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: spineRadius)
                    
                    // 2. Head Hitbox Reticle & Circle
                    // Baseline centerX in original FF cache is 0.035773 (located on head)
                    // When pulled down (increasing centerX up to 0.15), it moves from head (36px) to chest (86px) and abdomen!
                    let pullDown = CGFloat(headCenterX - 0.035773)
                    let headOffsetY = pullDown * 420.0
                    let targetHeadY = baseHeadY + headOffsetY
                    let targetHeadX = cx + CGFloat(headCenterY * 220.0)
                    
                    // Baseline radius: 0.058863 = 16px radius (diameter 32px matches mannequin head exactly)
                    let rHeadScaled = CGFloat(16.0 * (headRadius / 0.058863))
                    
                    ZStack {
                        // Glowing Head Hitbox Circle
                        Circle()
                            .fill(Color.red.opacity(0.32))
                            .frame(width: rHeadScaled * 2, height: rHeadScaled * 2)
                        
                        Circle()
                            .stroke(
                                headCenterX > 0.06 ? Color.orange : Color.yellow,
                                lineWidth: 2.2
                            )
                            .frame(width: rHeadScaled * 2, height: rHeadScaled * 2)
                        
                        // Crosshair reticle
                        Path { path in
                            path.move(to: CGPoint(x: -rHeadScaled - 4, y: 0))
                            path.addLine(to: CGPoint(x: rHeadScaled + 4, y: 0))
                            path.move(to: CGPoint(x: 0, y: -rHeadScaled - 4))
                            path.addLine(to: CGPoint(x: 0, y: rHeadScaled + 4))
                        }
                        .stroke(headCenterX > 0.06 ? Color.orange : Color.yellow, lineWidth: 1.2)
                        
                        // Center dot
                        Circle()
                            .fill(Color.red)
                            .frame(width: 5, height: 5)
                        
                        // Trajectory line if pulled down
                        if headCenterX > 0.045 {
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: 0))
                                path.addLine(to: CGPoint(x: 0, y: -headOffsetY))
                            }
                            .stroke(Color.orange.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        }
                    }
                    .position(x: targetHeadX, y: targetHeadY)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: headCenterX)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: headRadius)
                }
                
                // Overlay HUD Data
                VStack {
                    HStack {
                        HStack(spacing: 5) {
                            Circle().fill(Color.yellow).frame(width: 6, height: 6)
                            Text("Đầu: \(String(format: "%.3f", headRadius))m")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.yellow)
                            Text("(X: \(String(format: "%.3f", headCenterX)))")
                                .font(.system(size: 9))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        HStack(spacing: 5) {
                            Circle().fill(Color.purple).frame(width: 6, height: 6)
                            Text("Thân/Magic: \(String(format: "%.2f", spineRadius))m")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.purple)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 8)
                    
                    Spacer()
                    
                    // Bottom Description
                    HStack {
                        if headCenterX > 0.08 {
                            Label("Tâm đầu tụt xuống ngực/bụng (Bắn trúng thân = tính Headshot!)", systemImage: "flame.fill")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.orange)
                        } else if headRadius > 0.09 {
                            Label("Đầu to mở rộng +68% (Ghim tâm dễ dính đầu)", systemImage: "target")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.yellow)
                        } else if spineRadius > 0.5 {
                            Label("Magic Bullet phình to 1.07m (Bắn lệch ngoài vẫn trúng)", systemImage: "sparkles")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.cyan)
                        } else {
                            Label("Thông số gốc chuẩn Unity Free Fire", systemImage: "checkmark.shield")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.green)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
                }
            }
            .frame(height: 270)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        }
    }
    
    // Wireframe Fallback view
    private func wireframeCharacterView() -> some View {
        Canvas { context, size in
            let cx = size.width / 2.0
            let baseHeadY: CGFloat = 36.0
            let chestY: CGFloat = 86.0
            let pelvisY: CGFloat = 138.0
            let feetY: CGFloat = 245.0
            
            var bodyBones = Path()
            // Shoulders & Spine
            bodyBones.move(to: CGPoint(x: cx - 35, y: chestY - 15))
            bodyBones.addLine(to: CGPoint(x: cx + 35, y: chestY - 15))
            bodyBones.move(to: CGPoint(x: cx, y: baseHeadY + 14))
            bodyBones.addLine(to: CGPoint(x: cx, y: pelvisY))
            
            // Arms
            bodyBones.move(to: CGPoint(x: cx - 35, y: chestY - 15))
            bodyBones.addLine(to: CGPoint(x: cx - 48, y: chestY + 25))
            bodyBones.addLine(to: CGPoint(x: cx - 52, y: chestY + 65))
            bodyBones.move(to: CGPoint(x: cx + 35, y: chestY - 15))
            bodyBones.addLine(to: CGPoint(x: cx + 48, y: chestY + 25))
            bodyBones.addLine(to: CGPoint(x: cx + 52, y: chestY + 65))
            
            // Legs
            bodyBones.move(to: CGPoint(x: cx, y: pelvisY))
            bodyBones.addLine(to: CGPoint(x: cx - 22, y: pelvisY + 45))
            bodyBones.addLine(to: CGPoint(x: cx - 26, y: feetY))
            bodyBones.move(to: CGPoint(x: cx, y: pelvisY))
            bodyBones.addLine(to: CGPoint(x: cx + 22, y: pelvisY + 45))
            bodyBones.addLine(to: CGPoint(x: cx + 26, y: feetY))
            
            context.stroke(bodyBones, with: .color(Color.cyan.opacity(0.5)), lineWidth: 3)
            
            // Head base outline
            let charHead = Path(ellipseIn: CGRect(x: cx - 16, y: baseHeadY - 16, width: 32, height: 32))
            context.fill(charHead, with: .color(Color.cyan.opacity(0.2)))
            context.stroke(charHead, with: .color(Color.cyan.opacity(0.7)), lineWidth: 1.5)
        }
    }
}
