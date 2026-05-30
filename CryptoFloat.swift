import Cocoa
import Foundation

// MARK: - Configuration
struct AppConfig: Codable {
    var cryptos: [String]
    var transparency: Double
    var windowX: Double
    var windowY: Double
    var isExpanded: Bool
    var refreshRate: Int
    var showSparklines: Bool
    var menuBarSymbol: String?

    static let `default` = AppConfig(
        cryptos: ["BTC", "ETH", "SOL"],
        transparency: 0.85,
        windowX: 100,
        windowY: 100,
        isExpanded: true,
        refreshRate: 30,
        showSparklines: true,
        menuBarSymbol: nil
    )

    static let configPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".cryptofloat_config.json")

    static func load() -> AppConfig {
        guard let data = try? Data(contentsOf: configPath),
              let config = try? JSONDecoder().decode(AppConfig.self, from: data) else {
            return .default
        }
        return config
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(self) else { return }
        try? data.write(to: AppConfig.configPath)
    }
}

// Tolerant decoding: a missing or malformed key falls back to its default
// instead of throwing away the entire saved configuration. This keeps older
// config files (and future schema changes) working seamlessly.
extension AppConfig {
    enum CodingKeys: String, CodingKey {
        case cryptos, transparency, windowX, windowY, isExpanded, refreshRate, showSparklines, menuBarSymbol
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = AppConfig.default
        cryptos        = (try? c.decode([String].self, forKey: .cryptos)) ?? d.cryptos
        transparency   = (try? c.decode(Double.self,   forKey: .transparency)) ?? d.transparency
        windowX        = (try? c.decode(Double.self,   forKey: .windowX)) ?? d.windowX
        windowY        = (try? c.decode(Double.self,   forKey: .windowY)) ?? d.windowY
        isExpanded     = (try? c.decode(Bool.self,     forKey: .isExpanded)) ?? d.isExpanded
        refreshRate    = (try? c.decode(Int.self,      forKey: .refreshRate)) ?? d.refreshRate
        showSparklines = (try? c.decode(Bool.self,     forKey: .showSparklines)) ?? d.showSparklines
        menuBarSymbol  = try? c.decode(String.self,    forKey: .menuBarSymbol)
    }
}

// MARK: - Price Formatter
class PriceFormatter {
    static let shared = PriceFormatter()

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private let smallPriceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 4
        formatter.maximumFractionDigits = 6
        return formatter
    }()

    private let groupedFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    func format(_ price: Double) -> String {
        if price >= 1 {
            // Normal prices: $90,719.00, $3,097.70, $136.42
            return currencyFormatter.string(from: NSNumber(value: price)) ?? "$0.00"
        } else if price >= 0.0001 {
            // Small prices: $0.0012
            return smallPriceFormatter.string(from: NSNumber(value: price)) ?? "$0.0000"
        } else {
            // Very small prices: more decimals
            return String(format: "$%.8f", price)
        }
    }

    /// Compact form used in the menu bar where horizontal space is scarce.
    func compact(_ price: Double) -> String {
        if price >= 1000 {
            let rounded = NSNumber(value: price.rounded())
            return "$" + (groupedFormatter.string(from: rounded) ?? "0")
        } else if price >= 1 {
            return String(format: "$%.2f", price)
        }
        return format(price)
    }
}

// MARK: - Price Data
struct PriceData {
    let price: Double
    let change24h: Double
    let hasError: Bool
}

struct ChartPoint {
    let time: TimeInterval
    let price: Double
}

// MARK: - KuCoin API Manager
class CryptoAPI {
    static let shared = CryptoAPI()
    private let baseURL = "https://api.kucoin.com"

    func fetchPrice(for symbol: String, completion: @escaping (PriceData) -> Void) {
        let pair = "\(symbol.uppercased())-USDT"
        let urlString = "\(baseURL)/api/v1/market/stats?symbol=\(pair)"

        guard let url = URL(string: urlString) else {
            completion(PriceData(price: 0, change24h: 0, hasError: true))
            return
        }

        var request = URLRequest(url: url)
        request.setValue("CryptoFloat/1.1", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error for \(symbol): \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(PriceData(price: 0, change24h: 0, hasError: true))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(PriceData(price: 0, change24h: 0, hasError: true))
                }
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let code = json["code"] as? String,
                   code == "200000",
                   let dataDict = json["data"] as? [String: Any] {

                    let priceStr = dataDict["last"] as? String ?? "0"
                    let price = Double(priceStr) ?? 0

                    let changeRateStr = dataDict["changeRate"] as? String ?? "0"
                    let changeRate = (Double(changeRateStr) ?? 0) * 100

                    DispatchQueue.main.async {
                        completion(PriceData(price: price, change24h: changeRate, hasError: false))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(PriceData(price: 0, change24h: 0, hasError: true))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(PriceData(price: 0, change24h: 0, hasError: true))
                }
            }
        }.resume()
    }

    func fetchAllPrices(for symbols: [String], completion: @escaping ([String: PriceData]) -> Void) {
        let group = DispatchGroup()
        var results: [String: PriceData] = [:]
        let lock = NSLock()

        for symbol in symbols {
            group.enter()
            fetchPrice(for: symbol) { data in
                lock.lock()
                results[symbol] = data
                lock.unlock()
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(results)
        }
    }

    /// Fetches ~24h of hourly closing prices for a tiny trend sparkline.
    /// Returns an empty array on any failure so the UI can simply skip drawing.
    func fetchSparkline(for symbol: String, completion: @escaping ([Double]) -> Void) {
        let pair = "\(symbol.uppercased())-USDT"
        let end = Int(Date().timeIntervalSince1970)
        let start = end - 60 * 60 * 26  // 26h window to comfortably capture 24 hourly candles
        let urlString = "\(baseURL)/api/v1/market/candles?type=1hour&symbol=\(pair)&startAt=\(start)&endAt=\(end)"

        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { completion([]) }
            return
        }

        var request = URLRequest(url: url)
        request.setValue("CryptoFloat/1.1", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let code = json["code"] as? String, code == "200000",
                  let rows = json["data"] as? [[Any]] else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            // Each candle: [time, open, close, high, low, volume, turnover], newest first.
            let closesNewestFirst: [Double] = rows.compactMap { row in
                guard row.count > 2, let s = row[2] as? String, let v = Double(s) else { return nil }
                return v
            }
            let chronological = Array(closesNewestFirst.reversed())
            let trimmed = Array(chronological.suffix(32))

            DispatchQueue.main.async { completion(trimmed) }
        }.resume()
    }

    /// Fetches 7 days of two-hour closing prices for the detail popup chart.
    /// Returns an empty array on any failure so the popup can show a soft error state.
    func fetchSevenDayChart(for symbol: String, completion: @escaping ([ChartPoint]) -> Void) {
        let pair = "\(symbol.uppercased())-USDT"
        let end = Int(Date().timeIntervalSince1970)
        let start = end - 60 * 60 * 24 * 7
        let urlString = "\(baseURL)/api/v1/market/candles?type=2hour&symbol=\(pair)&startAt=\(start)&endAt=\(end)"

        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { completion([]) }
            return
        }

        var request = URLRequest(url: url)
        request.setValue("CryptoFloat/1.1", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let code = json["code"] as? String, code == "200000",
                  let rows = json["data"] as? [[Any]] else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            // Each candle: [time, open, close, high, low, volume, turnover], newest first.
            let pointsNewestFirst: [ChartPoint] = rows.compactMap { row in
                guard row.count > 2,
                      let priceString = row[2] as? String,
                      let price = Double(priceString) else {
                    return nil
                }

                let time: TimeInterval?
                if let timeString = row[0] as? String {
                    time = TimeInterval(timeString)
                } else if let timeNumber = row[0] as? NSNumber {
                    time = timeNumber.doubleValue
                } else {
                    time = nil
                }

                guard let time = time else { return nil }
                return ChartPoint(time: time, price: price)
            }
            let chronological = Array(pointsNewestFirst.reversed())
            let trimmed = Array(chronological.suffix(90))

            DispatchQueue.main.async { completion(trimmed) }
        }.resume()
    }
}

// MARK: - Toggle Button View
class ToggleButtonView: NSView {
    var isHovered = false
    var isExpanded = true
    var onClick: (() -> Void)?

    /// 24h change of the primary coin; tints the ring green/red as an ambient signal.
    var accentChange: Double = 0 {
        didSet { needsDisplay = true }
    }

    private var trackingArea: NSTrackingArea?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        setupTrackingArea()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        setupTrackingArea()
    }

    private func setupTrackingArea() {
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }

    private func accentRingColor() -> NSColor {
        let strong: CGFloat = isHovered ? 0.9 : 0.6
        if accentChange > 0.05 {
            return NSColor(calibratedRed: 0.30, green: 0.85, blue: 0.50, alpha: strong)
        } else if accentChange < -0.05 {
            return NSColor(calibratedRed: 1.0, green: 0.42, blue: 0.42, alpha: strong)
        } else {
            return NSColor(calibratedRed: 0.45, green: 0.55, blue: 0.78, alpha: isHovered ? 0.85 : 0.45)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let circleRect = bounds.insetBy(dx: 3, dy: 3)
        let path = NSBezierPath(ovalIn: circleRect)

        // Soft outer glow on hover
        if isHovered {
            let glow = NSBezierPath(ovalIn: bounds.insetBy(dx: 0.5, dy: 0.5))
            NSColor(calibratedRed: 0.5, green: 0.7, blue: 1.0, alpha: 0.18).setStroke()
            glow.lineWidth = 3
            glow.stroke()
        }

        // Vertical gradient fill for depth
        let top: NSColor
        let bottom: NSColor
        if isHovered {
            top = NSColor(calibratedRed: 0.30, green: 0.42, blue: 0.62, alpha: 0.97)
            bottom = NSColor(calibratedRed: 0.16, green: 0.23, blue: 0.36, alpha: 0.97)
        } else {
            top = NSColor(calibratedRed: 0.22, green: 0.30, blue: 0.44, alpha: 0.92)
            bottom = NSColor(calibratedRed: 0.11, green: 0.15, blue: 0.24, alpha: 0.92)
        }
        if let gradient = NSGradient(starting: top, ending: bottom) {
            gradient.draw(in: path, angle: -90)
        } else {
            bottom.setFill()
            path.fill()
        }

        // Accent ring (reflects market direction)
        accentRingColor().setStroke()
        path.lineWidth = isHovered ? 2 : 1.5
        path.stroke()

        // ₿ glyph with a subtle shadow
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.45)
        shadow.shadowBlurRadius = 2
        shadow.shadowOffset = NSSize(width: 0, height: -1)

        let symbol = "₿"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 19, weight: .semibold),
            .foregroundColor: NSColor.white,
            .shadow: shadow
        ]
        let size = symbol.size(withAttributes: attributes)
        let point = NSPoint(
            x: (bounds.width - size.width) / 2,
            y: (bounds.height - size.height) / 2
        )
        symbol.draw(at: point, withAttributes: attributes)
    }

    private func pulse() {
        guard let layer = self.layer else { return }
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.values = [1.0, 0.86, 1.0]
        animation.keyTimes = [0.0, 0.4, 1.0]
        animation.duration = 0.22
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        layer.add(animation, forKey: "pulse")
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        if bounds.contains(location) {
            pulse()
            onClick?()
        }
    }
}

// MARK: - Glass Content View
class GlassContentView: NSView {
    private let cornerRadius: CGFloat = 22
    var backgroundOpacity: CGFloat = 0.85 {
        didSet { needsDisplay = true }
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        updateCornerMask()
    }

    override func layout() {
        super.layout()
        updateCornerMask()
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updateCornerMask()
    }

    private func updateCornerMask() {
        guard let layer = layer else { return }
        layer.cornerRadius = cornerRadius
        if #available(macOS 10.15, *) {
            layer.cornerCurve = .continuous
        }
        layer.masksToBounds = true

        let mask = CAShapeLayer()
        mask.frame = bounds
        mask.path = CGPath(
            roundedRect: bounds,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )
        layer.mask = mask
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let fillPath = NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius)
        NSColor(calibratedRed: 0.10, green: 0.10, blue: 0.15, alpha: 0.72 * backgroundOpacity).setFill()
        fillPath.fill()

        // Faint inner highlight along the top edge for a glassy sheen
        let highlight = NSBezierPath()
        highlight.move(to: NSPoint(x: cornerRadius, y: bounds.height - 1))
        highlight.line(to: NSPoint(x: bounds.width - cornerRadius, y: bounds.height - 1))
        NSColor(calibratedWhite: 1, alpha: 0.12 * backgroundOpacity).setStroke()
        highlight.lineWidth = 1
        highlight.stroke()

        let strokeRect = bounds.insetBy(dx: 0.75, dy: 0.75)
        let path = NSBezierPath(
            roundedRect: strokeRect,
            xRadius: max(cornerRadius - 0.75, 0),
            yRadius: max(cornerRadius - 0.75, 0)
        )
        NSColor(calibratedRed: 0.4, green: 0.5, blue: 0.7, alpha: 0.3 * backgroundOpacity).setStroke()
        path.lineWidth = 1.5
        path.stroke()
    }
}

// MARK: - Sparkline View
class SparklineView: NSView {
    private var values: [Double] = []

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    func setValues(_ values: [Double]) {
        self.values = values
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard values.count >= 2, bounds.width > 1, bounds.height > 1 else { return }

        let minV = values.min() ?? 0
        let maxV = values.max() ?? 0
        let range = maxV - minV
        let inset: CGFloat = 3
        let stepX = bounds.width / CGFloat(values.count - 1)

        func point(_ i: Int) -> NSPoint {
            let x = CGFloat(i) * stepX
            let norm: CGFloat = range > 0 ? CGFloat((values[i] - minV) / range) : 0.5
            let y = inset + norm * (bounds.height - 2 * inset)
            return NSPoint(x: x, y: y)
        }

        let isUp = (values.last ?? 0) >= (values.first ?? 0)
        let lineColor = isUp
            ? NSColor(calibratedRed: 0.3, green: 0.9, blue: 0.5, alpha: 0.95)
            : NSColor(calibratedRed: 1.0, green: 0.42, blue: 0.42, alpha: 0.95)

        // Gradient fill beneath the line
        let fillPath = NSBezierPath()
        fillPath.move(to: NSPoint(x: 0, y: 0))
        for i in 0..<values.count {
            fillPath.line(to: point(i))
        }
        fillPath.line(to: NSPoint(x: bounds.width, y: 0))
        fillPath.close()
        if let gradient = NSGradient(starting: lineColor.withAlphaComponent(0.0),
                                     ending: lineColor.withAlphaComponent(0.28)) {
            gradient.draw(in: fillPath, angle: 90)
        }

        // The trend line itself
        let linePath = NSBezierPath()
        linePath.lineJoinStyle = .round
        linePath.lineCapStyle = .round
        for i in 0..<values.count {
            if i == 0 { linePath.move(to: point(i)) } else { linePath.line(to: point(i)) }
        }
        lineColor.setStroke()
        linePath.lineWidth = 1.6
        linePath.stroke()

        // End dot to anchor the eye on the latest value
        let last = point(values.count - 1)
        let dot = NSBezierPath(ovalIn: NSRect(x: last.x - 2, y: last.y - 2, width: 4, height: 4))
        lineColor.setFill()
        dot.fill()
    }
}

// MARK: - Seven Day Chart Popup
class SevenDayChartContentView: NSView {
    private let symbol: String
    private let cornerRadius: CGFloat = 22
    var backgroundOpacity: CGFloat = 0.85 {
        didSet { needsDisplay = true }
    }

    private var points: [ChartPoint] = []
    private var isLoading = true
    private var hasError = false
    private var latestPrice: Double?
    private var change24h: Double?
    private var hoveredIndex: Int?
    private var trackingArea: NSTrackingArea?

    private lazy var hoverDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d HH:mm"
        return f
    }()

    init(frame: NSRect, symbol: String, latest: PriceData?) {
        self.symbol = symbol
        if let latest = latest, !latest.hasError {
            self.latestPrice = latest.price
            self.change24h = latest.change24h
        }
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private func setup() {
        wantsLayer = false
        setupTrackingArea()
    }

    override func layout() {
        super.layout()
        updateCornerMask()
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updateCornerMask()
    }

    private func updateCornerMask() {
        guard let layer = layer else { return }
        layer.cornerRadius = cornerRadius
        if #available(macOS 10.15, *) {
            layer.cornerCurve = .continuous
        }
        layer.masksToBounds = true

        let mask = CAShapeLayer()
        mask.frame = bounds
        mask.path = CGPath(
            roundedRect: bounds,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )
        layer.mask = mask
    }

    private func setupTrackingArea() {
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }

        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        trackingArea = area
        addTrackingArea(area)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        setupTrackingArea()
    }

    func setSummary(_ data: PriceData?) {
        guard let data = data, !data.hasError else { return }
        latestPrice = data.price
        change24h = data.change24h
        needsDisplay = true
    }

    func setPoints(_ points: [ChartPoint]) {
        self.points = points
        hoveredIndex = nil
        isLoading = false
        hasError = points.count < 2
        needsDisplay = true
    }

    private func attributes(font: NSFont, color: NSColor, alignment: NSTextAlignment = .left) -> [NSAttributedString.Key: Any] {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        return [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: style
        ]
    }

    private func sevenDayChange() -> Double? {
        guard points.count >= 2,
              let first = points.first?.price,
              first != 0,
              let last = points.last?.price else {
            return nil
        }
        return ((last - first) / first) * 100
    }

    private func chartRect() -> NSRect {
        return NSRect(x: 18, y: 28, width: bounds.width - 36, height: 104)
    }

    private func updateHover(at location: NSPoint?) {
        guard points.count >= 2, let location = location, chartRect().contains(location) else {
            if hoveredIndex != nil {
                hoveredIndex = nil
                needsDisplay = true
            }
            return
        }

        let rect = chartRect()
        let clampedX = min(max(location.x, rect.minX), rect.maxX)
        let ratio = (clampedX - rect.minX) / rect.width
        let index = Int(round(ratio * CGFloat(points.count - 1)))
        let clampedIndex = min(max(index, 0), points.count - 1)

        if hoveredIndex != clampedIndex {
            hoveredIndex = clampedIndex
            needsDisplay = true
        }
    }

    override func mouseMoved(with event: NSEvent) {
        updateHover(at: convert(event.locationInWindow, from: nil))
    }

    override func mouseExited(with event: NSEvent) {
        updateHover(at: nil)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let fillPath = NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius)
        NSColor(calibratedRed: 0.08, green: 0.09, blue: 0.13, alpha: 0.94 * backgroundOpacity).setFill()
        fillPath.fill()

        let strokeRect = bounds.insetBy(dx: 0.75, dy: 0.75)
        let strokePath = NSBezierPath(
            roundedRect: strokeRect,
            xRadius: max(cornerRadius - 0.75, 0),
            yRadius: max(cornerRadius - 0.75, 0)
        )
        NSColor(calibratedRed: 0.48, green: 0.58, blue: 0.78, alpha: 0.36 * backgroundOpacity).setStroke()
        strokePath.lineWidth = 1.5
        strokePath.stroke()

        let titleAttrs = attributes(
            font: NSFont.systemFont(ofSize: 14, weight: .semibold),
            color: .white
        )
        "\(symbol)/USDT".draw(at: NSPoint(x: 18, y: bounds.height - 33), withAttributes: titleAttrs)

        let tagAttrs = attributes(
            font: NSFont.systemFont(ofSize: 10, weight: .semibold),
            color: NSColor(calibratedRed: 0.72, green: 0.82, blue: 1, alpha: 0.72),
            alignment: .right
        )
        "7D".draw(in: NSRect(x: bounds.width - 62, y: bounds.height - 31, width: 44, height: 14), withAttributes: tagAttrs)

        let hoveredPoint = hoveredIndex.flatMap { points.indices.contains($0) ? points[$0] : nil }
        let displayPrice = hoveredPoint?.price ?? latestPrice

        if let displayPrice = displayPrice {
            let priceAttrs = attributes(
                font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
                color: NSColor(calibratedWhite: 1, alpha: 0.82)
            )
            PriceFormatter.shared.format(displayPrice).draw(
                at: NSPoint(x: 18, y: bounds.height - 54),
                withAttributes: priceAttrs
            )
        }

        if let hoveredPoint = hoveredPoint {
            let dateAttrs = attributes(
                font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular),
                color: NSColor(calibratedRed: 0.72, green: 0.82, blue: 1, alpha: 0.72),
                alignment: .right
            )
            hoverDateFormatter.string(from: Date(timeIntervalSince1970: hoveredPoint.time)).draw(
                in: NSRect(x: bounds.width - 122, y: bounds.height - 54, width: 104, height: 14),
                withAttributes: dateAttrs
            )
        } else if let change = sevenDayChange() ?? change24h {
            let isUp = change >= 0
            let color = isUp
                ? NSColor(calibratedRed: 0.3, green: 0.9, blue: 0.5, alpha: 0.95)
                : NSColor(calibratedRed: 1.0, green: 0.42, blue: 0.42, alpha: 0.95)
            let changeAttrs = attributes(
                font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
                color: color,
                alignment: .right
            )
            let text = String(format: "%@%.2f%%", isUp ? "+" : "", change)
            text.draw(in: NSRect(x: bounds.width - 100, y: bounds.height - 54, width: 82, height: 16), withAttributes: changeAttrs)
        }

        drawChart(in: chartRect())
    }

    private func drawChart(in rect: NSRect) {
        let gridColor = NSColor(calibratedWhite: 1, alpha: 0.08)
        for i in 0...3 {
            let y = rect.minY + rect.height * CGFloat(i) / 3.0
            let line = NSBezierPath()
            line.move(to: NSPoint(x: rect.minX, y: y))
            line.line(to: NSPoint(x: rect.maxX, y: y))
            gridColor.setStroke()
            line.lineWidth = 0.6
            line.stroke()
        }

        guard points.count >= 2, !hasError else {
            let text = isLoading ? "Loading chart..." : "Chart unavailable"
            let attrs = attributes(
                font: NSFont.systemFont(ofSize: 12, weight: .regular),
                color: NSColor(calibratedWhite: 1, alpha: 0.52),
                alignment: .center
            )
            text.draw(in: NSRect(x: rect.minX, y: rect.midY - 8, width: rect.width, height: 18), withAttributes: attrs)
            return
        }

        let values = points.map { $0.price }
        let minV = values.min() ?? 0
        let maxV = values.max() ?? 0
        let range = max(maxV - minV, 0.00000001)
        let inset: CGFloat = 7
        let stepX = rect.width / CGFloat(values.count - 1)

        func point(_ i: Int) -> NSPoint {
            let x = rect.minX + CGFloat(i) * stepX
            let norm = CGFloat((values[i] - minV) / range)
            let y = rect.minY + inset + norm * (rect.height - 2 * inset)
            return NSPoint(x: x, y: y)
        }

        let isUp = (values.last ?? 0) >= (values.first ?? 0)
        let lineColor = isUp
            ? NSColor(calibratedRed: 0.3, green: 0.9, blue: 0.5, alpha: 0.98)
            : NSColor(calibratedRed: 1.0, green: 0.42, blue: 0.42, alpha: 0.98)

        let fillPath = NSBezierPath()
        fillPath.move(to: NSPoint(x: rect.minX, y: rect.minY))
        for i in 0..<values.count {
            fillPath.line(to: point(i))
        }
        fillPath.line(to: NSPoint(x: rect.maxX, y: rect.minY))
        fillPath.close()
        if let gradient = NSGradient(
            starting: lineColor.withAlphaComponent(0.02),
            ending: lineColor.withAlphaComponent(0.26)
        ) {
            gradient.draw(in: fillPath, angle: 90)
        }

        let linePath = NSBezierPath()
        linePath.lineJoinStyle = .round
        linePath.lineCapStyle = .round
        for i in 0..<values.count {
            if i == 0 {
                linePath.move(to: point(i))
            } else {
                linePath.line(to: point(i))
            }
        }
        lineColor.setStroke()
        linePath.lineWidth = 2
        linePath.stroke()

        let last = point(values.count - 1)
        let dot = NSBezierPath(ovalIn: NSRect(x: last.x - 3, y: last.y - 3, width: 6, height: 6))
        lineColor.setFill()
        dot.fill()

        if let hoveredIndex = hoveredIndex, values.indices.contains(hoveredIndex) {
            let hovered = point(hoveredIndex)

            let guide = NSBezierPath()
            guide.move(to: NSPoint(x: hovered.x, y: rect.minY))
            guide.line(to: NSPoint(x: hovered.x, y: rect.maxY))
            NSColor(calibratedWhite: 1, alpha: 0.22).setStroke()
            guide.lineWidth = 1
            guide.stroke()

            let ring = NSBezierPath(ovalIn: NSRect(x: hovered.x - 4, y: hovered.y - 4, width: 8, height: 8))
            NSColor(calibratedRed: 0.08, green: 0.09, blue: 0.13, alpha: 0.96).setFill()
            ring.fill()
            lineColor.setStroke()
            ring.lineWidth = 2
            ring.stroke()

            let tooltip = PriceFormatter.shared.format(values[hoveredIndex])
            let tooltipAttrs = attributes(
                font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .medium),
                color: .white,
                alignment: .center
            )
            let textSize = tooltip.size(withAttributes: tooltipAttrs)
            let tooltipWidth = min(max(textSize.width + 14, 72), rect.width)
            let tooltipX = min(max(hovered.x - tooltipWidth / 2, rect.minX), rect.maxX - tooltipWidth)
            let tooltipY = min(hovered.y + 12, rect.maxY - 22)
            let tooltipRect = NSRect(x: tooltipX, y: tooltipY, width: tooltipWidth, height: 20)
            let tooltipPath = NSBezierPath(roundedRect: tooltipRect, xRadius: 7, yRadius: 7)
            NSColor(calibratedRed: 0.05, green: 0.06, blue: 0.09, alpha: 0.9).setFill()
            tooltipPath.fill()
            NSColor(calibratedWhite: 1, alpha: 0.16).setStroke()
            tooltipPath.lineWidth = 1
            tooltipPath.stroke()
            tooltip.draw(in: tooltipRect.insetBy(dx: 4, dy: 3), withAttributes: tooltipAttrs)
        }

        let rangeAttrs = attributes(
            font: NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .regular),
            color: NSColor(calibratedWhite: 1, alpha: 0.42),
            alignment: .right
        )
        PriceFormatter.shared.compact(maxV).draw(
            in: NSRect(x: rect.maxX - 76, y: rect.maxY - 14, width: 76, height: 12),
            withAttributes: rangeAttrs
        )
        PriceFormatter.shared.compact(minV).draw(
            in: NSRect(x: rect.maxX - 76, y: rect.minY + 2, width: 76, height: 12),
            withAttributes: rangeAttrs
        )
    }
}

// MARK: - Animated Price Label
class AnimatedPriceLabel: NSTextField {
    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        layer?.masksToBounds = false
    }

    func flashGreen() {
        flash(color: NSColor(calibratedRed: 0.2, green: 0.9, blue: 0.4, alpha: 0.8))
    }

    func flashRed() {
        flash(color: NSColor(calibratedRed: 1.0, green: 0.3, blue: 0.3, alpha: 0.8))
    }

    private func flash(color: NSColor) {
        guard let layer = self.layer else { return }

        let flash = CALayer()
        flash.frame = layer.bounds.insetBy(dx: -4, dy: -2)
        flash.cornerRadius = 4
        flash.backgroundColor = color.cgColor
        flash.opacity = 0

        layer.insertSublayer(flash, at: 0)

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            flash.removeFromSuperlayer()
        }

        let animation = CAKeyframeAnimation(keyPath: "opacity")
        animation.values = [0.0, 0.7, 0.5, 0.0]
        animation.keyTimes = [0.0, 0.1, 0.5, 1.0]
        animation.duration = 0.6
        animation.isRemovedOnCompletion = true

        flash.add(animation, forKey: "flash")

        CATransaction.commit()
    }

    func animateValueChange(goingUp: Bool) {
        guard let layer = self.layer else { return }

        if goingUp {
            flashGreen()
        } else {
            flashRed()
        }

        let slideDistance: CGFloat = goingUp ? 3 : -3

        let slideAnimation = CAKeyframeAnimation(keyPath: "position.y")
        slideAnimation.values = [
            layer.position.y,
            layer.position.y + slideDistance,
            layer.position.y
        ]
        slideAnimation.keyTimes = [0.0, 0.3, 1.0]
        slideAnimation.duration = 0.3
        slideAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)

        layer.add(slideAnimation, forKey: "slide")

        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnimation.values = [1.0, 1.08, 1.0]
        scaleAnimation.keyTimes = [0.0, 0.2, 1.0]
        scaleAnimation.duration = 0.3
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)

        layer.add(scaleAnimation, forKey: "scale")
    }
}

// MARK: - Crypto Row View
class CryptoRowView: NSView {
    let symbol: String
    let showSparkline: Bool
    var onClick: ((CryptoRowView) -> Void)?

    private let symbolLabel = NSTextField(labelWithString: "")
    private let priceLabel = AnimatedPriceLabel(labelWithString: "Loading…")
    private let changeLabel = NSTextField(labelWithString: "")
    private let arrowLabel = NSTextField(labelWithString: "")
    private var sparklineView: SparklineView?

    private var lastPrice: Double = 0
    private var hasLoaded = false
    private var isHovered = false

    private let dimColor = NSColor(calibratedWhite: 0.75, alpha: 0.45)

    init(frame: NSRect, symbol: String, showSparkline: Bool) {
        self.symbol = symbol
        self.showSparkline = showSparkline
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private func makeLabel(_ field: NSTextField) {
        field.isBezeled = false
        field.drawsBackground = false
        field.isEditable = false
        field.isSelectable = false
    }

    private func setup() {
        wantsLayer = true
        let w = bounds.width

        makeLabel(symbolLabel)
        makeLabel(priceLabel)
        makeLabel(changeLabel)
        makeLabel(arrowLabel)

        symbolLabel.stringValue = symbol
        symbolLabel.textColor = .white
        addSubview(symbolLabel)

        priceLabel.textColor = .white
        priceLabel.alignment = .left
        addSubview(priceLabel)

        changeLabel.alignment = .right
        addSubview(changeLabel)

        arrowLabel.alignment = .center
        arrowLabel.wantsLayer = true

        if showSparkline {
            // Two-line layout: symbol + 24h% on top, price + arrow + sparkline below.
            symbolLabel.font = NSFont.boldSystemFont(ofSize: 14)
            symbolLabel.frame = NSRect(x: 14, y: 26, width: 90, height: 18)

            changeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
            changeLabel.frame = NSRect(x: w - 84, y: 27, width: 72, height: 16)

            priceLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
            priceLabel.frame = NSRect(x: 14, y: 6, width: 104, height: 18)

            arrowLabel.font = NSFont.systemFont(ofSize: 10, weight: .bold)
            arrowLabel.frame = NSRect(x: 118, y: 7, width: 14, height: 16)
            addSubview(arrowLabel)

            let spark = SparklineView(frame: NSRect(x: 140, y: 10, width: w - 152, height: 28))
            addSubview(spark)
            sparklineView = spark
        } else {
            // Compact single-line layout.
            symbolLabel.font = NSFont.boldSystemFont(ofSize: 14)
            symbolLabel.frame = NSRect(x: 14, y: 5, width: 56, height: 20)

            priceLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
            priceLabel.frame = NSRect(x: 74, y: 5, width: 64, height: 20)

            changeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
            changeLabel.frame = NSRect(x: w - 76, y: 6, width: 64, height: 18)
        }

        let tracking = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(tracking)

        let click = NSClickGestureRecognizer(target: self, action: #selector(handleClick(_:)))
        click.numberOfClicksRequired = 1
        addGestureRecognizer(click)
    }

    func setSparkline(_ values: [Double]) {
        sparklineView?.setValues(values)
    }

    func update(price: Double, change: Double, hasError: Bool) {
        if hasError {
            if hasLoaded {
                // Keep the last known price, just dim it to signal staleness.
                priceLabel.textColor = dimColor
                changeLabel.textColor = dimColor
                arrowLabel.stringValue = ""
            } else {
                priceLabel.stringValue = "—"
                priceLabel.textColor = dimColor
                changeLabel.stringValue = ""
                arrowLabel.stringValue = ""
            }
            return
        }

        let priceWentUp = hasLoaded && price > lastPrice
        let priceWentDown = hasLoaded && price < lastPrice
        let priceChanged = hasLoaded && price != lastPrice

        priceLabel.stringValue = PriceFormatter.shared.format(price)
        priceLabel.textColor = .white

        if priceChanged {
            if priceWentUp {
                arrowLabel.stringValue = "▲"
                arrowLabel.textColor = NSColor(calibratedRed: 0.3, green: 0.9, blue: 0.5, alpha: 1)
                priceLabel.animateValueChange(goingUp: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.fadeOutArrow()
                }
            } else if priceWentDown {
                arrowLabel.stringValue = "▼"
                arrowLabel.textColor = NSColor(calibratedRed: 1, green: 0.4, blue: 0.4, alpha: 1)
                priceLabel.animateValueChange(goingUp: false)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.fadeOutArrow()
                }
            }
        }

        if change >= 0 {
            changeLabel.stringValue = String(format: "+%.2f%%", change)
            changeLabel.textColor = NSColor(calibratedRed: 0.3, green: 0.9, blue: 0.5, alpha: 1)
        } else {
            changeLabel.stringValue = String(format: "%.2f%%", change)
            changeLabel.textColor = NSColor(calibratedRed: 1, green: 0.4, blue: 0.4, alpha: 1)
        }

        lastPrice = price
        hasLoaded = true
    }

    private func fadeOutArrow() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5
            arrowLabel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.arrowLabel.stringValue = ""
            self?.arrowLabel.alphaValue = 1
        })
    }

    @objc private func handleClick(_ sender: NSClickGestureRecognizer) {
        guard sender.state == .ended else { return }
        onClick?(self)
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if isHovered {
            let bg = NSBezierPath(roundedRect: bounds.insetBy(dx: 4, dy: 3), xRadius: 8, yRadius: 8)
            NSColor(calibratedWhite: 1, alpha: 0.06).setFill()
            bg.fill()
        }

        let separator = NSBezierPath()
        separator.move(to: NSPoint(x: 12, y: 0.5))
        separator.line(to: NSPoint(x: bounds.width - 12, y: 0.5))
        NSColor(calibratedWhite: 1, alpha: 0.07).setStroke()
        separator.lineWidth = 0.5
        separator.stroke()
    }
}

// MARK: - Floating Window
class FloatingWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.borderless, .fullSizeContentView], backing: .buffered, defer: false)

        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .stationary]
    }

    override var canBecomeKey: Bool { true }
}

class ChartPopupWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.borderless, .fullSizeContentView], backing: .buffered, defer: false)

        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
    }

    override var canBecomeKey: Bool { true }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var floatingWindow: FloatingWindow!
    var config: AppConfig!
    var cryptoRows: [String: CryptoRowView] = [:]
    var updateTimer: Timer?
    var toggleButton: ToggleButtonView!
    var contentPanel: GlassContentView?
    var containerView: NSView!
    var chartWindow: ChartPopupWindow?
    var chartContentView: SevenDayChartContentView?
    var chartDismissalMonitors: [Any] = []
    var activeChartSymbol: String?

    var transparencyMenu: NSMenu!
    var refreshRateMenu: NSMenu!
    var removeMenu: NSMenu!
    var menuBarMenu: NSMenu!
    var expandCollapseItem: NSMenuItem!
    var sparklineToggleItem: NSMenuItem!
    var updatedLabel: NSTextField?

    var latestPrices: [String: PriceData] = [:]
    var sparklineCache: [String: (values: [Double], fetchedAt: Date)] = [:]
    var chartCache: [String: (points: [ChartPoint], fetchedAt: Date)] = [:]

    let toggleButtonSize: CGFloat = 44
    let panelWidth: CGFloat = 220
    let chartPopupSize = NSSize(width: 300, height: 190)
    let headerHeight: CGFloat = 30
    let padding: CGFloat = 12

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    let refreshRates: [(label: String, seconds: Int)] = [
        ("5 seconds", 5),
        ("10 seconds", 10),
        ("15 seconds", 15),
        ("30 seconds", 30),
        ("1 minute", 60),
        ("2 minutes", 120),
        ("5 minutes", 300)
    ]

    var rowHeight: CGFloat {
        return config.showSparklines ? 48 : 30
    }

    var expandedWidth: CGFloat {
        return toggleButtonSize + 10 + panelWidth + 5
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        config = AppConfig.load()
        sanitizeMenuBarSymbol()

        setupStatusBar()
        setupWindow()
        startUpdateTimer()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hideChartPopup()
        let frame = floatingWindow.frame
        config.windowX = Double(frame.origin.x)
        config.windowY = Double(frame.origin.y)
        config.save()
    }

    private func sanitizeMenuBarSymbol() {
        if let sym = config.menuBarSymbol, !config.cryptos.contains(sym) {
            config.menuBarSymbol = nil
        }
    }

    // MARK: - Setup
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "₿"
        statusItem.button?.font = NSFont.systemFont(ofSize: 14)

        let menu = NSMenu()

        let showItem = NSMenuItem(title: "Show/Hide Window", action: #selector(toggleWindowVisibility), keyEquivalent: "")
        showItem.target = self
        menu.addItem(showItem)

        expandCollapseItem = NSMenuItem(title: config.isExpanded ? "Collapse Prices" : "Expand Prices", action: #selector(toggleExpandedFromMenu), keyEquivalent: "")
        expandCollapseItem.target = self
        menu.addItem(expandCollapseItem)

        menu.addItem(NSMenuItem.separator())

        // Transparency submenu
        transparencyMenu = NSMenu()
        for level in [100, 90, 80, 70, 60, 50] {
            let item = NSMenuItem(title: "\(level)%", action: #selector(setTransparency(_:)), keyEquivalent: "")
            item.target = self
            item.tag = level
            if Int(config.transparency * 100) == level {
                item.state = .on
            }
            transparencyMenu.addItem(item)
        }
        let transparencyItem = NSMenuItem(title: "Transparency", action: nil, keyEquivalent: "")
        transparencyItem.submenu = transparencyMenu
        menu.addItem(transparencyItem)

        // Refresh Rate submenu
        refreshRateMenu = NSMenu()
        for rate in refreshRates {
            let item = NSMenuItem(title: rate.label, action: #selector(setRefreshRate(_:)), keyEquivalent: "")
            item.target = self
            item.tag = rate.seconds
            if config.refreshRate == rate.seconds {
                item.state = .on
            }
            refreshRateMenu.addItem(item)
        }
        let refreshRateItem = NSMenuItem(title: "Refresh Rate", action: nil, keyEquivalent: "")
        refreshRateItem.submenu = refreshRateMenu
        menu.addItem(refreshRateItem)

        // Sparkline toggle
        sparklineToggleItem = NSMenuItem(title: "Show Sparklines", action: #selector(toggleSparklines(_:)), keyEquivalent: "")
        sparklineToggleItem.target = self
        sparklineToggleItem.state = config.showSparklines ? .on : .off
        menu.addItem(sparklineToggleItem)

        // Menu Bar Display submenu
        menuBarMenu = NSMenu()
        updateMenuBarMenu()
        let menuBarItem = NSMenuItem(title: "Menu Bar Display", action: nil, keyEquivalent: "")
        menuBarItem.submenu = menuBarMenu
        menu.addItem(menuBarItem)

        menu.addItem(NSMenuItem.separator())

        let addItem = NSMenuItem(title: "Add Cryptocurrency…", action: #selector(addCrypto), keyEquivalent: "")
        addItem.target = self
        menu.addItem(addItem)

        removeMenu = NSMenu()
        updateRemoveMenu()
        let removeItem = NSMenuItem(title: "Remove Cryptocurrency", action: nil, keyEquivalent: "")
        removeItem.submenu = removeMenu
        menu.addItem(removeItem)

        let resetItem = NSMenuItem(title: "Reset to Defaults", action: #selector(resetDefaults), keyEquivalent: "")
        resetItem.target = self
        menu.addItem(resetItem)

        menu.addItem(NSMenuItem.separator())

        let refreshItem = NSMenuItem(title: "Refresh Now", action: #selector(refreshPrices), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit CryptoFloat", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    func updateRemoveMenu() {
        removeMenu.removeAllItems()
        for symbol in config.cryptos {
            let item = NSMenuItem(title: symbol, action: #selector(removeCrypto(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = symbol
            removeMenu.addItem(item)
        }
    }

    func updateMenuBarMenu() {
        menuBarMenu.removeAllItems()

        let iconItem = NSMenuItem(title: "Icon Only (₿)", action: #selector(setMenuBarSymbol(_:)), keyEquivalent: "")
        iconItem.target = self
        iconItem.representedObject = nil
        iconItem.state = (config.menuBarSymbol == nil) ? .on : .off
        menuBarMenu.addItem(iconItem)

        if !config.cryptos.isEmpty {
            menuBarMenu.addItem(NSMenuItem.separator())
        }

        for symbol in config.cryptos {
            let item = NSMenuItem(title: symbol, action: #selector(setMenuBarSymbol(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = symbol
            item.state = (config.menuBarSymbol == symbol) ? .on : .off
            menuBarMenu.addItem(item)
        }
    }

    func calculateWindowSize() -> (width: CGFloat, height: CGFloat) {
        if config.isExpanded {
            let contentHeight = headerHeight + (rowHeight * CGFloat(config.cryptos.count)) + padding
            return (expandedWidth, max(contentHeight + 10, toggleButtonSize + 10))
        } else {
            return (toggleButtonSize + 10, toggleButtonSize + 10)
        }
    }

    func setupWindow() {
        let (width, height) = calculateWindowSize()
        let frame = NSRect(x: config.windowX, y: config.windowY, width: Double(width), height: Double(height))

        floatingWindow = FloatingWindow(contentRect: frame, styleMask: [], backing: .buffered, defer: false)
        floatingWindow.alphaValue = 1

        containerView = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        floatingWindow.contentView = containerView

        toggleButton = ToggleButtonView(frame: NSRect(x: 5, y: 5, width: toggleButtonSize, height: toggleButtonSize))
        toggleButton.isExpanded = config.isExpanded
        toggleButton.onClick = { [weak self] in
            self?.toggleExpanded()
        }
        containerView.addSubview(toggleButton)

        setupContentPanel()

        floatingWindow.makeKeyAndOrderFront(nil)
    }

    func setupContentPanel() {
        contentPanel?.removeFromSuperview()
        cryptoRows.removeAll()
        updatedLabel = nil

        guard config.isExpanded else { return }

        let contentHeight = headerHeight + (rowHeight * CGFloat(config.cryptos.count)) + padding

        contentPanel = GlassContentView(frame: NSRect(x: toggleButtonSize + 10, y: 5, width: panelWidth, height: contentHeight))
        contentPanel?.backgroundOpacity = CGFloat(config.transparency)
        containerView.addSubview(contentPanel!)

        let titleLabel = NSTextField(labelWithString: "PRICES · USDT")
        titleLabel.font = NSFont.systemFont(ofSize: 9, weight: .semibold)
        titleLabel.textColor = NSColor(calibratedRed: 0.72, green: 0.82, blue: 1, alpha: 0.8)
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.frame = NSRect(x: 14, y: contentHeight - 23, width: 80, height: 16)
        contentPanel?.addSubview(titleLabel)

        let updated = NSTextField(labelWithString: "")
        updated.font = NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .regular)
        updated.alignment = .right
        updated.textColor = NSColor(calibratedRed: 0.7, green: 0.8, blue: 1, alpha: 0.5)
        updated.isBezeled = false
        updated.drawsBackground = false
        updated.isEditable = false
        updated.frame = NSRect(x: panelWidth - 124, y: contentHeight - 23, width: 110, height: 16)
        contentPanel?.addSubview(updated)
        updatedLabel = updated

        for (index, symbol) in config.cryptos.enumerated() {
            let yPos = contentHeight - headerHeight - (CGFloat(index + 1) * rowHeight)

            let row = CryptoRowView(
                frame: NSRect(x: 0, y: yPos, width: panelWidth, height: rowHeight),
                symbol: symbol,
                showSparkline: config.showSparklines
            )
            row.onClick = { [weak self] _ in
                self?.showChartPopup(for: symbol)
            }
            contentPanel?.addSubview(row)
            cryptoRows[symbol] = row

            if let cached = sparklineCache[symbol]?.values {
                row.setSparkline(cached)
            }
        }

        updateStatusLabel()
    }

    private func chartAnchorScreenRect() -> NSRect {
        if let panel = contentPanel {
            let panelInWindow = panel.convert(panel.bounds, to: nil)
            return floatingWindow.convertToScreen(panelInWindow)
        }

        if let contentView = floatingWindow.contentView {
            let contentInWindow = contentView.convert(contentView.bounds, to: nil)
            return floatingWindow.convertToScreen(contentInWindow)
        }

        return floatingWindow.frame
    }

    func showChartPopup(for symbol: String) {
        hideChartPopup()
        activeChartSymbol = symbol

        let anchor = chartAnchorScreenRect()
        var origin = NSPoint(
            x: anchor.maxX + 10,
            y: anchor.maxY - chartPopupSize.height
        )

        if let visibleFrame = floatingWindow.screen?.visibleFrame ?? NSScreen.main?.visibleFrame {
            if origin.x + chartPopupSize.width > visibleFrame.maxX - 8 {
                origin.x = anchor.minX - chartPopupSize.width - 10
            }
            origin.x = min(max(origin.x, visibleFrame.minX + 8), visibleFrame.maxX - chartPopupSize.width - 8)
            origin.y = min(max(origin.y, visibleFrame.minY + 8), visibleFrame.maxY - chartPopupSize.height - 8)
        }

        let frame = NSRect(origin: origin, size: chartPopupSize)
        let popup = ChartPopupWindow(contentRect: frame, styleMask: [], backing: .buffered, defer: false)
        popup.alphaValue = 1
        popup.acceptsMouseMovedEvents = true

        let content = SevenDayChartContentView(
            frame: NSRect(origin: .zero, size: chartPopupSize),
            symbol: symbol,
            latest: latestPrices[symbol]
        )
        content.backgroundOpacity = CGFloat(config.transparency)
        popup.contentView = content
        content.needsDisplay = true
        chartWindow = popup
        chartContentView = content

        popup.displayIfNeeded()
        popup.orderFront(nil)
        installChartDismissalMonitors()

        if let cached = chartCache[symbol], Date().timeIntervalSince(cached.fetchedAt) < 600 {
            content.setPoints(cached.points)
            return
        }

        CryptoAPI.shared.fetchSevenDayChart(for: symbol) { [weak self, weak content] points in
            guard let self = self, self.activeChartSymbol == symbol else { return }
            if !points.isEmpty {
                self.chartCache[symbol] = (points, Date())
            }
            content?.setSummary(self.latestPrices[symbol])
            content?.setPoints(points)
        }
    }

    func hideChartPopup() {
        removeChartDismissalMonitors()
        chartWindow?.orderOut(nil)
        chartWindow = nil
        chartContentView = nil
        activeChartSymbol = nil
    }

    private func installChartDismissalMonitors() {
        removeChartDismissalMonitors()

        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.chartWindow != nil else { return }

            var monitors: [Any] = []
            if let local = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown], handler: { [weak self] _ in
                self?.hideChartPopup()
                return nil
            }) {
                monitors.append(local)
            }

            if let global = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown], handler: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.hideChartPopup()
                }
            }) {
                monitors.append(global)
            }

            self.chartDismissalMonitors = monitors
        }
    }

    private func removeChartDismissalMonitors() {
        for monitor in chartDismissalMonitors {
            NSEvent.removeMonitor(monitor)
        }
        chartDismissalMonitors.removeAll()
    }

    func toggleExpanded() {
        hideChartPopup()
        config.isExpanded.toggle()
        config.save()

        toggleButton.isExpanded = config.isExpanded
        expandCollapseItem.title = config.isExpanded ? "Collapse Prices" : "Expand Prices"

        let (width, height) = calculateWindowSize()
        var frame = floatingWindow.frame
        frame.origin.y += frame.size.height - height
        frame.size = NSSize(width: width, height: height)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            floatingWindow.animator().setFrame(frame, display: true)
        }

        containerView.frame = NSRect(x: 0, y: 0, width: width, height: height)
        toggleButton.frame = NSRect(x: 5, y: 5, width: toggleButtonSize, height: toggleButtonSize)

        if config.isExpanded {
            setupContentPanel()
            refreshPrices()
        } else {
            contentPanel?.removeFromSuperview()
            contentPanel = nil
            updatedLabel = nil
        }
    }

    func rebuildWindow() {
        guard config.isExpanded else { return }
        hideChartPopup()

        let (width, height) = calculateWindowSize()
        var frame = floatingWindow.frame
        frame.origin.y += frame.size.height - height
        frame.size = NSSize(width: width, height: height)
        floatingWindow.setFrame(frame, display: true)

        containerView.frame = NSRect(x: 0, y: 0, width: width, height: height)
        toggleButton.frame = NSRect(x: 5, y: 5, width: toggleButtonSize, height: toggleButtonSize)

        setupContentPanel()
        refreshPrices()
    }

    // MARK: - Timer
    func startUpdateTimer() {
        refreshPrices()
        updateTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(config.refreshRate), repeats: true) { [weak self] _ in
            self?.refreshPrices()
        }
    }

    func restartUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(config.refreshRate), repeats: true) { [weak self] _ in
            self?.refreshPrices()
        }
    }

    @objc func refreshPrices() {
        guard config.isExpanded else { return }

        CryptoAPI.shared.fetchAllPrices(for: config.cryptos) { [weak self] prices in
            guard let self = self else { return }
            self.latestPrices = prices
            for (symbol, data) in prices {
                self.cryptoRows[symbol]?.update(price: data.price, change: data.change24h, hasError: data.hasError)
            }
            if let activeSymbol = self.activeChartSymbol {
                self.chartContentView?.setSummary(prices[activeSymbol])
            }
            self.updateMenuBarTitle()
            self.updateAccent()
            self.updateStatusLabel()
            self.refreshSparklines()
        }
    }

    /// Fetches sparkline data for tracked coins, throttled so each symbol is
    /// only re-fetched roughly every 5 minutes regardless of the price refresh rate.
    func refreshSparklines() {
        guard config.isExpanded, config.showSparklines else { return }

        let now = Date()
        for symbol in config.cryptos {
            if let cached = sparklineCache[symbol] {
                cryptoRows[symbol]?.setSparkline(cached.values)
                if now.timeIntervalSince(cached.fetchedAt) < 290 { continue }
            }
            CryptoAPI.shared.fetchSparkline(for: symbol) { [weak self] values in
                guard let self = self else { return }
                if !values.isEmpty {
                    self.sparklineCache[symbol] = (values, Date())
                    self.cryptoRows[symbol]?.setSparkline(values)
                }
            }
        }
    }

    func updateMenuBarTitle() {
        guard let button = statusItem.button else { return }
        if let sym = config.menuBarSymbol, let data = latestPrices[sym], !data.hasError, data.price > 0 {
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            button.title = "\(sym) \(PriceFormatter.shared.compact(data.price))"
        } else {
            button.font = NSFont.systemFont(ofSize: 14)
            button.title = "₿"
        }
    }

    func updateAccent() {
        let primary = config.menuBarSymbol ?? config.cryptos.first
        if let p = primary, let data = latestPrices[p], !data.hasError {
            toggleButton.accentChange = data.change24h
        } else {
            toggleButton.accentChange = 0
        }
    }

    func updateStatusLabel() {
        guard let label = updatedLabel else { return }
        let symbols = config.cryptos
        if symbols.isEmpty {
            label.stringValue = ""
            return
        }
        let erroredCount = symbols.filter { (latestPrices[$0]?.hasError ?? true) }.count
        if erroredCount == symbols.count {
            label.stringValue = "reconnecting…"
            label.textColor = NSColor(calibratedRed: 1, green: 0.5, blue: 0.5, alpha: 0.7)
        } else {
            label.stringValue = "updated \(timeFormatter.string(from: Date()))"
            label.textColor = NSColor(calibratedRed: 0.7, green: 0.8, blue: 1, alpha: 0.55)
        }
    }

    // MARK: - Actions
    @objc func toggleWindowVisibility() {
        if floatingWindow.isVisible {
            hideChartPopup()
            floatingWindow.orderOut(nil)
        } else {
            floatingWindow.makeKeyAndOrderFront(nil)
        }
    }

    @objc func toggleExpandedFromMenu() {
        toggleExpanded()
    }

    @objc func setTransparency(_ sender: NSMenuItem) {
        let level = Double(sender.tag) / 100.0
        config.transparency = level
        config.save()
        floatingWindow.alphaValue = 1
        contentPanel?.backgroundOpacity = CGFloat(level)
        chartContentView?.backgroundOpacity = CGFloat(level)

        for item in transparencyMenu.items {
            item.state = item.tag == sender.tag ? .on : .off
        }
    }

    @objc func setRefreshRate(_ sender: NSMenuItem) {
        config.refreshRate = sender.tag
        config.save()

        for item in refreshRateMenu.items {
            item.state = item.tag == sender.tag ? .on : .off
        }

        restartUpdateTimer()
    }

    @objc func toggleSparklines(_ sender: NSMenuItem) {
        config.showSparklines.toggle()
        config.save()
        sparklineToggleItem.state = config.showSparklines ? .on : .off
        rebuildWindow()
        if config.showSparklines {
            refreshSparklines()
        }
    }

    @objc func setMenuBarSymbol(_ sender: NSMenuItem) {
        config.menuBarSymbol = sender.representedObject as? String
        config.save()
        updateMenuBarMenu()
        updateMenuBarTitle()
        updateAccent()
    }

    @objc func addCrypto() {
        let alert = NSAlert()
        alert.messageText = "Add Cryptocurrency"
        alert.informativeText = "Enter the trading symbol (e.g., 'BTC', 'ETH', 'SOL', 'DOGE').\n\nThe symbol will be paired with USDT on KuCoin."
        alert.addButton(withTitle: "Add")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.placeholderString = "e.g., BTC"
        alert.accessoryView = textField

        if alert.runModal() == .alertFirstButtonReturn {
            let symbol = textField.stringValue.trimmingCharacters(in: .whitespaces).uppercased()
            if !symbol.isEmpty && !config.cryptos.contains(symbol) {
                config.cryptos.append(symbol)
                config.save()
                updateRemoveMenu()
                updateMenuBarMenu()
                rebuildWindow()
            }
        }
    }

    @objc func removeCrypto(_ sender: NSMenuItem) {
        guard let symbol = sender.representedObject as? String else { return }
        if activeChartSymbol == symbol {
            hideChartPopup()
        }
        config.cryptos.removeAll { $0 == symbol }
        sparklineCache[symbol] = nil
        chartCache[symbol] = nil
        if config.menuBarSymbol == symbol {
            config.menuBarSymbol = nil
        }
        config.save()
        updateRemoveMenu()
        updateMenuBarMenu()
        updateMenuBarTitle()
        rebuildWindow()
    }

    @objc func resetDefaults() {
        hideChartPopup()
        config.cryptos = AppConfig.default.cryptos
        config.refreshRate = AppConfig.default.refreshRate
        sanitizeMenuBarSymbol()
        config.save()
        updateRemoveMenu()
        updateMenuBarMenu()
        updateMenuBarTitle()
        rebuildWindow()
        restartUpdateTimer()

        for item in refreshRateMenu.items {
            item.state = item.tag == config.refreshRate ? .on : .off
        }
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}

// MARK: - Main
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
