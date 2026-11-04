import AppKit

// Two people share one Touch Bar: Player 1 (red) uses the left half, Player 2 (blue) the right half.
// In 1-player mode the right side is a computer-controlled rival animal.

extension Mode {
    static let multiplayerGames: [Mode] = [.duel, .tug, .hurdles, .snap, .popBattle, .soccer, .rps, .mathBattle, .potato, .spaceDuel, .pongDuel,
                                           .tictactoe, .connect4, .boxing, .cannon, .pump, .memoryDuel, .gallop, .numbers]
    var isMultiplayer: Bool { Mode.multiplayerGames.contains(self) }
    /// Games where each player has their own buttons on their half (so in 1-player mode only the left half counts).
    var usesSideButtons: Bool { [.rps, .mathBattle, .popBattle, .memoryDuel, .numbers].contains(self) }
}

// MARK: - State

struct TugState {
    var rope: CGFloat = 0             // -1 = pulled to Player 1, +1 = pulled to Player 2
    var countdown: Double = 3
    var roundOver: Double = 0
    var cpuT: Double = 0
    var cpuRate: Double = 7
    var pull = [0.0, 0.0]
}

struct HurdleState {
    struct Runner { var d: CGFloat = 0; var y: CGFloat = 0; var vy: CGFloat = 0; var stumble: Double = 0; var walk: Double = 0 }
    static let length: CGFloat = 1500
    static let screenX: CGFloat = 120
    static let laneBase: [CGFloat] = [3, 15.5]
    var hurdles: [CGFloat] = []
    var knocked: [Set<Int>] = [[], []]
    var runners = [Runner(), Runner()]
    var countdown: Double = 3
    var cpuPlan: [Int: CGFloat] = [:]
}

struct SnapState {
    static let symbols = ["🍎", "🍌", "🍇", "🍒", "⭐", "🐶"]
    var current = 0
    var previous: Int?
    var timer: Double = 1.4
    var shownFor: Double = 0
    var matchLive = false
    var claimed = false
    var frozen = [0.0, 0.0]
    var cpuReact: Double = 0.5
    var cpuFalse = false
    var flashSide = 0
    var flashT: Double = 0
    var countdown: Double = 2
}

struct PopBattleState {
    var bubbles: [Bubble] = []
    var spawn: Double = 0.5
    var cpuT: Double = 0.6
}

struct SoccerState {
    var ball = CGPoint(x: 300, y: 22)
    var vx: CGFloat = 0
    var vy: CGFloat = 0
    var px: [CGFloat] = [140, 400]
    var target: [CGFloat?] = [nil, nil]
    var vel: [CGFloat] = [0, 0]
    var walk = [0.0, 0.0]
    var kickCooldown = [0.0, 0.0]
    var pause: Double = 1.2
}

struct RPSState {
    static let hands = ["✊", "✋", "✌️"]
    var choice: [Int?] = [nil, nil]
    var auto = [false, false]
    var timer: Double = 3
    var revealT: Double = 0
    var cpuAt: Double = 1.5
}

struct MathBattleState {
    var question = ""
    var answer = 0
    var options: [Int] = []
    var frozen = [0.0, 0.0]
    var nextT: Double = 0
    var solvedBy = 0
    var wrongSide = 0
    var cpuT: Double = 2.5
    var countdown: Double = 1.5
}

struct PotatoState {
    var holder = 0
    var flying = false
    var flyT: Double = 0
    var fuse: Double = 8
    var fuseTotal: Double = 8
    var readyT: Double = 0.6
    var boomT: Double = 0
    var cpuDelay: Double = 0.3
    var countdown: Double = 1.5
}

struct SpaceDuelState {
    struct Laser { var x: CGFloat; var y: CGFloat; var dir: CGFloat; var owner: Int }
    var phase = [0.0, 1.7]
    var omega = [1.7, 2.1]
    var lasers: [Laser] = []
    var reload = [0.0, 0.0]
    var hitFlash = [0.0, 0.0]
    var cpuT: Double = 0.3
    var countdown: Double = 1.5
}

struct PongDuelState {
    var ball = CGPoint(x: 300, y: 14)
    var vx: CGFloat = 0
    var vy: CGFloat = 0
    var speed: CGFloat = 170
    var g: CGFloat = 160
    var points = 0
    var inPlay = false
    var serveT: Double = 1.2
    var server = 0
    var bounced = false
    var swing = [0.0, 0.0]
    var swung = [false, false]
    var cpuOffset: CGFloat = 0
}

// MARK: - Shared multiplayer plumbing

extension World {
    var splitX: CGFloat { (World.W - 22) / 2 }
    var rival: Species { Species.byID(mpRivalID) }
    var p1Name: String { twoPlayer ? "Player 1" : petName }
    var p2Name: String { twoPlayer ? "Player 2" : rival.name }

    /// Which player a touch at `x` belongs to (nil = not anyone's button).
    func mpPlayer(at x: CGFloat) -> Int? {
        if twoPlayer { return x < splitX ? 0 : 1 }
        return mode.usesSideButtons ? (x < splitX ? 0 : nil) : 0
    }

    func mpPoint(_ player: Int, _ label: String? = nil) {
        if player == 0 { p1 += 1 } else { p2 += 1 }
        if let label {
            addText(label, x: player == 0 ? splitX / 2 : splitX * 1.5, y: 20, color: player == 0 ? hex(0xFF8A8A) : hex(0x8AB8FF))
        }
    }

    func mpFinish() {
        if mode == .hurdles || mode == .gallop {
            resultText = p1 > p2 ? "🔴 \(p1Name) wins the race!" : (twoPlayer ? "🔵 Player 2 wins the race!" : "\(rival.emoji) \(rival.name) wins the race")
            score = twoPlayer ? 3 : (p1 > p2 ? 3 : 1)
            Sound.play("Hero", volume: 0.35)
            endRound()
            return
        }
        if p1 > p2 { resultText = "🔴 \(p1Name) wins \(p1)–\(p2)!" }
        else if p2 > p1 { resultText = twoPlayer ? "🔵 Player 2 wins \(p2)–\(p1)!" : "\(rival.emoji) \(rival.name) wins \(p2)–\(p1)" }
        else { resultText = "🤝 Draw \(p1)–\(p2)" }
        score = twoPlayer ? max(p1, p2) : p1
        if p1 != p2 { Sound.play("Hero", volume: 0.35) }
        endRound()
    }

    func setupMultiplayer(_ m: Mode) {
        mpRivalID = rivalIDs(1)[0]
        p1 = 0; p2 = 0
        pet.x = -100
        resetMPGame(m)
    }

    func beginMultiplayer() {
        p1 = 0; p2 = 0
        touchOwner.removeAll()
        resetMPGame(mode)
    }

    private func resetMPGame(_ m: Mode) {
        switch m {
        case .tug: tug = TugState(); tug.cpuRate = Double.random(in: 6.2...8.2)
        case .hurdles:
            hurdles = HurdleState()
            var x: CGFloat = 220
            while x < HurdleState.length - 80 { hurdles.hurdles.append(x); x += CGFloat.random(in: 140...240) }
        case .snap: snap = SnapState(); snap.current = Int.random(in: 0..<SnapState.symbols.count)
        case .popBattle: popBattle = PopBattleState(); timeLeft = 30
        case .soccer: soccer = SoccerState(); kickoff()
        case .rps: rps = RPSState(); rps.cpuAt = Double.random(in: 0.5...2.5)
        case .mathBattle: mathBattle = MathBattleState(); newBattleQuestion()
        case .potato: potato = PotatoState(); newPotatoRound(holder: Int.random(in: 0...1))
        case .spaceDuel: spaceDuel = SpaceDuelState()
        case .pongDuel: pongDuel = PongDuelState()
        default: resetMP2(m)
        }
    }

    func mpTouchBegan(_ p: CGPoint, id: Int) {
        guard let player = mpPlayer(at: p.x) else { return }
        touchOwner[id] = player
        if !twoPlayer && player == 1 { return }
        switch mode {
        case .duel: duelTap(player: player)
        case .tug: tugPull(player)
        case .hurdles: hurdleJump(player)
        case .snap: snapTap(player)
        case .popBattle: popBattleTap(player, x: p.x)
        case .soccer: soccer.target[player] = p.x
        case .rps: rpsChoose(player, x: p.x)
        case .mathBattle: mathBattleTap(player, x: p.x)
        case .potato: potatoThrow(player)
        case .spaceDuel: spaceFire(player)
        case .pongDuel: pongDuelSwing(player)
        default: mp2TouchBegan(p, player: player)
        }
    }

    func mpTouchMoved(_ p: CGPoint, id: Int) {
        guard mode == .soccer, let player = touchOwner[id] ?? mpPlayer(at: p.x) else { return }
        if !twoPlayer && player == 1 { return }
        soccer.target[player] = p.x
    }

    func mpTouchEnded(_ p: CGPoint, id: Int) {
        guard let player = touchOwner.removeValue(forKey: id) else { return }
        if mode == .soccer { soccer.target[player] = nil }
        if !twoPlayer && player == 1 { return }
        mp2TouchEnded(p, player: player)
    }

    func updateMultiplayer(_ dt: Double) {
        guard phase == .playing else { return }
        switch mode {
        case .tug: updateTug(dt)
        case .hurdles: updateHurdles(dt)
        case .snap: updateSnap(dt)
        case .popBattle: updatePopBattle(dt)
        case .soccer: updateSoccer(dt)
        case .rps: updateRPS(dt)
        case .mathBattle: updateMathBattle(dt)
        case .potato: updatePotato(dt)
        case .spaceDuel: updateSpaceDuel(dt)
        case .pongDuel: updatePongDuel(dt)
        default: updateMP2(dt)
        }
    }

    func renderMultiplayer(_ ctx: CGContext) {
        if twoPlayer && phase == .playing && mode != .hurdles && mode != .gallop && !mode.isTurnBased {
            ctx.setFillColor(hex(0xE84A5F, 0.06).cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: splitX, height: World.H))
            ctx.setFillColor(hex(0x5FA8E8, 0.06).cgColor)
            ctx.fill(CGRect(x: splitX, y: 0, width: World.W - 22 - splitX, height: World.H))
        }
        switch mode {
        case .tug: renderTug(ctx)
        case .hurdles: renderHurdles(ctx)
        case .snap: renderSnap(ctx)
        case .popBattle: renderPopBattle(ctx)
        case .soccer: renderSoccer(ctx)
        case .rps: renderRPS(ctx)
        case .mathBattle: renderMathBattle(ctx)
        case .potato: renderPotato(ctx)
        case .spaceDuel: renderSpaceDuel(ctx)
        case .pongDuel: renderPongDuel(ctx)
        default: renderMP2(ctx)
        }
    }

    /// Big centred "3, 2, 1" before a round. Returns true while still counting down.
    private func countdown(_ value: inout Double, _ dt: Double) -> Bool {
        guard value > 0 else { return false }
        let before = Int(ceil(value))
        value -= dt
        let after = Int(ceil(max(value, 0)))
        if after != before { Sound.play(after > 0 ? "Tink" : "Glass", volume: 0.35) }
        return value > 0
    }

    private func drawCountdown(_ value: Double, _ ctx: CGContext, go: String = "GO!") {
        guard phase == .playing else { return }
        if value > 0 {
            text("\(Int(ceil(value)))", at: CGPoint(x: splitX, y: 8), size: 14, color: .white, ctx: ctx, center: true, bold: true)
        }
    }

    private func avatar(_ player: Int) -> Species { player == 0 ? species : rival }

    // MARK: HUD + start screen

    func drawMPHUD(_ ctx: CGContext) {
        if phase == .playing && (mode == .hurdles || mode == .gallop) { return }   // the lanes show each runner's progress
        if phase == .playing {
            text("🔴 \(p1Name)  \(p1)", at: CGPoint(x: 4, y: World.H - 8.5), size: 6.5, color: hex(0xFFB0B0), ctx: ctx, bold: true)
            var right = "\(p2)  \(p2Name) " + (twoPlayer ? "🔵" : rival.emoji)
            if mode.isTimed { right = "⏱ \(Int(ceil(timeLeft)))     " + right }
            text(right, at: CGPoint(x: World.W - 26, y: World.H - 8.5), size: 6.5, color: hex(0xB0D0FF), ctx: ctx, alignRight: true, bold: true)
            return
        }
        // Exit button stays available on the start / results screen.
        ctx.setFillColor(NSColor(white: 1, alpha: 0.18).cgColor)
        ctx.fillEllipse(in: CGRect(x: World.W - 19, y: World.H / 2 - 7, width: 14, height: 14))
        text("✕", at: CGPoint(x: World.W - 12, y: World.H / 2 - 4.5), size: 7, color: .white, ctx: ctx, center: true)

        ctx.setFillColor(NSColor(white: 0, alpha: 0.6).cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: World.W - 22, height: World.H))
        let title = phase == .ready ? "\(mode.emoji) \(mode.title)  —  \(mode.hint)" : "\(resultText ?? "")   +\(lastReward) ⭐️"
        text(title, at: CGPoint(x: splitX, y: 20), size: 7, color: .white, ctx: ctx, center: true, bold: true)
        let ready = phase == .ready || phaseTimer > 1.0
        for side in 0..<2 {
            let r = CGRect(x: side == 0 ? 6 : splitX + 6, y: 2, width: (side == 0 ? splitX : World.W - 22 - splitX) - 12, height: 14)
            ctx.addPath(CGPath(roundedRect: r, cornerWidth: 4, cornerHeight: 4, transform: nil))
            ctx.setFillColor((side == 0 ? hex(0xE84A5F, ready ? 0.55 : 0.25) : hex(0x5FA8E8, ready ? 0.55 : 0.25)).cgColor)
            ctx.fillPath()
            let label = side == 0 ? "👤 1 Player  vs  \(rival.emoji) \(rival.name)" : "👥 2 Players   🔴 left  ·  🔵 right"
            text(label, at: CGPoint(x: r.midX, y: 5.5), size: 6.5, color: .white, ctx: ctx, center: true, bold: true)
        }
    }

    // MARK: - 🪢 Tug of War

    private func tugPull(_ player: Int) {
        guard tug.countdown <= 0, tug.roundOver <= 0 else { return }
        tug.rope += player == 0 ? -0.045 : 0.045
        tug.pull[player] = 0.12
    }

    private func updateTug(_ dt: Double) {
        tug.pull[0] -= dt; tug.pull[1] -= dt
        if tug.roundOver > 0 {
            tug.roundOver -= dt
            if tug.roundOver <= 0 {
                if p1 >= 2 || p2 >= 2 { mpFinish(); return }
                tug.rope = 0
                tug.countdown = 3
                tug.cpuRate = Double.random(in: 6.2...8.2)
            }
            return
        }
        if countdown(&tug.countdown, dt) { return }
        if !twoPlayer {
            tug.cpuT -= dt
            if tug.cpuT <= 0 { tugPull(1); tug.cpuT = 1 / (tug.cpuRate * Double.random(in: 0.8...1.2)) }
        }
        if abs(tug.rope) >= 1 {
            let winner = tug.rope < 0 ? 0 : 1
            mpPoint(winner, "\(winner == 0 ? p1Name : p2Name) pulls it!")
            Sound.play("Glass", volume: 0.3)
            tug.roundOver = 1.5
        }
    }

    private func renderTug(_ ctx: CGContext) {
        let cx = splitX, half = splitX * 0.75
        let marker = cx + max(-1, min(1, tug.rope)) * half
        // Win lines
        ctx.setFillColor(hex(0xE84A5F, 0.6).cgColor)
        ctx.fill(CGRect(x: cx - half, y: World.ground, width: 1, height: 12))
        ctx.setFillColor(hex(0x5FA8E8, 0.6).cgColor)
        ctx.fill(CGRect(x: cx + half, y: World.ground, width: 1, height: 12))
        ctx.setFillColor(NSColor(white: 1, alpha: 0.35).cgColor)
        ctx.fill(CGRect(x: cx - 0.3, y: World.ground, width: 0.6, height: 4))
        // Rope follows the marker
        let x0 = marker - half - 14, x1 = marker + half + 14
        ctx.setStrokeColor(hex(0xC9A66B).cgColor)
        ctx.setLineWidth(1.2)
        ctx.move(to: CGPoint(x: x0, y: 11)); ctx.addLine(to: CGPoint(x: x1, y: 11)); ctx.strokePath()
        ctx.setFillColor(hex(0xE84A5F).cgColor)
        ctx.fill(CGRect(x: marker - 0.6, y: 6, width: 1.2, height: 10))
        for player in 0..<2 {
            let x = player == 0 ? x0 - 4 : x1 + 4
            let lean: CGFloat = tug.pull[player] > 0 ? (player == 0 ? -1.5 : 1.5) : 0
            drawCreature(ctx, avatar(player), x: x + lean, y: 0, scale: 1.1, facing: player == 0 ? 1 : -1, frame: tug.pull[player] > 0 ? 1 : 0)
        }
        drawCountdown(tug.countdown, ctx)
        if phase == .playing && tug.countdown <= 0 && tug.roundOver <= 0 && p1 + p2 == 0 {
            text("tap tap tap!", at: CGPoint(x: cx, y: 20), size: 6, color: NSColor(white: 1, alpha: 0.5), ctx: ctx, center: true)
        }
    }

    // MARK: - 🚧 Hurdle Race

    private func hurdleJump(_ player: Int) {
        guard hurdles.countdown <= 0, hurdles.runners[player].y <= 0.01 else { return }
        hurdles.runners[player].vy = 62
        Sound.play("Pop", volume: 0.12)
    }

    private func updateHurdles(_ dt: Double) {
        let fdt = CGFloat(dt)
        if countdown(&hurdles.countdown, dt) { return }
        for i in 0..<2 {
            var r = hurdles.runners[i]
            r.stumble -= dt
            let speed: CGFloat = r.stumble > 0 ? 45 : 125
            r.d += speed * fdt
            r.walk += Double(speed) * dt / 22
            if r.y > 0 || r.vy > 0 {
                r.vy -= 300 * fdt
                r.y += r.vy * fdt
                if r.y <= 0 { r.y = 0; r.vy = 0 }
            }
            for (k, h) in hurdles.hurdles.enumerated() where !hurdles.knocked[i].contains(k) && abs(r.d - h) < 4 && r.y < 3 {
                hurdles.knocked[i].insert(k)
                r.stumble = 0.7
                Sound.play("Funk", volume: 0.15)
            }
            hurdles.runners[i] = r
        }
        if !twoPlayer {
            let r = hurdles.runners[1]
            if let k = hurdles.hurdles.firstIndex(where: { $0 > r.d }) {
                if hurdles.cpuPlan[k] == nil { hurdles.cpuPlan[k] = Double.random(in: 0..<1) < 0.1 ? -999 : CGFloat.random(in: 17...33) }
                let plan = hurdles.cpuPlan[k]!
                if plan > 0 && hurdles.hurdles[k] - r.d <= plan && r.y <= 0.01 { hurdleJump(1); hurdles.cpuPlan[k] = -1 }
            }
        }
        let done = hurdles.runners.map { $0.d >= HurdleState.length }
        if done.contains(true) {
            if done[0] && done[1] { mpPoint(hurdles.runners[0].d >= hurdles.runners[1].d ? 0 : 1) }
            else { mpPoint(done[0] ? 0 : 1) }
            mpFinish()
        }
    }

    private func renderHurdles(_ ctx: CGContext) {
        for i in 0..<2 {
            let base = HurdleState.laneBase[i]
            let r = hurdles.runners[i]
            ctx.setFillColor((i == 0 ? hex(0xE84A5F, 0.15) : hex(0x5FA8E8, 0.15)).cgColor)
            ctx.fill(CGRect(x: 0, y: base - 0.5, width: World.W - 22, height: 0.8))
            for (k, h) in hurdles.hurdles.enumerated() {
                let x = HurdleState.screenX + (h - r.d)
                guard x > -5 && x < World.W - 22 else { continue }
                let down = hurdles.knocked[i].contains(k)
                ctx.setFillColor(NSColor(white: 1, alpha: 0.8).cgColor)
                ctx.fill(CGRect(x: x - 1.5, y: base, width: 0.5, height: down ? 1 : 3.5))
                ctx.fill(CGRect(x: x + 1, y: base, width: 0.5, height: down ? 1 : 3.5))
                ctx.setFillColor(hex(0xE84A5F).cgColor)
                ctx.fill(CGRect(x: x - 1.8, y: base + (down ? 0.6 : 3), width: 3.6, height: 0.8))
            }
            let finishX = HurdleState.screenX + (HurdleState.length - r.d)
            if finishX < World.W - 22 {
                for row in 0..<4 {
                    ctx.setFillColor((row % 2 == 0 ? NSColor.white : NSColor.black).cgColor)
                    ctx.fill(CGRect(x: finishX, y: base + CGFloat(row) * 2, width: 1.5, height: 2))
                }
            }
            let frame = r.y > 0 ? 1 : Int(r.walk * 2) % 2
            drawCreature(ctx, avatar(i), x: HurdleState.screenX, y: base - World.ground + r.y, scale: 0.65, facing: 1, frame: frame)
            let pct = Int(min(r.d / HurdleState.length, 1) * 100)
            let label = (i == 0 ? "🔴 " : (twoPlayer ? "🔵 " : "\(rival.emoji) ")) + "\(pct)%"
            text(label, at: CGPoint(x: 6, y: base + 1), size: 6, color: NSColor(white: 1, alpha: 0.85), ctx: ctx, bold: true)
        }
        drawCountdown(hurdles.countdown, ctx)
    }

    // MARK: - 🎴 Snap!

    private func snapTap(_ player: Int) {
        guard snap.countdown <= 0, snap.frozen[player] <= 0 else { return }
        if snap.matchLive && !snap.claimed {
            snap.claimed = true
            snap.flashSide = player
            snap.flashT = 0.5
            mpPoint(player, "SNAP!")
            Sound.play("Glass", volume: 0.35)
            if p1 >= 5 || p2 >= 5 { mpFinish() }
        } else if !snap.claimed {
            snap.frozen[player] = 1.0
            if player == 0 { p1 = max(0, p1 - 1) } else { p2 = max(0, p2 - 1) }
            addText("Oops! -1", x: player == 0 ? splitX / 2 : splitX * 1.5, y: 20, color: hex(0xFF9AA8))
            Sound.play("Funk", volume: 0.3)
        }
    }

    private func updateSnap(_ dt: Double) {
        snap.frozen[0] -= dt; snap.frozen[1] -= dt
        snap.flashT -= dt
        if countdown(&snap.countdown, dt) { return }
        snap.timer -= dt
        snap.shownFor += dt
        if snap.timer <= 0 {
            snap.previous = snap.current
            let match = Double.random(in: 0..<1) < 0.33
            var next = snap.current
            if !match { while next == snap.current { next = Int.random(in: 0..<SnapState.symbols.count) } }
            snap.current = next
            snap.matchLive = match
            snap.claimed = false
            snap.shownFor = 0
            snap.timer = max(0.85, 1.4 - Double(p1 + p2) * 0.05)
            snap.cpuReact = Double.random(in: 0.38...0.75)
            snap.cpuFalse = !match && Double.random(in: 0..<1) < 0.04
            Sound.play("Pop", volume: 0.1)
        }
        if !twoPlayer && !snap.claimed && snap.shownFor >= snap.cpuReact && (snap.matchLive || snap.cpuFalse) {
            snap.cpuFalse = false
            snapTap(1)
        }
    }

    private func renderSnap(_ ctx: CGContext) {
        let cx = splitX
        if let prev = snap.previous {
            ctx.addPath(CGPath(roundedRect: CGRect(x: cx - 40, y: 5, width: 18, height: 20), cornerWidth: 3, cornerHeight: 3, transform: nil))
            ctx.setFillColor(NSColor(white: 1, alpha: 0.35).cgColor)
            ctx.fillPath()
            text(SnapState.symbols[prev], at: CGPoint(x: cx - 31, y: 10), size: 10, color: .white, ctx: ctx, center: true)
        }
        let r = CGRect(x: cx - 14, y: 3, width: 28, height: 24)
        ctx.addPath(CGPath(roundedRect: r, cornerWidth: 4, cornerHeight: 4, transform: nil))
        ctx.setFillColor((snap.flashT > 0 ? (snap.flashSide == 0 ? hex(0xFFB0B0) : hex(0xB0D0FF)) : NSColor(white: 0.97, alpha: 1)).cgColor)
        ctx.fillPath()
        if snap.countdown <= 0 {
            text(SnapState.symbols[snap.current], at: CGPoint(x: cx, y: 9), size: 15, color: .white, ctx: ctx, center: true)
        }
        for player in 0..<2 where snap.frozen[player] > 0 {
            text("❄️ frozen", at: CGPoint(x: player == 0 ? splitX / 2 : splitX * 1.5, y: 8), size: 6, color: hex(0xBFE6FF), ctx: ctx, center: true)
        }
        drawCreature(ctx, avatar(0), x: 30, y: 0, scale: 1.0, facing: 1, frame: 0)
        drawCreature(ctx, avatar(1), x: World.W - 40, y: 0, scale: 1.0, facing: -1, frame: 0)
        drawCountdown(snap.countdown, ctx)
        if phase == .playing && snap.countdown <= 0 && p1 + p2 == 0 {
            text("tap when it matches the card before", at: CGPoint(x: splitX / 2 + 10, y: 15), size: 5.5, color: NSColor(white: 1, alpha: 0.5), ctx: ctx, center: true)
        }
    }

    // MARK: - 💥 Pop Battle

    private func popBattleTap(_ player: Int, x: CGFloat) {
        let lo = player == 0 ? 0 : splitX, hi = player == 0 ? splitX : World.W - 22
        guard let i = popBattle.bubbles.indices.filter({ popBattle.bubbles[$0].x >= lo && popBattle.bubbles[$0].x < hi })
                .min(by: { abs(popBattle.bubbles[$0].x - x) < abs(popBattle.bubbles[$1].x - x) }),
              abs(popBattle.bubbles[i].x - x) < popBattle.bubbles[i].r + 6 else { return }
        let b = popBattle.bubbles.remove(at: i)
        let pts = b.kind == .gold ? 3 : 1
        if player == 0 { p1 += pts } else { p2 += pts }
        burst(.spark(b.kind == .gold ? hex(0xFFD23F) : hex(0xA8DDFF)), at: b.x, b.y, count: 5)
        if pts > 1 { addText("+3", x: b.x, y: b.y, color: hex(0xFFD23F)) }
        Sound.play("Pop", volume: 0.2)
    }

    private func updatePopBattle(_ dt: Double) {
        let fdt = CGFloat(dt)
        timeLeft -= dt
        if timeLeft <= 0 { timeLeft = 0; popBattle.bubbles.removeAll(); mpFinish(); return }
        popBattle.spawn -= dt
        if popBattle.spawn <= 0 {
            popBattle.spawn = Double.random(in: 0.35...0.7)
            let rel = CGFloat.random(in: 14...(splitX - 14))
            let gold = Double.random(in: 0..<1) < 0.12
            let r = CGFloat.random(in: 4.5...7)
            let vy = CGFloat.random(in: 9...15)
            for base in [0, splitX] {   // mirrored on both sides, so it's fair
                popBattle.bubbles.append(Bubble(kind: gold ? .gold : .normal, x: base + rel, y: -r, r: r, vy: vy, phase: 0))
            }
        }
        for i in popBattle.bubbles.indices { popBattle.bubbles[i].y += popBattle.bubbles[i].vy * fdt }
        popBattle.bubbles.removeAll { $0.y - $0.r > World.H }
        if !twoPlayer {
            popBattle.cpuT -= dt
            if popBattle.cpuT <= 0 {
                popBattle.cpuT = Double.random(in: 0.45...0.8)
                if let b = popBattle.bubbles.filter({ $0.x >= splitX && $0.y > 3 }).max(by: { ($0.kind == .gold ? 100 : $0.y) < ($1.kind == .gold ? 100 : $1.y) }) {
                    popBattleTap(1, x: b.x)   // the rival pops on its own side
                }
            }
        }
    }

    private func renderPopBattle(_ ctx: CGContext) {
        ctx.setFillColor(NSColor(white: 1, alpha: 0.25).cgColor)
        ctx.fill(CGRect(x: splitX - 0.3, y: 0, width: 0.6, height: World.H - 9))
        for b in popBattle.bubbles {
            let rect = CGRect(x: b.x - b.r, y: b.y - b.r, width: b.r * 2, height: b.r * 2)
            ctx.setFillColor((b.kind == .gold ? hex(0xFFD23F, 0.3) : hex(0x7FC8FF, 0.22)).cgColor)
            ctx.fillEllipse(in: rect)
            ctx.setStrokeColor((b.kind == .gold ? hex(0xFFE58A) : hex(0xBFE6FF, 0.9)).cgColor)
            ctx.setLineWidth(0.8)
            ctx.strokeEllipse(in: rect)
        }
    }

    // MARK: - 🥅 Soccer

    private var goalLeft: CGFloat { 10 }
    private var goalRight: CGFloat { World.W - 30 }
    private var goalTop: CGFloat { World.ground + 14 }

    private func kickoff() {
        soccer.ball = CGPoint(x: (goalLeft + goalRight) / 2, y: 24)
        soccer.vx = CGFloat.random(in: -20...20)
        soccer.vy = 0
        soccer.px = [goalLeft + 60, goalRight - 60]
        soccer.pause = 1.2
    }

    private func updateSoccer(_ dt: Double) {
        let fdt = CGFloat(dt)
        if soccer.pause > 0 { soccer.pause -= dt; return }
        if !twoPlayer {
            // Rival stays on the goal side of the ball so its kicks head toward Player 1's goal.
            let want = soccer.ball.x + 6
            soccer.target[1] = soccer.ball.x > soccer.px[1] - 2 ? soccer.ball.x + 12 : want
        }
        for i in 0..<2 {
            soccer.kickCooldown[i] -= dt
            let speed: CGFloat = (!twoPlayer && i == 1) ? 170 : 260
            if let t = soccer.target[i] {
                let dx = min(max(t, goalLeft + 6), goalRight - 6) - soccer.px[i]
                let step = max(-speed * fdt, min(speed * fdt, dx))
                soccer.px[i] += step
                soccer.vel[i] = step / max(fdt, 0.001)
                if abs(step) > 0.1 { soccer.walk[i] += dt * 6 }
            } else { soccer.vel[i] = 0 }
        }
        soccer.vy -= 150 * fdt
        soccer.ball.x += soccer.vx * fdt
        soccer.ball.y += soccer.vy * fdt
        soccer.vx *= 1 - 0.2 * fdt
        if soccer.ball.y <= World.ground + 2 {
            soccer.ball.y = World.ground + 2
            soccer.vy = abs(soccer.vy) * 0.6
            soccer.vx *= 0.92
        }
        if soccer.ball.y > World.H - 1 { soccer.ball.y = World.H - 1; soccer.vy = -abs(soccer.vy) * 0.5 }
        // Kicks
        for i in 0..<2 where soccer.kickCooldown[i] <= 0 && abs(soccer.ball.x - soccer.px[i]) < 8 && soccer.ball.y < World.ground + 14 {
            let dir: CGFloat = soccer.ball.x >= soccer.px[i] ? 1 : -1
            // Close to the goal it's a low driven shot; further out a lofted kick.
            let toGoal = abs((dir < 0 ? goalLeft : goalRight) - soccer.ball.x)
            soccer.vx = dir * (150 + abs(soccer.vel[i]) * 0.35) + CGFloat.random(in: -15...15)
            soccer.vy = toGoal < 150 ? CGFloat.random(in: 15...40) : CGFloat.random(in: 55...90)
            soccer.kickCooldown[i] = 0.25
            Sound.play("Pop", volume: 0.2)
        }
        // Goals / walls
        if soccer.ball.x < goalLeft {
            if soccer.ball.y < goalTop { goal(by: 1) } else { soccer.ball.x = goalLeft; soccer.vx = abs(soccer.vx) * 0.6 }
        } else if soccer.ball.x > goalRight {
            if soccer.ball.y < goalTop { goal(by: 0) } else { soccer.ball.x = goalRight; soccer.vx = -abs(soccer.vx) * 0.6 }
        }
    }

    private func goal(by player: Int) {
        mpPoint(player, "GOAL!")
        flash = 0.2
        Sound.play("Glass", volume: 0.35)
        burst(.spark(player == 0 ? hex(0xFF8A8A) : hex(0x8AB8FF)), at: player == 0 ? goalRight : goalLeft, 10, count: 12)
        if p1 >= 5 || p2 >= 5 { mpFinish(); return }
        kickoff()
    }

    private func renderSoccer(_ ctx: CGContext) {
        ctx.setFillColor(NSColor(white: 1, alpha: 0.3).cgColor)
        ctx.fill(CGRect(x: (goalLeft + goalRight) / 2 - 0.3, y: 0, width: 0.6, height: World.ground + 1))
        for (x, dir, c) in [(goalLeft, CGFloat(-1), hex(0xE84A5F)), (goalRight, CGFloat(1), hex(0x5FA8E8))] {
            ctx.setFillColor(NSColor(white: 1, alpha: 0.12).cgColor)
            ctx.fill(CGRect(x: dir < 0 ? x - 8 : x, y: World.ground, width: 8, height: goalTop - World.ground))
            ctx.setFillColor(c.cgColor)
            ctx.fill(CGRect(x: x - 0.5, y: World.ground, width: 1, height: goalTop - World.ground))
            ctx.fill(CGRect(x: dir < 0 ? x - 8 : x, y: goalTop - 0.8, width: 8, height: 0.8))
        }
        for i in 0..<2 {
            drawCreature(ctx, avatar(i), x: soccer.px[i], y: 0, scale: 1.0, facing: i == 0 ? 1 : -1, frame: Int(soccer.walk[i] * 2) % 2)
        }
        drawItem(ctx, .soccer, x: soccer.ball.x, y: soccer.ball.y - 2, scale: 0.9)
    }

    // MARK: - ✊ Rock Paper Scissors

    private func handX(_ player: Int, _ k: Int) -> CGFloat {
        let lo = player == 0 ? 0 : splitX
        let w = player == 0 ? splitX : World.W - 22 - splitX
        return lo + w * (CGFloat(k) + 0.5) / 3
    }

    private func rpsChoose(_ player: Int, x: CGFloat) {
        guard rps.revealT <= 0, rps.choice[player] == nil else { return }
        guard let k = (0..<3).min(by: { abs(handX(player, $0) - x) < abs(handX(player, $1) - x) }) else { return }
        rps.choice[player] = k
        Sound.play("Tink", volume: 0.2)
    }

    private func updateRPS(_ dt: Double) {
        if rps.revealT > 0 {
            rps.revealT -= dt
            if rps.revealT <= 0 {
                if p1 >= 3 || p2 >= 3 { mpFinish(); return }
                rps = RPSState()
                rps.cpuAt = Double.random(in: 0.5...2.5)
            }
            return
        }
        rps.timer -= dt
        if !twoPlayer && rps.choice[1] == nil && 3 - rps.timer >= rps.cpuAt { rps.choice[1] = Int.random(in: 0..<3) }
        if rps.timer <= 0 {
            for i in 0..<2 where rps.choice[i] == nil { rps.choice[i] = Int.random(in: 0..<3); rps.auto[i] = true }
            let a = rps.choice[0]!, b = rps.choice[1]!
            if a == b { addText("Tie!", x: splitX, y: 20, color: .white) }
            else { mpPoint((a - b + 3) % 3 == 1 ? 0 : 1, "Wins!") }
            Sound.play(a == b ? "Pop" : "Glass", volume: 0.3)
            rps.revealT = 1.8
        }
    }

    private func renderRPS(_ ctx: CGContext) {
        let words = ["Rock…", "Paper…", "Scissors…"]
        let revealed = rps.revealT > 0
        for player in 0..<2 {
            if revealed {
                let k = rps.choice[player] ?? 0
                text(RPSState.hands[k], at: CGPoint(x: player == 0 ? splitX / 2 : splitX * 1.5, y: 4), size: 16, color: .white, ctx: ctx, center: true)
                if rps.auto[player] { text("(too slow — random)", at: CGPoint(x: player == 0 ? splitX / 2 : splitX * 1.5, y: 21), size: 5, color: NSColor(white: 1, alpha: 0.6), ctx: ctx, center: true) }
                continue
            }
            let chosen = rps.choice[player] != nil
            if !twoPlayer && player == 1 {
                text(chosen ? "\(rival.emoji) ready ✓" : "\(rival.emoji) thinking…", at: CGPoint(x: splitX * 1.5, y: 9), size: 7, color: .white, ctx: ctx, center: true)
                continue
            }
            for k in 0..<3 {
                let x = handX(player, k)
                ctx.addPath(CGPath(roundedRect: CGRect(x: x - 14, y: 3, width: 28, height: 16), cornerWidth: 4, cornerHeight: 4, transform: nil))
                ctx.setFillColor(NSColor(white: 1, alpha: chosen ? 0.06 : 0.16).cgColor)
                ctx.fillPath()
                text(RPSState.hands[k], at: CGPoint(x: x, y: 6), size: 11, color: NSColor(white: 1, alpha: chosen ? 0.3 : 1), ctx: ctx, center: true)
            }
            if chosen { text("ready ✓", at: CGPoint(x: player == 0 ? splitX / 2 : splitX * 1.5, y: 20.5), size: 6, color: hex(0x7BE07B), ctx: ctx, center: true, bold: true) }
        }
        if !revealed {
            let i = min(2, Int(3 - max(rps.timer, 0)))
            text(rps.timer > 0 ? words[i] : "SHOOT!", at: CGPoint(x: splitX, y: 20.5), size: 7, color: hex(0xFFD23F), ctx: ctx, center: true, bold: true)
        }
    }

    // MARK: - 🧮 Math Battle

    private func newBattleQuestion() {
        let level = (p1 + p2) / 3
        var a: Int, b: Int, op: String
        switch level {
        case 0: op = "+"; a = Int.random(in: 2...12); b = Int.random(in: 2...12)
        case 1: op = Bool.random() ? "+" : "−"; a = Int.random(in: 10...30); b = Int.random(in: 2...a)
        default: op = ["+", "−", "×"].randomElement()!
            if op == "×" { a = Int.random(in: 2...9); b = Int.random(in: 2...9) } else { a = Int.random(in: 15...60); b = Int.random(in: 3...a) }
        }
        mathBattle.answer = op == "+" ? a + b : op == "−" ? a - b : a * b
        mathBattle.question = "\(a) \(op) \(b) = ?"
        var opts: Set<Int> = [mathBattle.answer]
        while opts.count < 3 {
            let d = Int.random(in: 1...max(3, mathBattle.answer / 6 + 2)) * (Bool.random() ? 1 : -1)
            if mathBattle.answer + d >= 0 { opts.insert(mathBattle.answer + d) }
        }
        mathBattle.options = Array(opts).shuffled()
        mathBattle.cpuT = Double.random(in: 1.8...3.8)
    }

    private func mathBattleTap(_ player: Int, x: CGFloat) {
        guard mathBattle.countdown <= 0, mathBattle.nextT <= 0, mathBattle.frozen[player] <= 0,
              let k = (0..<3).min(by: { abs(handX(player, $0) - x) < abs(handX(player, $1) - x) }) else { return }
        mathAnswer(player, k)
    }

    private func mathAnswer(_ player: Int, _ k: Int) {
        if mathBattle.options[k] == mathBattle.answer {
            mpPoint(player, "✓ \(mathBattle.answer)")
            mathBattle.solvedBy = player
            mathBattle.nextT = 0.8
            Sound.play("Glass", volume: 0.3)
        } else {
            mathBattle.frozen[player] = 1.5
            mathBattle.wrongSide = player
            Sound.play("Funk", volume: 0.25)
        }
    }

    private func updateMathBattle(_ dt: Double) {
        mathBattle.frozen[0] -= dt; mathBattle.frozen[1] -= dt
        if countdown(&mathBattle.countdown, dt) { return }
        if mathBattle.nextT > 0 {
            mathBattle.nextT -= dt
            if mathBattle.nextT <= 0 {
                if p1 >= 7 || p2 >= 7 { mpFinish(); return }
                newBattleQuestion()
            }
            return
        }
        if !twoPlayer && mathBattle.frozen[1] <= 0 {
            mathBattle.cpuT -= dt
            if mathBattle.cpuT <= 0 {
                let right = mathBattle.options.firstIndex(of: mathBattle.answer)!
                let pick = Double.random(in: 0..<1) < 0.85 ? right : (right + 1) % 3
                mathAnswer(1, pick)
                mathBattle.cpuT = Double.random(in: 1.5...3)
            }
        }
    }

    private func renderMathBattle(_ ctx: CGContext) {
        drawCountdown(mathBattle.countdown, ctx)
        guard mathBattle.countdown <= 0 else { return }
        text(mathBattle.question, at: CGPoint(x: splitX, y: 19.5), size: 8, color: .white, ctx: ctx, center: true, bold: true)
        for player in 0..<2 {
            let frozen = mathBattle.frozen[player] > 0
            if !twoPlayer && player == 1 {
                text(frozen ? "\(rival.emoji) ❌ frozen" : "\(rival.emoji) thinking…", at: CGPoint(x: splitX * 1.5, y: 7), size: 7, color: .white, ctx: ctx, center: true)
                continue
            }
            for k in 0..<3 {
                let x = handX(player, k)
                let solved = mathBattle.nextT > 0 && mathBattle.options[k] == mathBattle.answer
                ctx.addPath(CGPath(roundedRect: CGRect(x: x - 15, y: 3, width: 30, height: 13), cornerWidth: 4, cornerHeight: 4, transform: nil))
                ctx.setFillColor((solved ? hex(0x6CD47A, 0.6) : NSColor(white: 1, alpha: frozen ? 0.05 : 0.16)).cgColor)
                ctx.fillPath()
                text("\(mathBattle.options[k])", at: CGPoint(x: x, y: 5.5), size: 8, color: NSColor(white: 1, alpha: frozen ? 0.3 : 1), ctx: ctx, center: true, bold: true)
            }
            if frozen { text("❌ frozen", at: CGPoint(x: player == 0 ? splitX / 2 : splitX * 1.5, y: 17), size: 5.5, color: hex(0xFF9AA8), ctx: ctx, center: true) }
        }
    }

    // MARK: - 💣 Hot Potato

    private var potatoX: [CGFloat] { [60, World.W - 50] }

    private func newPotatoRound(holder: Int) {
        potato.holder = holder
        potato.flying = false
        potato.fuseTotal = Double.random(in: 6...13)
        potato.fuse = potato.fuseTotal
        potato.readyT = Double.random(in: 0.3...1.0)
        potato.boomT = 0
        potato.countdown = 1.5
        potato.cpuDelay = Double.random(in: 0.2...0.5)
    }

    private func potatoThrow(_ player: Int) {
        guard potato.countdown <= 0, potato.boomT <= 0, !potato.flying, player == potato.holder else { return }
        if potato.readyT > 0 {
            potato.readyT += 0.8
            addText("Fumble!", x: potatoX[player] + (player == 0 ? 30 : -30), y: 15, color: hex(0xFF9AA8))
            Sound.play("Funk", volume: 0.25)
            return
        }
        potato.flying = true
        potato.flyT = 0
        Sound.play("Blow", volume: 0.2)
    }

    private func updatePotato(_ dt: Double) {
        if potato.boomT > 0 {
            potato.boomT -= dt
            if potato.boomT <= 0 {
                if p1 >= 3 || p2 >= 3 { mpFinish(); return }
                newPotatoRound(holder: Int.random(in: 0...1))
            }
            return
        }
        if countdown(&potato.countdown, dt) { return }
        potato.fuse -= dt
        if potato.flying {
            potato.flyT += dt
            if potato.flyT >= 0.45 {
                potato.flying = false
                potato.holder = 1 - potato.holder
                potato.readyT = Double.random(in: 0.3...1.0)
                potato.cpuDelay = Double.random(in: 0.2...0.5)
            }
        } else {
            potato.readyT -= dt
            if !twoPlayer && potato.holder == 1 && potato.readyT <= -potato.cpuDelay { potatoThrow(1) }
        }
        if potato.fuse <= 0 {
            let loser = potato.flying ? 1 - potato.holder : potato.holder
            mpPoint(1 - loser, "BOOM!")
            flash = 0.4
            burst(.spark(hex(0xFFB347)), at: potatoX[loser], 12, count: 16)
            Sound.play("Basso", volume: 0.4)
            potato.boomT = 1.6
        }
    }

    private func renderPotato(_ ctx: CGContext) {
        for i in 0..<2 {
            drawCreature(ctx, avatar(i), x: potatoX[i], y: 0, scale: 1.2, facing: i == 0 ? 1 : -1, frame: 0)
        }
        drawCountdown(potato.countdown, ctx)
        guard potato.boomT <= 0 else { return }
        var bx = potatoX[potato.holder] + (potato.holder == 0 ? 12 : -12), by: CGFloat = 13
        if potato.flying {
            let f = CGFloat(potato.flyT / 0.45)
            let from = potatoX[potato.holder] + (potato.holder == 0 ? 12 : -12)
            let to = potatoX[1 - potato.holder] + (potato.holder == 0 ? -12 : 12)
            bx = from + (to - from) * f
            by = 13 + sin(f * .pi) * 12
        }
        drawItem(ctx, .bomb, x: bx, y: by - 4, scale: 1.4)
        // Fuse burns down
        let fuseFrac = CGFloat(max(potato.fuse, 0) / potato.fuseTotal)
        ctx.setFillColor(hex(0xFFB347).cgColor)
        ctx.fill(CGRect(x: splitX - 40, y: 26, width: 80 * fuseFrac, height: 1))
        if Int(t * 12) % 2 == 0 {
            ctx.setFillColor(hex(0xFFE066).cgColor)
            ctx.fillEllipse(in: CGRect(x: splitX - 40 + 80 * fuseFrac - 1, y: 25.5, width: 2, height: 2))
        }
        if !potato.flying && potato.readyT <= 0 {
            text("!", at: CGPoint(x: bx, y: 18), size: 10, color: hex(0x7BE07B), ctx: ctx, center: true, bold: true)
        }
    }

    // MARK: - 🛸 Space Duel

    private var shipX: [CGFloat] { [26, World.W - 36] }
    private func shipY(_ i: Int) -> CGFloat { 14 + 6.5 * CGFloat(sin(spaceDuel.phase[i])) }

    private func spaceFire(_ player: Int) {
        guard spaceDuel.countdown <= 0, spaceDuel.reload[player] <= 0 else { return }
        spaceDuel.lasers.append(.init(x: shipX[player] + (player == 0 ? 6 : -6), y: shipY(player), dir: player == 0 ? 1 : -1, owner: player))
        spaceDuel.reload[player] = 0.7
        Sound.play("Pop", volume: 0.12)
    }

    private func updateSpaceDuel(_ dt: Double) {
        let fdt = CGFloat(dt)
        for i in 0..<2 {
            spaceDuel.phase[i] += spaceDuel.omega[i] * dt
            spaceDuel.reload[i] -= dt
            spaceDuel.hitFlash[i] -= dt
        }
        if countdown(&spaceDuel.countdown, dt) { return }
        var i = 0
        while i < spaceDuel.lasers.count {
            spaceDuel.lasers[i].x += spaceDuel.lasers[i].dir * 280 * fdt
            let l = spaceDuel.lasers[i]
            let target = 1 - l.owner
            if (l.dir > 0 && l.x >= shipX[target] - 4) || (l.dir < 0 && l.x <= shipX[target] + 4) {
                spaceDuel.lasers.remove(at: i)
                if abs(l.y - shipY(target)) < 2.8 {
                    spaceDuel.hitFlash[target] = 0.4
                    spaceDuel.omega[target] = Double.random(in: 1.3...2.8)
                    mpPoint(l.owner, "Hit!")
                    Sound.play("Glass", volume: 0.3)
                    burst(.spark(hex(0xFFB347)), at: shipX[target], shipY(target), count: 8)
                    if p1 >= 5 || p2 >= 5 { mpFinish(); return }
                }
                continue
            }
            i += 1
        }
        if !twoPlayer {
            spaceDuel.cpuT -= dt
            if spaceDuel.cpuT <= 0 {
                spaceDuel.cpuT = 0.15
                let travel = Double(shipX[1] - shipX[0]) / 280
                let predicted = 14 + 6.5 * CGFloat(sin(spaceDuel.phase[0] + spaceDuel.omega[0] * travel))
                if abs(predicted - shipY(1)) < 2 && Double.random(in: 0..<1) < 0.55 { spaceFire(1) }
            }
        }
    }

    private func renderSpaceDuel(_ ctx: CGContext) {
        for i in 0..<2 {
            let x = shipX[i], y = shipY(i)
            guard spaceDuel.hitFlash[i] <= 0 || Int(t * 12) % 2 == 0 else { continue }
            ctx.saveGState()
            ctx.translateBy(x: x, y: y)
            ctx.rotate(by: i == 0 ? -.pi / 2 : .pi / 2)
            let img = ItemKind.ship.image
            let w = CGFloat(img.width) * 1.5, h = CGFloat(img.height) * 1.5
            ctx.draw(img, in: CGRect(x: -w / 2, y: -h / 2, width: w, height: h))
            ctx.restoreGState()
            ctx.setFillColor((i == 0 ? hex(0xE84A5F) : hex(0x5FA8E8)).cgColor)
            ctx.fillEllipse(in: CGRect(x: x - (i == 0 ? 8 : -6.4), y: y - 1, width: 2, height: 2))
        }
        for l in spaceDuel.lasers {
            ctx.setFillColor((l.owner == 0 ? hex(0xFF7F7F) : hex(0x7FB8FF)).cgColor)
            ctx.fill(CGRect(x: l.x - 3, y: l.y - 0.3, width: 6, height: 0.6))
        }
        drawCountdown(spaceDuel.countdown, ctx)
        if phase == .playing && spaceDuel.countdown <= 0 && p1 + p2 == 0 {
            text("tap to fire — time it so the laser meets the other ship", at: CGPoint(x: splitX, y: 2), size: 5, color: NSColor(white: 1, alpha: 0.5), ctx: ctx, center: true)
        }
    }

    // MARK: - 🎾 Tennis Duel

    private var tdL: CGFloat { 50 }
    private var tdR: CGFloat { World.W - 48 }
    private var tdNet: CGFloat { (tdL + tdR) / 2 }
    private var tdTable: CGFloat { World.ground + 6 }
    private var tdPaddle: [CGFloat] { [tdL - 8, tdR + 8] }
    /// Hit window grows with ball speed (about ±60 ms), so fast rallies stay hard but possible.
    private var tdWindow: CGFloat { max(14, pongDuel.speed * 0.06) }

    private func tdLaunch(from: CGPoint, toward player: Int) {
        let landX = player == 0 ? CGFloat.random(in: (tdL + 20)...(tdNet - 25)) : CGFloat.random(in: (tdNet + 25)...(tdR - 20))
        let T = abs(from.x - landX) / pongDuel.speed
        pongDuel.ball = from
        pongDuel.vx = player == 0 ? -pongDuel.speed : pongDuel.speed
        pongDuel.g = arcGravity(fromY: from.y, landY: tdTable, apex: 20, time: T)
        pongDuel.vy = (tdTable - from.y + 0.5 * pongDuel.g * T * T) / T
        pongDuel.bounced = false
        pongDuel.inPlay = true
        pongDuel.swung[player] = false
        // The rival gets sloppier as rallies speed up.
        let pressure = Double(pongDuel.speed - 170) / 250
        pongDuel.cpuOffset = CGFloat.random(in: -3...3) * (1 + (pongDuel.speed - 170) / 70)
            + (Double.random(in: 0..<1) < 0.12 + pressure * 0.4 ? 18 : 0)
    }

    private func pongDuelSwing(_ player: Int) {
        guard pongDuel.swing[player] <= 0 else { return }
        pongDuel.swing[player] = 0.15
        let toward = pongDuel.vx < 0 ? 0 : 1
        guard pongDuel.inPlay, toward == player, !pongDuel.swung[player] else { return }
        pongDuel.swung[player] = true
        let dx = abs(pongDuel.ball.x - tdPaddle[player])
        guard pongDuel.bounced, dx < tdWindow else { return }
        let smash = dx < max(4, pongDuel.speed * 0.016)
        pongDuel.speed = min(pongDuel.speed + (smash ? 35 : 18), 520)
        Sound.play(smash ? "Glass" : "Pop", volume: 0.3)
        if smash { addText("Smash!", x: tdPaddle[player] + (player == 0 ? 20 : -20), y: 20, color: hex(0xFFD23F)) }
        tdLaunch(from: pongDuel.ball, toward: 1 - player)
    }

    private func updatePongDuel(_ dt: Double) {
        let fdt = CGFloat(dt)
        pongDuel.swing[0] -= dt; pongDuel.swing[1] -= dt
        if !pongDuel.inPlay {
            pongDuel.serveT -= dt
            if pongDuel.serveT <= 0 {
                let s = pongDuel.server
                pongDuel.speed = 170 + CGFloat(min(pongDuel.points, 10)) * 12   // each new rally starts faster
                tdLaunch(from: CGPoint(x: tdPaddle[s] + (s == 0 ? 6 : -6), y: 15), toward: 1 - s)
            }
            return
        }
        pongDuel.vy -= pongDuel.g * fdt
        pongDuel.ball.x += pongDuel.vx * fdt
        pongDuel.ball.y += pongDuel.vy * fdt
        if pongDuel.vy < 0 && pongDuel.ball.y <= tdTable + 1 && pongDuel.ball.x > tdL && pongDuel.ball.x < tdR {
            pongDuel.ball.y = tdTable + 1
            pongDuel.vy = abs(pongDuel.vy) * 0.85
            let receiver = pongDuel.vx < 0 ? 0 : 1
            if (receiver == 0) == (pongDuel.ball.x < tdNet) { pongDuel.bounced = true }
        }
        if !twoPlayer && pongDuel.vx > 0 && pongDuel.bounced && !pongDuel.swung[1]
            && pongDuel.ball.x >= tdPaddle[1] - 1 + pongDuel.cpuOffset {
            pongDuelSwing(1)
        }
        let missedBy: Int? = pongDuel.ball.x < tdPaddle[0] - tdWindow ? 0 : pongDuel.ball.x > tdPaddle[1] + tdWindow ? 1 : (pongDuel.ball.y < 0 ? (pongDuel.vx < 0 ? 0 : 1) : nil)
        if let m = missedBy {
            mpPoint(1 - m, "Point!")
            Sound.play("Funk", volume: 0.25)
            pongDuel.points += 1
            pongDuel.inPlay = false
            pongDuel.serveT = 1.0
            pongDuel.server = 1 - pongDuel.server
            if p1 >= 5 || p2 >= 5 { mpFinish() }
        }
    }

    private func renderPongDuel(_ ctx: CGContext) {
        ctx.setFillColor(hex(0x2E6FD0).cgColor)
        ctx.fill(CGRect(x: tdL, y: tdTable - 1.6, width: tdR - tdL, height: 2.2))
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fill(CGRect(x: tdL, y: tdTable + 0.3, width: tdR - tdL, height: 0.25))
        ctx.fill(CGRect(x: tdNet - 0.3, y: tdTable, width: 0.6, height: 3))
        ctx.setFillColor(hex(0x55596A).cgColor)
        for x in [tdL + 6, tdR - 6] { ctx.fill(CGRect(x: x, y: 0, width: 1, height: tdTable - 1.6)) }
        for i in 0..<2 {
            drawCreature(ctx, avatar(i), x: i == 0 ? 14 : World.W - 32, y: 0, scale: 0.9, facing: i == 0 ? 1 : -1, frame: 0)
            let a: CGFloat = pongDuel.swing[i] > 0 ? -0.6 : 0.5
            ctx.saveGState()
            ctx.translateBy(x: tdPaddle[i] + (i == 0 ? -4 : 4), y: tdTable + 5)
            ctx.rotate(by: i == 0 ? a : -a)
            ctx.setFillColor(hex(0x8B5A2B).cgColor)
            ctx.fill(CGRect(x: -0.5, y: -4, width: 1, height: 3))
            ctx.setFillColor((i == 0 ? hex(0xE84A5F) : hex(0x3A6EE8)).cgColor)
            ctx.fillEllipse(in: CGRect(x: -2.2, y: -1.5, width: 4.4, height: 5))
            ctx.restoreGState()
        }
        if pongDuel.inPlay {
            ctx.setFillColor(hex(0xFFF4E0).cgColor)
            ctx.fillEllipse(in: CGRect(x: pongDuel.ball.x - 1, y: pongDuel.ball.y - 1, width: 2, height: 2))
        }
    }
}
