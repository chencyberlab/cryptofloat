import Cocoa

// MARK: - Network Fees View
class NetworkFeesView: NSView {
    private var data: NetworkFeeData?
    private var isLoading = true
    private var changedTierKeys: Set<String> = []
    private var pulseAlpha: CGFloat = 0
    private var pulseTimer: Timer?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupAccessibility()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupAccessibility()
    }

    deinit {
        pulseTimer?.invalidate()
    }

    private func setupAccessibility() {
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        setAccessibilityLabel("Network fees")
        setAccessibilityValue("Updating")
    }

    func setLoading() {
        isLoading = true
        setAccessibilityValueAndNotify("Updating")
        needsDisplay = true
    }

    func setData(_ data: NetworkFeeData) {
        let changedKeys = changedTierKeys(from: self.data, to: data)
        self.data = data
        isLoading = false
        let availableNetworks = [
            data.eth.isEmpty ? nil : "Ethereum",
            data.btc.isEmpty ? nil : "Bitcoin"
        ].compactMap { $0 }.joined(separator: " and ")
        func tierSummaries(_ tiers: [NetworkFeeTier], network: String) -> [String] {
            return tiers.prefix(3).map { tier in
                let parts = rateParts(tier)
                let usd = tier.usdValue.map { feeUSDText($0) } ?? "USD unavailable"
                return "\(network) \(tier.label): \(parts.amount) \(parts.unit), \(usd), \(tier.eta)"
            }
        }
        let details = tierSummaries(data.eth, network: "Ethereum")
            + tierSummaries(data.btc, network: "Bitcoin")
        setAccessibilityValueAndNotify(
            availableNetworks.isEmpty
                ? "Fee data unavailable"
                : details.joined(separator: ". ")
        )

        if changedKeys.isEmpty {
            changedTierKeys.removeAll()
            pulseAlpha = 0
            pulseTimer?.invalidate()
            pulseTimer = nil
            needsDisplay = true
        } else {
            startPulse(for: changedKeys)
        }
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

    private func rateParts(_ tier: NetworkFeeTier) -> (amount: String, unit: String) {
        let amount: String
        if tier.unit == "gwei" {
            amount = String(format: "%.2f", tier.rate)
        } else if tier.unit == "sat/vB", tier.rate < 10 {
            amount = String(format: "%.1f", tier.rate)
        } else {
            amount = String(format: "%.0f", tier.rate)
        }

        return (amount, tier.unit == "gwei" ? "GWEI" : tier.unit)
    }

    private func tierTitle(for tier: NetworkFeeTier) -> String {
        switch tier.label.lowercased() {
        case "slow": return "LOW"
        case "standard": return "MEDIUM"
        case "fast": return "HIGH"
        default: return tier.label.uppercased()
        }
    }

    private func tierColor(for tier: NetworkFeeTier, theme: AppTheme) -> NSColor {
        switch tier.label.lowercased() {
        case "slow": return theme.positive.color()
        case "standard": return theme.warning.color()
        case "fast": return theme.negative.color()
        default: return theme.accent.color()
        }
    }

    private func tierKey(prefix: String, tier: NetworkFeeTier) -> String {
        return "\(prefix)-\(tier.label.lowercased())"
    }

    private func feeUSDText(_ value: Double) -> String {
        let roundedUp = ceil(max(value, 0) * 1000) / 1000
        return String(format: "$%.3f", roundedUp)
    }

    private func tierSignature(_ tier: NetworkFeeTier) -> String {
        let parts = rateParts(tier)
        let usd = tier.usdValue.map { feeUSDText($0) } ?? "--"
        return "\(parts.amount)|\(parts.unit)|\(usd)|\(tier.eta)"
    }

    private func changedTierKeys(from oldData: NetworkFeeData?, to newData: NetworkFeeData) -> Set<String> {
        guard let oldData = oldData else { return [] }

        var keys: Set<String> = []
        for (prefix, oldTiers, newTiers) in [
            ("eth", oldData.eth, newData.eth),
            ("btc", oldData.btc, newData.btc)
        ] {
            let oldByLabel = Dictionary(
                oldTiers.map { ($0.label.lowercased(), $0) },
                uniquingKeysWith: { _, latest in latest }
            )
            for tier in newTiers.prefix(3) {
                let key = tierKey(prefix: prefix, tier: tier)
                guard let oldTier = oldByLabel[tier.label.lowercased()] else {
                    keys.insert(key)
                    continue
                }
                if tierSignature(oldTier) != tierSignature(tier) {
                    keys.insert(key)
                }
            }
        }
        return keys
    }

    private func startPulse(for keys: Set<String>) {
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
            changedTierKeys.removeAll()
            pulseAlpha = 0
            pulseTimer?.invalidate()
            pulseTimer = nil
            needsDisplay = true
            return
        }
        changedTierKeys = keys
        pulseAlpha = 1
        pulseTimer?.invalidate()
        needsDisplay = true

        let started = Date()
        let duration: TimeInterval = 0.9
        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            let elapsed = Date().timeIntervalSince(started)
            if elapsed >= duration {
                self.pulseAlpha = 0
                self.changedTierKeys.removeAll()
                timer.invalidate()
                self.pulseTimer = nil
            } else {
                self.pulseAlpha = CGFloat(1 - (elapsed / duration))
            }
            self.needsDisplay = true
        }

        pulseTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func drawUnavailable(_ text: String, in rect: NSRect) {
        let theme = ThemeCatalog.current
        text.draw(
            in: rect,
            withAttributes: attributes(
                font: NSFont.systemFont(ofSize: 11, weight: .regular),
                color: theme.secondaryTextColor,
                alignment: .center
            )
        )
    }

    private func drawTierCard(_ tier: NetworkFeeTier, key: String, rect: NSRect) {
        let theme = ThemeCatalog.current
        let accent = tierColor(for: tier, theme: theme)
        let isFast = tier.label.caseInsensitiveCompare("Fast") == .orderedSame
        let isChanged = changedTierKeys.contains(key)
        let path = NSBezierPath(roundedRect: rect, xRadius: 8, yRadius: 8)
        let baseAlpha: CGFloat = isChanged ? 0.035 + (0.08 * pulseAlpha) : 0.035
        theme.foreground.color(alpha: baseAlpha).setFill()
        path.fill()
        accent.withAlphaComponent(isChanged ? 0.38 + (0.42 * pulseAlpha) : 0.38).setStroke()
        path.lineWidth = 1
        path.stroke()

        tierTitle(for: tier).draw(
            in: NSRect(x: rect.minX + 8, y: rect.maxY - 21, width: rect.width - 16, height: 12),
            withAttributes: attributes(
                font: NSFont.systemFont(ofSize: 9.5, weight: .bold),
                color: isFast ? theme.negativeTextColor : accent,
                alignment: .center
            )
        )

        let parts = rateParts(tier)
        parts.amount.draw(
            in: NSRect(x: rect.minX + 8, y: rect.maxY - 47, width: rect.width - 16, height: 20),
            withAttributes: attributes(
                font: NSFont.monospacedDigitSystemFont(ofSize: 15, weight: .medium),
                color: isChanged
                    ? theme.foreground.color(alpha: 0.97).blended(withFraction: pulseAlpha * 0.45, of: accent) ?? theme.foreground.color(alpha: 0.97)
                    : theme.foreground.color(alpha: 0.97),
                alignment: .center
            )
        )
        parts.unit.draw(
            in: NSRect(x: rect.minX + 6, y: rect.maxY - 59, width: rect.width - 12, height: 10),
            withAttributes: attributes(
                font: NSFont.systemFont(ofSize: 9, weight: .semibold),
                color: theme.secondaryTextColor,
                alignment: .center
            )
        )

        let usdText = tier.usdValue.map { feeUSDText($0) } ?? "--"
        usdText.draw(
            in: NSRect(x: rect.minX + 6, y: rect.minY + 18, width: rect.width - 12, height: 11),
            withAttributes: attributes(
                font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular),
                color: theme.secondaryTextColor,
                alignment: .center
            )
        )
        tier.eta.draw(
            in: NSRect(x: rect.minX + 6, y: rect.minY + 5, width: rect.width - 12, height: 10),
            withAttributes: attributes(
                font: NSFont.systemFont(ofSize: 9, weight: .regular),
                color: theme.secondaryTextColor,
                alignment: .center
            )
        )
    }

    private func drawNetworkSection(title: String, keyPrefix: String, tiers: [NetworkFeeTier], titleY: CGFloat, cardY: CGFloat) {
        let theme = ThemeCatalog.current
        let sectionAttrs = attributes(
            font: NSFont.systemFont(ofSize: 10.5, weight: .bold),
            color: theme.foreground.color(alpha: 0.86)
        )

        title.draw(in: NSRect(x: 14, y: titleY, width: bounds.width - 28, height: 14), withAttributes: sectionAttrs)

        let cardHeight: CGFloat = 90
        let gap: CGFloat = 8
        let columns = min(max(tiers.count, 1), 3)
        let available = bounds.width - 28
        let cardWidth = (available - (CGFloat(columns - 1) * gap)) / CGFloat(columns)

        guard !tiers.isEmpty else {
            drawUnavailable("Unavailable", in: NSRect(x: 14, y: cardY, width: available, height: cardHeight))
            return
        }

        for (index, tier) in tiers.prefix(3).enumerated() {
            let x = 14 + CGFloat(index) * (cardWidth + gap)
            drawTierCard(
                tier,
                key: tierKey(prefix: keyPrefix, tier: tier),
                rect: NSRect(
                    x: x,
                    y: cardY,
                    width: cardWidth,
                    height: cardHeight
                )
            )
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let theme = ThemeCatalog.current
        let line = NSBezierPath()
        line.move(to: NSPoint(x: 12, y: bounds.height - 1))
        line.line(to: NSPoint(x: bounds.width - 12, y: bounds.height - 1))
        theme.foreground.color(alpha: 0.08).setStroke()
        line.lineWidth = 0.6
        line.stroke()

        let titleAttrs = attributes(
            font: NSFont.systemFont(ofSize: 10, weight: .bold),
            color: theme.accentTextColor
        )
        "NETWORK FEES".draw(at: NSPoint(x: 14, y: bounds.height - 22), withAttributes: titleAttrs)

        if isLoading, data != nil {
            "UPDATING".draw(
                in: NSRect(x: bounds.width - 78, y: bounds.height - 22, width: 64, height: 12),
                withAttributes: attributes(
                    font: NSFont.systemFont(ofSize: 9, weight: .bold),
                    color: theme.secondaryTextColor,
                    alignment: .right
                )
            )
        }

        if isLoading, data == nil {
            "Loading fees...".draw(
                in: NSRect(x: 14, y: bounds.height - 56, width: bounds.width - 28, height: 18),
                withAttributes: attributes(
                    font: NSFont.systemFont(ofSize: 12, weight: .regular),
                    color: theme.subduedTextColor,
                    alignment: .center
                )
            )
            return
        }

        guard let data = data, !data.hasError else {
            "Fee data unavailable".draw(
                in: NSRect(x: 14, y: bounds.height - 56, width: bounds.width - 28, height: 18),
                withAttributes: attributes(
                    font: NSFont.systemFont(ofSize: 12, weight: .regular),
                    color: theme.negativeTextColor,
                    alignment: .center
                )
            )
            return
        }

        drawNetworkSection(title: "ETH GAS", keyPrefix: "eth", tiers: data.eth, titleY: bounds.height - 48, cardY: bounds.height - 146)
        drawNetworkSection(title: "BTC FEES", keyPrefix: "btc", tiers: data.btc, titleY: bounds.height - 170, cardY: 14)
    }
}
