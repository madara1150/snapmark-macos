// SnapMark — แคปหน้าจอ → วาด/ใส่ข้อความ → Copy ไปวางได้ทันที โดยไม่ต้องเซฟไฟล์
import Cocoa
import Carbon.HIToolbox

// MARK: - Model

enum Tool: Int, CaseIterable {
    case pen, highlighter, arrow, line, rect, ellipse, text, pixelate

    var symbol: String {
        switch self {
        case .pen: return "scribble"
        case .highlighter: return "highlighter"
        case .arrow: return "arrow.up.right"
        case .line: return "line.diagonal"
        case .rect: return "rectangle"
        case .ellipse: return "circle"
        case .text: return "textformat"
        case .pixelate: return "square.grid.3x3.fill"
        }
    }

    var tip: String {
        switch self {
        case .pen: return "ปากกา (P)"
        case .highlighter: return "ไฮไลต์ (H)"
        case .arrow: return "ลูกศร (A)"
        case .line: return "เส้นตรง (L)"
        case .rect: return "สี่เหลี่ยม (R)"
        case .ellipse: return "วงกลม (O)"
        case .text: return "ข้อความ (T)"
        case .pixelate: return "เบลอ/ปิดข้อมูล (B)"
        }
    }

    static func from(key: String) -> Tool? {
        switch key {
        case "p": return .pen
        case "h": return .highlighter
        case "a": return .arrow
        case "l": return .line
        case "r": return .rect
        case "o": return .ellipse
        case "t": return .text
        case "b": return .pixelate
        default: return nil
        }
    }
}

struct Annotation {
    var tool: Tool
    var color: NSColor
    var width: CGFloat
    var points: [CGPoint] = []
    var start: CGPoint = .zero
    var end: CGPoint = .zero
    var text: String = ""
    var fontSize: CGFloat = 20

    var textBounds: NSRect {
        let size = (text as NSString).size(withAttributes: [.font: NSFont.boldSystemFont(ofSize: fontSize)])
        return NSRect(origin: start, size: size).insetBy(dx: -4, dy: -4)
    }

    var rect: NSRect {
        NSRect(x: min(start.x, end.x), y: min(start.y, end.y),
               width: abs(end.x - start.x), height: abs(end.y - start.y))
    }

    var isMeaningful: Bool {
        switch tool {
        case .pen, .highlighter: return points.count > 1
        case .text: return !text.isEmpty
        default: return hypot(end.x - start.x, end.y - start.y) > 3
        }
    }
}

// MARK: - Rendering (shared by the canvas and the exported image; assumes a flipped context)

enum Renderer {
    static func draw(base: NSImage, pixelated: NSImage, annotations: [Annotation], size: NSSize) {
        let full = NSRect(origin: .zero, size: size)
        base.draw(in: full, from: .zero, operation: .copy, fraction: 1, respectFlipped: true, hints: nil)
        for a in annotations { draw(a, pixelated: pixelated, full: full) }
    }

    static func draw(_ a: Annotation, pixelated: NSImage, full: NSRect) {
        switch a.tool {
        case .pen, .highlighter:
            let path = NSBezierPath()
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.move(to: a.points[0])
            if a.points.count == 1 {
                path.line(to: CGPoint(x: a.points[0].x + 0.1, y: a.points[0].y))
            } else {
                for p in a.points.dropFirst() { path.line(to: p) }
            }
            if a.tool == .highlighter {
                path.lineWidth = a.width * 4
                path.lineCapStyle = .square
                a.color.withAlphaComponent(0.35).setStroke()
            } else {
                path.lineWidth = a.width
                a.color.setStroke()
            }
            path.stroke()

        case .line, .arrow:
            let s = a.start, e = a.end
            let angle = atan2(e.y - s.y, e.x - s.x)
            a.color.set()
            if a.tool == .arrow {
                let head = max(14, a.width * 4)
                let spread = CGFloat.pi / 7
                let p1 = CGPoint(x: e.x - head * cos(angle - spread), y: e.y - head * sin(angle - spread))
                let p2 = CGPoint(x: e.x - head * cos(angle + spread), y: e.y - head * sin(angle + spread))
                let back = CGPoint(x: e.x - head * 0.8 * cos(angle), y: e.y - head * 0.8 * sin(angle))
                let shaft = NSBezierPath()
                shaft.lineWidth = a.width
                shaft.lineCapStyle = .round
                shaft.move(to: s)
                shaft.line(to: back)
                shaft.stroke()
                let tri = NSBezierPath()
                tri.move(to: e); tri.line(to: p1); tri.line(to: p2); tri.close()
                tri.fill()
            } else {
                let path = NSBezierPath()
                path.lineWidth = a.width
                path.lineCapStyle = .round
                path.move(to: s)
                path.line(to: e)
                path.stroke()
            }

        case .rect:
            let path = NSBezierPath(rect: a.rect)
            path.lineWidth = a.width
            path.lineJoinStyle = .round
            a.color.setStroke()
            path.stroke()

        case .ellipse:
            let path = NSBezierPath(ovalIn: a.rect)
            path.lineWidth = a.width
            a.color.setStroke()
            path.stroke()

        case .text:
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: a.fontSize),
                .foregroundColor: a.color,
            ]
            (a.text as NSString).draw(at: a.start, withAttributes: attrs)

        case .pixelate:
            NSGraphicsContext.saveGraphicsState()
            NSBezierPath(rect: a.rect).addClip()
            NSGraphicsContext.current?.imageInterpolation = .none
            pixelated.draw(in: full, from: .zero, operation: .copy, fraction: 1, respectFlipped: true,
                           hints: [.interpolation: NSNumber(value: NSImageInterpolation.none.rawValue)])
            NSGraphicsContext.restoreGraphicsState()
        }
    }

    static func makePixelated(_ image: NSImage, block: CGFloat = 10) -> NSImage {
        let w = max(1, Int(image.size.width / block)), h = max(1, Int(image.size.height / block))
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h, bitsPerSample: 8,
                                   samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                   colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        rep.size = NSSize(width: w, height: h)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(x: 0, y: 0, width: w, height: h))
        NSGraphicsContext.restoreGraphicsState()
        let out = NSImage(size: image.size)
        out.addRepresentation(rep)
        return out
    }
}

// MARK: - Canvas

final class CanvasView: NSView, NSTextFieldDelegate {
    let image: NSImage
    let pixelated: NSImage
    private(set) var annotations: [Annotation] = [] { didSet { needsDisplay = true } }
    private var redoStack: [Annotation] = []
    private var current: Annotation?
    private var textField: NSTextField?
    private var editingIndex: Int?          // where an edited text goes back in the list
    private var editingFontSize: CGFloat = 24
    private var textDrag: (index: Int, last: CGPoint, moved: Bool)?

    var tool: Tool = .rect { didSet { commitText(); window?.invalidateCursorRects(for: self) } }
    var color: NSColor = .systemRed { didSet { textField?.textColor = color } }
    var lineWidth: CGFloat = 4
    var fontSize: CGFloat = 24 {
        didSet {
            guard let tf = textField else { return }
            editingFontSize = fontSize
            tf.font = .boldSystemFont(ofSize: fontSize)
            tf.frame.size.height = fontSize * 1.4
            controlTextDidChange(Notification(name: NSControl.textDidChangeNotification))
        }
    }

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    init(image: NSImage) {
        self.image = image
        self.pixelated = Renderer.makePixelated(image)
        super.init(frame: NSRect(origin: .zero, size: image.size))
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        var all = annotations
        if let current { all.append(current) }
        Renderer.draw(base: image, pixelated: pixelated, annotations: all, size: bounds.size)
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: tool == .text ? .iBeam : .crosshair)
    }

    // MARK: Mouse

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        if textField != nil { commitText(); return }
        // Existing text: with the text tool click = edit, drag = move. Any tool: double-click = edit.
        if let i = textIndex(at: p), tool == .text || event.clickCount == 2 {
            textDrag = (i, p, false)
            return
        }
        if tool == .text {
            beginText(frameOrigin: CGPoint(x: p.x, y: p.y - fontSize * 0.7), text: "", color: color, fontSize: fontSize)
            return
        }
        current = Annotation(tool: tool, color: color, width: lineWidth, points: [p], start: p, end: p)
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        var p = convert(event.locationInWindow, from: nil)
        if let d = textDrag {
            let dx = p.x - d.last.x, dy = p.y - d.last.y
            annotations[d.index].start.x += dx
            annotations[d.index].start.y += dy
            textDrag = (d.index, p, true)
            return
        }
        guard var a = current else { return }
        p.x = min(max(p.x, 0), bounds.width)
        p.y = min(max(p.y, 0), bounds.height)
        let shift = event.modifierFlags.contains(.shift)
        switch a.tool {
        case .pen, .highlighter:
            a.points.append(p)
        case .rect, .ellipse, .pixelate:
            if shift {
                let dx = p.x - a.start.x, dy = p.y - a.start.y
                let d = max(abs(dx), abs(dy))
                p = CGPoint(x: a.start.x + (dx < 0 ? -d : d), y: a.start.y + (dy < 0 ? -d : d))
            }
            a.end = p
        case .line, .arrow:
            if shift {
                let dx = p.x - a.start.x, dy = p.y - a.start.y
                let step = CGFloat.pi / 4
                let angle = (atan2(dy, dx) / step).rounded() * step
                let len = hypot(dx, dy)
                p = CGPoint(x: a.start.x + len * cos(angle), y: a.start.y + len * sin(angle))
            }
            a.end = p
        case .text:
            break
        }
        current = a
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        if let d = textDrag {
            textDrag = nil
            if !d.moved { editText(at: d.index) }
            return
        }
        if let a = current, a.isMeaningful { push(a) }
        current = nil
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        let flags = event.modifierFlags.intersection([.command, .control, .option])
        if flags.isEmpty, let key = event.charactersIgnoringModifiers?.lowercased(), let t = Tool.from(key: key) {
            (window as? EditorWindow)?.editor?.select(tool: t)
            return
        }
        super.keyDown(with: event)
    }

    // MARK: Text

    private func textIndex(at p: CGPoint) -> Int? {
        annotations.lastIndex { $0.tool == .text && $0.textBounds.contains(p) }
    }

    private func editText(at index: Int) {
        let a = annotations.remove(at: index)
        editingIndex = index
        beginText(frameOrigin: CGPoint(x: a.start.x - 2, y: a.start.y), text: a.text, color: a.color, fontSize: a.fontSize)
        controlTextDidChange(Notification(name: NSControl.textDidChangeNotification))
    }

    private func beginText(frameOrigin: CGPoint, text: String, color: NSColor, fontSize: CGFloat) {
        editingFontSize = fontSize
        let tf = NSTextField(string: text)
        tf.font = .boldSystemFont(ofSize: fontSize)
        tf.textColor = color
        tf.isBordered = false
        tf.drawsBackground = true
        tf.backgroundColor = NSColor.white.withAlphaComponent(0.25)
        tf.focusRingType = .none
        tf.delegate = self
        tf.placeholderString = "พิมพ์ข้อความ…"
        tf.frame = NSRect(origin: frameOrigin, size: NSSize(width: max(160, fontSize * 8), height: fontSize * 1.4))
        addSubview(tf)
        textField = tf
        window?.makeFirstResponder(tf)
    }

    func controlTextDidChange(_ obj: Notification) {
        guard let tf = textField else { return }
        let w = (tf.stringValue as NSString).size(withAttributes: [.font: tf.font!]).width + 24
        tf.frame.size.width = max(160, w)
    }

    func controlTextDidEndEditing(_ obj: Notification) { commitText() }

    func commitText() {
        guard let tf = textField else { return }
        textField = nil
        let text = tf.stringValue
        let origin = CGPoint(x: tf.frame.minX + 2, y: tf.frame.minY)
        tf.delegate = nil
        tf.removeFromSuperview()
        window?.makeFirstResponder(self)
        let index = editingIndex
        editingIndex = nil
        // Clearing an edited text deletes it.
        guard !text.isEmpty else { return }
        let a = Annotation(tool: .text, color: tf.textColor ?? color, width: lineWidth,
                           start: origin, end: origin, text: text, fontSize: editingFontSize)
        if let index {
            annotations.insert(a, at: min(index, annotations.count))
        } else {
            push(a)
        }
    }

    // MARK: History

    private func push(_ a: Annotation) {
        annotations.append(a)
        redoStack.removeAll()
    }

    func undo() {
        commitText()
        if let a = annotations.popLast() { redoStack.append(a) }
    }

    func redo() {
        if let a = redoStack.popLast() { annotations.append(a) }
    }

    // MARK: Export

    func renderedImageData() -> (png: Data, tiff: Data)? {
        commitText()
        let size = image.size
        let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        let pw = cg?.width ?? Int(size.width), ph = cg?.height ?? Int(size.height)
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        guard let ctx = CGContext(data: nil, width: pw, height: ph, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        ctx.scaleBy(x: CGFloat(pw) / size.width, y: CGFloat(ph) / size.height)
        ctx.translateBy(x: 0, y: size.height)
        ctx.scaleBy(x: 1, y: -1)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)
        Renderer.draw(base: image, pixelated: pixelated, annotations: annotations, size: size)
        NSGraphicsContext.restoreGraphicsState()
        guard let out = ctx.makeImage() else { return nil }
        let rep = NSBitmapImageRep(cgImage: out)
        rep.size = size // keep Retina DPI so it pastes at the right size
        guard let png = rep.representation(using: .png, properties: [:]),
              let tiff = rep.tiffRepresentation else { return nil }
        return (png, tiff)
    }
}

// MARK: - Editor window

final class EditorWindow: NSWindow {
    weak var editor: Editor?

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection([.command, .shift, .option, .control])
        let key = event.charactersIgnoringModifiers?.lowercased() ?? ""
        guard let editor else { return super.performKeyEquivalent(with: event) }

        // While typing text, let ⌘C/⌘V/⌘Z work inside the text field.
        if firstResponder is NSText {
            if flags == .command && key == "\r" { editor.copyAndClose(); return true }
            return super.performKeyEquivalent(with: event)
        }

        if flags == .command {
            switch key {
            case "c": editor.copyImage(); return true
            case "\r": editor.copyAndClose(); return true
            case "z": editor.undo(); return true
            case "s": editor.save(); return true
            case "w": close(); return true
            default: break
            }
        }
        if flags == [.command, .shift] && key == "z" { editor.redo(); return true }
        return super.performKeyEquivalent(with: event)
    }
}

final class Editor: NSObject, NSWindowDelegate {
    let window: EditorWindow
    let canvas: CanvasView
    private let toolControl: NSSegmentedControl
    private let colorWell = NSColorWell()
    private let status = NSTextField(labelWithString: "")
    private var swatches: [NSButton] = []
    var onClose: ((Editor) -> Void)?

    private static let palette: [NSColor] = [
        .systemRed, .systemOrange, .systemYellow, .systemGreen, .systemBlue, .systemPurple, .black, .white,
    ]
    private static let widths: [(String, CGFloat, CGFloat)] = [
        ("บาง", 2, 16), ("กลาง", 4, 24), ("หนา", 7, 34), ("หนามาก", 12, 48),
    ]

    init(image: NSImage) {
        canvas = CanvasView(image: image)
        toolControl = NSSegmentedControl()
        window = EditorWindow(contentRect: .zero, styleMask: [.titled, .closable, .resizable, .miniaturizable],
                              backing: .buffered, defer: false)
        super.init()
        window.editor = self
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.title = "SnapMark — ⌘C คัดลอก · ⌘↩ คัดลอกแล้วปิด"
        buildUI()
    }

    private func buildUI() {
        // Tools
        toolControl.segmentCount = Tool.allCases.count
        toolControl.trackingMode = .selectOne
        for t in Tool.allCases {
            toolControl.setImage(NSImage(systemSymbolName: t.symbol, accessibilityDescription: t.tip), forSegment: t.rawValue)
            toolControl.setToolTip(t.tip, forSegment: t.rawValue)
            toolControl.setWidth(30, forSegment: t.rawValue)
        }
        toolControl.selectedSegment = canvas.tool.rawValue
        toolControl.target = self
        toolControl.action = #selector(toolChanged)

        // Colors
        let colorStack = NSStackView()
        colorStack.spacing = 4
        for (i, c) in Self.palette.enumerated() {
            let b = NSButton(title: "", target: self, action: #selector(swatchClicked(_:)))
            b.tag = i
            b.isBordered = false
            b.wantsLayer = true
            b.layer?.backgroundColor = c.cgColor
            b.layer?.cornerRadius = 10
            b.layer?.borderColor = NSColor.controlAccentColor.cgColor
            b.layer?.borderWidth = 0
            b.translatesAutoresizingMaskIntoConstraints = false
            b.widthAnchor.constraint(equalToConstant: 20).isActive = true
            b.heightAnchor.constraint(equalToConstant: 20).isActive = true
            colorStack.addArrangedSubview(b)
            swatches.append(b)
        }
        colorWell.color = canvas.color
        colorWell.target = self
        colorWell.action = #selector(colorWellChanged)
        colorWell.translatesAutoresizingMaskIntoConstraints = false
        colorWell.widthAnchor.constraint(equalToConstant: 34).isActive = true
        colorWell.heightAnchor.constraint(equalToConstant: 22).isActive = true
        updateSwatchSelection()

        // Width
        let widthPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        widthPopup.addItems(withTitles: Self.widths.map(\.0))
        widthPopup.selectItem(at: 1)
        widthPopup.target = self
        widthPopup.action = #selector(widthChanged(_:))
        widthPopup.toolTip = "ความหนาเส้น / ขนาดตัวอักษร"

        let undoBtn = iconButton("arrow.uturn.backward", tip: "ย้อนกลับ (⌘Z)", action: #selector(undo))
        let redoBtn = iconButton("arrow.uturn.forward", tip: "ทำซ้ำ (⇧⌘Z)", action: #selector(redo))

        let copyBtn = NSButton(title: "Copy", target: self, action: #selector(copyImage))
        copyBtn.toolTip = "คัดลอกรูปไปคลิปบอร์ด (⌘C)"
        copyBtn.image = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: nil)
        copyBtn.imagePosition = .imageLeading
        let copyCloseBtn = NSButton(title: "Copy & ปิด", target: self, action: #selector(copyAndClose))
        copyCloseBtn.toolTip = "คัดลอกแล้วปิดหน้าต่าง (⌘↩)"
        copyCloseBtn.bezelColor = .controlAccentColor
        copyCloseBtn.keyEquivalent = "" // handled by EditorWindow so it doesn't steal Return while typing

        status.textColor = .systemGreen
        status.font = .systemFont(ofSize: 12, weight: .semibold)

        let spacer = NSView()
        spacer.setContentHuggingPriority(.init(1), for: .horizontal)

        let bar = NSStackView(views: [toolControl, colorStack, colorWell, widthPopup, undoBtn, redoBtn,
                                      spacer, status, copyBtn, copyCloseBtn])
        bar.orientation = .horizontal
        bar.spacing = 10
        bar.edgeInsets = NSEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        bar.translatesAutoresizingMaskIntoConstraints = false

        // Canvas in a zoomable scroll view
        let scroll = NSScrollView()
        scroll.documentView = canvas
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = true
        scroll.allowsMagnification = true
        scroll.minMagnification = 0.1
        scroll.maxMagnification = 4
        scroll.backgroundColor = NSColor(white: 0.18, alpha: 1)
        scroll.drawsBackground = true
        scroll.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView()
        content.addSubview(bar)
        content.addSubview(scroll)
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: content.topAnchor),
            bar.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: bar.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: content.bottomAnchor),
        ])
        window.contentView = content

        // Size the window to the image, shrinking (zoom out) if it doesn't fit on screen
        let barHeight: CGFloat = 44
        let visible = (NSScreen.main ?? NSScreen.screens[0]).visibleFrame
        let img = canvas.image.size
        let maxW = visible.width * 0.92, maxH = visible.height * 0.92 - barHeight
        let scale = min(1, maxW / img.width, maxH / img.height)
        let w = max(900, img.width * scale + 4), h = max(300, img.height * scale + barHeight + 4)
        window.setContentSize(NSSize(width: min(w, visible.width), height: min(h, visible.height)))
        window.minSize = NSSize(width: 700, height: 250)
        scroll.magnification = scale
        window.center()
    }

    private func iconButton(_ symbol: String, tip: String, action: Selector) -> NSButton {
        let b = NSButton(image: NSImage(systemSymbolName: symbol, accessibilityDescription: tip)!, target: self, action: action)
        b.toolTip = tip
        b.bezelStyle = .texturedRounded
        return b
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(canvas)
    }

    // MARK: Actions

    func select(tool: Tool) {
        canvas.tool = tool
        toolControl.selectedSegment = tool.rawValue
    }

    @objc private func toolChanged() {
        if let t = Tool(rawValue: toolControl.selectedSegment) { canvas.tool = t }
        window.makeFirstResponder(canvas)
    }

    @objc private func swatchClicked(_ sender: NSButton) {
        setColor(Self.palette[sender.tag])
    }

    @objc private func colorWellChanged() { setColor(colorWell.color) }

    private func setColor(_ c: NSColor) {
        canvas.color = c
        colorWell.color = c
        updateSwatchSelection()
    }

    private func updateSwatchSelection() {
        for (i, b) in swatches.enumerated() {
            b.layer?.borderWidth = Self.palette[i] == canvas.color ? 3 : 0
        }
    }

    @objc private func widthChanged(_ sender: NSPopUpButton) {
        let w = Self.widths[sender.indexOfSelectedItem]
        canvas.lineWidth = w.1
        canvas.fontSize = w.2
        window.makeFirstResponder(canvas)
    }

    @objc func undo() { canvas.undo() }
    @objc func redo() { canvas.redo() }

    @discardableResult
    @objc func copyImage() -> Bool {
        guard let data = canvas.renderedImageData() else { NSSound.beep(); return false }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setData(data.png, forType: .png)
        pb.setData(data.tiff, forType: .tiff)
        NSSound(named: "Pop")?.play()
        status.stringValue = "✓ คัดลอกแล้ว — ไปวาง (⌘V) ได้เลย"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in self?.status.stringValue = "" }
        return true
    }

    @objc func copyAndClose() {
        if copyImage() { window.close() }
    }

    func save() {
        guard let data = canvas.renderedImageData() else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        panel.nameFieldStringValue = "Screenshot \(f.string(from: Date())).png"
        panel.beginSheetModal(for: window) { resp in
            if resp == .OK, let url = panel.url { try? data.png.write(to: url) }
        }
    }

    func windowWillClose(_ notification: Notification) { onClose?(self) }
}

// MARK: - App

func debugLog(_ msg: String) {
    let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs/SnapMark.log")
    let line = "\(Date()) \(msg)\n"
    if let h = try? FileHandle(forWritingTo: url) {
        h.seekToEndOfFile(); h.write(line.data(using: .utf8)!); try? h.close()
    } else {
        try? line.write(to: url, atomically: true, encoding: .utf8)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var editors: [Editor] = []
    private var hotKeyRef: EventHotKeyRef?
    private var capturing = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "SnapMark")

        let menu = NSMenu()
        let area = NSMenuItem(title: "แคปบางส่วน (⌘⇧2)", action: #selector(captureArea), keyEquivalent: "")
        menu.addItem(area)
        menu.addItem(NSMenuItem(title: "แคปทั้งจอ", action: #selector(captureFullScreen), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "แก้ไขรูปจากคลิปบอร์ด", action: #selector(editClipboard), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "ออกจาก SnapMark", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        for item in menu.items where item.action != #selector(NSApplication.terminate(_:)) { item.target = self }
        statusItem.menu = menu

        registerHotKey()
        showLaunchHint()
    }

    private func showLaunchHint() {
        let alert = NSAlert()
        alert.messageText = "SnapMark พร้อมใช้งาน"
        alert.informativeText = "กด ⌘⇧2 เพื่อแคปหน้าจอ\nหรือคลิกไอคอน 📷 บนแถบเมนู / ดับเบิลคลิกแอปอีกครั้ง"
        alert.addButton(withTitle: "แคปเลย")
        alert.addButton(withTitle: "ตกลง")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn { captureArea() }
    }

    // ⌘⇧2 global hotkey (Carbon hotkeys don't need Accessibility permission)
    private func registerHotKey() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            let me = Unmanaged<AppDelegate>.fromOpaque(userData!).takeUnretainedValue()
            DispatchQueue.main.async { me.captureArea() }
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), nil)
        let id = EventHotKeyID(signature: OSType(0x534E_4D4B), id: 1)
        let st = RegisterEventHotKey(UInt32(kVK_ANSI_2), UInt32(cmdKey | shiftKey), id, GetApplicationEventTarget(), 0, &hotKeyRef)
        debugLog("register hotkey status=\(st)")
    }

    // Double-clicking the app (or clicking it in Dock/Spotlight) while it's running → start a capture,
    // since the menu bar icon can be hidden behind the notch.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        captureArea()
        return false
    }

    @objc func captureArea() { capture(args: ["-i", "-c"]) }
    @objc func captureFullScreen() { capture(args: ["-c"]) }

    @objc func editClipboard() {
        if let img = NSImage(pasteboard: .general) { openEditor(img) } else { NSSound.beep() }
    }

    // screencapture -c puts the shot straight on the clipboard — nothing is written to disk.
    private func capture(args: [String]) {
        debugLog("capture \(args) capturing=\(capturing) screenAccess=\(CGPreflightScreenCaptureAccess())")
        guard !capturing else { return }
        if !CGPreflightScreenCaptureAccess() {
            CGRequestScreenCaptureAccess()
        }
        capturing = true
        let pb = NSPasteboard.general
        let before = pb.changeCount
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        p.arguments = args
        let errPipe = Pipe()
        p.standardError = errPipe
        p.terminationHandler = { proc in
            let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            DispatchQueue.main.async {
                debugLog("screencapture exit=\(proc.terminationStatus) changed=\(pb.changeCount != before) types=\(pb.types?.map(\.rawValue) ?? []) stderr=\(err)")
                self.capturing = false
                if proc.terminationStatus != 0 && !CGPreflightScreenCaptureAccess() {
                    self.showPermissionHelp()
                    return
                }
                // changeCount unchanged → user pressed Esc
                if pb.changeCount != before, let img = NSImage(pasteboard: pb) { self.openEditor(img) }
            }
        }
        do { try p.run() } catch { debugLog("run failed: \(error)"); capturing = false; NSSound.beep() }
    }

    private func showPermissionHelp() {
        let alert = NSAlert()
        alert.messageText = "SnapMark ยังไม่ได้รับสิทธิ์บันทึกหน้าจอ"
        alert.informativeText = "เปิด System Settings → Privacy & Security → Screen & System Audio Recording แล้วเปิดสวิตช์ SnapMark (ถ้ามีอยู่แล้วให้ลบด้วยปุ่ม − แล้วเพิ่มใหม่)\n\nจากนั้นปิดและเปิด SnapMark ใหม่"
        alert.addButton(withTitle: "เปิด System Settings")
        alert.addButton(withTitle: "ปิด")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
        }
    }

    private func openEditor(_ image: NSImage) {
        let e = Editor(image: image)
        e.onClose = { [weak self] ed in
            DispatchQueue.main.async { self?.editors.removeAll { $0 === ed } }
        }
        editors.append(e)
        e.show()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
