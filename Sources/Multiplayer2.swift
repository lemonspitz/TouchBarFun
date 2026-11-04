import AppKit

// MARK: - State

struct TTTState {
    static let lines = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]
    var board = [Int](repeating: -1, count: 9)
    var turn = 0
    var starter = 0
    var winLine: [Int]?
    var resultT: Double = 0
    var cpuT: Double = 0.7
}

struct C4State {
    static let cols = 7, rows = 6
    var board = [[Int]](repeating: [Int](repeating: -1, count: 6), count: 7)    // [col][row], row 0 = bottom
    var turn = 0
    var starter = 0
    var dropping: (col: Int, row: Int, y: CGFloat)?
    var winCells: [(Int, Int)] = []
    var resultT: Double = 0
    var cpuT: Double = 0.8
}

struct BoxingState {
    var punchT = [0.0, 0.0]          // counts down 0.3 → 0 while a jab is thrown
    var landed = [false, false]
    var blocking = [false, false]
    var stun = [0.0, 0.0]
    var cooldown = [0.0, 0.0]
    var pressAt: [Double?] = [nil, nil]
    var hitFlash = [0.0, 0.0]
    var cpuNext: Double = 1.2
    var cpuBlockUntil: Double = 0
    var cpuSawPunch = false
}

struct CannonState {
    var hp = [3, 3]
    var turn = 0
    var charging = false
    var chargeT: Double = 0
    var shot: Item?
    var shooter = 0
    var wind: CGFloat = 0
    var wait: Double = 0.8
    var path: [CGPoint] = []
    var lastPath: [[CGPoint]] = [[], []]
    var cpuPower: CGFloat = 0.5
}

struct PumpState {
    var size: [CGFloat] = [0, 0]
    var limit: [CGFloat] = [0.85, 0.85]
    var popped = [false, false]
    var timer: Double = 8
    var countdown: Double = 2
    var resultT: Double = 0
    var cpuTarget: CGFloat = 0.7
    var cpuT: Double = 0
}

struct MemDuelState {
    var sequence: [Int] = []
    var showing = true
    var showIndex = 0
    var timer: Double = 1.2
    var lit: Int?
    var litT: Double = 0
    var progress = [0, 0]
    var failed = [false, false]
    var done = [false, false]
    var playerLit: [Int?] = [nil, nil]
    var playerLitT = [0.0, 0.0]
    var cpuT: Double = 0
    var resultT: Double = 0
}

struct GallopState {
    static let length: CGFloat = 900
    var d: [CGFloat] = [0, 0]
    var v: [CGFloat] = [35, 35]
    var beat: Double = 0.45
    var song: Double = 0
    var lastBeat = [-1, -1]
    var stumble = [0.0, 0.0]
    var feedback = ["", ""]
    var fbT = [0.0, 0.0]
    var walk = [0.0, 0.0]
    var countdown: Double = 3
    var cpuNext: Double = 0
}

struct NumbersState {
    var layout: [Int] = []
    var next = [1, 1]
    var frozen = [0.0, 0.0]
    var wrong: [Int?] = [nil, nil]
    var resultT: Double = 0
    var countdown: Double = 1.5
    var cpuT: Double = 0.6
}

// MARK: - Dispatch

extension Mode {
    /// Turn-based board games: whoever's turn it is plays, from anywhere on the bar.
    var isTurnBased: Bool { [.tictactoe, .connect4, .cannon].contains(self) }
}

extension World {
    func resetMP2(_ m: Mode) {
        switch m {
        case .tictactoe: ttt = TTTState()
        case .connect4: c4 = C4State()
        case .boxing: boxing = BoxingState()
        case .cannon: cannon = CannonState(); cannon.wind = CGFloat.random(in: -20...20)
        case .pump: pump = PumpState(); newPumpRound()
        case .memoryDuel: memDuel = MemDuelState(); memDuel.sequence = [Int.random(in: 0..<4)]
        case .gallop: gallop = GallopState()
        case .numbers: numbers = NumbersState(); numbers.layout = Array(1...8).shuffled()
        default: break
        }
    }

    /// Whose move a touch is in a turn-based game (nil = the computer's turn).
    private func turnPlayer(_ turn: Int) -> Int? { twoPlayer ? turn : (turn == 0 ? 0 : nil) }

    func mp2TouchBegan(_ p: CGPoint, player: Int) {
        switch mode {
        case .tictactoe: if let pl = turnPlayer(ttt.turn) { tttPlace(pl, at: p.x) }
        case .connect4: if let pl = turnPlayer(c4.turn) { c4Drop(pl, at: p.x) }
        case .cannon: if turnPlayer(cannon.turn) != nil && cannon.shot == nil && cannon.wait <= 0 { cannon.charging = true; cannon.chargeT = 0 }
        case .boxing: if boxing.stun[player] <= 0 { boxing.pressAt[player] = t }
        case .pump: pumpTap(player)
        case .memoryDuel: memDuelTap(player, x: p.x)
        case .gallop: gallopTap(player)
        case .numbers: numbersTap(player, x: p.x)
        default: break
        }
    }

    func mp2TouchEnded(_ p: CGPoint, player: Int) {
        switch mode {
        case .boxing:
            if let start = boxing.pressAt[player], t - start < 0.18 { boxingJab(player) }
            boxing.pressAt[player] = nil
            boxing.blocking[player] = false
        case .cannon: if cannon.charging { fireCannon() }
        default: break
        }
    }

    func updateMP2(_ dt: Double) {
        switch mode {
        case .tictactoe: updateTTT(dt)
        case .connect4: updateC4(dt)
        case .boxing: updateBoxing(dt)
        case .cannon: updateCannon(dt)
        case .pump: updatePump(dt)
        case .memoryDuel: updateMemDuel(dt)
        case .gallop: updateGallop(dt)
        case .numbers: updateNumbers(dt)
        default: break
        }
    }

    func renderMP2(_ ctx: CGContext) {
        switch mode {
        case .tictactoe: renderTTT(ctx)
        case .connect4: renderC4(ctx)
        case .boxing: renderBoxing(ctx)
        case .cannon: renderCannon(ctx)
        case .pump: renderPump(ctx)
        case .memoryDuel: renderMemDuel(ctx)
        case .gallop: renderGallop(ctx)
        case .numbers: renderNumbers(ctx)
        default: break
        }
    }

    private func turnBanner(_ turn: Int, _ ctx: CGContext) {
        let label = turn == 0 ? "🔴 \(p1Name)'s turn" : (twoPlayer ? "🔵 Player 2's turn" : "\(rival.emoji) \(rival.name) is thinking…")
        text(label, at: CGPoint(x: splitX, y: World.H - 8.5), size: 6, color: turn == 0 ? hex(0xFFB0B0) : hex(0xB0D0FF), ctx: ctx, center: true, bold: true)
    }

    // MARK: - ⭕ Tic-Tac-Toe

    private var tttX0: CGFloat { 44 }
    private var tttCell: CGFloat { (playMaxX - tttX0 - 24) / 9 }
    private func tttX(_ i: Int) -> CGFloat { tttX0 + tttCell * (CGFloat(i) + 0.5) + CGFloat(i / 3) * 12 }

    func tttWinner(_ b: [Int]) -> (Int, [Int])? {
        for l in TTTState.lines where b[l[0]] >= 0 && b[l[0]] == b[l[1]] && b[l[1]] == b[l[2]] { return (b[l[0]], l) }
        return nil
    }

    private func tttPlace(_ player: Int, at x: CGFloat) {
        guard ttt.resultT <= 0, let i = (0..<9).min(by: { abs(tttX($0) - x) < abs(tttX($1) - x) }), abs(tttX(i) - x) < tttCell * 0.6 else { return }
        tttMove(player, i)
    }

    private func tttMove(_ player: Int, _ i: Int) {
        guard ttt.board[i] < 0, player == ttt.turn else { return }
        ttt.board[i] = player
        Sound.play("Tink", volume: 0.25)
        if let (w, line) = tttWinner(ttt.board) {
            ttt.winLine = line
            mpPoint(w, "Three in a row!")
            ttt.resultT = 1.6
            Sound.play("Glass", volume: 0.3)
        } else if !ttt.board.contains(-1) {
            addText("Draw!", x: splitX, y: 20, color: .white)
            ttt.resultT = 1.4
        } else {
            ttt.turn = 1 - ttt.turn
            ttt.cpuT = Double.random(in: 0.5...1.0)
        }
    }

    /// Perfect-play score for `player` to move (minimax over the tiny 3×3 tree).
    private func tttMinimax(_ b: [Int], _ player: Int, _ me: Int) -> Int {
        if let (w, _) = tttWinner(b) { return w == me ? 1 : -1 }
        if !b.contains(-1) { return 0 }
        var best = player == me ? -2 : 2
        for i in 0..<9 where b[i] < 0 {
            var nb = b; nb[i] = player
            let s = tttMinimax(nb, 1 - player, me)
            best = player == me ? max(best, s) : min(best, s)
        }
        return best
    }

    private func updateTTT(_ dt: Double) {
        if ttt.resultT > 0 {
            ttt.resultT -= dt
            if ttt.resultT <= 0 {
                if p1 >= 3 || p2 >= 3 { mpFinish(); return }
                let starter = 1 - ttt.starter
                ttt = TTTState()
                ttt.starter = starter
                ttt.turn = starter
            }
            return
        }
        if !twoPlayer && ttt.turn == 1 {
            ttt.cpuT -= dt
            if ttt.cpuT <= 0 {
                let free = (0..<9).filter { ttt.board[$0] < 0 }
                var pick = free.randomElement()!
                if Double.random(in: 0..<1) < 0.75 {
                    pick = free.max { a, b in
                        var ba = ttt.board; ba[a] = 1
                        var bb = ttt.board; bb[b] = 1
                        return tttMinimax(ba, 0, 1) < tttMinimax(bb, 0, 1)
                    }!
                }
                tttMove(1, pick)
            }
        }
    }

    private func renderTTT(_ ctx: CGContext) {
        // Reference 3×3 board
        let s: CGFloat = 6
        for i in 0..<9 {
            let r = CGRect(x: 8 + CGFloat(i % 3) * s, y: 20 - CGFloat(i / 3 + 1) * s, width: s - 0.6, height: s - 0.6)
            ctx.setFillColor(NSColor(white: 1, alpha: ttt.winLine?.contains(i) == true ? 0.45 : 0.15).cgColor)
            ctx.fill(r)
            if ttt.board[i] >= 0 {
                text(ttt.board[i] == 0 ? "✕" : "◯", at: CGPoint(x: r.midX, y: r.minY + 0.6), size: 4.2, color: ttt.board[i] == 0 ? hex(0xFF8A8A) : hex(0x8AB8FF), ctx: ctx, center: true, bold: true)
            }
        }
        // Touch row: the three board rows laid side by side
        for i in 0..<9 {
            let x = tttX(i)
            let r = CGRect(x: x - tttCell / 2 + 1.5, y: 3, width: tttCell - 3, height: 16)
            ctx.addPath(CGPath(roundedRect: r, cornerWidth: 3, cornerHeight: 3, transform: nil))
            ctx.setFillColor(NSColor(white: 1, alpha: ttt.winLine?.contains(i) == true ? 0.4 : 0.12).cgColor)
            ctx.fillPath()
            if ttt.board[i] >= 0 {
                text(ttt.board[i] == 0 ? "✕" : "◯", at: CGPoint(x: x, y: 5.5), size: 11, color: ttt.board[i] == 0 ? hex(0xFF6B6B) : hex(0x6BA8FF), ctx: ctx, center: true, bold: true)
            }
        }
        for (k, label) in ["top row", "middle row", "bottom row"].enumerated() {
            text(label, at: CGPoint(x: tttX(k * 3 + 1), y: 0.6), size: 4, color: NSColor(white: 1, alpha: 0.5), ctx: ctx, center: true)
        }
        if phase == .playing && ttt.resultT <= 0 { turnBanner(ttt.turn, ctx) }
    }

    // MARK: - 🔴 Four in a Row

    private var c4ColW: CGFloat { 30 }
    private var c4X0: CGFloat { splitX - c4ColW * 3.5 }
    private func c4RowY(_ row: Int) -> CGFloat { 5.5 + CGFloat(row) * 3.9 }

    func c4Wins(_ b: [[Int]], _ col: Int, _ row: Int) -> [(Int, Int)]? {
        let who = b[col][row]
        guard who >= 0 else { return nil }
        for (dc, dr) in [(1, 0), (0, 1), (1, 1), (1, -1)] {
            var cells = [(col, row)]
            for sign in [1, -1] {
                var c = col + dc * sign, r = row + dr * sign
                while c >= 0 && c < C4State.cols && r >= 0 && r < C4State.rows && b[c][r] == who { cells.append((c, r)); c += dc * sign; r += dr * sign }
            }
            if cells.count >= 4 { return cells }
        }
        return nil
    }

    private func c4Drop(_ player: Int, at x: CGFloat) {
        let col = Int(floor((x - c4X0) / c4ColW))
        guard (0..<C4State.cols).contains(col) else { return }
        c4Play(player, col)
    }

    func c4Play(_ player: Int, _ col: Int) {
        guard c4.resultT <= 0, c4.dropping == nil, player == c4.turn, let row = c4.board[col].firstIndex(of: -1) else { return }
        c4.dropping = (col, row, World.H)
        Sound.play("Pop", volume: 0.2)
    }

    private func c4CPUMove() -> Int {
        let open = (0..<C4State.cols).filter { c4.board[$0].contains(-1) }
        func wins(_ who: Int, _ col: Int, in b: [[Int]]) -> Bool {
            guard let row = b[col].firstIndex(of: -1) else { return false }
            var nb = b; nb[col][row] = who
            return c4Wins(nb, col, row) != nil
        }
        if let c = open.first(where: { wins(1, $0, in: c4.board) }) { return c }
        if let c = open.first(where: { wins(0, $0, in: c4.board) }) { return c }
        let safe = open.filter { col in
            var nb = c4.board
            guard let row = nb[col].firstIndex(of: -1) else { return false }
            nb[col][row] = 1
            return !(0..<C4State.cols).contains { wins(0, $0, in: nb) }
        }
        let pool = safe.isEmpty ? open : safe
        return pool.max { a, b in Double(3 - abs(a - 3)) + Double.random(in: 0...1.5) < Double(3 - abs(b - 3)) + Double.random(in: 0...1.5) }!
    }

    private func updateC4(_ dt: Double) {
        if var d = c4.dropping {
            d.y -= 90 * CGFloat(dt)
            if d.y <= c4RowY(d.row) {
                c4.board[d.col][d.row] = c4.turn
                c4.dropping = nil
                if let cells = c4Wins(c4.board, d.col, d.row) {
                    c4.winCells = cells
                    mpPoint(c4.turn, "Four in a row!")
                    c4.resultT = 1.8
                    Sound.play("Glass", volume: 0.3)
                } else if !c4.board.contains(where: { $0.contains(-1) }) {
                    addText("Board full — draw", x: splitX, y: 20, color: .white)
                    c4.resultT = 1.5
                } else {
                    c4.turn = 1 - c4.turn
                    c4.cpuT = Double.random(in: 0.5...1.0)
                }
            } else { c4.dropping = d }
            return
        }
        if c4.resultT > 0 {
            c4.resultT -= dt
            if c4.resultT <= 0 {
                if p1 >= 2 || p2 >= 2 { mpFinish(); return }
                let starter = 1 - c4.starter
                c4 = C4State()
                c4.starter = starter
                c4.turn = starter
            }
            return
        }
        if !twoPlayer && c4.turn == 1 {
            c4.cpuT -= dt
            if c4.cpuT <= 0 { c4Play(1, c4CPUMove()) }
        }
    }

    private func renderC4(_ ctx: CGContext) {
        let w = c4ColW * CGFloat(C4State.cols)
        ctx.addPath(CGPath(roundedRect: CGRect(x: c4X0 - 2, y: 3, width: w + 4, height: 25), cornerWidth: 2, cornerHeight: 2, transform: nil))
        ctx.setFillColor(hex(0x2E5FB0).cgColor)
        ctx.fillPath()
        func disc(_ col: Int, _ y: CGFloat, _ who: Int, highlight: Bool) {
            let x = c4X0 + c4ColW * (CGFloat(col) + 0.5)
            let r = CGRect(x: x - 11, y: y - 1.6, width: 22, height: 3.2)
            ctx.setFillColor((who < 0 ? hex(0x10203A) : who == 0 ? hex(0xE84A5F) : hex(0xFFD23F)).cgColor)
            ctx.fillEllipse(in: r)
            if highlight {
                ctx.setStrokeColor(NSColor.white.cgColor)
                ctx.setLineWidth(0.5)
                ctx.strokeEllipse(in: r)
            }
        }
        for c in 0..<C4State.cols {
            for r in 0..<C4State.rows {
                disc(c, c4RowY(r), c4.board[c][r], highlight: c4.winCells.contains { $0 == (c, r) })
            }
        }
        if let d = c4.dropping { disc(d.col, d.y, c4.turn, highlight: false) }
        if phase == .playing && c4.resultT <= 0 { turnBanner(c4.turn, ctx) }
        if phase == .playing && c4.board.allSatisfy({ $0.allSatisfy { $0 < 0 } }) {
            text("tap a column to drop a disc", at: CGPoint(x: c4X0 - 50, y: 12), size: 5, color: NSColor(white: 1, alpha: 0.55), ctx: ctx, center: true)
        }
    }

    // MARK: - 🥊 Boxing

    private var boxerX: [CGFloat] { [splitX - 20, splitX + 20] }

    private func boxingJab(_ player: Int) {
        guard boxing.cooldown[player] <= 0, boxing.stun[player] <= 0, boxing.punchT[player] <= 0 else { return }
        boxing.punchT[player] = 0.3
        boxing.landed[player] = false
        boxing.cooldown[player] = 0.45
        if player == 0 { boxing.cpuSawPunch = false }
    }

    private func updateBoxing(_ dt: Double) {
        for i in 0..<2 {
            boxing.cooldown[i] -= dt
            boxing.stun[i] -= dt
            boxing.hitFlash[i] -= dt
            if let start = boxing.pressAt[i], t - start >= 0.18, boxing.stun[i] <= 0 { boxing.blocking[i] = true }
            if boxing.stun[i] > 0 { boxing.blocking[i] = false }
            guard boxing.punchT[i] > 0 else { continue }
            let before = boxing.punchT[i]
            boxing.punchT[i] -= dt
            if before > 0.1 && boxing.punchT[i] <= 0.1 && !boxing.landed[i] {   // moment of impact
                boxing.landed[i] = true
                let o = 1 - i
                if boxing.blocking[o] {
                    boxing.stun[i] = 0.5
                    addText("Blocked!", x: boxerX[o], y: 22, color: .white)
                    Sound.play("Pop", volume: 0.2)
                } else {
                    boxing.stun[o] = 0.35
                    boxing.hitFlash[o] = 0.25
                    mpPoint(i, "POW!")
                    Sound.play("Funk", volume: 0.3)
                    if p1 >= 7 || p2 >= 7 { mpFinish(); return }
                }
            }
        }
        guard !twoPlayer else { return }
        // Computer boxer: jabs on a rhythm, sometimes reads your jab and blocks.
        if boxing.punchT[0] > 0.2 && !boxing.cpuSawPunch {
            boxing.cpuSawPunch = true
            if Double.random(in: 0..<1) < 0.45 { boxing.cpuBlockUntil = t + 0.45 }
        }
        boxing.blocking[1] = boxing.stun[1] <= 0 && t < boxing.cpuBlockUntil
        boxing.cpuNext -= dt
        if boxing.cpuNext <= 0 {
            boxing.cpuNext = Double.random(in: 0.7...1.5)
            if !boxing.blocking[1] { boxingJab(1) }
        }
    }

    private func renderBoxing(_ ctx: CGContext) {
        ctx.setStrokeColor(hex(0xE84A5F, 0.5).cgColor)
        ctx.setLineWidth(0.5)
        for y: CGFloat in [10, 15, 20] {
            ctx.move(to: CGPoint(x: splitX - 70, y: y)); ctx.addLine(to: CGPoint(x: splitX + 70, y: y)); ctx.strokePath()
        }
        for i in 0..<2 {
            let x = boxerX[i]
            let facing: CGFloat = i == 0 ? 1 : -1
            if boxing.hitFlash[i] <= 0 || Int(t * 20) % 2 == 0 {
                drawCreature(ctx, avatar2(i), x: x, y: 0, scale: 1.3, facing: facing, frame: 0)
            }
            let extend = boxing.punchT[i] > 0 ? CGFloat(max(0, 0.3 - boxing.punchT[i]) / 0.2) : 0
            ctx.setFillColor((i == 0 ? hex(0xE84A5F) : hex(0x3A6EE8)).cgColor)
            if boxing.blocking[i] {
                for dy: CGFloat in [10, 14] { ctx.fillEllipse(in: CGRect(x: x + facing * 9 - 2.2, y: World.ground + dy, width: 4.4, height: 4.4)) }
            } else {
                ctx.fillEllipse(in: CGRect(x: x + facing * (7 + min(extend, 1) * 9) - 2.2, y: World.ground + 11, width: 4.4, height: 4.4))
                ctx.fillEllipse(in: CGRect(x: x + facing * 4 - 2, y: World.ground + 8, width: 4, height: 4))
            }
            if boxing.stun[i] > 0 { text("💫", at: CGPoint(x: x, y: 23), size: 6, color: .white, ctx: ctx, center: true) }
        }
        if phase == .playing && p1 + p2 == 0 {
            text("tap = jab · hold = block", at: CGPoint(x: splitX, y: 1), size: 5, color: NSColor(white: 1, alpha: 0.55), ctx: ctx, center: true)
        }
    }

    private func avatar2(_ player: Int) -> Species { player == 0 ? species : rival }

    // MARK: - 💥 Cannon Duel

    private var castleX: [CGFloat] { [24, World.W - 40] }
    private var cannonPower: CGFloat {
        let f = cannon.chargeT.truncatingRemainder(dividingBy: 1.4) / 1.4
        return CGFloat(f < 0.5 ? f * 2 : 2 - f * 2)
    }

    /// Launch velocity for a given power; the angle flattens with distance so the arc stays on screen.
    func cannonLaunch(_ shooter: Int, power: CGFloat) -> (CGPoint, CGFloat, CGFloat) {
        let from = CGPoint(x: castleX[shooter] + (shooter == 0 ? 7 : -7), y: 15)
        let dist = abs(castleX[1] - castleX[0])
        let a = atan(55 / dist)
        let v = 120 + power * 560
        return (from, (shooter == 0 ? 1 : -1) * v * cos(a), v * sin(a))
    }

    private func fireCannon() {
        cannon.charging = false
        let (from, vx, vy) = cannonLaunch(cannon.turn, power: twoPlayer || cannon.turn == 0 ? cannonPower : cannon.cpuPower)
        cannon.shot = Item(kind: .ball, x: from.x, y: from.y, vx: vx, vy: vy)
        cannon.shooter = cannon.turn
        cannon.path = []
        Sound.play("Blow", volume: 0.25)
    }

    private func updateCannon(_ dt: Double) {
        let fdt = CGFloat(dt)
        if cannon.charging { cannon.chargeT += dt }
        if cannon.wait > 0 {
            cannon.wait -= dt
            if cannon.wait <= 0 && !twoPlayer && cannon.turn == 1 {
                // The computer aims by trial and error, with a bit of wobble.
                var lo: CGFloat = 0, hi: CGFloat = 1
                for _ in 0..<24 {
                    let mid = (lo + hi) / 2
                    let (from, vx0, vy0) = cannonLaunch(1, power: mid)
                    var x = from.x, y = from.y, vx = vx0, vy = vy0
                    while y > 2 { vx += cannon.wind * 0.016; vy -= 120 * 0.016; x += vx * 0.016; y += vy * 0.016 }
                    if x > castleX[0] { lo = mid } else { hi = mid }
                }
                cannon.cpuPower = min(1, max(0, lo + CGFloat.random(in: -0.07...0.07)))
                fireCannon()
            }
            return
        }
        guard var s = cannon.shot else { return }
        s.vx += cannon.wind * fdt
        s.vy -= 120 * fdt
        s.x += s.vx * fdt
        s.y += s.vy * fdt
        cannon.path.append(CGPoint(x: s.x, y: s.y))
        let target = 1 - cannon.shooter
        if abs(s.x - castleX[target]) < 9 && s.y < World.ground + 13 {
            cannon.hp[target] -= 1
            cannon.shot = nil
            mpPoint(cannon.shooter, "Direct hit!")
            burst(.spark(hex(0xFFB347)), at: castleX[target], 12, count: 14)
            flash = 0.2
            Sound.play("Basso", volume: 0.35)
            endCannonTurn()
            if cannon.hp[target] <= 0 { mpFinish() }
            return
        }
        if s.y < World.ground || s.x < 0 || s.x > World.W {
            cannon.shot = nil
            burst(.spark(hex(0x8A8F99)), at: s.x, World.ground, count: 5)
            addText("Miss", x: min(max(s.x, 30), World.W - 40), y: 10, color: NSColor(white: 1, alpha: 0.7))
            endCannonTurn()
            return
        }
        cannon.shot = s
    }

    private func endCannonTurn() {
        cannon.lastPath[cannon.shooter] = cannon.path
        cannon.turn = 1 - cannon.turn
        cannon.wind = CGFloat.random(in: -20...20)
        cannon.wait = 1.0
    }

    private func renderCannon(_ ctx: CGContext) {
        for i in 0..<2 {
            let x = castleX[i]
            ctx.setFillColor((i == 0 ? hex(0x8A5A5A) : hex(0x5A6A8A)).cgColor)
            ctx.fill(CGRect(x: x - 7, y: World.ground, width: 14, height: 10))
            for k in 0..<3 { ctx.fill(CGRect(x: x - 7 + CGFloat(k) * 5.5, y: World.ground + 10, width: 3, height: 2)) }
            ctx.setStrokeColor(hex(0x2A2A33).cgColor)
            ctx.setLineWidth(1.6)
            ctx.move(to: CGPoint(x: x, y: 14)); ctx.addLine(to: CGPoint(x: x + (i == 0 ? 6 : -6), y: 16)); ctx.strokePath()
            text(String(repeating: "♥︎", count: max(0, cannon.hp[i])), at: CGPoint(x: x, y: 17.5), size: 5, color: i == 0 ? hex(0xFF8A8A) : hex(0x8AB8FF), ctx: ctx, center: true)
            ctx.setFillColor(NSColor(white: 1, alpha: 0.18).cgColor)
            for p in cannon.lastPath[i] where Int(p.x) % 4 == 0 { ctx.fill(CGRect(x: p.x, y: p.y, width: 0.5, height: 0.5)) }
        }
        if let s = cannon.shot {
            ctx.setFillColor(hex(0x1A1A1A).cgColor)
            ctx.fillEllipse(in: CGRect(x: s.x - 1.3, y: s.y - 1.3, width: 2.6, height: 2.6))
        }
        let w = cannon.wind
        text(abs(w) < 3 ? "Wind: calm" : String(format: "Wind %@ %.0f", w > 0 ? "→" : "←", abs(w)), at: CGPoint(x: splitX, y: 2), size: 5, color: NSColor(white: 1, alpha: 0.7), ctx: ctx, center: true)
        if cannon.charging {
            let p = cannonPower
            let bx = castleX[cannon.turn] + (cannon.turn == 0 ? 12 : -32)
            ctx.setFillColor(NSColor(white: 1, alpha: 0.2).cgColor)
            ctx.fill(CGRect(x: bx, y: 6, width: 20, height: 2))
            ctx.setFillColor(NSColor(calibratedHue: 0.33 * (1 - p), saturation: 0.8, brightness: 0.95, alpha: 1).cgColor)
            ctx.fill(CGRect(x: bx, y: 6, width: 20 * p, height: 2))
        }
        if phase == .playing && cannon.shot == nil {
            turnBanner(cannon.turn, ctx)
            if turnPlayer(cannon.turn) != nil && !cannon.charging && cannon.wait <= 0 {
                text("hold for power, release to fire", at: CGPoint(x: splitX, y: 8), size: 5, color: NSColor(white: 1, alpha: 0.55), ctx: ctx, center: true)
            }
        }
    }

    // MARK: - 🎈 Pump It

    private var pumpX: [CGFloat] { [splitX / 2, splitX * 1.5] }

    private func newPumpRound() {
        pump.size = [0, 0]
        pump.popped = [false, false]
        let limit = CGFloat.random(in: 0.62...0.98)
        pump.limit = [limit, limit]       // same hidden limit for both, so it's fair
        pump.timer = 8
        pump.countdown = 2
        pump.cpuTarget = CGFloat.random(in: 0.5...0.85)
    }

    private func pumpTap(_ player: Int) {
        guard pump.countdown <= 0, pump.timer > 0, pump.resultT <= 0, !pump.popped[player] else { return }
        pump.size[player] += 0.035
        Sound.play("Blow", volume: 0.08)
        if pump.size[player] > pump.limit[player] {
            pump.popped[player] = true
            burst(.spark(player == 0 ? hex(0xE84A5F) : hex(0x3A6EE8)), at: pumpX[player], 18, count: 14)
            addText("POP!", x: pumpX[player], y: 20, color: .white)
            Sound.play("Basso", volume: 0.3)
        }
    }

    private func updatePump(_ dt: Double) {
        if pump.resultT > 0 {
            pump.resultT -= dt
            if pump.resultT <= 0 {
                if p1 >= 3 || p2 >= 3 { mpFinish(); return }
                newPumpRound()
            }
            return
        }
        if pump.countdown > 0 {
            let before = Int(ceil(pump.countdown))
            pump.countdown -= dt
            if Int(ceil(max(pump.countdown, 0))) != before { Sound.play(pump.countdown > 0 ? "Tink" : "Glass", volume: 0.3) }
            return
        }
        pump.timer -= dt
        if !twoPlayer && !pump.popped[1] && pump.size[1] < pump.cpuTarget {
            pump.cpuT -= dt
            if pump.cpuT <= 0 { pumpTap(1); pump.cpuT = 1 / 6.5 }
        }
        if pump.timer <= 0 || pump.popped.allSatisfy({ $0 }) {
            let a = pump.popped[0] ? -1 : pump.size[0], b = pump.popped[1] ? -1 : pump.size[1]
            if a > b { mpPoint(0, "Biggest balloon!") } else if b > a { mpPoint(1, "Biggest balloon!") } else { addText("Tie", x: splitX, y: 20, color: .white) }
            addText(String(format: "it popped at %.0f%%", pump.limit[0] * 100), x: splitX, y: 13, color: NSColor(white: 1, alpha: 0.7))
            pump.resultT = 2
        }
    }

    private func renderPump(_ ctx: CGContext) {
        for i in 0..<2 {
            let x = pumpX[i]
            drawCreature(ctx, avatar2(i), x: x - 24, y: 0, scale: 1.0, facing: 1, frame: 0)
            ctx.setFillColor(hex(0x55596A).cgColor)
            ctx.fill(CGRect(x: x - 14, y: World.ground, width: 3, height: 8))
            ctx.setStrokeColor(NSColor(white: 1, alpha: 0.5).cgColor)
            ctx.setLineWidth(0.4)
            ctx.move(to: CGPoint(x: x - 12.5, y: World.ground + 7)); ctx.addLine(to: CGPoint(x: x, y: 8)); ctx.strokePath()
            if !pump.popped[i] {
                let r = 2 + pump.size[i] * 10
                ctx.setFillColor((i == 0 ? hex(0xE84A5F) : hex(0x3A6EE8)).cgColor)
                ctx.fillEllipse(in: CGRect(x: x - r, y: 8 + 0.5, width: r * 2, height: r * 2.1))
                ctx.setFillColor(NSColor(white: 1, alpha: 0.35).cgColor)
                ctx.fillEllipse(in: CGRect(x: x - r * 0.5, y: 8 + r * 1.3, width: r * 0.4, height: r * 0.4))
            } else {
                text("💥", at: CGPoint(x: x, y: 12), size: 9, color: .white, ctx: ctx, center: true)
            }
            text(String(format: "%.0f%%", min(pump.size[i], 1) * 100), at: CGPoint(x: x + 22, y: 6), size: 6, color: .white, ctx: ctx, center: true, bold: true)
        }
        if phase == .playing {
            if pump.countdown > 0 { text("\(Int(ceil(pump.countdown)))", at: CGPoint(x: splitX, y: 8), size: 14, color: .white, ctx: ctx, center: true, bold: true) }
            else if pump.timer > 0 && pump.resultT <= 0 { text(String(format: "%.1f", pump.timer), at: CGPoint(x: splitX, y: 10), size: 8, color: hex(0xFFD23F), ctx: ctx, center: true, bold: true) }
            else if pump.resultT > 0 { text("STOP!", at: CGPoint(x: splitX, y: 20), size: 7, color: hex(0xFFD23F), ctx: ctx, center: true, bold: true) }
        }
    }

    // MARK: - 🧠 Memory Duel

    private func memPadX(_ player: Int, _ k: Int) -> CGFloat {
        let lo = player == 0 ? 0 : splitX, w = player == 0 ? splitX : World.W - 22 - splitX
        return lo + w * (CGFloat(k) + 0.5) / 4
    }

    private func memDuelTap(_ player: Int, x: CGFloat) {
        guard !memDuel.showing, memDuel.resultT <= 0, !memDuel.done[player], !memDuel.failed[player],
              let k = (0..<4).min(by: { abs(memPadX(player, $0) - x) < abs(memPadX(player, $1) - x) }) else { return }
        memDuelInput(player, k)
    }

    func memDuelInput(_ player: Int, _ k: Int) {
        memDuel.playerLit[player] = k
        memDuel.playerLitT[player] = 0.25
        Sound.play(MemoryState.sounds[k], volume: 0.25)
        if memDuel.sequence[memDuel.progress[player]] == k {
            memDuel.progress[player] += 1
            if memDuel.progress[player] == memDuel.sequence.count { memDuel.done[player] = true }
        } else {
            memDuel.failed[player] = true
            Sound.play("Funk", volume: 0.25)
        }
    }

    private func updateMemDuel(_ dt: Double) {
        memDuel.litT -= dt
        if memDuel.litT <= 0 { memDuel.lit = nil }
        for i in 0..<2 { memDuel.playerLitT[i] -= dt; if memDuel.playerLitT[i] <= 0 { memDuel.playerLit[i] = nil } }
        if memDuel.resultT > 0 {
            memDuel.resultT -= dt
            if memDuel.resultT <= 0 {
                if memDuel.failed.contains(true) && memDuel.failed != [true, true] { mpFinish(); return }
                memDuel.sequence.append(Int.random(in: 0..<4))
                if memDuel.failed == [true, true] { memDuel.sequence = (0..<max(1, memDuel.sequence.count - 1)).map { _ in Int.random(in: 0..<4) } }
                memDuel.showing = true
                memDuel.showIndex = 0
                memDuel.timer = 1.0
                memDuel.progress = [0, 0]
                memDuel.failed = [false, false]
                memDuel.done = [false, false]
            }
            return
        }
        if memDuel.showing {
            memDuel.timer -= dt
            guard memDuel.timer <= 0 else { return }
            if memDuel.showIndex < memDuel.sequence.count {
                let dur = max(0.25, 0.5 - 0.02 * Double(memDuel.sequence.count))
                let k = memDuel.sequence[memDuel.showIndex]
                memDuel.lit = k
                memDuel.litT = dur
                Sound.play(MemoryState.sounds[k], volume: 0.3)
                memDuel.showIndex += 1
                memDuel.timer = dur + 0.15
            } else {
                memDuel.showing = false
                memDuel.cpuT = 0.6
            }
            return
        }
        if !twoPlayer && !memDuel.done[1] && !memDuel.failed[1] {
            memDuel.cpuT -= dt
            if memDuel.cpuT <= 0 {
                memDuel.cpuT = Double.random(in: 0.3...0.5)
                let right = memDuel.sequence[memDuel.progress[1]]
                let ok = Double.random(in: 0..<1) < max(0.6, 0.985 - 0.025 * Double(memDuel.sequence.count))
                memDuelInput(1, ok ? right : (right + 1) % 4)
            }
        }
        let resolved = (0..<2).allSatisfy { memDuel.done[$0] || memDuel.failed[$0] }
        if resolved {
            for i in 0..<2 where memDuel.done[i] { mpPoint(i, "✓ \(memDuel.sequence.count)") }
            if memDuel.failed == [true, true] {
                // Both slipped: whoever got further takes it; a tie replays.
                if memDuel.progress[0] != memDuel.progress[1] {
                    let w = memDuel.progress[0] > memDuel.progress[1] ? 0 : 1
                    mpPoint(w, "Got further!")
                    memDuel.failed[w] = false
                } else { addText("Both slipped — again!", x: splitX, y: 20, color: .white) }
            }
            memDuel.resultT = 1.3
        }
    }

    private func renderMemDuel(_ ctx: CGContext) {
        for player in 0..<2 {
            for k in 0..<4 {
                let x = memPadX(player, k)
                let lit = memDuel.lit == k || memDuel.playerLit[player] == k
                let c = hex(MemoryState.colors[k])
                ctx.addPath(CGPath(roundedRect: CGRect(x: x - 14, y: 4, width: 28, height: 14), cornerWidth: 3, cornerHeight: 3, transform: nil))
                ctx.setFillColor(c.withAlphaComponent(lit ? 1 : 0.3).cgColor)
                ctx.fillPath()
                text(MemoryState.symbols[k], at: CGPoint(x: x, y: 7), size: 8, color: NSColor(white: 1, alpha: lit ? 1 : 0.5), ctx: ctx, center: true, bold: true)
            }
            let status = memDuel.failed[player] ? "✗ out" : memDuel.done[player] ? "✓ done" : memDuel.showing ? "" : "\(memDuel.progress[player])/\(memDuel.sequence.count)"
            text(status, at: CGPoint(x: player == 0 ? splitX / 2 : splitX * 1.5, y: 19), size: 6, color: memDuel.failed[player] ? hex(0xFF9AA8) : hex(0x7BE07B), ctx: ctx, center: true, bold: true)
        }
        if phase == .playing {
            text(memDuel.showing ? "Watch… (\(memDuel.sequence.count))" : "Repeat it!", at: CGPoint(x: splitX, y: 19), size: 6, color: hex(0xFFD23F), ctx: ctx, center: true, bold: true)
        }
    }

    // MARK: - 🐎 Gallop Race

    private var gallopLane: [CGFloat] { [3, 15.5] }

    private func gallopTap(_ player: Int) {
        guard gallop.countdown <= 0, gallop.d[player] < GallopState.length else { return }
        let phase = gallop.song / gallop.beat
        let nearest = (phase).rounded()
        let err = abs(phase - nearest) * gallop.beat
        let beatIndex = Int(nearest)
        if beatIndex == gallop.lastBeat[player] || err > 0.15 {
            gallop.stumble[player] = 0.5
            gallop.v[player] *= 0.55
            gallop.feedback[player] = "Off beat!"
        } else {
            gallop.v[player] = min(gallop.v[player] + (err < 0.08 ? 30 : 14), 190)
            gallop.feedback[player] = err < 0.08 ? "Perfect" : "Good"
        }
        gallop.lastBeat[player] = beatIndex
        gallop.fbT[player] = 0.4
    }

    private func updateGallop(_ dt: Double) {
        let fdt = CGFloat(dt)
        if gallop.countdown > 0 {
            let before = Int(ceil(gallop.countdown))
            gallop.countdown -= dt
            if Int(ceil(max(gallop.countdown, 0))) != before { Sound.play(gallop.countdown > 0 ? "Tink" : "Glass", volume: 0.35) }
            return
        }
        let before = Int(floor(gallop.song / gallop.beat))
        gallop.song += dt
        if Int(floor(gallop.song / gallop.beat)) != before { Sound.play("Morse", volume: 0.12) }
        for i in 0..<2 {
            gallop.stumble[i] -= dt
            gallop.fbT[i] -= dt
            gallop.v[i] = max(25, gallop.v[i] - 32 * fdt)
            gallop.d[i] += gallop.v[i] * fdt
            gallop.walk[i] += Double(gallop.v[i]) * dt / 20
        }
        if !twoPlayer {
            // The rival taps near each beat with a little human-like wobble, and skips now and then.
            if gallop.song >= gallop.cpuNext {
                if Double.random(in: 0..<1) > 0.08 { gallopTap(1) }
                let nextBeat = (floor(gallop.song / gallop.beat) + 1) * gallop.beat
                gallop.cpuNext = nextBeat + Double.random(in: -0.09...0.09)
            }
        }
        if gallop.d.contains(where: { $0 >= GallopState.length }) {
            mpPoint(gallop.d[0] >= gallop.d[1] ? 0 : 1)
            mpFinish()
        }
    }

    private func renderGallop(_ ctx: CGContext) {
        let x0: CGFloat = 80
        for i in 0..<2 {
            let base = gallopLane[i]
            ctx.setFillColor((i == 0 ? hex(0xE84A5F, 0.2) : hex(0x5FA8E8, 0.2)).cgColor)
            ctx.fill(CGRect(x: 0, y: base - 0.5, width: World.W - 22, height: 0.8))
            let progress = gallop.d[i] / GallopState.length
            let x = x0 + (World.W - 22 - x0 - 40) * min(progress, 1)
            let bounce = gallop.stumble[i] > 0 ? 0 : CGFloat(abs(sin(gallop.walk[i] * .pi))) * 2
            drawCreature(ctx, avatar2(i), x: x, y: base - World.ground + bounce, scale: 0.65, facing: 1, frame: Int(gallop.walk[i] * 2) % 2)
            if gallop.fbT[i] > 0 {
                text(gallop.feedback[i], at: CGPoint(x: x + 14, y: base + 4), size: 5, color: gallop.feedback[i] == "Off beat!" ? hex(0xFF9AA8) : hex(0x7BE07B), ctx: ctx)
            }
        }
        let fx = World.W - 22 - 40 + 0
        for row in 0..<13 {
            ctx.setFillColor((row % 2 == 0 ? NSColor.white : NSColor.black).cgColor)
            ctx.fill(CGRect(x: fx + 10, y: CGFloat(row) * 2, width: 1.5, height: 2))
        }
        // Beat light
        let ph = gallop.song / gallop.beat
        let pulse = gallop.countdown > 0 ? 0 : CGFloat(max(0, 1 - (ph - floor(ph)) * 3))
        ctx.setFillColor(hex(0xFFD23F, 0.3 + pulse * 0.7).cgColor)
        ctx.fillEllipse(in: CGRect(x: 24 - 3 - pulse * 2, y: 13 - pulse * 2, width: 6 + pulse * 4, height: 6 + pulse * 4))
        text("♪", at: CGPoint(x: 24, y: 21), size: 6, color: NSColor(white: 1, alpha: 0.7), ctx: ctx, center: true)
        if gallop.countdown > 0 && phase == .playing {
            text("\(Int(ceil(gallop.countdown)))", at: CGPoint(x: splitX, y: 8), size: 14, color: .white, ctx: ctx, center: true, bold: true)
            text("tap on the beat — mashing makes you stumble", at: CGPoint(x: splitX, y: 22), size: 5, color: NSColor(white: 1, alpha: 0.6), ctx: ctx, center: true)
        }
    }

    // MARK: - 🔢 Number Rush

    private func numberX(_ player: Int, _ k: Int) -> CGFloat {
        let lo = player == 0 ? 0 : splitX, w = player == 0 ? splitX : World.W - 22 - splitX
        return lo + w * (CGFloat(k) + 0.5) / 8
    }

    private func numbersTap(_ player: Int, x: CGFloat) {
        guard numbers.countdown <= 0, numbers.resultT <= 0, numbers.frozen[player] <= 0,
              let k = (0..<8).min(by: { abs(numberX(player, $0) - x) < abs(numberX(player, $1) - x) }) else { return }
        numbersPress(player, k)
    }

    func numbersPress(_ player: Int, _ k: Int) {
        if numbers.layout[k] == numbers.next[player] {
            numbers.next[player] += 1
            Sound.play("Tink", volume: 0.15)
            if numbers.next[player] > 8 {
                mpPoint(player, "First to 8!")
                Sound.play("Glass", volume: 0.3)
                numbers.resultT = 1.5
            }
        } else if numbers.layout[k] >= numbers.next[player] {
            numbers.frozen[player] = 1
            numbers.wrong[player] = k
            Sound.play("Funk", volume: 0.25)
        }
    }

    private func updateNumbers(_ dt: Double) {
        for i in 0..<2 { numbers.frozen[i] -= dt }
        if numbers.resultT > 0 {
            numbers.resultT -= dt
            if numbers.resultT <= 0 {
                if p1 >= 3 || p2 >= 3 { mpFinish(); return }
                numbers.layout = Array(1...8).shuffled()
                numbers.next = [1, 1]
                numbers.countdown = 1.2
            }
            return
        }
        if numbers.countdown > 0 { numbers.countdown -= dt; return }
        if !twoPlayer && numbers.frozen[1] <= 0 {
            numbers.cpuT -= dt
            if numbers.cpuT <= 0 {
                numbers.cpuT = Double.random(in: 0.45...0.75)
                let k = numbers.layout.firstIndex(of: numbers.next[1])!
                numbersPress(1, Double.random(in: 0..<1) < 0.05 ? (k + 1) % 8 : k)
            }
        }
    }

    private func renderNumbers(_ ctx: CGContext) {
        for player in 0..<2 {
            for k in 0..<8 {
                let x = numberX(player, k)
                let n = numbers.layout.indices.contains(k) ? numbers.layout[k] : 0
                let done = n < numbers.next[player]
                let bad = numbers.wrong[player] == k && numbers.frozen[player] > 0
                ctx.addPath(CGPath(roundedRect: CGRect(x: x - 15, y: 4, width: 30, height: 16), cornerWidth: 3, cornerHeight: 3, transform: nil))
                ctx.setFillColor((bad ? hex(0xE84A5F, 0.8) : done ? hex(0x6CD47A, 0.5) : NSColor(white: 1, alpha: 0.15)).cgColor)
                ctx.fillPath()
                if numbers.countdown <= 0 {
                    text(done ? "✓" : "\(n)", at: CGPoint(x: x, y: 6.5), size: 10, color: .white, ctx: ctx, center: true, bold: true)
                }
            }
            if numbers.frozen[player] > 0 { text("❄️ frozen", at: CGPoint(x: player == 0 ? splitX / 2 : splitX * 1.5, y: 21), size: 5.5, color: hex(0xBFE6FF), ctx: ctx, center: true) }
        }
        if phase == .playing && numbers.countdown > 0 {
            text("tap 1 → 8 in order on your side", at: CGPoint(x: splitX, y: 21), size: 6, color: hex(0xFFD23F), ctx: ctx, center: true, bold: true)
        }
    }
}
