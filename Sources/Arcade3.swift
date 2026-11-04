import AppKit

// MARK: - State

struct CrossingState {
    struct Car { var y: CGFloat; var len: CGFloat; var color: UInt32 }
    struct Lane { var x: CGFloat; var speed: CGFloat; var cars: [Car]; var safe = false }   // safe = grass strip
    static let frogLow: CGFloat = 11.5, frogHigh: CGFloat = 18.5
    static let laneW: CGFloat = 30
    /// Cars loop over this stretch (the bar shows 0–30), so a lane's traffic repeats evenly.
    static let loopLow: CGFloat = -17, loopHigh: CGFloat = 47
    var lanes: [Lane] = []
    var col = -1                 // -1 = start, lanes.count = goal
    var hopT: Double = 0
    var lives = 3
    var crossings = 0
    var hitT: Double = 0
}

struct ClawState {
    struct Prize { var x: CGFloat; var kind: Int; var speciesID: String }   // kind 0 plush, 1 star, 2 gem
    var prizes: [Prize] = []
    var x: CGFloat = 60
    var dir: CGFloat = 1
    var speed: CGFloat = 70
    var stage = 0                // 0 moving, 1 dropping, 2 lifting, 3 carrying
    var y: CGFloat = 26
    var grabbed: Prize?
    var willSlip = false
    var tries = 10
    var won = 0
}

struct FireworksState {
    struct Rocket { var x: CGFloat; var y: CGFloat; var vy: CGFloat; var color: UInt32 }
    var rockets: [Rocket] = []
    var spawn: Double = 0.6
}

struct GolfState {
    struct Bump { var x: CGFloat; var h: CGFloat; var w: CGFloat }
    var hole = 1
    var strokes = 0
    var bumps: [Bump] = []
    var cupX: CGFloat = 400
    var ballX: CGFloat = 40
    var v: CGFloat = 0
    var moving = false
    var dragStart: CGFloat?
    var pull: CGFloat = 0
    var sunkT: Double = 0
}

struct SlotsState {
    static let symbols = ["7️⃣", "🍒", "🔔", "🍋", "⭐", "🐶"]
    var reels = [0.0, 2.0, 4.0]
    var stopped = [true, true, true]
    var spins = 10
    var speed = 7.0
    var resultT: Double = 0
    var lastWin = 0
}

struct MinesState {
    var count = 20
    var mines: [Bool] = []
    var revealed: [Bool] = []
    var flagged: [Bool] = []
    var generated = false
    var mineCount = 4
    var level = 1
    var pressX: CGFloat?
    var pressT: Double = 0
    var pressFlagged = false
    var boomT: Double = 0
    var clearT: Double = 0
}

struct ColorsState {
    static let names = ["RED", "BLUE", "GREEN", "YELLOW"]
    static let colors: [UInt32] = [0xE84A5F, 0x3A7BE8, 0x4CC25A, 0xFFD23F]
    var word = 0
    var ink = 1
    var askInk = true
    var streak = 0
    var solved = 0
    var wrong: Int?
    var flashT: Double = 0
}

struct TimingState {
    static let targets = [2.0, 3.5, 5.0, 4.25, 6.0]
    var round = 0
    var stage = 0                // 0 get ready, 1 running, 2 result
    var timer: Double = 1.5
    var elapsed = 0.0
    var lastLine = ""
}

struct SeekState {
    struct Hider { var x: CGFloat; var speciesID: String; var isPet: Bool }
    var lightX: CGFloat = 300
    var fingerX: CGFloat?
    var hiders: [Hider] = []
    var roundT: Double = 0
    var found = 0
}

struct DragRaceState {
    static let length: CGFloat = 1200
    static let gearTop: [CGFloat] = [70, 115, 160, 205, 250]
    struct Car { var gear = 0; var rpm: CGFloat = 0.2; var d: CGFloat = 0; var v: CGFloat = 0; var finish: Double? }
    var me = Car()
    var rival = Car()
    var rivalShift: CGFloat = 0.88
    var countdown: Double = 3
    var time: Double = 0
    var msg = ""
    var msgT: Double = 0
}

struct SkiState {
    static let edgeX: CGFloat = 150
    var jump = 1
    var total: CGFloat = 0
    var stage = 0                // 0 in-run, 1 flight, 2 result
    var s: CGFloat = 0           // in-run distance along the ramp
    var speed: CGFloat = 20
    var x: CGFloat = 10
    var y: CGFloat = 27
    var vx: CGFloat = 0
    var vy: CGFloat = 0
    var holding = false
    var jumped = false
    var resultT: Double = 0
    var line = ""
}

struct MissileState {
    struct Missile { var x: CGFloat; var y: CGFloat; var vx: CGFloat; var vy: CGFloat; var sx: CGFloat; var sy: CGFloat; var splits: Bool }
    var cities: [CGFloat] = []
    var alive: [Bool] = []
    var missiles: [Missile] = []
    var charges: Double = 2
    var beams: [(x: CGFloat, t: Double)] = []
    var wave = 1
    var toSpawn = 8
    var spawnT: Double = 1
}

// MARK: - Dispatch

extension World {
    var arcade3HUDText: String? {
        switch mode {
        case .crossing: return "Crossings \(crossing.crossings)  " + String(repeating: "♥︎", count: max(0, crossing.lives))
        case .claw: return "Tries \(claw.tries)"
        case .golf: return "Hole \(min(golf.hole, 6))/6 · Strokes \(golf.strokes)"
        case .slots: return "Spins \(slots.spins)"
        case .mines: return "Board \(mines.level) · 💣 \(mines.mineCount)"
        case .colors: return colors.streak > 2 ? "Streak \(colors.streak)" : nil
        case .timing: return "Round \(min(timing.round + 1, 5))/5"
        case .seek: return "Found \(seek.found)"
        case .dragrace: return "Gear \(dragrace.me.gear + 1)"
        case .skijump: return "Jump \(min(skijump.jump, 3))/3 · \(Int(skijump.total)) m"
        case .missiles: return "Wave \(missiles.wave) · ⚡︎ \(Int(missiles.charges))"
        default: return nil
        }
    }

    func setupArcade3(_ m: Mode) {
        switch m {
        case .crossing: crossing = CrossingState(); buildLanes()
        case .claw: pet.x = -100; claw = ClawState(); stockClaw()
        case .fireworks: pet.x = 20; fireworks = FireworksState()
        case .golf: pet.x = -100; golf = GolfState(); newHole()
        case .slots: pet.x = 22; slots = SlotsState()
        case .mines: pet.x = -100; mines = MinesState(); newMinesBoard()
        case .colors: pet.x = 16; colors = ColorsState(); newColorQuestion()
        case .timing: pet.x = 24; timing = TimingState()
        case .seek: pet.x = -100; seek = SeekState(); hideAndSeekRound()
        case .dragrace: pet.x = -100; dragrace = DragRaceState()
        case .skijump: skijump = SkiState()
        case .missiles: pet.x = -100; missiles = MissileState(); buildCities()
        default: break
        }
    }

    func beginArcade3() {
        switch mode {
        case .crossing: crossing = CrossingState(); buildLanes()
        case .claw: claw = ClawState(); stockClaw()
        case .fireworks: fireworks = FireworksState(); timeLeft = 45
        case .golf: golf = GolfState(); newHole()
        case .slots: slots = SlotsState()
        case .mines: mines = MinesState(); newMinesBoard()
        case .colors: colors = ColorsState(); newColorQuestion(); timeLeft = 40
        case .timing: timing = TimingState()
        case .seek: seek = SeekState(); hideAndSeekRound(); timeLeft = 40
        case .dragrace: dragrace = DragRaceState(); dragrace.rivalShift = CGFloat.random(in: 0.8...0.94)
        case .skijump: skijump = SkiState()
        case .missiles: missiles = MissileState(); buildCities()
        default: break
        }
    }

    func arcade3TouchBegan(_ p: CGPoint) {
        switch mode {
        case .crossing: hop()
        case .claw: if claw.stage == 0 && claw.tries > 0 { claw.stage = 1; Sound.play("Tink", volume: 0.2) }
        case .fireworks: explodeRocket(near: p.x)
        case .golf: if !golf.moving && golf.sunkT <= 0 { golf.dragStart = p.x; golf.pull = 0 }
        case .slots: slotsTap()
        case .mines: mines.pressX = p.x; mines.pressT = t; mines.pressFlagged = false
        case .colors: answerColor(at: p.x)
        case .timing: if timing.stage == 1 { stopClock() }
        case .seek: seek.fingerX = p.x
        case .dragrace: shiftGear()
        case .skijump:
            if skijump.stage == 0 && !skijump.jumped { skiTakeoff() }
            skijump.holding = true
        case .missiles: fireBeam(at: p.x)
        default: break
        }
    }

    func arcade3TouchMoved(_ p: CGPoint) {
        switch mode {
        case .golf: if let s = golf.dragStart { golf.pull = min(150, abs(p.x - s)) }
        case .seek: seek.fingerX = p.x
        case .mines: if let x = mines.pressX, abs(p.x - x) > 12 { mines.pressX = nil }
        default: break
        }
    }

    func arcade3TouchEnded(_ p: CGPoint) {
        switch mode {
        case .golf: if golf.dragStart != nil { puttGolf() }
        case .mines:
            if mines.pressX != nil && !mines.pressFlagged { revealMine(at: p.x) }
            mines.pressX = nil
        case .seek: seek.fingerX = nil; checkSeek()
        case .skijump: skijump.holding = false
        default: break
        }
    }

    /// Right-click in the pet window: flag a tile in Mine Row.
    func flagTile(at x: CGFloat) {
        guard mode == .mines, phase == .playing, let i = mineIndex(at: x), !mines.revealed[i] else { return }
        mines.flagged[i].toggle()
        Sound.play("Tink", volume: 0.15)
    }

    func updateArcade3(_ dt: Double) {
        switch mode {
        case .crossing: updateCrossing(dt)
        case .claw: updateClaw(dt)
        case .fireworks: updateFireworks(dt)
        case .golf: updateGolf(dt)
        case .slots: updateSlots(dt)
        case .mines: updateMines(dt)
        case .colors: updateColors(dt)
        case .timing: updateTiming(dt)
        case .seek: updateSeek(dt)
        case .dragrace: updateDragRace(dt)
        case .skijump: updateSki(dt)
        case .missiles: updateMissiles(dt)
        default: break
        }
    }

    func renderArcade3Behind(_ ctx: CGContext) {
        switch mode {
        case .crossing: renderCrossing(ctx)
        case .claw: renderClaw(ctx)
        case .fireworks: renderFireworks(ctx)
        case .golf: renderGolf(ctx)
        case .slots: renderSlots(ctx)
        case .mines: renderMines(ctx)
        case .colors: renderColors(ctx)
        case .timing: renderTiming(ctx)
        case .seek: renderSeekHiders(ctx)
        case .dragrace: renderDragRace(ctx)
        case .skijump: renderSkiHill(ctx)
        case .missiles: renderMissiles(ctx)
        default: break
        }
    }

    func renderArcade3Front(_ ctx: CGContext) {
        switch mode {
        case .seek: renderSeekDark(ctx)
        default: break
        }
    }

    // MARK: - 🐸 Road Crossing

    private var laneX0: CGFloat { 44 }
    private var goalX: CGFloat { laneX0 + CGFloat(crossing.lanes.count) * CrossingState.laneW + 18 }

    private func buildLanes() {
        let n = max(6, Int((playMaxX - laneX0 - 30) / CrossingState.laneW))
        let level = CGFloat(crossing.crossings)
        crossing.lanes = (0..<n).map { i in
            let x = laneX0 + (CGFloat(i) + 0.5) * CrossingState.laneW
            // Every third lane is a grass strip where you can stop and wait.
            if i % 3 == 2 && i < n - 1 { return CrossingState.Lane(x: x, speed: 0, cars: [], safe: true) }
            let dir: CGFloat = i % 2 == 0 ? 1 : -1
            let speed = dir * CGFloat.random(in: 5...10) * (1 + level * 0.12)
            let colors: [UInt32] = [0xE84A5F, 0xFFD23F, 0x5FA8E8, 0x6CD47A, 0xB04AE8, 0xF0892B]
            let loop = CrossingState.loopHigh - CrossingState.loopLow
            let count = level >= 3 && i % 3 == 0 ? 3 : 2
            let start = CGFloat.random(in: 0..<loop)
            let cars = (0..<count).map { k -> CrossingState.Car in
                let y = (start + loop * CGFloat(k) / CGFloat(count) + CGFloat.random(in: -3...3)).truncatingRemainder(dividingBy: loop)
                return .init(y: CrossingState.loopLow + y, len: CGFloat.random(in: 6...8), color: colors.randomElement()!)
            }
            return CrossingState.Lane(x: x, speed: speed, cars: cars)
        }
        crossing.col = -1
    }

    private func frogX(_ col: Int) -> CGFloat {
        col < 0 ? 22 : col >= crossing.lanes.count ? goalX : crossing.lanes[col].x
    }

    private func hop() {
        guard crossing.hopT <= 0, crossing.hitT <= 0, crossing.col < crossing.lanes.count else { return }
        crossing.col += 1
        crossing.hopT = 0.15
        Sound.play("Pop", volume: 0.12)
    }

    private func updateCrossing(_ dt: Double) {
        let fdt = CGFloat(dt)
        let span = CrossingState.loopHigh - CrossingState.loopLow
        for i in crossing.lanes.indices {
            for k in crossing.lanes[i].cars.indices {
                var y = crossing.lanes[i].cars[k].y + crossing.lanes[i].speed * fdt
                if y > CrossingState.loopHigh { y -= span }
                if y < CrossingState.loopLow { y += span }
                crossing.lanes[i].cars[k].y = y
            }
        }
        let wasHopping = crossing.hopT > 0
        crossing.hopT -= dt
        crossing.hitT -= dt
        let progress = wasHopping ? CGFloat(max(0, crossing.hopT) / 0.15) : 0
        pet.x = frogX(crossing.col) - progress * (frogX(crossing.col) - frogX(crossing.col - 1))
        pet.y = CrossingState.frogLow - World.ground + (wasHopping ? sin((1 - progress) * .pi) * 3 : 0)
        pet.facing = 1
        guard phase == .playing, crossing.hitT <= 0 else { return }
        if crossing.col >= 0 && crossing.col < crossing.lanes.count && crossing.hopT < 0.07 {
            let lane = crossing.lanes[crossing.col]
            if lane.cars.contains(where: { $0.y < CrossingState.frogHigh - 0.5 && $0.y + $0.len > CrossingState.frogLow + 0.5 }) {
                crossing.lives -= 1
                crossing.hitT = 0.9
                crossing.col = -1
                flash = 0.3
                Sound.play("Basso", volume: 0.3)
                if crossing.lives <= 0 { resultText = "🐸 Made \(crossing.crossings) crossing\(crossing.crossings == 1 ? "" : "s")"; endRound() }
                return
            }
        }
        if wasHopping && crossing.hopT <= 0 && crossing.col >= 0 { score += 1 }
        if crossing.col >= crossing.lanes.count && crossing.hopT <= 0 {
            crossing.crossings += 1
            score += 10
            addText("Safe! +10", x: goalX, y: 22, color: hex(0xFFD23F))
            Sound.play("Glass", volume: 0.3)
            buildLanes()
        }
    }

    private func renderCrossing(_ ctx: CGContext) {
        let endX = laneX0 + CGFloat(crossing.lanes.count) * CrossingState.laneW
        ctx.setFillColor(hex(0x2A2C33).cgColor)
        ctx.fill(CGRect(x: laneX0, y: 0, width: endX - laneX0, height: World.H))
        ctx.setFillColor(hex(0x3E8E41).cgColor)
        for lane in crossing.lanes where lane.safe {
            ctx.fill(CGRect(x: lane.x - CrossingState.laneW / 2, y: 0, width: CrossingState.laneW, height: World.H))
        }
        ctx.setFillColor(NSColor(white: 1, alpha: 0.3).cgColor)
        for i in 1..<crossing.lanes.count {
            let x = laneX0 + CGFloat(i) * CrossingState.laneW
            for y in stride(from: CGFloat(1), to: World.H, by: 6) { ctx.fill(CGRect(x: x - 0.25, y: y, width: 0.5, height: 3)) }
        }
        for lane in crossing.lanes {
            for c in lane.cars {
                let r = CGRect(x: lane.x - 5, y: c.y, width: 10, height: c.len)
                ctx.addPath(CGPath(roundedRect: r, cornerWidth: 1.5, cornerHeight: 1.5, transform: nil))
                ctx.setFillColor(hex(c.color).cgColor)
                ctx.fillPath()
                ctx.setFillColor(hex(0xBFE6FF, 0.8).cgColor)
                ctx.fill(CGRect(x: lane.x - 3.5, y: lane.speed > 0 ? r.maxY - 3 : r.minY + 1.5, width: 7, height: 1.4))
                ctx.setFillColor(hex(0xFFF2B0).cgColor)
                let hy = lane.speed > 0 ? r.maxY - 0.6 : r.minY
                ctx.fill(CGRect(x: lane.x - 4.5, y: hy, width: 2, height: 0.6))
                ctx.fill(CGRect(x: lane.x + 2.5, y: hy, width: 2, height: 0.6))
            }
        }
        // Goal pond
        ctx.setFillColor(hex(0x3A8AD6).cgColor)
        ctx.fillEllipse(in: CGRect(x: endX + 4, y: 6, width: 28, height: 16))
        ctx.setFillColor(hex(0x6CD47A).cgColor)
        ctx.fillEllipse(in: CGRect(x: endX + 12, y: 11, width: 12, height: 6))
        if phase == .playing && crossing.col < 0 && crossing.crossings == 0 {
            text("tap to hop →", at: CGPoint(x: 22, y: 21), size: 5, color: NSColor(white: 1, alpha: 0.6), ctx: ctx, center: true)
        }
    }

    // MARK: - 🧸 Claw Machine

    private var chuteX: CGFloat { 14 }

    private func stockClaw() {
        var xs: [CGFloat] = []
        while xs.count < 8 {
            let x = CGFloat.random(in: 50...(playMaxX - 15))
            if !xs.contains(where: { abs($0 - x) < 22 }) { xs.append(x) }
        }
        claw.prizes = xs.map { newPrize(at: $0) }
    }

    private func newPrize(at x: CGFloat) -> ClawState.Prize {
        let r = Double.random(in: 0..<1)
        return .init(x: x, kind: r < 0.7 ? 0 : r < 0.9 ? 1 : 2, speciesID: Species.all.randomElement()!.id)
    }

    private func prizeTolerance(_ p: ClawState.Prize) -> CGFloat { p.kind == 0 ? 5 : p.kind == 1 ? 3.8 : 2.8 }
    private func prizeValue(_ p: ClawState.Prize) -> Int { p.kind == 0 ? 3 : p.kind == 1 ? 5 : 8 }

    private func updateClaw(_ dt: Double) {
        let fdt = CGFloat(dt)
        guard phase == .playing else { return }
        switch claw.stage {
        case 0:
            claw.x += claw.dir * claw.speed * fdt
            if claw.x > playMaxX - 8 { claw.x = playMaxX - 8; claw.dir = -1 }
            if claw.x < 40 { claw.x = 40; claw.dir = 1 }
        case 1:
            claw.y -= 32 * fdt
            if claw.y <= 6 {
                claw.y = 6
                if let i = claw.prizes.indices.min(by: { abs(claw.prizes[$0].x - claw.x) < abs(claw.prizes[$1].x - claw.x) }),
                   abs(claw.prizes[i].x - claw.x) < prizeTolerance(claw.prizes[i]) {
                    let p = claw.prizes.remove(at: i)
                    claw.grabbed = p
                    claw.willSlip = abs(p.x - claw.x) > prizeTolerance(p) * 0.6 && Bool.random()
                }
                claw.stage = 2
            }
        case 2:
            claw.y += 24 * fdt
            if claw.willSlip, let p = claw.grabbed, claw.y > 16 {
                claw.prizes.append(ClawState.Prize(x: claw.x, kind: p.kind, speciesID: p.speciesID))
                claw.grabbed = nil
                claw.willSlip = false
                addText("Slipped!", x: claw.x, y: 20, color: hex(0xFF9AA8))
                Sound.play("Funk", volume: 0.25)
            }
            if claw.y >= 26 {
                claw.y = 26
                if claw.grabbed != nil { claw.stage = 3 } else { finishClawTry() }
            }
        case 3:
            claw.x -= 140 * fdt
            if claw.x <= chuteX {
                if let p = claw.grabbed {
                    let v = prizeValue(p)
                    score += v
                    claw.won += 1
                    addText("+\(v)", x: chuteX + 10, y: 20, color: hex(0xFFD23F))
                    Sound.play(p.kind == 2 ? "Hero" : "Glass", volume: 0.3)
                    claw.prizes.append(newPrize(at: CGFloat.random(in: 50...(playMaxX - 15))))
                    claw.speed = min(claw.speed + 6, 140)
                }
                claw.grabbed = nil
                finishClawTry()
            }
        default: break
        }
    }

    private func finishClawTry() {
        claw.tries -= 1
        claw.stage = 0
        claw.x = 40
        claw.dir = 1
        if claw.tries <= 0 { resultText = "🧸 Won \(claw.won) prize\(claw.won == 1 ? "" : "s")"; endRound() }
    }

    private func drawPrize(_ ctx: CGContext, _ p: ClawState.Prize, x: CGFloat, y: CGFloat) {
        switch p.kind {
        case 0: drawCreature(ctx, Species.byID(p.speciesID), x: x, y: y - World.ground, scale: 0.75, facing: 1, frame: 0)
        case 1: drawItem(ctx, .star, x: x, y: y, scale: 1.3)
        default:
            ctx.setFillColor(hex(0x7FE0FF).cgColor)
            ctx.move(to: CGPoint(x: x, y: y)); ctx.addLine(to: CGPoint(x: x + 3, y: y + 3.5)); ctx.addLine(to: CGPoint(x: x, y: y + 6))
            ctx.addLine(to: CGPoint(x: x - 3, y: y + 3.5)); ctx.closePath(); ctx.fillPath()
            ctx.setFillColor(NSColor(white: 1, alpha: 0.7).cgColor)
            ctx.fill(CGRect(x: x - 0.8, y: y + 3.5, width: 1, height: 1.5))
        }
    }

    private func renderClaw(_ ctx: CGContext) {
        ctx.setFillColor(NSColor(white: 1, alpha: 0.06).cgColor)
        ctx.fill(CGRect(x: 30, y: World.ground, width: playMaxX - 22, height: World.H - World.ground))
        ctx.setFillColor(hex(0x2A2C33).cgColor)
        ctx.fill(CGRect(x: 4, y: World.ground, width: 20, height: 10))
        text("PRIZE", at: CGPoint(x: 14, y: 6), size: 4.5, color: hex(0xFFD23F), ctx: ctx, center: true, bold: true)
        for p in claw.prizes { drawPrize(ctx, p, x: p.x, y: World.ground + 0.5) }
        // Cable and claw
        ctx.setStrokeColor(NSColor(white: 0.85, alpha: 1).cgColor)
        ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: claw.x, y: World.H)); ctx.addLine(to: CGPoint(x: claw.x, y: claw.y + 2)); ctx.strokePath()
        ctx.setFillColor(hex(0x8A8F99).cgColor)
        ctx.fill(CGRect(x: claw.x - 2.5, y: claw.y + 1, width: 5, height: 2))
        let open: CGFloat = claw.stage == 1 ? 3.5 : 1.8
        ctx.setStrokeColor(hex(0xC0C4CC).cgColor)
        ctx.setLineWidth(0.8)
        for dir: CGFloat in [-1, 1] {
            ctx.move(to: CGPoint(x: claw.x + dir * 2, y: claw.y + 1))
            ctx.addLine(to: CGPoint(x: claw.x + dir * open, y: claw.y - 1.5))
            ctx.addLine(to: CGPoint(x: claw.x + dir * (open - 1.2), y: claw.y - 3))
            ctx.strokePath()
        }
        if let g = claw.grabbed { drawPrize(ctx, g, x: claw.x, y: claw.y - 7) }
        if phase == .playing && claw.stage == 0 {
            text("tap to drop the claw", at: CGPoint(x: World.W / 2, y: World.H - 8.5), size: 5, color: NSColor(white: 1, alpha: 0.4), ctx: ctx, center: true)
        }
    }

    // MARK: - 🎆 Fireworks

    private func explodeRocket(near x: CGFloat) {
        guard let i = fireworks.rockets.indices.min(by: { abs(fireworks.rockets[$0].x - x) < abs(fireworks.rockets[$1].x - x) }),
              abs(fireworks.rockets[i].x - x) < 12 else { return }
        let r = fireworks.rockets.remove(at: i)
        let quality = abs(r.vy) < 5 ? 3 : abs(r.vy) < 14 ? 2 : 1
        score += quality
        addText(quality == 3 ? "Perfect! +3" : "+\(quality)", x: r.x, y: min(r.y + 4, 22), color: quality == 3 ? hex(0xFFD23F) : .white)
        for k in 0..<(quality * 7) {
            let a = CGFloat(k) / CGFloat(quality * 7) * .pi * 2
            let sp = CGFloat.random(in: 8...16) * CGFloat(quality)
            particles.append(Particle(kind: .spark(hex(r.color)), x: r.x, y: r.y, vx: cos(a) * sp, vy: sin(a) * sp, life: 0.9, maxLife: 0.9))
        }
        Sound.play(quality == 3 ? "Hero" : "Pop", volume: 0.3)
    }

    private func updateFireworks(_ dt: Double) {
        let fdt = CGFloat(dt)
        applyGravity(dt)
        guard phase == .playing else { return }
        timeLeft -= dt
        if timeLeft <= 0 { timeLeft = 0; resultText = "🎆 Show's over"; endRound(); return }
        fireworks.spawn -= dt
        if fireworks.spawn <= 0 {
            fireworks.spawn = Double.random(in: 0.5...1.1) * max(0.5, timeLeft / 45)
            let colors: [UInt32] = [0xFF6B9A, 0xFFD23F, 0x7FE0FF, 0x7BE07B, 0xB48CFF, 0xFF9A3C]
            fireworks.rockets.append(.init(x: CGFloat.random(in: 40...(playMaxX - 10)), y: 0, vy: CGFloat.random(in: 40...52), color: colors.randomElement()!))
        }
        var i = 0
        while i < fireworks.rockets.count {
            fireworks.rockets[i].vy -= 50 * fdt
            fireworks.rockets[i].y += fireworks.rockets[i].vy * fdt
            if fireworks.rockets[i].vy < -10 && fireworks.rockets[i].y < 10 {
                let r = fireworks.rockets.remove(at: i)
                score = max(0, score - 1)
                addText("dud -1", x: r.x, y: 12, color: hex(0xFF9AA8))
                continue
            }
            if Int.random(in: 0..<3) == 0 {
                particles.append(Particle(kind: .spark(hex(0xFFB347)), x: fireworks.rockets[i].x, y: fireworks.rockets[i].y - 1,
                                          vx: CGFloat.random(in: -2...2), vy: -6, life: 0.3, maxLife: 0.3))
            }
            i += 1
        }
    }

    private func renderFireworks(_ ctx: CGContext) {
        for r in fireworks.rockets {
            ctx.setFillColor(hex(r.color).cgColor)
            ctx.fill(CGRect(x: r.x - 0.6, y: r.y, width: 1.2, height: 2.6))
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fill(CGRect(x: r.x - 0.4, y: r.y + 2.6, width: 0.8, height: 0.8))
        }
        if phase == .playing && score == 0 {
            text("tap rockets at the top of their climb", at: CGPoint(x: World.W / 2, y: World.H - 8.5), size: 5, color: NSColor(white: 1, alpha: 0.45), ctx: ctx, center: true)
        }
    }

    // MARK: - ⛳ Mini Golf

    private func terrain(_ x: CGFloat) -> CGFloat {
        golf.bumps.reduce(0) { $0 + $1.h * exp(-pow((x - $1.x) / $1.w, 2)) }
    }
    private func slope(_ x: CGFloat) -> CGFloat {
        golf.bumps.reduce(0) { $0 + $1.h * exp(-pow((x - $1.x) / $1.w, 2)) * (-2 * (x - $1.x) / ($1.w * $1.w)) }
    }
    private var golfSurface: CGFloat { World.ground + 1 }

    private func newHole() {
        golf.strokes = 0
        golf.ballX = 40
        golf.v = 0
        golf.moving = false
        golf.cupX = CGFloat.random(in: 260...(playMaxX - 30))
        golf.bumps = (0..<Int.random(in: 2...3)).map { _ in
            .init(x: CGFloat.random(in: 90...(playMaxX - 40)), h: CGFloat.random(in: 2...6), w: CGFloat.random(in: 18...45))
        }
        // Keep the cup on fairly level ground.
        let cup = golf.cupX
        golf.bumps.removeAll { abs($0.x - cup) < $0.w * 1.2 }
    }

    /// One physics step of a rolling ball; shared with the self-test.
    func golfStep(x: inout CGFloat, v: inout CGFloat, dt: CGFloat) {
        let friction: CGFloat = 38
        let a = -90 * slope(x)
        if abs(v) < 2 && abs(a) < friction { v = 0; return }
        v += (a - friction * (v > 0 ? 1 : v < 0 ? -1 : 0)) * dt
        x += v * dt
        if x < 8 { x = 8; v = abs(v) * 0.5 }
        if x > playMaxX + 8 { x = playMaxX + 8; v = -abs(v) * 0.5 }
    }

    func golfPuttSpeed(power: CGFloat) -> CGFloat { 30 + power * 190 }

    private func puttGolf() {
        let power = max(0.03, golf.pull / 150)
        golf.v = (golf.cupX >= golf.ballX ? 1 : -1) * golfPuttSpeed(power: power)
        golf.moving = true
        golf.strokes += 1
        golf.dragStart = nil
        golf.pull = 0
        Sound.play("Tink", volume: 0.25)
    }

    private func updateGolf(_ dt: Double) {
        let fdt = CGFloat(dt)
        guard phase == .playing else { return }
        if golf.sunkT > 0 {
            golf.sunkT -= dt
            if golf.sunkT <= 0 {
                golf.hole += 1
                if golf.hole > 6 { resultText = "⛳ \(score) points over 6 holes"; endRound(); return }
                newHole()
            }
            return
        }
        guard golf.moving else { return }
        let prev = golf.ballX
        var x = golf.ballX, v = golf.v      // golfStep reads the course, so step on local copies
        golfStep(x: &x, v: &v, dt: fdt)
        golf.ballX = x
        golf.v = v
        let crossed = (prev - golf.cupX) * (golf.ballX - golf.cupX) <= 0 && prev != golf.ballX
        if crossed && abs(golf.v) < 70 {
            let pts = max(1, 6 - golf.strokes)
            score += pts
            addText(golf.strokes == 1 ? "HOLE IN ONE! +\(pts)" : "In! +\(pts)", x: golf.cupX, y: 20, color: hex(0xFFD23F))
            Sound.play(golf.strokes == 1 ? "Hero" : "Glass", volume: 0.3)
            golf.moving = false
            golf.ballX = golf.cupX
            golf.sunkT = 1.4
            return
        }
        if golf.v == 0 {
            golf.moving = false
            if golf.strokes >= 6 {
                addText("Picked up", x: golf.ballX, y: 18, color: hex(0xFF9AA8))
                golf.sunkT = 1.2
            }
        }
    }

    private func renderGolf(_ ctx: CGContext) {
        ctx.setFillColor(hex(0x6CD47A).cgColor)
        ctx.move(to: CGPoint(x: 0, y: 0))
        var x: CGFloat = 0
        while x <= World.W { ctx.addLine(to: CGPoint(x: x, y: golfSurface + terrain(x))); x += 2 }
        ctx.addLine(to: CGPoint(x: World.W, y: 0)); ctx.closePath(); ctx.fillPath()
        ctx.setFillColor(hex(0x4CA455).cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: World.W, height: World.ground))
        // Cup and flag
        let cy = golfSurface + terrain(golf.cupX)
        ctx.setFillColor(hex(0x1A1A1A).cgColor)
        ctx.fillEllipse(in: CGRect(x: golf.cupX - 2.4, y: cy - 1, width: 4.8, height: 1.6))
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fill(CGRect(x: golf.cupX - 0.2, y: cy, width: 0.4, height: 14))
        ctx.setFillColor(hex(0xE84A5F).cgColor)
        ctx.move(to: CGPoint(x: golf.cupX + 0.2, y: cy + 14)); ctx.addLine(to: CGPoint(x: golf.cupX + 6, y: cy + 12))
        ctx.addLine(to: CGPoint(x: golf.cupX + 0.2, y: cy + 10)); ctx.closePath(); ctx.fillPath()
        // Ball
        if golf.sunkT <= 0 {
            let by = golfSurface + terrain(golf.ballX)
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: golf.ballX - 1.2, y: by, width: 2.4, height: 2.4))
        }
        if golf.dragStart != nil {
            let p = golf.pull / 150
            ctx.setFillColor(NSColor(white: 1, alpha: 0.2).cgColor)
            ctx.fill(CGRect(x: golf.ballX - 10, y: 22, width: 20, height: 2))
            ctx.setFillColor(NSColor(calibratedHue: 0.33 * (1 - p), saturation: 0.8, brightness: 0.95, alpha: 1).cgColor)
            ctx.fill(CGRect(x: golf.ballX - 10, y: 22, width: 20 * p, height: 2))
        } else if phase == .playing && !golf.moving && golf.sunkT <= 0 && golf.strokes == 0 {
            text("drag to set power, release to putt", at: CGPoint(x: golf.ballX + 6, y: 16), size: 5, color: NSColor(white: 1, alpha: 0.6), ctx: ctx)
        }
    }

    // MARK: - 🎰 Lucky Slots

    private var reelX: [CGFloat] { [splitX - 48, splitX, splitX + 48] }

    private func slotsTap() {
        guard slots.resultT <= 0 else { return }
        if slots.stopped.allSatisfy({ $0 }) {
            guard slots.spins > 0 else { return }
            slots.spins -= 1
            slots.stopped = [false, false, false]
            slots.lastWin = 0
            Sound.play("Pop", volume: 0.2)
            return
        }
        if let i = slots.stopped.firstIndex(of: false) {
            slots.reels[i] = floor(slots.reels[i])          // lock on the symbol in the window
            slots.stopped[i] = true
            Sound.play("Tink", volume: 0.25)
            if i == 2 { scoreSlots() }
        }
    }

    private func slotSymbol(_ i: Int) -> Int { Int(floor(slots.reels[i])) % SlotsState.symbols.count }

    private func scoreSlots() {
        let s = (0..<3).map(slotSymbol)
        var win = 0
        if s[0] == s[1] && s[1] == s[2] { win = s[0] == 0 ? 50 : s[0] == 4 ? 25 : s[0] == 5 ? 20 : 10 }
        else if s[0] == s[1] || s[1] == s[2] || s[0] == s[2] { win = 3 }
        slots.lastWin = win
        score += win
        if win > 0 {
            addText(win >= 50 ? "JACKPOT! +\(win)" : "+\(win)", x: splitX, y: 22, color: win >= 20 ? hex(0xFFD23F) : .white)
            Sound.play(win >= 20 ? "Hero" : "Glass", volume: 0.35)
            if win >= 20 { burst(.item(.coin), at: splitX, 14, count: 8) }
        }
        slots.resultT = 1.2
        slots.speed = min(slots.speed + 0.3, 10)
    }

    private func updateSlots(_ dt: Double) {
        applyGravity(dt)
        guard phase == .playing else { return }
        for i in 0..<3 where !slots.stopped[i] { slots.reels[i] += slots.speed * (1 + Double(i) * 0.12) * dt }
        if slots.resultT > 0 {
            slots.resultT -= dt
            if slots.resultT <= 0 && slots.spins == 0 { resultText = "🎰 Won \(score) coins"; endRound() }
        }
    }

    private func renderSlots(_ ctx: CGContext) {
        ctx.addPath(CGPath(roundedRect: CGRect(x: splitX - 78, y: 2, width: 156, height: 26), cornerWidth: 4, cornerHeight: 4, transform: nil))
        ctx.setFillColor(hex(0xB5651D).cgColor)
        ctx.fillPath()
        for (i, x) in reelX.enumerated() {
            ctx.setFillColor(NSColor(white: 0.97, alpha: 1).cgColor)
            ctx.fill(CGRect(x: x - 20, y: 4, width: 40, height: 22))
            ctx.saveGState()
            ctx.clip(to: CGRect(x: x - 20, y: 4, width: 40, height: 22))
            let pos = slots.reels[i]
            let frac = CGFloat(pos - floor(pos))
            let n = SlotsState.symbols.count
            for k in -1...1 {
                let idx = ((Int(floor(pos)) + k) % n + n) % n
                let y = 15 - CGFloat(k) * 13 + frac * 13            // symbol centre; neighbours peek in above/below
                text(SlotsState.symbols[idx], at: CGPoint(x: x, y: y - 4.5), size: 9, color: .black, ctx: ctx, center: true)
            }
            ctx.restoreGState()
            if slots.stopped[i] && !slots.stopped.allSatisfy({ $0 }) {
                ctx.setFillColor(hex(0x6CD47A, 0.3).cgColor)
                ctx.fill(CGRect(x: x - 20, y: 4, width: 40, height: 22))
            }
        }
        ctx.setFillColor(hex(0xE84A5F, 0.7).cgColor)
        ctx.fill(CGRect(x: splitX - 72, y: 14.7, width: 144, height: 0.6))
        if phase == .playing {
            let hint = slots.stopped.allSatisfy({ $0 }) ? (slots.spins > 0 && slots.resultT <= 0 ? "tap to spin" : "") : "tap to stop reel \((slots.stopped.firstIndex(of: false) ?? 0) + 1)"
            text(hint, at: CGPoint(x: splitX + 86, y: 13), size: 5.5, color: NSColor(white: 1, alpha: 0.6), ctx: ctx)
            text("7️⃣7️⃣7️⃣ = 50", at: CGPoint(x: splitX - 140, y: 13), size: 5, color: NSColor(white: 1, alpha: 0.5), ctx: ctx)
        }
    }

    // MARK: - 💣 Mine Row

    private var mineW: CGFloat { (playMaxX - 20) / CGFloat(mines.count) }
    private func mineIndex(at x: CGFloat) -> Int? {
        let i = Int((x - 20) / mineW)
        return mines.mines.indices.contains(i) ? i : nil
    }
    func mineNumber(_ i: Int) -> Int { [i - 1, i + 1].filter { mines.mines.indices.contains($0) && mines.mines[$0] }.count }

    private func newMinesBoard() {
        mines.mines = Array(repeating: false, count: mines.count)
        mines.revealed = Array(repeating: false, count: mines.count)
        mines.flagged = Array(repeating: false, count: mines.count)
        mines.generated = false
    }

    private func revealMine(at x: CGFloat) {
        guard phase == .playing, mines.boomT <= 0, mines.clearT <= 0, let i = mineIndex(at: x), !mines.revealed[i], !mines.flagged[i] else { return }
        if !mines.generated {
            let safe = Set([i - 1, i, i + 1])
            let spots = mines.mines.indices.filter { !safe.contains($0) }.shuffled().prefix(mines.mineCount)
            for s in spots { mines.mines[s] = true }
            mines.generated = true
        }
        if mines.mines[i] {
            for k in mines.mines.indices where mines.mines[k] { mines.revealed[k] = true }
            flash = 0.4
            burst(.spark(hex(0xFFB347)), at: 20 + mineW * (CGFloat(i) + 0.5), 12, count: 14)
            Sound.play("Basso", volume: 0.35)
            mines.boomT = 1.4
            return
        }
        var stack = [i]
        while let k = stack.popLast() {
            guard mines.mines.indices.contains(k), !mines.revealed[k], !mines.mines[k] else { continue }
            mines.revealed[k] = true
            mines.flagged[k] = false
            score += 1
            if mineNumber(k) == 0 { stack += [k - 1, k + 1] }
        }
        Sound.play("Tink", volume: 0.15)
        if mines.mines.indices.allSatisfy({ mines.mines[$0] || mines.revealed[$0] }) {
            score += 10 * mines.level
            addText("Cleared! +\(10 * mines.level)", x: World.W / 2, y: 22, color: hex(0xFFD23F))
            Sound.play("Glass", volume: 0.35)
            mines.clearT = 1.2
        }
    }

    private func updateMines(_ dt: Double) {
        guard phase == .playing else { return }
        if let x = mines.pressX, !mines.pressFlagged, t - mines.pressT > 0.4 {
            mines.pressFlagged = true
            flagTile(at: x)
        }
        if mines.boomT > 0 {
            mines.boomT -= dt
            if mines.boomT <= 0 { resultText = "💣 Boom on board \(mines.level)"; endRound() }
        }
        if mines.clearT > 0 {
            mines.clearT -= dt
            if mines.clearT <= 0 {
                mines.level += 1
                mines.mineCount = min(mines.mineCount + 1, 8)
                newMinesBoard()
            }
        }
    }

    private func renderMines(_ ctx: CGContext) {
        let w = mineW
        for i in mines.mines.indices {
            let r = CGRect(x: 20 + w * CGFloat(i) + 1, y: 4, width: w - 2, height: 20)
            ctx.addPath(CGPath(roundedRect: r, cornerWidth: 2, cornerHeight: 2, transform: nil))
            if mines.revealed[i] {
                ctx.setFillColor((mines.mines[i] ? hex(0xE84A5F, 0.8) : NSColor(white: 0.92, alpha: 1)).cgColor)
                ctx.fillPath()
                if mines.mines[i] {
                    text("💣", at: CGPoint(x: r.midX, y: 9), size: 9, color: .white, ctx: ctx, center: true)
                } else if mineNumber(i) > 0 {
                    text("\(mineNumber(i))", at: CGPoint(x: r.midX, y: 8.5), size: 10, color: mineNumber(i) == 1 ? hex(0x3A7BE8) : hex(0xE84A5F), ctx: ctx, center: true, bold: true)
                }
            } else {
                ctx.setFillColor(hex(0x5A6B8A).cgColor)
                ctx.fillPath()
                ctx.setFillColor(NSColor(white: 1, alpha: 0.18).cgColor)
                ctx.fill(CGRect(x: r.minX, y: r.maxY - 1, width: r.width, height: 1))
                if mines.flagged[i] { text("🚩", at: CGPoint(x: r.midX, y: 9), size: 9, color: .white, ctx: ctx, center: true) }
            }
        }
        if phase == .playing && !mines.generated {
            text("tap to reveal · hold to flag · numbers count mines next door", at: CGPoint(x: World.W / 2 - 10, y: 25), size: 5, color: NSColor(white: 1, alpha: 0.55), ctx: ctx, center: true)
        }
    }

    // MARK: - 🎨 Color Clash

    private func swatchX(_ i: Int) -> CGFloat { 200 + (playMaxX - 200) * (CGFloat(i) + 0.5) / 4 }

    private func newColorQuestion() {
        colors.word = Int.random(in: 0..<4)
        colors.ink = Double.random(in: 0..<1) < 0.2 ? colors.word : ([0, 1, 2, 3].filter { $0 != colors.word }.randomElement()!)
        colors.askInk = colors.solved < 8 || Double.random(in: 0..<1) < 0.7
        colors.wrong = nil
    }

    var colorAnswer: Int { colors.askInk ? colors.ink : colors.word }

    private func answerColor(at x: CGFloat) {
        guard x > 180, let i = (0..<4).min(by: { abs(swatchX($0) - x) < abs(swatchX($1) - x) }) else { return }
        if i == colorAnswer {
            let pts = 1 + min(colors.streak / 4, 3)
            score += pts
            colors.streak += 1
            colors.solved += 1
            Sound.play("Tink", volume: 0.2)
            if pet.y <= 0.01 { pet.vy = 40 }
            newColorQuestion()
        } else {
            colors.streak = 0
            colors.wrong = i
            colors.flashT = 0.4
            score = max(0, score - 1)
            Sound.play("Funk", volume: 0.25)
        }
    }

    private func updateColors(_ dt: Double) {
        applyGravity(dt)
        colors.flashT -= dt
        guard phase == .playing else { return }
        timeLeft -= dt
        if timeLeft <= 0 { timeLeft = 0; resultText = "🎨 \(colors.solved) colors right"; endRound() }
    }

    private func renderColors(_ ctx: CGContext) {
        guard phase == .playing else { return }
        let badge = colors.askInk ? "INK" : "WORD"
        ctx.addPath(CGPath(roundedRect: CGRect(x: 30, y: 9, width: 24, height: 10), cornerWidth: 3, cornerHeight: 3, transform: nil))
        ctx.setFillColor((colors.askInk ? hex(0x8A8F99) : hex(0xF0892B)).cgColor)
        ctx.fillPath()
        text(badge, at: CGPoint(x: 42, y: 11), size: 6, color: .white, ctx: ctx, center: true, bold: true)
        text(ColorsState.names[colors.word], at: CGPoint(x: 115, y: 7), size: 15, color: hex(ColorsState.colors[colors.ink]), ctx: ctx, center: true, bold: true)
        for i in 0..<4 {
            let x = swatchX(i)
            let bad = colors.wrong == i && colors.flashT > 0
            ctx.addPath(CGPath(roundedRect: CGRect(x: x - 18 + (bad ? CGFloat(sin(t * 60)) : 0), y: 6, width: 36, height: 17), cornerWidth: 5, cornerHeight: 5, transform: nil))
            ctx.setFillColor(hex(ColorsState.colors[i]).cgColor)
            ctx.fillPath()
        }
        text(colors.askInk ? "tap the ink color" : "tap the color the word says", at: CGPoint(x: 115, y: 24), size: 5, color: NSColor(white: 1, alpha: 0.55), ctx: ctx, center: true)
    }

    // MARK: - ⏱ Perfect Timing

    private var timingTarget: Double { TimingState.targets[min(timing.round, TimingState.targets.count - 1)] }

    private func stopClock() {
        let err = timing.elapsed - timingTarget
        let pts = max(0, 100 - Int(abs(err) * 200))
        score += pts
        timing.lastLine = String(format: "%.2f s  (%@%.2f)  →  %d pts", timing.elapsed, err >= 0 ? "+" : "−", abs(err), pts)
        timing.stage = 2
        timing.timer = 2.2
        Sound.play(pts >= 90 ? "Hero" : pts >= 60 ? "Glass" : "Funk", volume: 0.3)
    }

    private func updateTiming(_ dt: Double) {
        applyGravity(dt)
        guard phase == .playing else { return }
        switch timing.stage {
        case 0:
            timing.timer -= dt
            if timing.timer <= 0 { timing.stage = 1; timing.elapsed = 0; Sound.play("Ping", volume: 0.3) }
        case 1:
            timing.elapsed += dt
            if timing.elapsed > timingTarget + 3 { stopClock() }
        default:
            timing.timer -= dt
            if timing.timer <= 0 {
                timing.round += 1
                if timing.round >= TimingState.targets.count { resultText = "⏱ \(score) / 500 points"; endRound(); return }
                timing.stage = 0
                timing.timer = 1.5
            }
        }
    }

    private func renderTiming(_ ctx: CGContext) {
        guard phase == .playing else { return }
        let cx = splitX - 40
        ctx.setFillColor(NSColor(white: 0.95, alpha: 1).cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - 12, y: 3, width: 24, height: 24))
        ctx.setFillColor(hex(0x8A8F99).cgColor)
        ctx.fill(CGRect(x: cx - 1.5, y: 27, width: 3, height: 2))
        let visible = timing.stage == 1 && timing.elapsed < 1.0 || timing.stage == 2
        if visible {
            let a = CGFloat(timing.elapsed / 60 * 2 * .pi) * 10
            ctx.setStrokeColor(hex(0xE84A5F).cgColor)
            ctx.setLineWidth(0.8)
            ctx.move(to: CGPoint(x: cx, y: 15)); ctx.addLine(to: CGPoint(x: cx + sin(a) * 10, y: 15 + cos(a) * 10)); ctx.strokePath()
        } else {
            text("?", at: CGPoint(x: cx, y: 9), size: 14, color: hex(0x3A3F4B), ctx: ctx, center: true, bold: true)
        }
        text(String(format: "Stop at %.2f s", timingTarget), at: CGPoint(x: cx + 30, y: 17), size: 9, color: .white, ctx: ctx, bold: true)
        let line: String
        switch timing.stage {
        case 0: line = "Get ready…"
        case 1: line = timing.elapsed < 1.0 ? String(format: "%.2f", timing.elapsed) : "counting in your head… tap to stop!"
        default: line = timing.lastLine
        }
        text(line, at: CGPoint(x: cx + 30, y: 7), size: 7, color: hex(0xFFD23F), ctx: ctx)
    }

    // MARK: - 🔦 Hide & Seek

    private func hideAndSeekRound() {
        var xs: [CGFloat] = []
        while xs.count < 4 {
            let x = CGFloat.random(in: 30...(playMaxX - 10))
            if !xs.contains(where: { abs($0 - x) < 40 }) { xs.append(x) }
        }
        let decoys = rivalIDs(3)
        seek.hiders = [SeekState.Hider(x: xs[0], speciesID: species.id, isPet: true)]
            + zip(xs.dropFirst(), decoys).map { SeekState.Hider(x: $0, speciesID: $1, isPet: false) }
        seek.roundT = 0
    }

    private func checkSeek() {
        guard phase == .playing, let h = seek.hiders.min(by: { abs($0.x - seek.lightX) < abs($1.x - seek.lightX) }), abs(h.x - seek.lightX) < 10 else { return }
        if h.isPet {
            let pts = 5 + max(0, 5 - Int(seek.roundT))
            score += pts
            seek.found += 1
            addText("Found \(petName)! +\(pts)", x: h.x, y: 22, color: hex(0xFFD23F))
            Sound.play("Glass", volume: 0.3)
            hideAndSeekRound()
        } else {
            score = max(0, score - 2)
            addText("That's \(Species.byID(h.speciesID).name)! -2", x: h.x, y: 22, color: hex(0xFF9AA8))
            Sound.play("Funk", volume: 0.25)
        }
    }

    private func updateSeek(_ dt: Double) {
        if let f = seek.fingerX { seek.lightX += (f - seek.lightX) * min(1, CGFloat(dt) * 18) }
        guard phase == .playing else { return }
        seek.roundT += dt
        timeLeft -= dt
        if timeLeft <= 0 { timeLeft = 0; resultText = "🔦 Found \(petName) \(seek.found) time\(seek.found == 1 ? "" : "s")"; endRound() }
    }

    private func renderSeekHiders(_ ctx: CGContext) {
        for h in seek.hiders {
            drawCreature(ctx, Species.byID(h.speciesID), x: h.x, y: 0, scale: 1.0, facing: h.x < splitX ? 1 : -1, frame: 0)
        }
    }

    private func renderSeekDark(_ ctx: CGContext) {
        guard phase == .playing else { return }
        let path = CGMutablePath()
        path.addRect(CGRect(x: 0, y: 0, width: World.W - 22, height: World.H))
        path.addEllipse(in: CGRect(x: seek.lightX - 16, y: -1, width: 32, height: 32))
        ctx.addPath(path)
        ctx.setFillColor(NSColor(white: 0.01, alpha: 0.985).cgColor)
        ctx.fillPath(using: .evenOdd)
        ctx.setStrokeColor(hex(0xFFF2B0, 0.35).cgColor)
        ctx.setLineWidth(0.6)
        ctx.strokeEllipse(in: CGRect(x: seek.lightX - 16, y: -1, width: 32, height: 32))
        text("slide to search, lift your finger on \(petName)", at: CGPoint(x: World.W / 2, y: World.H - 8.5), size: 5, color: NSColor(white: 1, alpha: 0.5), ctx: ctx, center: true)
    }

    // MARK: - 🏎 Drag Race

    private static let rpmRate: [CGFloat] = [0.95, 0.72, 0.58, 0.48, 0.4]

    private func shiftGear() {
        guard dragrace.countdown <= 0, dragrace.me.finish == nil, dragrace.me.gear < 4 else { return }
        let r = dragrace.me.rpm
        let (newRpm, msg): (CGFloat, String) = r >= 0.86 && r < 0.99 ? (0.62, "Perfect shift!") : r >= 0.72 && r < 0.86 ? (0.52, "Good") : r >= 0.99 ? (0.5, "Late!") : (0.36, "Too early")
        dragrace.me.gear += 1
        dragrace.me.rpm = newRpm
        dragrace.msg = msg
        dragrace.msgT = 0.8
        Sound.play(msg == "Perfect shift!" ? "Glass" : "Pop", volume: 0.25)
    }

    private func stepCar(_ c: inout DragRaceState.Car, _ dt: CGFloat) {
        guard c.finish == nil else { c.v = max(0, c.v - 120 * dt); c.d += c.v * dt; return }
        c.rpm = min(1, c.rpm + World.rpmRate[c.gear] * dt)
        var target = DragRaceState.gearTop[c.gear] * c.rpm
        if c.rpm >= 1 { target *= 0.9 }
        c.v += (target - c.v) * min(1, 2.2 * dt)
        c.d += c.v * dt
    }

    private func updateDragRace(_ dt: Double) {
        let fdt = CGFloat(dt)
        dragrace.msgT -= dt
        guard phase == .playing else { return }
        if dragrace.countdown > 0 {
            let before = Int(ceil(dragrace.countdown))
            dragrace.countdown -= dt
            if Int(ceil(max(dragrace.countdown, 0))) != before { Sound.play(dragrace.countdown > 0 ? "Tink" : "Glass", volume: 0.35) }
            return
        }
        dragrace.time += dt
        stepCar(&dragrace.me, fdt)
        stepCar(&dragrace.rival, fdt)
        if dragrace.rival.gear < 4 && dragrace.rival.rpm >= dragrace.rivalShift {
            dragrace.rival.gear += 1
            dragrace.rival.rpm = dragrace.rivalShift > 0.86 ? 0.62 : 0.52
            dragrace.rivalShift = CGFloat.random(in: 0.8...0.94)
        }
        if dragrace.rival.finish == nil && dragrace.rival.d >= DragRaceState.length { dragrace.rival.finish = dragrace.time }
        if dragrace.me.finish == nil && dragrace.me.d >= DragRaceState.length {
            dragrace.me.finish = dragrace.time
            let won = dragrace.rival.finish == nil
            score = max(5, Int(100 - dragrace.time * 6)) + (won ? 25 : 0)
            resultText = String(format: won ? "🏎 You win! %.2f s" : "🏎 %.2f s — the rival was faster", dragrace.time)
            Sound.play(won ? "Hero" : "Funk", volume: 0.35)
            endRound()
        }
    }

    private func renderDragRace(_ ctx: CGContext) {
        let camX: CGFloat = 170
        ctx.setFillColor(hex(0x2A2C33, 0.85).cgColor)
        ctx.fill(CGRect(x: 0, y: World.ground - 0.5, width: World.W, height: 24))
        ctx.setFillColor(hex(0xFFD23F, 0.7).cgColor)
        var x = -(dragrace.me.d.truncatingRemainder(dividingBy: 24))
        while x < World.W { ctx.fill(CGRect(x: x, y: World.ground + 11.2, width: 12, height: 0.6)); x += 24 }
        let fx = camX + (DragRaceState.length - dragrace.me.d)
        if fx < World.W {
            for row in 0..<12 {
                ctx.setFillColor((row % 2 == 0 ? NSColor.white : NSColor.black).cgColor)
                ctx.fill(CGRect(x: fx, y: World.ground + CGFloat(row) * 2, width: 2, height: 2))
            }
        }
        drawCar(ctx, x: camX + (dragrace.rival.d - dragrace.me.d), y: World.ground + 17, w: 24, color: hex(0x5FA8E8), facing: 1)
        drawCar(ctx, x: camX, y: World.ground + 5.5, w: 24, color: hex(0xE84A5F), facing: 1)
        // Tachometer
        let r = dragrace.me.rpm
        ctx.setFillColor(NSColor(white: 0, alpha: 0.6).cgColor)
        ctx.fill(CGRect(x: 6, y: 4, width: 7, height: 22))
        ctx.setFillColor(hex(0x6CD47A, 0.7).cgColor)
        ctx.fill(CGRect(x: 6, y: 4 + 22 * 0.86, width: 7, height: 22 * 0.12))
        ctx.setFillColor(hex(0xE84A5F, 0.7).cgColor)
        ctx.fill(CGRect(x: 6, y: 4 + 22 * 0.98, width: 7, height: 22 * 0.02))
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fill(CGRect(x: 5, y: 4 + 22 * r - 0.4, width: 9, height: 0.8))
        text("\(dragrace.me.gear + 1)", at: CGPoint(x: 9.5, y: 26.5), size: 5, color: .white, ctx: ctx, center: true, bold: true)
        if phase == .playing {
            if dragrace.countdown > 0 {
                text("\(Int(ceil(dragrace.countdown)))", at: CGPoint(x: World.W / 2, y: 8), size: 14, color: .white, ctx: ctx, center: true, bold: true)
            } else if dragrace.msgT > 0 {
                text(dragrace.msg, at: CGPoint(x: camX + 30, y: 22), size: 7, color: dragrace.msg == "Perfect shift!" ? hex(0x7BE07B) : .white, ctx: ctx, bold: true)
            } else if r >= 0.86 && dragrace.me.gear < 4 {
                text("SHIFT!", at: CGPoint(x: 26, y: 12), size: 7, color: hex(0x7BE07B), ctx: ctx, bold: true)
            } else if dragrace.me.gear == 0 && dragrace.time < 2 {
                text("tap to shift when the needle hits green", at: CGPoint(x: 26, y: 12), size: 5, color: NSColor(white: 1, alpha: 0.55), ctx: ctx)
            }
        }
    }

    // MARK: - ⛷️ Ski Jump

    private func hill(_ x: CGFloat) -> CGFloat {
        if x <= SkiState.edgeX { return 27 - (x - 8) / (SkiState.edgeX - 8) * 13 }
        return max(4, 12 - (x - SkiState.edgeX) * 0.028)
    }

    private func skiTakeoff() {
        let gap = SkiState.edgeX - skijump.x
        let q: CGFloat = gap >= 0 && gap < 14 ? max(0.25, 1 - abs(gap - 4) / 10) : 0.15
        let slopeAngle = atan(13 / (SkiState.edgeX - 8))
        skijump.vx = skijump.speed * cos(slopeAngle)
        skijump.vy = -skijump.speed * sin(slopeAngle) + 34 * q
        skijump.stage = 1
        skijump.jumped = true
        if q > 0.85 { addText("Great takeoff!", x: skijump.x, y: 22, color: hex(0x7BE07B)) }
        Sound.play("Blow", volume: 0.2)
    }

    private func updateSki(_ dt: Double) {
        let fdt = CGFloat(dt)
        pet.facing = 1
        defer { pet.x = skijump.x; pet.y = skijump.y - World.ground }
        guard phase == .playing else { return }
        switch skijump.stage {
        case 0:
            skijump.speed = min(skijump.speed + 55 * fdt, 140)
            skijump.x += skijump.speed * 0.995 * fdt
            skijump.y = hill(skijump.x)
            if skijump.x >= SkiState.edgeX { skiTakeoff() }
        case 1:
            let g: CGFloat = skijump.holding ? 42 : 95
            skijump.vy -= g * fdt
            skijump.vx *= 1 - 0.05 * fdt
            skijump.x += skijump.vx * fdt
            skijump.y += skijump.vy * fdt
            if skijump.y <= hill(skijump.x) {
                skijump.y = hill(skijump.x)
                var dist = max(0, (skijump.x - SkiState.edgeX) * 0.4)
                if skijump.holding {
                    dist *= 0.7
                    skijump.line = String(format: "Crash! %.1f m (still leaning)", dist)
                    flash = 0.25
                    Sound.play("Basso", volume: 0.3)
                } else {
                    skijump.line = String(format: "Landed! %.1f m", dist)
                    Sound.play(dist > 100 ? "Hero" : "Glass", volume: 0.3)
                }
                skijump.total += dist
                score = Int(skijump.total)
                skijump.stage = 2
                skijump.resultT = 2
            }
        default:
            skijump.resultT -= dt
            if skijump.resultT <= 0 {
                skijump.jump += 1
                if skijump.jump > 3 { resultText = "⛷️ \(Int(skijump.total)) m in 3 jumps"; endRound(); return }
                let jump = skijump.jump, total = skijump.total
                skijump = SkiState()
                skijump.jump = jump
                skijump.total = total
            }
        }
    }

    private func renderSkiHill(_ ctx: CGContext) {
        ctx.setFillColor(NSColor(white: 0.95, alpha: 1).cgColor)
        ctx.move(to: .zero)
        var x: CGFloat = 0
        while x <= World.W { ctx.addLine(to: CGPoint(x: x, y: x < 8 ? 27 : hill(x) - (x > SkiState.edgeX && x < SkiState.edgeX + 3 ? 2 : 0))); x += 2 }
        ctx.addLine(to: CGPoint(x: World.W, y: 0)); ctx.closePath(); ctx.fillPath()
        ctx.setFillColor(hex(0xE84A5F).cgColor)
        for m in stride(from: 50, through: 150, by: 25) {
            let mx = SkiState.edgeX + CGFloat(m) / 0.4
            guard mx < World.W - 10 else { continue }
            ctx.fill(CGRect(x: mx, y: hill(mx), width: 0.6, height: 3))
            text("\(m)m", at: CGPoint(x: mx, y: hill(mx) + 3.5), size: 4, color: hex(0x5A6070), ctx: ctx, center: true)
        }
        if phase == .playing {
            if skijump.stage == 0 { text("tap at the edge!", at: CGPoint(x: SkiState.edgeX + 8, y: 20), size: 5, color: NSColor(white: 1, alpha: 0.6), ctx: ctx) }
            if skijump.stage == 1 { text(skijump.holding ? "gliding… let go before landing" : "hold to glide", at: CGPoint(x: SkiState.edgeX + 8, y: 24), size: 5, color: NSColor(white: 1, alpha: 0.6), ctx: ctx) }
            if skijump.stage == 2 { text(skijump.line, at: CGPoint(x: World.W / 2, y: 20), size: 8, color: hex(0xFFD23F), ctx: ctx, center: true, bold: true) }
        }
    }

    // MARK: - 🏙 Missile Defense

    private func buildCities() {
        missiles.cities = (0..<6).map { 40 + (playMaxX - 50) * (CGFloat($0) + 0.5) / 6 }
        missiles.alive = Array(repeating: true, count: 6)
        missiles.toSpawn = 8
    }

    private func fireBeam(at x: CGFloat) {
        guard missiles.charges >= 1 else { addText("charging…", x: x, y: 20, color: hex(0xFF9AA8)); return }
        missiles.charges -= 1
        missiles.beams.append((x, 0.25))
        let before = missiles.missiles.count
        missiles.missiles.removeAll { abs($0.x - x) < 7 }
        let hits = before - missiles.missiles.count
        score += hits
        if hits > 0 { burst(.spark(hex(0x7FE0FF)), at: x, 18, count: 4 * hits); Sound.play("Pop", volume: 0.25) }
    }

    private func spawnMissile(from: CGPoint? = nil) {
        let targets = missiles.cities.indices.filter { missiles.alive[$0] }
        guard let ti = targets.randomElement() else { return }
        let start = from ?? CGPoint(x: CGFloat.random(in: 20...(playMaxX - 10)), y: World.H)
        let T = CGFloat.random(in: 3.5...5.5) / (1 + CGFloat(missiles.wave) * 0.1)
        let tx = missiles.cities[ti] + CGFloat.random(in: -4...4)
        missiles.missiles.append(.init(x: start.x, y: start.y, vx: (tx - start.x) / T, vy: -(start.y - World.ground) / T,
                                       sx: start.x, sy: start.y, splits: from == nil && missiles.wave >= 2 && Double.random(in: 0..<1) < 0.2))
    }

    private func updateMissiles(_ dt: Double) {
        let fdt = CGFloat(dt)
        for i in missiles.beams.indices { missiles.beams[i].t -= dt }
        missiles.beams.removeAll { $0.t <= 0 }
        guard phase == .playing else { return }
        missiles.charges = min(2, missiles.charges + dt * 0.9)
        missiles.spawnT -= dt
        if missiles.toSpawn > 0 && missiles.spawnT <= 0 {
            missiles.toSpawn -= 1
            missiles.spawnT = Double.random(in: 0.6...1.4) / (1 + Double(missiles.wave) * 0.12)
            spawnMissile()
        }
        var i = 0
        while i < missiles.missiles.count {
            var m = missiles.missiles[i]
            m.x += m.vx * fdt
            m.y += m.vy * fdt
            if m.splits && m.y < 18 {
                missiles.missiles.remove(at: i)
                spawnMissile(from: CGPoint(x: m.x, y: m.y))
                spawnMissile(from: CGPoint(x: m.x, y: m.y))
                continue
            }
            if m.y <= World.ground + 1 {
                missiles.missiles.remove(at: i)
                if let c = missiles.cities.indices.first(where: { missiles.alive[$0] && abs(missiles.cities[$0] - m.x) < 9 }) {
                    missiles.alive[c] = false
                    flash = 0.3
                    burst(.spark(hex(0xFFB347)), at: missiles.cities[c], 5, count: 12)
                    Sound.play("Basso", volume: 0.3)
                    if !missiles.alive.contains(true) { resultText = "🏙 Held out until wave \(missiles.wave)"; endRound(); return }
                }
                continue
            }
            missiles.missiles[i] = m
            i += 1
        }
        if missiles.toSpawn == 0 && missiles.missiles.isEmpty {
            let bonus = missiles.alive.filter { $0 }.count * 2
            score += bonus
            addText("Wave \(missiles.wave) cleared! +\(bonus)", x: World.W / 2, y: 20, color: hex(0xFFD23F))
            Sound.play("Glass", volume: 0.3)
            missiles.wave += 1
            missiles.toSpawn = 8 + missiles.wave * 2
            missiles.spawnT = 1.5
        }
    }

    private func renderMissiles(_ ctx: CGContext) {
        for (i, x) in missiles.cities.enumerated() {
            if missiles.alive[i] {
                for (dx, h, c) in [(CGFloat(-5), CGFloat(6), UInt32(0x5A6B8A)), (-1, 9, 0x6A7B9A), (3, 5, 0x4A5B7A)] {
                    ctx.setFillColor(hex(c).cgColor)
                    ctx.fill(CGRect(x: x + dx, y: World.ground, width: 4, height: h))
                    ctx.setFillColor(hex(0xFFE08A, 0.8).cgColor)
                    ctx.fill(CGRect(x: x + dx + 1, y: World.ground + h - 2, width: 0.8, height: 0.8))
                }
            } else {
                ctx.setFillColor(hex(0x3A3A3A).cgColor)
                ctx.fill(CGRect(x: x - 5, y: World.ground, width: 12, height: 1.5))
            }
        }
        for m in missiles.missiles {
            ctx.setStrokeColor(hex(0xFF7F7F, 0.4).cgColor)
            ctx.setLineWidth(0.4)
            ctx.move(to: CGPoint(x: m.sx, y: m.sy)); ctx.addLine(to: CGPoint(x: m.x, y: m.y)); ctx.strokePath()
            ctx.setFillColor(hex(0xFFE066).cgColor)
            ctx.fillEllipse(in: CGRect(x: m.x - 0.8, y: m.y - 0.8, width: 1.6, height: 1.6))
        }
        for b in missiles.beams {
            ctx.setFillColor(hex(0x7FE0FF, CGFloat(b.t / 0.25) * 0.6).cgColor)
            ctx.fill(CGRect(x: b.x - 4, y: World.ground, width: 8, height: World.H))
        }
        if phase == .playing && score == 0 && missiles.wave == 1 {
            text("tap to fire a laser beam up at incoming missiles", at: CGPoint(x: World.W / 2, y: World.H - 8.5), size: 5, color: NSColor(white: 1, alpha: 0.45), ctx: ctx, center: true)
        }
    }
}
