import AppKit

/// Short system sounds for game feedback. Toggled from the menu bar and remembered between launches.
enum Sound {
    private static let key = "TouchbarPet.sound"
    private static var cache: [String: NSSound] = [:]

    static var enabled: Bool {
        get { SaveData.persistenceEnabled && (UserDefaults.standard.object(forKey: key) as? Bool ?? true) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    static func play(_ name: String, volume: Float = 0.35) {
        guard enabled else { return }
        let base = cache[name] ?? NSSound(named: NSSound.Name(name))
        guard let base else { return }
        cache[name] = base
        // Copy so rapid repeats overlap instead of cutting each other off.
        guard let s = base.copy() as? NSSound else { return }
        s.volume = volume
        s.play()
    }
}
