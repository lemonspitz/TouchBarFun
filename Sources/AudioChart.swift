import AVFoundation
import Accelerate

// Drum charts for the user's own audio files (MP3, M4A, WAV…): the recording is analysed for its tempo and its
// rhythmic hits, so the notes land on what you actually hear. Low hits (kick, bass) are red, bright ones (snare,
// hats, claps) blue. Nothing from the recording is copied into the app — the file just plays from your disk.

struct AudioOnset: Codable { var t: Double; var strength: Double; var lowRatio: Double }

struct AudioAnalysis: Codable {
    var start: Double
    var end: Double
    var bpm: Double
    var beatOffset: Double          // seconds from `start` to the first beat
    var onsets: [AudioOnset]        // times relative to `start`
    var version: Int? = AudioAnalysis.currentVersion
    static let currentVersion = 2
}

/// Sidecar settings saved next to an imported audio file.
struct AudioSongInfo: Codable {
    var title: String
    var subtitle: String
    var start: Double
    var end: Double
    var analysis: AudioAnalysis?
}

enum AudioAnalyzer {
    static let audioExtensions = ["mp3", "m4a", "aac", "wav", "aif", "aiff", "caf"]

    static func duration(_ url: URL) -> Double? {
        guard let f = try? AVAudioFile(forReading: url) else { return nil }
        return Double(f.length) / f.processingFormat.sampleRate
    }

    /// Mono samples of the [start, end] section.
    private static func samples(_ url: URL, start: Double, end: Double) -> ([Float], Double)? {
        guard let file = try? AVAudioFile(forReading: url) else { return nil }
        let sr = file.processingFormat.sampleRate
        let first = AVAudioFramePosition(max(0, start) * sr)
        let last = min(file.length, AVAudioFramePosition(end * sr))
        guard last > first else { return nil }
        file.framePosition = first
        var mono = [Float]()
        mono.reserveCapacity(Int(last - first))
        let chunk: AVAudioFrameCount = 65536
        guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: chunk) else { return nil }
        var remaining = last - first
        while remaining > 0 {
            let want = AVAudioFrameCount(min(Int64(chunk), remaining))
            do { try file.read(into: buffer, frameCount: want) } catch { break }
            let n = Int(buffer.frameLength)
            if n == 0 { break }
            let channels = Int(buffer.format.channelCount)
            guard let data = buffer.floatChannelData else { break }
            for i in 0..<n {
                var s: Float = 0
                for c in 0..<channels { s += data[c][i] }
                mono.append(s / Float(channels))
            }
            remaining -= AVAudioFramePosition(n)
        }
        return (mono, sr)
    }

    static func analyze(_ url: URL, start: Double, end: Double) -> AudioAnalysis? {
        guard let (x, sr) = samples(url, start: start, end: end), x.count > 4096 else { return nil }
        let n = 1024, log2n = vDSP_Length(10)
        let hop = Int(sr * 0.01)                         // 10 ms frames
        guard let setup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { return nil }
        defer { vDSP_destroy_fftsetup(setup) }
        var window = [Float](repeating: 0, count: n)
        vDSP_hann_window(&window, vDSP_Length(n), Int32(vDSP_HANN_NORM))
        let binHz = sr / Double(n)
        let lowBins = max(1, Int(40 / binHz))...max(2, Int(180 / binHz))
        let highBins = Int(2000 / binHz)...min(n / 2 - 1, Int(9000 / binHz))

        var prev = [Float](repeating: 0, count: n / 2)
        var lowFlux: [Float] = [], highFlux: [Float] = [], allFlux: [Float] = []
        var frame = [Float](repeating: 0, count: n)
        var re = [Float](repeating: 0, count: n / 2), im = [Float](repeating: 0, count: n / 2)
        var pos = 0
        while pos + n <= x.count {
            x.withUnsafeBufferPointer { p in vDSP_vmul(p.baseAddress! + pos, 1, window, 1, &frame, 1, vDSP_Length(n)) }
            var mags = [Float](repeating: 0, count: n / 2)
            re.withUnsafeMutableBufferPointer { rp in
                im.withUnsafeMutableBufferPointer { ip in
                    var split = DSPSplitComplex(realp: rp.baseAddress!, imagp: ip.baseAddress!)
                    frame.withUnsafeBufferPointer { fp in
                        fp.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: n / 2) { vDSP_ctoz($0, 2, &split, 1, vDSP_Length(n / 2)) }
                    }
                    vDSP_fft_zrip(setup, &split, 1, log2n, FFTDirection(FFT_FORWARD))
                    vDSP_zvabs(&split, 1, &mags, 1, vDSP_Length(n / 2))
                }
            }
            var lf: Float = 0, hf: Float = 0, af: Float = 0
            for k in 1..<(n / 2) {
                let m = log1pf(100 * mags[k])
                let d = max(0, m - prev[k])
                prev[k] = m
                af += d
                if lowBins.contains(k) { lf += d }
                if highBins.contains(k) { hf += d }
            }
            lowFlux.append(lf); highFlux.append(hf); allFlux.append(af)
            pos += hop
        }
        guard allFlux.count > 200 else { return nil }
        let frameSec = Double(hop) / sr

        // Tempo: autocorrelation of the onset envelope between 70 and 180 BPM (gently preferring 90–140).
        let env = allFlux.map { Double($0) }
        let mean = env.reduce(0, +) / Double(env.count)
        let centered = env.map { $0 - mean }
        var bestLag = 50, bestScore = -Double.infinity
        for lag in Int(60 / 180 / frameSec)...Int(60 / 70 / frameSec) {
            var s = 0.0
            for i in 0..<(centered.count - lag) { s += centered[i] * centered[i + lag] }
            let bpm = 60 / (Double(lag) * frameSec)
            s *= exp(-pow(log2(bpm / 115), 2) * 0.7)
            if s > bestScore { bestScore = s; bestLag = lag }
        }
        let beatSec = Double(bestLag) * frameSec
        // Beat phase: the offset whose beat grid collects the most onset energy.
        var bestPhase = 0, bestPhaseScore = -1.0
        for o in 0..<bestLag {
            var s = 0.0, i = o
            while i < env.count { s += env[i]; i += bestLag }
            if s > bestPhaseScore { bestPhaseScore = s; bestPhase = o }
        }

        // Onsets: peaks of the envelope above a moving threshold.
        let lowMean = Double(lowFlux.reduce(0, +)) / Double(lowFlux.count) + 1e-6
        let highMean = Double(highFlux.reduce(0, +)) / Double(highFlux.count) + 1e-6
        var onsets: [AudioOnset] = []
        let w = 25
        var lastT = -1.0
        let maxEnv = env.max() ?? 1
        for i in 3..<(env.count - 3) {
            let v = env[i]
            guard v >= env[i - 1], v >= env[i + 1], v >= env[i - 2], v >= env[i + 2], v >= env[i - 3], v >= env[i + 3] else { continue }
            let lo = max(0, i - w), hi = min(env.count, i + w)
            let local = env[lo..<hi]
            let m = local.reduce(0, +) / Double(local.count)
            let sd = sqrt(local.reduce(0) { $0 + ($1 - m) * ($1 - m) } / Double(local.count))
            guard v > m + 0.5 * sd else { continue }
            let t = Double(i) * frameSec
            guard t - lastT > 0.07 else { continue }
            lastT = t
            let l = Double(lowFlux[i]) / lowMean, h = Double(highFlux[i]) / highMean
            onsets.append(AudioOnset(t: t, strength: v / maxEnv, lowRatio: l / (l + h + 1e-6)))
        }
        let (bpm, offset) = refine(onsets, bpm: 60 / beatSec)
        _ = bestPhase
        return AudioAnalysis(start: start, end: end, bpm: bpm, beatOffset: offset, onsets: onsets)
    }

    /// The autocorrelation tempo is only as fine as the 10 ms frames, which is enough to drift off the beat over a
    /// minute and a half. Search nearby tempos in 0.05 BPM steps for the grid the hits fit best.
    private static func refine(_ onsets: [AudioOnset], bpm rough: Double) -> (Double, Double) {
        let strong = onsets.filter { $0.strength > 0.12 }
        guard strong.count > 20 else { return (rough, 0) }
        func fit(_ bpm: Double, _ phase: Double, _ division: Double) -> Double {
            let step = 60 / bpm / division
            var s = 0.0
            for o in strong {
                let x = (o.t - phase) / step
                let dev = x - x.rounded()
                s += o.strength * exp(-dev * dev / 0.02)
            }
            return s
        }
        var best = (score: -1.0, bpm: rough, phase: 0.0)
        var bpm = rough * 0.97
        while bpm <= rough * 1.03 {
            let step = 60 / bpm / 2
            var phase = 0.0
            while phase < step {
                let s = fit(bpm, phase, 2)
                if s > best.score { best = (s, bpm, phase) }
                phase += 0.005
            }
            bpm += 0.05
        }
        // The eighth-note grid fits either beat or off-beat; take whichever makes the beats stronger.
        let beat = 60 / best.bpm
        let a = fit(best.bpm, best.phase, 1), b = fit(best.bpm, best.phase + beat / 2, 1)
        return (best.bpm, a >= b ? best.phase : (best.phase + beat / 2).truncatingRemainder(dividingBy: beat))
    }

    /// Drum notes from the analysed hits, snapped to the beat grid and thinned by difficulty.
    static func chart(_ a: AudioAnalysis, difficulty: Int) -> [(time: Double, ka: Bool, big: Bool)] {
        let d = min(max(difficulty, 0), 2)
        let beat = 60 / a.bpm
        let division = [1.0, 2.0, 4.0][d]             // quarter, eighth or sixteenth grid
        let step = beat / division
        let minGap = [0.5, 0.27, 0.14][d]
        let length = a.end - a.start
        // Snap each hit to the grid; keep the strongest hit per grid slot.
        var slots: [Int: AudioOnset] = [:]
        for o in a.onsets where o.t > 0.8 && o.t < length - 0.4 {
            let k = Int(((o.t - a.beatOffset) / step).rounded())
            let snapped = a.beatOffset + Double(k) * step
            guard abs(snapped - o.t) < step * 0.25 else { continue }   // only hits that really land on the beat grid
            if slots[k].map({ o.strength > $0.strength }) ?? true {
                slots[k] = AudioOnset(t: snapped, strength: o.strength, lowRatio: o.lowRatio)
            }
        }
        // Strongest hits first, keeping notes at least `minGap` apart.
        let threshold = [0.18, 0.1, 0.06][d]
        var accepted: [AudioOnset] = []
        for o in slots.values.sorted(by: { $0.strength > $1.strength }) where o.strength >= threshold {
            if accepted.contains(where: { abs($0.t - o.t) < minGap - 0.001 }) { continue }
            accepted.append(o)
        }
        accepted.sort { $0.t < $1.t }
        guard !accepted.isEmpty else { return [] }
        // Red = bass-heavy hit, blue = bright hit; split at the song's own median if it leans one way.
        var cut = 0.5
        let reds = accepted.filter { $0.lowRatio >= cut }.count
        if reds < accepted.count / 4 || reds > accepted.count * 4 / 5 {
            let sorted = accepted.map(\.lowRatio).sorted()
            cut = sorted[sorted.count * 45 / 100]
        }
        // Big notes on the heaviest on-beat hits (bass → 🟠 orange, bright → 🟣 purple), at least ~2 s apart.
        let strengths = accepted.map(\.strength).sorted()
        let heavy = strengths[min(strengths.count - 1, strengths.count * 85 / 100)]
        var lastBig = -10.0
        return accepted.map { o in
            let k = (o.t - a.beatOffset) / beat
            let onBeat = abs(k - k.rounded()) < 0.05
            let big = onBeat && o.strength >= heavy && o.t - lastBig >= 1.8
            if big { lastBig = o.t }
            return (o.t, o.lowRatio < cut, big)
        }
    }
}
