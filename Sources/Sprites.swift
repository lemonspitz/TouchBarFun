import AppKit

// MARK: - Pixel art renderer

func hex(_ v: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255,
            blue: CGFloat(v & 0xFF) / 255, alpha: a)
}

enum PixelArt {
    private static var cache: [String: CGImage] = [:]
    static let outlineColor = hex(0x0B0B12)

    /// Builds a pixel image from ASCII rows. Any character missing from the palette is transparent.
    /// When `outline` is true a 1px dark border is generated around the shape.
    static func image(_ key: String, rows: [String], palette: [Character: NSColor], outline: Bool = true) -> CGImage {
        if let img = cache[key] { return img }
        let h = rows.count
        let w = rows.map { $0.count }.max() ?? 1
        let pad = outline ? 1 : 0
        let W = w + pad * 2, H = h + pad * 2
        var grid = [[NSColor?]](repeating: [NSColor?](repeating: nil, count: W), count: H)
        for (r, row) in rows.enumerated() {
            for (c, ch) in row.enumerated() { grid[r + pad][c + pad] = palette[ch] }
        }
        if outline {
            let src = grid
            for r in 0..<H {
                for c in 0..<W where src[r][c] == nil {
                    let n = [(r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)]
                    if n.contains(where: { $0.0 >= 0 && $0.0 < H && $0.1 >= 0 && $0.1 < W && src[$0.0][$0.1] != nil }) {
                        grid[r][c] = outlineColor
                    }
                }
            }
        }
        let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        for r in 0..<H {
            for c in 0..<W {
                if let col = grid[r][c] {
                    ctx.setFillColor(col.cgColor)
                    ctx.fill(CGRect(x: c, y: H - 1 - r, width: 1, height: 1))
                }
            }
        }
        let img = ctx.makeImage()!
        cache[key] = img
        return img
    }
}

// MARK: - Items

enum ItemKind: String, CaseIterable {
    case bone, fish, carrot, bamboo, fly, meat, berry, ball, heart, star, coin, cactus, tallCactus, rock, cake,
         baseball, glove, goldFish, boot, apple, honey, leaf, seeds, chili, watermelon, orange, soccer, mole, goldMole, bomb, basketball, alienA, alienB, ship

    var rows: [String] {
        switch self {
        case .bone: return ["ww...ww", ".wwwwww", "ww...ww"]
        case .fish: return ["b..bbb.", ".bbbbeb", ".bbbbbb", "b..bbb."]
        case .carrot: return ["g.g", ".g.", "ooo", "ooo", ".o.", ".o."]
        case .bamboo: return ["l..", ".l.", "ggg", "gdg", "ggg", "ggg", "gdg"]
        case .fly: return ["ww.ww", ".kkk.", "..k.."]
        case .meat: return ["..rrr.", ".rrrrr", "wrrrr.", "w....."]
        case .berry: return [".g.", "rrr", "rwr", "rrr", ".r."]
        case .ball: return [".ggg.", "gwggg", "ggwgg", "gggwg", ".ggg."]
        case .heart: return ["rr.rr", "rrrrr", ".rrr.", "..r.."]
        case .star: return ["..y..", "yyyyy", ".yyy.", ".y.y."]
        case .coin: return [".yy.", "yowy", "yooy", ".yy."]
        case .cactus: return ["..g..", "g.g..", "g.g.g", "ggggg", "..g..", "..g..", "..g.."]
        case .tallCactus: return ["..g..", "..g.g", "g.g.g", "g.ggg", "ggg..", "..g..", "..g..", "..g..", "..g.."]
        case .rock: return [".kkk..", "kkwkkk", "kkkkkk"]
        case .cake: return ["..r..", "wwwww", "ppppp", "wwwww"]
        case .baseball: return [".www.", "wrwww", "wwwww", "wwwrw", ".www."]
        case .glove: return [".n.n.n", "nnnnnn", "nmmmnn", "nmmmnn", ".nnnn.", "..nn.."]
        case .goldFish: return ItemKind.fish.rows
        case .boot: return ["nnn...", "nnn...", "nnn...", "nnnnnn", "kkkkkk"]
        case .apple: return ["..g..", ".rrr.", "rrwrr", "rrrrr", ".rrr."]
        case .honey: return ["yyyyy", ".nnn.", "nnynn", "nnnnn", ".nnn."]
        case .leaf: return ["...gl", ".ggg.", "gglg.", "ggg..", "l...."]
        case .seeds: return ["o.o.o", ".o.o."]
        case .chili: return ["g.....", "grrr..", ".rrrrr", "...rrr"]
        case .watermelon: return [".gdgdg.", "gdgdgdg", "gdgdgdg", "gdgdgdg", ".gdgdg."]
        case .orange: return ["..g..", ".ooo.", "ooooo", "ooooo", ".ooo."]
        case .soccer: return [".www.", "wweww", "weeew", "wweww", ".www."]
        case .mole, .goldMole: return ["..nnnnn..", ".nnnnnnn.", ".nenpnen.", ".nnnpnnn.", "wnnmmmnnw", ".nnmmmnn.", ".nnmmmnn."]
        case .bomb: return ["....ry", "...k..", ".kkkk.", "kwkkkk", "kkkkkk", ".kkkk."]
        case .basketball: return [".ooo.", "okoko", "kkkkk", "okoko", ".ooo."]
        case .alienA: return ["..g...g..", "...g.g...", "..ggggg..", ".gg.g.gg.", "ggggggggg", "g.ggggg.g", "g.g...g.g", "...g.g..."]
        case .alienB: return ["..g...g..", "g..g.g..g", "g.ggggg.g", "ggg.g.ggg", "ggggggggg", ".ggggggg.", "..g...g..", ".g.....g."]
        case .ship: return ["...w...", "..wbw..", ".wwwww.", "wwrwrww"]
        }
    }

    static let palette: [Character: NSColor] = [
        "w": hex(0xF5F1E6), "b": hex(0x5FA8E8), "e": hex(0x10131A), "g": hex(0x56B84A), "o": hex(0xF0892B),
        "l": hex(0xA6E37A), "d": hex(0x2F6E2A), "k": hex(0x8A8F99), "r": hex(0xE84A5F), "y": hex(0xFFD23F),
        "p": hex(0xF7A8C4), "n": hex(0x9A5A2E), "m": hex(0xD9A066),
    ]

    var image: CGImage {
        var pal = ItemKind.palette
        if self == .ball { pal["g"] = hex(0xD7F04A) }
        if self == .coin { pal["o"] = hex(0xE6A817) }
        if self == .fly { pal["w"] = hex(0xBFE6FF) }
        if self == .goldFish { pal["b"] = hex(0xFFC93C) }
        if self == .baseball { pal["r"] = hex(0xD8313F) }
        if self == .honey { pal["n"] = hex(0xB5651D) }
        if self == .basketball { pal["k"] = hex(0x5A2A10) }
        if self == .alienA || self == .alienB { pal["g"] = hex(0x7BE07B) }
        if self == .ship { pal["w"] = hex(0xDDE6F0); pal["b"] = hex(0x5FA8E8) }
        if self == .bomb { pal["k"] = hex(0x4A4E5E); pal["w"] = hex(0x9AA0B4) }
        if self == .mole { pal["n"] = hex(0x7A5236); pal["m"] = hex(0xC99A72) }
        if self == .goldMole { pal["n"] = hex(0xE8B830); pal["m"] = hex(0xFFE58A) }
        return PixelArt.image("item-\(rawValue)", rows: rows, palette: pal)
    }

    var pixelSize: CGSize {
        CGSize(width: (rows.map { $0.count }.max() ?? 0) + 2, height: rows.count + 2)
    }
}

// MARK: - Species

enum LegStyle { case quad, biped, hop }

struct Species {
    let id: String
    let name: String
    let emoji: String
    let defaultName: String
    let rows: [String]           // 9 body rows, 16 wide, facing right
    let palette: [Character: NSColor]
    let legStyle: LegStyle
    let legColor: Character
    let legXs: [Int]
    let food: ItemKind
    let speed: CGFloat

    static let all: [Species] = [dog, cat, bunny, fox, penguin, panda, frog, dino,
                                 pig, bear, koala, unicorn, owl, turtle, hamster, lion, chick, dragon, elephant]
    static func byID(_ id: String) -> Species { all.first { $0.id == id } ?? dog }

    static let dog = Species(
        id: "dog", name: "Puppy", emoji: "🐶", defaultName: "Biscuit",
        rows: ["..........bbbbb.",
               ".b.......dbbbbbd",
               ".b.......dbebebd",
               "..b......dbbpbbd",
               "..b.......bwwwb.",
               "..bbbbbbbbbbbbb.",
               "..bbbbbbbbbbbb..",
               "..bblllllllbbb..",
               "...bbbbbbbbbb..."],
        palette: ["b": hex(0xD9A066), "l": hex(0xF3D7B0), "d": hex(0x8F563B), "e": hex(0x15110F),
                  "p": hex(0x3B2416), "w": hex(0xF6E7CF)],
        legStyle: .quad, legColor: "b", legXs: [4, 6, 10, 12], food: .bone, speed: 55)

    static let cat = Species(
        id: "cat", name: "Kitty", emoji: "🐱", defaultName: "Mochi",
        rows: ["b.........b...b.",
               "b.........bb.bb.",
               ".b........bbbbb.",
               ".b........bebeb.",
               "..b.......bbpbb.",
               "..bbbbbbbbbbbb..",
               "..bdbbdbbdbbbb..",
               "..bbllllllllbb..",
               "...bbbbbbbbbb..."],
        palette: ["b": hex(0xA3ABBD), "l": hex(0xE2E6EE), "d": hex(0x737B8F), "e": hex(0x3BD16F),
                  "p": hex(0xF4A3B4)],
        legStyle: .quad, legColor: "b", legXs: [4, 6, 10, 12], food: .fish, speed: 60)

    static let bunny = Species(
        id: "bunny", name: "Bunny", emoji: "🐰", defaultName: "Clover",
        rows: ["..........b.b...",
               "..........p.p...",
               "..........b.b...",
               ".........bbbbb..",
               ".........bebeb..",
               "..w......bbpbb..",
               ".www.bbbbbbbbb..",
               "..wbbbbbbbbbbb..",
               "...bbbllllbbb..."],
        palette: ["b": hex(0xECE8E4), "l": hex(0xFFFFFF), "p": hex(0xF4A3B4), "e": hex(0x1A1A1A),
                  "w": hex(0xFFFFFF)],
        legStyle: .hop, legColor: "b", legXs: [4, 6, 9, 11], food: .carrot, speed: 50)

    static let fox = Species(
        id: "fox", name: "Fox", emoji: "🦊", defaultName: "Ember",
        rows: ["..........d...d.",
               "..........bb.bb.",
               "..........bbbbb.",
               "bb........bebeb.",
               "wbb.......wbpbw.",
               ".bbbbbbbbbbwwww.",
               "..bbbbbbbbbbww..",
               "..bbbbbbbbbbb...",
               "...bbbbbbbbbb..."],
        palette: ["b": hex(0xE8762B), "w": hex(0xFFF4E6), "d": hex(0x3A2A22), "e": hex(0x1A1A1A),
                  "p": hex(0x1A1A1A)],
        legStyle: .quad, legColor: "d", legXs: [4, 6, 10, 12], food: .berry, speed: 70)

    static let penguin = Species(
        id: "penguin", name: "Penguin", emoji: "🐧", defaultName: "Pebble",
        rows: ["......bbbb......",
               ".....bbbbbb.....",
               ".....bwebwe.....",
               ".....bwwwwby....",
               "....bbwwwwbb....",
               "...bbbwwwwbbb...",
               "....bbwwwwbb....",
               ".....bwwwwb.....",
               "......bbbb......"],
        palette: ["b": hex(0x3A4766), "w": hex(0xF4F4F4), "e": hex(0x000000), "y": hex(0xF2B134)],
        legStyle: .biped, legColor: "y", legXs: [6, 9], food: .fish, speed: 35)

    static let panda = Species(
        id: "panda", name: "Panda", emoji: "🐼", defaultName: "Bao",
        rows: ["..........d...d.",
               "..........bbbbb.",
               "..........dwbwd.",
               "..........bbpbb.",
               "..b.......bbbbb.",
               "..dddddddddddd..",
               "..bbbbbbbbbbbb..",
               "..bbbbbbbbbbbb..",
               "...bbbbbbbbbb..."],
        palette: ["b": hex(0xF3F3F0), "d": hex(0x26262B), "w": hex(0xFFFFFF), "p": hex(0x26262B)],
        legStyle: .quad, legColor: "d", legXs: [4, 6, 10, 12], food: .bamboo, speed: 40)

    static let frog = Species(
        id: "frog", name: "Froggy", emoji: "🐸", defaultName: "Lily",
        rows: ["........ww.ww...",
               "........we.we...",
               ".......bbbbbbb..",
               "......bbbbbbbbb.",
               "......bpbbbbbpb.",
               ".....bbbllllbbb.",
               "....bbbbbbbbbbb.",
               "....bblllllllbb.",
               "....bbbbbbbbbb.."],
        palette: ["b": hex(0x5DBB4C), "l": hex(0xB8E986), "w": hex(0xFFFFFF), "e": hex(0x000000),
                  "p": hex(0xF28BA0)],
        legStyle: .hop, legColor: "l", legXs: [5, 7, 11, 13], food: .fly, speed: 55)

    static let dino = Species(
        id: "dino", name: "Dino", emoji: "🦖", defaultName: "Rex",
        rows: [".........bbbbb..",
               ".........bebbbb.",
               ".........bbbbbb.",
               ".........bbbww..",
               "b.......bbbb....",
               "bb.....bbbbbb...",
               ".bbbbbbbbbbb....",
               "..bbbbbblll.....",
               "....bbbbbb......"],
        palette: ["b": hex(0x4CAF7A), "l": hex(0xA8E6B8), "e": hex(0x000000), "w": hex(0xFFFFFF)],
        legStyle: .biped, legColor: "b", legXs: [5, 8], food: .meat, speed: 50)

    static let pig = Species(
        id: "pig", name: "Piggy", emoji: "🐷", defaultName: "Truffle",
        rows: ["..........dd.dd.",
               "..........bbbbb.",
               "..........bebeb.",
               ".d........bbbddd",
               "..d.......bbbdpd",
               "..bbbbbbbbbbbbb.",
               "..bbbbbbbbbbbbb.",
               "..bbbbbbbbbbbb..",
               "...bbbbbbbbbb..."],
        palette: ["b": hex(0xF5A9B8), "d": hex(0xE07A93), "p": hex(0x8C3A50), "e": hex(0x1A1A1A)],
        legStyle: .quad, legColor: "b", legXs: [4, 6, 10, 12], food: .apple, speed: 42)

    static let bear = Species(
        id: "bear", name: "Bear", emoji: "🐻", defaultName: "Bruno",
        rows: [".........bb..bb.",
               ".........bbbbbb.",
               ".........bebbeb.",
               ".........bblplb.",
               "..b.......bllb..",
               "..bbbbbbbbbbbbb.",
               ".bbbbbbbbbbbbbb.",
               ".bbbbbbbbbbbbbb.",
               "..bbbbbbbbbbbb.."],
        palette: ["b": hex(0x9C6B43), "l": hex(0xD9B38C), "d": hex(0x6B4428), "p": hex(0x1A1A1A), "e": hex(0x1A1A1A)],
        legStyle: .quad, legColor: "d", legXs: [3, 5, 10, 12], food: .honey, speed: 38)

    static let koala = Species(
        id: "koala", name: "Koala", emoji: "🐨", defaultName: "Gumnut",
        rows: ["........bbb.bbb.",
               "........blbbblb.",
               "........bbebebb.",
               ".........bbpbb..",
               ".........bbpbb..",
               "..bbbbbbbbbbbb..",
               "..bbbbbbbbbbbb..",
               "..bbllllllllbb..",
               "...bbbbbbbbbb..."],
        palette: ["b": hex(0x9AA0A8), "l": hex(0xE6E1DC), "p": hex(0x2E2A2A), "e": hex(0x1A1A1A)],
        legStyle: .quad, legColor: "b", legXs: [4, 6, 10, 12], food: .leaf, speed: 30)

    static let unicorn = Species(
        id: "unicorn", name: "Unicorn", emoji: "🦄", defaultName: "Sparkle",
        rows: ["............h...",
               "..........rhb...",
               ".........robbb..",
               ".........obebbb.",
               "ro.......ybbbbbp",
               ".ry.....ybbb....",
               "..bbbbbbbbbb....",
               "..bbbbbbbbbb....",
               "..bbbbbbbbbb...."],
        palette: ["b": hex(0xF7F4FA), "r": hex(0xFF6B9A), "o": hex(0xFFB347), "y": hex(0x8FD3FF), "h": hex(0xFFD23F),
                  "p": hex(0xF4A3B4), "e": hex(0x6B3FA0)],
        legStyle: .quad, legColor: "b", legXs: [3, 5, 9, 11], food: .cake, speed: 70)

    static let owl = Species(
        id: "owl", name: "Owl", emoji: "🦉", defaultName: "Hoot",
        rows: [".....d....d.....",
               ".....bbbbbb.....",
               "....bwwbbwwb....",
               "....bwebbewb....",
               "....bbbyybbb....",
               "...bbllllllbb...",
               "...bblllllldb...",
               "....bllllllb....",
               ".....bbbbbb....."],
        palette: ["b": hex(0x8B5E3C), "d": hex(0x5C3A22), "w": hex(0xFFFFFF), "e": hex(0x1A1A1A), "y": hex(0xF2A33A),
                  "l": hex(0xE8D3B0)],
        legStyle: .biped, legColor: "y", legXs: [6, 9], food: .berry, speed: 32)

    static let turtle = Species(
        id: "turtle", name: "Turtle", emoji: "🐢", defaultName: "Shelly",
        rows: ["................",
               "................",
               "................",
               "......ssss......",
               "....ssdssdss....",
               "...ssdssssdss...",
               "..sssssdsssssbb.",
               "..sssssssssssbeb",
               "..lllllllllllbbb"],
        palette: ["s": hex(0x6B8E3A), "d": hex(0x4A6628), "l": hex(0xC9B26B), "b": hex(0x8FBF5A), "e": hex(0x1A1A1A)],
        legStyle: .quad, legColor: "b", legXs: [3, 5, 10, 12], food: .leaf, speed: 24)

    static let hamster = Species(
        id: "hamster", name: "Hamster", emoji: "🐹", defaultName: "Peanut",
        rows: ["................",
               "................",
               "..........b..b..",
               ".........bbbbbb.",
               ".........bebbeb.",
               "....bbbbbbwwpww.",
               "...bbbbbbbwwwww.",
               "...bwwwwwwwwwww.",
               "....bbbbbbbbbb.."],
        palette: ["b": hex(0xE8A15A), "w": hex(0xFFF4E6), "p": hex(0xF4A3B4), "e": hex(0x1A1A1A)],
        legStyle: .quad, legColor: "p", legXs: [5, 7, 10, 12], food: .seeds, speed: 58)

    static let lion = Species(
        id: "lion", name: "Lion", emoji: "🦁", defaultName: "Leo",
        rows: [".........mmmmm..",
               "........mmbbbmm.",
               "........mbebebm.",
               "........mbbpbbm.",
               "m.......mmbbbmm.",
               "mbbbbbbbbmmmmm..",
               ".bbbbbbbbbbbbb..",
               "..bbbbbbbbbbbb..",
               "...bbbbbbbbbb..."],
        palette: ["b": hex(0xE8B04A), "m": hex(0xB5651D), "e": hex(0x1A1A1A), "p": hex(0x5A3A2A)],
        legStyle: .quad, legColor: "b", legXs: [4, 6, 10, 12], food: .meat, speed: 62)

    static let chick = Species(
        id: "chick", name: "Chick", emoji: "🐥", defaultName: "Nugget",
        rows: ["................",
               "................",
               "......bbbb......",
               ".....bbbbeb.....",
               ".....bbbbbby....",
               "...bbbbbbbb.....",
               "..bbbbwbbbb.....",
               "...bbbbbbbb.....",
               "....bbbbbb......"],
        palette: ["b": hex(0xFFD93D), "w": hex(0xFFEE99), "e": hex(0x1A1A1A), "y": hex(0xF28C28)],
        legStyle: .biped, legColor: "y", legXs: [6, 8], food: .seeds, speed: 40)

    static let dragon = Species(
        id: "dragon", name: "Dragon", emoji: "🐲", defaultName: "Blaze",
        rows: ["...........h.h..",
               ".....ww....bbbb.",
               "....www....bebbb",
               "...wwww....bbbbb",
               "b...wwbbbbbbbb..",
               "bb..bbbbbbbbbb..",
               ".bbbbbbbbbbbbb..",
               "..bblllllllbbb..",
               "...bbbbbbbbbb..."],
        palette: ["b": hex(0x8E5BD9), "w": hex(0xC9A6F5), "l": hex(0xFFD58A), "h": hex(0xFFE9B0), "e": hex(0x1A1A1A)],
        legStyle: .quad, legColor: "b", legXs: [4, 6, 10, 12], food: .chili, speed: 55)

    static let elephant = Species(
        id: "elephant", name: "Elephant", emoji: "🐘", defaultName: "Jumbo",
        rows: ["................",
               "..........bbbb..",
               ".........dbbbbb.",
               "........ddbbebb.",
               "b.......ddbbbbbb",
               ".bbbbbbbddbbb.bb",
               ".bbbbbbbbbbbb..b",
               ".bbbbbbbbbbbb..b",
               "..bbbbbbbbbbb..."],
        palette: ["b": hex(0x9AA3AE), "d": hex(0x7A8390), "e": hex(0x1A1A1A)],
        legStyle: .quad, legColor: "b", legXs: [3, 5, 9, 11], food: .apple, speed: 36)

    // MARK: Frames

    static let pixelWidth = 18   // 16 + outline
    static let pixelHeight = 13  // 9 body + 2 legs + outline

    /// frame: 0 = standing, 1 = stride. closedEyes for blinking / sleeping.
    func image(frame: Int, closedEyes: Bool) -> CGImage {
        var legs = [[Character]](repeating: [Character](repeating: ".", count: 16), count: 2)
        func put(_ row: Int, _ x: Int) { if x >= 0 && x < 16 { legs[row][x] = "L" } }
        switch legStyle {
        case .quad:
            for x in legXs { put(0, x) }
            if frame == 0 { for x in legXs { put(1, x) } }
            else { for (i, x) in legXs.enumerated() { put(1, i % 2 == 0 ? x - 1 : x + 1) } }
        case .hop:
            for x in legXs { put(0, x) }
            if frame == 1 { for (i, x) in legXs.enumerated() { put(1, i < 2 ? x - 1 : x + 1) } }
        case .biped:
            let a = legXs[0], b = legXs[1]
            put(0, a); put(0, b)
            if frame == 0 || frame == 1 { put(1, a); put(1, a + 1) }
            if frame == 0 { put(1, b); put(1, b + 1) }
        }
        var pal = palette
        pal["L"] = palette[legColor]
        if closedEyes, let body = palette["b"] {
            pal["e"] = body.blended(withFraction: 0.55, of: .black)
        }
        let all = rows + legs.map { String($0) }
        return PixelArt.image("\(id)-\(frame)-\(closedEyes)", rows: all, palette: pal)
    }
}
