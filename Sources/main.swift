import AppKit
import ServiceManagement
import AVFoundation

enum AppInfo {
    static let name = "TouchBarFun!"
    static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    static let author = "lemonspitz"
    static let profileURL = URL(string: "https://github.com/lemonspitz")!
    static let repoURL = URL(string: "https://github.com/lemonspitz/TouchBarFun")!

    /// TouchBarFun! used to be called Touchbar Pet. On first launch, copy that app's pet save, settings and imported
    /// songs across so nothing is lost. The old copies stay where they are.
    static func migrateFromTouchbarPet() {
        let defaults = UserDefaults.standard
        if defaults.data(forKey: SaveData.key) == nil, let old = UserDefaults(suiteName: "com.touchbarpet.swift") {
            for (key, value) in old.dictionaryRepresentation() where key.hasPrefix("TouchbarPet.") {
                defaults.set(value, forKey: key)
            }
        }
        let fm = FileManager.default
        let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let oldSongs = support.appendingPathComponent("TouchbarPet/Songs", isDirectory: true)
        let newSongs = SongLibrary.folderURL
        if fm.fileExists(atPath: oldSongs.path) && !fm.fileExists(atPath: newSongs.path) {
            try? fm.createDirectory(at: newSongs.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? fm.copyItem(at: oldSongs, to: newSongs)
        }
    }
}

final class PetWindowController: NSWindowController, NSWindowDelegate {
    let world: World
    let tb: TouchBarController
    private var statsLabel = NSTextField(labelWithString: "")
    private var speciesPopup = NSPopUpButton()
    private var sceneryPopup = NSPopUpButton()
    private var sleepButton = NSButton()

    init(world: World, tb: TouchBarController, scene: PetSceneView) {
        self.world = world
        self.tb = tb
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1060, height: 370),
                              styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = AppInfo.name
        window.isReleasedWhenClosed = false
        super.init(window: window)

        for s in Species.all { speciesPopup.addItem(withTitle: "\(s.emoji) \(s.name)") }
        speciesPopup.target = self
        speciesPopup.action = #selector(pickSpecies)
        for e in Environment.all { sceneryPopup.addItem(withTitle: "\(e.emoji) \(e.name)") }
        sceneryPopup.target = self
        sceneryPopup.action = #selector(pickScenery)

        let feed = NSButton(title: "🍖 Feed", target: self, action: #selector(feedPet))
        let ball = NSButton(title: "🎾 Throw ball", target: self, action: #selector(throwBall))
        sleepButton = NSButton(title: "💤 Sleep", target: self, action: #selector(toggleSleep))
        func gameButton(_ m: Mode) -> NSButton {
            let b = NSButton(title: "\(m.emoji) \(m.shortTitle)", target: self, action: #selector(startGame(_:)))
            b.identifier = NSUserInterfaceItemIdentifier(m.rawValue)
            b.toolTip = "\(m.title) — \(m.hint)"
            return b
        }
        let soloButtons = Mode.singlePlayerGames.map(gameButton)
        let duoButtons = Mode.multiplayerGames.map(gameButton)
        let showTB = NSButton(title: "Show on Touch Bar", target: self, action: #selector(showTouchBar))

        let backToPet = NSButton(title: "🏠 Pet", target: self, action: #selector(startGame(_:)))
        backToPet.identifier = NSUserInterfaceItemIdentifier(Mode.pet.rawValue)
        let row1 = NSStackView(views: [speciesPopup, sceneryPopup, feed, ball, sleepButton, NSView(), showTB])
        row1.spacing = 8
        // Game buttons in rows of 11: single-player first, then 2-player games.
        var gameRows: [NSView] = []
        for (title, buttons) in [("Games:", soloButtons), ("2 Players:", duoButtons)] {
            for start in stride(from: 0, to: buttons.count, by: 11) {
                let label = NSTextField(labelWithString: title)
                label.textColor = start == 0 ? .secondaryLabelColor : .clear
                label.widthAnchor.constraint(equalToConstant: 70).isActive = true
                let extra: [NSView] = gameRows.isEmpty ? [NSView(), backToPet] : [NSView()]
                let row = NSStackView(views: [label] + buttons[start..<min(start + 11, buttons.count)].map { $0 as NSView } + extra)
                row.spacing = 6
                gameRows.append(row)
            }
        }
        let rowGames = NSStackView(views: gameRows)
        rowGames.orientation = .vertical
        rowGames.alignment = .leading
        rowGames.spacing = 6
        gameRows.forEach { $0.widthAnchor.constraint(equalTo: rowGames.widthAnchor).isActive = true }
        statsLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        statsLabel.textColor = .secondaryLabelColor
        statsLabel.lineBreakMode = .byTruncatingTail
        let row2 = NSStackView(views: [statsLabel, NSView()])
        let stack = NSStackView(views: [scene, row1, rowGames, row2])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 16, right: 20)
        row1.widthAnchor.constraint(equalTo: scene.widthAnchor).isActive = true
        rowGames.widthAnchor.constraint(equalTo: scene.widthAnchor).isActive = true
        row2.widthAnchor.constraint(equalTo: scene.widthAnchor).isActive = true
        window.contentView = stack
        tb.attach(to: window)
        window.delegate = self
        window.center()
        refresh()
    }

    required init?(coder: NSCoder) { fatalError() }

    /// The app has no Dock icon, so once its window closes, hand the keyboard back to the previous app.
    func windowWillClose(_ notification: Notification) {
        DispatchQueue.main.async { NSApp.hide(nil) }
    }

    func refresh() {
        let s = world.save
        if let i = Species.all.firstIndex(where: { $0.id == s.speciesID }) { speciesPopup.selectItem(at: i) }
        if let i = Environment.all.firstIndex(where: { $0.id == world.environment.id }) { sceneryPopup.selectItem(at: i) }
        sleepButton.title = s.sleeping ? "☀️ Wake up" : "💤 Sleep"
        let best = Mode.singlePlayerGames.map { "\($0.emoji)\(s.best[$0.rawValue] ?? 0)" }.joined(separator: " ")
        statsLabel.stringValue = String(format: "%@ the %@  ·  Lv %d  ·  ⭐️ %d   |   🍖 %.0f%%  ❤️ %.0f%%  ⚡️ %.0f%%   |   Best: %@",
                                        world.petName, world.species.name, world.level, s.stars,
                                        s.fullness, s.happiness, s.energy, best)
    }

    @objc private func pickSpecies() { world.setSpecies(Species.all[speciesPopup.indexOfSelectedItem].id) }
    @objc private func pickScenery() { world.setEnvironment(Environment.all[sceneryPopup.indexOfSelectedItem].id) }
    @objc private func feedPet() { world.feed() }
    @objc private func throwBall() { world.throwBall() }
    @objc private func toggleSleep() { world.toggleSleep() }
    @objc private func showTouchBar() { tb.presentSystemBar() }
    @objc private func startGame(_ sender: NSButton) {
        if let raw = sender.identifier?.rawValue, let m = Mode(rawValue: raw) { world.startMode(m) }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let world = World()
    lazy var tb = TouchBarController(world: world)
    var statusItem: NSStatusItem!
    var windowController: PetWindowController?
    var windowScene: PetSceneView?
    var timer: Timer?
    var last = CACurrentMediaTime()

    func applicationDidFinishLaunching(_ note: Notification) {
        world.onStateChange = { [weak self] in
            self?.tb.refresh()
            self?.windowController?.refresh()
        }
        tb.installControlStrip()
        setupStatusItem()
        startLoop()
        // Open the window only on the very first launch; afterwards the pet just appears on the
        // Touch Bar without taking keyboard focus from whatever you're doing.
        if !UserDefaults.standard.bool(forKey: "TouchbarPet.launchedBefore") {
            UserDefaults.standard.set(true, forKey: "TouchbarPet.launchedBefore")
            showWindow()
        }
        tb.presentSystemBar()
        // `--start <game>` opens straight into a game (handy for testing).
        if let i = CommandLine.arguments.firstIndex(of: "--start"), i + 1 < CommandLine.arguments.count,
           let m = Mode(rawValue: CommandLine.arguments[i + 1]) {
            world.startMode(m)
        }
        // `--menu <animals|games|scenery>` opens a Touch Bar menu (handy for testing).
        if let i = CommandLine.arguments.firstIndex(of: "--menu"), i + 1 < CommandLine.arguments.count,
           let menu = TouchBarController.Menu(rawValue: CommandLine.arguments[i + 1]) {
            tb.open(menu)
        }
    }

    func applicationWillTerminate(_ note: Notification) { world.save.store() }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showWindow(); return true
    }

    // MARK: Frame loop (adaptive rate to save battery)
    //
    // Games: 60 fps. Pet scene: 20 fps while something moves, 10 fps when calm, 6 fps asleep (halved in
    // Low Power Mode). Nothing visible, display asleep, or no input for a while (the Touch Bar dims and
    // turns off): the world is simulated at 1 Hz with no drawing at all.

    private var screensAsleep = false
    private var currentRate = 0.0

    func startLoop() {
        let nc = NSWorkspace.shared.notificationCenter
        for (name, asleep) in [(NSWorkspace.screensDidSleepNotification, true), (NSWorkspace.screensDidWakeNotification, false),
                               (NSWorkspace.willSleepNotification, true), (NSWorkspace.didWakeNotification, false)] {
            nc.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.screensAsleep = asleep
                self?.frame()
            }
        }
        // Wake up straight away when the user touches the bar or the pet window.
        NSEvent.addLocalMonitorForEvents(matching: [.directTouch, .leftMouseDown, .keyDown]) { [weak self] e in
            if self?.currentRate ?? 60 < 10 { DispatchQueue.main.async { self?.frame() } }
            return e
        }
        schedule(rate: 60)
    }

    private func schedule(rate: Double) {
        guard rate != currentRate else { return }
        currentRate = rate
        timer?.invalidate()
        let t = Timer(timeInterval: 1.0 / rate, repeats: true) { [weak self] _ in self?.frame() }
        t.tolerance = rate >= 30 ? 0.002 : 0.2 / rate   // let the OS coalesce wake-ups at low rates
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    /// Seconds since the last keyboard / mouse / trackpad / Touch Bar input.
    private var userIdle: Double {
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)
    }

    private func desiredRate(visible: Bool) -> Double {
        if !visible { return 1 }
        if world.mode != .pet { return 60 }
        var low = false
        if #available(macOS 12.0, *) { low = ProcessInfo.processInfo.isLowPowerModeEnabled }
        let rate: Double
        if world.save.sleeping { rate = 6 }
        else if world.pet.moving || !world.items.isEmpty || !world.particles.isEmpty || world.pet.eatTimer > 0 || world.pet.shakeTimer > 0 { rate = 20 }
        else { rate = 10 }
        return low ? rate / 2 : rate
    }

    func frame() {
        let now = CACurrentMediaTime()
        let dt = min(now - last, world.mode == .pet ? 1.5 : 0.1)
        last = now
        var views = tb.sceneViews.filter { $0.isOnScreen } + [windowScene].compactMap { $0 }.filter { $0.window?.isVisible == true }
        // The Touch Bar dims after about a minute without input; games keep running so a paused round isn't lost.
        if screensAsleep || (world.mode == .pet && userIdle > 60) { views = [] }
        var remaining = dt                  // long gaps at low rates are simulated in small steps
        repeat { let step = min(remaining, 0.1); world.tick(step); remaining -= step } while remaining > 0
        if !views.isEmpty { views.forEach { $0.needsDisplay = true } }
        schedule(rate: desiredRate(visible: !views.isEmpty))
    }

    // MARK: UI

    func showWindow() {
        if windowController == nil {
            let scene = PetSceneView(world: world, height: 45, flexible: false)
            windowScene = scene
            windowController = PetWindowController(world: world, tb: tb, scene: scene)
        }
        NSApp.activate(ignoringOtherApps: true)
        windowController?.showWindow(nil)
        windowController?.window?.makeKeyAndOrderFront(nil)
    }

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🐾"
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        func add(_ title: String, _ action: Selector?, _ key: String = "", rep: Any? = nil, on: Bool = false) -> NSMenuItem {
            let i = NSMenuItem(title: title, action: action, keyEquivalent: key)
            i.target = self; i.representedObject = rep; i.state = on ? .on : .off
            menu.addItem(i); return i
        }
        _ = add("Show Pet on Touch Bar", #selector(showTB))
        _ = add("Open Pet Window", #selector(openWindow))
        menu.addItem(.separator())
        _ = add("🍖 Feed", #selector(feedAction))
        _ = add("🎾 Throw Ball", #selector(ballAction))
        _ = add(world.save.sleeping ? "☀️ Wake Up" : "💤 Sleep", #selector(sleepAction))
        menu.addItem(.separator())
        let pets = NSMenu()
        for s in Species.all {
            let i = NSMenuItem(title: "\(s.emoji) \(s.name)", action: #selector(pickAction(_:)), keyEquivalent: "")
            i.target = self; i.representedObject = s.id; i.state = s.id == world.save.speciesID ? .on : .off
            pets.addItem(i)
        }
        add("Animal", nil).submenu = pets
        let scenery = NSMenu()
        for e in Environment.all {
            let i = NSMenuItem(title: "\(e.emoji) \(e.name)", action: #selector(sceneryAction(_:)), keyEquivalent: "")
            i.target = self; i.representedObject = e.id; i.state = e.id == world.environment.id ? .on : .off
            scenery.addItem(i)
        }
        add("Scenery", nil).submenu = scenery
        let games = NSMenu()
        for m in Mode.games + [.pet] {
            if m == Mode.multiplayerGames.first || m == .pet { games.addItem(.separator()) }
            let i = NSMenuItem(title: m == .pet ? "🏠 Back to Pet" : "\(m.emoji) \(m.title)", action: #selector(gameAction(_:)), keyEquivalent: "")
            i.target = self; i.representedObject = m.rawValue; i.state = m == world.mode ? .on : .off
            games.addItem(i)
        }
        add("Games", nil).submenu = games
        menu.addItem(.separator())
        _ = add("🎵 Import Song for Drum Beat (MIDI or audio)…", #selector(importSong))
        _ = add("Open Songs Folder", #selector(openSongsFolder))
        menu.addItem(.separator())
        _ = add("Rename Pet…", #selector(renameAction))
        _ = add("Sound & Music", #selector(toggleSound), on: Sound.enabled)
        if #available(macOS 13.0, *) {
            _ = add("Open at Login", #selector(toggleLogin), on: SMAppService.mainApp.status == .enabled)
        }
        menu.addItem(.separator())
        _ = add("About \(AppInfo.name)", #selector(showAbout))
        _ = add("Made by @\(AppInfo.author) on GitHub", #selector(openProfile))
        _ = add("Quit \(AppInfo.name)", #selector(quit), "q")
    }

    @objc func showTB() { tb.presentSystemBar() }
    @objc func openWindow() { showWindow() }
    @objc func feedAction() { world.feed() }
    @objc func ballAction() { world.throwBall() }
    @objc func sleepAction() { world.toggleSleep() }
    @objc func pickAction(_ i: NSMenuItem) { if let id = i.representedObject as? String { world.setSpecies(id) } }
    @objc func sceneryAction(_ i: NSMenuItem) { if let id = i.representedObject as? String { world.setEnvironment(id) } }
    @objc func gameAction(_ i: NSMenuItem) {
        if let raw = i.representedObject as? String, let m = Mode(rawValue: raw) { world.startMode(m); tb.presentSystemBar() }
    }
    @objc func quit() { NSApp.terminate(nil) }
    @objc func openProfile() { NSWorkspace.shared.open(AppInfo.profileURL) }
    @objc func showAbout() {
        let credits = NSMutableAttributedString()
        let center = NSMutableParagraphStyle(); center.alignment = .center
        let body: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11), .paragraphStyle: center,
                                                   .foregroundColor: NSColor.labelColor]
        credits.append(NSAttributedString(string: "Pets, sceneries and 50+ games for the Touch Bar.\nMade by ", attributes: body))
        var link = body; link[.link] = AppInfo.profileURL
        credits.append(NSAttributedString(string: "@\(AppInfo.author)", attributes: link))
        credits.append(NSAttributedString(string: "\n", attributes: body))
        var repo = body; repo[.link] = AppInfo.repoURL
        credits.append(NSAttributedString(string: "github.com/lemonspitz/TouchBarFun", attributes: repo))
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [.applicationName: AppInfo.name, .applicationVersion: AppInfo.version,
                                                     .version: "", .credits: credits])
    }
    @objc func toggleSound() { Sound.enabled.toggle() }

    /// Adds songs you own to Drum Beat. MIDI: notes follow the melody. Audio: the recording plays and the notes
    /// follow its beats and hits.
    @objc func importSong() {
        let panel = NSOpenPanel()
        panel.title = "Import songs for Drum Beat (MIDI or audio)"
        panel.allowedFileTypes = ["mid", "midi", "kar"] + AudioAnalyzer.audioExtensions
        panel.allowsMultipleSelection = true
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK else { return }
        var added: [Song] = []
        var failed: [String] = []
        for url in panel.urls {
            if AudioAnalyzer.audioExtensions.contains(url.pathExtension.lowercased()) {
                guard let opts = askAudioSection(url) else { continue }
                if let song = SongLibrary.shared.importAudio(url, title: opts.title, subtitle: opts.subtitle, start: opts.start, end: opts.end) {
                    added.append(song)
                } else { failed.append(url.lastPathComponent) }
            } else if let song = SongLibrary.shared.importFile(url) { added.append(song) } else { failed.append(url.lastPathComponent) }
        }
        let alert = NSAlert()
        if let first = added.first, let i = SongLibrary.shared.songs.firstIndex(where: { $0.id == first.id }) {
            alert.messageText = added.count == 1 ? "Added “\(first.title)” to Drum Beat" : "Added \(added.count) songs to Drum Beat"
            alert.informativeText = "Drum notes were generated from the song (\(ChartBuilder.chart(first, difficulty: 1).count) on Normal). Pick it from the Drum Beat song list."
                + (failed.isEmpty ? "" : "\n\nCouldn't read: " + failed.joined(separator: ", "))
            world.rhythm.songIndex = i
            world.rhythm.listOffset = i
            world.startMode(.rhythm)
            tb.presentSystemBar()
        } else {
            alert.messageText = "Couldn't use that file"
            alert.informativeText = "Drum Beat needs a standard MIDI file with a melody, or an audio file with a clear beat."
        }
        alert.runModal()
    }

    /// Asks for a title, artist and the section of an audio file to play.
    private func askAudioSection(_ url: URL) -> (title: String, subtitle: String, start: Double, end: Double)? {
        let length = AudioAnalyzer.duration(url) ?? 0
        func clock(_ s: Double) -> String { String(format: "%d:%02d", Int(s) / 60, Int(s) % 60) }
        func seconds(_ text: String) -> Double? {
            let parts = text.split(separator: ":").map { Double($0.trimmingCharacters(in: .whitespaces)) }
            if parts.count == 2, let m = parts[0], let s = parts[1] { return m * 60 + s }
            return parts.count == 1 ? parts[0] : nil
        }
        let alert = NSAlert()
        alert.messageText = "Add “\(url.deletingPathExtension().lastPathComponent)” to Drum Beat"
        alert.informativeText = "Song length \(clock(length)). Choose the part to play (m:ss)."
        let fields = ["Title", "Artist", "Start", "End"].map { label -> NSTextField in
            let f = NSTextField(frame: .zero); f.placeholderString = label; return f
        }
        fields[0].stringValue = url.deletingPathExtension().lastPathComponent
        fields[2].stringValue = "0:00"
        fields[3].stringValue = clock(min(length, 180))
        let grid = NSGridView(views: zip(["Title", "Artist", "Start", "End"], fields).map { [NSTextField(labelWithString: $0), $1] })
        grid.column(at: 1).width = 260
        grid.frame = NSRect(x: 0, y: 0, width: 330, height: 120)
        alert.accessoryView = grid
        alert.addButton(withTitle: "Add")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        let start = max(0, seconds(fields[2].stringValue) ?? 0)
        let end = min(length, max(start + 10, seconds(fields[3].stringValue) ?? length))
        let artist = fields[1].stringValue.trimmingCharacters(in: .whitespaces)
        let subtitle = (artist.isEmpty ? "🎧 Your audio" : "\(artist) · your audio") + " · \(clock(start))–\(clock(end))"
        return (fields[0].stringValue, subtitle, start, end)
    }

    @objc func openSongsFolder() {
        let folder = SongLibrary.shared.folder
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        NSWorkspace.shared.open(folder)
    }

    @objc func renameAction() {
        let alert = NSAlert()
        alert.messageText = "Rename your \(world.species.name)"
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 220, height: 24))
        field.stringValue = world.petName
        alert.accessoryView = field
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        alert.window.initialFirstResponder = field
        if alert.runModal() == .alertFirstButtonReturn {
            let name = field.stringValue.trimmingCharacters(in: .whitespaces)
            world.save.names[world.save.speciesID] = name.isEmpty ? nil : String(name.prefix(16))
            world.save.store()
            world.changed()
        }
    }

    @objc func toggleLogin() {
        guard #available(macOS 13.0, *) else { return }
        do {
            if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            else { try SMAppService.mainApp.register() }
        } catch { NSSound.beep() }
    }
}

// MARK: - Offscreen rendering (used for the build's icon and for previews)

func renderPNG(_ path: String, width: Int, height: Int, draw: (CGContext) -> Void) {
    let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
    draw(ctx)
    let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
}

func runCLI(_ args: [String]) -> Bool {
    if let i = args.firstIndex(of: "--icon"), i + 1 < args.count {
        let dir = args[i + 1]
        for size in [16, 32, 64, 128, 256, 512, 1024] {
            renderPNG("\(dir)/icon_\(size).png", width: size, height: size) { ctx in
                let s = CGFloat(size)
                let path = CGPath(roundedRect: CGRect(x: s * 0.1, y: s * 0.1, width: s * 0.8, height: s * 0.8),
                                  cornerWidth: s * 0.18, cornerHeight: s * 0.18, transform: nil)
                ctx.addPath(path); ctx.clip()
                let grad = CGGradient(colorsSpace: nil, colors: [hex(0x2C5F7F).cgColor, hex(0x1B3A5C).cgColor] as CFArray, locations: [0, 1])!
                ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: s * 0.1), end: CGPoint(x: 0, y: s * 0.9), options: [])
                ctx.setFillColor(hex(0x2F7A3A).cgColor)
                ctx.fill(CGRect(x: 0, y: 0, width: s, height: s * 0.3))
                ctx.interpolationQuality = .none
                let img = Species.dog.image(frame: 0, closedEyes: false)
                let px = s * 0.6 / CGFloat(img.width)
                ctx.draw(img, in: CGRect(x: s * 0.2, y: s * 0.26, width: CGFloat(img.width) * px, height: CGFloat(img.height) * px))
            }
        }
        return true
    }
    if let i = args.firstIndex(of: "--preview"), i + 1 < args.count {
        let dir = args[i + 1]
        SaveData.persistenceEnabled = false
        let w = World()
        w.save = SaveData()
        func shot(_ name: String) {
            renderPNG("\(dir)/\(name).png", width: Int(World.W * 3), height: Int(World.H * 3)) { ctx in
                ctx.scaleBy(x: 3, y: 3); w.render(in: ctx)
            }
        }
        for (n, s) in Species.all.enumerated() {
            w.save.speciesID = s.id
            w.pet.x = 60 + CGFloat(n) * 10
            w.particles.removeAll()
            w.tick(0.01)
            shot("pet-\(s.id)")
        }
        // Sprite sheet of every animal side by side.
        renderPNG("\(dir)/lineup.png", width: 1920, height: 90) { ctx in
            ctx.scaleBy(x: 3, y: 3); w.render(in: ctx)
            ctx.setFillColor(hex(0x1B3A5C).cgColor); ctx.fill(CGRect(x: 0, y: 0, width: 640, height: 30))
            ctx.interpolationQuality = .none
            for (n, s) in Species.all.enumerated() {
                let img = s.image(frame: n % 2, closedEyes: false)
                ctx.draw(img, in: CGRect(x: 3 + CGFloat(n) * 33.5, y: 3, width: 18 * 1.75, height: 13 * 1.75))
            }
        }
        // Every scenery, day and night.
        for e in Environment.all {
            for night in [false, true] {
                World.forcedNight = night
                w.save.environmentID = e.id
                w.ambient.removeAll()
                w.startMode(.pet)
                w.pet.x = 200
                for _ in 0..<240 { w.tick(1.0 / 30) }
                w.pet.x = 200
                shot("env-\(e.id)-\(night ? "night" : "day")")
            }
        }
        World.forcedNight = false
        w.save.environmentID = nil
        // Touch Bar games menu, both pages, at real Touch Bar size (2x).
        let list = [ChoiceBarView.Choice(id: "pet", emoji: "🏠", label: "Pet")]
            + Mode.games.map { .init(id: $0.rawValue, emoji: $0.emoji, label: $0.shortTitle, badge: $0.isMultiplayer ? "2P" : nil) }
        for page in 0..<5 {
            let menu = ChoiceBarView(choices: list, selectedID: "runner", section: list.firstIndex { $0.badge != nil }.map { ($0, "2 Players") })
            menu.frame = NSRect(x: 0, y: 0, width: 900, height: 30)
            menu.page = page
            if let rep = menu.bitmapImageRepForCachingDisplay(in: menu.bounds) {
                rep.size = menu.bounds.size
                menu.cacheDisplay(in: menu.bounds, to: rep)
                let ctxImg = NSImage(size: NSSize(width: 1800, height: 60))
                ctxImg.lockFocus(); NSColor.black.setFill(); NSRect(x: 0, y: 0, width: 1800, height: 60).fill()
                rep.draw(in: NSRect(x: 0, y: 0, width: 1800, height: 60)); ctxImg.unlockFocus()
                if let tiff = ctxImg.tiffRepresentation, let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
                    try? png.write(to: URL(fileURLWithPath: "\(dir)/menu-games-\(page + 1).png"))
                }
            }
        }
        w.save.speciesID = "dog"
        w.feed(); for _ in 0..<60 { w.tick(1.0 / 30) }
        shot("pet-feeding")
        for m in Mode.games {
            w.startMode(m); shot("game-\(m.rawValue)-ready")
            w.touchBegan(CGPoint(x: m.isMultiplayer ? 500 : 300, y: 15))
            if m == .rhythm { w.touchEnded(CGPoint(x: 300, y: 15)) }
            if m.isMultiplayer {
                for k in 0..<150 {
                    w.tick(1.0 / 30)
                    if k % 7 == 0 { w.touchBegan(CGPoint(x: 120, y: 10), id: 1) }
                    if k % 9 == 0 { w.touchBegan(CGPoint(x: 480, y: 10), id: 2) }
                    if m == .soccer { w.touchMoved(CGPoint(x: w.soccer.ball.x - 6, y: 10), id: 1) }
                }
                shot("game-\(m.rawValue)-playing")
                continue
            }
            let frames = m == .race ? 200 : m == .fishing ? 150 : m == .archery ? 40 : m == .rhythm ? 120 : m == .hoops ? 62 : m == .bowling ? 70 : m == .duel ? 120 : m == .dragrace ? 160 : m == .missiles ? 200 : m == .golf ? 45 : m == .skijump ? 100 : 90
            for k in 0..<frames {
                w.tick(1.0 / 30)
                switch m {
                case .catcher: w.touchMoved(CGPoint(x: 200 + CGFloat(k), y: 10))
                case .race where k % 4 == 0: w.touchBegan(CGPoint(x: k % 8 == 0 ? 100 : 500, y: 10))
                case .fishing where k == 5: w.touchBegan(CGPoint(x: 260, y: 10))
                case .playCatch: w.touchMoved(CGPoint(x: w.playCatch.ball.x, y: 10))
                case .balloon where k % 40 == 0: w.touchBegan(CGPoint(x: 300, y: 10))
                case .balloon where k % 40 == 22: w.touchEnded(CGPoint(x: 300, y: 10))
                case .archery where k == 5: w.touchBegan(CGPoint(x: 300, y: 10))
                case .archery where k == 25: w.touchEnded(CGPoint(x: 300, y: 10))
                case .keepy where w.keepy.ball.y < 8 && w.keepy.ball.vy < 0: w.touchBegan(CGPoint(x: w.keepy.ball.x - 3, y: 10))
                case .slice where k == 84: w.touchBegan(CGPoint(x: 60, y: 10))
                case .slice where k > 84: w.touchMoved(CGPoint(x: 60 + CGFloat(k - 84) * 40, y: 10))
                case .bridge where k == 30: w.touchBegan(CGPoint(x: 300, y: 10))
                case .stack where k % 25 == 24: w.touchBegan(CGPoint(x: 300, y: 10))
                case .chef where k == 80: w.touchBegan(CGPoint(x: w.chef.pans.first?.x ?? 0, y: 10))
                case .pairs where k == 20 || k == 40: w.touchBegan(CGPoint(x: 26 + (w.playMaxX - 26) / 16 * (k == 20 ? 2.5 : 9.5), y: 10))
                case .aliens: w.touchMoved(CGPoint(x: 200 + CGFloat(k) * 2, y: 10))
                case .hoops where k == 30: w.touchBegan(CGPoint(x: 400, y: 10))
                case .hoops where k == 40: w.touchMoved(CGPoint(x: 330, y: 10))
                case .hoops where k == 50: w.touchEnded(CGPoint(x: 330, y: 10))
                case .words where k == 30: w.touchBegan(CGPoint(x: 160, y: 10))
                case .bowling where k == 20 || k == 50: w.touchBegan(CGPoint(x: 300, y: 10))
                case .crossing where k % 25 == 10: w.touchBegan(CGPoint(x: 300, y: 10))
                case .claw where k == 40: w.touchBegan(CGPoint(x: 300, y: 10))
                case .golf where k == 10: w.touchBegan(CGPoint(x: 400, y: 10))
                case .golf where k == 20: w.touchMoved(CGPoint(x: 330, y: 10))
                case .golf where k == 30: w.touchEnded(CGPoint(x: 330, y: 10))
                case .slots where k == 10 || k == 60 || k == 70: w.touchBegan(CGPoint(x: 300, y: 10))
                case .mines where k == 10: w.touchBegan(CGPoint(x: 300, y: 10)); w.touchEnded(CGPoint(x: 300, y: 10))
                case .seek where k == 20: w.touchBegan(CGPoint(x: 250, y: 10))
                case .dragrace where k % 20 == 0 && k > 100: w.touchBegan(CGPoint(x: 300, y: 10))
                case .missiles where k % 30 == 0: w.touchBegan(CGPoint(x: CGFloat(100 + k * 2), y: 10))
                default: break
                }
            }
            shot("game-\(m.rawValue)-playing")
        }
        return true
    }
    if let i = args.firstIndex(of: "--import-audio"), i + 1 < args.count {
        func value(_ flag: String) -> String? { args.firstIndex(of: flag).flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil } }
        let url = URL(fileURLWithPath: args[i + 1])
        let start = Double(value("--start") ?? "0") ?? 0
        let end = Double(value("--end") ?? "") ?? min(AudioAnalyzer.duration(url) ?? 0, 180)
        guard let song = SongLibrary.shared.importAudio(url, title: value("--title") ?? url.deletingPathExtension().lastPathComponent,
                                                        subtitle: value("--subtitle") ?? "🎧 Your audio", start: start, end: end),
              let a = song.audio else { print("import failed"); return true }
        let charts = (0..<3).map { ChartBuilder.chart(song, difficulty: $0) }
        print(String(format: "Imported “%@”: %.0f–%.0fs, tempo %.1f BPM, %d hits found; notes Easy/Normal/Hard %d/%d/%d (red %d%%, big %d on Normal)",
                     song.title, a.start, a.end, a.bpm, a.onsets.count, charts[0].count, charts[1].count, charts[2].count,
                     charts[1].filter { !$0.ka }.count * 100 / max(1, charts[1].count), charts[1].filter { $0.big }.count))
        return true
    }
    if args.contains("--selftest") {
        SaveData.persistenceEnabled = false
        selfTest()
        return true
    }
    return false
}

/// Plays each newer game with a simple bot through the real game logic and prints the outcome.
func selfTest() {
    let dt = 1.0 / 60
    func run(_ m: Mode, seconds: Double, bot: (World, Double) -> Void) -> World {
        let w = World()
        w.save = SaveData()
        w.startMode(m)
        w.touchBegan(CGPoint(x: 300, y: 15))        // start the round
        if m == .rhythm { w.touchEnded(CGPoint(x: 300, y: 15)) }   // Drum Beat picks a song on release
        var time = 0.0
        while time < seconds && w.phase == .playing { bot(w, time); w.tick(dt); time += dt }
        print(String(format: "%-10@ phase=%@ score=%d  %@  (%.1fs)", m.rawValue, "\(w.phase)", w.score, w.resultText ?? "", time))
        return w
    }
    // Baseball: perfect timing should hit, never swinging should strike out.
    _ = run(.baseball, seconds: 40) { w, _ in
        if let b = w.baseball.ball, !w.baseball.swung, b.x - w.plateX <= w.baseball.speed * 0.01 { w.touchBegan(CGPoint(x: 100, y: 10)) }
    }
    _ = run(.baseball, seconds: 40) { _, _ in }
    // Play catch: follow the ball with the glove, throw back into the +2 zone.
    var lastStage = ""
    _ = run(.playCatch, seconds: 40) { w, _ in
        let st = "\(w.playCatch.stage)"
        if st != lastStage, ProcessInfo.processInfo.environment["DEBUG_CATCH"] != nil {
            print(String(format: "  %@ ball=(%.0f,%.1f) v=(%.0f,%.0f) glove=%.0f pet=%.0f target=%.0f lives=%d",
                         st, w.playCatch.ball.x, w.playCatch.ball.y, w.playCatch.ball.vx, w.playCatch.ball.vy, w.playCatch.gloveX, w.pet.x, w.playCatch.targetX, w.playCatch.lives))
            lastStage = st
        }
        switch w.playCatch.stage {
        case .toPlayer: w.touchMoved(CGPoint(x: w.playCatch.ball.x + w.playCatch.ball.vx * 0.02, y: 10))
        case .holding: if w.playCatch.timer < 2.5 { w.touchBegan(CGPoint(x: w.pet.x + 100, y: 10)) }
        default: break
        }
    }
    // Play catch: throwing far out of reach should cost lives.
    _ = run(.playCatch, seconds: 60) { w, _ in
        switch w.playCatch.stage {
        case .toPlayer: w.touchMoved(CGPoint(x: w.playCatch.ball.x + w.playCatch.ball.vx * 0.02, y: 10))
        case .holding: if w.playCatch.timer < 2.5 { w.touchBegan(CGPoint(x: w.pet.x + 260, y: 10)) }
        default: break
        }
    }
    // Race: fast alternating taps vs slow same-side taps.
    for (rate, alternate) in [(8.0, true), (7.0, true), (5.0, false)] {
        var next = 0.0, side = false
        _ = run(.race, seconds: 30) { w, time in
            if time >= next { side.toggle(); w.touchBegan(CGPoint(x: alternate && side ? 500 : 100, y: 10)); next = time + 1 / rate }
        }
    }
    // Fishing: hook every bite after a 0.25 s reaction, recast near fish.
    _ = run(.fishing, seconds: 50) { w, _ in
        let f = w.fishing
        if f.fish.contains(where: { $0.mood == .bite }) {
            if w.t - f.biteStart > 0.25 { w.touchBegan(CGPoint(x: 300, y: 10)) }
        } else if f.bobberX == nil && f.cast == nil && f.caught == nil, let fish = f.fish.randomElement() {
            w.touchBegan(CGPoint(x: fish.x, y: 10))
        }
    }
    // Balloon: steer to a safe height for the next obstacle.
    _ = run(.balloon, seconds: 60) { w, _ in
        let b = w.balloon
        let ahead = b.obstacles.filter { $0.x + $0.w / 2 > BalloonState.x - 8 && $0.x - $0.w / 2 < BalloonState.x + 60 }.min { $0.x < $1.x }
        var target: CGFloat = 6
        if let o = ahead {
            switch o.kind {
            case .tree: target = 12
            case .cloud: target = 0
            case .bird: target = o.y - World.ground > 9 ? 0 : 12
            }
        }
        let hold = b.y + b.vy * 0.35 < target
        if hold && b.touches == 0 { w.touchBegan(CGPoint(x: 300, y: 10)) }
        if !hold && b.touches > 0 { w.touchEnded(CGPoint(x: 300, y: 10)) }
    }
    // Keepy uppy: kick when low, nudging the ball back toward the middle.
    _ = run(.keepy, seconds: 45) { w, _ in
        let b = w.keepy.ball
        if b.y < 9 && b.vy < 0 { w.touchBegan(CGPoint(x: b.x + (b.x > w.playMaxX / 2 ? 3 : -3), y: 10)) }
    }
    // Whack-a-mole: bonk moles, leave friends alone.
    _ = run(.whack, seconds: 40) { w, _ in
        for h in w.whack.holes where (h.kind == .mole || h.kind == .gold) && !h.whacked && h.t > 0.12 {
            w.touchBegan(CGPoint(x: h.x, y: 10))
        }
    }
    // Fruit slice: tap fruit that is clear of bombs.
    _ = run(.slice, seconds: 60) { w, _ in
        let bombs = w.slice.fruits.filter { $0.kind == .bomb }.map(\.x)
        if let f = w.slice.fruits.first(where: { fruit in fruit.kind != .bomb && fruit.y > 6 && !bombs.contains { abs($0 - fruit.x) < 14 } }) {
            w.touchBegan(CGPoint(x: f.x, y: 10)); w.touchEnded(CGPoint(x: f.x, y: 10))
        }
    }
    // Archery: work out the power that hits the bullseye and release at that moment.
    _ = run(.archery, seconds: 90) { w, _ in
        let a = w.archery
        if a.arrow == nil && a.wait <= 0 && !a.charging && a.arrowsLeft > 0 { w.touchBegan(CGPoint(x: 300, y: 10)); return }
        guard a.charging else { return }
        func heightAtTarget(_ p: CGFloat) -> CGFloat {
            let v = 110 + p * 260
            var x = w.pet.x + 10, y: CGFloat = 11, vx = v * cos(0.3), vy = v * sin(0.3)
            let d = CGFloat(1.0 / 60)
            while x < a.targetX && y > -20 {
                let px = x, py = y
                vx += a.wind * d; vy -= 130 * d; x += vx * d; y += vy * d
                if x >= a.targetX { return py + (y - py) * (a.targetX - px) / max(x - px, 0.01) }
            }
            return -100
        }
        var lo: CGFloat = 0, hi: CGFloat = 1
        for _ in 0..<30 { let mid = (lo + hi) / 2; if heightAtTarget(mid) < a.targetY { lo = mid } else { hi = mid } }
        let f = a.chargeT.truncatingRemainder(dividingBy: 1.4) / 1.4
        let power = CGFloat(f < 0.5 ? f * 2 : 2 - f * 2)
        if abs(power - lo) < 0.012 { w.touchEnded(CGPoint(x: 300, y: 10)) }
    }
    // Drums: 1 finger red, 2 blue, 3 big orange, 4 big purple — right on the beat.
    var tapped = -1.0
    _ = run(.rhythm, seconds: 60) { w, _ in
        let r = w.rhythm
        if let n = r.notes.first(where: { !$0.hit && !$0.missed }), abs(n.time - r.song) < 0.01, n.time != tapped {
            tapped = n.time
            let fingers = (n.ka ? 2 : 1) + (n.big ? 2 : 0)
            for k in 0..<fingers { w.touchBegan(CGPoint(x: 200 + CGFloat(k) * 40, y: 10), id: 100 + k) }
        }
    }
    // Drums: always one finger, so every blue/purple note is missed (big orange ones still count, without the bonus).
    _ = run(.rhythm, seconds: 60) { w, _ in
        let r = w.rhythm
        if let n = r.notes.first(where: { !$0.hit && !$0.missed }), abs(n.time - r.song) < 0.01 { w.touchBegan(CGPoint(x: 200, y: 10)) }
    }
    let tap = { (w: World, x: CGFloat) in w.touchBegan(CGPoint(x: x, y: 10)) }
    // Bridge: release when the plank reaches the middle of the next ledge.
    _ = run(.bridge, seconds: 60) { w, _ in
        let b = w.bridge
        guard b.stage == .aim, b.platforms.count == 2 else { return }
        if !b.growing { tap(w, 300); return }
        if b.platforms[0].x + b.platforms[0].w + b.plank >= b.platforms[1].x + b.platforms[1].w / 2 - 1 { w.touchEnded(CGPoint(x: 300, y: 10)) }
    }
    // Stack: drop when the sliding block lines up with the top.
    _ = run(.stack, seconds: 60) { w, _ in
        if let top = w.stack.blocks.last, abs(w.stack.moving.x - top.x) <= w.stack.speed / 120 + 0.1 { tap(w, 300) }
    }
    // Highway: change lanes when a car is close ahead.
    _ = run(.highway, seconds: 60) { w, _ in
        let h = w.highway
        let danger = h.cars.contains { !$0.coin && $0.lane == h.lane && $0.x + $0.w / 2 > HighwayState.playerX - 11
            && $0.x - $0.w / 2 - (HighwayState.playerX + 11) < 30 + h.speed * 0.2 }
        let otherBusy = h.cars.contains { !$0.coin && $0.lane != h.lane && abs($0.x - HighwayState.playerX) < $0.w / 2 + 14 }
        if danger && !otherBusy && abs(h.laneY - CGFloat(h.lane)) < 0.05 { tap(w, 300) }
    }
    // Chef: flip and serve right in the golden window.
    _ = run(.chef, seconds: 50) { w, _ in
        for p in w.chef.pans where (p.stage == 1 || p.stage == 3) && p.t / p.cookTime > 0.97 && p.t / p.cookTime < 1.1 { tap(w, p.x) }
    }
    // Pairs: a bot with perfect memory.
    var nextTap = 0.0
    _ = run(.pairs, seconds: 60) { w, time in
        let p = w.pairs
        guard time >= nextTap, p.hideTimer <= 0 else { return }
        let cell = (w.playMaxX - 26) / 16
        let target: Int?
        if let f = p.first { target = p.cards.indices.first { $0 != f && p.cards[$0] == p.cards[f] } }
        else { target = p.cards.indices.first { !p.matched[$0] && !p.up[$0] } }
        if let i = target { tap(w, 26 + cell * (CGFloat(i) + 0.5)); nextTap = time + 0.3 }
    }
    // Math: always right, one answer every 0.6 s.
    nextTap = 0
    _ = run(.math, seconds: 50) { w, time in
        guard time >= nextTap, let i = w.math.options.firstIndex(of: w.math.answer) else { return }
        tap(w, 200 + (w.playMaxX - 200) * (CGFloat(i) + 0.5) / 4)
        nextTap = time + 0.6
    }
    // Aliens: chase the lowest alien, sidestep bombs.
    _ = run(.aliens, seconds: 60) { w, _ in
        let a = w.aliens
        if let bomb = a.bombs.first(where: { abs($0.x - a.shipX) < 9 && $0.y < 16 }) {
            w.touchMoved(CGPoint(x: bomb.x < a.shipX ? a.shipX + 25 : a.shipX - 25, y: 10)); return
        }
        let col = a.aliens.filter(\.alive).min { abs(a.offsetX + CGFloat($0.col) * AliensState.spacing - a.shipX) < abs(a.offsetX + CGFloat($1.col) * AliensState.spacing - a.shipX) }
        if let c = col { w.touchMoved(CGPoint(x: a.offsetX + CGFloat(c.col) * AliensState.spacing, y: 10)) }
    }
    // Hoops: work out the pull that drops the ball through the rim.
    _ = run(.hoops, seconds: 90) { w, _ in
        let h = w.hoops
        guard h.ball == nil, h.wait <= 0, h.dragStart == nil, h.shotsLeft > 0 else { return }
        func heightAtHoop(_ p: CGFloat) -> CGFloat {
            var (vx, vy) = w.hoopLaunch(power: p)
            var x = w.pet.x + 9, y: CGFloat = 9
            let d = CGFloat(1.0 / 60)
            while y > -5 {
                let px = x, py = y
                vy -= 190 * d; x += vx * d; y += vy * d
                if x >= h.hoopX { return py + (y - py) * (h.hoopX - px) / max(x - px, 0.01) }
            }
            return -100
        }
        var lo: CGFloat = 0.05, hi: CGFloat = 1
        for _ in 0..<30 { let mid = (lo + hi) / 2; if heightAtHoop(mid) < h.rimY { lo = mid } else { hi = mid } }
        tap(w, 400); w.touchMoved(CGPoint(x: 400 - lo * 150, y: 10)); w.touchEnded(CGPoint(x: 400 - lo * 150, y: 10))
    }
    // Duel: shoot 0.2 s after DRAW!, never before.
    _ = run(.duel, seconds: 60) { w, _ in
        if w.duel.stage == 2 && w.t - w.duel.drawTime >= 0.2 { tap(w, 300) }
    }
    // Words: tap the right letters, one every 0.25 s.
    nextTap = 0
    _ = run(.words, seconds: 70) { w, time in
        let wd = w.words
        guard time >= nextTap, wd.nextT <= 0, wd.progress < wd.word.count else { return }
        let want = Array(wd.word)[wd.progress]
        guard let i = wd.tiles.indices.first(where: { !wd.used[$0] && wd.tiles[$0] == want }) else { return }
        let spacing = min(46, (w.playMaxX - 150) / CGFloat(wd.tiles.count))
        tap(w, 150 + spacing * (CGFloat(i) + 0.5))
        nextTap = time + 0.25
    }
    // Pong: swing as the ball reaches the paddle after its bounce.
    _ = run(.pong, seconds: 60) { w, _ in
        let p = w.pong
        if p.inPlay && p.vx < 0 && p.bounced && !p.swung && abs(p.ball.x - 42) < 2.5 { tap(w, 300) }
    }
    // Bowling: lock a straight aim and the ideal power.
    _ = run(.bowling, seconds: 90) { w, _ in
        let b = w.bowling
        if b.stage == 0 && abs(sin(b.aimT * 2.6)) < 0.03 { tap(w, 300) }
        if b.stage == 1 {
            let f = b.powT.truncatingRemainder(dividingBy: 1.3) / 1.3
            let p = f < 0.5 ? f * 2 : 2 - f * 2
            if abs(p - 0.85) < 0.02 { tap(w, 300) }
        }
    }
    // MARK: Drum Beat songs: chart sizes per difficulty, colour balance, and a MIDI write → read round trip.
    for song in SongLibrary.shared.songs {
        let charts = (0..<3).map { ChartBuilder.chart(song, difficulty: $0) }
        let reds = charts[1].filter { !$0.ka }.count
        let bigs = charts[1].filter { $0.big }.count
        let parsed = MIDIReader.parse(MIDIWriter.data(for: song))
        let melody = parsed.map(MIDIReader.melody) ?? []
        let length = (song.melody.map { $0.beat + $0.dur }.max() ?? 0) * 60 / song.bpm
        let player = try? AVMIDIPlayer(data: MIDIWriter.data(for: song), soundBankURL: SoundBank.url)
        print(String(format: "song %-9@ %3.0fs  notes E/N/H %3d/%3d/%3d  red %2d%%  big %2d  melody %3d → MIDI round trip %3d  player %@", song.id, length,
                     charts[0].count, charts[1].count, charts[2].count, reds * 100 / max(1, charts[1].count), bigs, song.melody.count, melody.count,
                     player.map { String(format: "ok %.0fs", $0.duration) } ?? "FAILED"))
    }
    // Drum Beat layout: hits count right of the guard gap, the gap is ignored, and ✕ on the left exits mid-song.
    do {
        let w = World(); w.save = SaveData(); w.startMode(.rhythm); w.touchBegan(CGPoint(x: 300, y: 10)); w.touchEnded(CGPoint(x: 300, y: 10))
        for _ in 0..<300 { w.tick(1.0 / 60) }
        w.touchBegan(CGPoint(x: World.W - 40, y: 10))
        for _ in 0..<10 { w.tick(1.0 / 60) }
        let hitRegistered = w.rhythm.flashT > 0
        w.rhythm.flashT = 0
        w.touchBegan(CGPoint(x: RhythmState.playLeft - 3, y: 10))
        for _ in 0..<10 { w.tick(1.0 / 60) }
        let gapIgnored = w.rhythm.flashT <= 0 && w.mode == .rhythm
        w.touchBegan(CGPoint(x: World.W - 5, y: 10))
        for _ in 0..<10 { w.tick(1.0 / 60) }
        let rightEdgeStays = w.mode == .rhythm
        w.touchBegan(CGPoint(x: 12, y: 10))
        print("drum layout: hit on the right \(hitRegistered ? "✓" : "✗")  guard gap ignored \(gapIgnored ? "✓" : "✗")  right edge no longer exits \(rightEdgeStays ? "✓" : "✗")  ✕ on the left exits \(w.mode == .pet ? "✓" : "✗")")
    }
    // Song list: sliding scrolls without starting a song; a tap still picks one.
    do {
        let w = World(); w.save = SaveData(); w.startMode(.rhythm)
        w.touchBegan(CGPoint(x: 400, y: 10)); w.touchMoved(CGPoint(x: 300, y: 10)); w.touchMoved(CGPoint(x: 160, y: 10)); w.touchEnded(CGPoint(x: 160, y: 10))
        let scrolled = w.rhythm.listOffset, stillPicking = w.phase == .ready
        w.touchBegan(CGPoint(x: 400, y: 10)); w.touchEnded(CGPoint(x: 400, y: 10))
        print("song list swipe: slid to card \(scrolled) \(scrolled > 0 && stillPicking ? "✓" : "✗")  tap still starts a song \(w.phase == .playing ? "✓" : "✗")")
        // A single-finger hit freezes its note in the target, then pops it (no drift while fingers are counted).
        if let i = w.rhythm.notes.firstIndex(where: { !$0.ka }) {
            while w.rhythm.song < w.rhythm.notes[i].time { w.tick(1.0 / 60) }
            w.touchBegan(CGPoint(x: 300, y: 10))
            let held = w.rhythm.claimed == i
            for _ in 0..<12 { w.tick(1.0 / 60) }
            print("hit note: held in target while counting fingers \(held ? "✓" : "✗")  popped \(w.rhythm.notes[i].hit ? "✓" : "✗")")
        }
    }
    // Import path: a MIDI file on disk is loaded like one the user imported.
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("Imported_Test_Song.mid")
    if let night = SongLibrary.shared.songs.first(where: { $0.id == "night" }) {
        try? MIDIWriter.data(for: night).write(to: tmp)
        if let song = SongLibrary.load(tmp) {
            print("import test: “\(song.title)” \(song.imported.count) melody notes (expected \(night.melody.count)), Normal chart \(ChartBuilder.chart(song, difficulty: 1).count) notes, bpm \(Int(song.bpm))")
        } else { print("import test: FAILED") }
    }
    // MARK: Multiplayer — one bot vs the computer rival, then two bots head to head.
    func runMP(_ m: Mode, twoPlayers: Bool, seconds: Double = 120, bot: (World, Double) -> Void) {
        let w = World()
        w.save = SaveData()
        w.startMode(m)
        w.touchBegan(CGPoint(x: twoPlayers ? 500 : 100, y: 15))
        var time = 0.0
        while time < seconds && w.phase == .playing { bot(w, time); w.tick(dt); time += dt }
        print(String(format: "%-10@ %@ phase=%@ %d–%d  %@  (%.1fs)", m.rawValue, twoPlayers ? "2P" : "1P", "\(w.phase)", w.p1, w.p2, w.resultText ?? "", time))
    }
    let L = CGFloat(100), R = CGFloat(500)
    func side(_ w: World, _ player: Int, _ k: Int) -> CGFloat {
        let lo = player == 0 ? 0 : w.splitX, width = player == 0 ? w.splitX : World.W - 22 - w.splitX
        return lo + width * (CGFloat(k) + 0.5) / 3
    }
    for two in [false, true] {
        runMP(.duel, twoPlayers: two) { w, _ in
            if w.duel.stage == 2 && w.t - w.duel.drawTime >= 0.2 { w.touchBegan(CGPoint(x: L, y: 10), id: 1) }
            if two && w.duel.stage == 2 && w.t - w.duel.drawTime >= 0.24 { w.touchBegan(CGPoint(x: R, y: 10), id: 2) }
        }
        var n1 = 0.0, n2 = 0.0
        runMP(.tug, twoPlayers: two) { w, time in
            if time >= n1 { w.touchBegan(CGPoint(x: L, y: 10), id: 1); n1 = time + 1 / 9.0 }
            if two && time >= n2 { w.touchBegan(CGPoint(x: R, y: 10), id: 2); n2 = time + 1 / 7.0 }
        }
        runMP(.hurdles, twoPlayers: two) { w, _ in
            for i in 0..<(two ? 2 : 1) {
                let r = w.hurdles.runners[i]
                if let h = w.hurdles.hurdles.first(where: { $0 > r.d }), h - r.d <= (i == 0 ? 25 : 40), r.y <= 0.01 {
                    w.touchBegan(CGPoint(x: i == 0 ? L : R, y: 10), id: i + 1)
                }
            }
        }
        runMP(.snap, twoPlayers: two) { w, _ in
            if w.snap.matchLive && !w.snap.claimed && w.snap.shownFor > 0.3 { w.touchBegan(CGPoint(x: L, y: 10), id: 1) }
            if two && w.snap.matchLive && !w.snap.claimed && w.snap.shownFor > 0.32 { w.touchBegan(CGPoint(x: R, y: 10), id: 2) }
        }
        n1 = 0; n2 = 0
        runMP(.popBattle, twoPlayers: two) { w, time in
            for (i, next) in [(0, n1), (1, n2)] where (i == 0 || two) && time >= next {
                let lo = i == 0 ? 0 : w.splitX, hi = i == 0 ? w.splitX : World.W - 22
                if let b = w.popBattle.bubbles.first(where: { $0.x >= lo && $0.x < hi && $0.y > 2 }) {
                    w.touchBegan(CGPoint(x: b.x, y: 10), id: i + 1)
                    if i == 0 { n1 = time + 0.3 } else { n2 = time + 0.4 }
                }
            }
        }
        runMP(.soccer, twoPlayers: two) { w, time in
            if time < 0.02 { w.touchBegan(CGPoint(x: L, y: 10), id: 1); if two { w.touchBegan(CGPoint(x: R, y: 10), id: 2) } }
            // 1P: chase the ball. 2P: Player 1 only guards the middle, so Player 2 should score.
            w.touchMoved(CGPoint(x: two ? World.W - 60 : w.soccer.ball.x - 7, y: 10), id: 1)
            if two { w.touchMoved(CGPoint(x: w.soccer.ball.x + 5, y: 10), id: 2) }
        }
        runMP(.rps, twoPlayers: two) { w, _ in
            if w.rps.choice[0] == nil && w.rps.timer < 2 { w.touchBegan(CGPoint(x: side(w, 0, Int.random(in: 0..<3)), y: 10), id: 1) }
            if two && w.rps.choice[1] == nil && w.rps.timer < 1.5 { w.touchBegan(CGPoint(x: side(w, 1, Int.random(in: 0..<3)), y: 10), id: 2) }
        }
        var asked = ""
        var askedAt = 0.0
        runMP(.mathBattle, twoPlayers: two) { w, time in
            let mb = w.mathBattle
            guard mb.countdown <= 0, mb.nextT <= 0 else { return }
            if mb.question != asked { asked = mb.question; askedAt = time }
            let k = mb.options.firstIndex(of: mb.answer)!
            if time - askedAt > 1.0 { w.touchBegan(CGPoint(x: side(w, 0, k), y: 10), id: 1) }
            if two && time - askedAt > 1.3 { w.touchBegan(CGPoint(x: side(w, 1, k), y: 10), id: 2) }
        }
        runMP(.potato, twoPlayers: two) { w, _ in
            let p = w.potato
            guard p.countdown <= 0, !p.flying, p.boomT <= 0, p.readyT <= 0 else { return }
            if p.holder == 0 { w.touchBegan(CGPoint(x: L, y: 10), id: 1) }
            if two && p.holder == 1 && p.readyT <= -0.35 { w.touchBegan(CGPoint(x: R, y: 10), id: 2) }
        }
        runMP(.spaceDuel, twoPlayers: two) { w, _ in
            let sd = w.spaceDuel
            let x0: CGFloat = 26, x1 = World.W - 36
            let travel = Double(x1 - x0) / 280
            for i in 0..<(two ? 2 : 1) where sd.reload[i] <= 0 {
                let o = 1 - i
                let predicted = 14 + 6.5 * CGFloat(sin(sd.phase[o] + sd.omega[o] * travel))
                if abs(predicted - (14 + 6.5 * CGFloat(sin(sd.phase[i])))) < (i == 0 ? 1.2 : 2) { w.touchBegan(CGPoint(x: i == 0 ? L : R, y: 10), id: i + 1) }
            }
        }
        runMP(.pongDuel, twoPlayers: two) { w, _ in
            let p = w.pongDuel
            guard p.inPlay, p.bounced else { return }
            let step = abs(p.vx) / 60
            if p.vx < 0 && !p.swung[0] && p.ball.x - 42 < step && p.ball.x - 42 > -2 { w.touchBegan(CGPoint(x: L, y: 10), id: 1) }
            if two && p.vx > 0 && !p.swung[1] && (World.W - 40) - p.ball.x < step + 3 {
                if Double.random(in: 0..<1) < 0.85 { w.touchBegan(CGPoint(x: R, y: 10), id: 2) } else { w.pongDuel.swung[1] = true }
            }
        }
    }
    // MARK: Newest single-player games
    let tapAt = { (w: World, x: CGFloat) in w.touchBegan(CGPoint(x: x, y: 10)); w.touchEnded(CGPoint(x: x, y: 10)) }
    _ = run(.crossing, seconds: 90) { w, _ in
        let c = w.crossing
        guard c.hopT <= 0, c.hitT <= 0 else { return }
        let next = c.col + 1
        guard next < c.lanes.count else { tapAt(w, 300); return }
        func clear(_ lane: CrossingState.Lane, for steps: Int) -> Bool {
            (0..<steps).allSatisfy { k in
                lane.cars.allSatisfy { car in
                    var y = car.y + lane.speed * CGFloat(k) * 0.05
                    let loop = CrossingState.loopHigh - CrossingState.loopLow
                    if y > CrossingState.loopHigh { y -= loop }; if y < CrossingState.loopLow { y += loop }
                    return !(y < CrossingState.frogHigh + 1 && y + car.len > CrossingState.frogLow - 1)
                }
            }
        }
        // Hop when the next lane stays clear; hop sooner if a car is about to reach us.
        let here = c.col >= 0 ? c.lanes[c.col] : nil
        let threatened = here.map { !$0.safe && !clear($0, for: 6) } ?? false
        let nextLane = c.lanes[next]
        if nextLane.safe || clear(nextLane, for: 14) || (threatened && clear(nextLane, for: 5)) { tapAt(w, 300) }
    }
    _ = run(.claw, seconds: 120) { w, _ in
        let c = w.claw
        guard c.stage == 0, let target = c.prizes.max(by: { $0.kind < $1.kind }) else { return }
        if abs(c.x - target.x) < c.speed / 60 + 0.3 { tapAt(w, 300) }
    }
    _ = run(.fireworks, seconds: 50) { w, _ in
        if let r = w.fireworks.rockets.first(where: { abs($0.vy) < 2.5 }) { tapAt(w, r.x) }
    }
    _ = run(.golf, seconds: 150) { w, _ in
        let g = w.golf
        guard !g.moving, g.sunkT <= 0, g.dragStart == nil else { return }
        let dir: CGFloat = g.cupX >= g.ballX ? 1 : -1
        func stop(_ p: CGFloat) -> CGFloat {
            var x = g.ballX, v = dir * w.golfPuttSpeed(power: p)
            for _ in 0..<3000 { w.golfStep(x: &x, v: &v, dt: 1.0 / 60); if v == 0 { break } }
            return x
        }
        var lo: CGFloat = 0.03, hi: CGFloat = 1
        for _ in 0..<30 { let mid = (lo + hi) / 2; if (stop(mid) - (g.cupX + dir * 3)) * dir < 0 { lo = mid } else { hi = mid } }
        w.touchBegan(CGPoint(x: 400, y: 10)); w.touchMoved(CGPoint(x: 400 - hi * 150, y: 10)); w.touchEnded(CGPoint(x: 400 - hi * 150, y: 10))
    }
    _ = run(.slots, seconds: 90) { w, _ in
        let sl = w.slots
        guard sl.resultT <= 0 else { return }
        if sl.stopped.allSatisfy({ $0 }) { if sl.spins > 0 { tapAt(w, 300) }; return }
        if let i = sl.stopped.firstIndex(of: false), Int(floor(sl.reels[i])) % 6 == 0, sl.reels[i] - floor(sl.reels[i]) < 0.4 { tapAt(w, 300) }
    }
    _ = run(.mines, seconds: 120) { w, _ in
        let m = w.mines
        guard m.boomT <= 0, m.clearT <= 0 else { return }
        let tileX = { (i: Int) in 20 + (w.playMaxX - 20) / CGFloat(m.count) * (CGFloat(i) + 0.5) }
        if !m.generated { tapAt(w, tileX(m.count / 2)); return }
        for i in m.mines.indices where m.revealed[i] {
            let ns = [i - 1, i + 1].filter { m.mines.indices.contains($0) }
            let unknown = ns.filter { !m.revealed[$0] && !m.flagged[$0] }
            let flags = ns.filter { m.flagged[$0] }.count
            let need = w.mineNumber(i) - flags
            if !unknown.isEmpty && need == 0 { tapAt(w, tileX(unknown[0])); return }
            if !unknown.isEmpty && need == unknown.count { w.secondaryTap(CGPoint(x: tileX(unknown[0]), y: 10)); return }
        }
        if let guess = m.mines.indices.filter({ !m.revealed[$0] && !m.flagged[$0] }).randomElement() { tapAt(w, tileX(guess)) }
    }
    var nextAt = 0.0
    _ = run(.colors, seconds: 45) { w, time in
        guard time >= nextAt else { return }
        tapAt(w, 200 + (w.playMaxX - 200) * (CGFloat(w.colorAnswer) + 0.5) / 4)
        nextAt = time + 0.5
    }
    _ = run(.timing, seconds: 60) { w, _ in
        let tm = w.timing
        if tm.stage == 1 && tm.elapsed >= TimingState.targets[tm.round] - 1.0 / 120 { tapAt(w, 300) }
    }
    var seekStart: Double?
    _ = run(.seek, seconds: 45) { w, time in
        guard let pet = w.seek.hiders.first(where: { $0.isPet }) else { return }
        if seekStart == nil { w.touchBegan(CGPoint(x: pet.x, y: 10)); seekStart = time }
        else if time - seekStart! > 0.35 { w.touchMoved(CGPoint(x: pet.x, y: 10)); w.touchEnded(CGPoint(x: pet.x, y: 10)); seekStart = nil }
        else { w.touchMoved(CGPoint(x: pet.x, y: 10)) }
    }
    _ = run(.dragrace, seconds: 30) { w, _ in if w.dragrace.me.rpm >= 0.9 && w.dragrace.me.gear < 4 { tapAt(w, 300) } }
    _ = run(.skijump, seconds: 40) { w, _ in
        let sk = w.skijump
        if sk.stage == 0 && sk.x >= SkiState.edgeX - 5 && !sk.jumped { w.touchBegan(CGPoint(x: 300, y: 10)) }
        if sk.stage == 1 && sk.holding && sk.vy < 0 && sk.y - max(4, 12 - (sk.x - SkiState.edgeX) * 0.028) < 3 { w.touchEnded(CGPoint(x: 300, y: 10)) }
    }
    _ = run(.missiles, seconds: 90) { w, _ in
        if w.missiles.charges >= 1, let m = w.missiles.missiles.min(by: { $0.y < $1.y }), m.y < 16 { tapAt(w, m.x) }
    }
    // Newest two-player games: a bot vs the computer rival, then two bots.
    for two in [false, true] {
        runMP(.tictactoe, twoPlayers: two) { w, _ in
            let b = w.ttt
            guard b.resultT <= 0, b.turn == 0 || two else { return }
            let me = b.turn
            let free = (0..<9).filter { b.board[$0] < 0 }
            func wins(_ who: Int, _ i: Int) -> Bool { var nb = b.board; nb[i] = who; return w.tttWinner(nb) != nil }
            let pick = free.first { wins(me, $0) } ?? free.first { wins(1 - me, $0) } ?? (free.contains(4) ? 4 : free.randomElement())
            guard let i = pick else { return }
            let cell = (w.playMaxX - 44 - 24) / 9
            w.touchBegan(CGPoint(x: 44 + cell * (CGFloat(i) + 0.5) + CGFloat(i / 3) * 12, y: 10), id: me + 1)
        }
        runMP(.connect4, twoPlayers: two) { w, _ in
            guard w.c4.resultT <= 0, w.c4.dropping == nil, w.c4.turn == 0 || two else { return }
            let open = (0..<7).filter { w.c4.board[$0].contains(-1) }
            guard let col = open.randomElement() else { return }
            w.touchBegan(CGPoint(x: w.splitX - 105 + 30 * (CGFloat(col) + 0.5), y: 10), id: w.c4.turn + 1)
        }
        var held = [false, false]
        runMP(.boxing, twoPlayers: two) { w, _ in
            let b = w.boxing
            for i in 0..<(two ? 2 : 1) {
                let o = 1 - i
                let x = i == 0 ? CGFloat(100) : 500
                if b.punchT[o] > 0.12 && !held[i] && b.stun[i] <= 0 { w.touchBegan(CGPoint(x: x, y: 10), id: 10 + i); held[i] = true; continue }
                if held[i] && b.punchT[o] <= 0 { w.touchEnded(CGPoint(x: x, y: 10), id: 10 + i); held[i] = false; continue }
                if !held[i] && b.cooldown[i] <= 0 && b.stun[i] <= 0 && !b.blocking[o] && Double.random(in: 0..<1) < (i == 0 ? 0.08 : 0.04) {
                    w.touchBegan(CGPoint(x: x, y: 10), id: 20 + i); w.touchEnded(CGPoint(x: x, y: 10), id: 20 + i)
                }
            }
        }
        var cannonTarget: CGFloat = -1
        runMP(.cannon, twoPlayers: two) { w, _ in
            let c = w.cannon
            guard c.shot == nil, c.wait <= 0, c.turn == 0 || two else { return }
            if !c.charging {
                var lo: CGFloat = 0, hi: CGFloat = 1
                let target = c.turn == 0 ? World.W - 40 : 24
                for _ in 0..<24 {
                    let mid = (lo + hi) / 2
                    let (from, vx0, vy0) = w.cannonLaunch(c.turn, power: mid)
                    var x = from.x, y = from.y, vx = vx0, vy = vy0
                    while y > 2 { vx += c.wind * 0.016; vy -= 120 * 0.016; x += vx * 0.016; y += vy * 0.016 }
                    if (x - target) * (c.turn == 0 ? 1 : -1) < 0 { lo = mid } else { hi = mid }
                }
                cannonTarget = lo + (c.turn == 1 ? 0.04 : 0)
                w.touchBegan(CGPoint(x: 300, y: 10), id: 30 + c.turn)
                return
            }
            let f = c.chargeT.truncatingRemainder(dividingBy: 1.4) / 1.4
            let p = CGFloat(f < 0.5 ? f * 2 : 2 - f * 2)
            if abs(p - cannonTarget) < 0.012 { w.touchEnded(CGPoint(x: 300, y: 10), id: 30 + c.turn) }
        }
        var pumpNext = [0.0, 0.0]
        runMP(.pump, twoPlayers: two) { w, time in
            for i in 0..<(two ? 2 : 1) where time >= pumpNext[i] && w.pump.size[i] < (i == 0 ? 0.6 : 0.5) {
                w.touchBegan(CGPoint(x: i == 0 ? 100 : 500, y: 10), id: 40 + i)
                pumpNext[i] = time + 0.15
            }
        }
        var memNext = [0.0, 0.0]
        runMP(.memoryDuel, twoPlayers: two) { w, time in
            let m = w.memDuel
            guard !m.showing, m.resultT <= 0 else { return }
            for i in 0..<(two ? 2 : 1) where time >= memNext[i] && !m.done[i] && !m.failed[i] {
                var k = m.sequence[m.progress[i]]
                if i == 1 && m.sequence.count > 5 { k = (k + 1) % 4 }   // player 2 bot "forgets" at length 6
                let lo = i == 0 ? 0 : w.splitX, width = i == 0 ? w.splitX : World.W - 22 - w.splitX
                w.touchBegan(CGPoint(x: lo + width * (CGFloat(k) + 0.5) / 4, y: 10), id: 50 + i)
                memNext[i] = time + 0.3
            }
        }
        runMP(.gallop, twoPlayers: two) { w, _ in
            let g = w.gallop
            guard g.countdown <= 0 else { return }
            let ph = g.song / g.beat
            let beatIdx = Int(ph.rounded())
            if abs(ph - ph.rounded()) * g.beat < 0.01 {
                if g.lastBeat[0] != beatIdx { w.touchBegan(CGPoint(x: 100, y: 10), id: 60) }
                if two && g.lastBeat[1] != beatIdx && beatIdx % 3 != 0 { w.touchBegan(CGPoint(x: 500, y: 10), id: 61) }
            }
        }
        var numNext = [0.0, 0.0]
        runMP(.numbers, twoPlayers: two) { w, time in
            let n = w.numbers
            guard n.countdown <= 0, n.resultT <= 0 else { return }
            for i in 0..<(two ? 2 : 1) where time >= numNext[i] && n.frozen[i] <= 0 && n.next[i] <= 8 {
                guard let k = n.layout.firstIndex(of: n.next[i]) else { continue }
                let lo = i == 0 ? 0 : w.splitX, width = i == 0 ? w.splitX : World.W - 22 - w.splitX
                w.touchBegan(CGPoint(x: lo + width * (CGFloat(k) + 0.5) / 8, y: 10), id: 70 + i)
                numNext[i] = time + (i == 0 ? 0.35 : 0.5)
            }
        }
    }
    // Memory: repeat 7 rounds correctly, then press a wrong pad.
    _ = run(.memory, seconds: 120) { w, _ in
        let m = w.memory
        guard !m.showing, m.litTimer <= 0 else { return }
        let spacing = (w.playMaxX - 60) / 4
        var pad = m.sequence[m.inputIndex]
        if m.sequence.count > 7 { pad = (pad + 1) % 4 }
        w.touchBegan(CGPoint(x: 60 + spacing * (CGFloat(pad) + 0.5), y: 10))
    }
}

let args = CommandLine.arguments
if !runCLI(args) {
    AppInfo.migrateFromTouchbarPet()
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    app.run()
}
