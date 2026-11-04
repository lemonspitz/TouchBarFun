import AppKit
import AVFoundation

// MARK: - Song model

struct MelodyNote { var beat: Double; var dur: Double; var pitch: Int }

/// A melody onset used to build a drum chart (time in seconds, position in beats).
struct ChartSource { var time: Double; var beat: Double; var pitch: Int; var durBeats: Double }

enum AccompStyle { case oompah, waltz, arpeggio, pad, pop, drone, staccato }

struct Song {
    enum Kind { case classical, original, imported, audio }
    let id: String
    let title: String
    let subtitle: String
    let kind: Kind
    let bpm: Double
    var beatsPerBar: Double = 4
    var melody: [MelodyNote] = []
    var chords: [String] = []
    var style: AccompStyle = .oompah
    var melodyProgram = 0
    var accProgram = 0
    var fileURL: URL?              // imported songs play straight from their file
    var imported: [ChartSource] = []
    var audio: AudioAnalysis?      // imported audio recordings (MP3 etc.)

    var badge: String {
        switch kind {
        case .classical: return "🎻"
        case .original: return "✨"
        case .imported: return "📁"
        case .audio: return "🎧"
        }
    }

    /// Accompaniment onsets (bass and chord hits) — Hard mode drums on these too.
    var accompanimentSource: [ChartSource] {
        guard kind != .imported && kind != .audio else { return [] }
        var seen = Set<Int>()
        return MIDIWriter.accompaniment(self).sorted { $0.beat < $1.beat }.compactMap { n in
            let key = Int((n.beat * 100).rounded())
            guard seen.insert(key).inserted else { return nil }
            return ChartSource(time: n.beat * 60 / bpm, beat: n.beat, pitch: n.pitch, durBeats: n.dur)
        }
    }

    /// Melody onsets in seconds, ready for chart building.
    var chartSource: [ChartSource] {
        if kind == .imported { return imported }
        return melody.map { ChartSource(time: $0.beat * 60 / bpm, beat: $0.beat, pitch: $0.pitch, durBeats: $0.dur) }
    }
}

// MARK: - Notation helpers

enum Notation {
    static let semis: [Character: Int] = ["C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11]

    /// "F#4" → MIDI 66
    static func pitch(_ s: Substring) -> Int? {
        guard let first = s.first, let base = semis[first] else { return nil }
        var rest = s.dropFirst()
        var acc = 0
        if rest.first == "#" { acc = 1; rest = rest.dropFirst() } else if rest.first == "b" { acc = -1; rest = rest.dropFirst() }
        guard let octave = Int(rest) else { return nil }
        return 12 * (octave + 1) + base + acc
    }

    /// Parses "E4:1 r:.5 F#4:0.5 | G4" (durations in beats; a missing duration repeats the previous one).
    static func melody(_ text: String) -> [MelodyNote] {
        var notes: [MelodyNote] = []
        var beat = 0.0, lastDur = 1.0
        for token in text.split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "|" }) {
            let parts = token.split(separator: ":")
            let dur = parts.count > 1 ? (Double(parts[1]) ?? lastDur) : lastDur
            lastDur = dur
            if parts[0] != "r", let p = pitch(parts[0]) { notes.append(MelodyNote(beat: beat, dur: dur, pitch: p)) }
            beat += dur
        }
        return notes
    }

    /// "F#m" → (root pitch class, chord tones as semitone offsets)
    static func chord(_ s: Substring) -> (Int, [Int])? {
        guard let first = s.first, var root = semis[first] else { return nil }
        var rest = s.dropFirst()
        if rest.first == "#" { root += 1; rest = rest.dropFirst() } else if rest.first == "b" { root -= 1; rest = rest.dropFirst() }
        switch rest {
        case "m": return ((root + 12) % 12, [0, 3, 7])
        case "7": return ((root + 12) % 12, [0, 4, 7, 10])
        case "m7": return ((root + 12) % 12, [0, 3, 7, 10])
        case "dim": return ((root + 12) % 12, [0, 3, 6])
        default: return ((root + 12) % 12, [0, 4, 7])
        }
    }
}

// MARK: - Built-in songs (public-domain classics + original J-pop-style tunes)

enum BuiltInSongs {
    private static func song(_ id: String, _ title: String, _ subtitle: String, _ kind: Song.Kind, bpm: Double, bar: Double = 4,
                             melody: String, chords: [String], style: AccompStyle, lead: Int, acc: Int = 0) -> Song {
        Song(id: id, title: title, subtitle: subtitle, kind: kind, bpm: bpm, beatsPerBar: bar,
             melody: Notation.melody(melody), chords: chords, style: style, melodyProgram: lead, accProgram: acc)
    }

    /// Scale-aware upper neighbour in C major, for the Twinkle variation.
    private static func upperNeighbour(_ p: Int) -> Int {
        let scale = [0, 2, 4, 5, 7, 9, 11]
        let pc = p % 12
        let i = scale.firstIndex(of: pc) ?? 0
        let next = scale[(i + 1) % 7]
        return p - pc + next + (next < pc ? 12 : 0)
    }

    static let all: [Song] = {
        // Ode to Joy — Beethoven, Symphony No. 9 (D major)
        let ode = song("ode", "Ode to Joy", "Beethoven · Symphony No. 9", .classical, bpm: 112,
            melody: """
            F#4 F#4 G4 A4 | A4 G4 F#4 E4 | D4 D4 E4 F#4 | F#4:1.5 E4:.5 E4:2 |
            F#4:1 F#4 G4 A4 | A4 G4 F#4 E4 | D4 D4 E4 F#4 | E4:1.5 D4:.5 D4:2 |
            E4:1 E4 F#4 D4 | E4 F#4:.5 G4:.5 F#4:1 D4 | E4 F#4:.5 G4:.5 F#4:1 E4 | D4 E4 A3:2 |
            F#4:1 F#4 G4 A4 | A4 G4 F#4 E4 | D4 D4 E4 F#4 | E4:1.5 D4:.5 D4:2
            """,
            chords: ["D", "A", "D", "A", "D", "A", "D", "D", "A", "D", "A", "A", "D", "A", "D", "D"], style: .oompah, lead: 48)

        // Für Elise — Beethoven (A minor, 3/8)
        let a1 = "E5:.25 D#5 E5 B4 D5 C5 | A4:.5 r:.25 C4 E4 A4 | B4:.5 r:.25 E4 G#4 B4 | C5:.5 r:.25 E4 E5 D#5 | E5:.25 D#5 E5 B4 D5 C5 | A4:.5 r:.25 C4 E4 A4 | B4:.5 r:.25 E4 C5 B4 |"
        let a1Chords = ["-", "Am", "E", "Am", "-", "Am", "E"]
        let elise = song("elise", "Für Elise", "Beethoven", .classical, bpm: 72, bar: 1.5,
            melody: "r:1 E5:.25 D#5 | " + a1 + " A4:1 E5:.25 D#5 | " + a1 + " A4:.5 r:.25 B4 C5 D5 | "
                + "E5:.75 G4:.25 F5 E5 | D5:.75 F4:.25 E5 D5 | C5:.75 E4:.25 D5 C5 | B4:.5 r:.25 E4 E5 D#5 | " + a1 + " A4:1.5",
            chords: ["-"] + a1Chords + ["Am"] + a1Chords + ["Am", "C", "G", "Am", "E"] + a1Chords + ["Am"], style: .arpeggio, lead: 0)

        // Twinkle variations — Mozart, "Ah vous dirai-je, maman"
        let theme = "C4 C4 G4 G4 | A4 A4 G4:2 | F4:1 F4 E4 E4 | D4 D4 C4:2 | G4:1 G4 F4 F4 | E4 E4 D4:2 | G4:1 G4 F4 F4 | E4 E4 D4:2 | C4:1 C4 G4 G4 | A4 A4 G4:2 | F4:1 F4 E4 E4 | D4 D4 C4:2"
        let themeNotes = Notation.melody(theme)
        let length = 48.0
        var variation: [MelodyNote] = []
        for n in themeNotes {
            let p = n.pitch + 12, b = n.beat + length
            if n.dur == 1 {
                variation += [MelodyNote(beat: b, dur: 0.5, pitch: p), MelodyNote(beat: b + 0.5, dur: 0.25, pitch: upperNeighbour(p)),
                              MelodyNote(beat: b + 0.75, dur: 0.25, pitch: p)]
            } else {
                variation.append(MelodyNote(beat: b, dur: n.dur, pitch: p))
            }
        }
        let twinkleChords = ["C", "F,C", "F,C", "G,C", "C,F", "C,G", "C,F", "C,G", "C", "F,C", "F,C", "G,C"]
        var twinkle = song("twinkle", "Twinkle Variations", "Mozart · Ah vous dirai-je, maman", .classical, bpm: 104,
                           melody: theme, chords: twinkleChords + twinkleChords, style: .oompah, lead: 10)
        twinkle.melody += variation

        // Eine kleine Nachtmusik — Mozart (opening)
        let nacht = "G4:1 r:.5 D4 G4:1 r:.5 D4 | G4:.5 D4 G4 B4 D5:2 | C5:1 r:.5 A4 C5:1 r:.5 A4 | C5:.5 A4 F#4 A4 D4:2 | "
        let kleine = song("nacht", "Eine kleine Nachtmusik", "Mozart", .classical, bpm: 132,
            melody: nacht + nacht + nacht + "G4:.5 B4 D5 B4 G4:2",
            chords: Array(repeating: ["G", "G", "D", "D"], count: 3).flatMap { $0 } + ["G"], style: .oompah, lead: 48)

        // Rondo alla Turca — Mozart (A minor, 2/4)
        let turkish = "C5:.5 r:.5 D5:.25 C5 B4 C5 | E5:.5 r:.5 F5:.25 E5 D#5 E5 | B5:.25 A5 G#5 A5 B5 A5 G#5 A5 | C6:1 A5:.5 C6 | B5:.5 A5 G5 A5 | B5:.5 A5 G5 A5 | B5:.5 A5 G5 F#5 | "
        let turkishChords = ["Am", "Am", "E", "Am", "Em", "Em", "B7"]
        let turca = song("turca", "Turkish March", "Mozart · Rondo alla Turca", .classical, bpm: 120, bar: 2,
            melody: "r:1 B4:.25 A4 G#4 A4 | " + turkish + "E5:1 B4:.25 A4 G#4 A4 | " + turkish + "E5:1 B4:.25 A4 G#4 A4 | " + turkish + "E5:2",
            chords: ["-"] + turkishChords + ["Em"] + turkishChords + ["Em"] + turkishChords + ["Em"], style: .oompah, lead: 0)

        // Minuet in G — Petzold (formerly attributed to Bach)
        let minuetA = "D5:1 G4:.5 A4 B4 C5 | D5:1 G4 G4 | E5:1 C5:.5 D5 E5 F#5 | G5:1 G4 G4 | C5:1 D5:.5 C5 B4 A4 | B4:1 C5:.5 B4 A4 G4 | "
        let minuet = song("minuet", "Minuet in G", "Petzold (Bach notebook)", .classical, bpm: 132, bar: 3,
            melody: minuetA + "F#4:1 G4:.5 A4 B4 G4 | A4:3 | " + minuetA + "A4:1 B4:.5 A4 G4 F#4 | G4:3 | "
                + minuetA + "F#4:1 G4:.5 A4 B4 G4 | A4:3 | " + minuetA + "A4:1 B4:.5 A4 G4 F#4 | G4:3",
            chords: Array(repeating: ["G", "G", "C", "G", "Am", "G", "D", "D", "G", "G", "C", "G", "Am", "G", "D", "G"], count: 2).flatMap { $0 },
            style: .waltz, lead: 6, acc: 6)

        // Canon in D — Pachelbel (simplified)
        let canonA = "F#5:2 E5 D5 C#5 | B4:2 A4 B4 C#5 | "
        let canon = song("canon", "Canon in D", "Pachelbel", .classical, bpm: 72,
            melody: canonA + canonA + "D5:1 C#5 B4 A4 G4 F#4 G4 E4 D5 C#5 B4 A4 G4 F#4 G4 A4 | "
                + "D4:.5 F#4 A4 G4 F#4 D4 F#4 E4 D4 B3 D4 A4 G4 B4 A4 G4 F#4 D4 E4 C#5 D5 F#5 A5 A4 B4 G4 A4 F#4 D4 D5 D5:1",
            chords: Array(repeating: ["D,A", "Bm,F#m", "G,D", "G,A"], count: 4).flatMap { $0 }, style: .pad, lead: 40, acc: 48)

        // In the Hall of the Mountain King — Grieg (B minor)
        let king = "B3:.5 C#4 D4 E4 F#4 D4 F#4:1 | F4:.5 C#4 F4:1 E4:.5 C4 E4:1 | B3:.5 C#4 D4 E4 F#4 D4 F#4 B4 | A4:.5 F#4 D4 F#4 A4:2 | "
        var mountain = song("king", "Hall of the Mountain King", "Grieg · Peer Gynt", .classical, bpm: 132,
            melody: king + king, chords: Array(repeating: ["Bm", "C#,C", "Bm", "D"], count: 4).flatMap { $0 }, style: .staccato, lead: 70, acc: 45)
        mountain.melody += Notation.melody(king + king).map { MelodyNote(beat: $0.beat + 32, dur: $0.dur, pitch: $0.pitch + 12) }

        // Brahms' Lullaby (Wiegenlied)
        let lullabyA = "G4:2 E4:.5 E4 | G4:2 E4:.5 G4 | C5:1 B4:1.5 A4:.5 | A4:1 G4 D4:.5 E4 | F4:1 D4 D4:.5 E4 | F4:2 D4:.5 F4 | B4:.5 A4 G4:1 B4 | C5:3 | "
        let lullaby = song("lullaby", "Lullaby", "Brahms · Wiegenlied", .classical, bpm: 84, bar: 3,
            melody: "r:2 E4:.5 E4 | " + lullabyA + "r:2 E4:.5 E4 | " + lullabyA,
            chords: ["-", "C", "C", "F", "G", "G7", "G7", "G", "C", "-", "C", "C", "F", "G", "G7", "G7", "G", "C"], style: .waltz, lead: 8)

        // Sakura Sakura — Japanese traditional
        let sakura = song("sakura", "Sakura Sakura", "Japanese traditional", .classical, bpm: 76,
            melody: """
            A4 A4 B4:2 | A4:1 A4 B4:2 | A4:1 B4 C5 B4 | A4 B4:.5 A4 F4:2 | E4:1 C4 E4 F4 | E4 E4:.5 C4 B3:2 |
            A4:1 B4 C5 B4 | A4 B4:.5 A4 F4:2 | E4:1 C4 E4 F4 | E4 E4:.5 C4 B3:2 |
            A4:1 A4 B4:2 | A4:1 A4 B4:2 | E4:1 F4 B4:.5 A4 F4:1 | E4:4
            """,
            chords: Array(repeating: "Am", count: 14), style: .drone, lead: 107, acc: 107)

        // Jingle Bells — James Lord Pierpont
        let jingle = song("jingle", "Jingle Bells", "J. L. Pierpont", .classical, bpm: 140,
            melody: """
            E4 E4 E4:2 | E4:1 E4 E4:2 | E4:1 G4 C4:1.5 D4:.5 | E4:4 | F4:1 F4 F4:1.5 F4:.5 | F4:1 E4 E4 E4:.5 E4 |
            E4:1 D4 D4 E4 | D4:2 G4:2 | E4:1 E4 E4:2 | E4:1 E4 E4:2 | E4:1 G4 C4:1.5 D4:.5 | E4:4 |
            F4:1 F4 F4 F4 | F4 E4 E4 E4:.5 E4 | G4:1 G4 F4 D4 | C4:4
            """,
            chords: ["C", "C", "C", "C", "F", "C", "G", "G", "C", "C", "C", "C", "F", "C", "G", "C"], style: .oompah, lead: 9)

        // ✨ Originals in a J-pop style (composed for this app)
        let springVerse = """
        E4:.5 G4 G4 A4 G4:1 E4 | D4:.5 E4 G4 E4 D4:2 | C4:.5 E4 A4 G4 E4:1 C4 | D4:.5 E4 F4 E4 D4:2 |
        E4:.5 G4 G4 A4 C5:1 A4 | G4:.5 E4 G4 A4 B4:2 | C5:.5 B4 A4 G4 E4:1 A4 | G4:1.5 F4:.5 E4 D4:1.5 |
        """
        let springChorus = """
        A4:.5 C5 C5:1 D5:.5 C5 A4:1 | B4:.5 D5 D5:1 E5:.5 D5 B4:1 | G4:.5 B4 E5:1 D5:.5 B4 G4:1 | A4:.5 C5 E5:1.5 D5:.5 C5:1 |
        A4:.5 C5 C5:1 D5:.5 E5 F5:1 | E5:.5 D5 D5:1 C5:.5 D5 E5:1 | E5:.5 D5 C5:1 B4:.5 A4 G4:1 | C5:4 |
        """
        let springChords = ["C", "G", "Am", "F", "C", "G", "Am", "F,G", "F", "G", "Em", "Am", "F", "G", "Dm,G", "C"]
        let spring = song("spring", "Spring Light", "✨ Original · J-pop style", .original, bpm: 140,
            melody: springVerse + springChorus + springVerse + springChorus, chords: springChords + springChords, style: .pop, lead: 81)

        let night = """
        A4:.5 A4 C5 A4 r E5 D5 C5 | C5:.5 A4 F4 A4 r C5 D5 C5 | B4:.5 G4 D5 B4 r G4 A4 B4 | C5:1.5 B4:.5 C5 E5:1.5 |
        A4:.5 A4 C5 A4 r E5 D5 C5 | F5:.5 E5 D5 C5 r A4 C5 D5 | D5:.5 C5 B4 G4 r B4 C5 D5 | E5:2 G#4:2 |
        E5:.5 E5 E5 D5 C5 D5 E5:1 | D5:.5 D5 D5 C5 B4 C5 D5:1 | C5:.5 C5 C5 B4 A4 B4 C5 E5 | A5:1.5 G5:.5 E5:2 |
        F5:.5 E5 D5 C5 D5 C5 A4:1 | G4:.5 A4 B4 C5 D5 E5 D5:1 | E5:.5 D5 C5 B4 C5 B4 A4 G#4 | A4:4 |
        """
        let nightChords = ["Am", "F", "G", "C", "Am", "F", "G", "E", "F", "G", "Em", "Am", "F", "G", "E", "Am"]
        let nightTrain = song("night", "Night Train", "✨ Original · J-pop style", .original, bpm: 168,
            melody: night + night, chords: nightChords + nightChords, style: .pop, lead: 80)

        let blue = song("blue", "Blue Hour", "✨ Original · J-pop ballad", .original, bpm: 92,
            melody: """
            F#4:1 A4 D5:1.5 C#5:.5 | B4:1 A4:.5 F#4 A4:2 | G4:1 B4 A4 F#4 | E4:1.5 F#4:.5 G4:1 A4 |
            F#4:1 A4 D5 E5 | F#5:1.5 E5:.5 D5:1 C#5 | B4:1 D5 A4 G4:.5 F#4 | E4:1 G4:.5 F#4 E4:1 A4 |
            D5:1.5 E5:.5 F#5:1 E5:.5 D5 | D5:1 C#5 B4:2 | B4:.5 C#5 D5:1 A4 F#4 | G4:1 F#4 E4:2 |
            D5:1.5 E5:.5 F#5:1 A5 | G5:1 F#5:.5 E5 D5:2 | B4:1 D5 E5:1.5 D5:.5 | D5:4
            """,
            chords: ["D,A", "Bm,F#m", "G,D", "G,A", "D,A", "Bm,F#m", "G,D", "G,A", "D,A", "Bm,F#m", "G,D", "G,A", "D,A", "Bm,F#m", "G,A", "D"],
            style: .pad, lead: 0, acc: 48)

        let glow = """
        C5:.5 C5 D5 E5 G5:1 E5 | D5:.5 C5 D5 E5 E5:1 B4 | A4:.5 B4 C5 D5 F5:1 D5 | C5:2 r:1 G4:.5 A4 |
        C5:.5 C5 D5 E5 G5:1 A5 | G5:.5 E5 D5 C5 E5:1 D5 | C5:.5 A4 C5 D5 E5 D5 G4:1 | C5:3 r:1 |
        A5:1 G5:.5 E5 G5:1 C5 | G5:.5 G5 E5 D5 E5:2 | F5:1 E5:.5 D5 E5 D5 C5:1 | D5:.5 E5 D5:1 G4:2 |
        A5:1 G5:.5 E5 G5:1 C6 | B5:.5 A5 G5 E5 G5:2 | F5:.5 E5 D5 E5 F5 D5 B4:1 | C5:4 |
        """
        let glowChords = ["F,G", "Em,Am", "Dm,G", "C", "F,G", "Em,Am", "Dm,G", "C", "F,G", "Em,Am", "Dm,G", "C,G", "F,G", "Em,Am", "Dm,G", "C"]
        let glowStick = song("glow", "Glow Stick", "✨ Original · idol-pop style", .original, bpm: 176,
            melody: glow + glow, chords: glowChords + glowChords, style: .pop, lead: 62)

        return [ode, twinkle, elise, kleine, turca, minuet, canon, mountain, lullaby, sakura, jingle, spring, nightTrain, blue, glowStick]
    }()
}

// MARK: - Standard MIDI File writer

enum MIDIWriter {
    private static func vlq(_ value: Int) -> [UInt8] {
        var v = value, bytes = [UInt8(v & 0x7F)]
        v >>= 7
        while v > 0 { bytes.insert(UInt8(v & 0x7F) | 0x80, at: 0); v >>= 7 }
        return bytes
    }

    private struct Event { var tick: Int; var order: Int; var bytes: [UInt8] }

    private static func track(_ events: [Event]) -> [UInt8] {
        var out: [UInt8] = []
        var last = 0
        for e in events.sorted(by: { ($0.tick, $0.order) < ($1.tick, $1.order) }) {
            out += vlq(e.tick - last) + e.bytes
            last = e.tick
        }
        out += [0x00, 0xFF, 0x2F, 0x00]
        let n = out.count
        return Array("MTrk".utf8) + [UInt8(n >> 24 & 0xFF), UInt8(n >> 16 & 0xFF), UInt8(n >> 8 & 0xFF), UInt8(n & 0xFF)] + out
    }

    /// Accompaniment notes generated from the chord chart.
    static func accompaniment(_ song: Song) -> [MelodyNote] {
        var notes: [MelodyNote] = []
        for (bar, symbol) in song.chords.enumerated() {
            let parts = symbol.split(separator: ",")
            let segLen = song.beatsPerBar / Double(max(parts.count, 1))
            for (k, part) in parts.enumerated() {
                guard part != "-", let (root, tones) = Notation.chord(part) else { continue }
                let start = Double(bar) * song.beatsPerBar + Double(k) * segLen
                let bass = 36 + root
                let voicing = tones.map { t -> Int in var p = 48 + root + t; if p < 52 { p += 12 }; return p }
                func chord(_ b: Double, _ d: Double) { for p in voicing { notes.append(MelodyNote(beat: b, dur: d, pitch: p)) } }
                switch song.style {
                case .oompah:
                    var b = 0.0
                    while b < segLen - 0.01 {
                        if Int(b.rounded()) % 2 == 0 { notes.append(MelodyNote(beat: start + b, dur: 0.9, pitch: bass)) } else { chord(start + b, 0.8) }
                        b += 1
                    }
                case .waltz:
                    var b = 0.0
                    while b < segLen - 0.01 {
                        if b < 0.5 { notes.append(MelodyNote(beat: start + b, dur: 0.9, pitch: bass)) } else { chord(start + b, 0.7) }
                        b += 1
                    }
                case .arpeggio:
                    // Left-hand broken chord: root, fifth, octave (as in Für Elise).
                    notes += [MelodyNote(beat: start, dur: 0.25, pitch: bass),
                              MelodyNote(beat: start + 0.25, dur: 0.25, pitch: bass + 7),
                              MelodyNote(beat: start + 0.5, dur: 0.25, pitch: bass + 12)]
                case .pad:
                    notes.append(MelodyNote(beat: start, dur: segLen, pitch: bass))
                    chord(start, segLen)
                case .pop:
                    var b = 0.0
                    while b < segLen - 0.01 {
                        notes.append(MelodyNote(beat: start + b, dur: 0.45, pitch: bass))
                        if (Int((b * 2).rounded()) % 4) == 2 { chord(start + b, 0.5) }
                        b += 0.5
                    }
                case .drone:
                    notes.append(MelodyNote(beat: start, dur: segLen, pitch: bass))
                    notes.append(MelodyNote(beat: start, dur: segLen, pitch: bass + 19))
                case .staccato:
                    var b = 0.0
                    while b < segLen - 0.01 {
                        notes.append(MelodyNote(beat: start + b, dur: 0.35, pitch: bass + (Int(b) % 2 == 0 ? 0 : 7)))
                        b += 1
                    }
                }
            }
        }
        return notes
    }

    /// Melody (channel 0), accompaniment (channel 1) and a soft hi-hat on every beat (channel 10).
    static func data(for song: Song) -> Data {
        let ppq = 480
        let usPerBeat = Int(60_000_000 / song.bpm)
        var tempo = [Event(tick: 0, order: 0, bytes: [0xFF, 0x51, 0x03, UInt8(usPerBeat >> 16 & 0xFF), UInt8(usPerBeat >> 8 & 0xFF), UInt8(usPerBeat & 0xFF)])]
        tempo.append(Event(tick: 0, order: 0, bytes: [0xFF, 0x58, 0x04, UInt8(max(1, Int(song.beatsPerBar.rounded()))), 0x02, 0x18, 0x08]))
        func notes(_ list: [MelodyNote], channel: UInt8, program: Int, velocity: UInt8) -> [Event] {
            var ev = [Event(tick: 0, order: 0, bytes: [0xC0 | channel, UInt8(program & 0x7F)])]
            for n in list {
                let on = Int((n.beat * Double(ppq)).rounded()), off = Int(((n.beat + n.dur * 0.95) * Double(ppq)).rounded())
                ev.append(Event(tick: on, order: 2, bytes: [0x90 | channel, UInt8(n.pitch & 0x7F), velocity]))
                ev.append(Event(tick: max(on + 1, off), order: 1, bytes: [0x80 | channel, UInt8(n.pitch & 0x7F), 0]))
            }
            return ev
        }
        let end = song.melody.map { $0.beat + $0.dur }.max() ?? 0
        var hats: [MelodyNote] = []
        var b = 0.0
        while b < end { hats.append(MelodyNote(beat: b, dur: 0.1, pitch: 42)); b += 1 }
        var drumEvents: [Event] = []
        for h in hats {
            let on = Int(h.beat * Double(ppq))
            drumEvents += [Event(tick: on, order: 2, bytes: [0x99, 42, 34]), Event(tick: on + 40, order: 1, bytes: [0x89, 42, 0])]
        }
        var out = Array("MThd".utf8) + [0, 0, 0, 6, 0, 1, 0, 4, UInt8(ppq >> 8), UInt8(ppq & 0xFF)]
        out += track(tempo)
        out += track(notes(song.melody, channel: 0, program: song.melodyProgram, velocity: 104))
        out += track(notes(accompaniment(song), channel: 1, program: song.accProgram, velocity: 62))
        out += track(drumEvents)
        return Data(out)
    }
}

// MARK: - Standard MIDI File reader (for imported songs)

struct ParsedMIDI {
    struct Note { var track: Int; var channel: Int; var pitch: Int; var tick: Int; var endTick: Int; var start: Double; var end: Double; var beat: Double; var durBeats: Double }
    var notes: [Note]
    var firstTempoBPM: Double
}

enum MIDIReader {
    static func parse(_ data: Data) -> ParsedMIDI? {
        let b = [UInt8](data)
        var i = 0
        func u32() -> Int? { guard i + 4 <= b.count else { return nil }; defer { i += 4 }; return Int(b[i]) << 24 | Int(b[i + 1]) << 16 | Int(b[i + 2]) << 8 | Int(b[i + 3]) }
        func u16() -> Int? { guard i + 2 <= b.count else { return nil }; defer { i += 2 }; return Int(b[i]) << 8 | Int(b[i + 1]) }
        guard b.count > 14, String(bytes: b[0..<4], encoding: .ascii) == "MThd" else { return nil }
        i = 4
        guard let hlen = u32(), u16() != nil, let ntrks = u16(), let division = u16(), division & 0x8000 == 0 else { return nil }
        i = 8 + hlen
        let ppq = max(division, 1)
        var tempos: [(tick: Int, us: Int)] = []
        var raw: [ParsedMIDI.Note] = []
        for t in 0..<ntrks {
            guard i + 8 <= b.count, String(bytes: b[i..<i + 4], encoding: .ascii) == "MTrk" else { break }
            i += 4
            guard let len = u32() else { break }
            let end = min(b.count, i + len)
            var tick = 0, status: UInt8 = 0
            var open: [Int: [(Int, Int)]] = [:]           // key channel*128+pitch → start ticks
            func vlq() -> Int { var v = 0; while i < end { let c = b[i]; i += 1; v = v << 7 | Int(c & 0x7F); if c & 0x80 == 0 { break } }; return v }
            while i < end {
                tick += vlq()
                guard i < end else { break }
                var s = b[i]
                if s & 0x80 != 0 { i += 1; if s < 0xF0 { status = s } } else { s = status }
                switch s {
                case 0xFF:
                    guard i < end else { break }
                    let type = b[i]; i += 1
                    let l = vlq()
                    if type == 0x51 && l == 3 && i + 3 <= end { tempos.append((tick, Int(b[i]) << 16 | Int(b[i + 1]) << 8 | Int(b[i + 2]))) }
                    i += l
                case 0xF0, 0xF7:
                    i += vlq()
                default:
                    let kind = s & 0xF0, ch = Int(s & 0x0F)
                    let size = (kind == 0xC0 || kind == 0xD0) ? 1 : 2
                    guard i + size <= end else { i = end; break }
                    if kind == 0x90 || kind == 0x80 {
                        let pitch = Int(b[i]), vel = Int(b[i + 1])
                        let key = ch * 128 + pitch
                        if kind == 0x90 && vel > 0 { open[key, default: []].append((tick, vel)) }
                        else if var starts = open[key], !starts.isEmpty {
                            let (st, _) = starts.removeFirst()
                            open[key] = starts
                            raw.append(.init(track: t, channel: ch, pitch: pitch, tick: st, endTick: tick, start: 0, end: 0, beat: 0, durBeats: 0))
                        }
                    }
                    i += size
                }
            }
            i = end
        }
        tempos.sort { $0.tick < $1.tick }
        if tempos.first?.tick != 0 { tempos.insert((0, 500_000), at: 0) }
        func seconds(_ tick: Int) -> Double {
            var sec = 0.0
            for (k, tp) in tempos.enumerated() {
                let next = k + 1 < tempos.count ? tempos[k + 1].tick : Int.max
                if tick <= tp.tick { break }
                let span = min(tick, next) - tp.tick
                sec += Double(span) / Double(ppq) * Double(tp.us) / 1_000_000
                if tick <= next { break }
            }
            return sec
        }
        let notes = raw.map { n -> ParsedMIDI.Note in
            var m = n
            m.start = seconds(n.tick); m.end = seconds(n.endTick)
            m.beat = Double(n.tick) / Double(ppq); m.durBeats = Double(n.endTick - n.tick) / Double(ppq)
            return m
        }
        return ParsedMIDI(notes: notes.sorted { $0.start < $1.start }, firstTempoBPM: 60_000_000 / Double(tempos[0].us))
    }

    /// Picks the most melody-like part (busy, high, mostly one note at a time; drums excluded).
    static func melody(_ midi: ParsedMIDI) -> [ChartSource] {
        let groups = Dictionary(grouping: midi.notes.filter { $0.channel != 9 }, by: { $0.track * 16 + $0.channel })
        var bestKey: Int?
        var bestScore = -1.0
        for (key, notes) in groups where notes.count >= 12 {
            let mean = Double(notes.map(\.pitch).reduce(0, +)) / Double(notes.count)
            var overlaps = 0
            for k in 1..<notes.count where notes[k].start < notes[k - 1].end - 0.03 { overlaps += 1 }
            let mono = 1 - Double(overlaps) / Double(notes.count)
            let score = mean * min(1, Double(notes.count) / 60) * (0.4 + 0.6 * mono)
            if score > bestScore { bestScore = score; bestKey = key }
        }
        guard let key = bestKey, let notes = groups[key] else { return [] }
        var out: [ChartSource] = []
        for n in notes.sorted(by: { $0.start < $1.start }) {
            if let last = out.last, n.start - last.time < 0.03 {
                if n.pitch > last.pitch { out[out.count - 1] = ChartSource(time: n.start, beat: n.beat, pitch: n.pitch, durBeats: n.durBeats) }
                continue
            }
            out.append(ChartSource(time: n.start, beat: n.beat, pitch: n.pitch, durBeats: n.durBeats))
        }
        return out
    }
}

// MARK: - Chart builder: drum notes that follow the melody

enum ChartBuilder {
    static let difficulties = ["Easy", "Normal", "Hard"]

    typealias Note = (time: Double, ka: Bool, big: Bool)

    static func chart(_ song: Song, difficulty: Int) -> [Note] {
        if let a = song.audio { return AudioAnalyzer.chart(a, difficulty: difficulty) }
        let notes = chart(song.chartSource, accompaniment: difficulty >= 2 ? song.accompanimentSource : [], difficulty: difficulty)
        return markBig(notes, source: song.chartSource, barBeats: song.kind == .imported ? 4 : song.beatsPerBar)
    }

    /// Big notes (🟠 3 fingers / 🟣 4 fingers) go on the heavy moments: long notes that start a bar.
    private static func markBig(_ notes: [(time: Double, ka: Bool)], source: [ChartSource], barBeats: Double) -> [Note] {
        var heavy = Set<Int>()
        var downbeats = Set<Int>()
        for s in source {
            let bar = s.beat / barBeats
            let barPos = bar - floor(bar)
            let onDownbeat = barPos < 0.02 || barPos > 0.98
            if onDownbeat && s.durBeats >= 1.5 || s.durBeats >= 2.5 { heavy.insert(Int((s.time * 100).rounded())) }
            if onDownbeat && Int(bar.rounded()) % 4 == 0 { downbeats.insert(Int((s.time * 100).rounded())) }
        }
        // Tunes without long notes still get a big note on the downbeat of every fourth bar.
        let heavyInChart = notes.filter { heavy.contains(Int(($0.time * 100).rounded())) }.count
        if heavyInChart < 3 { heavy.formUnion(downbeats) }
        var lastBig = -10.0
        return notes.map { n in
            let isHeavy = heavy.contains(Int((n.time * 100).rounded()))
            guard isHeavy, n.time - lastBig >= 2.0 else { return (n.time, n.ka, false) }
            lastBig = n.time
            return (n.time, n.ka, true)
        }
    }

    /// One drum note per melody note (thinned for the difficulty). Red (don) falls on strong beats and low notes
    /// of the tune, blue (ka) on weak beats, off-beats and high notes. Hard also drums the accompaniment's rhythm
    /// in the gaps between melody notes.
    static func chart(_ source: [ChartSource], accompaniment: [ChartSource] = [], difficulty: Int) -> [(time: Double, ka: Bool)] {
        let d = min(max(difficulty, 0), 2)
        let minGap = [0.55, 0.3, 0.14][d]
        func onBeat(_ b: Double) -> Bool { let f = b - floor(b); return f < 0.1 || f > 0.9 }
        func strong(_ b: Double) -> Bool { onBeat(b) && Int(b.rounded()) % 2 == 0 }
        var kept: [ChartSource] = []
        for s in source.sorted(by: { $0.time < $1.time }) where s.time >= 0.6 {
            if d == 0 && !onBeat(s.beat) && s.durBeats < 1 { continue }
            if let last = kept.last, s.time - last.time < minGap { continue }
            kept.append(s)
        }
        guard !kept.isEmpty else { return [] }
        let sorted = kept.map(\.pitch).sorted()
        let median = sorted[sorted.count / 2]
        var notes = kept.map { s -> (time: Double, ka: Bool) in
            let don = strong(s.beat) || (onBeat(s.beat) && s.pitch < median) || s.durBeats >= 1.5
            return (s.time, !don)
        }
        // If the tune makes the colours lopsided, fall back to following the melody's pitch.
        let reds = notes.filter { !$0.ka }.count
        if reds < notes.count / 4 || reds > notes.count * 80 / 100 {
            notes = kept.map { ($0.time, $0.pitch > median) }
        }
        // Hard: add accompaniment hits that fit between melody notes (bass on strong beats = red, the rest blue).
        if !accompaniment.isEmpty {
            var times = notes.map(\.time)
            for a in accompaniment where a.time >= 0.6 {
                let i = times.firstIndex { $0 > a.time } ?? times.count
                let before = i > 0 ? a.time - times[i - 1] : .infinity
                let after = i < times.count ? times[i] - a.time : .infinity
                guard before >= minGap * 1.5, after >= minGap * 1.5 else { continue }
                notes.insert((a.time, !strong(a.beat)), at: i)
                times.insert(a.time, at: i)
            }
        }
        return notes
    }
}

// MARK: - Playback

enum SoundBank {
    static let url: URL? = {
        let u = URL(fileURLWithPath: "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")
        return FileManager.default.fileExists(atPath: u.path) ? u : nil
    }()
}

final class MusicPlayer {
    static let shared = MusicPlayer()
    private var player: AVMIDIPlayer?
    private var audioPlayer: AVAudioPlayer?
    private var section: (start: Double, end: Double) = (0, 0)
    private var fading = false

    /// Starts the song from the beginning; returns false if sound is off or the file can't be played.
    @discardableResult
    func play(_ song: Song) -> Bool {
        stop()
        guard Sound.enabled else { return false }
        if let url = song.fileURL, let a = song.audio {
            // Your own recording: play just the chosen section, fading out at its end.
            guard let p = try? AVAudioPlayer(contentsOf: url) else { return false }
            p.currentTime = a.start
            p.volume = 1
            p.prepareToPlay()
            p.play()
            audioPlayer = p
            section = (a.start, a.end)
            fading = false
            return true
        }
        do {
            let p = song.fileURL != nil ? try AVMIDIPlayer(contentsOf: song.fileURL!, soundBankURL: SoundBank.url)
                                        : try AVMIDIPlayer(data: MIDIWriter.data(for: song), soundBankURL: SoundBank.url)
            p.prepareToPlay()
            p.play(nil)
            player = p
            return true
        } catch {
            return false
        }
    }

    var isPlaying: Bool { (player?.isPlaying ?? false) || (audioPlayer?.isPlaying ?? false) }
    var currentTime: Double {
        if let a = audioPlayer { return a.currentTime - section.start }
        return player?.currentPosition ?? 0
    }

    /// Ends an audio section on time with a short fade.
    func update() {
        guard let a = audioPlayer, a.isPlaying else { return }
        if !fading && a.currentTime >= section.end - 1.5 { a.setVolume(0, fadeDuration: 1.5); fading = true }
        if a.currentTime >= section.end { a.stop() }
    }

    func stop() {
        player?.stop()
        player = nil
        audioPlayer?.stop()
        audioPlayer = nil
    }
}

/// Taiko-style hits from the General MIDI percussion kit.
final class DrumKit {
    static let shared = DrumKit()
    private let engine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()
    private var ready = false
    private var tried = false

    func prepare() {
        guard !tried, let bank = SoundBank.url else { return }
        tried = true
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        do {
            try sampler.loadSoundBankInstrument(at: bank, program: 0, bankMSB: UInt8(kAUSampler_DefaultPercussionBankMSB),
                                                bankLSB: UInt8(kAUSampler_DefaultBankLSB))
            try engine.start()
            ready = true
        } catch { ready = false }
    }

    func hit(ka: Bool, big: Bool = false) {
        guard Sound.enabled else { return }
        prepare()
        guard ready else { Sound.play(ka ? "Tink" : "Bottle", volume: 0.3); return }
        var notes: [UInt8] = ka ? [76, 37] : [41, 36]      // ka: wood block + rim; don: floor tom + kick
        if big { notes.append(ka ? 55 : 49) }               // big notes add a splash / crash
        for (k, n) in notes.enumerated() { sampler.startNote(n, withVelocity: k == 0 ? 118 : 84, onChannel: 9) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [sampler] in notes.forEach { sampler.stopNote($0, onChannel: 9) } }
    }
}

// MARK: - Library (built-ins + imported MIDI files)

final class SongLibrary {
    static let shared = SongLibrary()
    private(set) var songs: [Song] = BuiltInSongs.all

    static var folderURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("TouchBarFun/Songs", isDirectory: true)
    }
    var folder: URL { SongLibrary.folderURL }

    init() { reloadImports() }

    func reloadImports() {
        songs = BuiltInSongs.all
        guard SaveData.persistenceEnabled,
              let files = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) else { return }
        for url in files.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let ext = url.pathExtension.lowercased()
            if ["mid", "midi", "kar"].contains(ext), let song = SongLibrary.load(url) { songs.append(song) }
            if AudioAnalyzer.audioExtensions.contains(ext), let song = SongLibrary.loadAudio(url) { songs.append(song) }
        }
    }

    private static func infoURL(_ audio: URL) -> URL { audio.appendingPathExtension("drumbeat.json") }

    /// An audio file plus its saved section and analysis (analysed on first load).
    static func loadAudio(_ url: URL) -> Song? {
        var info = (try? Data(contentsOf: infoURL(url))).flatMap { try? JSONDecoder().decode(AudioSongInfo.self, from: $0) }
            ?? AudioSongInfo(title: url.deletingPathExtension().lastPathComponent, subtitle: "🎧 Your audio",
                             start: 0, end: min(AudioAnalyzer.duration(url) ?? 0, 180), analysis: nil)
        if info.analysis == nil || info.analysis?.start != info.start || info.analysis?.end != info.end
            || info.analysis?.version != AudioAnalysis.currentVersion {
            info.analysis = AudioAnalyzer.analyze(url, start: info.start, end: info.end)
            if let data = try? JSONEncoder().encode(info) { try? data.write(to: infoURL(url)) }
        }
        guard let a = info.analysis, a.onsets.count >= 8 else { return nil }
        var song = Song(id: "audio:" + url.lastPathComponent, title: info.title, subtitle: info.subtitle, kind: .audio, bpm: a.bpm)
        song.fileURL = url
        song.audio = a
        return song
    }

    /// Copies an audio file into the songs folder with its title and the section to play.
    func importAudio(_ url: URL, title: String, subtitle: String, start: Double, end: Double) -> Song? {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let dest = folder.appendingPathComponent(url.lastPathComponent)
        if dest != url {
            try? FileManager.default.removeItem(at: dest)
            guard (try? FileManager.default.copyItem(at: url, to: dest)) != nil else { return nil }
        }
        let info = AudioSongInfo(title: title, subtitle: subtitle, start: start, end: end, analysis: nil)
        if let data = try? JSONEncoder().encode(info) { try? data.write(to: SongLibrary.infoURL(dest)) }
        guard let song = SongLibrary.loadAudio(dest) else { return nil }
        reloadImports()
        return song
    }

    static func load(_ url: URL) -> Song? {
        guard let data = try? Data(contentsOf: url), let midi = MIDIReader.parse(data) else { return nil }
        let melody = MIDIReader.melody(midi)
        guard melody.count >= 8 else { return nil }
        let title = url.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " ")
        var song = Song(id: "file:" + url.lastPathComponent, title: title, subtitle: "📁 Your MIDI · \(melody.count) melody notes",
                        kind: .imported, bpm: midi.firstTempoBPM)
        song.fileURL = url
        song.imported = melody
        return song
    }

    /// Copies a MIDI file into the songs folder and adds it to the list.
    func importFile(_ url: URL) -> Song? {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let dest = folder.appendingPathComponent(url.lastPathComponent)
        if dest != url {
            try? FileManager.default.removeItem(at: dest)
            guard (try? FileManager.default.copyItem(at: url, to: dest)) != nil else { return nil }
        }
        guard let song = SongLibrary.load(dest) else { try? FileManager.default.removeItem(at: dest); return nil }
        reloadImports()
        return song
    }
}
