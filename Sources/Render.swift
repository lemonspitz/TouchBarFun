import AppKit

/// Draws the world into a context whose unit space is World.W x World.H (origin bottom-left).
extension World {
    func render(in ctx: CGContext) {
        ctx.interpolationQuality = .none
        ctx.setShouldAntialias(true)
        drawBackground(ctx)

        let g = World.ground
        // Shadows + items
        let drawnItems = (mode == .runner ? obstacles : items)
        for it in drawnItems {
            if mode == .catcher {
                ctx.setFillColor(NSColor(white: 0, alpha: 0.35).cgColor)
                ctx.fillEllipse(in: CGRect(x: it.x - 3, y: g - 0.6, width: 6, height: 1.4))
            }
            drawItem(ctx, it.kind, x: it.x, y: g + it.y, scale: it.scale, flip: it.vx < 0)
        }
        if mode == .popper { drawBubbles(ctx) }
        renderGameBehindPet(ctx)

        drawPet(ctx)
        renderGameFront(ctx)

        drawParticles(ctx)
        drawHUD(ctx)

        if flash > 0 {
            ctx.setFillColor(hex(0xE84A5F, CGFloat(flash) * 1.2).cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: World.W, height: World.H))
        }
    }

    // MARK: Background

    private func drawBackground(_ ctx: CGContext) { drawEnvironment(ctx) }

    // MARK: Sprites

    func drawItem(_ ctx: CGContext, _ kind: ItemKind, x: CGFloat, y: CGFloat, scale: CGFloat, flip: Bool = false) {
        let img = kind.image
        let w = CGFloat(img.width) * scale, h = CGFloat(img.height) * scale
        drawImage(ctx, img, CGRect(x: x - w / 2, y: y, width: w, height: h), flip: flip)
    }

    func drawImage(_ ctx: CGContext, _ img: CGImage, _ r: CGRect, flip: Bool) {
        ctx.saveGState()
        if flip {
            ctx.translateBy(x: r.maxX, y: r.minY)
            ctx.scaleBy(x: -1, y: 1)
            ctx.draw(img, in: CGRect(x: 0, y: 0, width: r.width, height: r.height))
        } else {
            ctx.draw(img, in: r)
        }
        ctx.restoreGState()
    }

    private func drawPet(_ ctx: CGContext) {
        let s = species
        let frame: Int
        if pet.moving || ((mode == .runner || mode == .race) && phase == .playing && pet.y <= 0 && (mode != .race || race.v > 15)) {
            frame = Int(pet.walkPhase * 2) % 2 == 0 ? 0 : 1
        } else if s.legStyle == .biped && pet.eatTimer > 0 {
            frame = Int(pet.eatTimer * 5) % 2
        } else {
            frame = mode == .runner && pet.y > 0 ? 1 : 0
        }
        let closed = save.sleeping || pet.blinkTimer < 0 || pet.happyTimer > 0
        let img = s.image(frame: frame, closedEyes: closed)
        let size = petSize
        var x = pet.x - size.width / 2
        if pet.shakeTimer > 0 { x += sin(CGFloat(t) * 60) * 1.5 }
        var y = World.ground + pet.y - petScale   // feet touch the ground line
        var h = size.height
        if save.sleeping && mode == .pet {          // breathing
            h *= 0.94 + 0.03 * CGFloat(sin(t * 2.5))
        }
        if pet.eatTimer > 0 { y -= CGFloat(abs(sin(t * 12))) * 0.8 }

        // Shadow
        ctx.setFillColor(NSColor(white: 0, alpha: 0.3).cgColor)
        let shadowW = size.width * 0.7 * max(0.5, 1 - pet.y / 30)
        ctx.fillEllipse(in: CGRect(x: pet.x - shadowW / 2, y: World.ground - 0.8, width: shadowW, height: 1.8))

        drawImage(ctx, img, CGRect(x: x, y: y, width: size.width, height: h), flip: pet.facing < 0)

        if pet.carryingBall {
            drawItem(ctx, .ball, x: pet.x + pet.facing * size.width * 0.45, y: y + size.height * 0.25, scale: 1.2)
        }

        // Thought bubble when hungry or tired.
        if mode == .pet && !save.sleeping && pet.thoughtTimer < 0 && pet.eatTimer <= 0 {
            let want: ItemKind? = save.fullness < 30 ? s.food : (save.happiness < 30 ? .ball : nil)
            if let want = want {
                let bx = pet.x + pet.facing * 14, by = World.H - 10
                ctx.setFillColor(NSColor(white: 1, alpha: 0.9).cgColor)
                ctx.fillEllipse(in: CGRect(x: bx - 7, y: by - 1, width: 14, height: 11))
                ctx.fillEllipse(in: CGRect(x: bx - pet.facing * 6 - 1.5, y: by - 3, width: 3, height: 3))
                drawItem(ctx, want, x: bx, y: by + 0.5, scale: 1.0)
            }
        }
    }

    private func drawBubbles(_ ctx: CGContext) {
        for b in bubbles {
            let rect = CGRect(x: b.x - b.r, y: b.y - b.r, width: b.r * 2, height: b.r * 2)
            let (fill, stroke): (NSColor, NSColor)
            switch b.kind {
            case .normal: (fill, stroke) = (hex(0x7FC8FF, 0.22), hex(0xBFE6FF, 0.9))
            case .gold: (fill, stroke) = (hex(0xFFD23F, 0.3), hex(0xFFE58A, 1))
            case .spiky: (fill, stroke) = (hex(0xB04AE8, 0.35), hex(0xD9A3FF, 1))
            }
            ctx.setFillColor(fill.cgColor)
            ctx.fillEllipse(in: rect)
            ctx.setStrokeColor(stroke.cgColor)
            ctx.setLineWidth(0.8)
            if b.kind == .spiky {
                let n = 8
                ctx.beginPath()
                for k in 0...(n * 2) {
                    let a = CGFloat(k) / CGFloat(n * 2) * .pi * 2 + CGFloat(t)
                    let rr = k % 2 == 0 ? b.r + 1.6 : b.r
                    let p = CGPoint(x: b.x + cos(a) * rr, y: b.y + sin(a) * rr)
                    if k == 0 { ctx.move(to: p) } else { ctx.addLine(to: p) }
                }
                ctx.strokePath()
            } else {
                ctx.strokeEllipse(in: rect)
            }
            ctx.setFillColor(NSColor(white: 1, alpha: 0.8).cgColor)
            ctx.fillEllipse(in: CGRect(x: b.x - b.r * 0.5, y: b.y + b.r * 0.25, width: b.r * 0.4, height: b.r * 0.4))
        }
    }

    private func drawParticles(_ ctx: CGContext) {
        for p in particles {
            let a = CGFloat(min(1, p.life / p.maxLife * 2))
            ctx.setAlpha(a)
            switch p.kind {
            case .item(let k):
                drawItem(ctx, k, x: p.x, y: p.y, scale: 1.1)
            case .spark(let c):
                ctx.setFillColor(c.cgColor)
                ctx.fill(CGRect(x: p.x, y: p.y, width: 1.2, height: 1.2))
            case .z:
                text("z", at: CGPoint(x: p.x, y: p.y), size: 5 + CGFloat(1 - p.life / p.maxLife) * 3, color: hex(0xBFE6FF), ctx: ctx)
            case .text(let s, let c):
                text(s, at: CGPoint(x: p.x, y: p.y), size: 7, color: c, ctx: ctx, center: true)
            case .half(let k, let left):
                let img = k.image
                let w = CGFloat(img.width) * p.size, h = CGFloat(img.height) * p.size
                let r = CGRect(x: p.x - w / 2, y: p.y, width: w, height: h)
                ctx.saveGState()
                ctx.clip(to: CGRect(x: left ? r.minX : r.midX, y: r.minY, width: w / 2, height: h))
                ctx.translateBy(x: r.midX, y: r.midY)
                ctx.rotate(by: CGFloat(1 - p.life / p.maxLife) * (left ? 1.2 : -1.2))
                ctx.draw(img, in: CGRect(x: -w / 2, y: -h / 2, width: w, height: h))
                ctx.restoreGState()
            }
            ctx.setAlpha(1)
        }
    }

    // MARK: HUD

    private func drawHUD(_ ctx: CGContext) {
        let x0 = World.W - World.hudWidth + 4
        if mode == .pet {
            ctx.setFillColor(NSColor(white: 0, alpha: 0.35).cgColor)
            ctx.fill(CGRect(x: World.W - World.hudWidth, y: 0, width: World.hudWidth, height: World.H))
            let bars: [(String, Double, NSColor)] = [
                ("🍖", save.fullness, hex(0xF0892B)),
                ("❤️", save.happiness, hex(0xE84A5F)),
                ("⚡️", save.energy, hex(0xFFD23F)),
            ]
            for (i, b) in bars.enumerated() {
                let y = World.H - 9.5 - CGFloat(i) * 9
                text(b.0, at: CGPoint(x: x0, y: y - 0.5), size: 6, color: .white, ctx: ctx)
                let bx = x0 + 10, bw: CGFloat = 54
                ctx.setFillColor(NSColor(white: 1, alpha: 0.15).cgColor)
                ctx.fill(CGRect(x: bx, y: y + 1, width: bw, height: 4))
                ctx.setFillColor((b.1 < 25 ? hex(0xE84A5F) : b.2).cgColor)
                ctx.fill(CGRect(x: bx, y: y + 1, width: bw * CGFloat(b.1 / 100), height: 4))
            }
            text("\(petName) · Lv \(level) · ⭐️\(save.stars)", at: CGPoint(x: 4, y: World.H - 8), size: 5.5,
                 color: NSColor(white: 1, alpha: 0.75), ctx: ctx)
            return
        }

        if mode.isMultiplayer { drawMPHUD(ctx); return }
        if mode == .rhythm && phase != .playing { drawSongMenu(ctx); return }
        if mode == .rhythm {   // exit lives on the left in Drum Beat; score sits on the right
            text("\(gameHUDText ?? "")    🥁 \(score)", at: CGPoint(x: World.W - 4, y: World.H - 9), size: 6.5, color: .white, ctx: ctx, alignRight: true)
            return
        }

        // Game HUD
        text("\(mode.emoji) \(score)", at: CGPoint(x: 4, y: World.H - 9), size: 7, color: .white, ctx: ctx)
        let best = save.best[mode.rawValue] ?? 0
        var right = "Best \(best)"
        if mode.isTimed && phase == .playing { right = "⏱ \(Int(ceil(timeLeft)))   " + right }
        if let extra = gameHUDText, phase == .playing { right = extra + "   " + right }
        text(right, at: CGPoint(x: World.W - 26, y: World.H - 9), size: 6, color: NSColor(white: 1, alpha: 0.8), ctx: ctx, alignRight: true)
        // Exit button
        ctx.setFillColor(NSColor(white: 1, alpha: 0.18).cgColor)
        ctx.fillEllipse(in: CGRect(x: World.W - 19, y: World.H / 2 - 7, width: 14, height: 14))
        text("✕", at: CGPoint(x: World.W - 12, y: World.H / 2 - 4.5), size: 7, color: .white, ctx: ctx, center: true)

        if phase != .playing {
            ctx.setFillColor(NSColor(white: 0, alpha: 0.55).cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: World.W - 22, height: World.H))
            let line1: String, line2: String
            if phase == .ready {
                line1 = "\(mode.emoji) \(mode.title)"
                line2 = "\(mode.hint) — tap to start!"
            } else {
                let isBest = score >= best && score > 0
                let headline = resultText.map { $0 + "  ·  " } ?? ""
                line1 = isBest ? "\(headline)🏆 New best: \(score)!" : "\(headline)Score \(score)  ·  Best \(best)"
                line2 = "+\(lastReward) ⭐️   Tap to play again"
            }
            text(line1, at: CGPoint(x: (World.W - 22) / 2, y: 15.5), size: 8.5, color: .white, ctx: ctx, center: true, bold: true)
            text(line2, at: CGPoint(x: (World.W - 22) / 2, y: 5), size: 6.5, color: NSColor(white: 1, alpha: 0.8), ctx: ctx, center: true)
        }
    }

    func text(_ s: String, at p: CGPoint, size: CGFloat, color: NSColor, ctx: CGContext,
              center: Bool = false, alignRight: Bool = false, bold: Bool = false) {
        let img = RenderCache.text(s, size: size, color: color, bold: bold)
        let w = CGFloat(img.width) / RenderCache.textScale, h = CGFloat(img.height) / RenderCache.textScale
        var x = p.x
        if center { x -= w / 2 } else if alignRight { x -= w }
        ctx.interpolationQuality = .high
        ctx.draw(img, in: CGRect(x: x, y: p.y - RenderCache.textPad, width: w, height: h))
        ctx.interpolationQuality = .none
    }
}

/// Rasterised text and sky gradients, reused across frames so a 60 fps redraw is mostly image blits.
enum RenderCache {
    static let textScale: CGFloat = 6
    static let textPad: CGFloat = 1
    private static var texts: [String: CGImage] = [:]
    private static var skies: [String: CGImage] = [:]

    static func text(_ s: String, size: CGFloat, color: NSColor, bold: Bool) -> CGImage {
        let key = "\(s)|\(size)|\(color.description)|\(bold)"
        if let img = texts[key] { return img }
        if texts.count > 400 { texts.removeAll() }
        let font = bold ? NSFont.systemFont(ofSize: size, weight: .heavy) : NSFont.systemFont(ofSize: size, weight: .semibold)
        let str = NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: color])
        let sz = str.size()
        let w = Int(ceil((sz.width + 2) * textScale)), h = Int(ceil((sz.height + textPad) * textScale))
        let ctx = CGContext(data: nil, width: max(w, 1), height: max(h, 1), bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.scaleBy(x: textScale, y: textScale)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
        str.draw(at: CGPoint(x: 0, y: textPad))
        NSGraphicsContext.restoreGraphicsState()
        let img = ctx.makeImage()!
        texts[key] = img
        return img
    }

    static func sky(_ key: String, top: NSColor, bottom: NSColor) -> CGImage {
        if let img = skies[key] { return img }
        let ctx = CGContext(data: nil, width: 4, height: 120, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let grad = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                              colors: [bottom.cgColor, top.cgColor] as CFArray, locations: [0, 1])!
        ctx.drawLinearGradient(grad, start: .zero, end: CGPoint(x: 0, y: 120), options: [])
        let img = ctx.makeImage()!
        skies[key] = img
        return img
    }
}

struct SeededRandom {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> Int {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Int((state >> 33) & 0x7FFFFFFF)
    }
}

// MARK: - View

final class PetSceneView: NSView {
    let world: World

    /// The Touch Bar copy is `flexible`: it stretches to fill the bar and sets the world's width.
    /// The window copy keeps a fixed size and letterboxes the world.
    let flexible: Bool

    init(world: World, height: CGFloat, flexible: Bool) {
        self.world = world
        self.flexible = flexible
        super.init(frame: NSRect(x: 0, y: 0, width: World.W * height / World.H, height: height))
        allowedTouchTypes = [.direct]
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: height).isActive = true
        if flexible {
            widthAnchor.constraint(greaterThanOrEqualToConstant: 380).isActive = true
            let wide = widthAnchor.constraint(equalToConstant: 2000)
            wide.priority = .defaultLow
            wide.isActive = true
            setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
        } else {
            widthAnchor.constraint(equalToConstant: frame.width).isActive = true
        }
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        if flexible && newSize.height > 0 && newSize.width > 0 {
            World.W = max(380, newSize.width / (newSize.height / World.H))
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override var isFlipped: Bool { false }
    // The Touch Bar decides what fits from this, so the stretchy copy only asks for its minimum.
    override var intrinsicContentSize: NSSize { NSSize(width: flexible ? 380 : frame.width, height: frame.height) }
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    private var scale: CGFloat { min(bounds.height / World.H, bounds.width / World.W) }
    private var yOffset: CGFloat { (bounds.height - World.H * scale) / 2 }

    // The scene is rendered into a reusable sRGB bitmap (same colour space as every sprite, so CoreGraphics
    // never colour-converts per draw) and handed to the layer as its contents; the compositor does the final
    // colour match on the GPU. Much cheaper than draw(_:) into a display-space backing store.
    override var wantsUpdateLayer: Bool { true }
    private var offscreen: CGContext?

    override func updateLayer() {
        guard let layer = layer, bounds.width > 0, bounds.height > 0 else { return }
        let px = window?.backingScaleFactor ?? 2
        let w = Int(bounds.width * px), h = Int(bounds.height * px)
        if offscreen?.width != w || offscreen?.height != h {
            offscreen = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        }
        guard let ctx = offscreen else { return }
        ctx.saveGState()
        ctx.clear(CGRect(x: 0, y: 0, width: w, height: h))
        ctx.scaleBy(x: px, y: px)
        if !flexible {
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.fill(bounds)
        }
        ctx.translateBy(x: 0, y: yOffset)
        ctx.scaleBy(x: scale, y: scale)
        ctx.clip(to: CGRect(x: 0, y: 0, width: World.W, height: World.H))
        world.render(in: ctx)
        ctx.restoreGState()
        layer.contentsScale = px
        layer.contents = ctx.makeImage()
    }

    private func worldPoint(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x / scale, y: (p.y - yOffset) / scale) }

    // Touch Bar touches
    override func touchesBegan(with event: NSEvent) {
        for t in event.touches(matching: .began, in: self) { world.touchBegan(worldPoint(t.location(in: self)), id: (t.identity as AnyObject).hash) }
    }
    override func touchesMoved(with event: NSEvent) {
        for t in event.touches(matching: .moved, in: self) { world.touchMoved(worldPoint(t.location(in: self)), id: (t.identity as AnyObject).hash) }
    }
    override func touchesEnded(with event: NSEvent) {
        for t in event.touches(matching: .ended, in: self) { world.touchEnded(worldPoint(t.location(in: self)), id: (t.identity as AnyObject).hash) }
    }
    override func touchesCancelled(with event: NSEvent) {
        for t in event.touches(matching: .cancelled, in: self) { world.touchEnded(worldPoint(t.location(in: self)), id: (t.identity as AnyObject).hash) }
    }

    // Mouse / trackpad (pet window)
    override func mouseDown(with event: NSEvent) {
        if world.mode == .rhythm && event.modifierFlags.contains(.shift) { world.mouseDrum(fingers: 3); return }
        world.touchBegan(worldPoint(convert(event.locationInWindow, from: nil)))
    }
    override func mouseDragged(with event: NSEvent) { world.touchMoved(worldPoint(convert(event.locationInWindow, from: nil))) }
    override func mouseUp(with event: NSEvent) { world.touchEnded(worldPoint(convert(event.locationInWindow, from: nil))) }
    override func rightMouseDown(with event: NSEvent) {
        if world.mode == .rhythm && event.modifierFlags.contains(.shift) { world.mouseDrum(fingers: 4); return }
        world.secondaryTap(worldPoint(convert(event.locationInWindow, from: nil)))
    }

    var isOnScreen: Bool { window != nil }
}
