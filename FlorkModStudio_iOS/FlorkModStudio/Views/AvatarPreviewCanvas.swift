import SwiftUI

public struct AvatarPreviewCanvas: View {
    public let targetBone: String
    public let scaleVal: Double
    public let posX: Double
    public let posY: Double
    public let posZ: Double
    public let isAntena: Bool
    public let modBigGun: Bool
    public let gunScale: Double
    public let accentColor: Color
    public var onSelectJoint: ((String) -> Void)? = nil
    
    @State private var pulseAnimation: Bool = false
    
    public init(
        targetBone: String,
        scaleVal: Double,
        posX: Double = -0.1566203,
        posY: Double = 0.0,
        posZ: Double = 0.0,
        isAntena: Bool = false,
        modBigGun: Bool = false,
        gunScale: Double = 3.5,
        accentColor: Color = .red,
        onSelectJoint: ((String) -> Void)? = nil
    ) {
        self.targetBone = targetBone
        self.scaleVal = scaleVal
        self.posX = posX
        self.posY = posY
        self.posZ = posZ
        self.isAntena = isAntena
        self.modBigGun = modBigGun
        self.gunScale = gunScale
        self.accentColor = accentColor
        self.onSelectJoint = onSelectJoint
    }
    
    // Joint target coordinates relative to viewBox (280 x 350)
    private var baseJointPoint: (x: CGFloat, y: CGFloat) {
        switch targetBone {
        case "bone_Head":
            return (140.0, 42.0)
        case "bone_Neck":
            return (140.0, 76.0)
        case "bone_Spine1":
            return (140.0, 108.0)
        case "bone_Spine":
            return (140.0, 145.0)
        case "bone_Hips":
            return (140.0, 185.0)
        case "bone_Legs", "bone_LeftLegUpper":
            return (140.0, 250.0)
        case "bone_Arms", "bone_LeftArm":
            return (70.0, 142.0)
        default:
            return (140.0, 42.0)
        }
    }
    
    private var defaultJointPosX: Double {
        switch targetBone {
        case "bone_Head": return -0.1566203
        case "bone_Neck": return -0.086620286
        case "bone_Spine1": return -0.04
        case "bone_Spine": return 0.0
        case "bone_Hips": return 0.20
        default: return -0.1566203
        }
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Header Bar
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "figure.walk")
                        .foregroundColor(.cyan)
                    Text("Xem trước Avatar")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.cyan)
                }
                
                Spacer()
                
                // Target Badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 7, height: 7)
                    Text(jointLabel(for: targetBone))
                        .font(.system(size: 9.5, weight: .heavy))
                        .foregroundColor(accentColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(accentColor.opacity(0.15))
                .cornerRadius(6)
            }
            
            // Visualizer Canvas ViewBox (280 x 350 standard)
            ZStack {
                // Background Dark Cyber Grid
                Color(red: 0.03, green: 0.04, blue: 0.07)
                
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    let cx = w / 2.0
                    let s: CGFloat = min(w / 280.0, h / 350.0)
                    
                    // Transformation helper from SVG (280 x 350) space to Canvas space
                    // X is centered at cx
                    let mapX = { (svgX: CGFloat) -> CGFloat in
                        return cx + (svgX - 140.0) * s
                    }
                    let mapY = { (svgY: CGFloat) -> CGFloat in
                        return svgY * s
                    }
                    
                    ZStack {
                        // 1. Grid Background Pattern
                        Canvas { ctx, size in
                            let step: CGFloat = 20.0 * s
                            var p = Path()
                            var x: CGFloat = 0
                            while x <= size.width {
                                p.move(to: CGPoint(x: x, y: 0))
                                p.addLine(to: CGPoint(x: x, y: size.height))
                                x += step
                            }
                            var y: CGFloat = 0
                            while y <= size.height {
                                p.move(to: CGPoint(x: 0, y: y))
                                p.addLine(to: CGPoint(x: size.width, y: y))
                                y += step
                            }
                            ctx.stroke(p, with: .color(Color.white.opacity(0.025)), lineWidth: 1)
                        }
                        
                        // 2. Skeleton Connection Lines (Exact dpi coordinates)
                        Path { path in
                            // Spine column (Head -> Neck -> Spine1 -> Spine -> Hips)
                            path.move(to: CGPoint(x: mapX(140), y: mapY(48)))
                            path.addLine(to: CGPoint(x: mapX(140), y: mapY(76)))
                            
                            path.move(to: CGPoint(x: mapX(140), y: mapY(76)))
                            path.addLine(to: CGPoint(x: mapX(140), y: mapY(108)))
                            
                            path.move(to: CGPoint(x: mapX(140), y: mapY(108)))
                            path.addLine(to: CGPoint(x: mapX(140), y: mapY(145)))
                            
                            path.move(to: CGPoint(x: mapX(140), y: mapY(145)))
                            path.addLine(to: CGPoint(x: mapX(140), y: mapY(185)))
                            
                            // Shoulders & Arms
                            path.move(to: CGPoint(x: mapX(140), y: mapY(88)))
                            path.addLine(to: CGPoint(x: mapX(95), y: mapY(98)))
                            path.addLine(to: CGPoint(x: mapX(70), y: mapY(142)))
                            path.addLine(to: CGPoint(x: mapX(48), y: mapY(186)))
                            
                            path.move(to: CGPoint(x: mapX(140), y: mapY(88)))
                            path.addLine(to: CGPoint(x: mapX(185), y: mapY(98)))
                            path.addLine(to: CGPoint(x: mapX(210), y: mapY(142)))
                            path.addLine(to: CGPoint(x: mapX(232), y: mapY(186)))
                            
                            // Pelvis & Legs
                            path.move(to: CGPoint(x: mapX(140), y: mapY(185)))
                            path.addLine(to: CGPoint(x: mapX(110), y: mapY(235)))
                            path.addLine(to: CGPoint(x: mapX(105), y: mapY(295)))
                            path.addLine(to: CGPoint(x: mapX(95), y: mapY(330)))
                            
                            path.move(to: CGPoint(x: mapX(140), y: mapY(185)))
                            path.addLine(to: CGPoint(x: mapX(170), y: mapY(235)))
                            path.addLine(to: CGPoint(x: mapX(175), y: mapY(295)))
                            path.addLine(to: CGPoint(x: mapX(185), y: mapY(330)))
                            
                            // Wire from Left Hand to Original socket
                            path.move(to: CGPoint(x: mapX(48), y: mapY(186)))
                            path.addLine(to: CGPoint(x: mapX(35), y: mapY(200)))
                        }
                        .stroke(Color.gray.opacity(0.35), style: StrokeStyle(lineWidth: 2 * s, lineCap: .round))
                        
                        // 3. Socket Redirect Wire (Yellow dashed wire from Left Hand to Target Bone)
                        let targetSvg = baseJointPoint
                        let deltaX = CGFloat(posX - defaultJointPosX)
                        let targetSvgX = targetSvg.x + CGFloat(posZ * 200.0)
                        let targetSvgY: CGFloat = isAntena ? 22.0 : (targetSvg.y + deltaX * 250.0)
                        
                        let targetCanvasX = mapX(targetSvgX)
                        let targetCanvasY = mapY(targetSvgY)
                        
                        Path { path in
                            path.move(to: CGPoint(x: mapX(35), y: mapY(200)))
                            path.addLine(to: CGPoint(x: targetCanvasX, y: targetCanvasY))
                        }
                        .stroke(Color.yellow.opacity(0.75), style: StrokeStyle(lineWidth: 1.6 * s, dash: [4 * s, 3 * s]))
                        
                        // 4. Antena Beam (If active)
                        if isAntena {
                            Path { path in
                                path.move(to: CGPoint(x: targetCanvasX, y: targetCanvasY))
                                path.addLine(to: CGPoint(x: targetCanvasX, y: mapY(10)))
                            }
                            .stroke(
                                LinearGradient(colors: [Color.yellow, Color.cyan, Color.clear], startPoint: .bottom, endPoint: .top),
                                style: StrokeStyle(lineWidth: 2.2 * s, dash: [4 * s, 2 * s])
                            )
                            
                            ForEach(0..<3) { i in
                                Circle()
                                    .stroke(Color.yellow.opacity(0.5 - Double(i) * 0.12), lineWidth: 1.2 * s)
                                    .frame(width: CGFloat(14 + i * 12) * s, height: CGFloat(14 + i * 12) * s)
                                    .position(x: targetCanvasX, y: mapY(18))
                            }
                        }
                        
                        // 5. Big Weapon Socket Indicator (If enabled)
                        if modBigGun {
                            let rHandX = mapX(232)
                            let rHandY = mapY(186)
                            let rSize = CGFloat(16.0 * (gunScale / 2.0)) * s
                            
                            Circle()
                                .stroke(Color.orange.opacity(0.8), lineWidth: 1.5 * s)
                                .frame(width: rSize, height: rSize)
                                .position(x: rHandX, y: rHandY)
                            
                            Image(systemName: "flame.fill")
                                .font(.system(size: 9 * s))
                                .foregroundColor(.orange)
                                .position(x: rHandX, y: rHandY)
                        }
                        
                        // 6. Dynamic Hitbox Collision Circle (Exact Center on Target Joint)
                        let baseHitboxR: CGFloat = 18.0 * s
                        let finalHitboxR = baseHitboxR * CGFloat(scaleVal)
                        
                        // Halo fill
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [accentColor.opacity(0.35), accentColor.opacity(0.02)],
                                    center: .center,
                                    startRadius: 2,
                                    endRadius: finalHitboxR
                                )
                            )
                            .frame(width: finalHitboxR * 2, height: finalHitboxR * 2)
                            .position(x: targetCanvasX, y: targetCanvasY)
                        
                        // Outer dashed border
                        Circle()
                            .stroke(accentColor.opacity(0.9), style: StrokeStyle(lineWidth: 2 * s, dash: [5 * s, 3 * s]))
                            .frame(width: finalHitboxR * 2, height: finalHitboxR * 2)
                            .position(x: targetCanvasX, y: targetCanvasY)
                            .shadow(color: accentColor.opacity(0.7), radius: 6 * s)
                        
                        // Center crosshair
                        Path { path in
                            path.move(to: CGPoint(x: targetCanvasX - 10 * s, y: targetCanvasY))
                            path.addLine(to: CGPoint(x: targetCanvasX + 10 * s, y: targetCanvasY))
                            path.move(to: CGPoint(x: targetCanvasX, y: targetCanvasY - 10 * s))
                            path.addLine(to: CGPoint(x: targetCanvasX, y: targetCanvasY + 10 * s))
                        }
                        .stroke(Color.white.opacity(0.95), lineWidth: 1.2 * s)
                        
                        // 7. Interactive Joint Nodes (Exact dpi SVG joints)
                        Group {
                            // HEAD Node (cx: 140, cy: 42)
                            jointNodeView(
                                title: "HEAD",
                                svgX: 140,
                                svgY: 42,
                                outerR: 16 * s,
                                innerR: 5 * s,
                                color: .red,
                                isTarget: (targetBone == "bone_Head" && !isAntena),
                                mapX: mapX,
                                mapY: mapY,
                                onTapped: { onSelectJoint?("aimbot_head") }
                            )
                            
                            // NECK Node (cx: 140, cy: 76)
                            jointNodeView(
                                title: "NECK",
                                svgX: 140,
                                svgY: 76,
                                outerR: 14 * s,
                                innerR: 5 * s,
                                color: .cyan,
                                isTarget: (targetBone == "bone_Neck"),
                                mapX: mapX,
                                mapY: mapY,
                                onTapped: { onSelectJoint?("aimbot_neck") }
                            )
                            
                            // DRAG / Spine1 Node (cx: 140, cy: 108)
                            jointNodeView(
                                title: "DRAG",
                                svgX: 140,
                                svgY: 108,
                                outerR: 13 * s,
                                innerR: 4 * s,
                                color: .indigo,
                                isTarget: (targetBone == "bone_Spine1"),
                                mapX: mapX,
                                mapY: mapY,
                                onTapped: { onSelectJoint?("aim_body_spine1") }
                            )
                            
                            // BODY HS / Spine Node (cx: 140, cy: 145)
                            jointNodeView(
                                title: "BODY HS",
                                svgX: 140,
                                svgY: 145,
                                outerR: 16 * s,
                                innerR: 6 * s,
                                color: .red,
                                isTarget: (targetBone == "bone_Spine"),
                                mapX: mapX,
                                mapY: mapY,
                                onTapped: { onSelectJoint?("aim_body_all_hs") }
                            )
                            
                            // HIPS HS Node (cx: 140, cy: 185)
                            jointNodeView(
                                title: "HIPS HS",
                                svgX: 140,
                                svgY: 185,
                                outerR: 13 * s,
                                innerR: 4 * s,
                                color: .orange,
                                isTarget: (targetBone == "bone_Hips"),
                                mapX: mapX,
                                mapY: mapY,
                                onTapped: { onSelectJoint?("aim_hips_hs") }
                            )
                            
                            // LEGS HS Nodes (cx: 110 & 170, cy: 250)
                            legsNodeView(
                                svgY: 250,
                                s: s,
                                mapX: mapX,
                                mapY: mapY,
                                isTarget: (targetBone == "bone_Legs"),
                                onTapped: { onSelectJoint?("aim_legs_hs") }
                            )
                            
                            // ARMS HS Nodes (cx: 70 & 210, cy: 142)
                            armsNodeView(
                                svgY: 142,
                                s: s,
                                mapX: mapX,
                                mapY: mapY,
                                isTarget: (targetBone == "bone_Arms"),
                                onTapped: { onSelectJoint?("aim_arms_hs") }
                            )
                            
                            // Original Weapon Socket (Left Hand: 35, 200)
                            origSocketView(
                                svgX: 35,
                                svgY: 200,
                                s: s,
                                mapX: mapX,
                                mapY: mapY
                            )
                        }
                    }
                }
                
                // Bottom HUD Status Bar
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        HStack(spacing: 3) {
                            Text("Khớp:")
                                .foregroundColor(.gray)
                            Text(targetBone)
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        }
                        
                        Text("•")
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 3) {
                            Text("Scale:")
                                .foregroundColor(.gray)
                            Text(String(format: "%.2fx", scaleVal))
                                .foregroundColor(accentColor)
                                .fontWeight(.bold)
                        }
                        
                        Text("•")
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 3) {
                            Text("XYZ:")
                                 .foregroundColor(.gray)
                            Text(String(format: "%+.3f, %+.3f, %+.3f", posX, posY, posZ))
                                 .foregroundColor(.cyan)
                                 .font(.system(size: 9, design: .monospaced))
                                 .fontWeight(.bold)
                        }
                    }
                    .font(.system(size: 9.5))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 1))
                    .padding(.bottom, 6)
                }
            }
            .frame(height: 340)
            .cornerRadius(24)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.1), lineWidth: 1))
            
            // Instruction Hint
            Text("💡 Bấm trực tiếp vào HEAD / NECK / BODY / HIPS / LEGS / ARMS trên sơ đồ để chọn!")
                .font(.system(size: 9.5))
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Subviews for Joint Nodes
    private func jointNodeView(
        title: String,
        svgX: CGFloat,
        svgY: CGFloat,
        outerR: CGFloat,
        innerR: CGFloat,
        color: Color,
        isTarget: Bool,
        mapX: (CGFloat) -> CGFloat,
        mapY: (CGFloat) -> CGFloat,
        onTapped: @escaping () -> Void
    ) -> some View {
        let x = mapX(svgX)
        let y = mapY(svgY)
        
        return ZStack {
            // Outer Ring
            Circle()
                .fill(Color(red: 0.06, green: 0.08, blue: 0.14).opacity(0.95))
                .frame(width: outerR * 2, height: outerR * 2)
            
            Circle()
                .stroke(isTarget ? color : color.opacity(0.6), lineWidth: isTarget ? 2.5 : 1.5)
                .frame(width: outerR * 2, height: outerR * 2)
                .shadow(color: isTarget ? color.opacity(0.8) : Color.clear, radius: 4)
            
            // Inner Core Dot
            Circle()
                .fill(color)
                .frame(width: innerR * 2, height: innerR * 2)
            
            // Title label
            Text(title)
                .font(.system(size: max(6.5, outerR * 0.45), weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .offset(y: outerR + 6)
        }
        .position(x: x, y: y)
        .onTapGesture {
            onTapped()
        }
    }
    
    private func legsNodeView(
        svgY: CGFloat,
        s: CGFloat,
        mapX: (CGFloat) -> CGFloat,
        mapY: (CGFloat) -> CGFloat,
        isTarget: Bool,
        onTapped: @escaping () -> Void
    ) -> some View {
        let y = mapY(svgY)
        let r: CGFloat = 11.0 * s
        let lX = mapX(110)
        let rX = mapX(170)
        let midX = mapX(140)
        
        return ZStack {
            // Left leg circle
            Circle()
                .fill(Color(red: 0.06, green: 0.08, blue: 0.14))
                .frame(width: r * 2, height: r * 2)
                .overlay(Circle().stroke(Color.red.opacity(isTarget ? 0.9 : 0.6), lineWidth: isTarget ? 2.2 : 1.2))
                .position(x: lX, y: y)
            
            // Right leg circle
            Circle()
                .fill(Color(red: 0.06, green: 0.08, blue: 0.14))
                .frame(width: r * 2, height: r * 2)
                .overlay(Circle().stroke(Color.red.opacity(isTarget ? 0.9 : 0.6), lineWidth: isTarget ? 2.2 : 1.2))
                .position(x: rX, y: y)
            
            // Label
            Text("LEGS HS")
                .font(.system(size: 7.0 * s, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .position(x: midX, y: y)
        }
        .onTapGesture {
            onTapped()
        }
    }
    
    private func armsNodeView(
        svgY: CGFloat,
        s: CGFloat,
        mapX: (CGFloat) -> CGFloat,
        mapY: (CGFloat) -> CGFloat,
        isTarget: Bool,
        onTapped: @escaping () -> Void
    ) -> some View {
        let y = mapY(svgY)
        let r: CGFloat = 10.0 * s
        let lX = mapX(70)
        let rX = mapX(210)
        
        return ZStack {
            // Left arm
            Circle()
                .fill(Color(red: 0.06, green: 0.08, blue: 0.14))
                .frame(width: r * 2, height: r * 2)
                .overlay(Circle().stroke(Color.red.opacity(isTarget ? 0.9 : 0.6), lineWidth: isTarget ? 2.2 : 1.2))
                .position(x: lX, y: y)
            
            Text("ARM L")
                .font(.system(size: 6.0 * s, design: .monospaced))
                .foregroundColor(.white)
                .position(x: lX, y: y + 14 * s)
            
            // Right arm
            Circle()
                .fill(Color(red: 0.06, green: 0.08, blue: 0.14))
                .frame(width: r * 2, height: r * 2)
                .overlay(Circle().stroke(Color.red.opacity(isTarget ? 0.9 : 0.6), lineWidth: isTarget ? 2.2 : 1.2))
                .position(x: rX, y: y)
            
            Text("ARM R")
                .font(.system(size: 6.0 * s, design: .monospaced))
                .foregroundColor(.white)
                .position(x: rX, y: y + 14 * s)
        }
        .onTapGesture {
            onTapped()
        }
    }
    
    private func origSocketView(
        svgX: CGFloat,
        svgY: CGFloat,
        s: CGFloat,
        mapX: (CGFloat) -> CGFloat,
        mapY: (CGFloat) -> CGFloat
    ) -> some View {
        let x = mapX(svgX)
        let y = mapY(svgY)
        let r: CGFloat = 7.0 * s
        
        return ZStack {
            Circle()
                .fill(Color.yellow.opacity(0.85))
                .frame(width: r * 2, height: r * 2)
            
            Text("Gốc (Tay L)")
                .font(.system(size: 7.5 * s, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow)
                .offset(y: 12 * s)
        }
        .position(x: x, y: y)
    }
    
    private func jointLabel(for bone: String) -> String {
        switch bone {
        case "bone_Head": return isAntena ? "ANTENA BEACON" : "KHÓA ĐỈNH ĐẦU (HEAD)"
        case "bone_Neck": return "HẠ CỔ (NECK HS)"
        case "bone_Spine1": return "THƯỢNG THÂN (DRAG)"
        case "bone_Spine": return "TOÀN THÂN (BODY HS)"
        case "bone_Hips": return "VÙNG HÔNG (HIPS HS)"
        case "bone_Legs": return "VÙNG CHÂN (LEGS HS)"
        case "bone_Arms": return "CÁNH TAY (ARMS HS)"
        default: return bone.replacingOccurrences(of: "bone_", with: "")
        }
    }
}
