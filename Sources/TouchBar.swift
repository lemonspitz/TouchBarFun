import AppKit

extension NSTouchBarItem.Identifier {
    static let controlStrip = NSTouchBarItem.Identifier("com.lemonspitz.touchbarfun.controlstrip")
    static let scene = NSTouchBarItem.Identifier("com.lemonspitz.touchbarfun.scene")
    static let picker = NSTouchBarItem.Identifier("com.lemonspitz.touchbarfun.picker")
    static let feed = NSTouchBarItem.Identifier("com.lemonspitz.touchbarfun.feed")
    static let ball = NSTouchBarItem.Identifier("com.lemonspitz.touchbarfun.ball")
    static let sleep = NSTouchBarItem.Identifier("com.lemonspitz.touchbarfun.sleep")
    static let games = NSTouchBarItem.Identifier("com.lemonspitz.touchbarfun.games")
    static let scenery = NSTouchBarItem.Identifier("com.lemonspitz.touchbarfun.scenery")
    static let menuBack = NSTouchBarItem.Identifier("com.lemonspitz.touchbarfun.menuback")
}

/// Private DFRFoundation / NSTouchBar entry points used to place the pet in the Control Strip
/// and show it system-wide (not only while this app is frontmost).
enum SystemTouchBar {
    private static let dfr = dlopen("/System/Library/PrivateFrameworks/DFRFoundation.framework/DFRFoundation", RTLD_NOW)

    static func setControlStripPresence(_ id: NSTouchBarItem.Identifier, _ present: Bool) {
        typealias Fn = @convention(c) (CFString, Bool) -> Void
        guard let sym = dlsym(dfr, "DFRElementSetControlStripPresenceForIdentifier") else { return }
        unsafeBitCast(sym, to: Fn.self)(id.rawValue as CFString, present)
    }

    static func showCloseBox(_ show: Bool) {
        typealias Fn = @convention(c) (Bool) -> Void
        guard let sym = dlsym(dfr, "DFRSystemModalShowsCloseBoxWhenFrontMost") else { return }
        unsafeBitCast(sym, to: Fn.self)(show)
    }

    static func addSystemTrayItem(_ item: NSTouchBarItem) {
        let sel = NSSelectorFromString("addSystemTrayItem:")
        let cls: AnyObject = NSTouchBarItem.self
        if cls.responds(to: sel) { _ = cls.perform(sel, with: item) }
    }

    static func present(_ bar: NSTouchBar, trayID: NSTouchBarItem.Identifier) {
        let cls: AnyObject = NSTouchBar.self
        let modern = NSSelectorFromString("presentSystemModalTouchBar:systemTrayItemIdentifier:")
        let legacy = NSSelectorFromString("presentSystemModalFunctionBar:systemTrayItemIdentifier:")
        if cls.responds(to: modern) { _ = cls.perform(modern, with: bar, with: trayID.rawValue as NSString) }
        else if cls.responds(to: legacy) { _ = cls.perform(legacy, with: bar, with: trayID.rawValue as NSString) }
    }

    static func minimize(_ bar: NSTouchBar) {
        let cls: AnyObject = NSTouchBar.self
        let sel = NSSelectorFromString("minimizeSystemModalTouchBar:")
        if cls.responds(to: sel) { _ = cls.perform(sel, with: bar) }
    }
}

/// A row of choices drawn edge to edge, so every option is visible at once without scrolling.
/// Long lists split into pages with "More" / "Back" cells. Tapping a choice highlights it briefly, then reports it.
final class ChoiceBarView: NSView {
    struct Choice {
        let id: String; let emoji: String; let label: String; var badge: String? = nil
    }
    enum Cell { case choice(Int), prev, next }
    static let perPage = 14

    let choices: [Choice]
    /// Index where a new section starts on its own page, with the label for the button that leads to it.
    let section: (start: Int, title: String)?
    private(set) var selectedID: String?
    var onPick: ((String) -> Void)?
    private var pressed: Int?
    private var picked = false
    var page = 0

    init(choices: [Choice], selectedID: String?, section: (start: Int, title: String)? = nil) {
        self.choices = choices
        self.section = section
        self.selectedID = selectedID
        super.init(frame: NSRect(x: 0, y: 0, width: 600, height: 30))
        allowedTouchTypes = [.direct]
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 30).isActive = true
        widthAnchor.constraint(greaterThanOrEqualToConstant: minWidth).isActive = true
        let wide = widthAnchor.constraint(equalToConstant: 2000)
        wide.priority = .defaultLow
        wide.isActive = true
        setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
        showPageOfSelection()
    }

    required init?(coder: NSCoder) { fatalError() }

    /// Called each time the menu is shown again.
    func reset(selected: String?) {
        selectedID = selected
        picked = false
        pressed = nil
        showPageOfSelection()
        needsDisplay = true
    }

    private var paged: Bool { choices.count > 20 }

    /// Pages of up to `perPage`, with the optional section always starting a fresh page.
    private var pages: [Range<Int>] {
        guard paged else { return [choices.indices] }
        let parts = section.map { [0..<$0.start, $0.start..<choices.count] } ?? [choices.indices]
        return parts.flatMap { part -> [Range<Int>] in
            // Spread each section evenly over as few pages as it needs.
            let pages = max(1, (part.count + Self.perPage - 1) / Self.perPage)
            let size = (part.count + pages - 1) / pages
            return stride(from: part.lowerBound, to: part.upperBound, by: size).map { $0..<min($0 + size, part.upperBound) }
        }
    }
    private var pageCount: Int { pages.count }

    private func showPageOfSelection() {
        let i = choices.firstIndex { $0.id == selectedID } ?? 0
        page = pages.firstIndex { $0.contains(i) } ?? 0
    }

    private var cells: [Cell] {
        guard paged else { return choices.indices.map { .choice($0) } }
        return (page > 0 ? [.prev] : []) + pages[page].map { .choice($0) } + (page < pageCount - 1 ? [.next] : [])
    }

    private var minWidth: CGFloat { CGFloat(paged ? Self.perPage + 2 : choices.count) * 38 }
    override var intrinsicContentSize: NSSize { NSSize(width: minWidth, height: 30) }
    override var isFlipped: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    private var cellWidth: CGFloat { bounds.width / CGFloat(max(cells.count, 1)) }
    private func index(at p: CGPoint) -> Int? {
        let i = Int(p.x / cellWidth)
        return cells.indices.contains(i) ? i : nil
    }

    private func content(_ cell: Cell) -> (emoji: String, label: String, id: String?, badge: String?) {
        switch cell {
        case .choice(let i): return (choices[i].emoji, choices[i].label, choices[i].id, choices[i].badge)
        case .prev: return ("◀︎", "Back", nil, nil)
        case .next:
            if let section, page + 1 < pages.count, pages[page + 1].lowerBound == section.start { return ("▶︎", section.title, nil, nil) }
            return ("▶︎", "More (\(page + 2)/\(pageCount))", nil, nil)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        let w = cellWidth
        let labelFont = NSFont.systemFont(ofSize: 12, weight: .medium)
        let shown = cells.map(content)
        // One layout for the whole row: side by side only if every choice fits that way.
        let sideBySide = shown.allSatisfy { c in
            NSAttributedString(string: c.emoji, attributes: [.font: NSFont.systemFont(ofSize: 15)]).size().width + 4
                + NSAttributedString(string: c.label, attributes: [.font: labelFont]).size().width <= w - 11
        }
        for (i, c) in shown.enumerated() {
            let cell = NSRect(x: CGFloat(i) * w + 1.5, y: 0, width: w - 3, height: bounds.height)
            let isNav = c.id == nil
            let fill: NSColor = pressed == i ? NSColor(white: 1, alpha: 0.45)
                : c.id != nil && c.id == selectedID ? NSColor.controlAccentColor.withAlphaComponent(0.55)
                : isNav ? NSColor(white: 1, alpha: 0.25)
                : NSColor(white: 1, alpha: 0.13)
            fill.setFill()
            NSBezierPath(roundedRect: cell, xRadius: 6, yRadius: 6).fill()

            let emoji = NSAttributedString(string: c.emoji, attributes: [.font: NSFont.systemFont(ofSize: 15), .foregroundColor: NSColor.white])
            let wide = NSAttributedString(string: c.label, attributes: [.font: labelFont, .foregroundColor: NSColor.white])
            let ew = emoji.size().width
            if sideBySide {
                let total = ew + 4 + wide.size().width
                let x = cell.midX - total / 2
                emoji.draw(at: CGPoint(x: x, y: (bounds.height - emoji.size().height) / 2))
                wide.draw(at: CGPoint(x: x + ew + 4, y: (bounds.height - wide.size().height) / 2))
            } else {
                // Emoji above a small name, shrunk to fit narrow cells.
                let small = NSAttributedString(string: c.label, attributes: [
                    .font: NSFont.systemFont(ofSize: 8, weight: .medium), .foregroundColor: NSColor(white: 1, alpha: 0.9)])
                let em = NSAttributedString(string: c.emoji, attributes: [.font: NSFont.systemFont(ofSize: 12), .foregroundColor: NSColor.white])
                em.draw(at: CGPoint(x: cell.midX - em.size().width / 2, y: 11.5))
                var lw = small.size().width
                var label = small
                if lw > cell.width - 2 {
                    let f = NSFont.systemFont(ofSize: 8 * (cell.width - 2) / lw, weight: .medium)
                    label = NSAttributedString(string: c.label, attributes: [.font: f, .foregroundColor: NSColor(white: 1, alpha: 0.9)])
                    lw = label.size().width
                }
                label.draw(at: CGPoint(x: cell.midX - lw / 2, y: 1.5))
            }
            if let badge = c.badge {
                let b = NSAttributedString(string: badge, attributes: [.font: NSFont.systemFont(ofSize: 6.5, weight: .heavy), .foregroundColor: NSColor.white])
                let bw = b.size().width + 3
                let br = NSRect(x: cell.maxX - bw - 1, y: bounds.height - 9, width: bw, height: 8)
                NSColor.systemOrange.setFill()
                NSBezierPath(roundedRect: br, xRadius: 2.5, yRadius: 2.5).fill()
                b.draw(at: CGPoint(x: br.minX + 1.5, y: br.minY + 0.3))
            }
        }
    }

    private func began(_ p: CGPoint) { pressed = index(at: p); needsDisplay = true }
    private func moved(_ p: CGPoint) { if let i = index(at: p), i != pressed { pressed = i; needsDisplay = true } }
    private func ended(_ p: CGPoint) {
        guard !picked, let i = index(at: p) ?? pressed else { pressed = nil; needsDisplay = true; return }
        pressed = nil
        switch cells[i] {
        case .prev: page -= 1; needsDisplay = true
        case .next: page += 1; needsDisplay = true
        case .choice(let c):
            picked = true
            pressed = i
            needsDisplay = true
            let id = choices[c].id
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in self?.onPick?(id) }
        }
    }

    override func touchesBegan(with event: NSEvent) { event.touches(matching: .began, in: self).first.map { began($0.location(in: self)) } }
    override func touchesMoved(with event: NSEvent) { event.touches(matching: .moved, in: self).first.map { moved($0.location(in: self)) } }
    override func touchesEnded(with event: NSEvent) { event.touches(matching: .ended, in: self).first.map { ended($0.location(in: self)) } }
    override func touchesCancelled(with event: NSEvent) { pressed = nil; needsDisplay = true }
    override func mouseDown(with event: NSEvent) { began(convert(event.locationInWindow, from: nil)) }
    override func mouseDragged(with event: NSEvent) { moved(convert(event.locationInWindow, from: nil)) }
    override func mouseUp(with event: NSEvent) { ended(convert(event.locationInWindow, from: nil)) }
}

final class TouchBarController: NSObject, NSTouchBarDelegate {
    enum Menu: String, CaseIterable {
        case animals, games, scenery
        var itemID: NSTouchBarItem.Identifier { NSTouchBarItem.Identifier("com.lemonspitz.touchbarfun.menu.\(rawValue)") }
    }

    static let mainItems: [NSTouchBarItem.Identifier] = [.picker, .feed, .ball, .sleep, .games, .scenery, .scene]

    let world: World
    private(set) var sceneViews: [PetSceneView] = []
    private var animalButtons: [NSButton] = []
    private var sceneryButtons: [NSButton] = []
    private var sleepButtons: [NSButton] = []
    private var choiceViews: [Menu: [ChoiceBarView]] = [:]
    /// One bar for the system-wide Touch Bar and one for the pet window. Menus change what these
    /// bars contain instead of presenting new bars, so touches always reach a live bar.
    private var systemBar: NSTouchBar?
    private var windowBar: NSTouchBar?
    private(set) var openMenu: Menu?

    init(world: World) {
        self.world = world
        super.init()
    }

    func makeBar() -> NSTouchBar {
        let bar = NSTouchBar()
        bar.delegate = self
        bar.defaultItemIdentifiers = TouchBarController.mainItems
        return bar
    }

    private var bars: [NSTouchBar] { [systemBar, windowBar].compactMap { $0 } }

    /// Gives the pet window its Touch Bar.
    func attach(to window: NSWindow) {
        let bar = makeBar()
        windowBar = bar
        window.touchBar = bar
    }

    // MARK: System-wide presentation

    func installControlStrip() {
        let item = NSCustomTouchBarItem(identifier: .controlStrip)
        item.view = NSButton(title: "🐾", target: self, action: #selector(presentSystemBar))
        SystemTouchBar.addSystemTrayItem(item)
        SystemTouchBar.setControlStripPresence(.controlStrip, true)
    }

    @objc func presentSystemBar() {
        if openMenu != nil { closeMenu() }
        if systemBar == nil { systemBar = makeBar() }
        SystemTouchBar.showCloseBox(true)
        SystemTouchBar.present(systemBar!, trayID: .controlStrip)
    }

    func minimizeSystemBar() {
        if let bar = systemBar { SystemTouchBar.minimize(bar) }
    }

    // MARK: Menus (fill the whole bar, then go back after a pick)

    func open(_ menu: Menu) {
        openMenu = menu
        let (_, selected) = choices(for: menu)
        choiceViews[menu]?.forEach { $0.reset(selected: selected) }
        for bar in bars { bar.defaultItemIdentifiers = [.menuBack, menu.itemID] }
    }

    @objc func closeMenu() {
        openMenu = nil
        for bar in bars { bar.defaultItemIdentifiers = TouchBarController.mainItems }
        refresh()
    }

    private func choices(for menu: Menu) -> (choices: [ChoiceBarView.Choice], selected: String?) {
        switch menu {
        case .animals:
            return (Species.all.map { .init(id: $0.id, emoji: $0.emoji, label: $0.name) }, world.species.id)
        case .scenery:
            return (Environment.all.map { .init(id: $0.id, emoji: $0.emoji, label: $0.name) }, world.environment.id)
        case .games:
            let list = [ChoiceBarView.Choice(id: Mode.pet.rawValue, emoji: "🏠", label: "Pet")]
                + Mode.games.map { .init(id: $0.rawValue, emoji: $0.emoji, label: $0.shortTitle, badge: $0.isMultiplayer ? "2P" : nil) }
            return (list, world.mode.rawValue)
        }
    }

    func pick(_ id: String, in menu: Menu) {
        switch menu {
        case .animals: world.setSpecies(id)
        case .scenery: world.setEnvironment(id)
        case .games: if let m = Mode(rawValue: id) { world.startMode(m) }
        }
        closeMenu()
    }

    // MARK: Items

    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        if let menu = Menu.allCases.first(where: { $0.itemID == identifier }) {
            let (list, selected) = choices(for: menu)
            let firstDuo = menu == .games ? list.firstIndex { $0.badge != nil } : nil
            let view = ChoiceBarView(choices: list, selectedID: selected, section: firstDuo.map { ($0, "2 Players") })
            view.onPick = { [weak self] id in self?.pick(id, in: menu) }
            choiceViews[menu, default: []].append(view)
            let item = NSCustomTouchBarItem(identifier: identifier)
            item.view = view
            item.visibilityPriority = .high
            return item
        }
        switch identifier {
        case .scene:
            let item = NSCustomTouchBarItem(identifier: identifier)
            let view = PetSceneView(world: world, height: 30, flexible: true)
            sceneViews.append(view)
            item.view = view
            item.visibilityPriority = .high
            return item
        case .feed:
            return button(identifier, "🍖", #selector(feed))
        case .ball:
            return button(identifier, "🎾", #selector(ball))
        case .sleep:
            let item = button(identifier, world.save.sleeping ? "☀️" : "💤", #selector(sleep))
            if let b = item.view as? NSButton { sleepButtons.append(b) }
            return item
        case .picker:
            let item = button(identifier, world.species.emoji, #selector(openAnimals))
            if let b = item.view as? NSButton { animalButtons.append(b) }
            return item
        case .games:
            return button(identifier, "🎮", #selector(openGames))
        case .scenery:
            let item = button(identifier, world.environment.emoji, #selector(openScenery))
            if let b = item.view as? NSButton { sceneryButtons.append(b) }
            return item
        case .menuBack:
            return button(identifier, "◀︎", #selector(closeMenu))
        default:
            return nil
        }
    }

    private func button(_ id: NSTouchBarItem.Identifier, _ title: String, _ action: Selector) -> NSCustomTouchBarItem {
        let item = NSCustomTouchBarItem(identifier: id)
        let b = NSButton(title: title, target: self, action: action)
        if title.count <= 2 { b.widthAnchor.constraint(equalToConstant: 46).isActive = true }   // compact emoji buttons
        item.view = b
        return item
    }

    // MARK: Actions

    @objc func feed() { world.feed() }
    @objc func ball() { world.throwBall() }
    @objc func sleep() { world.toggleSleep() }
    @objc func openAnimals() { open(.animals) }
    @objc func openGames() { open(.games) }
    @objc func openScenery() { open(.scenery) }

    /// Refreshes labels that depend on world state.
    func refresh() {
        for b in animalButtons { b.title = world.species.emoji }
        for b in sceneryButtons { b.title = world.environment.emoji }
        for b in sleepButtons { b.title = world.save.sleeping ? "☀️" : "💤" }
    }
}
