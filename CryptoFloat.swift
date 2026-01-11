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
    
    static let `default` = AppConfig(
        cryptos: ["BTC", "ETH", "SOL"],
        transparency: 0.85,
        windowX: 100,
        windowY: 100,
        isExpanded: true,
        refreshRate: 30
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
        guard let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: AppConfig.configPath)
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
    
    func format(_ price: Double) -> String {
        if price >= 1 {
            return currencyFormatter.string(from: NSNumber(value: price)) ?? "$0.00"
        } else if price >= 0.0001 {
            return smallPriceFormatter.string(from: NSNumber(value: price)) ?? "$0.0000"
        } else {
            return String(format: "$%.8f", price)
        }
    }
}

// MARK: - Price Data
struct PriceData {
    let price: Double
    let change24h: Double
    let hasError: Bool
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
        request.setValue("CryptoFloat/1.0", forHTTPHeaderField: "User-Agent")
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
    
    // Fetch klines (candlestick) data for chart
    func fetchKlines(for symbol: String, days: Int = 7, completion: @escaping ([Double]) -> Void) {
        let pair = "\(symbol.uppercased())-USDT"
        let endTime = Int(Date().timeIntervalSince1970)
        let startTime = endTime - (days * 24 * 60 * 60)
        
        // Use 4hour candles for 7 days = ~42 data points
        let urlString = "\(baseURL)/api/v1/market/candles?type=4hour&symbol=\(pair)&startAt=\(startTime)&endAt=\(endTime)"
        
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("CryptoFloat/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Klines error: \(error.localizedDescription)")
                DispatchQueue.main.async { completion([]) }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let code = json["code"] as? String,
                   code == "200000",
                   let candles = json["data"] as? [[String]] {
                    
                    // Extract closing prices (index 2), data comes newest first
                    let closingPrices = candles.reversed().compactMap { Double($0[2]) }
                    
                    DispatchQueue.main.async {
                        completion(closingPrices)
                    }
                } else {
                    DispatchQueue.main.async { completion([]) }
                }
            } catch {
                print("Klines parse error: \(error)")
                DispatchQueue.main.async { completion([]) }
            }
        }.resume()
    }
}

// MARK: - Line Chart View
class LineChartView: NSView {
    var dataPoints: [Double] = []
    var isPositive: Bool = true
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard dataPoints.count > 1 else {
            drawNoData()
            return
        }
        
        let padding: CGFloat = 20
        let chartWidth = bounds.width - (padding * 2)
        let chartHeight = bounds.height - (padding * 2)
        
        guard let minVal = dataPoints.min(), let maxVal = dataPoints.max(), maxVal > minVal else {
            drawNoData()
            return
        }
        
        let range = maxVal - minVal
        
        // Determine color based on trend
        let lineColor: NSColor
        let gradientStartColor: NSColor
        if dataPoints.last! >= dataPoints.first! {
            lineColor = NSColor(calibratedRed: 0.3, green: 0.9, blue: 0.5, alpha: 1)
            gradientStartColor = NSColor(calibratedRed: 0.3, green: 0.9, blue: 0.5, alpha: 0.3)
        } else {
            lineColor = NSColor(calibratedRed: 1, green: 0.4, blue: 0.4, alpha: 1)
            gradientStartColor = NSColor(calibratedRed: 1, green: 0.4, blue: 0.4, alpha: 0.3)
        }
        
        // Create path for line
        let linePath = NSBezierPath()
        let fillPath = NSBezierPath()
        
        for (index, value) in dataPoints.enumerated() {
            let x = padding + (CGFloat(index) / CGFloat(dataPoints.count - 1)) * chartWidth
            let y = padding + ((value - minVal) / range) * chartHeight
            
            if index == 0 {
                linePath.move(to: NSPoint(x: x, y: y))
                fillPath.move(to: NSPoint(x: x, y: padding))
                fillPath.line(to: NSPoint(x: x, y: y))
            } else {
                linePath.line(to: NSPoint(x: x, y: y))
                fillPath.line(to: NSPoint(x: x, y: y))
            }
        }
        
        // Complete fill path
        let lastX = padding + chartWidth
        fillPath.line(to: NSPoint(x: lastX, y: padding))
        fillPath.close()
        
        // Draw gradient fill
        gradientStartColor.setFill()
        fillPath.fill()
        
        // Draw line
        lineColor.setStroke()
        linePath.lineWidth = 2
        linePath.lineCapStyle = .round
        linePath.lineJoinStyle = .round
        linePath.stroke()
        
        // Draw dots at start and end
        let dotRadius: CGFloat = 4
        lineColor.setFill()
        
        // Start dot
        let startY = padding + ((dataPoints.first! - minVal) / range) * chartHeight
        let startDot = NSBezierPath(ovalIn: NSRect(x: padding - dotRadius, y: startY - dotRadius, width: dotRadius * 2, height: dotRadius * 2))
        startDot.fill()
        
        // End dot
        let endY = padding + ((dataPoints.last! - minVal) / range) * chartHeight
        let endDot = NSBezierPath(ovalIn: NSRect(x: lastX - dotRadius, y: endY - dotRadius, width: dotRadius * 2, height: dotRadius * 2))
        endDot.fill()
        
        // Draw price labels
        drawPriceLabels(minVal: minVal, maxVal: maxVal, padding: padding, chartHeight: chartHeight)
    }
    
    private func drawPriceLabels(minVal: Double, maxVal: Double, padding: CGFloat, chartHeight: CGFloat) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .regular),
            .foregroundColor: NSColor(white: 1, alpha: 0.6)
        ]
        
        // Max price (top)
        let maxStr = PriceFormatter.shared.format(maxVal)
        maxStr.draw(at: NSPoint(x: 4, y: padding + chartHeight - 12), withAttributes: attributes)
        
        // Min price (bottom)
        let minStr = PriceFormatter.shared.format(minVal)
        minStr.draw(at: NSPoint(x: 4, y: padding), withAttributes: attributes)
    }
    
    private func drawNoData() {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor(white: 1, alpha: 0.5)
        ]
        let text = "Loading chart..."
        let size = text.size(withAttributes: attributes)
        let point = NSPoint(x: (bounds.width - size.width) / 2, y: (bounds.height - size.height) / 2)
        text.draw(at: point, withAttributes: attributes)
    }
}

// MARK: - Chart Window
class ChartWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.borderless], backing: .buffered, defer: false)
        
        level = .floating
        isOpaque = false
        backgroundColor = NSColor.clear
        hasShadow = true
        isMovableByWindowBackground = true
        
        // Ensure the content view also has no background
        contentView?.wantsLayer = true
        contentView?.layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    override var canBecomeKey: Bool { true }
}

// MARK: - Chart Panel View
class ChartPanelView: NSView {
    var symbol: String = ""
    var currentPrice: Double = 0
    var change24h: Double = 0
    var chartView: LineChartView!
    var onClose: (() -> Void)?
    
    private var trackingArea: NSTrackingArea?
    
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
        layer?.cornerRadius = 16
        layer?.masksToBounds = true
        layer?.backgroundColor = NSColor.clear.cgColor
        
        // Setup tracking area for click
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }
    
    func configure(symbol: String, price: Double, change: Double) {
        self.symbol = symbol
        self.currentPrice = price
        self.change24h = change
        
        // Clear subviews
        subviews.forEach { $0.removeFromSuperview() }
        
        // Header with symbol
        let headerLabel = NSTextField(labelWithString: "\(symbol)/USDT - 7 Day Chart")
        headerLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        headerLabel.textColor = .white
        headerLabel.frame = NSRect(x: 15, y: bounds.height - 30, width: bounds.width - 30, height: 20)
        addSubview(headerLabel)
        
        // Current price
        let priceLabel = NSTextField(labelWithString: PriceFormatter.shared.format(price))
        priceLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 18, weight: .semibold)
        priceLabel.textColor = .white
        priceLabel.frame = NSRect(x: 15, y: bounds.height - 55, width: 150, height: 24)
        addSubview(priceLabel)
        
        // Change percentage
        let changeLabel = NSTextField(labelWithString: String(format: "%@%.2f%%", change >= 0 ? "+" : "", change))
        changeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        changeLabel.textColor = change >= 0 ?
            NSColor(calibratedRed: 0.3, green: 0.9, blue: 0.5, alpha: 1) :
            NSColor(calibratedRed: 1, green: 0.4, blue: 0.4, alpha: 1)
        changeLabel.frame = NSRect(x: 165, y: bounds.height - 53, width: 80, height: 20)
        addSubview(changeLabel)
        
        // Close hint
        let closeHint = NSTextField(labelWithString: "Click to close")
        closeHint.font = NSFont.systemFont(ofSize: 9, weight: .light)
        closeHint.textColor = NSColor(white: 1, alpha: 0.4)
        closeHint.alignment = .right
        closeHint.frame = NSRect(x: bounds.width - 85, y: bounds.height - 28, width: 70, height: 14)
        addSubview(closeHint)
        
        // Chart view
        chartView = LineChartView(frame: NSRect(x: 10, y: 10, width: bounds.width - 20, height: bounds.height - 75))
        chartView.wantsLayer = true
        addSubview(chartView)
        
        // Fetch chart data
        CryptoAPI.shared.fetchKlines(for: symbol) { [weak self] prices in
            self?.chartView.dataPoints = prices
            self?.chartView.needsDisplay = true
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        // Draw rounded rectangle background
        let path = NSBezierPath(roundedRect: bounds, xRadius: 16, yRadius: 16)
        path.addClip()
        
        NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.15, alpha: 0.95).setFill()
        path.fill()
        
        // Border
        NSColor(calibratedRed: 0.4, green: 0.5, blue: 0.7, alpha: 0.3).setStroke()
        path.lineWidth = 1.5
        path.stroke()
    }
    
    override func mouseUp(with event: NSEvent) {
        onClose?()
    }
}

// MARK: - Toggle Button View
class ToggleButtonView: NSView {
    var isHovered = false
    var isExpanded = true
    var onClick: (() -> Void)?
    
    private var trackingArea: NSTrackingArea?
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        setupTrackingArea()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
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
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let circleRect = bounds.insetBy(dx: 2, dy: 2)
        let path = NSBezierPath(ovalIn: circleRect)
        
        if isHovered {
            NSColor(calibratedRed: 0.3, green: 0.4, blue: 0.6, alpha: 0.95).setFill()
        } else {
            NSColor(calibratedRed: 0.15, green: 0.2, blue: 0.3, alpha: 0.9).setFill()
        }
        path.fill()
        
        if isHovered {
            NSColor(calibratedRed: 0.5, green: 0.7, blue: 1.0, alpha: 0.6).setStroke()
        } else {
            NSColor(calibratedRed: 0.4, green: 0.5, blue: 0.7, alpha: 0.4).setStroke()
        }
        path.lineWidth = 1.5
        path.stroke()
        
        let symbol = "₿"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 18, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let size = symbol.size(withAttributes: attributes)
        let point = NSPoint(
            x: (bounds.width - size.width) / 2,
            y: (bounds.height - size.height) / 2
        )
        symbol.draw(at: point, withAttributes: attributes)
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
            onClick?()
        }
    }
}

// MARK: - Glass Content View
class GlassContentView: NSVisualEffectView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        blendingMode = .behindWindow
        material = .hudWindow
        state = .active
        wantsLayer = true
        layer?.cornerRadius = 16
        layer?.masksToBounds = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let path = NSBezierPath(roundedRect: bounds, xRadius: 16, yRadius: 16)
        NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.15, alpha: 0.7).setFill()
        path.fill()
        
        NSColor(calibratedRed: 0.4, green: 0.5, blue: 0.7, alpha: 0.3).setStroke()
        path.lineWidth = 1.5
        path.stroke()
    }
}

// MARK: - Animated Price Label
class AnimatedPriceLabel: NSTextField {
    private var flashLayer: CALayer?
    
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
    var onTap: ((String, Double, Double) -> Void)?
    
    private let symbolLabel = NSTextField(labelWithString: "")
    private let priceLabel = AnimatedPriceLabel(labelWithString: "Loading...")
    private let changeLabel = NSTextField(labelWithString: "")
    private let arrowLabel = NSTextField(labelWithString: "")
    
    private var lastPrice: Double = 0
    private var currentChange: Double = 0
    private var isFirstUpdate = true
    private var isHovered = false
    private var trackingArea: NSTrackingArea?
    
    init(frame: NSRect, symbol: String) {
        self.symbol = symbol
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    private func setup() {
        wantsLayer = true
        
        // Setup tracking area for hover and click
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
        
        // Symbol label
        symbolLabel.stringValue = symbol
        symbolLabel.font = NSFont.boldSystemFont(ofSize: 14)
        symbolLabel.textColor = .white
        symbolLabel.isBezeled = false
        symbolLabel.drawsBackground = false
        symbolLabel.isEditable = false
        symbolLabel.frame = NSRect(x: 12, y: 8, width: 40, height: 24)
        addSubview(symbolLabel)
        
        // Arrow indicator
        arrowLabel.font = NSFont.systemFont(ofSize: 10, weight: .bold)
        arrowLabel.isBezeled = false
        arrowLabel.drawsBackground = false
        arrowLabel.isEditable = false
        arrowLabel.alignment = .center
        arrowLabel.frame = NSRect(x: 48, y: 10, width: 14, height: 20)
        arrowLabel.wantsLayer = true
        addSubview(arrowLabel)
        
        // Price label
        priceLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        priceLabel.textColor = .white
        priceLabel.alignment = .left
        priceLabel.isBezeled = false
        priceLabel.drawsBackground = false
        priceLabel.isEditable = false
        priceLabel.frame = NSRect(x: 62, y: 8, width: 85, height: 24)
        addSubview(priceLabel)
        
        // Change label
        changeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        changeLabel.alignment = .right
        changeLabel.isBezeled = false
        changeLabel.drawsBackground = false
        changeLabel.isEditable = false
        changeLabel.frame = NSRect(x: 145, y: 10, width: 48, height: 20)
        addSubview(changeLabel)
    }
    
    func update(price: Double, change: Double, hasError: Bool) {
        if hasError {
            priceLabel.stringValue = "Error"
            priceLabel.textColor = NSColor(calibratedRed: 1, green: 0.4, blue: 0.4, alpha: 1)
            changeLabel.stringValue = ""
            arrowLabel.stringValue = ""
            return
        }
        
        let priceWentUp = price > lastPrice
        let priceWentDown = price < lastPrice
        let priceChanged = price != lastPrice && !isFirstUpdate
        
        let priceStr = PriceFormatter.shared.format(price)
        
        priceLabel.stringValue = priceStr
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
        currentChange = change
        isFirstUpdate = false
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
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Hover highlight
        if isHovered {
            let hoverPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 4, dy: 2), xRadius: 6, yRadius: 6)
            NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 0.1).setFill()
            hoverPath.fill()
        }
        
        // Separator line
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 10, y: 0))
        path.line(to: NSPoint(x: bounds.width - 10, y: 0))
        NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 0.1).setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }
    
    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        NSCursor.pointingHand.set()
        needsDisplay = true
    }
    
    override func mouseExited(with event: NSEvent) {
        isHovered = false
        NSCursor.arrow.set()
        needsDisplay = true
    }
    
    override func mouseUp(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        if bounds.contains(location) {
            onTap?(symbol, lastPrice, currentChange)
        }
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
    
    // Chart window
    var chartWindow: ChartWindow?
    var chartPanel: ChartPanelView?
    var currentChartSymbol: String?
    
    var transparencyMenu: NSMenu!
    var refreshRateMenu: NSMenu!
    var removeMenu: NSMenu!
    var expandCollapseItem: NSMenuItem!
    
    let toggleButtonSize: CGFloat = 44
    let panelWidth: CGFloat = 200
    let rowHeight: CGFloat = 40
    let headerHeight: CGFloat = 35
    let padding: CGFloat = 15
    
    let chartWidth: CGFloat = 280
    let chartHeight: CGFloat = 180
    
    let refreshRates: [(label: String, seconds: Int)] = [
        ("5 seconds", 5),
        ("10 seconds", 10),
        ("15 seconds", 15),
        ("30 seconds", 30),
        ("1 minute", 60),
        ("2 minutes", 120),
        ("5 minutes", 300)
    ]
    
    var expandedWidth: CGFloat {
        return toggleButtonSize + 10 + panelWidth + 5
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        config = AppConfig.load()
        
        setupStatusBar()
        setupWindow()
        startUpdateTimer()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        let frame = floatingWindow.frame
        config.windowX = Double(frame.origin.x)
        config.windowY = Double(frame.origin.y)
        config.save()
    }
    
    // MARK: - Chart
    func showChart(for symbol: String, price: Double, change: Double) {
        // If clicking same symbol, close chart
        if currentChartSymbol == symbol && chartWindow?.isVisible == true {
            closeChart()
            return
        }
        
        currentChartSymbol = symbol
        
        // Position chart window near the main window
        let mainFrame = floatingWindow.frame
        let chartX = mainFrame.origin.x + mainFrame.width + 10
        let chartY = mainFrame.origin.y + mainFrame.height - chartHeight
        
        let chartFrame = NSRect(x: chartX, y: chartY, width: chartWidth, height: chartHeight)
        
        if chartWindow == nil {
            chartWindow = ChartWindow(contentRect: chartFrame, styleMask: [], backing: .buffered, defer: false)
            chartWindow?.alphaValue = CGFloat(config.transparency)
        } else {
            chartWindow?.setFrame(chartFrame, display: true)
        }
        
        // Create chart panel
        chartPanel = ChartPanelView(frame: NSRect(x: 0, y: 0, width: chartWidth, height: chartHeight))
        chartPanel?.configure(symbol: symbol, price: price, change: change)
        chartPanel?.onClose = { [weak self] in
            self?.closeChart()
        }
        
        chartWindow?.contentView = chartPanel
        chartWindow?.makeKeyAndOrderFront(nil)
        
        // Animate in
        chartWindow?.alphaValue = 0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            chartWindow?.animator().alphaValue = CGFloat(config.transparency)
        }
    }
    
    func closeChart() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            chartWindow?.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.chartWindow?.orderOut(nil)
            self?.currentChartSymbol = nil
        })
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
        
        menu.addItem(NSMenuItem.separator())
        
        let addItem = NSMenuItem(title: "Add Cryptocurrency...", action: #selector(addCrypto), keyEquivalent: "")
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
    
    func calculateWindowSize() -> (width: CGFloat, height: CGFloat) {
        if config.isExpanded {
            let contentHeight = headerHeight + (rowHeight * CGFloat(config.cryptos.count)) + padding
            return (expandedWidth, max(contentHeight, toggleButtonSize + 10))
        } else {
            return (toggleButtonSize + 10, toggleButtonSize + 10)
        }
    }
    
    func setupWindow() {
        let (width, height) = calculateWindowSize()
        let frame = NSRect(x: config.windowX, y: config.windowY, width: Double(width), height: Double(height))
        
        floatingWindow = FloatingWindow(contentRect: frame, styleMask: [], backing: .buffered, defer: false)
        floatingWindow.alphaValue = CGFloat(config.transparency)
        
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
        
        guard config.isExpanded else { return }
        
        let contentHeight = headerHeight + (rowHeight * CGFloat(config.cryptos.count)) + padding
        
        contentPanel = GlassContentView(frame: NSRect(x: toggleButtonSize + 10, y: 5, width: panelWidth, height: contentHeight))
        containerView.addSubview(contentPanel!)
        
        let headerLabel = NSTextField(labelWithString: "Crypto Prices (USDT)")
        headerLabel.font = NSFont.systemFont(ofSize: 10, weight: .light)
        headerLabel.textColor = NSColor(calibratedRed: 0.7, green: 0.8, blue: 1, alpha: 0.8)
        headerLabel.frame = NSRect(x: 12, y: contentHeight - 28, width: panelWidth - 24, height: 20)
        contentPanel?.addSubview(headerLabel)
        
        for (index, symbol) in config.cryptos.enumerated() {
            let yPos = contentHeight - headerHeight - (CGFloat(index + 1) * rowHeight) + 5
            
            let row = CryptoRowView(
                frame: NSRect(x: 0, y: yPos, width: panelWidth, height: rowHeight),
                symbol: symbol
            )
            row.onTap = { [weak self] sym, price, change in
                self?.showChart(for: sym, price: price, change: change)
            }
            contentPanel?.addSubview(row)
            cryptoRows[symbol] = row
        }
    }
    
    func toggleExpanded() {
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
            closeChart()
        }
    }
    
    func rebuildWindow() {
        guard config.isExpanded else { return }
        
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
            for (symbol, data) in prices {
                self?.cryptoRows[symbol]?.update(price: data.price, change: data.change24h, hasError: data.hasError)
            }
        }
    }
    
    // MARK: - Actions
    @objc func toggleWindowVisibility() {
        if floatingWindow.isVisible {
            floatingWindow.orderOut(nil)
            closeChart()
        } else {
            floatingWindow.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc func toggleExpandedFromMenu() {
        toggleExpanded()
    }
    
    @objc func setTransparency(_ sender: NSMenuItem) {
        let level = Double(sender.tag) / 100.0
        floatingWindow.alphaValue = CGFloat(level)
        chartWindow?.alphaValue = CGFloat(level)
        config.transparency = level
        config.save()
        
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
    
    @objc func addCrypto() {
        let alert = NSAlert()
        alert.messageText = "Add Cryptocurrency"
        alert.informativeText = "Enter the trading symbol (e.g., 'BTC', 'ETH', 'SOL', 'DOGE').\n\nThe symbol will be paired with USDT."
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
                rebuildWindow()
            }
        }
    }
    
    @objc func removeCrypto(_ sender: NSMenuItem) {
        guard let symbol = sender.representedObject as? String else { return }
        config.cryptos.removeAll { $0 == symbol }
        config.save()
        updateRemoveMenu()
        rebuildWindow()
        
        if currentChartSymbol == symbol {
            closeChart()
        }
    }
    
    @objc func resetDefaults() {
        config.cryptos = AppConfig.default.cryptos
        config.refreshRate = AppConfig.default.refreshRate
        config.save()
        updateRemoveMenu()
        rebuildWindow()
        restartUpdateTimer()
        closeChart()
        
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
