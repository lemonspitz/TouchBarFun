import AppKit

// MARK: - State

struct BalloonState {
    struct Obstacle {
        enum Kind { case bird, tree, cloud }
        var kind: Kind
        var x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat
        var vx: CGFloat
    }
    static let x: CGFloat = 80
    static let height: CGFloat = 15      // basket bottom to envelope top
    static let maxY: CGFloat = 12
    var y: CGFloat = 4                   // basket bottom above the ground
    var vy: CGFloat = 0
    var touches = 0
    var obstacles: [Obstacle] = []
    var stars: [Item] = []
    var speed: CGFloat = 55
    var distance: CGFloat = 0
    var spawn: Double = 1.0
    var bonus = 0
    var lastNeedsHigh: Bool?             // whether the previous obstacle had to be passed high
}

struct KeepyState {
    var ball = Item(kind: .soccer, x: 200, y: 16, scale: 1.1)
    var kicks = 0
    var bonus = 0
    var star: Item?
    var hintCooldown: Double = 0
}

struct WhackState {
    enum Kind { case none, mole, gold, friend }
    struct Hole { var x: CGFloat; var kind: Kind = .none; var t: Double = 0; var up: Double = 1; var whacked = false }
    var holes: [Hole] = []
    var spawn: Double = 0.6
    var hammerX: CGFloat = 0
    var hammerT: Double = 0
    var streak = 0
}

struct SliceState {
    var fruits: [Item] = []
    var lives = 3
    var spawn: Double = 0.6
    var elapsed: Double = 0
    var lastX: CGFloat?
    var swipeCount = 0
    var trail: [(x0: CGFloat, x1: CGFloat, age: Double)] = []
}

struct ArcheryState {
    var arrowsLeft = 10
    var targetX: CGFloat = 400
    var targetY: CGFloat = 14
    var wind: CGFloat = 0
    var charging = false
    var chargeT: Double = 0
    var arrow: Item?
    var path: [CGPoint] = []
    var ghost: [CGPoint] = []
    var stuck: [CGFloat] = []
    var wait: Double = 0
    var newTarget = false
}

struct RhythmState {
    struct Note { var time: Double; var ka: Bool; var big = false; var hit = false; var missed = false }
    struct Pop { var x: CGFloat; var color: UInt32; var big: Bool; var age: Double = 0 }
    /// Layout: exit button on the far left, the target right next to it, notes arrive from the right.
    static let exitRight: CGFloat = 24        // taps left of this exit
    static let playLeft: CGFloat = 32         // drum taps count right of this (the gap guards the exit)
    static let hitX: CGFloat = 46
    /// Touch Bar taps reach the app a little after the finger lands; judge them slightly earlier.
    static let inputLag = 0.03
    static let colors: [UInt32] = [0xE84A5F, 0x5FA8E8, 0xF28C28, 0x9B59D0]   // red, blue, orange, purple
    static let speed: CGFloat = 150
    var notes: [Note] = []
    var song: Double = -2
    var beat: Double = 60.0 / 112
    var combo = 0
    var maxCombo = 0
    var perfect = 0
    var misses = 0
    var lastTick = -1
    var judgement = ""
    var judgeT: Double = 0
    var flashSide = 0
    var flashT: Double = 0
    /// First finger of a possible two-finger tap: song time when it landed, and world time to time out.
    var pendingSong: Double?
    var pendingAt: Double = 0
    var pendingCount = 0
    static let fingerWindow = 0.09          // fingers landing this close together count as one hit
    var pops: [Pop] = []
    /// The note a tap is about to hit; it waits inside the target while the finger count settles.
    var claimed: Int?
    // Song list swiping
    var dragStartX: CGFloat?
    var dragStartOffset = 0
    var dragged = false
    var timing = ""
    var timingT: Double = 0
    // Song selection and playback
    var songIndex = 0
    var difficulty = 1
    var listOffset = 0
    var great = 0
    var good = 0
    var started = false
    var usingPlayer = false
    var lastAudio: Double = -1
    var audioStall: Double = 0
}

extension World {
    // MARK: - Dispatch

    var arcadeHUDText: String? {
        switch mode {
        case .balloon: return "★ \(balloon.bonus / 3)"
        case .keepy: return "Kicks \(keepy.kicks)"
        case .slice: return String(repeating: "♥︎", count: slice.lives) + String(repeating: "♡", count: max(0, 3 - slice.lives))
        case .archery:
            let w = archery.wind
            let arrow = abs(w) < 3 ? "calm" : (w > 0 ? "→" : "←") + String(format: " %.0f", abs(w))
            return "Arrows \(archery.arrowsLeft)  ·  Wind \(arrow)"
        case .rhythm: return currentSong.title + (rhythm.combo > 2 ? "  ·  Combo \(rhythm.combo)" : "")
        default: return arcade2HUDText
        }
    }

    func setupArcade(_ m: Mode) {
        switch m {
        case .balloon: pet.x = BalloonState.x; balloon = BalloonState()
        case .keepy: pet.x = 120; keepy = KeepyState(); keepy.ball.x = 140
        case .whack: pet.x = 22; whack = WhackState(); layoutHoles()
        case .slice: pet.x = 22; slice = SliceState()
        case .archery: pet.x = 40; archery = ArcheryState(); newArcheryTarget()
        case .rhythm: pet.x = World.W - 14; resetRhythmKeepingChoice()
        default: setupArcade2(m)
        }
    }

    func beginArcade() {
        switch mode {
        case .balloon: balloon = BalloonState()
        case .keepy: keepy = KeepyState(); keepy.ball.x = pet.x + 10; keepy.ball.vy = 30
        case .whack: whack = WhackState(); layoutHoles(); timeLeft = 30
        case .slice: slice = SliceState()
        case .archery: archery = ArcheryState(); newArcheryTarget()
        case .rhythm: resetRhythmKeepingChoice(); buildChart()
        default: beginArcade2()
        }
    }

    func arcadeTouchBegan(_ p: CGPoint) {
        switch mode {
        case .balloon: balloon.touches += 1
        case .keepy: kick(at: p.x)
        case .whack: bonk(at: p.x)
        case .slice: slice.lastX = p.x; slice.swipeCount = 0; sliceRange(p.x - 4, p.x + 4)
        case .archery:
            if archery.arrow == nil && archery.wait <= 0 && archery.arrowsLeft > 0 { archery.charging = true; archery.chargeT = 0 }
        case .rhythm: fingerDown()
        default: arcade2TouchBegan(p)
        }
    }

    func arcadeTouchMoved(_ p: CGPoint) {
        if mode != .slice { arcade2TouchMoved(p); return }
        if let last = slice.lastX {
            sliceRange(min(last, p.x), max(last, p.x))
            slice.lastX = p.x
        }
    }

    func arcadeTouchEnded(_ p: CGPoint) {
        switch mode {
        case .balloon: balloon.touches = max(0, balloon.touches - 1)
        case .slice:
            if slice.swipeCount >= 3 {
                score += slice.swipeCount
                addText("Combo ×\(slice.swipeCount)! +\(slice.swipeCount)", x: p.x, y: 20, color: hex(0xFFD23F))
                Sound.play("Hero", volume: 0.25)
            }
            slice.lastX = nil
            slice.swipeCount = 0
        case .archery: if archery.charging { fireArrow() }
        default: arcade2TouchEnded(p)
        }
    }

    func updateArcade(_ dt: Double) {
        switch mode {
        case .balloon: updateBalloon(dt)
        case .keepy: updateKeepy(dt)
        case .whack: updateWhack(dt)
        case .slice: updateSlice(dt)
        case .archery: updateArchery(dt)
        case .rhythm: updateRhythm(dt)
        default: updateArcade2(dt)
        }
    }

    func renderArcadeBehind(_ ctx: CGContext) {
        switch mode {
        case .balloon: renderBalloonBehind(ctx)
        case .whack: renderWhack(ctx)
        case .rhythm: renderRhythm(ctx)
        case .archery: renderArcheryBehind(ctx)
        default: renderArcade2Behind(ctx)
        }
    }

    func renderArcadeFront(_ ctx: CGContext) {
        switch mode {
        case .balloon: renderBalloonFront(ctx)
        case .keepy: renderKeepy(ctx)
        case .whack: renderHammer(ctx)
        case .slice: renderSlice(ctx)
        case .archery: renderArcheryFront(ctx)
        default: renderArcade2Front(ctx)
        }
    }

    // MARK: - 🎈 Balloon Ride

    private func balloonRects(_ y: CGFloat) -> [CGRect] {
        let x = BalloonState.x, g = World.ground
        return [CGRect(x: x - 4, y: g + y, width: 8, height: 7),            // basket + pet
                CGRect(x: x - 5, y: g + y + 7.5, width: 10, height: 7.5)]  // envelope
    }

    private func updateBalloon(_ dt: Double) {
        let fdt = CGFloat(dt)
        var b = balloon
        if phase == .playing {
            b.vy += (b.touches > 0 ? 48 : -32) * fdt
            b.vy = max(-18, min(18, b.vy))
            b.y += b.vy * fdt
            if b.y < 0 { b.y = 0; b.vy = 0 }
            if b.y > BalloonState.maxY { b.y = BalloonState.maxY; b.vy = 0 }
        } else {
            b.y = 4 + CGFloat(sin(t * 2)) * 0.8
        }
        pet.x = BalloonState.x
        pet.y = b.y + 0.6
        pet.facing = 1
        pet.moving = false
        balloon = b
        guard phase == .playing else { return }

        balloon.speed = min(55 + balloon.distance / 60, 120)
        balloon.distance += balloon.speed * fdt
        score = Int(balloon.distance / 40) + balloon.bonus

        balloon.spawn -= dt
        if balloon.spawn <= 0 {
            // Everything scrolls at one speed, so the gap between obstacles stays as spawned.
            // Switching between "fly high" and "fly low" gets enough time to climb or sink.
            let x = World.W + 12
            let needsHigh: Bool
            switch Int.random(in: 0..<4) {
            case 0, 1:
                let low = Bool.random()
                needsHigh = low
                let y = low ? CGFloat.random(in: World.ground + 1...World.ground + 6) : CGFloat.random(in: World.ground + 19...World.ground + 24)
                balloon.obstacles.append(.init(kind: .bird, x: x, y: y, w: 7, h: 3.5, vx: -balloon.speed))
            case 2:
                needsHigh = true
                balloon.obstacles.append(.init(kind: .tree, x: x, y: World.ground, w: 7, h: CGFloat.random(in: 8...10), vx: -balloon.speed))
            default:
                needsHigh = false
                balloon.obstacles.append(.init(kind: .cloud, x: x, y: World.ground + 19.5, w: 20, h: 9, vx: -balloon.speed))
            }
            let flip = balloon.lastNeedsHigh.map { $0 != needsHigh } ?? false
            balloon.lastNeedsHigh = needsHigh
            let pace = Double(min(1, 70 / balloon.speed))          // a little denser as it speeds up
            balloon.spawn = flip ? Double.random(in: 1.7...2.2) : Double.random(in: 0.9...1.5) * pace + 0.3
            if Double.random(in: 0..<1) < 0.45 {
                balloon.stars.append(Item(kind: .star, x: x + balloon.speed * CGFloat(balloon.spawn) / 2,
                                          y: World.ground + CGFloat.random(in: 2...20), vx: -balloon.speed, scale: 1.2))
            }
        }
        for i in balloon.obstacles.indices { balloon.obstacles[i].vx = -balloon.speed }
        for i in balloon.stars.indices { balloon.stars[i].vx = -balloon.speed }
        for i in balloon.obstacles.indices { balloon.obstacles[i].x += balloon.obstacles[i].vx * fdt }
        for i in balloon.stars.indices { balloon.stars[i].x += balloon.stars[i].vx * fdt }
        balloon.obstacles.removeAll { $0.x < -30 }
        balloon.stars.removeAll { $0.x < -10 }

        let rects = balloonRects(balloon.y)
        if let si = balloon.stars.firstIndex(where: { s in rects.contains { $0.insetBy(dx: -2, dy: -2).contains(CGPoint(x: s.x, y: s.y + 2)) } }) {
            let s = balloon.stars.remove(at: si)
            balloon.bonus += 3
            addText("+3", x: s.x, y: s.y + 4, color: hex(0xFFD23F))
            Sound.play("Tink", volume: 0.3)
        }
        for o in balloon.obstacles {
            let r = CGRect(x: o.x - o.w / 2, y: o.y, width: o.w, height: o.h).insetBy(dx: 1, dy: 0.6)
            if rects.contains(where: { $0.insetBy(dx: 0.8, dy: 0.5).intersects(r) }) {
                flash = 0.35
                Sound.play("Basso")
                burst(.spark(hex(0xE84A5F)), at: BalloonState.x, World.ground + balloon.y + 11, count: 10)
                resultText = "🎈 Popped after \(Int(balloon.distance / 20))m"
                endRound()
                return
            }
        }
    }

    private func renderBalloonBehind(_ ctx: CGContext) {
        for o in balloon.obstacles {
            switch o.kind {
            case .tree:
                let img = Decor.pine.image
                ctx.draw(img, in: CGRect(x: o.x - o.w / 2 - 1, y: o.y - 0.3, width: o.w + 2, height: o.h + 1))
            case .cloud:
                ctx.setFillColor(hex(0x5A6070, 0.95).cgColor)
                for (dx, dy, r) in [(CGFloat(-6), CGFloat(2), CGFloat(5)), (0, 3.5, 6), (6, 2, 5), (0, 0.5, 5)] {
                    ctx.fillEllipse(in: CGRect(x: o.x + dx - r, y: o.y + dy, width: r * 2, height: r * 1.3))
                }
                if Int(t * 3) % 4 == 0 {
                    ctx.setStrokeColor(hex(0xFFE066).cgColor)
                    ctx.setLineWidth(0.7)
                    ctx.move(to: CGPoint(x: o.x, y: o.y + 1)); ctx.addLine(to: CGPoint(x: o.x - 1.5, y: o.y - 2))
                    ctx.addLine(to: CGPoint(x: o.x + 0.5, y: o.y - 2)); ctx.addLine(to: CGPoint(x: o.x - 1, y: o.y - 5))
                    ctx.strokePath()
                }
            case .bird:
                let flap = CGFloat(sin(t * 14 + Double(o.x))) * 1.6
                ctx.setFillColor(hex(0x2A2A3A).cgColor)
                ctx.fillEllipse(in: CGRect(x: o.x - 3, y: o.y + 0.8, width: 6, height: 2.2))
                ctx.setStrokeColor(hex(0x2A2A3A).cgColor)
                ctx.setLineWidth(0.9)
                ctx.move(to: CGPoint(x: o.x - 2.5, y: o.y + 2 + flap)); ctx.addLine(to: CGPoint(x: o.x, y: o.y + 2))
                ctx.addLine(to: CGPoint(x: o.x + 2.5, y: o.y + 2 + flap)); ctx.strokePath()
                ctx.setFillColor(hex(0xF0892B).cgColor)
                ctx.fill(CGRect(x: o.x - 4, y: o.y + 1.6, width: 1.2, height: 0.7))
                ctx.setFillColor(NSColor.white.cgColor)
                ctx.fill(CGRect(x: o.x - 2.4, y: o.y + 2.1, width: 0.6, height: 0.6))
            }
        }
        for s in balloon.stars { drawItem(ctx, .star, x: s.x, y: s.y, scale: s.scale) }

        // Envelope + ropes (pet sits in the basket in front of these).
        let x = BalloonState.x, base = World.ground + balloon.y
        ctx.setStrokeColor(hex(0x8B5A2B).cgColor)
        ctx.setLineWidth(0.4)
        for dx: CGFloat in [-3.6, 3.6] {
            ctx.move(to: CGPoint(x: x + dx, y: base + 3)); ctx.addLine(to: CGPoint(x: x + dx * 0.8, y: base + 8.5)); ctx.strokePath()
        }
        let env = CGRect(x: x - 5.5, y: base + 7.5, width: 11, height: 8.5)
        ctx.saveGState()
        ctx.addEllipse(in: env); ctx.clip()
        let stripes: [UInt32] = [0xE84A5F, 0xFFD23F, 0x5FA8E8, 0x6CD47A, 0xE84A5F]
        for (i, c) in stripes.enumerated() {
            ctx.setFillColor(hex(c).cgColor)
            ctx.fill(CGRect(x: env.minX + CGFloat(i) * env.width / 5, y: env.minY, width: env.width / 5 + 0.1, height: env.height))
        }
        ctx.setFillColor(NSColor(white: 1, alpha: 0.3).cgColor)
        ctx.fillEllipse(in: CGRect(x: env.minX + 2, y: env.midY + 1, width: 2.5, height: 2.5))
        ctx.restoreGState()
    }

    private func renderBalloonFront(_ ctx: CGContext) {
        let x = BalloonState.x, base = World.ground + balloon.y
        ctx.setFillColor(hex(0xA0703A).cgColor)
        ctx.fill(CGRect(x: x - 4, y: base, width: 8, height: 3.2))
        ctx.setFillColor(hex(0x7A4E2D).cgColor)
        ctx.fill(CGRect(x: x - 4, y: base + 1.4, width: 8, height: 0.5))
        if phase == .playing && balloon.touches > 0 {
            ctx.setFillColor(hex(0xFFB347, 0.9).cgColor)
            ctx.fillEllipse(in: CGRect(x: x - 1, y: base + 7 + CGFloat(sin(t * 30)) * 0.3, width: 2, height: 2.4))
        }
    }

    // MARK: - ⚽ Keepy Uppy

    private func kick(at x: CGFloat) {
        let b = keepy.ball
        let dx = b.x - x
        guard abs(dx) < 18 else { return }
        guard b.y < 15 else {
            if keepy.hintCooldown <= 0 { addText("Wait for it…", x: b.x, y: 22, color: NSColor(white: 1, alpha: 0.7)); keepy.hintCooldown = 1 }
            return
        }
        keepy.ball.vy = CGFloat.random(in: 55...61)
        keepy.ball.vx = max(-80, min(80, dx * 4 + CGFloat.random(in: -12...12)))
        keepy.kicks += 1
        score = keepy.kicks + keepy.bonus
        if keepy.kicks % 10 == 0 { addText("\(keepy.kicks) kicks!", x: b.x, y: 20, color: hex(0xFFD23F)) }
        burst(.spark(.white), at: b.x, World.ground + b.y, count: 4)
        Sound.play("Pop", volume: 0.3)
        if pet.y <= 0.01 { pet.vy = 45 }
    }

    private func updateKeepy(_ dt: Double) {
        let fdt = CGFloat(dt)
        applyGravity(dt)
        pet.moving = false
        keepy.hintCooldown -= dt
        let target = keepy.ball.x - pet.facing * 4
        if abs(target - pet.x) > 4 { _ = move(toward: target, speed: 190, dt: dt); pet.walkPhase += dt * 6 }
        guard phase == .playing else { return }
        var b = keepy.ball
        let g = 105 + CGFloat(min(keepy.kicks, 40))
        b.vy -= g * fdt
        b.x += b.vx * fdt
        b.y += b.vy * fdt
        b.vx *= 1 - 0.25 * fdt
        if b.x < 8 { b.x = 8; b.vx = abs(b.vx) * 0.9 }
        if b.x > playMaxX { b.x = playMaxX; b.vx = -abs(b.vx) * 0.9 }
        keepy.ball = b
        if keepy.star == nil && Double.random(in: 0..<1) < dt * 0.2 {
            keepy.star = Item(kind: .star, x: CGFloat.random(in: 30...(playMaxX - 20)), y: CGFloat.random(in: 13...22), scale: 1.2)
        }
        if var s = keepy.star {
            s.age += dt
            if hypot(s.x - b.x, s.y - (b.y + 3)) < 6 {
                keepy.bonus += 3
                score = keepy.kicks + keepy.bonus
                addText("+3", x: s.x, y: s.y + 3, color: hex(0xFFD23F))
                Sound.play("Tink", volume: 0.3)
                keepy.star = nil
            } else { keepy.star = s.age > 6 ? nil : s }
        }
        if b.y <= 0 {
            flash = 0.3
            Sound.play("Basso")
            resultText = "⚽ Dropped after \(keepy.kicks) kick\(keepy.kicks == 1 ? "" : "s")"
            endRound()
        }
    }

    private func renderKeepy(_ ctx: CGContext) {
        if phase == .playing {
            ctx.setFillColor(NSColor(white: 1, alpha: 0.05).cgColor)
            ctx.fill(CGRect(x: 0, y: World.ground, width: playMaxX + 8, height: 15))
            text("kick zone", at: CGPoint(x: playMaxX - 4, y: World.ground + 13.2), size: 4.5, color: NSColor(white: 1, alpha: 0.3), ctx: ctx, alignRight: true)
        }
        if let s = keepy.star { drawItem(ctx, .star, x: s.x, y: World.ground + s.y, scale: s.scale) }
        let b = keepy.ball
        ctx.setFillColor(NSColor(white: 0, alpha: 0.3).cgColor)
        ctx.fillEllipse(in: CGRect(x: b.x - 3, y: World.ground - 0.6, width: 6, height: 1.2))
        drawItem(ctx, .soccer, x: b.x, y: World.ground + b.y, scale: b.scale)
    }

    // MARK: - 🔨 Whack-a-Mole

    private func layoutHoles() {
        let n = max(5, min(9, Int((playMaxX - 50) / 62)))
        whack.holes = (0..<n).map { i in WhackState.Hole(x: 50 + (playMaxX - 50) * (CGFloat(i) + 0.5) / CGFloat(n)) }
    }

    private func rise(_ h: WhackState.Hole) -> CGFloat {
        guard h.kind != .none else { return 0 }
        if h.t < 0.15 { return CGFloat(h.t / 0.15) }
        if h.t < h.up { return 1 }
        return max(0, CGFloat(1 - (h.t - h.up) / 0.15))
    }

    private func bonk(at x: CGFloat) {
        guard !whack.holes.isEmpty else { return }
        let spacing = (playMaxX - 50) / CGFloat(whack.holes.count)
        guard let i = whack.holes.indices.min(by: { abs(whack.holes[$0].x - x) < abs(whack.holes[$1].x - x) }),
              abs(whack.holes[i].x - x) < spacing / 2 else { return }
        whack.hammerX = whack.holes[i].x
        whack.hammerT = 0.18
        var h = whack.holes[i]
        guard h.kind != .none, !h.whacked, rise(h) > 0.35 else { whack.streak = 0; return }
        h.whacked = true
        h.t = max(h.t, h.up)
        switch h.kind {
        case .friend:
            score = max(0, score - 3); whack.streak = 0; flash = 0.3
            addText("Ouch! -3", x: h.x, y: 18, color: hex(0xFF9AA8))
            Sound.play("Basso")
        case .gold:
            score += 3; whack.streak += 1
            addText("+3", x: h.x, y: 18, color: hex(0xFFD23F))
            burst(.spark(hex(0xFFD23F)), at: h.x, World.ground + 6, count: 8)
            Sound.play("Glass")
        default:
            score += 1; whack.streak += 1
            addText("+1", x: h.x, y: 18, color: .white)
            burst(.spark(.white), at: h.x, World.ground + 6, count: 4)
            Sound.play("Pop", volume: 0.3)
        }
        if whack.streak > 0 && whack.streak % 5 == 0 {
            score += 2
            addText("Streak \(whack.streak)! +2", x: h.x, y: 24, color: hex(0x7BE07B))
        }
        if pet.y <= 0.01 { pet.vy = 40 }
        whack.holes[i] = h
    }

    private func updateWhack(_ dt: Double) {
        applyGravity(dt)
        pet.facing = 1
        whack.hammerT = max(0, whack.hammerT - dt)
        for i in whack.holes.indices where whack.holes[i].kind != .none {
            whack.holes[i].t += dt
            if whack.holes[i].t > whack.holes[i].up + 0.15 { whack.holes[i].kind = .none; whack.holes[i].whacked = false }
        }
        guard phase == .playing else { return }
        timeLeft -= dt
        if timeLeft <= 0 { timeLeft = 0; resultText = "🔨 Time's up"; endRound(); return }
        whack.spawn -= dt
        if whack.spawn <= 0 {
            let progress = 1 - timeLeft / 30
            whack.spawn = Double.random(in: 0.35...0.8) * (1 - progress * 0.4)
            let free = whack.holes.indices.filter { whack.holes[$0].kind == .none }
            if let i = free.randomElement() {
                let roll = Double.random(in: 0..<1)
                whack.holes[i].kind = roll < 0.72 ? .mole : roll < 0.84 ? .gold : .friend
                whack.holes[i].t = 0
                whack.holes[i].up = (1.1 - progress * 0.5) * (whack.holes[i].kind == .gold ? 0.7 : 1)
                whack.holes[i].whacked = false
            }
        }
    }

    private func renderWhack(_ ctx: CGContext) {
        let g = World.ground
        for h in whack.holes {
            ctx.setFillColor(hex(0x1A120C).cgColor)
            ctx.fillEllipse(in: CGRect(x: h.x - 7.5, y: g - 1.6, width: 15, height: 3.2))
            let r = rise(h)
            guard r > 0 else { continue }
            ctx.saveGState()
            ctx.clip(to: CGRect(x: h.x - 12, y: g, width: 24, height: World.H))
            switch h.kind {
            case .friend:
                let s = species
                let hgt = CGFloat(Species.pixelHeight) * 0.95
                drawCreature(ctx, s, x: h.x, y: -hgt + hgt * r, scale: 0.95, facing: -1, frame: 0)
            case .mole, .gold:
                let kind: ItemKind = h.kind == .gold ? .goldMole : .mole
                let hgt = kind.pixelSize.height * 1.4
                drawItem(ctx, kind, x: h.x, y: g - hgt + hgt * r, scale: 1.4)
                if h.whacked {
                    text("✦", at: CGPoint(x: h.x, y: g + hgt * r + 1), size: 5, color: hex(0xFFD23F), ctx: ctx, center: true)
                }
            case .none: break
            }
            ctx.restoreGState()
            ctx.setFillColor(hex(0x5A3A22).cgColor)
            ctx.fillEllipse(in: CGRect(x: h.x - 7.5, y: g - 1.6, width: 15, height: 1.6))
        }
    }

    private func renderHammer(_ ctx: CGContext) {
        guard whack.hammerT > 0 else { return }
        let f = CGFloat(1 - whack.hammerT / 0.18)       // 0 → 1 as it swings down
        let a = (75 - 75 * f) * .pi / 180
        let pivot = CGPoint(x: whack.hammerX + 10, y: World.ground + 4)
        let head = CGPoint(x: pivot.x - cos(a) * 11, y: pivot.y + sin(a) * 11)
        ctx.setStrokeColor(hex(0xC68A4A).cgColor)
        ctx.setLineWidth(1.4)
        ctx.move(to: pivot); ctx.addLine(to: head); ctx.strokePath()
        ctx.setFillColor(hex(0x8A8F99).cgColor)
        ctx.fill(CGRect(x: head.x - 3, y: head.y - 2, width: 6, height: 4))
    }

    // MARK: - 🍉 Fruit Slice

    private func fruitRadius(_ k: ItemKind) -> CGFloat { k.pixelSize.width * 1.3 / 2 }

    private func sliceRange(_ x0: CGFloat, _ x1: CGFloat) {
        guard phase == .playing else { return }
        slice.trail.append((x0, x1, 0))
        var i = 0
        while i < slice.fruits.count {
            let f = slice.fruits[i]
            let r = fruitRadius(f.kind) * 0.8
            guard f.x + r >= x0 && f.x - r <= x1 && f.y > 1 else { i += 1; continue }
            slice.fruits.remove(at: i)
            let cy = World.ground + f.y + fruitRadius(f.kind)
            if f.kind == .bomb {
                slice.lives -= 1
                flash = 0.4
                Sound.play("Basso")
                burst(.spark(hex(0xFFB347)), at: f.x, cy, count: 14)
                addText("BOOM!", x: f.x, y: cy + 4, color: hex(0xFF9AA8))
                if slice.lives <= 0 { resultText = "🍉 Sliced \(score) fruit"; endRound(); return }
                continue
            }
            score += 1
            slice.swipeCount += 1
            let juice: UInt32 = f.kind == .watermelon ? 0xE84A5F : f.kind == .orange ? 0xF0892B : 0xFFE58A
            burst(.spark(hex(juice)), at: f.x, cy, count: 6)
            for left in [true, false] {
                particles.append(Particle(kind: .half(f.kind, left), x: f.x, y: World.ground + f.y,
                                          vx: left ? -18 : 18, vy: 10, life: 0.8, maxLife: 0.8, size: 1.3))
            }
            Sound.play("Pop", volume: 0.25)
        }
    }

    private func updateSlice(_ dt: Double) {
        let fdt = CGFloat(dt)
        for i in slice.trail.indices { slice.trail[i].age += dt }
        slice.trail.removeAll { $0.age > 0.25 }
        guard phase == .playing else { return }
        slice.elapsed += dt
        slice.spawn -= dt
        if slice.spawn <= 0 {
            slice.spawn = Double.random(in: 0.9...1.4) * max(0.55, 1 - slice.elapsed / 120)
            var used: [CGFloat] = []
            for _ in 0..<Int.random(in: 1...3) {
                let bomb = slice.elapsed > 5 && Double.random(in: 0..<1) < 0.18
                let kind: ItemKind = bomb ? .bomb : [.watermelon, .orange, .apple].randomElement()!
                var x = CGFloat.random(in: 45...(playMaxX - 15))
                for _ in 0..<6 where used.contains(where: { abs($0 - x) < 26 }) { x = CGFloat.random(in: 45...(playMaxX - 15)) }
                used.append(x)
                slice.fruits.append(Item(kind: kind, x: x, y: -6, vx: CGFloat.random(in: -18...18),
                                         vy: CGFloat.random(in: 50...60), scale: 1.3))
            }
        }
        var i = 0
        while i < slice.fruits.count {
            var f = slice.fruits[i]
            f.vy -= 80 * fdt
            f.x += f.vx * fdt
            f.y += f.vy * fdt
            if f.y < -7 && f.vy < 0 {
                slice.fruits.remove(at: i)
                if f.kind != .bomb {
                    slice.lives -= 1
                    addText("Missed!", x: f.x, y: 8, color: hex(0xFF9AA8))
                    Sound.play("Funk", volume: 0.3)
                    if slice.lives <= 0 { resultText = "🍉 Sliced \(score) fruit"; endRound(); return }
                }
                continue
            }
            slice.fruits[i] = f
            i += 1
        }
    }

    private func renderSlice(_ ctx: CGContext) {
        for f in slice.fruits {
            let wobble = f.kind == .bomb && Int(t * 8) % 2 == 0
            drawItem(ctx, f.kind, x: f.x + (wobble ? 0.3 : 0), y: World.ground + f.y, scale: f.scale)
        }
        for tr in slice.trail {
            let a = CGFloat(1 - tr.age / 0.25)
            ctx.setFillColor(NSColor(white: 1, alpha: 0.75 * a).cgColor)
            ctx.fill(CGRect(x: tr.x0 - 2, y: 15.5, width: tr.x1 - tr.x0 + 4, height: 0.8 * a + 0.2))
        }
    }

    // MARK: - 🏹 Archery

    private var archeryPower: CGFloat {
        let f = archery.chargeT.truncatingRemainder(dividingBy: 1.4) / 1.4
        return CGFloat(f < 0.5 ? f * 2 : 2 - f * 2)
    }

    private func newArcheryTarget() {
        archery.targetX = CGFloat.random(in: 200...min(playMaxX - 12, 560))
        archery.targetY = CGFloat.random(in: 8...20)
        archery.wind = CGFloat.random(in: -25...25)
        archery.stuck.removeAll()
        archery.ghost.removeAll()
    }

    private func fireArrow() {
        archery.charging = false
        let v = 110 + archeryPower * 260
        let angle: CGFloat = 0.3
        archery.arrow = Item(kind: .ball, x: pet.x + 10, y: 11, vx: v * cos(angle), vy: v * sin(angle))
        archery.path = []
        archery.arrowsLeft -= 1
        Sound.play("Blow", volume: 0.2)
    }

    private func updateArchery(_ dt: Double) {
        let fdt = CGFloat(dt)
        pet.facing = 1
        if archery.charging { archery.chargeT += dt }
        guard phase == .playing else { return }
        if archery.wait > 0 {
            archery.wait -= dt
            if archery.wait <= 0 {
                if archery.newTarget { newArcheryTarget(); archery.newTarget = false }
                if archery.arrowsLeft == 0 {
                    resultText = "🏹 \(score) points from 10 arrows"
                    endRound()
                }
            }
            return
        }
        guard var a = archery.arrow else { return }
        let prev = a
        a.vx += archery.wind * fdt
        a.vy -= 130 * fdt
        a.x += a.vx * fdt
        a.y += a.vy * fdt
        if Int(a.x) % 3 == 0 { archery.path.append(CGPoint(x: a.x, y: a.y)) }
        if prev.x < archery.targetX && a.x >= archery.targetX {
            let f = (archery.targetX - prev.x) / max(a.x - prev.x, 0.01)
            let y = prev.y + (a.y - prev.y) * f
            let dy = y - archery.targetY
            if abs(dy) <= 5 {
                let pts = abs(dy) <= 1 ? 10 : abs(dy) <= 2 ? 8 : abs(dy) <= 3 ? 6 : abs(dy) <= 4 ? 4 : 2
                score += pts
                archery.stuck.append(dy)
                archery.arrow = nil
                archery.ghost = []
                archery.wait = 1.0
                archery.newTarget = true
                addText(pts == 10 ? "BULLSEYE! +10" : "+\(pts)", x: archery.targetX, y: archery.targetY + World.ground + 7,
                        color: pts == 10 ? hex(0xFFD23F) : .white)
                Sound.play(pts == 10 ? "Hero" : "Pop", volume: 0.35)
                if pts == 10 { burst(.spark(hex(0xFFD23F)), at: archery.targetX, World.ground + archery.targetY, count: 10) }
                return
            }
        }
        if a.y < 0 || a.x > World.W + 10 {
            archery.arrow = nil
            archery.ghost = archery.path
            archery.wait = 0.5
            addText(a.x < archery.targetX ? "Too short" : "Missed", x: min(a.x, playMaxX - 20), y: 12, color: hex(0xFF9AA8))
            Sound.play("Funk", volume: 0.25)
            return
        }
        archery.arrow = a
    }

    private func renderArcheryBehind(_ ctx: CGContext) {
        let tx = archery.targetX, ty = World.ground + archery.targetY
        ctx.setStrokeColor(hex(0x7A4E2D).cgColor)
        ctx.setLineWidth(0.9)
        ctx.move(to: CGPoint(x: tx - 2, y: World.ground)); ctx.addLine(to: CGPoint(x: tx, y: ty)); ctx.strokePath()
        ctx.move(to: CGPoint(x: tx + 2, y: World.ground)); ctx.addLine(to: CGPoint(x: tx, y: ty)); ctx.strokePath()
        for (r, c) in [(CGFloat(5), UInt32(0xF5F5F5)), (4, 0x2A2A33), (3, 0x3A7BD5), (2, 0xE84A5F), (1, 0xFFD23F)] {
            ctx.setFillColor(hex(c).cgColor)
            ctx.fillEllipse(in: CGRect(x: tx - r * 0.45, y: ty - r, width: r * 0.9, height: r * 2))
        }
        // Wind sock
        let dir: CGFloat = archery.wind >= 0 ? 1 : -1
        let len = min(abs(archery.wind) / 25, 1) * 6
        ctx.setStrokeColor(NSColor(white: 1, alpha: 0.5).cgColor)
        ctx.move(to: CGPoint(x: tx + 9, y: World.ground)); ctx.addLine(to: CGPoint(x: tx + 9, y: World.ground + 14)); ctx.strokePath()
        ctx.setFillColor(hex(0xF0892B).cgColor)
        ctx.fill(CGRect(x: dir > 0 ? tx + 9 : tx + 9 - len, y: World.ground + 12.4, width: max(len, 0.8), height: 1.4))
        // Last miss, to help adjust.
        ctx.setFillColor(NSColor(white: 1, alpha: 0.25).cgColor)
        for p in archery.ghost { ctx.fill(CGRect(x: p.x, y: World.ground + p.y, width: 0.6, height: 0.6)) }
    }

    private func drawArrow(_ ctx: CGContext, at p: CGPoint, angle: CGFloat) {
        let c = cos(angle), s = sin(angle)
        let tail = CGPoint(x: p.x - c * 7, y: p.y - s * 7)
        ctx.setStrokeColor(hex(0xC68A4A).cgColor)
        ctx.setLineWidth(0.6)
        ctx.move(to: tail); ctx.addLine(to: p); ctx.strokePath()
        ctx.setFillColor(hex(0xDDDDDD).cgColor)
        ctx.move(to: CGPoint(x: p.x + c * 1.5, y: p.y + s * 1.5))
        ctx.addLine(to: CGPoint(x: p.x - s * 0.8, y: p.y + c * 0.8))
        ctx.addLine(to: CGPoint(x: p.x + s * 0.8, y: p.y - c * 0.8))
        ctx.closePath(); ctx.fillPath()
        ctx.setFillColor(hex(0xE84A5F).cgColor)
        ctx.fill(CGRect(x: tail.x - 0.6, y: tail.y - 0.6, width: 1.2, height: 1.2))
    }

    private func renderArcheryFront(_ ctx: CGContext) {
        // Arrows stuck in the target.
        for dy in archery.stuck {
            drawArrow(ctx, at: CGPoint(x: archery.targetX + 1, y: World.ground + archery.targetY + dy), angle: 0)
        }
        if let a = archery.arrow {
            drawArrow(ctx, at: CGPoint(x: a.x, y: World.ground + a.y), angle: atan2(a.vy, a.vx))
        }
        // Bow
        let bx = pet.x + 9, by = World.ground + 11
        let pull = archery.charging ? archeryPower * 3.5 : 0
        ctx.setStrokeColor(hex(0x8B5A2B).cgColor)
        ctx.setLineWidth(1)
        ctx.addArc(center: CGPoint(x: bx - 3, y: by), radius: 6, startAngle: -1.1, endAngle: 1.1, clockwise: false)
        ctx.strokePath()
        let top = CGPoint(x: bx - 3 + 6 * cos(1.1), y: by + 6 * sin(1.1)), bottom = CGPoint(x: top.x, y: by - 6 * sin(1.1))
        ctx.setStrokeColor(NSColor(white: 1, alpha: 0.8).cgColor)
        ctx.setLineWidth(0.3)
        ctx.move(to: top); ctx.addLine(to: CGPoint(x: bx - 1 - pull, y: by)); ctx.addLine(to: bottom); ctx.strokePath()
        if archery.charging || (archery.arrow == nil && archery.wait <= 0 && archery.arrowsLeft > 0 && phase == .playing) {
            drawArrow(ctx, at: CGPoint(x: bx + 5 - pull, y: by), angle: 0)
        }
        // Power meter
        if archery.charging {
            let p = archeryPower
            ctx.setFillColor(NSColor(white: 1, alpha: 0.2).cgColor)
            ctx.fill(CGRect(x: pet.x + 17, y: World.ground + 2, width: 2.2, height: 20))
            ctx.setFillColor(NSColor(calibratedHue: 0.33 * (1 - p), saturation: 0.8, brightness: 0.95, alpha: 1).cgColor)
            ctx.fill(CGRect(x: pet.x + 17, y: World.ground + 2, width: 2.2, height: 20 * p))
        } else if phase == .playing && archery.arrow == nil && archery.wait <= 0 && archery.arrowsLeft > 0 {
            text("hold, then release", at: CGPoint(x: pet.x + 17, y: 21), size: 4.8, color: NSColor(white: 1, alpha: 0.5), ctx: ctx)
        }
    }

    // MARK: - 🥁 Drum Beat

    var currentSong: Song {
        let songs = SongLibrary.shared.songs
        return songs[min(max(rhythm.songIndex, 0), songs.count - 1)]
    }

    private func resetRhythmKeepingChoice() {
        let (song, diff, offset) = (rhythm.songIndex, rhythm.difficulty, rhythm.listOffset)
        rhythm = RhythmState()
        rhythm.songIndex = song
        rhythm.difficulty = diff
        rhythm.listOffset = offset
        MusicPlayer.shared.stop()
    }

    /// Drum notes come from the chosen song's melody.
    private func buildChart() {
        let song = currentSong
        rhythm.notes = ChartBuilder.chart(song, difficulty: rhythm.difficulty).map { RhythmState.Note(time: $0.time, ka: $0.ka, big: $0.big) }
        rhythm.beat = 60 / max(song.bpm, 30)
        rhythm.song = -2
        DrumKit.shared.prepare()
    }

    /// Fingers that land within a few milliseconds count as one hit: 1 = 🔴 red, 2 = 🔵 blue,
    /// 3 = 🟠 big red, 4 = 🟣 big blue. Timing is judged from the first finger, so the short wait costs nothing.
    private func fingerDown() {
        if rhythm.pendingSong != nil && t - rhythm.pendingAt <= RhythmState.fingerWindow {
            rhythm.pendingCount += 1
            if rhythm.pendingCount >= 4 { resolveFingers() }
            return
        }
        if rhythm.pendingSong != nil { resolveFingers() }
        rhythm.pendingSong = rhythm.song
        rhythm.pendingAt = t
        rhythm.pendingCount = 1
        // Hold the note being hit inside the target straight away, so it never slides past while we count fingers.
        let tap = rhythm.song - RhythmState.inputLag
        rhythm.claimed = rhythm.notes.indices.filter { !rhythm.notes[$0].hit && !rhythm.notes[$0].missed && abs(rhythm.notes[$0].time - tap) < 0.16 }
            .min { abs(rhythm.notes[$0].time - tap) < abs(rhythm.notes[$1].time - tap) }
    }

    private func resolveFingers() {
        guard let first = rhythm.pendingSong else { return }
        let n = rhythm.pendingCount
        rhythm.pendingSong = nil
        rhythm.pendingCount = 0
        drum(fingers: n, at: first)
    }

    /// Mouse in the pet window: click = red, right-click = blue, add Shift for the big ones.
    func mouseDrum(fingers: Int) {
        if mode == .rhythm && phase == .playing { drum(fingers: fingers, at: rhythm.song) }
    }

    /// Right-click in the pet window plays a blue note (a mouse has no second finger).
    func secondaryTap(_ p: CGPoint) {
        if mode == .rhythm && phase == .playing { drum(fingers: 2, at: rhythm.song) }
        else if mode == .mines && phase == .playing { flagTile(at: p.x) }
        else { touchBegan(p) }
    }

    private func noteColor(_ n: RhythmState.Note) -> UInt32 { RhythmState.colors[(n.ka ? 1 : 0) + (n.big ? 2 : 0)] }

    private func drum(fingers: Int, at tapTime: Double) {
        let ka = fingers % 2 == 0, bigHit = fingers >= 3
        let songTime = tapTime - RhythmState.inputLag
        rhythm.flashSide = ka ? 1 : -1
        rhythm.flashT = 0.12
        DrumKit.shared.hit(ka: ka, big: bigHit)
        let claimed = rhythm.claimed
        rhythm.claimed = nil
        let candidates = rhythm.notes.indices.filter { !rhythm.notes[$0].hit && !rhythm.notes[$0].missed && rhythm.notes[$0].ka == ka }
        let nearest = candidates.min(by: { abs(rhythm.notes[$0].time - songTime) < abs(rhythm.notes[$1].time - songTime) })
        guard let i = (claimed.flatMap { candidates.contains($0) ? $0 : nil }) ?? nearest else { return }
        let offset = rhythm.notes[i].time - songTime          // > 0: you tapped early
        let d = abs(offset)
        guard d < 0.16 else { return }
        rhythm.notes[i].hit = true
        let note = rhythm.notes[i]
        var (pts, label): (Int, String) = d < 0.05 ? (3, "Perfect!") : d < 0.1 ? (2, "Great") : (1, "Good")
        if pts == 3 { rhythm.perfect += 1 } else if pts == 2 { rhythm.great += 1 } else { rhythm.good += 1 }
        if note.big {
            if bigHit { pts *= 2; label = "BIG " + label } else { label += " — use \(ka ? 4 : 3) fingers!" }
        }
        rhythm.combo += 1
        rhythm.maxCombo = max(rhythm.maxCombo, rhythm.combo)
        score += pts + rhythm.combo / 10
        rhythm.judgement = label
        rhythm.judgeT = 0.5
        rhythm.timing = d < 0.05 ? "" : offset > 0 ? "early" : "late"
        rhythm.timingT = 0.5
        // The note pops inside the target circle, however early or late the tap was.
        let x = RhythmState.hitX
        rhythm.pops.append(RhythmState.Pop(x: x, color: noteColor(note), big: note.big))
    }

    private func updateRhythm(_ dt: Double) {
        if rhythm.pendingSong != nil && t - rhythm.pendingAt > RhythmState.fingerWindow { resolveFingers() }
        rhythm.flashT -= dt
        rhythm.judgeT -= dt
        rhythm.timingT -= dt
        for i in rhythm.pops.indices { rhythm.pops[i].age += dt }
        rhythm.pops.removeAll { $0.age > 0.35 }
        pet.x = World.W - 14
        pet.facing = -1
        let beatPhase = (rhythm.song / rhythm.beat).truncatingRemainder(dividingBy: 1)
        pet.y = phase == .playing && rhythm.song > 0 ? CGFloat(abs(sin(beatPhase * .pi))) * 2 : 0
        guard phase == .playing else { return }
        // The music is the clock once it starts, so the notes stay locked to the song.
        MusicPlayer.shared.update()
        if !rhythm.started {
            rhythm.song += dt
            if rhythm.song >= 0 {
                rhythm.started = true
                rhythm.usingPlayer = MusicPlayer.shared.play(currentSong)
            }
        } else if rhythm.usingPlayer && MusicPlayer.shared.isPlaying {
            let audio = MusicPlayer.shared.currentTime
            let predicted = rhythm.song + dt
            // If the player's clock ever stops moving, keep the game running on its own clock.
            rhythm.audioStall = audio == rhythm.lastAudio ? rhythm.audioStall + dt : 0
            rhythm.lastAudio = audio
            if rhythm.audioStall > 0.25 { rhythm.usingPlayer = false; rhythm.song = predicted }
            else { rhythm.song = abs(audio - predicted) > 0.08 ? audio : predicted + (audio - predicted) * 0.15 }
        } else {
            rhythm.song += dt
        }
        for i in rhythm.notes.indices where i != rhythm.claimed && !rhythm.notes[i].hit && !rhythm.notes[i].missed && rhythm.song - rhythm.notes[i].time > 0.16 {
            rhythm.notes[i].missed = true
            rhythm.misses += 1
            rhythm.combo = 0
            rhythm.judgement = "Miss"
            rhythm.judgeT = 0.5
        }
        if rhythm.notes.isEmpty || rhythm.song > (rhythm.notes.last?.time ?? 0) + 1.5 { finishSong() }
    }

    private func finishSong() {
        MusicPlayer.shared.stop()
        let total = max(rhythm.notes.count, 1)
        let accuracy = Double(rhythm.perfect * 3 + rhythm.great * 2 + rhythm.good) / Double(total * 3)
        let grade = accuracy >= 0.95 ? "S" : accuracy >= 0.85 ? "A" : accuracy >= 0.7 ? "B" : accuracy >= 0.5 ? "C" : "D"
        let key = "rhythm:\(currentSong.id):\(rhythm.difficulty)"
        save.best[key] = max(save.best[key] ?? 0, score)
        save.best[key + ":acc"] = max(save.best[key + ":acc"] ?? 0, Int(accuracy * 100))
        resultText = "🥁 Grade \(grade) · \(Int(accuracy * 100))%  ·  Perfect \(rhythm.perfect)  Great \(rhythm.great)  Good \(rhythm.good)  Miss \(rhythm.misses)"
        Sound.play(grade == "S" || grade == "A" ? "Hero" : "Glass", volume: 0.3)
        endRound()
    }

    // MARK: Song picker (ready / results screen)
    // The Touch Bar only senses horizontal position, so every control has its own x range:
    // difficulty on the left, ◀ ▶ arrows, and song cards in between.

    private var menuRight: CGFloat { World.W - 24 }
    private var cardsLeft: CGFloat { 62 }
    private var cardsRight: CGFloat { menuRight - 18 }
    private var visibleCards: Int { max(1, Int((cardsRight - cardsLeft) / 116)) }
    private static var noteCounts: [String: Int] = [:]

    private func noteCount(_ song: Song, _ difficulty: Int) -> Int {
        let key = "\(song.id):\(difficulty)"
        if let n = World.noteCounts[key] { return n }
        let n = ChartBuilder.chart(song, difficulty: difficulty).count
        World.noteCounts[key] = n
        return n
    }

    // Slide left/right to scroll the song list; a tap without sliding selects.
    func songMenuPress(_ p: CGPoint) {
        rhythm.dragStartX = p.x
        rhythm.dragStartOffset = rhythm.listOffset
        rhythm.dragged = false
    }

    func songMenuDrag(_ p: CGPoint) {
        guard let start = rhythm.dragStartX else { return }
        let dx = p.x - start
        if abs(dx) > 8 { rhythm.dragged = true }
        guard rhythm.dragged else { return }
        let slot = (cardsRight - cardsLeft) / CGFloat(visibleCards)
        let maxOffset = max(0, SongLibrary.shared.songs.count - visibleCards)
        let offset = min(max(rhythm.dragStartOffset - Int((dx / slot).rounded()), 0), maxOffset)
        if offset != rhythm.listOffset {
            rhythm.listOffset = offset
            Sound.play("Tink", volume: 0.1)
        }
    }

    func songMenuRelease(_ p: CGPoint) {
        defer { rhythm.dragStartX = nil }
        if rhythm.dragStartX != nil && !rhythm.dragged { songMenuTap(p) }
    }

    func songMenuTap(_ p: CGPoint) {
        let songs = SongLibrary.shared.songs
        let visible = visibleCards
        if p.x < 42 {
            rhythm.difficulty = (rhythm.difficulty + 1) % 3
            Sound.play("Tink", volume: 0.2)
        } else if p.x < cardsLeft {
            rhythm.listOffset = max(0, rhythm.listOffset - visible)
            Sound.play("Pop", volume: 0.15)
        } else if p.x >= cardsRight {
            if rhythm.listOffset + visible < songs.count { rhythm.listOffset += visible }
            Sound.play("Pop", volume: 0.15)
        } else {
            let k = Int((p.x - cardsLeft) / ((cardsRight - cardsLeft) / CGFloat(visible)))
            let i = rhythm.listOffset + k
            guard songs.indices.contains(i), phase == .ready || phaseTimer > 0.7 else { return }
            rhythm.songIndex = i
            beginRound()
        }
    }

    func drawSongMenu(_ ctx: CGContext) {
        ctx.setFillColor(NSColor(white: 0, alpha: 0.6).cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: World.W, height: World.H))
        ctx.setFillColor(NSColor(white: 1, alpha: 0.18).cgColor)
        ctx.fillEllipse(in: CGRect(x: World.W - 19, y: World.H / 2 - 7, width: 14, height: 14))
        text("✕", at: CGPoint(x: World.W - 12, y: World.H / 2 - 4.5), size: 7, color: .white, ctx: ctx, center: true)

        let header = phase == .over ? "\(resultText ?? "")   +\(lastReward) ⭐️" : "🥁 Drum Beat — pick a song   (🔴 1 finger · 🔵 2 fingers)"
        text(header, at: CGPoint(x: 6, y: 21.5), size: 6, color: .white, ctx: ctx, bold: true)

        // Difficulty toggle
        let diffColors: [UInt32] = [0x6CD47A, 0xFFD23F, 0xE84A5F]
        ctx.addPath(CGPath(roundedRect: CGRect(x: 3, y: 2, width: 37, height: 17), cornerWidth: 3, cornerHeight: 3, transform: nil))
        ctx.setFillColor(hex(diffColors[rhythm.difficulty], 0.85).cgColor)
        ctx.fillPath()
        text(ChartBuilder.difficulties[rhythm.difficulty], at: CGPoint(x: 21.5, y: 9.5), size: 6, color: .black, ctx: ctx, center: true, bold: true)
        text("tap to change", at: CGPoint(x: 21.5, y: 4), size: 3.8, color: NSColor(white: 0, alpha: 0.6), ctx: ctx, center: true)

        // Arrows
        let songs = SongLibrary.shared.songs
        let visible = visibleCards
        for (x, label, enabled) in [(CGFloat(51), "◀︎", rhythm.listOffset > 0), (cardsRight + 9, "▶︎", rhythm.listOffset + visible < songs.count)] {
            text(label, at: CGPoint(x: x, y: 8), size: 9, color: NSColor(white: 1, alpha: enabled ? 0.9 : 0.2), ctx: ctx, center: true)
        }
        // Song cards
        let slot = (cardsRight - cardsLeft) / CGFloat(visible)
        for k in 0..<visible {
            let i = rhythm.listOffset + k
            guard songs.indices.contains(i) else { break }
            let song = songs[i]
            let r = CGRect(x: cardsLeft + slot * CGFloat(k) + 2, y: 2, width: slot - 4, height: 17)
            ctx.addPath(CGPath(roundedRect: r, cornerWidth: 3, cornerHeight: 3, transform: nil))
            let base: UInt32 = song.kind == .classical ? 0x3A4A7A : song.kind == .original ? 0x6A3A7A : song.kind == .audio ? 0x7A4A2E : 0x2E6A5A
            ctx.setFillColor(hex(base, i == rhythm.songIndex && phase == .over ? 1 : 0.85).cgColor)
            ctx.fillPath()
            var titleSize: CGFloat = 6.2
            let full = "\(song.badge) \(song.title)"
            while titleSize > 4.2 && NSAttributedString(string: full, attributes: [.font: NSFont.systemFont(ofSize: titleSize, weight: .heavy)]).size().width > r.width - 4 { titleSize -= 0.4 }
            text(full, at: CGPoint(x: r.minX + 2.5, y: 12.4), size: titleSize, color: .white, ctx: ctx, bold: true)
            text(song.subtitle, at: CGPoint(x: r.minX + 2.5, y: 7.6), size: 4.4, color: NSColor(white: 1, alpha: 0.75), ctx: ctx)
            let key = "rhythm:\(song.id):\(rhythm.difficulty)"
            let best = save.best[key].map { "  ·  best \($0) (\(save.best[key + ":acc"] ?? 0)%)" } ?? ""
            text("♩\(Int(song.bpm.rounded()))  ·  \(noteCount(song, rhythm.difficulty)) notes\(best)", at: CGPoint(x: r.minX + 2.5, y: 3.2), size: 4.2,
                 color: hex(0xFFE58A), ctx: ctx)
        }
    }

    private func renderRhythm(_ ctx: CGContext) {
        let y = World.ground + 9
        let hx = RhythmState.hitX
        if phase == .playing {
            if rhythm.flashT > 0 {
                ctx.setFillColor(hex(rhythm.flashSide > 0 ? 0x5FA8E8 : 0xE84A5F, 0.18).cgColor)
                ctx.fill(CGRect(x: RhythmState.playLeft, y: 0, width: World.W - RhythmState.playLeft, height: World.H))
            }
            text("🔴 1 finger   🔵 2   🟠 3   🟣 4  — tap anywhere right of the target", at: CGPoint(x: (World.W + hx) / 2 - 20, y: 21.5),
                 size: 5.2, color: NSColor(white: 1, alpha: 0.45), ctx: ctx, center: true)
            // Exit button on the far left
            ctx.setFillColor(NSColor(white: 0, alpha: 0.45).cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: RhythmState.exitRight + 2, height: World.H))
            ctx.setFillColor(NSColor(white: 1, alpha: 0.3).cgColor)
            ctx.fill(CGRect(x: RhythmState.exitRight + 2, y: 0, width: 0.5, height: World.H))
            ctx.setFillColor(NSColor(white: 1, alpha: 0.2).cgColor)
            ctx.fillEllipse(in: CGRect(x: 6, y: 9, width: 14, height: 14))
            text("✕", at: CGPoint(x: 13, y: 11.5), size: 7, color: .white, ctx: ctx, center: true)
            text("exit", at: CGPoint(x: 13, y: 2.5), size: 4.5, color: NSColor(white: 1, alpha: 0.6), ctx: ctx, center: true)
        }
        // Lane and target
        ctx.setFillColor(NSColor(white: 1, alpha: 0.12).cgColor)
        ctx.fill(CGRect(x: hx, y: y - 0.3, width: World.W - hx, height: 0.6))
        ctx.setStrokeColor(NSColor(white: 1, alpha: 0.35).cgColor)
        ctx.setLineWidth(0.5)
        ctx.strokeEllipse(in: CGRect(x: hx - 7.5, y: y - 7.5, width: 15, height: 15))
        ctx.setStrokeColor(NSColor(white: 1, alpha: 0.85).cgColor)
        ctx.setLineWidth(0.8)
        ctx.strokeEllipse(in: CGRect(x: hx - 5, y: y - 5, width: 10, height: 10))
        // Notes (latest first so earlier notes sit on top); hit notes are gone, missed ones fade away.
        for (index, n) in rhythm.notes.enumerated().reversed() where !n.hit {
            // A note that's being hit waits inside the target until it pops.
            let x = index == rhythm.claimed ? hx : hx + CGFloat(n.time - rhythm.song) * RhythmState.speed
            guard x < World.W + 8 && x > RhythmState.exitRight else { continue }
            let r: CGFloat = n.big ? 6.6 : 4.4
            ctx.setAlpha(n.missed ? max(0, 0.35 - CGFloat(rhythm.song - n.time) * 0.5) : 1)
            if n.ka {   // ring = more than one finger
                ctx.setStrokeColor(hex(noteColor(n)).cgColor)
                ctx.setLineWidth(0.6)
                ctx.strokeEllipse(in: CGRect(x: x - r - 1.2, y: y - r - 1.2, width: (r + 1.2) * 2, height: (r + 1.2) * 2))
            }
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
            ctx.setFillColor(hex(noteColor(n)).cgColor)
            ctx.fillEllipse(in: CGRect(x: x - r + 0.6, y: y - r + 0.6, width: r * 2 - 1.2, height: r * 2 - 1.2))
            ctx.setFillColor(NSColor(white: 0.1, alpha: 1).cgColor)
            let eye: CGFloat = n.big ? 1.1 : 0.8
            ctx.fill(CGRect(x: x - r * 0.38 - eye / 2, y: y + r * 0.15, width: eye, height: eye))
            ctx.fill(CGRect(x: x + r * 0.38 - eye / 2, y: y + r * 0.15, width: eye, height: eye))
            if n.big { text(n.ka ? "4" : "3", at: CGPoint(x: x, y: y - r + 0.8), size: 4.2, color: .white, ctx: ctx, center: true, bold: true) }
            ctx.setAlpha(1)
        }
        // Pops for notes you hit
        for p in rhythm.pops {
            let f = CGFloat(p.age / 0.35)
            let r = min((p.big ? 6.6 : 4.4) * (1 + f * 0.6), 7.5)   // grows only to the target's outer ring
            ctx.setStrokeColor(hex(p.color, 1 - f).cgColor)
            ctx.setLineWidth(1.2 * (1 - f) + 0.3)
            ctx.strokeEllipse(in: CGRect(x: p.x - r, y: y - r, width: r * 2, height: r * 2))
            ctx.setFillColor(hex(p.color, (1 - f) * 0.35).cgColor)
            ctx.fillEllipse(in: CGRect(x: p.x - r * 0.6, y: y - r * 0.6, width: r * 1.2, height: r * 1.2))
        }
        if rhythm.judgeT > 0 {
            let c = rhythm.judgement == "Miss" ? hex(0xFF9AA8) : rhythm.judgement == "Perfect!" ? hex(0xFFD23F) : .white
            text(rhythm.judgement, at: CGPoint(x: RhythmState.hitX + 12, y: 20), size: 6.5, color: c, ctx: ctx, bold: true)
        }
        if rhythm.timingT > 0 && !rhythm.timing.isEmpty {
            text(rhythm.timing, at: CGPoint(x: RhythmState.hitX + 12, y: 0.8), size: 5, color: NSColor(white: 1, alpha: 0.7), ctx: ctx)
        }
        if phase == .playing && rhythm.song < 0 {
            text("Get ready… \(Int(ceil(-rhythm.song)))", at: CGPoint(x: 150, y: 17), size: 8, color: .white, ctx: ctx, center: true, bold: true)
        }
    }
}
