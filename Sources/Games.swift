import AppKit

// MARK: - Per-game state

struct BaseballState {
    enum Pitch: String { case fastball = "Fastball", changeup = "Changeup", curve = "Curveball", sinker = "Sinker" }
    var pitcherID = "cat"
    var strikes = 0
    var pitches = 0
    var ball: Item?            // pitch on its way to the plate
    var hit: Item?             // ball flying off the bat
    var pitch: Pitch = .fastball
    var speed: CGFloat = 200
    var windup: Double = 1.2   // countdown to the next pitch
    var swing: Double = 0      // > 0 while the bat is moving
    var swung = false          // already swung at this pitch
    var pitcherHop: CGFloat = 0
}

struct CatchState {
    enum Stage { case petWindup, toPlayer, holding, toPet, dropped }
    var stage: Stage = .petWindup
    var ball = Item(kind: .baseball, x: 0, y: 0)
    var gloveX: CGFloat = 400
    var gloveTarget: CGFloat = 400
    var lives = 3
    var streak = 0
    var throwCount = 0
    var timer: Double = 0.8
    var targetX: CGFloat = 0
    var petStartX: CGFloat = 0
    var autoThrow = false
}

struct RaceState {
    struct Runner {
        var speciesID: String
        var lane: Int
        var base: CGFloat
        var phase: Double
        var d: CGFloat = 0
        var v: CGFloat = 0
        var walk: Double = 0
        var finish: Double?
    }
    static let length: CGFloat = 2000      // shown as 100 m
    static let screenX: CGFloat = 90       // where the pet is drawn
    var rivals: [Runner] = []
    var d: CGFloat = 0
    var v: CGFloat = 0
    var countdown: Double = 3
    var time: Double = 0
    var lastSide = -1
    var finished = false
}

struct FishingState {
    enum Kind { case small, big, gold, boot }
    enum Mood { case roam, approach, nibble, bite, flee }
    struct Fish {
        var x: CGFloat
        var vx: CGFloat
        var kind: Kind
        var mood: Mood = .roam
        var timer: Double = 0
        var nibbles = 0
    }
    static let waterStart: CGFloat = 70
    static let surface: CGFloat = 5
    var fish: [Fish] = []
    var bobberX: CGFloat?
    var cast: Item?        // bobber in flight
    var caught: Item?      // catch flying back to the dock
    var dip: CGFloat = 0
    var biteStart: Double = 0
}

struct MemoryState {
    static let colors: [UInt32] = [0xE84A5F, 0xFFD23F, 0x56B84A, 0x5FA8E8]
    static let symbols = ["♥", "★", "♣", "♦"]
    static let sounds = ["Tink", "Pop", "Bottle", "Glass"]
    var sequence: [Int] = []
    var showIndex = 0
    var inputIndex = 0
    var showing = true
    var timer: Double = 1
    var lit: Int?
    var litTimer: Double = 0
}

// MARK: - Shared

extension World {
    var groundScroll: CGFloat {
        switch mode {
        case .runner: return runDistance
        case .race: return race.d
        case .balloon: return balloon.distance
        case .bridge: return bridge.cam
        case .highway: return highway.distance
        default: return 0
        }
    }

    var gameHUDText: String? {
        switch mode {
        case .baseball:
            return "Strikes " + String(repeating: "●", count: baseball.strikes) + String(repeating: "○", count: max(0, 3 - baseball.strikes))
        case .playCatch:
            let c = playCatch
            return String(repeating: "♥︎", count: c.lives) + String(repeating: "♡", count: max(0, 3 - c.lives))
                + (c.streak > 1 ? "  Streak \(c.streak)" : "")
        case .race:
            guard race.countdown <= 0 else { return nil }
            let pos = 1 + race.rivals.filter { $0.d > race.d }.count
            return String(format: "%dm  ·  %.2fs  ·  P%d/4", Int(min(race.d, RaceState.length) / 20), race.time, pos)
        case .memory:
            return memory.showing ? "Round \(memory.sequence.count) · Watch 👀" : "Round \(memory.sequence.count) · Your turn 👆"
        default:
            return arcadeHUDText
        }
    }

    func rivalIDs(_ n: Int) -> [String] {
        Array(Species.all.map(\.id).filter { $0 != save.speciesID }.shuffled().prefix(n))
    }

    /// Ballistic arc that lands at (x1, landY) after `time` seconds under `gravity`.
    func arc(_ kind: ItemKind, from p: CGPoint, to x1: CGFloat, landY: CGFloat, time: CGFloat,
             gravity: CGFloat = 150, scale: CGFloat = 1.1) -> Item {
        Item(kind: kind, x: p.x, y: p.y, vx: (x1 - p.x) / time,
             vy: (landY - p.y + 0.5 * gravity * time * time) / time, scale: scale)
    }

    /// Gravity for a ball launched from `fromY` that peaks at `apex` and lands at `landY` after `time` seconds.
    /// Keeping the apex fixed keeps fast and slow shots inside the 30pt bar.
    func arcGravity(fromY: CGFloat, landY: CGFloat, apex: CGFloat, time: CGFloat) -> CGFloat {
        let up = max(apex - fromY, 0.5), down = max(apex - landY, 0.5)
        let root = ((2 * up).squareRoot() + (2 * down).squareRoot()) / max(time, 0.05)
        return root * root
    }

    func fly(_ it: inout Item, _ dt: Double, gravity: CGFloat = 150) {
        it.vy -= gravity * CGFloat(dt)
        it.x += it.vx * CGFloat(dt)
        it.y += it.vy * CGFloat(dt)
        it.age += dt
    }

    func setupGame(_ m: Mode) {
        pet.facing = 1
        pet.moving = false
        switch m {
        case .baseball:
            pet.x = 40
            baseball = BaseballState()
            baseball.pitcherID = rivalIDs(1)[0]
        case .playCatch:
            pet.x = 40
            playCatch = CatchState()
            playCatch.gloveX = playMaxX - 60
            playCatch.gloveTarget = playCatch.gloveX
        case .race:
            pet.x = RaceState.screenX
            race = RaceState()
            race.rivals = rivalIDs(3).enumerated().map { i, id in
                RaceState.Runner(speciesID: id, lane: i + 1, base: CGFloat.random(in: 172...212), phase: Double.random(in: 0...6))
            }
        case .fishing:
            pet.x = 36
            pet.y = 2
            fishing = FishingState()
            fishing.fish = (0..<4).map { _ in newFish() }
        case .memory:
            pet.x = 30
            memory = MemoryState()
        default: setupArcade(m)
        }
    }

    func beginGame() {
        switch mode {
        case .baseball:
            let pitcher = baseball.pitcherID
            baseball = BaseballState()
            baseball.pitcherID = pitcher
        case .playCatch:
            let glove = playCatch.gloveX
            playCatch = CatchState()
            playCatch.gloveX = glove
            playCatch.gloveTarget = glove
        case .race:
            let rivals = race.rivals.map { RaceState.Runner(speciesID: $0.speciesID, lane: $0.lane, base: CGFloat.random(in: 172...212), phase: Double.random(in: 0...6)) }
            race = RaceState()
            race.rivals = rivals
        case .fishing:
            timeLeft = 45
            fishing.bobberX = nil
            fishing.cast = nil
            fishing.caught = nil
        case .memory:
            memory = MemoryState()
            memory.sequence = [Int.random(in: 0..<4)]
        default: beginArcade()
        }
    }

    func gameTouchBegan(_ p: CGPoint) {
        switch mode {
        case .baseball: swingBat()
        case .playCatch: catchTouch(p)
        case .race: raceTap(p)
        case .fishing: fishingTap(p)
        case .memory: memoryTap(p)
        default: arcadeTouchBegan(p)
        }
    }

    func gameTouchMoved(_ p: CGPoint) {
        if mode == .playCatch, playCatch.stage != .holding { playCatch.gloveTarget = p.x }
    }

    func updateGame(_ dt: Double) {
        switch mode {
        case .baseball: updateBaseball(dt)
        case .playCatch: updateCatch(dt)
        case .race: updateRace(dt)
        case .fishing: updateFishing(dt)
        case .memory: updateMemory(dt)
        default: updateArcade(dt)
        }
    }

    // MARK: - ⚾ Home Run Derby

    var plateX: CGFloat { pet.x + 15 }
    var pitcherX: CGFloat { min(pet.x + 300, playMaxX - 24) }

    private func swingBat() {
        guard baseball.swing <= 0 else { return }
        baseball.swing = 0.22
        guard let ball = baseball.ball, !baseball.swung else { return }
        baseball.swung = true
        let timing = (ball.x - plateX) / baseball.speed      // > 0: early
        let miss = abs(timing)
        guard miss < 0.11 else {
            addText(timing > 0 ? "Too early!" : "Too late!", x: plateX + 30, y: 18, color: hex(0xFF9AA8))
            return
        }
        let (runs, label, power): (Int, String, CGFloat) =
            miss < 0.035 ? (4, "HOME RUN! 💥", 1) : miss < 0.065 ? (2, "Double!", 0.65) : (1, "Single!", 0.4)
        score += runs
        baseball.hit = Item(kind: .baseball, x: plateX, y: ball.y, vx: 220 + 380 * power, vy: 35 + 75 * power, scale: 1.2)
        baseball.ball = nil
        baseball.windup = 1.8
        pet.vy = runs == 4 ? 80 : 50
        burst(.spark(.white), at: plateX, ball.y + World.ground, count: 5)
        if runs == 4 {
            addText("\(label)  \(Int.random(in: 380...470)) ft", x: plateX + 70, y: 18, color: hex(0xFFD23F))
            burst(.spark(hex(0xFFD23F)), at: plateX + 40, 15, count: 14)
            Sound.play("Hero")
        } else {
            addText(label, x: plateX + 50, y: 18, color: .white)
            Sound.play("Pop")
        }
    }

    private func updateBaseball(_ dt: Double) {
        let fdt = CGFloat(dt)
        applyGravity(dt)
        baseball.swing = max(0, baseball.swing - dt)
        guard phase == .playing else { return }

        if var h = baseball.hit {
            fly(&h, dt, gravity: 140)
            if h.y <= 0 && h.vy < 0 { h.y = 0; h.vy = -h.vy * 0.4; h.vx *= 0.6 }
            baseball.hit = (h.x > World.W + 10 || h.age > 2.5) ? nil : h
        }

        if var ball = baseball.ball {
            let start = pitcherX - 8
            ball.x -= baseball.speed * fdt
            let p = max(0, (start - ball.x) / (start - plateX))
            switch baseball.pitch {
            case .fastball, .changeup: ball.y = 11 - p * 2
            case .curve: ball.y = 11 + 6 * sin(min(p, 1) * .pi) - p * 3
            case .sinker: ball.y = 11 - p * 5
            }
            baseball.ball = ball
            if ball.x < pet.x - 25 {
                baseball.ball = nil
                baseball.strikes += 1
                baseball.windup = 1.0
                addText(baseball.swung ? "Strike \(baseball.strikes)!" : "Strike \(baseball.strikes) — looking!", x: plateX + 30, y: 18, color: hex(0xFF9AA8))
                Sound.play("Funk")
                if baseball.strikes >= 3 {
                    flash = 0.3
                    resultText = "⚾ Struck out with \(score) run\(score == 1 ? "" : "s")"
                    endRound()
                }
            }
            return
        }

        baseball.windup -= dt
        baseball.pitcherHop = baseball.windup < 0.35 ? sin(CGFloat((0.35 - max(baseball.windup, 0)) / 0.35) * .pi) * 3 : 0
        if baseball.windup <= 0 {
            baseball.pitches += 1
            let pitch: BaseballState.Pitch = baseball.pitches <= 2 ? .fastball : [.fastball, .fastball, .changeup, .curve, .sinker].randomElement()!
            baseball.pitch = pitch
            let base = min(190 + CGFloat(baseball.pitches) * 9, 390)
            baseball.speed = base * (pitch == .changeup ? 0.66 : pitch == .curve ? 0.85 : 1)
            baseball.ball = Item(kind: .baseball, x: pitcherX - 8, y: 11, scale: 1.1)
            baseball.swung = false
            baseball.pitcherHop = 0
            addText(pitch.rawValue, x: pitcherX, y: 21, color: NSColor(white: 1, alpha: 0.7))
        }
    }

    private func renderBaseball(_ ctx: CGContext) {
        let night = hex(0x5E4630), day = hex(0x9C7A54)
        ctx.setFillColor((isNightTime ? night : day).cgColor)
        ctx.fill(CGRect(x: pet.x - 18, y: 0, width: pitcherX - pet.x + 36, height: World.ground))
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fill(CGRect(x: plateX - 2.5, y: World.ground - 0.6, width: 5, height: 1))
        // Plate timing guide
        ctx.setFillColor(NSColor(white: 1, alpha: 0.12).cgColor)
        ctx.fill(CGRect(x: plateX - 0.5, y: World.ground + 2, width: 1, height: 18))
        drawCreature(ctx, Species.byID(baseball.pitcherID), x: pitcherX, y: baseball.pitcherHop, scale: 1.2, facing: -1, frame: 0)
        for b in [baseball.ball, baseball.hit].compactMap({ $0 }) {
            ctx.setFillColor(NSColor(white: 0, alpha: 0.3).cgColor)
            ctx.fillEllipse(in: CGRect(x: b.x - 2, y: World.ground - 0.6, width: 4, height: 1.2))
        }
    }

    private func renderBaseballFront(_ ctx: CGContext) {
        let pivot = CGPoint(x: pet.x + 4, y: World.ground + pet.y + petSize.height * 0.45)
        let rest: CGFloat = 115, end: CGFloat = -35
        let deg = baseball.swing > 0 ? rest + (end - rest) * CGFloat(1 - baseball.swing / 0.22) : rest
        let a = deg * .pi / 180
        ctx.setStrokeColor(hex(0xC68A4A).cgColor)
        ctx.setLineWidth(1.8)
        ctx.setLineCap(.round)
        ctx.move(to: pivot)
        ctx.addLine(to: CGPoint(x: pivot.x + cos(a) * 12, y: pivot.y + sin(a) * 12))
        ctx.strokePath()
        for b in [baseball.ball, baseball.hit].compactMap({ $0 }) {
            drawItem(ctx, .baseball, x: b.x, y: World.ground + b.y, scale: b.scale)
        }
    }

    // MARK: - 🧤 Play Catch

    private var gloveCatchY: CGFloat { 8 }
    private var petReach: CGFloat { 150 }

    private func catchTouch(_ p: CGPoint) {
        switch playCatch.stage {
        case .holding:
            throwBack(to: min(max(p.x, 12), playCatch.gloveX - 30), auto: false)
        default:
            playCatch.gloveTarget = p.x
        }
    }

    private func throwBack(to x: CGFloat, auto: Bool) {
        playCatch.targetX = x
        playCatch.petStartX = pet.x
        playCatch.autoThrow = auto
        playCatch.ball = arc(.baseball, from: CGPoint(x: playCatch.gloveX - 4, y: 10), to: x, landY: 5, time: 1.0)
        playCatch.stage = .toPet
    }

    private func loseCatchLife(_ msg: String) {
        playCatch.lives -= 1
        playCatch.streak = 0
        playCatch.stage = .dropped
        playCatch.timer = 1.0
        playCatch.ball.vy = 25
        flash = 0.25
        Sound.play("Basso")
        addText(msg, x: playCatch.ball.x, y: 16, color: hex(0xFF9AA8))
        if playCatch.lives <= 0 {
            resultText = "🧤 \(score) point\(score == 1 ? "" : "s") of catch"
            endRound()
        }
    }

    private func updateCatch(_ dt: Double) {
        applyGravity(dt)
        pet.moving = false
        var c = playCatch
        let gloveMin = pet.x + 110
        c.gloveTarget = min(max(c.gloveTarget, gloveMin), playMaxX)
        let step = 700 * CGFloat(dt)
        c.gloveX += max(-step, min(step, c.gloveTarget - c.gloveX))
        c.gloveX = min(max(c.gloveX, gloveMin), playMaxX)
        playCatch = c
        guard phase == .playing else { return }

        switch playCatch.stage {
        case .petWindup:
            playCatch.timer -= dt
            if !move(toward: 40, speed: 120, dt: dt) { pet.walkPhase += dt * 5; return }
            pet.facing = 1
            if playCatch.timer <= 0 {
                playCatch.throwCount += 1
                let n = CGFloat(playCatch.throwCount)
                var time = max(0.8, 1.6 - n * 0.04) * CGFloat.random(in: 0.85...1.15)
                if Double.random(in: 0..<1) < 0.2 { time *= 1.4 }       // pop fly
                let land = CGFloat.random(in: max(pet.x + 140, playMaxX - 260)...playMaxX - 6)
                playCatch.ball = arc(.baseball, from: CGPoint(x: pet.x + 8, y: 12), to: land, landY: gloveCatchY, time: time)
                playCatch.stage = .toPlayer
                pet.vy = 40
            }
        case .toPlayer:
            fly(&playCatch.ball, dt)
            let b = playCatch.ball
            if b.vy < 0 && b.y <= 13 && b.y >= 3 && abs(b.x - playCatch.gloveX) < 10 {
                playCatch.streak += 1
                let pts = 1 + playCatch.streak / 5
                score += pts
                addText(playCatch.streak % 5 == 0 ? "Streak \(playCatch.streak)! +\(pts)" : "Nice catch! +\(pts)",
                        x: playCatch.gloveX, y: 18, color: .white)
                Sound.play("Pop")
                playCatch.stage = .holding
                playCatch.timer = 3
            } else if b.y <= 0 || b.x > World.W + 10 {
                loseCatchLife("Missed!")
            }
        case .holding:
            playCatch.ball.x = playCatch.gloveX
            playCatch.ball.y = gloveCatchY
            playCatch.timer -= dt
            if playCatch.timer <= 0 { throwBack(to: pet.x, auto: true) }
        case .toPet:
            fly(&playCatch.ball, dt)
            if !move(toward: playCatch.targetX, speed: 160, dt: dt) { pet.walkPhase += dt * 6 }
            let b = playCatch.ball
            if b.vy < 0 && b.y <= petSize.height * 0.75 && abs(b.x - pet.x) < 10 {
                let dist = abs(playCatch.targetX - playCatch.petStartX)
                let bonus = playCatch.autoThrow ? 0 : dist < 60 ? 1 : dist < 120 ? 2 : 3
                score += bonus
                if bonus > 0 { addText("\(petName) caught it! +\(bonus)", x: pet.x, y: 18, color: hex(0xFFD23F)) }
                burst(.item(.heart), at: pet.x, petSize.height, count: 2)
                Sound.play("Tink")
                pet.vy = 50
                playCatch.stage = .petWindup
                playCatch.timer = 0.7
            } else if b.y <= 0 {
                loseCatchLife("Too far!")
            }
        case .dropped:
            fly(&playCatch.ball, dt)
            if playCatch.ball.y <= 0 { playCatch.ball.y = 0; playCatch.ball.vy = abs(playCatch.ball.vy) * 0.3; playCatch.ball.vx *= 0.5 }
            playCatch.timer -= dt
            if playCatch.timer <= 0 && phase == .playing { playCatch.stage = .petWindup; playCatch.timer = 0.6 }
        }
    }

    private func renderCatch(_ ctx: CGContext) {
        let c = playCatch
        if c.stage == .holding && phase == .playing {
            // Throw zones: how far the pet will have to run (farther = more points, too far = dropped).
            let zones: [(CGFloat, CGFloat, NSColor, String)] = [(0, 60, hex(0x56B84A), "+1"), (60, 120, hex(0xFFD23F), "+2"), (120, petReach, hex(0xF0892B), "+3")]
            for (lo, hi, col, label) in zones {
                for dir: CGFloat in [-1, 1] {
                    let a = pet.x + dir * lo, b = pet.x + dir * hi
                    let x0 = max(4, min(a, b)), x1 = min(c.gloveX - 30, max(a, b))
                    guard x1 > x0 else { continue }
                    ctx.setFillColor(col.withAlphaComponent(0.45).cgColor)
                    ctx.fill(CGRect(x: x0, y: 0, width: x1 - x0, height: World.ground))
                    if dir > 0 { text(label, at: CGPoint(x: (x0 + x1) / 2, y: World.ground + 1), size: 5, color: col, ctx: ctx, center: true) }
                }
            }
            text("← tap where to throw", at: CGPoint(x: c.gloveX - 12, y: 8), size: 5.5, color: NSColor(white: 1, alpha: 0.8), ctx: ctx, alignRight: true)
        }
        drawItem(ctx, .glove, x: c.gloveX, y: World.ground + 1, scale: 1.6)
        if c.stage != .holding {
            ctx.setFillColor(NSColor(white: 0, alpha: 0.3).cgColor)
            ctx.fillEllipse(in: CGRect(x: c.ball.x - 2, y: World.ground - 0.6, width: 4, height: 1.2))
        }
    }

    private func renderCatchFront(_ ctx: CGContext) {
        guard phase == .playing || playCatch.stage == .dropped else { return }
        if playCatch.stage == .petWindup { return }
        drawItem(ctx, .baseball, x: playCatch.ball.x, y: World.ground + playCatch.ball.y, scale: 1.1)
    }

    // MARK: - 🏁 Run Race

    private func raceTap(_ p: CGPoint) {
        guard race.countdown <= 0, !race.finished else { return }
        let side = p.x < (World.W - 22) / 2 ? 0 : 1
        let alternating = side != race.lastSide
        race.v = min(race.v + (alternating ? 36 : 20), 330)
        race.lastSide = side
        if Int.random(in: 0..<3) == 0 { burst(.spark(hex(0xC9B48A)), at: pet.x - 8, World.ground + 1, count: 1) }
    }

    private func updateRace(_ dt: Double) {
        let fdt = CGFloat(dt)
        pet.x = RaceState.screenX
        pet.facing = 1
        guard phase != .ready else { pet.moving = false; return }
        if phase == .playing && race.countdown > 0 {
            let before = Int(ceil(race.countdown))
            race.countdown -= dt
            let after = Int(ceil(max(race.countdown, 0)))
            if after != before { Sound.play(after > 0 ? "Tink" : "Glass", volume: 0.45) }
            return
        }
        if phase == .playing && !race.finished { race.time += dt }

        race.v = max(0, race.v - race.v * 1.1 * fdt - (race.finished ? 90 * fdt : 0))
        race.d += race.v * fdt
        pet.walkPhase += Double(race.v) * dt / 22
        pet.moving = race.v > 15

        for i in race.rivals.indices {
            var r = race.rivals[i]
            var target = r.base + 22 * CGFloat(sin(race.time * 0.9 + r.phase))
            if RaceState.length - r.d < 500 { target += 35 }             // final kick
            if r.finish != nil { target = 0 }
            r.v += (target - r.v) * min(1, 2 * fdt)
            r.d += r.v * fdt
            r.walk += Double(r.v) * dt / 22
            if r.finish == nil && r.d >= RaceState.length { r.finish = race.time }
            race.rivals[i] = r
        }

        if phase == .playing && !race.finished && race.d >= RaceState.length {
            race.finished = true
            let place = 1 + race.rivals.filter { $0.finish != nil }.count
            score = [10, 6, 3, 1][place - 1] + max(0, Int((16 - race.time) * 2))
            let medal = ["🥇 1st", "🥈 2nd", "🥉 3rd", "4th"][place - 1]
            resultText = String(format: "%@ place · %.2fs", medal, race.time)
            Sound.play(place == 1 ? "Hero" : "Glass")
            if place == 1 { burst(.item(.star), at: pet.x, 18, count: 6) }
            endRound()
        }
    }

    private func renderRace(_ ctx: CGContext) {
        let sx = { (d: CGFloat) -> CGFloat in RaceState.screenX + (d - self.race.d) }
        // Distance markers every 10 m, start line and checkered finish.
        var m: CGFloat = 0
        while m <= RaceState.length {
            let x = sx(m)
            if x > -20 && x < World.W + 20 {
                if m == 0 {
                    ctx.setFillColor(NSColor.white.cgColor)
                    ctx.fill(CGRect(x: x, y: 0, width: 1.5, height: World.ground))
                } else if m == RaceState.length {
                    for row in 0..<9 {
                        for col in 0..<2 {
                            ctx.setFillColor(((row + col) % 2 == 0 ? NSColor.white : NSColor.black).cgColor)
                            ctx.fill(CGRect(x: x + CGFloat(col) * 2, y: CGFloat(row) * 2, width: 2, height: 2))
                        }
                    }
                    text("FINISH", at: CGPoint(x: x + 2, y: 19), size: 5.5, color: .white, ctx: ctx, center: true, bold: true)
                } else {
                    ctx.setFillColor(NSColor(white: 1, alpha: 0.35).cgColor)
                    ctx.fill(CGRect(x: x, y: World.ground, width: 0.8, height: 7))
                    text("\(Int(m / 20))m", at: CGPoint(x: x, y: 11), size: 4.5, color: NSColor(white: 1, alpha: 0.5), ctx: ctx, center: true)
                }
            }
            m += 200
        }
        for r in race.rivals.sorted(by: { $0.lane > $1.lane }) {
            let frame = r.v > 15 ? Int(r.walk * 2) % 2 : 0
            drawCreature(ctx, Species.byID(r.speciesID), x: sx(r.d), y: CGFloat(r.lane) * 2.6,
                         scale: 1.3 - CGFloat(r.lane) * 0.12, facing: 1, frame: frame, alpha: 1 - CGFloat(r.lane) * 0.08)
        }
    }

    private func renderRaceFront(_ ctx: CGContext) {
        // Mini-map of the whole race.
        let x0: CGFloat = 150, x1 = World.W - 170, y: CGFloat = 26.5
        guard x1 > x0 + 40 else { return }
        ctx.setFillColor(NSColor(white: 1, alpha: 0.25).cgColor)
        ctx.fill(CGRect(x: x0, y: y, width: x1 - x0, height: 0.8))
        ctx.fill(CGRect(x: x1, y: y - 1.5, width: 0.8, height: 3.8))
        let pos = { (d: CGFloat) -> CGFloat in x0 + (x1 - x0) * min(1, d / RaceState.length) }
        for r in race.rivals {
            ctx.setFillColor((Species.byID(r.speciesID).palette["b"] ?? .gray).cgColor)
            ctx.fillEllipse(in: CGRect(x: pos(r.d) - 1.5, y: y - 1.1, width: 3, height: 3))
        }
        ctx.setFillColor(hex(0xFFD23F).cgColor)
        ctx.fillEllipse(in: CGRect(x: pos(race.d) - 2, y: y - 1.6, width: 4, height: 4))

        if phase == .playing && race.countdown > 0 {
            text("\(Int(ceil(race.countdown)))", at: CGPoint(x: World.W / 2, y: 7), size: 15, color: .white, ctx: ctx, center: true, bold: true)
        } else if phase == .playing && race.time < 0.7 {
            text("GO!", at: CGPoint(x: World.W / 2, y: 7), size: 15, color: hex(0x7BE07B), ctx: ctx, center: true, bold: true)
        }
    }

    // MARK: - 🎣 Fishing

    private var rodTip: CGPoint { CGPoint(x: pet.x + 16, y: World.ground + pet.y + petSize.height + 5) }

    private func newFish() -> FishingState.Fish {
        let roll = Double.random(in: 0..<1)
        let kind: FishingState.Kind = roll < 0.58 ? .small : roll < 0.83 ? .big : roll < 0.92 ? .gold : .boot
        let speed: CGFloat = kind == .boot ? 4 : kind == .gold ? 22 : CGFloat.random(in: 8...16)
        return FishingState.Fish(x: CGFloat.random(in: (FishingState.waterStart + 20)...playMaxX),
                                 vx: Bool.random() ? speed : -speed, kind: kind)
    }

    private func fishingTap(_ p: CGPoint) {
        guard fishing.cast == nil, fishing.caught == nil else { return }
        if let i = fishing.fish.firstIndex(where: { $0.mood == .bite }), let bx = fishing.bobberX {
            let f = fishing.fish[i]
            let reaction = t - fishing.biteStart
            let (item, pts, label, scale): (ItemKind, Int, String, CGFloat) = {
                switch f.kind {
                case .small: return (.fish, 1, "Fish!", 1.1)
                case .big: return (.fish, 3, "Big fish!", 1.7)
                case .gold: return (.goldFish, 6, "GOLDEN fish! ✨", 1.4)
                case .boot: return (.boot, 0, "An old boot…", 1.3)
                }
            }()
            score += pts
            addText(String(format: "%@ +%d  (%.2fs)", label, pts, reaction), x: bx, y: 16,
                    color: f.kind == .gold ? hex(0xFFD23F) : .white)
            Sound.play(f.kind == .gold ? "Hero" : f.kind == .boot ? "Funk" : "Glass")
            burst(.spark(hex(0xBFE6FF)), at: bx, FishingState.surface, count: 6)
            fishing.caught = arc(item, from: CGPoint(x: bx, y: FishingState.surface), to: pet.x + 4,
                                 landY: World.ground + pet.y + petSize.height * 0.5, time: 0.75, scale: scale)
            fishing.bobberX = nil
            fishing.fish[i] = newFish()
            return
        }
        if let i = fishing.fish.firstIndex(where: { $0.mood == .nibble }) {
            fishing.fish[i].mood = .flee
            fishing.fish[i].vx = fishing.fish[i].x < (fishing.bobberX ?? 0) ? -80 : 80
            addText("Too early!", x: fishing.fish[i].x, y: 14, color: hex(0xFF9AA8))
            Sound.play("Funk")
            return
        }
        // (Re)cast toward the tapped spot.
        let target = min(max(p.x, FishingState.waterStart + 16), playMaxX - 4)
        fishing.bobberX = nil
        for i in fishing.fish.indices where fishing.fish[i].mood == .approach { fishing.fish[i].mood = .roam }
        fishing.cast = arc(.ball, from: rodTip, to: target, landY: FishingState.surface, time: 0.55)
    }

    private func updateFishing(_ dt: Double) {
        let fdt = CGFloat(dt)
        let lo = FishingState.waterStart + 8, hi = playMaxX
        fishing.dip = max(0, fishing.dip - fdt * 8)
        let engaged = fishing.fish.contains { [.approach, .nibble, .bite].contains($0.mood) }

        for i in fishing.fish.indices {
            var f = fishing.fish[i]
            switch f.mood {
            case .roam:
                f.x += f.vx * fdt
                if f.x < lo { f.x = lo; f.vx = abs(f.vx) }
                if f.x > hi { f.x = hi; f.vx = -abs(f.vx) }
                if phase == .playing, !engaged, let b = fishing.bobberX, abs(b - f.x) < 80, Double.random(in: 0..<1) < dt * 0.7 {
                    f.mood = .approach
                }
            case .approach:
                guard let b = fishing.bobberX else { f.mood = .roam; break }
                let dx = b - f.x
                f.vx = dx > 0 ? abs(f.vx) : -abs(f.vx)
                f.x += (dx > 0 ? 1 : -1) * min(abs(dx), 22 * fdt)
                if abs(dx) < 3 { f.mood = .nibble; f.nibbles = Int.random(in: 1...3); f.timer = Double.random(in: 0.6...1.3) }
            case .nibble:
                guard fishing.bobberX != nil else { f.mood = .roam; break }
                f.timer -= dt
                if f.timer <= 0 {
                    if f.nibbles > 0 {
                        f.nibbles -= 1
                        fishing.dip = 1.3
                        f.timer = Double.random(in: 0.5...1.2)
                    } else {
                        f.mood = .bite
                        f.timer = f.kind == .gold ? 0.45 : 0.65
                        fishing.biteStart = t
                        fishing.dip = 3.5
                        Sound.play("Ping", volume: 0.3)
                    }
                }
            case .bite:
                fishing.dip = max(fishing.dip, 3)
                f.timer -= dt
                if f.timer <= 0 {
                    f.mood = .flee
                    f.vx = Bool.random() ? 80 : -80
                    addText("It got away…", x: f.x, y: 14, color: NSColor(white: 1, alpha: 0.7))
                }
            case .flee:
                f.x += f.vx * fdt
                if f.x < lo - 10 || f.x > hi + 10 { f = newFish() }
            }
            fishing.fish[i] = f
        }

        if var c = fishing.cast {
            fly(&c, dt)
            if c.vy < 0 && c.y <= FishingState.surface {
                fishing.bobberX = c.x
                fishing.cast = nil
                burst(.spark(hex(0xBFE6FF)), at: c.x, FishingState.surface, count: 4)
            } else { fishing.cast = c }
        }
        if var c = fishing.caught {
            fly(&c, dt)
            if c.age > 0.75 {
                fishing.caught = nil
                burst(.item(.heart), at: pet.x, petSize.height + 2, count: 1)
            } else { fishing.caught = c }
        }

        guard phase == .playing else { return }
        timeLeft -= dt
        if timeLeft <= 0 {
            timeLeft = 0
            fishing.bobberX = nil
            resultText = "🎣 Time's up"
            endRound()
        }
    }

    private func renderFishing(_ ctx: CGContext) {
        let ws = FishingState.waterStart
        let water = isNightTime ? hex(0x2A5E9C) : hex(0x3A8AD6)
        ctx.setFillColor(water.cgColor)
        ctx.fill(CGRect(x: ws, y: 0, width: World.W - ws, height: FishingState.surface))
        ctx.setFillColor(NSColor(white: 1, alpha: 0.25).cgColor)
        var x = ws + CGFloat(t * 6).truncatingRemainder(dividingBy: 17)
        while x < World.W {
            ctx.fill(CGRect(x: x, y: FishingState.surface - 0.6, width: 4, height: 0.6))
            x += 17
        }
        for f in fishing.fish {
            let w: CGFloat = f.kind == .big ? 10 : f.kind == .boot ? 6 : 7
            ctx.setFillColor((f.kind == .gold ? hex(0xFFC93C, 0.7) : hex(0x0A1A33, 0.75)).cgColor)
            ctx.fillEllipse(in: CGRect(x: f.x - w / 2, y: 1, width: w, height: 2.2))
            if f.kind != .boot {
                let tail = f.x - (f.vx >= 0 ? 1 : -1) * (w / 2 + 1)
                ctx.fill(CGRect(x: tail - 1, y: 1.4, width: 2, height: 1.4))
            }
        }
        // Dock
        ctx.setFillColor(hex(0x7A4E2D).cgColor)
        ctx.fill(CGRect(x: 0, y: World.ground + 1, width: ws + 4, height: 1.5))
        ctx.setFillColor(hex(0x5A3820).cgColor)
        for px in stride(from: CGFloat(10), through: ws, by: 25) {
            ctx.fill(CGRect(x: px, y: 0, width: 1.5, height: World.ground + 1))
        }
    }

    private func renderFishingFront(_ ctx: CGContext) {
        let tip = rodTip
        ctx.setLineCap(.round)
        ctx.setStrokeColor(hex(0x8B5A2B).cgColor)
        ctx.setLineWidth(1.2)
        ctx.move(to: CGPoint(x: pet.x + 5, y: World.ground + pet.y + 7))
        ctx.addLine(to: tip)
        ctx.strokePath()

        var bobber: CGPoint?
        if let bx = fishing.bobberX { bobber = CGPoint(x: bx, y: FishingState.surface + 0.4 + CGFloat(sin(t * 3)) * 0.3 - fishing.dip) }
        if let c = fishing.cast { bobber = CGPoint(x: c.x, y: c.y) }
        if let b = bobber {
            ctx.setStrokeColor(NSColor(white: 1, alpha: 0.5).cgColor)
            ctx.setLineWidth(0.4)
            ctx.move(to: tip)
            ctx.addQuadCurve(to: b, control: CGPoint(x: (tip.x + b.x) / 2, y: min(tip.y, b.y) - 2))
            ctx.strokePath()
            ctx.setFillColor(hex(0xE84A5F).cgColor)
            ctx.fillEllipse(in: CGRect(x: b.x - 1.5, y: max(b.y, 1), width: 3, height: 2))
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fill(CGRect(x: b.x - 1.5, y: max(b.y, 1) + 1.6, width: 3, height: 0.8))
            if fishing.fish.contains(where: { $0.mood == .bite }) {
                text("!", at: CGPoint(x: b.x, y: 9), size: 11, color: hex(0xFFD23F), ctx: ctx, center: true, bold: true)
            }
        }
        if let c = fishing.caught {
            drawItem(ctx, c.kind, x: c.x, y: c.y, scale: c.scale, flip: c.vx < 0)
        }
    }

    // MARK: - 🧠 Copy Cat (memory)

    private var padSpacing: CGFloat { (playMaxX - 60) / 4 }
    private func padCenter(_ i: Int) -> CGFloat { 60 + padSpacing * (CGFloat(i) + 0.5) }

    private func lightPad(_ i: Int, for duration: Double) {
        memory.lit = i
        memory.litTimer = duration
        pet.targetX = padCenter(i)
        if pet.y <= 0.01 { pet.vy = 55 }
        Sound.play(MemoryState.sounds[i], volume: 0.4)
    }

    private func memoryTap(_ p: CGPoint) {
        guard !memory.showing, p.x > 60 - 8 else { return }
        let i = Int((p.x - 60) / padSpacing)
        guard (0..<4).contains(i) else { return }
        lightPad(i, for: 0.3)
        if memory.sequence[memory.inputIndex] == i {
            memory.inputIndex += 1
            if memory.inputIndex == memory.sequence.count {
                score = memory.sequence.count
                addText("✓ \(score)", x: padCenter(i), y: 18, color: hex(0x7BE07B))
                burst(.spark(hex(MemoryState.colors[i])), at: padCenter(i), 10, count: 8)
                memory.sequence.append(Int.random(in: 0..<4))
                memory.showing = true
                memory.showIndex = 0
                memory.timer = 1.1
            }
        } else {
            flash = 0.35
            Sound.play("Basso")
            resultText = "🧠 Remembered \(score) in a row"
            endRound()
        }
    }

    private func updateMemory(_ dt: Double) {
        applyGravity(dt)
        if let tx = pet.targetX {
            if move(toward: tx, speed: 420, dt: dt) { pet.targetX = nil }
        } else { pet.moving = false }
        memory.litTimer -= dt
        if memory.litTimer <= 0 { memory.lit = nil }
        guard phase == .playing, memory.showing else { return }
        memory.timer -= dt
        guard memory.timer <= 0 else { return }
        if memory.showIndex < memory.sequence.count {
            let dur = max(0.25, 0.55 - 0.025 * Double(memory.sequence.count))
            lightPad(memory.sequence[memory.showIndex], for: dur)
            memory.showIndex += 1
            memory.timer = dur + 0.18
        } else {
            memory.showing = false
            memory.inputIndex = 0
        }
    }

    private func renderMemory(_ ctx: CGContext) {
        let w = padSpacing - 16
        for i in 0..<4 {
            let c = hex(MemoryState.colors[i])
            let lit = memory.lit == i
            let x = padCenter(i)
            if lit {
                ctx.setFillColor(c.withAlphaComponent(0.25).cgColor)
                ctx.fillEllipse(in: CGRect(x: x - w / 2, y: -4, width: w, height: 22))
            }
            ctx.setFillColor(c.withAlphaComponent(lit ? 1 : 0.35).cgColor)
            ctx.fill(CGRect(x: x - w / 2, y: 0.5, width: w, height: World.ground + 0.5))
            text(MemoryState.symbols[i], at: CGPoint(x: x, y: 16), size: 10,
                 color: c.withAlphaComponent(lit ? 1 : 0.35), ctx: ctx, center: true, bold: true)
        }
    }

    // MARK: - Render hooks

    func renderGameBehindPet(_ ctx: CGContext) {
        switch mode {
        case .baseball: renderBaseball(ctx)
        case .playCatch: renderCatch(ctx)
        case .race: renderRace(ctx)
        case .fishing: renderFishing(ctx)
        case .memory: renderMemory(ctx)
        default: renderArcadeBehind(ctx)
        }
    }

    func renderGameFront(_ ctx: CGContext) {
        switch mode {
        case .baseball: renderBaseballFront(ctx)
        case .playCatch: renderCatchFront(ctx)
        case .race: renderRaceFront(ctx)
        case .fishing: renderFishingFront(ctx)
        default: renderArcadeFront(ctx)
        }
    }

    var isNightTime: Bool {
        if let forced = World.forcedNight { return forced }
        let h = Calendar.current.component(.hour, from: Date())
        return h < 6 || h >= 19
    }

    func drawCreature(_ ctx: CGContext, _ s: Species, x: CGFloat, y: CGFloat, scale: CGFloat,
                      facing: CGFloat, frame: Int, alpha: CGFloat = 1) {
        let w = CGFloat(Species.pixelWidth) * scale, h = CGFloat(Species.pixelHeight) * scale
        ctx.setFillColor(NSColor(white: 0, alpha: 0.25 * alpha).cgColor)
        ctx.fillEllipse(in: CGRect(x: x - w * 0.35, y: World.ground + y - 0.8, width: w * 0.7, height: 1.6))
        ctx.setAlpha(alpha)
        drawImage(ctx, s.image(frame: frame, closedEyes: false), CGRect(x: x - w / 2, y: World.ground + y - scale, width: w, height: h), flip: facing < 0)
        ctx.setAlpha(1)
    }
}
