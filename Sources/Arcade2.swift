import AppKit

// MARK: - State

struct BridgeState {
    struct Platform { var x: CGFloat; var w: CGFloat }
    enum Stage { case aim, walking, falling, scrolling }
    static let top: CGFloat = 11                 // absolute y of platform tops
    var platforms: [Platform] = []               // [current, next]
    var bridges: [(x: CGFloat, len: CGFloat)] = []
    var cam: CGFloat = 0
    var camTarget: CGFloat = 0
    var petX: CGFloat = 0
    var plank: CGFloat = 0
    var growing = false
    var growT: Double = 0
    var stage: Stage = .aim
    var walkTarget: CGFloat = 0
    var success = false
    var perfect = false
    var crossed = 0
    var fallT: Double = 0
}

struct StackState {
    struct Block { var x: CGFloat; var w: CGFloat; var hue: CGFloat }
    struct Falling { var block: Block; var y: CGFloat; var vy: CGFloat }
    static let h: CGFloat = 3.0
    var blocks: [Block] = []
    var moving = Block(x: 10, w: 120, hue: 0.55)
    var dir: CGFloat = 1
    var speed: CGFloat = 110
    var cam: CGFloat = 0
    var falling: [Falling] = []
    var combo = 0
}

struct HighwayState {
    struct Car { var x: CGFloat; var lane: Int; var w: CGFloat; var color: UInt32; var coin: Bool }
    static let playerX: CGFloat = 70
    var lane = 0
    var laneY: CGFloat = 0
    var cars: [Car] = []
    var speed: CGFloat = 150
    var distance: CGFloat = 0
    var spawn: CGFloat = 220
    var lastLane = 0
    var coins = 0
}

struct ChefState {
    struct Pan { var x: CGFloat; var stage = 0; var t: Double = 0; var cookTime: Double = 3; var sideA = 0; var wait: Double = 0.6 }
    var pans: [Pan] = []
    var served = 0
}

struct PairsState {
    var cards: [String] = []
    var face: [CGFloat] = []         // 0 = face down … 1 = face up (animated)
    var up: [Bool] = []
    var matched: [Bool] = []
    var first: Int?
    var hideTimer: Double = 0
    var pending: [Int] = []
    var moves = 0
    var time: Double = 0
}

struct MathState {
    var question = ""
    var answer = 0
    var options: [Int] = []
    var streak = 0
    var solved = 0
    var wrong: Int?
    var flashT: Double = 0
}

struct AliensState {
    struct Alien { var col: Int; var row: Int; var alive = true }
    var aliens: [Alien] = []
    var cols = 10
    var offsetX: CGFloat = 20
    var dir: CGFloat = 1
    var drop: CGFloat = 0
    var shipX: CGFloat = 200
    var targetX: CGFloat = 200
    var bullets: [CGPoint] = []
    var bombs: [CGPoint] = []
    var fireT: Double = 0
    var bombT: Double = 1.5
    var lives = 3
    var wave = 1
    var invuln: Double = 0
    var speed: CGFloat = 22
    static let spacing: CGFloat = 34
}

struct HoopsState {
    var hoopX: CGFloat = 420
    var rimY: CGFloat = 19
    var ball: Item?
    var dragStart: CGFloat?
    var pull: CGFloat = 0
    var shotsLeft = 10
    var rimTouched = false
    var scored = false
    var wait: Double = 0
    var newHoop = false
    var path: [CGPoint] = []
    var ghost: [CGPoint] = []
}

struct DuelState {
    var rivalID = "cat"
    var round = 0
    var wins = 0
    var losses = 0
    var stage = 0                 // 0 standoff, 2 draw!, 3 result
    var timer: Double = 2
    var fakeAt: Double = -1
    var fakeShown = false
    var word = "Ready…"
    var drawTime: Double = 0
    var rivalReaction: Double = 0.45
    var resultT: Double = 0
    var petLost = false
    var bestMs: Int?
}

struct WordsState {
    static let list: [(String, String)] = [
        ("PUPPY", "🐶"), ("KITTY", "🐱"), ("BUNNY", "🐰"), ("FOX", "🦊"), ("PANDA", "🐼"), ("FROG", "🐸"), ("LION", "🦁"),
        ("BEAR", "🐻"), ("KOALA", "🐨"), ("OWL", "🦉"), ("TURTLE", "🐢"), ("PIG", "🐷"), ("CHICK", "🐥"), ("TIGER", "🐯"),
        ("ZEBRA", "🦓"), ("MONKEY", "🐵"), ("WHALE", "🐳"), ("SNAKE", "🐍"), ("SHEEP", "🐑"), ("HORSE", "🐴"),
        ("MOUSE", "🐭"), ("DUCK", "🦆"), ("CAMEL", "🐫"), ("SHARK", "🦈"), ("APPLE", "🍎"), ("PIZZA", "🍕"), ("CAKE", "🍰"),
        ("STAR", "⭐"), ("MOON", "🌙"), ("TREE", "🌳"), ("FISH", "🐟"), ("ROCKET", "🚀"), ("DRAGON", "🐲"), ("BANANA", "🍌"),
    ]
    var word = ""
    var emoji = ""
    var tiles: [Character] = []
    var used: [Bool] = []
    var progress = 0
    var wrong: Int?
    var flashT: Double = 0
    var nextT: Double = 0
    var remaining: [Int] = []
}

struct PongState {
    var ball = CGPoint(x: 300, y: 14)
    var vx: CGFloat = 0
    var vy: CGFloat = 0
    var speed: CGFloat = 170
    var g: CGFloat = 160
    var rally = 0
    var bestRally = 0
    var lives = 3
    var swing: Double = 0
    var swung = false
    var bounced = false
    var inPlay = false
    var serveT: Double = 1
}

struct BowlingState {
    var frame = 1
    var roll = 1
    var pinsUp = 10
    var stage = 0                // 0 aim, 1 power, 2 rolling, 3 result
    var aimT: Double = 0
    var powT: Double = 0
    var aim: CGFloat = 0
    var power: CGFloat = 0
    var ballX: CGFloat = 50
    var resultT: Double = 0
    var firstRoll = 0
    var frameTotal = 0
}

// MARK: - Dispatch

extension World {
    var arcade2HUDText: String? {
        switch mode {
        case .bridge: return "Bridges \(bridge.crossed)"
        case .stack: return "Height \(max(0, stack.blocks.count - 1))"
        case .highway: return "🪙 \(highway.coins)"
        case .pairs: return "Moves \(pairs.moves)"
        case .math: return math.streak > 1 ? "Streak \(math.streak)" : nil
        case .aliens: return "Wave \(aliens.wave)  " + String(repeating: "♥︎", count: max(0, aliens.lives))
        case .hoops: return "Balls \(hoops.shotsLeft)"
        case .duel: return "Round \(max(duel.round, 1))"
        case .pong: return "Rally \(pong.rally)  " + String(repeating: "♥︎", count: max(0, pong.lives))
        case .bowling: return "Frame \(min(bowling.frame, 5))/5 · Roll \(bowling.roll)"
        default: return arcade3HUDText
        }
    }

    func setupArcade2(_ m: Mode) {
        switch m {
        case .bridge: resetBridge()
        case .stack: pet.x = 18; resetStack()
        case .highway: highway = HighwayState(); pet.x = HighwayState.playerX
        case .chef: pet.x = 22; resetChef()
        case .pairs: pet.x = -100; resetPairs()
        case .math: pet.x = 16; math = MathState(); newQuestion()
        case .aliens: pet.x = -100; resetAliens()
        case .hoops: pet.x = 40; hoops = HoopsState(); newHoop()
        case .duel:
            pet.x = 120
            p1 = 0; p2 = 0
            mpRivalID = rivalIDs(1)[0]
            duel = DuelState(); duel.rivalID = mpRivalID
        case .words: pet.x = -100; words = WordsState(); nextWord()
        case .pong: pong = PongState(); pet.x = playMaxX - 8; pet.facing = -1
        case .bowling: pet.x = 30; bowling = BowlingState()
        default: if m.isMultiplayer { setupMultiplayer(m) } else { setupArcade3(m) }
        }
    }

    func beginArcade2() {
        switch mode {
        case .bridge: resetBridge()
        case .stack: resetStack()
        case .highway: highway = HighwayState()
        case .chef: resetChef(); timeLeft = 45
        case .pairs: resetPairs()
        case .math: math = MathState(); newQuestion(); timeLeft = 45
        case .aliens: resetAliens()
        case .hoops: hoops = HoopsState(); newHoop()
        case .duel:
            p1 = 0; p2 = 0
            duel = DuelState(); duel.rivalID = mpRivalID
            startDuelRound()
        case .words: words = WordsState(); nextWord(); timeLeft = 60
        case .pong: pong = PongState(); pet.x = playMaxX - 8
        case .bowling: bowling = BowlingState()
        default: if mode.isMultiplayer { beginMultiplayer() } else { beginArcade3() }
        }
    }

    func arcade2TouchBegan(_ p: CGPoint) {
        switch mode {
        case .bridge: if bridge.stage == .aim { bridge.growing = true; bridge.growT = 0 }
        case .stack: dropBlock()
        case .highway:
            highway.lane = 1 - highway.lane
            Sound.play("Pop", volume: 0.15)
        case .chef: tapPan(at: p.x)
        case .pairs: flipCard(at: p.x)
        case .math: answerMath(at: p.x)
        case .aliens: aliens.targetX = p.x
        case .hoops:
            if hoops.ball == nil && hoops.wait <= 0 && hoops.shotsLeft > 0 { hoops.dragStart = p.x; hoops.pull = 0 }
        case .words: tapTile(at: p.x)
        case .pong: swingPaddle()
        case .bowling: bowlingTap()
        default: arcade3TouchBegan(p)
        }
    }

    func arcade2TouchMoved(_ p: CGPoint) {
        switch mode {
        case .aliens: aliens.targetX = p.x
        case .hoops: if let s = hoops.dragStart { hoops.pull = min(150, abs(p.x - s)) }
        default: arcade3TouchMoved(p)
        }
    }

    func arcade2TouchEnded(_ p: CGPoint) {
        switch mode {
        case .bridge: if bridge.growing { releasePlank() }
        case .hoops: if hoops.dragStart != nil { shootHoop() }
        default: arcade3TouchEnded(p)
        }
    }

    func updateArcade2(_ dt: Double) {
        switch mode {
        case .bridge: updateBridge(dt)
        case .stack: updateStack(dt)
        case .highway: updateHighway(dt)
        case .chef: updateChef(dt)
        case .pairs: updatePairs(dt)
        case .math: updateMath(dt)
        case .aliens: updateAliens(dt)
        case .hoops: updateHoops(dt)
        case .duel: updateDuel(dt)
        case .words: updateWords(dt)
        case .pong: updatePong(dt)
        case .bowling: updateBowling(dt)
        default: if mode.isMultiplayer { updateMultiplayer(dt) } else { updateArcade3(dt) }
        }
    }

    func renderArcade2Behind(_ ctx: CGContext) {
        switch mode {
        case .bridge: renderBridge(ctx)
        case .stack: renderStack(ctx)
        case .highway: renderHighway(ctx)
        case .chef: renderChef(ctx)
        case .pairs: renderPairs(ctx)
        case .math: renderMath(ctx)
        case .aliens: renderAliens(ctx)
        case .hoops: renderHoopsBehind(ctx)
        case .duel: renderDuel(ctx)
        case .words: renderWords(ctx)
        case .pong: renderPongBehind(ctx)
        case .bowling: renderBowling(ctx)
        default: if mode.isMultiplayer { renderMultiplayer(ctx) } else { renderArcade3Behind(ctx) }
        }
    }

    func renderArcade2Front(_ ctx: CGContext) {
        switch mode {
        case .highway: renderHighwayFront(ctx)
        case .chef: renderChefHat(ctx)
        case .hoops: renderHoopsFront(ctx)
        case .pong: renderPongFront(ctx)
        default: renderArcade3Front(ctx)
        }
    }

    // MARK: - 🌉 Bridge

    private func newPlatform(after p: BridgeState.Platform) -> BridgeState.Platform {
        let c = CGFloat(bridge.crossed)
        let gap = CGFloat.random(in: 30...min(70 + c * 10, 230))
        let w = CGFloat.random(in: max(8, 26 - c * 0.8)...max(14, 40 - c))
        return .init(x: p.x + p.w + gap, w: w)
    }

    private func resetBridge() {
        bridge = BridgeState()
        let first = BridgeState.Platform(x: 10, w: 34)
        bridge.platforms = [first, newPlatform(after: first)]
        bridge.petX = first.x + first.w - 7
        pet.x = bridge.petX
        pet.y = BridgeState.top - World.ground
        pet.facing = 1
    }

    private func releasePlank() {
        bridge.growing = false
        guard bridge.platforms.count == 2 else { return }
        let cur = bridge.platforms[0], next = bridge.platforms[1]
        let end = cur.x + cur.w + bridge.plank
        bridge.success = end >= next.x && end <= next.x + next.w
        bridge.perfect = abs(end - (next.x + next.w / 2)) < 2
        bridge.walkTarget = bridge.success ? next.x + next.w - 7 : end + 5
        bridge.stage = .walking
        Sound.play("Tink", volume: 0.2)
    }

    private func updateBridge(_ dt: Double) {
        let fdt = CGFloat(dt)
        pet.moving = false
        pet.facing = 1
        defer { pet.x = bridge.petX - bridge.cam }
        guard phase == .playing else { pet.y = BridgeState.top - World.ground; return }
        switch bridge.stage {
        case .aim:
            pet.y = BridgeState.top - World.ground
            if bridge.growing {
                bridge.growT += dt
                let base = min(70 + CGFloat(bridge.crossed) * 4, 170)
                bridge.plank += base * (0.75 + 0.5 * CGFloat(abs(sin(bridge.growT * 2.2)))) * fdt
                if bridge.plank > 320 { releasePlank() }
            }
        case .walking:
            let dx = bridge.walkTarget - bridge.petX
            bridge.petX += min(dx, 95 * fdt)
            pet.moving = true
            pet.walkPhase += dt * 5
            if dx <= 0.5 {
                if bridge.success {
                    let cur = bridge.platforms[0]
                    bridge.bridges.append((cur.x + cur.w, bridge.plank))
                    if bridge.bridges.count > 3 { bridge.bridges.removeFirst() }
                    bridge.crossed += 1
                    score += bridge.perfect ? 3 : 1
                    addText(bridge.perfect ? "Perfect! +3" : "+1", x: bridge.petX - bridge.cam, y: 22, color: bridge.perfect ? hex(0xFFD23F) : .white)
                    Sound.play(bridge.perfect ? "Glass" : "Pop", volume: 0.3)
                    let next = bridge.platforms[1]
                    bridge.platforms = [next, newPlatform(after: next)]
                    bridge.camTarget = next.x - 20
                    bridge.stage = .scrolling
                } else {
                    bridge.stage = .falling
                    bridge.fallT = 0
                    pet.vy = 0
                    Sound.play("Basso")
                }
            }
        case .falling:
            bridge.fallT += dt
            pet.vy -= 300 * fdt
            pet.y += pet.vy * fdt
            if bridge.fallT > 0.9 {
                resultText = "🌉 Fell after \(bridge.crossed) bridge\(bridge.crossed == 1 ? "" : "s")"
                endRound()
            }
        case .scrolling:
            bridge.cam += (bridge.camTarget - bridge.cam) * min(1, 7 * fdt)
            if abs(bridge.camTarget - bridge.cam) < 0.5 {
                bridge.cam = bridge.camTarget
                bridge.plank = 0
                bridge.stage = .aim
            }
        }
    }

    private func renderBridge(_ ctx: CGContext) {
        let cam = bridge.cam, top = BridgeState.top
        for p in bridge.platforms {
            let x = p.x - cam
            ctx.setFillColor(hex(0x3A3F4B).cgColor)
            ctx.fill(CGRect(x: x, y: 0, width: p.w, height: top))
            ctx.setFillColor(hex(0x5A6070).cgColor)
            ctx.fill(CGRect(x: x, y: top - 1, width: p.w, height: 1))
            if p.x == bridge.platforms.last?.x {
                ctx.setFillColor(hex(0xE84A5F).cgColor)
                ctx.fill(CGRect(x: x + p.w / 2 - 1.5, y: top - 0.6, width: 3, height: 0.6))
            }
        }
        if bridge.platforms.count == 2 {
            let gapX = bridge.platforms[0].x + bridge.platforms[0].w - cam
            ctx.setFillColor(NSColor(white: 0, alpha: 0.7).cgColor)
            ctx.fill(CGRect(x: gapX, y: 0, width: bridge.platforms[1].x - bridge.platforms[0].x - bridge.platforms[0].w, height: World.ground))
        }
        ctx.setFillColor(hex(0xA0703A).cgColor)
        for b in bridge.bridges { ctx.fill(CGRect(x: b.x - cam, y: top - 1.2, width: b.len, height: 1.2)) }
        if let cur = bridge.platforms.first, bridge.plank > 0, bridge.stage != .scrolling {
            let x0 = cur.x + cur.w - cam
            ctx.saveGState()
            ctx.translateBy(x: x0, y: top)
            if bridge.stage == .falling { ctx.rotate(by: -min(CGFloat(bridge.fallT) * 3, .pi / 2)) }
            ctx.fill(CGRect(x: 0, y: -1.2, width: bridge.plank, height: 1.2))
            ctx.restoreGState()
        }
        if phase == .playing && bridge.stage == .aim && !bridge.growing {
            text("hold to build the bridge", at: CGPoint(x: bridge.petX - cam + 10, y: 21), size: 5, color: NSColor(white: 1, alpha: 0.6), ctx: ctx)
        }
    }

    // MARK: - 🧱 Stack

    private func resetStack() {
        stack = StackState()
        let w: CGFloat = 120
        stack.blocks = [.init(x: (playMaxX - w) / 2 + 20, w: w, hue: 0.55)]
        stack.moving = .init(x: 30, w: w, hue: 0.62)
    }

    private func dropBlock() {
        guard let top = stack.blocks.last else { return }
        let m = stack.moving
        let l = max(m.x, top.x), r = min(m.x + m.w, top.x + top.w)
        let level = CGFloat(stack.blocks.count)
        if r - l <= 0 {
            stack.falling.append(.init(block: m, y: World.ground + level * StackState.h - stack.cam, vy: 0))
            Sound.play("Basso")
            flash = 0.3
            resultText = "🧱 Tower of \(stack.blocks.count - 1) blocks"
            endRound()
            return
        }
        var placed: StackState.Block
        if abs(m.x - top.x) < 1.5 {
            stack.combo += 1
            placed = .init(x: top.x, w: min(top.w + (stack.combo >= 3 ? 3 : 0), 130), hue: m.hue)
            score += 2
            addText(stack.combo >= 3 ? "Perfect ×\(stack.combo)! wider" : "Perfect!", x: placed.x + placed.w / 2, y: 22, color: hex(0xFFD23F))
            Sound.play("Glass", volume: 0.3)
            if pet.y <= 0.01 { pet.vy = 50 }
        } else {
            stack.combo = 0
            placed = .init(x: l, w: r - l, hue: m.hue)
            let piece: StackState.Block = m.x < l ? .init(x: m.x, w: l - m.x, hue: m.hue) : .init(x: r, w: m.x + m.w - r, hue: m.hue)
            stack.falling.append(.init(block: piece, y: World.ground + level * StackState.h - stack.cam, vy: 0))
            score += 1
            Sound.play("Pop", volume: 0.25)
        }
        stack.blocks.append(placed)
        let fromLeft = stack.blocks.count % 2 == 0
        stack.moving = .init(x: fromLeft ? 10 : playMaxX - placed.w, w: placed.w, hue: (m.hue + 0.06).truncatingRemainder(dividingBy: 1))
        stack.dir = fromLeft ? 1 : -1
        stack.speed = min(stack.speed + 5, 300)
    }

    private func updateStack(_ dt: Double) {
        let fdt = CGFloat(dt)
        applyGravity(dt)
        pet.facing = 1
        for i in stack.falling.indices {
            stack.falling[i].vy -= 160 * fdt
            stack.falling[i].y += stack.falling[i].vy * fdt
        }
        stack.falling.removeAll { $0.y < -10 }
        let camTarget = max(0, CGFloat(stack.blocks.count + 1) * StackState.h - 20)
        stack.cam += (camTarget - stack.cam) * min(1, 6 * fdt)
        guard phase == .playing else { return }
        stack.moving.x += stack.dir * stack.speed * fdt
        if stack.moving.x < 10 { stack.moving.x = 10; stack.dir = 1 }
        if stack.moving.x + stack.moving.w > playMaxX { stack.moving.x = playMaxX - stack.moving.w; stack.dir = -1 }
    }

    private func blockColor(_ hue: CGFloat) -> NSColor { NSColor(calibratedHue: hue, saturation: 0.55, brightness: 0.92, alpha: 1) }

    private func drawBlock(_ ctx: CGContext, _ b: StackState.Block, y: CGFloat) {
        let r = CGRect(x: b.x, y: y, width: b.w, height: StackState.h)
        ctx.setFillColor(blockColor(b.hue).cgColor)
        ctx.fill(r)
        ctx.setFillColor(NSColor(white: 1, alpha: 0.35).cgColor)
        ctx.fill(CGRect(x: r.minX, y: r.maxY - 0.5, width: r.width, height: 0.5))
        ctx.setFillColor(NSColor(white: 0, alpha: 0.25).cgColor)
        ctx.fill(CGRect(x: r.minX, y: r.minY, width: r.width, height: 0.4))
    }

    private func renderStack(_ ctx: CGContext) {
        for (i, b) in stack.blocks.enumerated() {
            let y = World.ground + CGFloat(i) * StackState.h - stack.cam
            if y > -StackState.h { drawBlock(ctx, b, y: y) }
        }
        if phase == .playing {
            drawBlock(ctx, stack.moving, y: World.ground + CGFloat(stack.blocks.count) * StackState.h - stack.cam)
        }
        for f in stack.falling { drawBlock(ctx, f.block, y: f.y) }
    }

    // MARK: - 🚗 Highway

    private func laneCenter(_ lane: CGFloat) -> CGFloat { World.ground + 5.5 + lane * 11.5 }

    private func updateHighway(_ dt: Double) {
        let fdt = CGFloat(dt)
        highway.laneY += (CGFloat(highway.lane) - highway.laneY) * min(1, 16 * fdt)
        pet.x = HighwayState.playerX
        pet.facing = 1
        pet.moving = false
        pet.y = laneCenter(highway.laneY) - World.ground - 2.4
        guard phase == .playing else { return }
        highway.speed = min(highway.speed + 3 * fdt, 360)
        highway.distance += highway.speed * fdt
        score = Int(highway.distance / 30) + highway.coins * 3
        highway.spawn -= highway.speed * fdt
        if highway.spawn <= 0 {
            let lane = Int.random(in: 0...1)
            let truck = Double.random(in: 0..<1) < 0.3
            let colors: [UInt32] = [0x5FA8E8, 0xFFD23F, 0x6CD47A, 0xB04AE8, 0xF0892B, 0xE8E8E8]
            highway.cars.append(.init(x: World.W + 20, lane: lane, w: truck ? 34 : 22, color: colors.randomElement()!, coin: false))
            if Double.random(in: 0..<1) < 0.35 {
                highway.cars.append(.init(x: World.W + 20, lane: 1 - lane, w: 5, color: 0, coin: true))
            }
            var gap = CGFloat.random(in: 120...260)
            // Leave room to slip in behind a car in the other lane before the next one arrives.
            if lane != highway.lastLane { gap = max(gap, highway.speed * 0.7 + 80) }
            highway.lastLane = lane
            highway.spawn = gap
        }
        for i in highway.cars.indices { highway.cars[i].x -= highway.speed * (highway.cars[i].coin ? 1 : 0.55) * fdt }
        highway.cars.removeAll { $0.x < -40 }
        let py = laneCenter(highway.laneY)
        let me = CGRect(x: HighwayState.playerX - 11, y: py - 3.5, width: 22, height: 7)
        if let ci = highway.cars.firstIndex(where: { $0.coin && me.insetBy(dx: -2, dy: -1).contains(CGPoint(x: $0.x, y: laneCenter(CGFloat($0.lane)))) }) {
            highway.cars.remove(at: ci)
            highway.coins += 1
            addText("+3", x: HighwayState.playerX, y: py + 6, color: hex(0xFFD23F))
            Sound.play("Tink", volume: 0.25)
        }
        for c in highway.cars where !c.coin {
            let r = CGRect(x: c.x - c.w / 2, y: laneCenter(CGFloat(c.lane)) - 3.5, width: c.w, height: 7)
            if r.insetBy(dx: 1.5, dy: 1).intersects(me.insetBy(dx: 1.5, dy: 1)) {
                flash = 0.4
                Sound.play("Basso")
                burst(.spark(hex(0xFFB347)), at: HighwayState.playerX + 10, py, count: 12)
                resultText = "🚗 Crashed after \(Int(highway.distance / 20))m"
                endRound()
                return
            }
        }
    }

    func drawCar(_ ctx: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, color: NSColor, facing: CGFloat, roofless: Bool = false) {
        ctx.setFillColor(color.cgColor)
        ctx.fill(CGRect(x: x - w / 2, y: y - 2.5, width: w, height: 4))
        if !roofless {
            ctx.fill(CGRect(x: x - w * 0.3, y: y + 1.5, width: w * 0.5, height: 2.5))
            ctx.setFillColor(hex(0xBFE6FF, 0.9).cgColor)
            ctx.fill(CGRect(x: x + (facing > 0 ? 0 : -w * 0.2), y: y + 1.9, width: w * 0.18, height: 1.7))
        }
        ctx.setFillColor(hex(0x1A1A1A).cgColor)
        for dx in [-w * 0.3, w * 0.3] { ctx.fillEllipse(in: CGRect(x: x + dx - 1.6, y: y - 3.8, width: 3.2, height: 3.2)) }
        ctx.setFillColor(hex(facing > 0 ? 0xFFE58A : 0xE84A5F).cgColor)
        ctx.fill(CGRect(x: facing > 0 ? x + w / 2 - 0.8 : x - w / 2, y: y - 1, width: 0.8, height: 1))
    }

    private func renderHighway(_ ctx: CGContext) {
        ctx.setFillColor(hex(0x2A2C33, 0.85).cgColor)
        ctx.fill(CGRect(x: 0, y: World.ground - 0.5, width: World.W, height: 23.5))
        ctx.setFillColor(NSColor(white: 1, alpha: 0.5).cgColor)
        ctx.fill(CGRect(x: 0, y: World.ground - 0.5, width: World.W, height: 0.5))
        ctx.fill(CGRect(x: 0, y: World.ground + 22.5, width: World.W, height: 0.5))
        ctx.setFillColor(hex(0xFFD23F, 0.8).cgColor)
        var x = -(highway.distance.truncatingRemainder(dividingBy: 24))
        while x < World.W { ctx.fill(CGRect(x: x, y: World.ground + 11.2, width: 12, height: 0.6)); x += 24 }
        for c in highway.cars {
            let y = laneCenter(CGFloat(c.lane))
            if c.coin {
                drawItem(ctx, .coin, x: c.x, y: y - 3, scale: 1.4)
            } else {
                drawCar(ctx, x: c.x, y: y, w: c.w, color: hex(c.color), facing: 1)
            }
        }
    }

    private func renderHighwayFront(_ ctx: CGContext) {
        // Convertible body over the pet, so it looks like the pet is driving.
        drawCar(ctx, x: HighwayState.playerX, y: laneCenter(highway.laneY), w: 22, color: hex(0xE84A5F), facing: 1, roofless: true)
    }

    // MARK: - 🍳 Chef

    private func resetChef() {
        chef = ChefState()
        let n = min(5, max(3, Int((playMaxX - 60) / 110)))
        chef.pans = (0..<n).map { i in ChefState.Pan(x: 70 + (playMaxX - 70) * (CGFloat(i) + 0.5) / CGFloat(n), wait: Double(i) * 0.7 + 0.3) }
    }

    private func doneness(_ p: ChefState.Pan) -> Double { p.t / p.cookTime }

    private func quality(_ d: Double) -> Int { d < 0.8 ? 0 : d < 1.2 ? 2 : d < 1.6 ? 1 : -1 }

    private func tapPan(at x: CGFloat) {
        guard let i = chef.pans.indices.min(by: { abs(chef.pans[$0].x - x) < abs(chef.pans[$1].x - x) }),
              abs(chef.pans[i].x - x) < 40 else { return }
        var p = chef.pans[i]
        switch p.stage {
        case 1:
            p.sideA = quality(doneness(p))
            p.stage = 2
            p.t = 0
            Sound.play("Pop", volume: 0.25)
        case 3:
            let q = quality(doneness(p))
            var pts = p.sideA + q
            if p.sideA == 2 && q == 2 { pts += 2 }
            if p.sideA < 0 || q < 0 { pts = -1 }
            score = max(0, score + pts)
            chef.served += 1
            let label = pts < 0 ? "Burnt! -1" : pts >= 6 ? "Perfect pancake! +\(pts)" : pts == 0 ? "Raw… +0" : "+\(pts)"
            addText(label, x: p.x, y: 18, color: pts < 0 ? hex(0xFF9AA8) : pts >= 6 ? hex(0xFFD23F) : .white)
            Sound.play(pts >= 6 ? "Glass" : pts < 0 ? "Funk" : "Tink", volume: 0.3)
            if pts >= 6 { burst(.spark(hex(0xFFD23F)), at: p.x, 10, count: 6) }
            p.stage = 0
            p.wait = Double.random(in: 0.4...1.6)
        default: return
        }
        chef.pans[i] = p
    }

    private func updateChef(_ dt: Double) {
        applyGravity(dt)
        pet.facing = 1
        guard phase == .playing else { return }
        timeLeft -= dt
        if timeLeft <= 0 { timeLeft = 0; resultText = "🍳 Served \(chef.served) pancakes"; endRound(); return }
        let progress = 1 - timeLeft / 45
        for i in chef.pans.indices {
            var p = chef.pans[i]
            switch p.stage {
            case 0:
                p.wait -= dt
                if p.wait <= 0 { p.stage = 1; p.t = 0; p.cookTime = Double.random(in: 2.4...3.4) * (1 - progress * 0.3) }
            case 2:
                p.t += dt
                if p.t > 0.4 { p.stage = 3; p.t = 0 }
            default:
                p.t += dt
                if doneness(p) > 2.2 {
                    score = max(0, score - 1)
                    addText("Burnt! -1", x: p.x, y: 18, color: hex(0xFF9AA8))
                    burst(.spark(hex(0x555555)), at: p.x, 9, count: 6)
                    Sound.play("Funk", volume: 0.25)
                    p.stage = 0
                    p.wait = Double.random(in: 0.5...1.5)
                }
            }
            chef.pans[i] = p
        }
    }

    private func pancakeColor(_ d: Double) -> NSColor {
        if d < 0.8 { return hex(0xF3E3B5).blended(withFraction: CGFloat(d / 0.8) * 0.5, of: hex(0xE8A33A)) ?? hex(0xF3E3B5) }
        if d < 1.2 { return hex(0xE8A33A) }
        if d < 1.6 { return hex(0xA8622A) }
        return hex(0x3A2412)
    }

    private func renderChef(_ ctx: CGContext) {
        for p in chef.pans {
            let y: CGFloat = World.ground + 3
            ctx.setFillColor(hex(0x55596A).cgColor)
            ctx.fill(CGRect(x: p.x + 12, y: y + 0.6, width: 9, height: 1.2))
            ctx.setFillColor(hex(0x2A2C33).cgColor)
            ctx.fillEllipse(in: CGRect(x: p.x - 13, y: y - 1.5, width: 26, height: 4))
            ctx.setFillColor(hex(0xE84A5F, 0.5).cgColor)
            ctx.fill(CGRect(x: p.x - 10, y: World.ground - 0.5, width: 20, height: 1))
            guard p.stage != 0 else { continue }
            let d = p.stage == 2 ? 0 : doneness(p)
            var cy = y + 0.5
            var hgt: CGFloat = 2.6
            if p.stage == 2 {
                let f = CGFloat(p.t / 0.4)
                cy += sin(f * .pi) * 10
                hgt *= abs(cos(f * .pi))
            }
            ctx.setFillColor((p.stage == 2 ? pancakeColor(1) : pancakeColor(d)).cgColor)
            ctx.fillEllipse(in: CGRect(x: p.x - 9.5, y: cy - hgt / 2, width: 19, height: max(hgt, 0.4)))
            if p.stage != 2 && d >= 0.8 && d < 1.2 && Int(t * 6) % 2 == 0 {
                text("✦", at: CGPoint(x: p.x, y: y + 4), size: 5, color: hex(0xFFD23F), ctx: ctx, center: true)
            }
            if d > 1.4 {
                ctx.setFillColor(NSColor(white: 0.7, alpha: 0.5).cgColor)
                for k in 0..<3 {
                    let sy = y + 3 + CGFloat((t * 6 + Double(k) * 2).truncatingRemainder(dividingBy: 8))
                    ctx.fillEllipse(in: CGRect(x: p.x - 4 + CGFloat(k) * 4, y: sy, width: 2.2, height: 2.2))
                }
            }
            if p.stage == 3 {
                text("serve", at: CGPoint(x: p.x, y: 21), size: 4.5, color: NSColor(white: 1, alpha: 0.5), ctx: ctx, center: true)
            }
        }
    }

    private func renderChefHat(_ ctx: CGContext) {
        let top = World.ground + pet.y + petSize.height - 1
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fill(CGRect(x: pet.x + 1, y: top, width: 6, height: 1.6))
        ctx.fillEllipse(in: CGRect(x: pet.x, y: top + 1, width: 8, height: 4))
    }

    // MARK: - 🃏 Pairs

    private var pairsX0: CGFloat { 26 }
    private var pairsCell: CGFloat { (playMaxX - pairsX0) / 16 }

    private func resetPairs() {
        pairs = PairsState()
        let ids = Array(Species.all.map(\.id).shuffled().prefix(8))
        pairs.cards = (ids + ids).shuffled()
        pairs.face = Array(repeating: 0, count: 16)
        pairs.up = Array(repeating: false, count: 16)
        pairs.matched = Array(repeating: false, count: 16)
    }

    private func flipCard(at x: CGFloat) {
        let i = Int((x - pairsX0) / pairsCell)
        guard pairs.cards.indices.contains(i), !pairs.up[i], !pairs.matched[i], pairs.hideTimer <= 0 else { return }
        pairs.up[i] = true
        Sound.play("Tink", volume: 0.2)
        guard let f = pairs.first else { pairs.first = i; return }
        pairs.first = nil
        pairs.moves += 1
        if pairs.cards[f] == pairs.cards[i] {
            pairs.matched[f] = true
            pairs.matched[i] = true
            score += 5
            addText("Match! +5", x: pairsX0 + pairsCell * (CGFloat(i) + 0.5), y: 22, color: hex(0xFFD23F))
            Sound.play("Glass", volume: 0.3)
            if pairs.matched.allSatisfy({ $0 }) {
                let bonus = max(0, 40 - pairs.moves * 2) + max(0, 30 - Int(pairs.time))
                score += bonus
                resultText = String(format: "🃏 Cleared in %d moves · %.0fs", pairs.moves, pairs.time)
                endRound()
            }
        } else {
            pairs.pending = [f, i]
            pairs.hideTimer = 0.8
        }
    }

    private func updatePairs(_ dt: Double) {
        for i in pairs.face.indices {
            let target: CGFloat = pairs.up[i] || pairs.matched[i] ? 1 : 0
            pairs.face[i] += (target - pairs.face[i]) * min(1, CGFloat(dt) * 14)
        }
        guard phase == .playing else { return }
        pairs.time += dt
        if pairs.hideTimer > 0 {
            pairs.hideTimer -= dt
            if pairs.hideTimer <= 0 { for i in pairs.pending { pairs.up[i] = false }; pairs.pending = [] }
        }
    }

    private func renderPairs(_ ctx: CGContext) {
        let w = pairsCell - 3
        for i in pairs.cards.indices {
            let cx = pairsX0 + pairsCell * (CGFloat(i) + 0.5)
            let f = pairs.face[i]
            let squeeze = abs(cos(f * .pi))
            let r = CGRect(x: cx - w / 2 * squeeze, y: 3.5, width: w * squeeze, height: 23)
            let path = CGPath(roundedRect: r, cornerWidth: 2, cornerHeight: 2, transform: nil)
            ctx.addPath(path)
            if f > 0.5 {
                ctx.setFillColor((pairs.matched[i] ? hex(0xD8F5D0) : hex(0xFFF8E8)).cgColor)
                ctx.fillPath()
                if squeeze > 0.3 {
                    let s = Species.byID(pairs.cards[i])
                    let scale = min(1.5, (w - 4) / CGFloat(Species.pixelWidth)) * squeeze
                    drawImage(ctx, s.image(frame: 0, closedEyes: false),
                              CGRect(x: cx - CGFloat(Species.pixelWidth) * scale / 2, y: 8, width: CGFloat(Species.pixelWidth) * scale,
                                     height: CGFloat(Species.pixelHeight) * min(1.5, (w - 4) / CGFloat(Species.pixelWidth))), flip: false)
                }
            } else {
                ctx.setFillColor(hex(0x5A4FCF).cgColor)
                ctx.fillPath()
                if squeeze > 0.4 {
                    text("🐾", at: CGPoint(x: cx, y: 11), size: 8, color: .white, ctx: ctx, center: true)
                }
            }
        }
    }

    // MARK: - ➕ Math

    private func newQuestion() {
        let level = math.solved / 5
        var a = 0, b = 0, op = "+"
        switch level {
        case 0: a = Int.random(in: 1...10); b = Int.random(in: 1...10)
        case 1: op = Bool.random() ? "+" : "−"; a = Int.random(in: 5...20); b = Int.random(in: 1...a)
        case 2: op = ["+", "−", "×"].randomElement()!
            if op == "×" { a = Int.random(in: 2...9); b = Int.random(in: 2...9) } else { a = Int.random(in: 10...50); b = Int.random(in: 1...a) }
        default: op = ["+", "−", "×", "×"].randomElement()!
            if op == "×" { a = Int.random(in: 3...12); b = Int.random(in: 3...12) } else { a = Int.random(in: 20...99); b = Int.random(in: 5...a) }
        }
        math.answer = op == "+" ? a + b : op == "−" ? a - b : a * b
        math.question = "\(a) \(op) \(b) = ?"
        var opts: Set<Int> = [math.answer]
        while opts.count < 4 {
            let d = Int.random(in: 1...max(3, math.answer / 5 + 2)) * (Bool.random() ? 1 : -1)
            if math.answer + d >= 0 { opts.insert(math.answer + d) }
        }
        math.options = Array(opts).shuffled()
        math.wrong = nil
    }

    private var mathX0: CGFloat { 200 }
    private func mathOptionX(_ i: Int) -> CGFloat { mathX0 + (playMaxX - mathX0) * (CGFloat(i) + 0.5) / 4 }

    private func answerMath(at x: CGFloat) {
        guard x > mathX0 - 10, let i = math.options.indices.min(by: { abs(mathOptionX($0) - x) < abs(mathOptionX($1) - x) }) else { return }
        if math.options[i] == math.answer {
            let pts = 1 + min(math.streak / 5, 3)
            score += pts
            math.streak += 1
            math.solved += 1
            addText("+\(pts)", x: mathOptionX(i), y: 22, color: .white)
            Sound.play("Tink", volume: 0.25)
            if pet.y <= 0.01 { pet.vy = 40 }
            newQuestion()
        } else {
            math.streak = 0
            math.wrong = i
            math.flashT = 0.4
            score = max(0, score - 1)
            Sound.play("Funk", volume: 0.25)
        }
    }

    private func updateMath(_ dt: Double) {
        applyGravity(dt)
        pet.facing = 1
        math.flashT -= dt
        guard phase == .playing else { return }
        timeLeft -= dt
        if timeLeft <= 0 { timeLeft = 0; resultText = "➕ Solved \(math.solved)"; endRound() }
    }

    private func renderMath(_ ctx: CGContext) {
        guard phase == .playing else { return }
        text(math.question, at: CGPoint(x: 30, y: 9), size: 11, color: .white, ctx: ctx, bold: true)
        for (i, o) in math.options.enumerated() {
            let x = mathOptionX(i)
            let bad = math.wrong == i && math.flashT > 0
            let r = CGRect(x: x - 22, y: 6, width: 44, height: 17)
            ctx.addPath(CGPath(roundedRect: r, cornerWidth: 5, cornerHeight: 5, transform: nil))
            ctx.setFillColor((bad ? hex(0xE84A5F, 0.8) : NSColor(white: 1, alpha: 0.16)).cgColor)
            ctx.fillPath()
            text("\(o)", at: CGPoint(x: x + (bad ? CGFloat(sin(t * 60)) : 0), y: 9.5), size: 10, color: .white, ctx: ctx, center: true, bold: true)
        }
    }

    // MARK: - 👾 Aliens

    private func resetAliens() {
        aliens = AliensState()
        aliens.cols = max(6, min(12, Int((playMaxX - 60) / AliensState.spacing)))
        spawnWave()
        aliens.shipX = playMaxX / 2
        aliens.targetX = aliens.shipX
    }

    private func spawnWave() {
        aliens.aliens = (0..<2).flatMap { row in (0..<aliens.cols).map { AliensState.Alien(col: $0, row: row) } }
        aliens.offsetX = 20
        aliens.drop = 0
        aliens.dir = 1
    }

    private func alienPos(_ a: AliensState.Alien) -> CGPoint {
        CGPoint(x: aliens.offsetX + CGFloat(a.col) * AliensState.spacing, y: (a.row == 0 ? 25 : 19.5) - aliens.drop)
    }

    private func updateAliens(_ dt: Double) {
        let fdt = CGFloat(dt)
        guard phase == .playing else { return }
        aliens.invuln -= dt
        let step = 320 * fdt
        aliens.shipX += max(-step, min(step, aliens.targetX - aliens.shipX))
        aliens.shipX = min(max(aliens.shipX, 8), playMaxX)
        // Formation march
        let width = CGFloat(aliens.cols - 1) * AliensState.spacing
        aliens.offsetX += aliens.dir * aliens.speed * fdt
        if aliens.offsetX < 12 || aliens.offsetX + width > playMaxX {
            aliens.dir *= -1
            aliens.offsetX = min(max(aliens.offsetX, 12), playMaxX - width)
            aliens.drop += 1
        }
        // Auto-fire
        aliens.fireT -= dt
        if aliens.fireT <= 0 && aliens.bullets.count < 3 {
            aliens.fireT = 0.28
            aliens.bullets.append(CGPoint(x: aliens.shipX, y: 8))
            Sound.play("Pop", volume: 0.06)
        }
        for i in aliens.bullets.indices { aliens.bullets[i].y += 110 * fdt }
        aliens.bullets.removeAll { $0.y > World.H }
        // Hits
        var bi = 0
        while bi < aliens.bullets.count {
            let b = aliens.bullets[bi]
            if let ai = aliens.aliens.indices.first(where: { aliens.aliens[$0].alive && abs(alienPos(aliens.aliens[$0]).x - b.x) < 4 && abs(alienPos(aliens.aliens[$0]).y - b.y) < 2.6 }) {
                aliens.aliens[ai].alive = false
                let pts = aliens.aliens[ai].row == 0 ? 2 : 1
                score += pts
                burst(.spark(hex(aliens.aliens[ai].row == 0 ? 0xF7A8C4 : 0x7BE07B)), at: b.x, b.y, count: 5)
                aliens.bullets.remove(at: bi)
                continue
            }
            bi += 1
        }
        // Bombs
        aliens.bombT -= dt
        if aliens.bombT <= 0 {
            aliens.bombT = Double.random(in: 0.6...1.4) / Double(1 + CGFloat(aliens.wave - 1) * 0.2)
            let shooters = aliens.aliens.filter(\.alive)
            if let a = shooters.randomElement() { aliens.bombs.append(alienPos(a)) }
        }
        for i in aliens.bombs.indices { aliens.bombs[i].y -= 24 * fdt }
        aliens.bombs.removeAll { $0.y < 0 }
        if aliens.invuln <= 0, let hit = aliens.bombs.firstIndex(where: { abs($0.x - aliens.shipX) < 5 && $0.y < 7 }) {
            aliens.bombs.remove(at: hit)
            aliens.lives -= 1
            aliens.invuln = 1.2
            flash = 0.3
            Sound.play("Basso", volume: 0.3)
            if aliens.lives <= 0 { resultText = "👾 Reached wave \(aliens.wave)"; endRound(); return }
        }
        if aliens.aliens.filter(\.alive).contains(where: { alienPos($0).y < 10 }) {
            resultText = "👾 Invaded on wave \(aliens.wave)"
            flash = 0.4
            endRound()
            return
        }
        if !aliens.aliens.contains(where: \.alive) {
            score += 5
            aliens.wave += 1
            aliens.speed += 7
            addText("Wave \(aliens.wave)! +5", x: World.W / 2, y: 18, color: hex(0xFFD23F))
            Sound.play("Glass", volume: 0.3)
            spawnWave()
        }
    }

    private func renderAliens(_ ctx: CGContext) {
        let frame = Int(t * 3) % 2
        for a in aliens.aliens where a.alive {
            let p = alienPos(a)
            let kind: ItemKind = frame == 0 ? .alienA : .alienB
            ctx.saveGState()
            if a.row == 0 { ctx.setAlpha(1) }
            drawItem(ctx, kind, x: p.x, y: p.y - 2.4, scale: 0.6)
            ctx.restoreGState()
        }
        ctx.setFillColor(hex(0xFFF2B0).cgColor)
        for b in aliens.bullets { ctx.fill(CGRect(x: b.x - 0.3, y: b.y, width: 0.6, height: 1.8)) }
        ctx.setFillColor(hex(0xFF7F7F).cgColor)
        for b in aliens.bombs { ctx.fill(CGRect(x: b.x - 0.4, y: b.y, width: 0.8, height: 1.6)) }
        if aliens.invuln <= 0 || Int(t * 10) % 2 == 0 {
            drawItem(ctx, .ship, x: aliens.shipX, y: World.ground - 0.5, scale: 1.1)
        }
    }

    // MARK: - 🏀 Hoops

    private func newHoop() {
        hoops.hoopX = CGFloat.random(in: 170...min(playMaxX - 25, 440))
        hoops.rimY = CGFloat.random(in: 12...20)
        hoops.ghost.removeAll()
    }

    private var hoopsStart: CGPoint { CGPoint(x: pet.x + 9, y: 9) }

    /// The bar is only 30pt tall, so the shot angle flattens for far hoops to keep the arc on screen;
    /// the player only controls power.
    func hoopLaunch(power: CGFloat) -> (vx: CGFloat, vy: CGFloat) {
        let dist = max(hoops.hoopX - hoopsStart.x, 60)
        let a = min(max(atan(80 / dist), 12 * .pi / 180), 35 * .pi / 180)
        let v = 60 + power * 440
        return (v * cos(a), v * sin(a))
    }

    private func shootHoop() {
        let power = max(0.05, hoops.pull / 150)
        let (vx, vy) = hoopLaunch(power: power)
        hoops.ball = Item(kind: .basketball, x: hoopsStart.x, y: hoopsStart.y, vx: vx, vy: vy, scale: 0.75)
        hoops.dragStart = nil
        hoops.pull = 0
        hoops.shotsLeft -= 1
        hoops.rimTouched = false
        hoops.scored = false
        hoops.path = []
        Sound.play("Blow", volume: 0.2)
    }

    private func updateHoops(_ dt: Double) {
        let fdt = CGFloat(dt)
        pet.facing = 1
        guard phase == .playing else { return }
        if hoops.wait > 0 {
            hoops.wait -= dt
            if hoops.wait <= 0 {
                if hoops.newHoop { newHoop(); hoops.newHoop = false }
                if hoops.shotsLeft == 0 { resultText = "🏀 \(score) points from 10 shots"; endRound() }
            }
            return
        }
        guard var b = hoops.ball else { return }
        let prevY = b.y, prevX = b.x
        b.vy -= 190 * fdt
        b.x += b.vx * fdt
        b.y += b.vy * fdt
        b.age += dt
        if Int(b.age * 60) % 2 == 0 { hoops.path.append(CGPoint(x: b.x, y: b.y)) }
        let hx = hoops.hoopX, ry = hoops.rimY
        // Score where the ball actually crossed the rim plane between frames (fast shots move ~7pt per frame).
        var throughHoop = false
        if !hoops.scored && prevY >= ry && b.y < ry && b.vy < 0 {
            let crossX = prevX + (b.x - prevX) * (prevY - ry) / max(prevY - b.y, 0.001)
            if abs(crossX - hx) < 4.3 {
                throughHoop = true
                hoops.scored = true
                let pts = hoops.rimTouched ? 2 : 3
                score += pts
                addText(pts == 3 ? "SWISH! +3" : "+2", x: hx, y: ry + 6, color: pts == 3 ? hex(0xFFD23F) : .white)
                Sound.play(pts == 3 ? "Hero" : "Glass", volume: 0.3)
                burst(.spark(hex(0xFFB347)), at: hx, ry, count: 6)
            }
        }
        // Backboard and rim bounces
        if !throughHoop && !hoops.scored {
            if b.vx > 0 && b.x > hx + 6 && prevX <= hx + 8 && b.y > ry - 1 && b.y < ry + 10 {
                b.x = hx + 6; b.vx = -abs(b.vx) * 0.55; hoops.rimTouched = true; Sound.play("Pop", volume: 0.15)
            }
            // Flat arcs come in low, so the front rim only catches balls that really hit it.
            for (rx, radius) in [(hx - 5, CGFloat(0.9)), (hx + 5, CGFloat(1.5))] where hypot(b.x - rx, b.y - ry) < radius {
                b.vx *= -0.45
                b.vy = abs(b.vy) * 0.45
                hoops.rimTouched = true
            }
        }
        if b.y < 0 || b.x > World.W + 5 || b.x < -5 || b.age > 4 {
            hoops.ball = nil
            if hoops.scored { hoops.newHoop = true; hoops.wait = 0.8 } else {
                hoops.ghost = hoops.path
                hoops.wait = 0.5
                addText("Miss", x: min(max(b.x, 40), playMaxX - 10), y: 10, color: hex(0xFF9AA8))
            }
            return
        }
        hoops.ball = b
    }

    private func renderHoopsBehind(_ ctx: CGContext) {
        let hx = hoops.hoopX, ry = hoops.rimY
        ctx.setFillColor(hex(0x8A8F99).cgColor)
        ctx.fill(CGRect(x: hx + 9, y: 0, width: 1.2, height: ry + 9))
        ctx.setFillColor(NSColor(white: 1, alpha: 0.9).cgColor)
        ctx.fill(CGRect(x: hx + 7, y: ry - 1, width: 1.4, height: 11))
        ctx.setFillColor(NSColor(white: 1, alpha: 0.25).cgColor)
        for p in hoops.ghost { ctx.fill(CGRect(x: p.x, y: p.y, width: 0.6, height: 0.6)) }
    }

    private func renderHoopsFront(_ ctx: CGContext) {
        let hx = hoops.hoopX, ry = hoops.rimY
        if let b = hoops.ball { drawItem(ctx, .basketball, x: b.x, y: b.y - 2.5, scale: b.scale) }
        else if phase == .playing && hoops.shotsLeft > 0 && hoops.wait <= 0 {
            drawItem(ctx, .basketball, x: hoopsStart.x, y: hoopsStart.y - 2.5, scale: 0.75)
        }
        // Net and rim in front of the ball
        ctx.setStrokeColor(NSColor(white: 1, alpha: 0.7).cgColor)
        ctx.setLineWidth(0.3)
        for k in 0..<4 {
            let x = hx - 4.5 + CGFloat(k) * 3
            ctx.move(to: CGPoint(x: x, y: ry)); ctx.addLine(to: CGPoint(x: hx - 2.5 + CGFloat(k) * 1.7, y: ry - 4)); ctx.strokePath()
        }
        ctx.setFillColor(hex(0xF0892B).cgColor)
        ctx.fill(CGRect(x: hx - 5, y: ry - 0.4, width: 10.5, height: 0.8))
        if let _ = hoops.dragStart {
            let p = hoops.pull / 150
            ctx.setFillColor(NSColor(white: 1, alpha: 0.2).cgColor)
            ctx.fill(CGRect(x: pet.x + 15, y: World.ground + 2, width: 2.2, height: 20))
            ctx.setFillColor(NSColor(calibratedHue: 0.33 * (1 - p), saturation: 0.8, brightness: 0.95, alpha: 1).cgColor)
            ctx.fill(CGRect(x: pet.x + 15, y: World.ground + 2, width: 2.2, height: 20 * p))
        } else if phase == .playing && hoops.ball == nil && hoops.wait <= 0 && hoops.shotsLeft > 0 {
            text("drag to pull back, release to shoot", at: CGPoint(x: pet.x + 18, y: 23), size: 4.8, color: NSColor(white: 1, alpha: 0.55), ctx: ctx)
        }
    }

    // MARK: - 🤠 Duel

    private func startDuelRound() {
        duel.round += 1
        duel.stage = 0
        duel.word = "Ready…"
        duel.timer = Double.random(in: 1.6...3.6)
        duel.fakeShown = false
        duel.fakeAt = duel.round >= 3 && Double.random(in: 0..<1) < 0.4 ? Double.random(in: 0.5...max(0.6, duel.timer - 0.6)) : -1
        duel.rivalReaction = max(0.22, 0.5 - Double(duel.round) * 0.04) + Double.random(in: -0.04...0.06)
    }

    func duelTap(player: Int) {
        switch duel.stage {
        case 0:
            // Shooting before DRAW! gives the round to the other side.
            duelRoundOver(winner: 1 - player, word: twoPlayer ? "\(player == 0 ? "🔴" : "🔵") too early!" : "Too early!")
            Sound.play("Funk", volume: 0.3)
        case 2:
            let reaction = t - duel.drawTime
            let ms = Int(reaction * 1000)
            duel.bestMs = min(duel.bestMs ?? ms, ms)
            if !twoPlayer { score += 10 + max(0, Int((0.5 - reaction) * 40)) }
            let who = twoPlayer ? (player == 0 ? "🔴 Player 1" : "🔵 Player 2") : "You"
            duelRoundOver(winner: player, word: "\(who) win\(twoPlayer ? "s" : "") — \(ms) ms")
            Sound.play("Hero", volume: 0.3)
            burst(.spark(hex(0xFFD23F)), at: player == 0 ? playMaxX - 100 : pet.x, 12, count: 8)
        default: break
        }
    }

    private func duelRoundOver(winner: Int, word: String) {
        if winner == 0 { p1 += 1 } else { p2 += 1 }
        duel.petLost = winner == 1
        duel.word = word
        duel.stage = 3
        duel.resultT = 1.4
    }

    private func updateDuel(_ dt: Double) {
        pet.facing = 1
        guard phase == .playing else { return }
        switch duel.stage {
        case 0:
            duel.timer -= dt
            if duel.fakeAt > 0 && !duel.fakeShown && duel.timer < duel.fakeAt {
                duel.fakeShown = true
                duel.word = ["DRAT!", "DUCK!", "DRAWL!", "DART!"].randomElement()!
            } else if duel.fakeShown && duel.timer < duel.fakeAt - 0.6 {
                duel.word = "Ready…"
            }
            if duel.timer <= 0 {
                duel.stage = 2
                duel.drawTime = t
                duel.word = "DRAW!"
                Sound.play("Ping", volume: 0.5)
            }
        case 2:
            if !twoPlayer && t - duel.drawTime >= duel.rivalReaction {
                duelRoundOver(winner: 1, word: "Too slow!")
                flash = 0.25
                Sound.play("Basso", volume: 0.3)
            } else if twoPlayer && t - duel.drawTime > 3 {
                duel.word = "Nobody drew…"
                duel.round -= 1
                duel.stage = 3
                duel.resultT = 1.0
                duel.petLost = false
            }
        case 3:
            duel.resultT -= dt
            if duel.resultT <= 0 {
                if p1 >= 3 || p2 >= 3 {
                    let best = duel.bestMs.map { " · best \($0) ms" } ?? ""
                    if twoPlayer {
                        resultText = (p1 > p2 ? "🔴 Player 1 wins \(p1)–\(p2)" : "🔵 Player 2 wins \(p2)–\(p1)") + best
                        score = max(p1, p2) * 10
                    } else {
                        resultText = p1 >= 3 ? "🤠 Won \(p1)–\(p2)\(best)" : "🤠 Lost \(p1)–\(p2)\(best)"
                    }
                    endRound()
                } else {
                    startDuelRound()
                }
            }
        default: break
        }
    }

    private func renderDuel(_ ctx: CGContext) {
        let rx = playMaxX - 100
        let rivalDown = duel.stage == 3 && !duel.petLost
        ctx.saveGState()
        if rivalDown {
            ctx.translateBy(x: rx, y: World.ground)
            ctx.rotate(by: -.pi / 2)
            ctx.translateBy(x: -rx, y: -World.ground)
        }
        drawCreature(ctx, Species.byID(duel.rivalID), x: rx, y: 0, scale: 1.3, facing: -1, frame: 0)
        ctx.restoreGState()
        if phase == .playing {
            let color: NSColor = duel.word == "DRAW!" ? hex(0xFF4D4D) : duel.stage == 3 ? (duel.petLost ? hex(0xFF9AA8) : hex(0x7BE07B)) : duel.word == "Ready…" ? .white : hex(0xFFD23F)
            text(duel.word, at: CGPoint(x: (pet.x + rx) / 2, y: 9), size: duel.word == "DRAW!" ? 15 : 10, color: color, ctx: ctx, center: true, bold: true)
            if duel.stage == 3 && duel.petLost {
                text("💫", at: CGPoint(x: pet.x, y: petSize.height + 4), size: 7, color: .white, ctx: ctx, center: true)
            }
            if duel.stage == 0 && duel.round == 1 {
                text(twoPlayer ? "🔴 left half vs 🔵 right half — tap only on DRAW!" : "tap only when it says DRAW!", at: CGPoint(x: (pet.x + rx) / 2, y: 22), size: 5, color: NSColor(white: 1, alpha: 0.5), ctx: ctx, center: true)
            }
        }
    }

    // MARK: - 🔤 Words

    private func nextWord() {
        if words.remaining.isEmpty { words.remaining = Array(WordsState.list.indices).shuffled() }
        let (w, e) = WordsState.list[words.remaining.removeLast()]
        words.word = w
        words.emoji = e
        var tiles = Array(w)
        repeat { tiles.shuffle() } while tiles.count > 1 && String(tiles) == w
        words.tiles = tiles
        words.used = Array(repeating: false, count: tiles.count)
        words.progress = 0
        words.wrong = nil
    }

    private var tilesX0: CGFloat { 150 }
    private func tileX(_ i: Int) -> CGFloat {
        let spacing = min(46, (playMaxX - tilesX0) / CGFloat(max(words.tiles.count, 1)))
        return tilesX0 + spacing * (CGFloat(i) + 0.5)
    }

    private func tapTile(at x: CGFloat) {
        guard words.nextT <= 0, x > tilesX0 - 10,
              let i = words.tiles.indices.min(by: { abs(tileX($0) - x) < abs(tileX($1) - x) }), !words.used[i] else { return }
        let target = Array(words.word)[words.progress]
        if words.tiles[i] == target {
            words.used[i] = true
            words.progress += 1
            Sound.play("Tink", volume: 0.2)
            if words.progress == words.word.count {
                score += words.word.count
                addText("✓ \(words.word) +\(words.word.count)", x: 80, y: 22, color: hex(0x7BE07B))
                Sound.play("Glass", volume: 0.3)
                words.nextT = 0.6
            }
        } else {
            words.wrong = i
            words.flashT = 0.4
            score = max(0, score - 1)
            Sound.play("Funk", volume: 0.25)
        }
    }

    private func updateWords(_ dt: Double) {
        words.flashT -= dt
        guard phase == .playing else { return }
        if words.nextT > 0 {
            words.nextT -= dt
            if words.nextT <= 0 { nextWord() }
        }
        timeLeft -= dt
        if timeLeft <= 0 { timeLeft = 0; resultText = "🔤 Time's up"; endRound() }
    }

    private func renderWords(_ ctx: CGContext) {
        guard phase == .playing else { return }
        text(words.emoji, at: CGPoint(x: 18, y: 8), size: 14, color: .white, ctx: ctx, center: true)
        let letters = Array(words.word)
        for i in letters.indices {
            let x = 34 + CGFloat(i) * 15
            ctx.setFillColor(NSColor(white: 1, alpha: 0.12).cgColor)
            ctx.fill(CGRect(x: x, y: 6, width: 13, height: 16))
            ctx.setFillColor(NSColor(white: 1, alpha: 0.5).cgColor)
            ctx.fill(CGRect(x: x + 1, y: 6, width: 11, height: 0.6))
            if i < words.progress {
                text(String(letters[i]), at: CGPoint(x: x + 6.5, y: 9), size: 10, color: hex(0x7BE07B), ctx: ctx, center: true, bold: true)
            }
        }
        for (i, ch) in words.tiles.enumerated() where !words.used[i] {
            let x = tileX(i)
            let bad = words.wrong == i && words.flashT > 0
            let r = CGRect(x: x - 15 + (bad ? CGFloat(sin(t * 60)) : 0), y: 5, width: 30, height: 19)
            ctx.addPath(CGPath(roundedRect: r, cornerWidth: 4, cornerHeight: 4, transform: nil))
            ctx.setFillColor((bad ? hex(0xE84A5F) : hex(0xF5E6C8)).cgColor)
            ctx.fillPath()
            text(String(ch), at: CGPoint(x: r.midX, y: 9), size: 11, color: hex(0x3A2A1A), ctx: ctx, center: true, bold: true)
        }
    }

    // MARK: - 🏓 Pong

    private var tableY: CGFloat { World.ground + 6 }
    private var tableL: CGFloat { 50 }
    private var tableR: CGFloat { playMaxX - 26 }
    private var netX: CGFloat { (tableL + tableR) / 2 }
    private var paddleX: CGFloat { 42 }
    /// Hit window grows with ball speed (about ±60 ms), so fast rallies stay hard but possible.
    private var pongWindow: CGFloat { max(14, pong.speed * 0.06) }

    /// Ball path from `from` that bounces on the table at `landX` after `speed`-paced flight.
    private func pongLaunch(from: CGPoint, landX: CGFloat, leftward: Bool) {
        let T = abs(from.x - landX) / pong.speed
        pong.ball = from
        pong.vx = leftward ? -pong.speed : pong.speed
        pong.g = arcGravity(fromY: from.y, landY: tableY, apex: 20, time: T)
        pong.vy = (tableY - from.y + 0.5 * pong.g * T * T) / T
        pong.bounced = false
        pong.inPlay = true
    }

    private func swingPaddle() {
        guard pong.swing <= 0 else { return }
        pong.swing = 0.15
        guard pong.inPlay, pong.vx < 0, !pong.swung else { return }
        pong.swung = true
        let dx = pong.ball.x - paddleX
        guard pong.bounced, abs(dx) < pongWindow else {
            addText("Whiff!", x: 60, y: 20, color: hex(0xFF9AA8))
            return
        }
        let smash = abs(dx) < max(4, pong.speed * 0.016)
        pong.rally += 1
        pong.bestRally = max(pong.bestRally, pong.rally)
        score += smash ? 2 : 1
        pong.speed = min(pong.speed + 14, 480)
        if smash { addText("Smash! +2", x: 70, y: 20, color: hex(0xFFD23F)) }
        Sound.play(smash ? "Glass" : "Pop", volume: 0.3)
        let saved = pong.speed
        if smash { pong.speed *= 1.2 }
        pongLaunch(from: pong.ball, landX: CGFloat.random(in: (netX + 30)...(tableR - 20)), leftward: false)
        pong.speed = saved
    }

    private func updatePong(_ dt: Double) {
        let fdt = CGFloat(dt)
        pong.swing -= dt
        pet.facing = -1
        guard phase == .playing else { return }
        if !pong.inPlay {
            pong.serveT -= dt
            if pong.serveT <= 0 {
                pong.swung = false
                pongLaunch(from: CGPoint(x: tableR + 6, y: 15), landX: CGFloat.random(in: (tableL + 25)...(netX - 25)), leftward: true)
            }
            return
        }
        pong.vy -= pong.g * fdt
        pong.ball.x += pong.vx * fdt
        pong.ball.y += pong.vy * fdt
        if pong.vy < 0 && pong.ball.y <= tableY + 1 && pong.ball.x > tableL && pong.ball.x < tableR {
            pong.ball.y = tableY + 1
            pong.vy = abs(pong.vy) * 0.85
            if (pong.vx < 0) == (pong.ball.x < netX) { pong.bounced = true }
        }
        // The pet returns everything that reaches its end.
        if pong.vx > 0 && pong.ball.x >= tableR + 4 {
            pong.swung = false
            if pet.y <= 0.01 { pet.vy = 30 }
            Sound.play("Pop", volume: 0.15)
            pongLaunch(from: pong.ball, landX: CGFloat.random(in: (tableL + 20)...(netX - 25)), leftward: true)
        }
        applyGravity(dt)
        if pong.ball.x < paddleX - pongWindow - 2 || pong.ball.y < 0 {
            pong.lives -= 1
            pong.rally = 0
            pong.inPlay = false
            pong.serveT = 1.0
            addText("Miss!", x: 40, y: 18, color: hex(0xFF9AA8))
            Sound.play("Basso", volume: 0.3)
            if pong.lives <= 0 { resultText = "🏓 Longest rally \(pong.bestRally)"; endRound() }
        }
    }

    private func renderPongBehind(_ ctx: CGContext) {
        ctx.setFillColor(hex(0x2E6FD0).cgColor)
        ctx.fill(CGRect(x: tableL, y: tableY - 1.6, width: tableR - tableL, height: 2.2))
        ctx.setFillColor(hex(0x1B4A8F).cgColor)
        ctx.fill(CGRect(x: tableL, y: tableY - 1.6, width: tableR - tableL, height: 0.6))
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fill(CGRect(x: tableL, y: tableY + 0.3, width: tableR - tableL, height: 0.25))
        ctx.fill(CGRect(x: netX - 0.3, y: tableY, width: 0.6, height: 3))
        ctx.setFillColor(hex(0x55596A).cgColor)
        for x in [tableL + 6, tableR - 6] { ctx.fill(CGRect(x: x, y: 0, width: 1, height: tableY - 1)) }
    }

    private func renderPongFront(_ ctx: CGContext) {
        if pong.inPlay {
            ctx.setFillColor(NSColor(white: 0, alpha: 0.3).cgColor)
            ctx.fillEllipse(in: CGRect(x: pong.ball.x - 1, y: tableY + 0.3, width: 2, height: 0.6))
            ctx.setFillColor(hex(0xFFF4E0).cgColor)
            ctx.fillEllipse(in: CGRect(x: pong.ball.x - 1, y: pong.ball.y - 1, width: 2, height: 2))
        }
        // Your paddle on the left, the pet's on the right.
        let a: CGFloat = pong.swing > 0 ? -0.6 : 0.5
        for (x, angle, flip) in [(paddleX - 4, a, false), (pet.x - 7, CGFloat(0.4), true)] {
            ctx.saveGState()
            ctx.translateBy(x: x, y: tableY + 5)
            ctx.rotate(by: flip ? -angle : angle)
            ctx.setFillColor(hex(0x8B5A2B).cgColor)
            ctx.fill(CGRect(x: -0.5, y: -4, width: 1, height: 3))
            ctx.setFillColor(hex(flip ? 0x3A6EE8 : 0xE84A5F).cgColor)
            ctx.fillEllipse(in: CGRect(x: -2.2, y: -1.5, width: 4.4, height: 5))
            ctx.restoreGState()
        }
        if phase == .playing && pong.rally == 0 && pong.inPlay && pong.vx < 0 {
            text("tap when the ball reaches your paddle", at: CGPoint(x: 70, y: 22), size: 5, color: NSColor(white: 1, alpha: 0.5), ctx: ctx)
        }
    }

    // MARK: - 🎳 Bowling

    private var pinsX: CGFloat { playMaxX - 30 }
    private var bowlingAim: CGFloat { CGFloat(sin(bowling.aimT * 2.6)) }
    private var bowlingPower: CGFloat {
        let f = bowling.powT.truncatingRemainder(dividingBy: 1.3) / 1.3
        return CGFloat(f < 0.5 ? f * 2 : 2 - f * 2)
    }

    private func bowlingTap() {
        switch bowling.stage {
        case 0:
            bowling.aim = bowlingAim
            bowling.stage = 1
            bowling.powT = 0
            Sound.play("Tink", volume: 0.2)
        case 1:
            bowling.power = bowlingPower
            bowling.stage = 2
            bowling.ballX = pet.x + 10
            Sound.play("Submarine", volume: 0.15)
        default: break
        }
    }

    private func updateBowling(_ dt: Double) {
        let fdt = CGFloat(dt)
        pet.facing = 1
        guard phase == .playing else { return }
        switch bowling.stage {
        case 0: bowling.aimT += dt
        case 1: bowling.powT += dt
        case 2:
            bowling.ballX += (120 + bowling.power * 200) * fdt
            if bowling.ballX >= pinsX - 4 {
                let a = 1 - abs(bowling.aim)
                let pf = max(0, 1 - abs(bowling.power - 0.85) * 2.2)
                var knocked: Int
                if a < 0.15 { knocked = 0 }
                else if bowling.roll == 1 && a > 0.93 && pf > 0.85 { knocked = 10 }
                else {
                    let q = Double(pow(a, 1.3) * (0.4 + 0.6 * pf)) + Double.random(in: -0.12...0.08)
                    knocked = Int((Double(bowling.pinsUp) * q).rounded())
                }
                knocked = max(0, min(bowling.pinsUp, knocked))
                bowling.pinsUp -= knocked
                burst(.spark(.white), at: pinsX + 4, 8, count: knocked * 2)
                var label = "\(knocked) pin\(knocked == 1 ? "" : "s")"
                if bowling.roll == 1 {
                    bowling.firstRoll = knocked
                    if knocked == 10 { label = "STRIKE! 🎳"; score += 20; Sound.play("Hero", volume: 0.35) }
                    else { score += knocked; Sound.play(knocked > 0 ? "Pop" : "Funk", volume: 0.3) }
                } else {
                    if bowling.firstRoll + knocked == 10 { label = "SPARE! +\(knocked + 5)"; score += knocked + 5; Sound.play("Glass", volume: 0.3) }
                    else { score += knocked; Sound.play(knocked > 0 ? "Pop" : "Funk", volume: 0.3) }
                }
                if a < 0.15 { label = "Gutter ball" }
                addText(label, x: pinsX - 40, y: 20, color: knocked == 10 || label.hasPrefix("SPARE") ? hex(0xFFD23F) : .white)
                bowling.stage = 3
                bowling.resultT = 1.3
            }
        case 3:
            bowling.resultT -= dt
            if bowling.resultT <= 0 {
                if bowling.roll == 1 && bowling.pinsUp > 0 {
                    bowling.roll = 2
                } else {
                    bowling.frame += 1
                    bowling.roll = 1
                    bowling.pinsUp = 10
                    if bowling.frame > 5 { resultText = "🎳 \(score) points in 5 frames"; endRound(); return }
                }
                bowling.stage = 0
                bowling.aimT = Double.random(in: 0...2)
            }
        default: break
        }
    }

    private func renderBowling(_ ctx: CGContext) {
        let laneY = World.ground
        ctx.setFillColor(hex(0xD9A066, 0.9).cgColor)
        ctx.fill(CGRect(x: pet.x + 6, y: laneY - 1.5, width: pinsX + 14 - pet.x - 6, height: 2))
        ctx.setFillColor(hex(0x7A4E2D).cgColor)
        ctx.fill(CGRect(x: pet.x + 6, y: laneY - 1.8, width: pinsX + 14 - pet.x - 6, height: 0.3))
        // Pins (side view): standing pins fill the columns from the back.
        let rows = [4, 3, 2, 1]
        var drawn = 0
        for (r, count) in rows.enumerated() {
            for k in 0..<count {
                guard drawn < bowling.pinsUp else { break }
                drawn += 1
                let x = pinsX + 12 - CGFloat(r) * 3.2 - CGFloat(k) * 0.5
                ctx.setFillColor(NSColor.white.cgColor)
                ctx.fillEllipse(in: CGRect(x: x - 1.2, y: laneY, width: 2.4, height: 4))
                ctx.fillEllipse(in: CGRect(x: x - 0.8, y: laneY + 3.6, width: 1.6, height: 2.2))
                ctx.setFillColor(hex(0xE84A5F).cgColor)
                ctx.fill(CGRect(x: x - 0.8, y: laneY + 3.4, width: 1.6, height: 0.4))
            }
        }
        if phase != .playing { return }
        // Ball
        let bx = bowling.stage >= 2 ? bowling.ballX : pet.x + 10
        if bowling.stage < 3 || bowling.ballX < pinsX {
            ctx.setFillColor(hex(0x3A6EE8).cgColor)
            ctx.fillEllipse(in: CGRect(x: bx - 2.2, y: laneY, width: 4.4, height: 4.4))
            ctx.setFillColor(NSColor(white: 1, alpha: 0.4).cgColor)
            ctx.fillEllipse(in: CGRect(x: bx - 1, y: laneY + 2.6, width: 1, height: 1))
        }
        // Aim gauge (top-down lane offset) near the pins
        let gx = pinsX - 22, gy0: CGFloat = 6, gh: CGFloat = 18
        ctx.setFillColor(NSColor(white: 1, alpha: 0.15).cgColor)
        ctx.fill(CGRect(x: gx, y: gy0, width: 3, height: gh))
        ctx.setFillColor(hex(0x6CD47A, 0.7).cgColor)
        ctx.fill(CGRect(x: gx, y: gy0 + gh / 2 - 1.2, width: 3, height: 2.4))
        let aimV = bowling.stage == 0 ? bowlingAim : bowling.aim
        ctx.setFillColor(hex(0xFFD23F).cgColor)
        ctx.fill(CGRect(x: gx - 1, y: gy0 + gh / 2 + aimV * gh / 2 - 0.4, width: 5, height: 0.8))
        text("aim", at: CGPoint(x: gx + 1.5, y: 24.5), size: 4.5, color: NSColor(white: 1, alpha: 0.6), ctx: ctx, center: true)
        // Power meter by the bowler
        if bowling.stage >= 1 {
            let p = bowling.stage == 1 ? bowlingPower : bowling.power
            ctx.setFillColor(NSColor(white: 1, alpha: 0.15).cgColor)
            ctx.fill(CGRect(x: pet.x + 16, y: 6, width: 40, height: 3))
            ctx.setFillColor(hex(0x6CD47A, 0.6).cgColor)
            ctx.fill(CGRect(x: pet.x + 16 + 40 * 0.78, y: 6, width: 40 * 0.14, height: 3))
            ctx.setFillColor(NSColor(calibratedHue: 0.33 * (1 - p), saturation: 0.8, brightness: 0.95, alpha: 1).cgColor)
            ctx.fill(CGRect(x: pet.x + 16, y: 6.6, width: 40 * p, height: 1.8))
        }
        let hint = bowling.stage == 0 ? "tap to lock aim (green = straight)" : bowling.stage == 1 ? "tap to lock power (green zone)" : ""
        if !hint.isEmpty { text(hint, at: CGPoint(x: pet.x + 16, y: 22), size: 5, color: NSColor(white: 1, alpha: 0.55), ctx: ctx) }
    }
}
