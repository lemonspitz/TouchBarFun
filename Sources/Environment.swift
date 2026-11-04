import AppKit

// MARK: - Scenery definitions

enum FarLayer { case hills, mountains, dunes, skyline, pines, sea, reef, candyHills, sakuraHills, ridges }
enum GroundStyle { case grass, sand, snow, asphalt, lunar, frosting, seabed, forestFloor }
enum AmbientKind { case butterfly, firefly, snow, leaf, petal, bubble, fish, sprinkle, shootingStar, seagull }

struct Environment {
    let id: String
    let name: String
    let emoji: String
    let day: (UInt32, UInt32)          // sky top, bottom
    let night: (UInt32, UInt32)
    var alwaysNight = false
    let far: FarLayer
    let farDay: [UInt32]
    let farNight: [UInt32]
    let ground: GroundStyle
    let groundDay: (UInt32, UInt32)    // fill, detail
    let groundNight: (UInt32, UInt32)
    let decor: [Decor]
    let ambientDay: [AmbientKind]
    let ambientNight: [AmbientKind]
    var clouds: UInt32? = 0xFFFFFF
    var sun = false
    var stars = true
    var planets = false
    var lightRays = false

    static let all: [Environment] = [meadow, beach, snow, desert, forest, city, sakura, space, underwater, candy]
    static func byID(_ id: String?) -> Environment { all.first { $0.id == id } ?? meadow }

    static let meadow = Environment(
        id: "meadow", name: "Meadow", emoji: "🌼", day: (0x1B3A5C, 0x2C5F7F), night: (0x05071A, 0x10142E),
        far: .hills, farDay: [0x2F6B4A, 0x3E7E52], farNight: [0x14281F, 0x1A3326],
        ground: .grass, groundDay: (0x2F7A3A, 0x4CA455), groundNight: (0x163A22, 0x1F5530),
        decor: [.tree, .bush, .flowerRed, .flowerYellow, .tree, .flowerBlue, .bush],
        ambientDay: [.butterfly], ambientNight: [.firefly])

    static let beach = Environment(
        id: "beach", name: "Beach", emoji: "🏖", day: (0x1E5F99, 0x4FA3D1), night: (0x070B22, 0x15224A),
        far: .sea, farDay: [0x1C6EA4, 0x8FD0F2, 0x2E5E3E], farNight: [0x0E2C4F, 0x3A6A9A, 0x12261A],
        ground: .sand, groundDay: (0xE3C48A, 0xC9A66B), groundNight: (0x7A6A4A, 0x5E5038),
        decor: [.palm, .sandcastle, .shell, .palm, .shell],
        ambientDay: [.seagull], ambientNight: [], sun: true)

    static let snow = Environment(
        id: "snow", name: "Snowy Peaks", emoji: "❄️", day: (0x3B5A7A, 0x8FB1CC), night: (0x0A1024, 0x1C2A48),
        far: .mountains, farDay: [0x4F607A, 0x3A4A62, 0xF2F6FA], farNight: [0x2A3550, 0x1F2840, 0xB8C6DA],
        ground: .snow, groundDay: (0xDDE8F3, 0xFFFFFF), groundNight: (0x8FA0B8, 0xC8D4E4),
        decor: [.snowPine, .snowman, .snowPine, .rock, .snowPine],
        ambientDay: [.snow], ambientNight: [.snow], clouds: 0xE0E6EE)

    static let desert = Environment(
        id: "desert", name: "Desert", emoji: "🏜", day: (0x3A6EA5, 0xE8B07A), night: (0x0B0A24, 0x2A1838),
        far: .dunes, farDay: [0xC98E4E, 0xD9A464, 0xA8743C], farNight: [0x4A3550, 0x5A4060, 0x3A2840],
        ground: .sand, groundDay: (0xE0A960, 0xC78B45), groundNight: (0x6A4A50, 0x553A42),
        decor: [.cactus, .rock, .cactus, .cactus],
        ambientDay: [], ambientNight: [.shootingStar], sun: true)

    static let forest = Environment(
        id: "forest", name: "Forest", emoji: "🌲", day: (0x24493A, 0x5C8F6A), night: (0x040B0A, 0x0E1F1A),
        far: .pines, farDay: [0x1E4A35, 0x163A28], farNight: [0x0A1A14, 0x06120D],
        ground: .forestFloor, groundDay: (0x3A3A1E, 0x55702E), groundNight: (0x1A1C10, 0x263318),
        decor: [.pine, .mushroom, .log, .pine, .bush, .pine],
        ambientDay: [.leaf], ambientNight: [.firefly])

    static let city = Environment(
        id: "city", name: "City", emoji: "🏙", day: (0x4A6A8A, 0xA8C0D0), night: (0x0A0A1E, 0x2A1E3E),
        far: .skyline, farDay: [0x7A8AA0, 0x56657A, 0xCFE3F0], farNight: [0x1C2034, 0x121626, 0xFFE08A],
        ground: .asphalt, groundDay: (0x4A4E59, 0xFFD23F), groundNight: (0x24262E, 0xC9A62E),
        decor: [.lamp, .hydrant, .bench, .lamp, .tree],
        ambientDay: [], ambientNight: [])

    static let sakura = Environment(
        id: "sakura", name: "Sakura Garden", emoji: "🌸", day: (0x6A7FB8, 0xF0C4D8), night: (0x120E2A, 0x3A2440),
        far: .sakuraHills, farDay: [0xB89AC8, 0x9A3A3A], farNight: [0x3A2A4A, 0x4A1E24],
        ground: .grass, groundDay: (0x5A9A5A, 0xF7A8C4), groundNight: (0x24402A, 0x7A4A60),
        decor: [.sakuraTree, .lantern, .flowerPink, .sakuraTree, .flowerPink],
        ambientDay: [.petal], ambientNight: [.petal, .firefly])

    static let space = Environment(
        id: "space", name: "Space", emoji: "🚀", day: (0x020210, 0x0C0A2A), night: (0x020210, 0x0C0A2A), alwaysNight: true,
        far: .ridges, farDay: [0x3A3A4A, 0x2A2A38], farNight: [0x3A3A4A, 0x2A2A38],
        ground: .lunar, groundDay: (0x8A8A96, 0x6A6A78), groundNight: (0x8A8A96, 0x6A6A78),
        decor: [.rocket, .rock, .flag, .rock],
        ambientDay: [.shootingStar], ambientNight: [.shootingStar], clouds: nil, planets: true)

    static let underwater = Environment(
        id: "underwater", name: "Under the Sea", emoji: "🐠", day: (0x0A3A6A, 0x1E7AA8), night: (0x03122A, 0x0A2A48),
        far: .reef, farDay: [0x0E5A6A, 0x13707A], farNight: [0x06303A, 0x0A3C46],
        ground: .seabed, groundDay: (0xD9C08A, 0xB59A6A), groundNight: (0x6A5E48, 0x52483A),
        decor: [.seaweed, .coral, .coralOrange, .shell, .seaweed, .coral],
        ambientDay: [.bubble, .fish], ambientNight: [.bubble, .fish], clouds: nil, stars: false, lightRays: true)

    static let candy = Environment(
        id: "candy", name: "Candy Land", emoji: "🍭", day: (0x8E5BB8, 0xF0A6CA), night: (0x2A1240, 0x5A2A6A),
        far: .candyHills, farDay: [0xFFC4DD, 0xC8F0E0, 0xFFE9A8, 0xD8C4FF], farNight: [0x6A3A6A, 0x3A5A5A, 0x6A5A3A, 0x4A3A6A],
        ground: .frosting, groundDay: (0xF7A8C4, 0xFFFFFF), groundNight: (0x8A4A6A, 0xC8A0B8),
        decor: [.lollipop, .candyCane, .gumdropGreen, .lollipopPurple, .gumdropPink],
        ambientDay: [.sprinkle], ambientNight: [.sprinkle], clouds: 0xFFD6E8, sun: true)
}

// MARK: - Decorations (pixel sprites placed along the ground)

enum Decor: String {
    case tree, bush, flowerRed, flowerYellow, flowerBlue, flowerPink, palm, sandcastle, shell, pine, snowPine, snowman,
         cactus, rock, mushroom, log, lamp, hydrant, bench, sakuraTree, lantern, rocket, flag, seaweed, coral, coralOrange,
         lollipop, lollipopPurple, candyCane, gumdropGreen, gumdropPink

    var rows: [String] {
        switch self {
        case .tree: return ["..ggggg..", ".gglgggg.", "gglggggGg", "ggggggglg", "gGgglgggg", "gggggGggg", ".ggggggg.", "..gGngg..", "....n....", "....n....", "...nnn..."]
        case .bush: return ["..ggg..", ".gglggg", "ggggglg", "gGggggg", ".ggggg."]
        case .flowerRed, .flowerYellow, .flowerBlue, .flowerPink: return [".f.", "fyf", ".f.", ".l.", "ll.", ".l."]
        case .palm: return ["gg....gg..", "lgg..ggl..", "..gggg....", ".gg.nggg..", "gg..n..gg.", "g...n...g.", "....n.....", "....nN....", ".....n....", ".....n....", ".....nN...", "......n...", ".....nnn.."]
        case .sandcastle: return ["...r...", "...k...", "t.ttt.t", "ttttttt", ".ttttt.", ".ttNtt.", "tttNttt"]
        case .shell: return [".pPp.", "pPpPp", "PpPpP", ".P.P."]
        case .pine: return ["...G...", "..GGG..", ".GGgGG.", "..GGG..", ".GGGgG.", "GGgGGGG", "..GGG..", ".GGgGG.", "GGGGGgG", "...N...", "...N..."]
        case .snowPine: return ["...s...", "..sGs..", ".GGsGG.", "..sGs..", ".sGGGs.", "GGsGGsG", "..sGs..", ".sGGGs.", "sGGsGGs", "...N...", "...N..."]
        case .snowman: return ["..KKK..", "..KKK..", ".KKKKK.", "..www..", ".wewew.", ".wwoww.", "..www..", ".wwwww.", "wwwKwww", "wwwwwww", "wwwKwww", ".wwwww."]
        case .cactus: return ["..G..", "..G.G", "G.G.G", "G.GGG", "GGG..", "..G..", "..G..", "..G..", "..G.."]
        case .rock: return [".kkk..", "kkKkk.", "kkkkkK"]
        case .mushroom: return [".rrr.", "rwrrr", "rrrwr", "..w..", ".www."]
        case .log: return [".nnnnnnt", "nNnnNnnt", "nnnnnnnt"]
        case .lamp: return ["KKKK", "KccK", "KKKK", ".KK.", ".KK.", ".KK.", ".KK.", ".KK.", ".KK.", ".KK.", ".KK.", "KKKK"]
        case .hydrant: return [".rr.", "rrrr", ".rr.", "rrrr", ".rr.", "rrrr"]
        case .bench: return ["nnnnnnnnn", ".........", "nnnnnnnnn", "K.......K", "K.......K"]
        case .sakuraTree: return ["..pPp.pp...", ".pppPpppP..", "pPpppppppp.", "pppPpppPppp", ".ppppPpppp.", "..ppNpppp..", "....N.N....", "....NN.....", "....N......", "...NNN....."]
        case .lantern: return ["..k..", ".kkk.", "kkkkk", ".kyk.", ".kkk.", "..k..", ".kkk."]
        case .rocket: return ["..r..", ".rwr.", ".www.", ".wbw.", ".www.", ".www.", "rwwwr", "r.o.r", "..o.."]
        case .flag: return ["Krrrr", "Krwwr", "Krrrr", "K....", "K....", "K....", "K....", "K...."]
        case .seaweed: return []
        case .coral, .coralOrange: return ["P.P..P.", "PP.P.PP", ".PPPPP.", "..PPP..", "..PPP..", ".PPPPP."]
        case .lollipop, .lollipopPurple: return [".rwr.", "rwrwr", "wrwrw", "rwrwr", ".rwr.", "..w..", "..w..", "..w..", "..w..", "..w.."]
        case .candyCane: return [".rwr", "w..w", "r..r", "...w", "...r", "...w", "...r", "...w", "...r"]
        case .gumdropGreen, .gumdropPink: return [".ff.", "ffff", "fwff", "ffff"]
        }
    }

    static let palette: [Character: NSColor] = [
        "g": hex(0x3E8E41), "G": hex(0x2A6430), "l": hex(0x6CC24A), "n": hex(0x7A4E2D), "N": hex(0x5A3820),
        "w": hex(0xF5F5F5), "s": hex(0xEAF2FA), "p": hex(0xF7B8D0), "P": hex(0xE86A9A), "y": hex(0xFFD23F),
        "r": hex(0xE84A5F), "o": hex(0xF0892B), "b": hex(0x5FA8E8), "k": hex(0x9A9FA8), "K": hex(0x4A4E59),
        "c": hex(0xFFF2B0), "t": hex(0xE8C990), "e": hex(0x1A1A1A),
    ]

    var image: CGImage {
        var pal = Decor.palette
        switch self {
        case .flowerRed: pal["f"] = hex(0xE84A5F)
        case .flowerYellow: pal["f"] = hex(0xFFF4C2)
        case .flowerBlue: pal["f"] = hex(0x7FB8FF)
        case .flowerPink: pal["f"] = hex(0xF7A8C4)
        case .coralOrange: pal["P"] = hex(0xF0892B)
        case .lollipopPurple: pal["r"] = hex(0xB04AE8)
        case .gumdropGreen: pal["f"] = hex(0x6CD47A)
        case .gumdropPink: pal["f"] = hex(0xF26FA8)
        default: break
        }
        return PixelArt.image("decor-\(rawValue)", rows: rows, palette: pal, outline: false)
    }

    var scale: CGFloat {
        switch self {
        case .flowerRed, .flowerYellow, .flowerBlue, .flowerPink, .shell, .mushroom, .gumdropGreen, .gumdropPink: return 1.3
        default: return 1.6
        }
    }
}

// MARK: - Ambient particles (snow, petals, fireflies…)

struct AmbientParticle {
    var kind: AmbientKind
    var x: CGFloat, y: CGFloat
    var vx: CGFloat, vy: CGFloat
    var phase: CGFloat
    var life: Double
    var color: NSColor
}

// MARK: - Far background tiles (cached, seamlessly repeating)

enum FarTiles {
    static let period: CGFloat = 512
    static let pxPerUnit: CGFloat = 4
    private static var cache: [String: CGImage] = [:]

    static func tile(_ env: Environment, night: Bool) -> CGImage {
        let key = "\(env.id)-\(night)"
        if let img = cache[key] { return img }
        let P = period
        let ctx = CGContext(data: nil, width: Int(P * pxPerUnit), height: Int(World.H * pxPerUnit), bitsPerComponent: 8,
                            bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.scaleBy(x: pxPerUnit, y: pxPerUnit)
        let cols = (night ? env.farNight : env.farDay).map { hex($0) }
        var rng = SeededRandom(seed: env.id.unicodeScalars.reduce(UInt64(11)) { $0 &* 31 &+ UInt64($1.value) })
        func rnd(_ lo: CGFloat, _ hi: CGFloat) -> CGFloat { lo + CGFloat(rng.next() % 10000) / 10000 * (hi - lo) }

        func curve(_ color: NSColor, base: CGFloat, _ terms: [(CGFloat, CGFloat, CGFloat)]) {
            ctx.setFillColor(color.cgColor)
            ctx.move(to: .zero)
            var x: CGFloat = 0
            while x <= P {
                let y = base + terms.reduce(0) { $0 + $1.1 * sin(2 * .pi * $1.0 * x / P + $1.2) }
                ctx.addLine(to: CGPoint(x: x, y: y))
                x += 2
            }
            ctx.addLine(to: CGPoint(x: P, y: 0))
            ctx.closePath()
            ctx.fillPath()
        }
        /// Jagged ridge line through random peaks; `cap` adds snow on the tall ones.
        func ridge(_ color: NSColor, lo: CGFloat, hi: CGFloat, step: ClosedRange<CGFloat>, cap: NSColor?) {
            var pts: [CGPoint] = []
            var x: CGFloat = 0
            while x < P {
                pts.append(CGPoint(x: x, y: rnd(lo, hi)))
                pts.append(CGPoint(x: x + rnd(step.lowerBound, step.upperBound) / 2, y: rnd(lo * 0.4, lo)))
                x = pts.last!.x + rnd(step.lowerBound, step.upperBound) / 2
            }
            pts.append(CGPoint(x: P, y: pts[0].y))
            ctx.setFillColor(color.cgColor)
            ctx.move(to: .zero)
            pts.forEach { ctx.addLine(to: $0) }
            ctx.addLine(to: CGPoint(x: P, y: 0))
            ctx.closePath()
            ctx.fillPath()
            guard let cap else { return }
            ctx.setFillColor(cap.cgColor)
            for i in stride(from: 0, to: pts.count - 2, by: 2) where pts[i].y > hi - (hi - lo) * 0.45 {
                let p = pts[i]
                let prev = i > 0 ? pts[i - 1] : CGPoint(x: p.x - 10, y: lo * 0.5)
                let next = pts[i + 1]
                let f: CGFloat = 3.5
                func along(_ q: CGPoint) -> CGPoint {
                    let d = max(p.y - q.y, 0.1)
                    return CGPoint(x: p.x + (q.x - p.x) * f / d, y: p.y - f)
                }
                ctx.move(to: along(prev)); ctx.addLine(to: p); ctx.addLine(to: along(next)); ctx.closePath(); ctx.fillPath()
            }
        }

        switch env.far {
        case .hills:
            curve(cols[0], base: 10, [(2, 3, 0), (5, 1.6, 1)])
            curve(cols[1], base: 6.5, [(3, 2.2, 2), (7, 1, 0.5)])
        case .mountains:
            ridge(cols[0], lo: 10, hi: 24, step: 50...90, cap: cols[2])
            ridge(cols[1], lo: 7, hi: 15, step: 30...60, cap: nil)
        case .ridges:
            ridge(cols[0], lo: 6, hi: 13, step: 40...80, cap: nil)
            ridge(cols[1], lo: 4, hi: 8, step: 25...50, cap: nil)
        case .dunes:
            curve(cols[0], base: 8, [(2, 2.5, 0.3), (4, 1, 1)])
            ctx.setFillColor(cols[2].cgColor)
            for (px, w, h) in [(CGFloat(150), CGFloat(44), CGFloat(18)), (205, 28, 11), (390, 34, 13)] {
                ctx.move(to: CGPoint(x: px - w / 2, y: 3)); ctx.addLine(to: CGPoint(x: px, y: 3 + h))
                ctx.addLine(to: CGPoint(x: px + w / 2, y: 3)); ctx.closePath(); ctx.fillPath()
            }
            curve(cols[1], base: 5, [(3, 1.8, 2), (6, 0.8, 0)])
        case .skyline:
            for (layer, color) in [(0, cols[0]), (1, cols[1])] {
                var x: CGFloat = layer == 0 ? 0 : 6
                while x < P {
                    let w = rnd(12, 26), h = layer == 0 ? rnd(12, 25) : rnd(7, 16)
                    ctx.setFillColor(color.cgColor)
                    ctx.fill(CGRect(x: x, y: 0, width: min(w, P - x), height: h))
                    for wy in stride(from: CGFloat(4), to: h - 1.5, by: 3) {
                        for wx in stride(from: x + 2, to: min(x + w, P) - 1.5, by: 3) where rnd(0, 1) < (night ? 0.4 : 0.2) {
                            ctx.setFillColor(cols[2].withAlphaComponent(layer == 0 ? 0.55 : 0.85).cgColor)
                            ctx.fill(CGRect(x: wx, y: wy, width: 1.2, height: 1.4))
                        }
                    }
                    x += w + rnd(1, 4)
                }
            }
        case .pines:
            for (layer, color) in [(0, cols[0]), (1, cols[1])] {
                var x: CGFloat = 0
                ctx.setFillColor(color.cgColor)
                while x < P {
                    let w = rnd(7, 12), h = layer == 0 ? rnd(12, 22) : rnd(7, 13)
                    for dx in [0, -P] {   // wrap across the seam
                        ctx.move(to: CGPoint(x: x + dx - w / 2, y: 2)); ctx.addLine(to: CGPoint(x: x + dx, y: 2 + h))
                        ctx.addLine(to: CGPoint(x: x + dx + w / 2, y: 2)); ctx.closePath(); ctx.fillPath()
                    }
                    x += rnd(4, 8)
                }
                ctx.fill(CGRect(x: 0, y: 0, width: P, height: 2.5))
            }
        case .sea:
            ctx.setFillColor(cols[0].cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: P, height: 9))
            ctx.setFillColor(cols[2].cgColor)
            ctx.fillEllipse(in: CGRect(x: 300, y: 5, width: 50, height: 8))
            ctx.fill(CGRect(x: 323, y: 9, width: 0.8, height: 6))
            ctx.fillEllipse(in: CGRect(x: 318, y: 14, width: 11, height: 2.2))
            ctx.setFillColor(NSColor(white: 1, alpha: night ? 0.35 : 0.8).cgColor)
            ctx.move(to: CGPoint(x: 120, y: 9.5)); ctx.addLine(to: CGPoint(x: 124, y: 17)); ctx.addLine(to: CGPoint(x: 128, y: 9.5))
            ctx.closePath(); ctx.fillPath()
            ctx.setFillColor(cols[2].cgColor)
            ctx.fill(CGRect(x: 117, y: 8.6, width: 14, height: 1.2))
            ctx.setFillColor(cols[1].withAlphaComponent(0.6).cgColor)
            for _ in 0..<60 { ctx.fill(CGRect(x: rnd(0, P - 5), y: rnd(3.5, 8.5), width: rnd(2, 5), height: 0.4)) }
        case .reef:
            for (layer, color) in [(0, cols[0]), (1, cols[1])] {
                ctx.setFillColor(color.cgColor)
                var x: CGFloat = 0
                while x < P {
                    let r = layer == 0 ? rnd(3, 7) : rnd(2, 4.5)
                    let h = layer == 0 ? rnd(4, 12) : rnd(2, 7)
                    for dx in [0, -P] {
                        ctx.fillEllipse(in: CGRect(x: x + dx - r, y: h - r, width: r * 2, height: r * 2))
                        ctx.fill(CGRect(x: x + dx - r * 0.6, y: 0, width: r * 1.2, height: h))
                    }
                    x += rnd(5, 14)
                }
            }
        case .candyHills:
            var x: CGFloat = 0, i = 0
            for layer in 0..<2 {
                x = layer == 0 ? 0 : 12
                while x < P {
                    let r = layer == 0 ? rnd(9, 14) : rnd(5, 8)
                    let c = cols[i % cols.count]
                    ctx.setFillColor((layer == 0 ? c.withAlphaComponent(0.75) : c).cgColor)
                    for dx in [0, -P] { ctx.fillEllipse(in: CGRect(x: x + dx - r, y: -r * 0.5, width: r * 2, height: r * 2)) }
                    ctx.setFillColor(NSColor(white: 1, alpha: 0.35).cgColor)
                    ctx.fillEllipse(in: CGRect(x: x - r * 0.5, y: r * 1.1, width: r * 0.5, height: r * 0.25))
                    x += r * 1.5
                    i += 1
                }
            }
        case .sakuraHills:
            curve(cols[0], base: 8, [(2, 2.5, 1), (5, 1.2, 0)])
            ctx.setFillColor(cols[1].cgColor)
            // Pagoda
            for (k, w) in [CGFloat(22), 17, 12].enumerated() {
                let y = 6 + CGFloat(k) * 5
                ctx.fill(CGRect(x: 180 - w * 0.3, y: y, width: w * 0.6, height: 4))
                ctx.move(to: CGPoint(x: 180 - w / 2, y: y + 3.5)); ctx.addLine(to: CGPoint(x: 180 + w / 2, y: y + 3.5))
                ctx.addLine(to: CGPoint(x: 180 + w * 0.3, y: y + 5.2)); ctx.addLine(to: CGPoint(x: 180 - w * 0.3, y: y + 5.2))
                ctx.closePath(); ctx.fillPath()
            }
            ctx.fill(CGRect(x: 179.4, y: 21, width: 1.2, height: 4))
            // Torii gate
            ctx.fill(CGRect(x: 395, y: 3, width: 1.4, height: 13))
            ctx.fill(CGRect(x: 408, y: 3, width: 1.4, height: 13))
            ctx.fill(CGRect(x: 392, y: 15.5, width: 20, height: 1.6))
            ctx.fill(CGRect(x: 394, y: 12.5, width: 16, height: 1))
        }
        let img = ctx.makeImage()!
        cache[key] = img
        return img
    }
}

// MARK: - Rendering + simulation

extension World {
    var environment: Environment { Environment.byID(save.environmentID) }
    var nightMode: Bool { environment.alwaysNight || isNightTime }

    func setEnvironment(_ id: String) {
        guard id != environment.id || save.environmentID == nil else { return }
        save.environmentID = id
        ambient.removeAll()
        save.store()
        changed()
    }

    func drawEnvironment(_ ctx: CGContext) {
        let env = environment
        let night = nightMode
        let sky = night ? env.night : env.day
        ctx.draw(RenderCache.sky("\(env.id)-\(night)", top: hex(sky.0), bottom: hex(sky.1)),
                 in: CGRect(x: 0, y: 0, width: World.W, height: World.H))
        let gamesDim: CGFloat = mode == .pet ? 1 : 0.55

        if night && env.stars {
            var rng = SeededRandom(seed: 7)
            for _ in 0..<(env.id == "space" ? 90 : 40) {
                let x = CGFloat(rng.next() % Int(World.W)), y = CGFloat(6 + rng.next() % 24)
                let tw = 0.4 + 0.6 * abs(sin(t * 1.5 + Double(x)))
                ctx.setFillColor(NSColor(white: 1, alpha: CGFloat(tw) * 0.8).cgColor)
                ctx.fill(CGRect(x: x, y: y, width: 0.8, height: 0.8))
            }
        }
        if env.planets { drawPlanets(ctx, alpha: gamesDim) }
        if env.lightRays {
            for i in 0..<4 {
                let cx = World.W * [0.15, 0.38, 0.62, 0.85][i] + CGFloat(sin(t * 0.3 + Double(i))) * 12
                ctx.setFillColor(NSColor(white: 1, alpha: night ? 0.025 : 0.06).cgColor)
                ctx.move(to: CGPoint(x: cx - 4, y: World.H)); ctx.addLine(to: CGPoint(x: cx + 4, y: World.H))
                ctx.addLine(to: CGPoint(x: cx + 14, y: 0)); ctx.addLine(to: CGPoint(x: cx - 6, y: 0))
                ctx.closePath(); ctx.fillPath()
            }
        }
        if mode == .pet { drawCelestial(ctx, env: env, night: night, skyTop: hex(sky.0)) }
        if !night, let cloud = env.clouds {
            for (i, base) in [CGFloat(60), 250, 420].enumerated() {
                var x = (base + CGFloat(t) * (3 + CGFloat(i))).truncatingRemainder(dividingBy: World.W + 60) - 30
                if groundScroll > 0 { x = (base - groundScroll * 0.1).truncatingRemainder(dividingBy: World.W + 60); if x < -30 { x += World.W + 60 } }
                ctx.setFillColor(hex(cloud, 0.16).cgColor)
                ctx.fill(CGRect(x: x, y: 20 + CGFloat(i % 2) * 3, width: 22, height: 3))
                ctx.fill(CGRect(x: x + 5, y: 23 + CGFloat(i % 2) * 3, width: 11, height: 2))
            }
        }

        // Far layer, slowly scrolling.
        let tile = FarTiles.tile(env, night: night)
        let P = FarTiles.period
        var x0 = -(groundScroll * 0.2).truncatingRemainder(dividingBy: P)
        ctx.interpolationQuality = .high
        ctx.setAlpha(mode == .pet ? 1 : 0.8)
        while x0 < World.W { ctx.draw(tile, in: CGRect(x: x0, y: 0, width: P, height: World.H)); x0 += P }
        ctx.setAlpha(1)
        ctx.interpolationQuality = .none

        drawDecor(ctx, env: env, night: night, alpha: (night ? 0.7 : 0.95) * gamesDim)
        drawGround(ctx, env: env, night: night)
        drawAmbient(ctx)
    }

    private func drawCelestial(_ ctx: CGContext, env: Environment, night: Bool, skyTop: NSColor) {
        let mx = (World.W - World.hudWidth) * 0.72
        if night && env.stars && !env.planets {
            ctx.setFillColor(hex(0xF6F1D5).cgColor)
            ctx.fillEllipse(in: CGRect(x: mx, y: 16, width: 9, height: 9))
            ctx.setFillColor(skyTop.cgColor)
            ctx.fillEllipse(in: CGRect(x: mx + 3, y: 18, width: 8, height: 8))
        } else if !night && env.sun {
            ctx.setFillColor(hex(0xFFE58A, 0.25).cgColor)
            ctx.fillEllipse(in: CGRect(x: mx - 3, y: 14, width: 16, height: 16))
            ctx.setFillColor(hex(0xFFE58A).cgColor)
            ctx.fillEllipse(in: CGRect(x: mx + 0.5, y: 17.5, width: 9, height: 9))
        }
    }

    private func drawPlanets(_ ctx: CGContext, alpha: CGFloat) {
        ctx.setAlpha(alpha)
        let px = (World.W - World.hudWidth) * 0.62
        ctx.setFillColor(hex(0xD98C5F).cgColor)
        ctx.fillEllipse(in: CGRect(x: px, y: 13, width: 14, height: 14))
        ctx.setFillColor(hex(0xB06A44).cgColor)
        ctx.fill(CGRect(x: px + 2, y: 19, width: 10, height: 1.2))
        ctx.fill(CGRect(x: px + 1, y: 22, width: 12, height: 0.8))
        ctx.setFillColor(NSColor(white: 0, alpha: 0.35).cgColor)
        ctx.fillEllipse(in: CGRect(x: px + 4, y: 12, width: 12, height: 14))
        let rx = World.W * 0.22
        ctx.setFillColor(hex(0x9FD3E8).cgColor)
        ctx.fillEllipse(in: CGRect(x: rx, y: 20, width: 6, height: 6))
        ctx.setStrokeColor(hex(0xE8D9A8, 0.9).cgColor)
        ctx.setLineWidth(0.6)
        ctx.strokeEllipse(in: CGRect(x: rx - 3, y: 22, width: 12, height: 2))
        ctx.setAlpha(1)
    }

    private static var decorSlots: [String: [(CGFloat, Decor)]] = [:]

    private func drawDecor(_ ctx: CGContext, env: Environment, night: Bool, alpha: CGFloat) {
        let D: CGFloat = 640
        let slots: [(CGFloat, Decor)]
        if let s = World.decorSlots[env.id] { slots = s } else {
            var rng = SeededRandom(seed: 99)
            var list: [(CGFloat, Decor)] = []
            var x: CGFloat = 25
            var i = 0
            while x < D - 20 {
                list.append((x, env.decor[i % env.decor.count]))
                x += CGFloat(55 + rng.next() % 70)
                i += 1
            }
            World.decorSlots[env.id] = list
            slots = list
        }
        let offset = (groundScroll * 0.55).truncatingRemainder(dividingBy: D)
        ctx.setAlpha(alpha)
        var rep: CGFloat = 0
        while rep * D - offset < World.W + 20 {
            for (sx0, d) in slots {
                let sx = sx0 + rep * D - offset
                guard sx > -20 && sx < World.W + 20 else { continue }
                if d == .seaweed {
                    ctx.setStrokeColor(hex(0x2F9E5A).cgColor)
                    ctx.setLineWidth(1.1)
                    for k in 0..<3 {
                        ctx.move(to: CGPoint(x: sx + CGFloat(k) * 2.2, y: World.ground))
                        for seg in 1...6 {
                            let y = World.ground + CGFloat(seg) * 2.2 - CGFloat(k)
                            ctx.addLine(to: CGPoint(x: sx + CGFloat(k) * 2.2 + CGFloat(sin(t * 1.6 + Double(seg) * 0.6 + Double(k))) * CGFloat(seg) * 0.25, y: y))
                        }
                        ctx.strokePath()
                    }
                    continue
                }
                let img = d.image
                let w = CGFloat(img.width) * d.scale, h = CGFloat(img.height) * d.scale
                ctx.draw(img, in: CGRect(x: sx - w / 2, y: World.ground - 0.3, width: w, height: h))
                if d == .lamp && night {
                    ctx.setFillColor(hex(0xFFE08A, 0.22).cgColor)
                    ctx.fillEllipse(in: CGRect(x: sx - 7, y: World.ground + h - 9, width: 14, height: 12))
                }
            }
            rep += 1
        }
        ctx.setAlpha(1)
    }

    private func drawGround(_ ctx: CGContext, env: Environment, night: Bool) {
        let (fillHex, detailHex) = night ? env.groundNight : env.groundDay
        let g = World.ground
        ctx.setFillColor(hex(fillHex).cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: World.W, height: g))
        let detail = hex(detailHex)
        ctx.setFillColor(detail.cgColor)
        let scroll = groundScroll
        func each(_ step: CGFloat, _ body: (CGFloat, Int) -> Void) {
            var x = -(scroll.truncatingRemainder(dividingBy: step))
            var i = Int(scroll / step)
            while x < World.W { body(x, i); x += step; i += 1 }
        }
        switch env.ground {
        case .grass, .forestFloor:
            each(23) { x, i in
                ctx.fill(CGRect(x: x, y: g, width: 1, height: 1))
                ctx.fill(CGRect(x: x + 2, y: g, width: 1, height: 1.6))
                if env.id == "sakura" && i % 2 == 0 { ctx.fill(CGRect(x: x + 9, y: g - 1.4, width: 1.2, height: 0.8)) }
            }
        case .sand, .seabed:
            each(9) { x, i in ctx.fill(CGRect(x: x + CGFloat(i * 7 % 5), y: CGFloat(i * 3 % 3) * 0.8 + 0.3, width: 0.8, height: 0.6)) }
            if env.ground == .seabed {
                ctx.setFillColor(hex(0xF7B8D0, 0.8).cgColor)
                each(71) { x, _ in ctx.fillEllipse(in: CGRect(x: x + 30, y: g - 1, width: 2, height: 1.2)) }
            }
        case .snow:
            ctx.fill(CGRect(x: 0, y: g - 0.6, width: World.W, height: 0.6))
            each(13) { x, i in
                let a = 0.4 + 0.6 * abs(sin(t * 2 + Double(i)))
                ctx.setFillColor(NSColor(white: 1, alpha: CGFloat(a)).cgColor)
                ctx.fill(CGRect(x: x + 4, y: CGFloat(i % 3) * 0.7 + 0.4, width: 0.6, height: 0.6))
            }
        case .asphalt:
            ctx.setFillColor(hex(0x8A8F99).cgColor)
            ctx.fill(CGRect(x: 0, y: g - 0.5, width: World.W, height: 0.5))
            ctx.setFillColor(detail.cgColor)
            each(16) { x, _ in ctx.fill(CGRect(x: x, y: 1.1, width: 8, height: 0.5)) }
        case .lunar:
            ctx.setFillColor(detail.cgColor)
            each(37) { x, i in ctx.fillEllipse(in: CGRect(x: x + CGFloat(i % 4) * 3, y: 0.6 + CGFloat(i % 2) * 0.6, width: 5 + CGFloat(i % 3), height: 1.3)) }
        case .frosting:
            ctx.setFillColor(detail.cgColor)
            ctx.fill(CGRect(x: 0, y: g - 0.7, width: World.W, height: 0.7))
            each(6) { x, i in ctx.fillEllipse(in: CGRect(x: x, y: g - 1.6 - CGFloat(i % 3) * 0.3, width: 3, height: 2)) }
            let sprinkles: [UInt32] = [0xE84A5F, 0x5FA8E8, 0xFFD23F, 0x6CD47A]
            each(5) { x, i in
                ctx.setFillColor(hex(sprinkles[i % 4]).cgColor)
                ctx.fill(CGRect(x: x + 2, y: 0.5 + CGFloat(i % 3) * 0.5, width: 0.9, height: 0.35))
            }
        }
    }

    // MARK: Ambient

    func updateAmbient(_ dt: Double) {
        let env = environment
        let kinds = nightMode ? env.ambientNight : env.ambientDay
        let fdt = CGFloat(dt)
        for i in ambient.indices {
            var p = ambient[i]
            p.life -= dt
            p.phase += fdt
            switch p.kind {
            case .butterfly, .firefly, .fish:
                p.vx += CGFloat.random(in: -12...12) * fdt
                p.vy += CGFloat.random(in: -8...8) * fdt
                p.vx = max(-12, min(12, p.vx)); p.vy = max(-5, min(5, p.vy))
                if p.kind == .fish { p.vy *= 0.5 }
                if p.y < 6 { p.vy = abs(p.vy) }
                if p.y > 26 { p.vy = -abs(p.vy) }
            case .snow, .leaf, .petal, .sprinkle:
                p.x += sin(p.phase * 1.7) * (p.kind == .snow ? 3 : 6) * fdt
            default: break
            }
            p.x += p.vx * fdt
            p.y += p.vy * fdt
            ambient[i] = p
        }
        ambient.removeAll { $0.life <= 0 || $0.y < -2 || $0.y > World.H + 4 || $0.x < -30 || $0.x > World.W + 30 }

        for k in kinds {
            let count = ambient.lazy.filter { $0.kind == k }.count
            let (maxCount, rate): (Int, Double) = {
                switch k {
                case .butterfly: return (3, 0.3)
                case .firefly: return (12, 2)
                case .snow: return (45, 12)
                case .leaf: return (8, 1.2)
                case .petal: return (16, 3)
                case .bubble: return (12, 2.5)
                case .fish: return (4, 0.4)
                case .sprinkle: return (18, 3)
                case .shootingStar: return (1, 0.12)
                case .seagull: return (2, 0.15)
                }
            }()
            guard count < maxCount, Double.random(in: 0..<1) < rate * dt else { continue }
            let x = CGFloat.random(in: 0...World.W)
            switch k {
            case .butterfly:
                let c = [0xFFD23F, 0xF7A8C4, 0xFFFFFF, 0x7FB8FF].randomElement()!
                ambient.append(AmbientParticle(kind: k, x: x, y: CGFloat.random(in: 8...22), vx: 6, vy: 0, phase: 0, life: 14, color: hex(UInt32(c))))
            case .firefly:
                ambient.append(AmbientParticle(kind: k, x: x, y: CGFloat.random(in: 5...24), vx: 0, vy: 0, phase: CGFloat.random(in: 0...6), life: 10, color: hex(0xE8FF8A)))
            case .snow:
                ambient.append(AmbientParticle(kind: k, x: x, y: World.H + 1, vx: CGFloat.random(in: -2...2), vy: -CGFloat.random(in: 4...8),
                                               phase: CGFloat.random(in: 0...6), life: 12, color: NSColor(white: 1, alpha: CGFloat.random(in: 0.6...1))))
            case .leaf, .petal:
                let c: UInt32 = k == .petal ? [0xF7B8D0, 0xFFD6E8, 0xF28BB0].randomElement()! : [0xE8762B, 0xD94A2A, 0xE8B04A].randomElement()!
                ambient.append(AmbientParticle(kind: k, x: x, y: World.H + 1, vx: CGFloat.random(in: -4...6), vy: -CGFloat.random(in: 3...6),
                                               phase: CGFloat.random(in: 0...6), life: 14, color: hex(c)))
            case .sprinkle:
                let c: UInt32 = [0xE84A5F, 0x5FA8E8, 0xFFD23F, 0x6CD47A, 0xFFFFFF].randomElement()!
                ambient.append(AmbientParticle(kind: k, x: x, y: World.H + 1, vx: 0, vy: -CGFloat.random(in: 3...6), phase: CGFloat.random(in: 0...6), life: 14, color: hex(c)))
            case .bubble:
                ambient.append(AmbientParticle(kind: k, x: x, y: -1, vx: 0, vy: CGFloat.random(in: 4...9), phase: CGFloat.random(in: 0...6), life: 12,
                                               color: NSColor(white: 1, alpha: 0.6)))
            case .fish:
                let c: UInt32 = [0xFFB347, 0x7FE0FF, 0xFF7FA8, 0xFFE066].randomElement()!
                let left = Bool.random()
                ambient.append(AmbientParticle(kind: k, x: left ? -10 : World.W + 10, y: CGFloat.random(in: 10...24), vx: left ? 10 : -10, vy: 0,
                                               phase: 0, life: 70, color: hex(c)))
            case .shootingStar:
                ambient.append(AmbientParticle(kind: k, x: x, y: CGFloat.random(in: 18...28), vx: -120, vy: -40, phase: 0, life: 0.6, color: .white))
            case .seagull:
                let left = Bool.random()
                ambient.append(AmbientParticle(kind: k, x: left ? -10 : World.W + 10, y: CGFloat.random(in: 18...26), vx: left ? 18 : -18, vy: 0,
                                               phase: 0, life: 60, color: NSColor(white: 1, alpha: 0.85)))
            }
        }
    }

    private func drawAmbient(_ ctx: CGContext) {
        for p in ambient {
            ctx.setFillColor(p.color.cgColor)
            switch p.kind {
            case .snow:
                ctx.fill(CGRect(x: p.x, y: p.y, width: 0.9, height: 0.9))
            case .leaf, .petal, .sprinkle:
                let w: CGFloat = p.kind == .sprinkle ? 0.4 : 1.4
                let h: CGFloat = p.kind == .sprinkle ? 1.2 : 0.8 + 0.5 * abs(sin(p.phase * 3))
                ctx.fill(CGRect(x: p.x, y: p.y, width: w, height: h))
            case .firefly:
                let a = max(0, sin(p.phase * 2.2))
                ctx.setFillColor(p.color.withAlphaComponent(a * 0.3).cgColor)
                ctx.fillEllipse(in: CGRect(x: p.x - 1.5, y: p.y - 1.5, width: 3.6, height: 3.6))
                ctx.setFillColor(p.color.withAlphaComponent(a).cgColor)
                ctx.fill(CGRect(x: p.x, y: p.y, width: 0.7, height: 0.7))
            case .butterfly:
                let open = abs(sin(p.phase * 14))
                ctx.fill(CGRect(x: p.x - 1.2 * open, y: p.y, width: 1.2 * open, height: 1))
                ctx.fill(CGRect(x: p.x + 0.4, y: p.y, width: 1.2 * open, height: 1))
                ctx.setFillColor(NSColor(white: 0.1, alpha: 1).cgColor)
                ctx.fill(CGRect(x: p.x, y: p.y, width: 0.4, height: 1))
            case .bubble:
                ctx.setStrokeColor(p.color.cgColor)
                ctx.setLineWidth(0.3)
                let r: CGFloat = 0.6 + CGFloat(Int(p.phase * 10) % 3) * 0.0
                ctx.strokeEllipse(in: CGRect(x: p.x + sin(p.phase * 3) * 0.8, y: p.y, width: r * 2, height: r * 2))
            case .fish:
                let dir: CGFloat = p.vx >= 0 ? 1 : -1
                ctx.fillEllipse(in: CGRect(x: p.x - 1.5, y: p.y, width: 3, height: 1.4))
                ctx.fill(CGRect(x: p.x - dir * 2.3 - 0.5, y: p.y + 0.1, width: 1, height: 1.2))
            case .shootingStar:
                ctx.setStrokeColor(NSColor(white: 1, alpha: CGFloat(p.life / 0.6)).cgColor)
                ctx.setLineWidth(0.5)
                ctx.move(to: CGPoint(x: p.x, y: p.y)); ctx.addLine(to: CGPoint(x: p.x + 9, y: p.y + 3)); ctx.strokePath()
            case .seagull:
                let flap = sin(p.phase * 8) * 0.8
                ctx.setStrokeColor(p.color.cgColor)
                ctx.setLineWidth(0.5)
                ctx.move(to: CGPoint(x: p.x - 2, y: p.y + 0.8 + flap)); ctx.addLine(to: CGPoint(x: p.x, y: p.y))
                ctx.addLine(to: CGPoint(x: p.x + 2, y: p.y + 0.8 + flap)); ctx.strokePath()
            }
        }
    }
}
