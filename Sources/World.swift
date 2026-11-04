import AppKit

// MARK: - Persistence

struct SaveData: Codable {
    var speciesID = "dog"
    var names: [String: String] = [:]
    var fullness: Double = 80
    var happiness: Double = 80
    var energy: Double = 90
    var xp: Double = 0
    var stars: Int = 0
    var best: [String: Int] = [:]
    var sleeping = false
    var lastSeen = Date()
    var environmentID: String?      // optional so saves from older versions still decode

    static let key = "TouchbarPet.save.v1"
    /// Off for offscreen previews so they never touch the real save.
    static var persistenceEnabled = true

    static func load() -> SaveData {
        guard persistenceEnabled, let data = UserDefaults.standard.data(forKey: key),
              var s = try? JSONDecoder().decode(SaveData.self, from: data) else { return SaveData() }
        // Catch up on time spent away (capped so the pet never ends up miserable).
        let away = min(max(Date().timeIntervalSince(s.lastSeen), 0), 3 * 86400)
        s.fullness = max(15, s.fullness - away / World.fullnessDrainSeconds * 100)
        s.happiness = max(20, s.happiness - away / World.happinessDrainSeconds * 100)
        s.energy = s.sleeping ? 100 : min(100, s.energy + away / 3600 * 10)
        s.sleeping = false
        return s
    }

    func store() {
        guard SaveData.persistenceEnabled else { return }
        var s = self
        s.lastSeen = Date()
        if let data = try? JSONEncoder().encode(s) { UserDefaults.standard.set(data, forKey: SaveData.key) }
    }
}

// MARK: - Entities

enum Mode: String {
    case pet, runner, catcher, popper, baseball, playCatch, race, fishing, memory, balloon, keepy, whack, slice, archery, rhythm,
         bridge, stack, highway, chef, pairs, math, aliens, hoops, duel, words, pong, bowling,
         tug, hurdles, snap, popBattle, soccer, rps, mathBattle, potato, spaceDuel, pongDuel,
         crossing, claw, fireworks, golf, slots, mines, colors, timing, seek, dragrace, skijump, missiles, tictactoe, connect4, boxing, cannon, pump, memoryDuel, gallop, numbers

    static let singlePlayerGames: [Mode] = [.runner, .catcher, .popper, .baseball, .playCatch, .race, .fishing, .memory,
                                            .balloon, .keepy, .whack, .slice, .archery, .rhythm,
                                            .bridge, .stack, .highway, .chef, .pairs, .math, .aliens, .hoops, .words, .pong, .bowling,
                                            .crossing, .claw, .fireworks, .golf, .slots, .mines, .colors, .timing, .seek, .dragrace, .skijump, .missiles]
    static let games: [Mode] = singlePlayerGames + multiplayerGames

    var title: String {
        switch self {
        case .pet: return "Pet"
        case .runner: return "Hop Runner"
        case .catcher: return "Treat Catch"
        case .popper: return "Bubble Pop"
        case .baseball: return "Home Run Derby"
        case .playCatch: return "Play Catch"
        case .race: return "Run Race"
        case .fishing: return "Fishing"
        case .memory: return "Copy Cat"
        case .balloon: return "Balloon Ride"
        case .keepy: return "Keepy Uppy"
        case .whack: return "Whack-a-Mole"
        case .slice: return "Fruit Slice"
        case .archery: return "Archery"
        case .rhythm: return "Drum Beat"
        case .bridge: return "Bridge Builder"
        case .stack: return "Tower Stack"
        case .highway: return "Highway Dash"
        case .chef: return "Pancake Chef"
        case .pairs: return "Pair Match"
        case .math: return "Math Dash"
        case .aliens: return "Alien Attack"
        case .hoops: return "Hoops"
        case .duel: return "Quick Draw"
        case .words: return "Word Scramble"
        case .pong: return "Ping Pong"
        case .bowling: return "Bowling"
        case .tug: return "Tug of War"
        case .hurdles: return "Hurdle Race"
        case .snap: return "Snap!"
        case .popBattle: return "Pop Battle"
        case .soccer: return "Soccer"
        case .rps: return "Rock Paper Scissors"
        case .mathBattle: return "Math Battle"
        case .potato: return "Hot Potato"
        case .spaceDuel: return "Space Duel"
        case .pongDuel: return "Tennis Duel"
        case .crossing: return "Road Crossing"
        case .claw: return "Claw Machine"
        case .fireworks: return "Fireworks"
        case .golf: return "Mini Golf"
        case .slots: return "Lucky Slots"
        case .mines: return "Mine Row"
        case .colors: return "Color Clash"
        case .timing: return "Perfect Timing"
        case .seek: return "Hide & Seek"
        case .dragrace: return "Drag Race"
        case .skijump: return "Ski Jump"
        case .missiles: return "Missile Defense"
        case .tictactoe: return "Tic-Tac-Toe"
        case .connect4: return "Four in a Row"
        case .boxing: return "Boxing"
        case .cannon: return "Cannon Duel"
        case .pump: return "Pump It"
        case .memoryDuel: return "Memory Duel"
        case .gallop: return "Gallop Race"
        case .numbers: return "Number Rush"
        }
    }
    /// Compact label for the Touch Bar game picker.
    var shortTitle: String {
        switch self {
        case .pet: return "Back to pet"
        case .runner: return "Runner"
        case .catcher: return "Treats"
        case .popper: return "Bubbles"
        case .baseball: return "Batting"
        case .playCatch: return "Catch"
        case .race: return "Race"
        case .fishing: return "Fishing"
        case .memory: return "Memory"
        case .balloon: return "Balloon"
        case .keepy: return "Keepy"
        case .whack: return "Whack"
        case .slice: return "Slice"
        case .archery: return "Archery"
        case .rhythm: return "Drums"
        case .bridge: return "Bridge"
        case .stack: return "Stack"
        case .highway: return "Highway"
        case .chef: return "Chef"
        case .pairs: return "Pairs"
        case .math: return "Math"
        case .aliens: return "Aliens"
        case .hoops: return "Hoops"
        case .duel: return "Duel"
        case .words: return "Words"
        case .pong: return "Pong"
        case .bowling: return "Bowling"
        case .tug: return "Tug"
        case .hurdles: return "Hurdles"
        case .snap: return "Snap"
        case .popBattle: return "Pop War"
        case .soccer: return "Soccer"
        case .rps: return "RPS"
        case .mathBattle: return "Math War"
        case .potato: return "Potato"
        case .spaceDuel: return "Space"
        case .pongDuel: return "Tennis"
        case .crossing: return "Crossing"
        case .claw: return "Claw"
        case .fireworks: return "Fireworks"
        case .golf: return "Golf"
        case .slots: return "Slots"
        case .mines: return "Mines"
        case .colors: return "Colors"
        case .timing: return "Timing"
        case .seek: return "Seek"
        case .dragrace: return "Drag"
        case .skijump: return "Ski"
        case .missiles: return "Defense"
        case .tictactoe: return "TicTacToe"
        case .connect4: return "Four"
        case .boxing: return "Boxing"
        case .cannon: return "Cannon"
        case .pump: return "Pump"
        case .memoryDuel: return "Mem Duel"
        case .gallop: return "Gallop"
        case .numbers: return "Numbers"
        }
    }
    var emoji: String {
        switch self {
        case .pet: return "🏠"
        case .runner: return "🏃"
        case .catcher: return "🧺"
        case .popper: return "🫧"
        case .baseball: return "⚾"
        case .playCatch: return "🧤"
        case .race: return "🏁"
        case .fishing: return "🎣"
        case .memory: return "🧠"
        case .balloon: return "🎈"
        case .keepy: return "⚽"
        case .whack: return "🔨"
        case .slice: return "🍉"
        case .archery: return "🏹"
        case .rhythm: return "🥁"
        case .bridge: return "🌉"
        case .stack: return "🧱"
        case .highway: return "🚗"
        case .chef: return "🍳"
        case .pairs: return "🃏"
        case .math: return "➕"
        case .aliens: return "👾"
        case .hoops: return "🏀"
        case .duel: return "🤠"
        case .words: return "🔤"
        case .pong: return "🏓"
        case .bowling: return "🎳"
        case .tug: return "🪢"
        case .hurdles: return "🚧"
        case .snap: return "🎴"
        case .popBattle: return "💥"
        case .soccer: return "🥅"
        case .rps: return "✊"
        case .mathBattle: return "🧮"
        case .potato: return "💣"
        case .spaceDuel: return "🛸"
        case .pongDuel: return "🎾"
        case .crossing: return "🐸"
        case .claw: return "🧸"
        case .fireworks: return "🎆"
        case .golf: return "⛳"
        case .slots: return "🎰"
        case .mines: return "💣"
        case .colors: return "🎨"
        case .timing: return "⏱"
        case .seek: return "🔦"
        case .dragrace: return "🏎"
        case .skijump: return "⛷️"
        case .missiles: return "🏙"
        case .tictactoe: return "⭕"
        case .connect4: return "🔴"
        case .boxing: return "🥊"
        case .cannon: return "💥"
        case .pump: return "🎈"
        case .memoryDuel: return "🧩"
        case .gallop: return "🐎"
        case .numbers: return "🔢"
        }
    }
    var hint: String {
        switch self {
        case .pet: return ""
        case .runner: return "Tap to jump over cacti"
        case .catcher: return "Slide to catch treats, dodge rocks"
        case .popper: return "Tap bubbles before they float away"
        case .baseball: return "Tap to swing when the pitch reaches the plate"
        case .playCatch: return "Slide the glove to catch, tap where to throw back"
        case .race: return "Tap fast with two fingers, left-right-left"
        case .fishing: return "Tap to cast, tap again the moment a fish bites"
        case .memory: return "Watch your pet hop, then tap the same pads"
        case .balloon: return "Hold to rise, let go to sink — dodge birds, trees and storms"
        case .keepy: return "Tap beside the ball when it's low to kick it back up"
        case .whack: return "Bonk the moles, but never your friend!"
        case .slice: return "Swipe across fruit to slice it — avoid the bombs"
        case .archery: return "Hold to draw the bow, release at the right power"
        case .rhythm: return "Pick a song — red: tap with 1 finger, blue: 2 fingers together"
        case .bridge: return "Hold to stretch the plank, release when it reaches the next ledge"
        case .stack: return "Tap to drop the sliding block right on top"
        case .highway: return "Tap to switch lanes — dodge cars, grab coins"
        case .chef: return "Tap a pan to flip when golden, tap again to serve"
        case .pairs: return "Flip two cards at a time and find every matching pair"
        case .math: return "Tap the right answer — streaks score more"
        case .aliens: return "Slide to move your ship, it fires by itself"
        case .hoops: return "Drag to pull back, release to shoot"
        case .duel: return "Wait for DRAW! then tap — faster than your rival"
        case .words: return "Tap the letters in order to spell the word"
        case .pong: return "Tap when the ball reaches your paddle"
        case .bowling: return "Tap to lock your aim, then tap to lock the power"
        case .tug: return "Tap your side as fast as you can"
        case .hurdles: return "Tap your side to jump your runner's hurdles"
        case .snap: return "Tap when the card matches the one before"
        case .popBattle: return "Pop the bubbles on your side — most pops wins"
        case .soccer: return "Slide your finger to move, run into the ball to kick"
        case .rps: return "Pick a hand before SHOOT! — first to 3"
        case .mathBattle: return "First to tap the right answer scores"
        case .potato: return "Throw the bomb back when you see “!”"
        case .spaceDuel: return "Tap to fire — hit the bobbing ship"
        case .pongDuel: return "Tap as the ball reaches your paddle — first to 5"
        case .crossing: return "Tap to hop across, lane by lane, between the cars"
        case .claw: return "Tap to drop the claw onto a prize"
        case .fireworks: return "Tap rockets right at the top of their climb"
        case .golf: return "Drag to set power, release to putt — 6 holes"
        case .slots: return "Tap to spin, then tap to stop each reel"
        case .mines: return "Tap to reveal, hold to flag — numbers count mines next door"
        case .colors: return "Tap the INK color, not the word"
        case .timing: return "Stop the clock on the target — it hides after 1 second"
        case .seek: return "Slide the flashlight, lift your finger on your pet"
        case .dragrace: return "Tap to shift gears when the needle hits green"
        case .skijump: return "Tap at the edge, hold to glide, let go before landing"
        case .missiles: return "Tap to fire laser beams at incoming missiles"
        case .tictactoe: return "Take turns — three in a row wins, first to 3"
        case .connect4: return "Take turns dropping discs — line up four"
        case .boxing: return "Tap to jab, hold to block — first to 7"
        case .cannon: return "Take turns: hold for power, release to fire"
        case .pump: return "Pump the biggest balloon without popping it"
        case .memoryDuel: return "Both repeat the pattern on your own pads"
        case .gallop: return "Tap on the beat to gallop — mashing stumbles"
        case .numbers: return "Tap 1 to 8 in order on your side, fastest wins"
        }
    }
    var isTimed: Bool { [.catcher, .popper, .fishing, .whack, .chef, .math, .words, .popBattle, .fireworks, .colors, .seek].contains(self) }
    /// Score points per ⭐ earned at the end of a round.
    var pointsPerStar: Int {
        switch self {
        case .runner: return 4
        case .baseball, .memory, .keepy: return 1
        case .archery, .hoops, .bowling: return 5
        case .rhythm, .pairs, .duel: return 10
        case .highway: return 3
        case .tug, .hurdles, .snap, .soccer, .rps, .mathBattle, .potato, .spaceDuel, .pongDuel: return 1
        case .tictactoe, .connect4, .boxing, .cannon, .pump, .memoryDuel, .gallop, .numbers: return 1
        case .timing, .golf: return 20
        case .slots, .skijump: return 10
        case .dragrace: return 8
        default: return 2
        }
    }
}

enum Phase { case ready, playing, over }

struct Item {
    var kind: ItemKind
    var x: CGFloat, y: CGFloat
    var vx: CGFloat = 0, vy: CGFloat = 0
    var scale: CGFloat = 1.5
    var age: Double = 0
    var landed = false
}

struct Particle {
    enum Kind { case item(ItemKind), text(String, NSColor), z, spark(NSColor), half(ItemKind, Bool) }
    var kind: Kind
    var x: CGFloat, y: CGFloat
    var vx: CGFloat = 0, vy: CGFloat = 8
    var life: Double = 1.2
    var maxLife: Double = 1.2
    var size: CGFloat = 1
}

struct Bubble {
    enum Kind { case normal, gold, spiky }
    var kind: Kind
    var x: CGFloat, y: CGFloat, r: CGFloat, vy: CGFloat, phase: CGFloat
}

struct PetBody {
    var x: CGFloat = 200
    var y: CGFloat = 0
    var vy: CGFloat = 0
    var facing: CGFloat = 1
    var targetX: CGFloat?
    var idleTimer: Double = 2
    var eatTimer: Double = 0
    var happyTimer: Double = 0
    var shakeTimer: Double = 0
    var carryingBall = false
    var ballReturnX: CGFloat = 200
    var walkPhase: Double = 0
    var moving = false
    var blinkTimer: Double = 3
    var thoughtTimer: Double = 6
}

// MARK: - World

final class World {
    /// Logical width; follows the Touch Bar scene's real width so the world fills the available space.
    static var W: CGFloat = 640
    static let H: CGFloat = 30
    static let ground: CGFloat = 3
    static let hudWidth: CGFloat = 74
    static let fullnessDrainSeconds: Double = 8 * 3600
    static let happinessDrainSeconds: Double = 10 * 3600
    static let energyDrainSeconds: Double = 6 * 3600
    /// Overrides the clock's day/night (used for previews).
    static var forcedNight: Bool?

    var save = SaveData.load()
    var species: Species { Species.byID(save.speciesID) }
    var petName: String { save.names[save.speciesID] ?? species.defaultName }
    var level: Int { 1 + Int((save.xp / 25).squareRoot()) }

    var pet = PetBody()
    var items: [Item] = []
    var particles: [Particle] = []
    var t: Double = 0

    var mode: Mode = .pet
    var phase: Phase = .ready
    var score = 0
    var timeLeft: Double = 0
    var phaseTimer: Double = 0
    var lastReward = 0

    // game state
    var runSpeed: CGFloat = 0
    var runDistance: CGFloat = 0
    var nextGap: CGFloat = 0
    var sinceLast: CGFloat = 0
    var obstacles: [Item] = []
    var spawnTimer: Double = 0
    var bubbles: [Bubble] = []
    var combo = 0
    var comboTimer: Double = 0
    var touchX: CGFloat?
    var flash: Double = 0
    /// Optional headline for the game-over overlay (otherwise the score is shown).
    var resultText: String?

    // newer games (Games.swift)
    var baseball = BaseballState()
    var playCatch = CatchState()
    var race = RaceState()
    var fishing = FishingState()
    var memory = MemoryState()
    var balloon = BalloonState()
    var keepy = KeepyState()
    var whack = WhackState()
    var slice = SliceState()
    var archery = ArcheryState()
    var rhythm = RhythmState()
    var bridge = BridgeState()
    var stack = StackState()
    var highway = HighwayState()
    var chef = ChefState()
    var pairs = PairsState()
    var math = MathState()
    var aliens = AliensState()
    var hoops = HoopsState()
    var duel = DuelState()
    var words = WordsState()
    var pong = PongState()
    var bowling = BowlingState()

    // multiplayer
    var twoPlayer = false
    var p1 = 0
    var p2 = 0
    var mpRivalID = "cat"
    var touchOwner: [Int: Int] = [:]
    var tug = TugState()
    var hurdles = HurdleState()
    var snap = SnapState()
    var popBattle = PopBattleState()
    var soccer = SoccerState()
    var rps = RPSState()
    var mathBattle = MathBattleState()
    var potato = PotatoState()
    var spaceDuel = SpaceDuelState()
    var pongDuel = PongDuelState()
    var crossing = CrossingState()
    var claw = ClawState()
    var fireworks = FireworksState()
    var golf = GolfState()
    var slots = SlotsState()
    var mines = MinesState()
    var colors = ColorsState()
    var timing = TimingState()
    var seek = SeekState()
    var dragrace = DragRaceState()
    var skijump = SkiState()
    var missiles = MissileState()
    var ttt = TTTState()
    var c4 = C4State()
    var boxing = BoxingState()
    var cannon = CannonState()
    var pump = PumpState()
    var memDuel = MemDuelState()
    var gallop = GallopState()
    var numbers = NumbersState()

    // scenery
    var ambient: [AmbientParticle] = []

    var onStateChange: (() -> Void)?
    var saveTimer: Double = 0

    var playMaxX: CGFloat { World.W - World.hudWidth - 10 }

    var petScale: CGFloat {
        switch mode {
        case .runner: return 1.3
        case .catcher: return 1.25
        case .popper: return 1.3
        case .baseball, .playCatch, .fishing: return 1.2
        case .race: return 1.3
        case .memory: return 1.1
        case .balloon: return 0.55
        case .keepy, .archery: return 1.2
        case .whack, .slice, .rhythm, .chef, .pairs, .aliens, .words: return 1.0
        case .bridge, .stack, .math: return 0.9
        case .highway: return 0.55
        case .hoops: return 1.2
        case .duel: return 1.3
        case .pong, .bowling: return 1.1
        case .tug, .hurdles, .snap, .popBattle, .soccer, .rps, .mathBattle, .potato, .spaceDuel, .pongDuel: return 1.0
        case .crossing: return 0.55
        case .skijump: return 0.7
        case .colors: return 0.9
        case .claw, .fireworks, .golf, .slots, .mines, .timing, .seek, .dragrace, .missiles: return 1.0
        case .tictactoe, .connect4, .boxing, .cannon, .pump, .memoryDuel, .gallop, .numbers: return 1.0
        case .pet: return 1.35 + CGFloat(min(level, 8)) * 0.05
        }
    }
    var petSize: CGSize { CGSize(width: CGFloat(Species.pixelWidth) * petScale, height: CGFloat(Species.pixelHeight) * petScale) }

    init() { pet.x = 180 }

    // MARK: Actions

    func setSpecies(_ id: String) {
        guard id != save.speciesID else { return }
        save.speciesID = id
        burst(.spark(hex(0xFFD23F)), at: pet.x, pet.y + petSize.height / 2, count: 10)
        addText("Hi, I'm \(petName)!", x: pet.x, y: petSize.height + 1, color: .white)
        changed()
    }

    func feed() {
        if mode != .pet { startMode(.pet) }
        if save.sleeping { wake() }
        let x = CGFloat.random(in: 30...(playMaxX - 20))
        items.append(Item(kind: species.food, x: x, y: World.H + 4, vy: -10))
    }

    func throwBall() {
        if mode != .pet { startMode(.pet) }
        if save.sleeping { wake() }
        items.removeAll { $0.kind == .ball }
        pet.carryingBall = false
        let dir: CGFloat = pet.x < playMaxX / 2 ? 1 : -1
        pet.facing = dir
        pet.ballReturnX = pet.x
        items.append(Item(kind: .ball, x: pet.x + dir * 10, y: 14, vx: dir * CGFloat.random(in: 170...260),
                          vy: CGFloat.random(in: 50...80), scale: 1.4))
    }

    func toggleSleep() {
        if mode != .pet { startMode(.pet) }
        if save.sleeping { wake() } else { save.sleeping = true; pet.targetX = nil; changed() }
    }

    func wake() {
        save.sleeping = false
        addText("!", x: pet.x, y: petSize.height + 2, color: hex(0xFFD23F))
        changed()
    }

    func startMode(_ m: Mode) {
        if mode == .rhythm || m == .rhythm { MusicPlayer.shared.stop() }
        mode = m
        phase = m == .pet ? .playing : .ready
        obstacles.removeAll(); bubbles.removeAll()
        items.removeAll { m != .pet || $0.kind == .ball }
        pet.carryingBall = false
        pet.y = 0; pet.vy = 0
        pet.targetX = nil
        score = 0; combo = 0
        touchX = nil
        if m != .pet { save.sleeping = false }
        switch m {
        case .runner: pet.x = 60; pet.facing = 1
        case .catcher: pet.x = playMaxX / 2
        case .popper: pet.x = 24; pet.facing = 1
        case .pet: break
        default: setupGame(m)
        }
        resultText = nil
        changed()
    }

    func beginRound() {
        phase = .playing
        score = 0; combo = 0; phaseTimer = 0
        obstacles.removeAll(); bubbles.removeAll(); items.removeAll()
        switch mode {
        case .runner:
            runSpeed = 140; runDistance = 0; sinceLast = 0; nextGap = 220; lastBonus = 0
        case .catcher, .popper:
            timeLeft = 30; spawnTimer = 0.5
        case .pet: break
        default: beginGame()
        }
        resultText = nil
    }

    func endRound() {
        phase = .over
        phaseTimer = 0
        let key = mode.rawValue
        let isBest = score > (save.best[key] ?? 0)
        if isBest { save.best[key] = score }
        lastReward = max(1, score / mode.pointsPerStar)
        save.stars += lastReward
        save.xp += Double(score)
        save.happiness = min(100, save.happiness + Double(min(score, 20)))
        save.energy = max(0, save.energy - 6)
        save.fullness = max(0, save.fullness - 3)
        if isBest { burst(.item(.star), at: World.W / 2, 15, count: 8); Sound.play("Hero") }
        save.store()
        changed()
    }

    // MARK: Input (world coordinates)

    func touchBegan(_ p: CGPoint, id: Int = 0) {
        // ✕ is disabled while tapping frantically (race, drums, 2-player games) so a stray finger can't quit.
        let locked = phase == .playing && (mode == .race || mode == .rhythm || mode.isMultiplayer)
        // Drum Beat: the exit button is on the far left beside the target; a small gap guards it.
        if mode == .rhythm && phase == .playing && p.x < RhythmState.playLeft {
            if p.x < RhythmState.exitRight { startMode(.pet) }
            return
        }
        if mode != .pet && p.x > World.W - 22 && !locked { startMode(.pet); return }
        if mode == .rhythm && phase != .playing { songMenuPress(p); return }
        if mode.isMultiplayer {
            if phase == .playing { mpTouchBegan(p, id: id) }
            else if phase == .ready || (phase == .over && phaseTimer > 1.0) { twoPlayer = p.x >= splitX; beginRound() }
            return
        }
        switch mode {
        case .pet: petTap(p)
        case .runner:
            if phase == .playing { jump() } else { tryStart() }
        case .catcher:
            if phase == .playing { touchX = p.x } else { tryStart() }
        case .popper:
            if phase == .playing { pop(at: p) } else { tryStart() }
        default:
            if phase == .playing { gameTouchBegan(p) } else { tryStart() }
        }
    }

    func touchMoved(_ p: CGPoint, id: Int = 0) {
        if mode == .rhythm && phase != .playing { songMenuDrag(p); return }
        if mode.isMultiplayer { if phase == .playing { mpTouchMoved(p, id: id) }; return }
        if mode == .catcher && phase == .playing { touchX = p.x }
        if mode == .playCatch && phase == .playing { gameTouchMoved(p) }
        if phase == .playing { arcadeTouchMoved(p) }
        if mode == .pet && !save.sleeping && pet.eatTimer <= 0 && abs(p.x - pet.x) > 6 {
            pet.targetX = min(max(p.x, 12), playMaxX)
        }
    }

    func touchEnded(_ p: CGPoint, id: Int = 0) {
        if mode == .rhythm && phase != .playing { songMenuRelease(p); return }
        if mode.isMultiplayer { mpTouchEnded(p, id: id); return }
        if mode != .pet { arcadeTouchEnded(p) }
    }

    func tryStart() {
        // The race needs a longer pause so frantic tapping doesn't skip the results.
        let delay = mode == .race ? 2.0 : 0.7
        if phase == .ready || (phase == .over && phaseTimer > delay) { beginRound() }
    }

    private func petTap(_ p: CGPoint) {
        if p.x > World.W - World.hudWidth { return }
        let hit = abs(p.x - pet.x) < petSize.width * 0.6 && p.y < pet.y + petSize.height + 4
        if hit {
            if save.sleeping {
                wake()
                save.happiness = max(0, save.happiness - 2)
            } else {
                pet.happyTimer = 1.2
                pet.targetX = nil
                save.happiness = min(100, save.happiness + 4)
                save.xp += 1
                burst(.item(.heart), at: pet.x, pet.y + petSize.height, count: 3)
                changed()
            }
        } else if !save.sleeping {
            pet.targetX = min(max(p.x, 12), playMaxX)
        }
    }

    private func jump() {
        if pet.y <= 0.01 { pet.vy = 105 }
    }

    private func pop(at p: CGPoint) {
        var best: Int?
        var bestD = CGFloat.greatestFiniteMagnitude
        // The Touch Bar only senses horizontal position, so match bubbles by x.
        for (i, b) in bubbles.enumerated() {
            let d = abs(b.x - p.x)
            if d < b.r + 7 && d < bestD { best = i; bestD = d }
        }
        guard let i = best else { combo = 0; return }
        let b = bubbles.remove(at: i)
        switch b.kind {
        case .spiky:
            score = max(0, score - 2); combo = 0; flash = 0.25
            Sound.play("Funk")
            addText("-2", x: b.x, y: b.y, color: hex(0xE84A5F))
        case .normal, .gold:
            combo = comboTimer > 0 ? min(combo + 1, 5) : 1
            comboTimer = 0.9
            let pts = (b.kind == .gold ? 3 : 1) * combo
            score += pts
            addText(combo > 1 ? "+\(pts) x\(combo)" : "+\(pts)", x: b.x, y: b.y, color: b.kind == .gold ? hex(0xFFD23F) : .white)
            if pet.y <= 0.01 { pet.vy = 60 }
            Sound.play("Pop")
        }
        burst(.spark(b.kind == .gold ? hex(0xFFD23F) : hex(0xA8DDFF)), at: b.x, b.y, count: 6)
    }

    // MARK: Simulation

    func tick(_ dt: Double) {
        t += dt
        phaseTimer += dt
        flash = max(0, flash - dt)
        updateNeeds(dt)
        switch mode {
        case .pet: updatePetMode(dt)
        case .runner: updateRunner(dt)
        case .catcher: updateCatcher(dt)
        case .popper: updatePopper(dt)
        default: updateGame(dt)
        }
        updateParticles(dt)
        updateAmbient(dt)
        pet.blinkTimer -= dt
        if pet.blinkTimer < -0.15 { pet.blinkTimer = Double.random(in: 2...5) }
        saveTimer += dt
        if saveTimer > 15 { saveTimer = 0; save.store(); changed() }
    }

    private func updateNeeds(_ dt: Double) {
        save.fullness = max(0, save.fullness - dt / World.fullnessDrainSeconds * 100)
        save.happiness = max(0, save.happiness - dt / World.happinessDrainSeconds * 100)
        if save.sleeping {
            save.energy = min(100, save.energy + dt / 600 * 100)   // 10 minutes for a full nap
        } else {
            save.energy = max(0, save.energy - dt / World.energyDrainSeconds * 100)
        }
    }

    func move(toward x: CGFloat, speed: CGFloat, dt: Double) -> Bool {
        let dx = x - pet.x
        if abs(dx) < 1.5 { pet.moving = false; return true }
        pet.facing = dx > 0 ? 1 : -1
        pet.x += pet.facing * min(abs(dx), speed * CGFloat(dt))
        pet.moving = true
        return false
    }

    private func updatePetMode(_ dt: Double) {
        let s = species
        let speed = s.speed * (save.energy < 20 ? 0.6 : 1)
        pet.moving = false

        // Items: falling food and bouncing ball.
        for i in items.indices {
            items[i].age += dt
            if items[i].landed { continue }
            items[i].vy -= 200 * CGFloat(dt)
            items[i].x += items[i].vx * CGFloat(dt)
            items[i].y += items[i].vy * CGFloat(dt)
            if items[i].x < 6 { items[i].x = 6; items[i].vx = abs(items[i].vx) * 0.7 }
            if items[i].x > playMaxX { items[i].x = playMaxX; items[i].vx = -abs(items[i].vx) * 0.7 }
            if items[i].y <= 0 {
                items[i].y = 0
                if abs(items[i].vy) > 25 && items[i].kind == .ball {
                    items[i].vy = -items[i].vy * 0.55
                    items[i].vx *= 0.8
                } else {
                    items[i].vy = 0
                    items[i].vx *= pow(0.02, CGFloat(dt))
                    if abs(items[i].vx) < 4 { items[i].vx = 0; items[i].landed = true }
                }
            }
        }

        if save.sleeping {
            if Int(t * 1.2) % 2 == 0 && particles.filter({ if case .z = $0.kind { return true }; return false }).count < 3,
               Int((t - dt) * 1.2) % 2 != 0 {
                particles.append(Particle(kind: .z, x: pet.x + pet.facing * 6, y: petSize.height - 2, vx: 3, vy: 4, life: 2.2, maxLife: 2.2))
            }
            if save.energy >= 100 { wake() }
            return
        }

        if pet.eatTimer > 0 {
            pet.eatTimer -= dt
            if Int(pet.eatTimer * 6) != Int((pet.eatTimer + dt) * 6) {
                burst(.spark(hex(0xF6E7CF)), at: pet.x + pet.facing * petSize.width * 0.45, 4, count: 1)
            }
            if pet.eatTimer <= 0 {
                if let i = items.firstIndex(where: { $0.kind != .ball && abs($0.x - pet.x) < petSize.width }) { items.remove(at: i) }
                save.fullness = min(100, save.fullness + 25)
                save.happiness = min(100, save.happiness + 4)
                save.xp += 3
                pet.happyTimer = 1
                burst(.item(.heart), at: pet.x, petSize.height, count: 2)
                changed()
            }
            return
        }

        if pet.happyTimer > 0 {
            pet.happyTimer -= dt
            pet.y = abs(sin(pet.happyTimer * 9)) * 4
            if pet.happyTimer <= 0 { pet.y = 0 }
            return
        }

        if let food = items.filter({ $0.kind != .ball && $0.landed }).min(by: { abs($0.x - pet.x) < abs($1.x - pet.x) }) {
            let mouthOffset = petSize.width * 0.42
            let target = food.x - (food.x > pet.x ? mouthOffset : -mouthOffset)
            if move(toward: target, speed: speed * 1.6, dt: dt) {
                pet.facing = food.x >= pet.x ? 1 : -1
                pet.eatTimer = 1.6
            }
        } else if let bi = items.firstIndex(where: { $0.kind == .ball }), !pet.carryingBall {
            let ball = items[bi]
            let reach = petSize.width * 0.45
            _ = move(toward: ball.x - (ball.x > pet.x ? reach : -reach), speed: speed * 2.4, dt: dt)
            if abs(ball.x - pet.x) < reach + 3 && ball.y < 6 {
                items.remove(at: bi)
                pet.carryingBall = true
            }
        } else if pet.carryingBall {
            if move(toward: pet.ballReturnX, speed: speed * 2, dt: dt) {
                pet.carryingBall = false
                pet.happyTimer = 1.2
                save.happiness = min(100, save.happiness + 8)
                save.energy = max(0, save.energy - 3)
                save.xp += 5
                burst(.item(.heart), at: pet.x, petSize.height, count: 3)
                changed()
            }
        } else if let tx = pet.targetX {
            if move(toward: tx, speed: speed, dt: dt) { pet.targetX = nil; pet.idleTimer = Double.random(in: 1.5...4) }
        } else {
            pet.idleTimer -= dt
            if pet.idleTimer <= 0 {
                if save.energy < 12 {
                    save.sleeping = true; changed()
                } else {
                    pet.targetX = CGFloat.random(in: 20...playMaxX)
                }
            }
        }

        if s.legStyle == .hop && pet.moving {
            pet.y = abs(sin(pet.walkPhase * .pi)) * 3
        } else if pet.happyTimer <= 0 {
            pet.y = 0
        }
        if pet.moving { pet.walkPhase += dt * 4 }

        // Occasionally think about food when hungry.
        pet.thoughtTimer -= dt
        if pet.thoughtTimer < -2.5 { pet.thoughtTimer = Double.random(in: 6...12) }
    }

    func applyGravity(_ dt: Double) {
        if pet.y > 0 || pet.vy > 0 {
            pet.vy -= 420 * CGFloat(dt)
            pet.y += pet.vy * CGFloat(dt)
            if pet.y <= 0 { pet.y = 0; pet.vy = 0 }
        }
    }

    private func updateRunner(_ dt: Double) {
        let fdt = CGFloat(dt)
        pet.facing = 1
        applyGravity(dt)
        guard phase == .playing else { pet.moving = false; return }
        pet.moving = pet.y <= 0
        pet.walkPhase += dt * Double(runSpeed) / 25
        runSpeed += 4 * fdt
        runDistance += runSpeed * fdt
        sinceLast += runSpeed * fdt
        score = Int(runDistance / 25) + lastBonus

        if sinceLast >= nextGap {
            sinceLast = 0
            nextGap = max(CGFloat.random(in: 160...340), runSpeed * 0.65 + 50)
            let kind: ItemKind = [.cactus, .cactus, .tallCactus, .rock].randomElement()!
            obstacles.append(Item(kind: kind, x: World.W + 10, y: 0, scale: kind == .rock ? 1.7 : 1.3))
            if Bool.random() {
                obstacles.append(Item(kind: .coin, x: World.W + 10 + nextGap / 2, y: CGFloat.random(in: 6...14), scale: 1.4))
            }
        }
        for i in obstacles.indices { obstacles[i].x -= runSpeed * fdt }
        obstacles.removeAll { $0.x < -20 }

        let ps = petSize
        let petRect = CGRect(x: pet.x - ps.width * 0.28, y: pet.y + 2, width: ps.width * 0.56, height: ps.height * 0.6)
        var hitIndex: Int?
        for (i, o) in obstacles.enumerated() {
            let sz = o.kind.pixelSize
            let r = CGRect(x: o.x - sz.width * o.scale / 2, y: o.y, width: sz.width * o.scale, height: sz.height * o.scale)
                .insetBy(dx: o.scale * 1.5, dy: o.scale * 1)
            if r.intersects(petRect) { hitIndex = i; break }
        }
        if let i = hitIndex {
            if obstacles[i].kind == .coin {
                let c = obstacles.remove(at: i)
                lastBonus += 5
                addText("+5", x: c.x, y: c.y + 4, color: hex(0xFFD23F))
            } else {
                flash = 0.3
                pet.shakeTimer = 0.4
                Sound.play("Basso")
                endRound()
            }
        }
    }

    private var lastBonus = 0

    private func updateCatcher(_ dt: Double) {
        let fdt = CGFloat(dt)
        pet.shakeTimer = max(0, pet.shakeTimer - dt)
        if let tx = touchX, phase == .playing {
            _ = move(toward: min(max(tx, 12), playMaxX), speed: 320, dt: dt)
        } else { pet.moving = false }
        if pet.moving { pet.walkPhase += dt * 6 }
        guard phase == .playing else { return }
        timeLeft -= dt
        if timeLeft <= 0 { timeLeft = 0; items.removeAll(); endRound(); return }
        spawnTimer -= dt
        if spawnTimer <= 0 {
            spawnTimer = Double.random(in: 0.45...0.85) * (timeLeft < 10 ? 0.75 : 1)
            let roll = Double.random(in: 0..<1)
            let kind: ItemKind = roll < 0.72 ? species.food : (roll < 0.82 ? .star : .rock)
            items.append(Item(kind: kind, x: CGFloat.random(in: 16...(playMaxX - 6)), y: World.H + 2,
                              vy: -CGFloat.random(in: 11...18) * (timeLeft < 10 ? 1.3 : 1), scale: 1.3))
        }
        let ps = petSize
        var i = 0
        while i < items.count {
            items[i].y += items[i].vy * fdt
            let it = items[i]
            let caught = it.y < ps.height * 0.75 && it.y > 2 && abs(it.x - pet.x) < ps.width * 0.5
            if caught {
                items.remove(at: i)
                switch it.kind {
                case .rock:
                    score = max(0, score - 3); flash = 0.3; pet.shakeTimer = 0.4
                    addText("-3", x: it.x, y: ps.height, color: hex(0xE84A5F))
                case .star:
                    score += 5; addText("+5", x: it.x, y: ps.height, color: hex(0xFFD23F))
                    burst(.spark(hex(0xFFD23F)), at: it.x, ps.height * 0.7, count: 6)
                default:
                    score += 1; addText("+1", x: it.x, y: ps.height, color: .white)
                }
                continue
            }
            if it.y <= 0 {
                items.remove(at: i)
                if it.kind != .rock { burst(.spark(hex(0x8A8F99)), at: it.x, 1, count: 3) }
                continue
            }
            i += 1
        }
    }

    private func updatePopper(_ dt: Double) {
        let fdt = CGFloat(dt)
        applyGravity(dt)
        comboTimer = max(0, comboTimer - dt)
        if comboTimer == 0 { combo = 0 }
        guard phase == .playing else { return }
        timeLeft -= dt
        if timeLeft <= 0 { timeLeft = 0; bubbles.removeAll(); endRound(); return }
        spawnTimer -= dt
        if spawnTimer <= 0 {
            spawnTimer = Double.random(in: 0.3...0.65) * (timeLeft < 10 ? 0.7 : 1)
            let roll = Double.random(in: 0..<1)
            let kind: Bubble.Kind = roll < 0.12 ? .gold : (roll < 0.24 ? .spiky : .normal)
            let r = CGFloat.random(in: 4.5...8)
            bubbles.append(Bubble(kind: kind, x: CGFloat.random(in: 50...(playMaxX - 6)), y: -r,
                                  r: r, vy: CGFloat.random(in: 9...16) * (timeLeft < 10 ? 1.3 : 1),
                                  phase: CGFloat.random(in: 0...6)))
        }
        for i in bubbles.indices {
            bubbles[i].y += bubbles[i].vy * fdt
            bubbles[i].x += sin(CGFloat(t) * 3 + bubbles[i].phase) * 6 * fdt
        }
        bubbles.removeAll { $0.y - $0.r > World.H }
    }

    private func updateParticles(_ dt: Double) {
        for i in particles.indices {
            particles[i].life -= dt
            particles[i].x += particles[i].vx * CGFloat(dt)
            particles[i].y += particles[i].vy * CGFloat(dt)
        }
        particles.removeAll { $0.life <= 0 }
    }

    // MARK: Helpers

    func burst(_ kind: Particle.Kind, at x: CGFloat, _ y: CGFloat, count: Int) {
        for _ in 0..<count {
            let life = Double.random(in: 0.7...1.3)
            particles.append(Particle(kind: kind, x: x + CGFloat.random(in: -4...4), y: y,
                                      vx: CGFloat.random(in: -14...14), vy: CGFloat.random(in: 6...16),
                                      life: life, maxLife: life))
        }
    }

    func addText(_ s: String, x: CGFloat, y: CGFloat, color: NSColor) {
        particles.append(Particle(kind: .text(s, color), x: x, y: min(y, World.H - 8), vx: 0, vy: 6, life: 1.1, maxLife: 1.1))
    }

    func changed() { onStateChange?() }
}
