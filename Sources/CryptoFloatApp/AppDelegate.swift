import Cocoa

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem!
    var floatingWindow: FloatingWindow!
    var config: AppConfig!
    var cryptoRows: [String: CryptoRowView] = [:]
    var updateTimer: Timer?
    var toggleButton: ToggleButtonView?
    var marqueeWidget: MarqueeWidgetView?
    var contentPanel: GlassContentView?
    var networkFeesView: NetworkFeesView?
    var contentScrollView: NSScrollView?
    var containerView: NSView!
    var chartWindow: ChartPopupWindow?
    var chartContentView: SevenDayChartContentView?
    var chartDismissalMonitors: [Any] = []
    var activeChartSymbol: String?

    var transparencyMenu: NSMenu!
    var refreshRateMenu: NSMenu!
    var removeMenu: NSMenu!
    var menuBarMenu: NSMenu!
    var floatingWidgetMenu: NSMenu!
    var themeMenu: NSMenu!
    var dataProviderMenu: NSMenu!
    var showHideItem: NSMenuItem!
    var expandCollapseItem: NSMenuItem!
    var sparklineToggleItem: NSMenuItem!
    var networkFeesToggleItem: NSMenuItem!
    var updatedLabel: NSTextField?

    var latestPrices: [String: PriceData] = [:]
    var sparklineCache: [String: (values: [Double], fetchedAt: Date)] = [:]
    var chartCache: [String: (points: [ChartPoint], fetchedAt: Date)] = [:]
    var networkFeeCache: NetworkFeeData?
    var lastNetworkFeeResult: NetworkFeeData?
    var lastSuccessfulPriceUpdate: Date?

    private var marketGeneration = 0
    private var isPriceRefreshInFlight = false
    private var isPriceRefreshPending = false
    private var sparklineRequestsInFlight: Set<String> = []
    private var sparklineFailureBackoffs: [String: FailureBackoff] = [:]
    private var isNetworkFeeRefreshInFlight = false
    private var networkFeeFailureBackoff = FailureBackoff()
    private var windowPositionSaveWorkItem: DispatchWorkItem?

    let toggleButtonSize: CGFloat = 44
    let marqueeWidgetWidth: CGFloat = 274
    let panelWidth: CGFloat = 248
    let chartPopupSize = NSSize(width: 300, height: 190)
    let headerHeight: CGFloat = 30
    let networkFeesHeight: CGFloat = 282
    let padding: CGFloat = 12
    let networkFeeRefreshInterval: TimeInterval = 90

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

    var naturalPanelContentHeight: CGFloat {
        let feesHeight = config.showNetworkFees ? networkFeesHeight : 0
        return headerHeight + (rowHeight * CGFloat(config.cryptos.count)) + padding + feesHeight
    }

    var maximumPanelContentHeight: CGFloat {
        let visibleHeight = (floatingWindow?.screen ?? NSScreen.main)?.visibleFrame.height ?? 800
        let widgetAllowance = config.floatingWidgetMode == .marquee ? toggleButtonSize + 25 : 20
        return max(220, visibleHeight - widgetAllowance)
    }

    var panelContentHeight: CGFloat {
        return min(naturalPanelContentHeight, maximumPanelContentHeight)
    }

    var floatingWidgetWidth: CGFloat {
        return config.floatingWidgetMode == .marquee ? marqueeWidgetWidth : toggleButtonSize
    }

    var currentPanelWidth: CGFloat {
        let baseWidth = config.floatingWidgetMode == .marquee ? marqueeWidgetWidth : panelWidth
        return config.showNetworkFees ? max(baseWidth, marqueeWidgetWidth) : baseWidth
    }

    var expandedWidth: CGFloat {
        if config.floatingWidgetMode == .marquee {
            return max(floatingWidgetWidth, currentPanelWidth) + 10
        }
        return floatingWidgetWidth + 10 + currentPanelWidth + 5
    }

    var shouldUseWindowShadow: Bool {
        return config.floatingWidgetMode == .bitcoin
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        config = AppConfig.load()
        ThemeCatalog.current = ThemeCatalog.theme(for: config.theme)
        sanitizeMenuBarSymbol()

        setupStatusBar()
        setupWindow()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        startUpdateTimer()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hideChartPopup()
        NotificationCenter.default.removeObserver(self)
        windowPositionSaveWorkItem?.cancel()
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

    @objc private func screenParametersChanged() {
        hideChartPopup()
        let widgetAnchor = floatingWidgetScreenOrigin()
        let (width, height) = calculateWindowSize()
        let frame = resizedWindowFrame(
            size: NSSize(width: width, height: height),
            preservingWidgetAt: widgetAnchor
        )
        floatingWindow.setFrame(frame, display: true)
        containerView.frame = NSRect(origin: .zero, size: frame.size)
        layoutFloatingWidget()
        setupContentPanel()
        refreshPrices()
    }

    // MARK: - Setup
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "₿"
        statusItem.button?.font = NSFont.systemFont(ofSize: 14)
        statusItem.button?.toolTip = "CryptoFloat"
        statusItem.button?.setAccessibilityLabel("CryptoFloat")

        let menu = NSMenu()

        showHideItem = NSMenuItem(title: "Hide Window", action: #selector(toggleWindowVisibility), keyEquivalent: "")
        showHideItem.target = self
        menu.addItem(showHideItem)

        expandCollapseItem = NSMenuItem(title: config.isExpanded ? "Collapse Prices" : "Expand Prices", action: #selector(toggleExpandedFromMenu), keyEquivalent: "")
        expandCollapseItem.target = self
        menu.addItem(expandCollapseItem)

        menu.addItem(NSMenuItem.separator())

        // Floating widget submenu
        floatingWidgetMenu = NSMenu()
        updateFloatingWidgetMenu()
        let floatingWidgetItem = NSMenuItem(title: "Floating Widget", action: nil, keyEquivalent: "")
        floatingWidgetItem.submenu = floatingWidgetMenu
        menu.addItem(floatingWidgetItem)

        // Theme submenu
        themeMenu = NSMenu()
        updateThemeMenu()
        let themeItem = NSMenuItem(title: "Theme", action: nil, keyEquivalent: "")
        themeItem.submenu = themeMenu
        menu.addItem(themeItem)

        // Data source submenu
        dataProviderMenu = NSMenu()
        updateDataProviderMenu()
        let dataProviderItem = NSMenuItem(title: "Data Source", action: nil, keyEquivalent: "")
        dataProviderItem.submenu = dataProviderMenu
        menu.addItem(dataProviderItem)

        // Transparency submenu
        transparencyMenu = NSMenu()
        for level in [100, 90, 85, 80, 70, 60, 50] {
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

        // Network fee toggle
        networkFeesToggleItem = NSMenuItem(title: "Show Network Fees", action: #selector(toggleNetworkFees(_:)), keyEquivalent: "")
        networkFeesToggleItem.target = self
        networkFeesToggleItem.state = config.showNetworkFees ? .on : .off
        menu.addItem(networkFeesToggleItem)

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
        guard !config.cryptos.isEmpty else {
            let emptyItem = NSMenuItem(title: "No Tracked Assets", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            removeMenu.addItem(emptyItem)
            return
        }
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

    func updateFloatingWidgetMenu() {
        floatingWidgetMenu.removeAllItems()

        let choices: [(title: String, mode: FloatingWidgetMode)] = [
            ("Simple Bitcoin", .bitcoin),
            ("Marquee Prices", .marquee)
        ]

        for choice in choices {
            let item = NSMenuItem(title: choice.title, action: #selector(setFloatingWidgetMode(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = choice.mode.rawValue
            item.state = config.floatingWidgetMode == choice.mode ? .on : .off
            floatingWidgetMenu.addItem(item)
        }
    }

    func updateThemeMenu() {
        themeMenu.removeAllItems()

        for theme in ThemeCatalog.all {
            let item = NSMenuItem(title: theme.displayName, action: #selector(setTheme(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = theme.id.rawValue
            item.state = config.theme == theme.id ? .on : .off
            themeMenu.addItem(item)
        }
    }

    func updateDataProviderMenu() {
        dataProviderMenu.removeAllItems()

        for provider in DataProvider.allCases {
            let item = NSMenuItem(title: provider.displayName, action: #selector(setDataProvider(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = provider.rawValue
            item.state = config.dataProvider == provider ? .on : .off
            dataProviderMenu.addItem(item)
        }
    }

    func updateWindowShadow() {
        floatingWindow?.hasShadow = shouldUseWindowShadow
    }

    private func invalidateMarketRequests(clearPrices: Bool = true) {
        marketGeneration &+= 1
        isPriceRefreshInFlight = false
        isPriceRefreshPending = false
        sparklineRequestsInFlight.removeAll()
        sparklineFailureBackoffs.removeAll()
        isNetworkFeeRefreshInFlight = false
        networkFeeFailureBackoff.reset()
        sparklineCache.removeAll()
        chartCache.removeAll()
        networkFeeCache = nil
        lastNetworkFeeResult = nil
        lastSuccessfulPriceUpdate = nil
        if clearPrices {
            latestPrices.removeAll()
        }
    }

    private func clampedWindowFrame(_ proposedFrame: NSRect) -> NSRect {
        guard !NSScreen.screens.isEmpty else { return proposedFrame }

        let bestScreen = NSScreen.screens.max { lhs, rhs in
            lhs.visibleFrame.intersection(proposedFrame).width
                * lhs.visibleFrame.intersection(proposedFrame).height
                < rhs.visibleFrame.intersection(proposedFrame).width
                * rhs.visibleFrame.intersection(proposedFrame).height
        }
        let hasVisibleIntersection = bestScreen
            .map { !$0.visibleFrame.intersection(proposedFrame).isNull }
            ?? false
        let visibleFrame = (hasVisibleIntersection ? bestScreen : NSScreen.main)?.visibleFrame
            ?? NSScreen.screens[0].visibleFrame

        var frame = proposedFrame
        frame.size.width = min(frame.width, visibleFrame.width)
        frame.size.height = min(frame.height, visibleFrame.height)
        frame.origin.x = min(max(frame.origin.x, visibleFrame.minX), visibleFrame.maxX - frame.width)
        frame.origin.y = min(max(frame.origin.y, visibleFrame.minY), visibleFrame.maxY - frame.height)
        return frame
    }

    func windowDidMove(_ notification: Notification) {
        windowPositionSaveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, let window = self.floatingWindow else { return }
            self.config.windowX = Double(window.frame.origin.x)
            self.config.windowY = Double(window.frame.origin.y)
            self.config.save()
        }
        windowPositionSaveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    func calculateWindowSize() -> (width: CGFloat, height: CGFloat) {
        if config.isExpanded {
            if config.floatingWidgetMode == .marquee {
                let height = panelContentHeight + toggleButtonSize + 15
                return (expandedWidth, max(height, toggleButtonSize + 10))
            }
            return (expandedWidth, max(panelContentHeight + 10, toggleButtonSize + 10))
        } else {
            return (floatingWidgetWidth + 10, toggleButtonSize + 10)
        }
    }

    private func floatingWidgetScreenOrigin() -> NSPoint? {
        guard let widget = (toggleButton as NSView?) ?? marqueeWidget,
              let window = widget.window else {
            return nil
        }
        return window.convertPoint(
            toScreen: widget.convert(.zero, to: nil)
        )
    }

    private func resizedWindowFrame(
        size: NSSize,
        preservingWidgetAt screenOrigin: NSPoint?
    ) -> NSRect {
        var frame = floatingWindow.frame
        let oldHeight = frame.height
        frame.size = size

        if let screenOrigin = screenOrigin {
            let targetWidgetFrame = floatingWidgetFrame(for: size)
            frame.origin = FloatingWidgetLayout.windowOrigin(
                preservingWidgetAt: screenOrigin,
                targetWidgetFrame: targetWidgetFrame
            )
        } else {
            frame.origin.y += oldHeight - size.height
        }
        return clampedWindowFrame(frame)
    }

    func setupWindow() {
        let (width, height) = calculateWindowSize()
        let desiredFrame = NSRect(x: config.windowX, y: config.windowY, width: Double(width), height: Double(height))
        let frame = clampedWindowFrame(desiredFrame)

        floatingWindow = FloatingWindow(contentRect: frame, styleMask: [], backing: .buffered, defer: false)
        floatingWindow.delegate = self
        floatingWindow.alphaValue = 1
        floatingWindow.hasShadow = shouldUseWindowShadow

        containerView = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        floatingWindow.contentView = containerView

        setupFloatingWidget()

        setupContentPanel()

        floatingWindow.orderFrontRegardless()
    }

    func setupFloatingWidget() {
        toggleButton?.removeFromSuperview()
        marqueeWidget?.removeFromSuperview()
        toggleButton = nil
        marqueeWidget = nil

        let frame = floatingWidgetFrame(for: containerView.bounds.size)

        switch config.floatingWidgetMode {
        case .bitcoin:
            let button = ToggleButtonView(frame: frame)
            button.isExpanded = config.isExpanded
            button.backgroundOpacity = CGFloat(config.transparency)
            button.onClick = { [weak self] in
                self?.toggleExpanded()
            }
            containerView.addSubview(button)
            toggleButton = button

        case .marquee:
            let marquee = MarqueeWidgetView(frame: frame)
            marquee.isExpanded = config.isExpanded
            marquee.backgroundOpacity = CGFloat(config.transparency)
            marquee.onClick = { [weak self] in
                self?.toggleExpanded()
            }
            marquee.setMarketData(symbols: config.cryptos, prices: latestPrices)
            containerView.addSubview(marquee)
            marqueeWidget = marquee
        }

        updateAccent()
    }

    func floatingWidgetFrame(for containerSize: NSSize) -> NSRect {
        return FloatingWidgetLayout.frame(
            mode: config.floatingWidgetMode,
            isExpanded: config.isExpanded,
            containerSize: containerSize,
            widgetWidth: floatingWidgetWidth,
            widgetHeight: toggleButtonSize
        )
    }

    func layoutFloatingWidget() {
        let frame = floatingWidgetFrame(for: containerView.bounds.size)
        toggleButton?.frame = frame
        toggleButton?.isExpanded = config.isExpanded
        toggleButton?.backgroundOpacity = CGFloat(config.transparency)
        marqueeWidget?.frame = frame
        marqueeWidget?.isExpanded = config.isExpanded
        marqueeWidget?.backgroundOpacity = CGFloat(config.transparency)
        marqueeWidget?.setMarketData(symbols: config.cryptos, prices: latestPrices)
    }

    func setupContentPanel() {
        contentPanel?.removeFromSuperview()
        cryptoRows.removeAll()
        updatedLabel = nil
        networkFeesView = nil
        contentScrollView = nil

        guard config.isExpanded else { return }

        let contentHeight = panelContentHeight
        let panelW = currentPanelWidth
        let panelX: CGFloat
        if config.floatingWidgetMode == .marquee {
            panelX = max((containerView.bounds.width - panelW) / 2, 5)
        } else {
            panelX = floatingWidgetWidth + 10
        }

        contentPanel = GlassContentView(frame: NSRect(x: panelX, y: 5, width: panelW, height: contentHeight))
        contentPanel?.backgroundOpacity = CGFloat(config.transparency)
        containerView.addSubview(contentPanel!)

        let titleLabel = NSTextField(labelWithString: "PRICES · \(config.dataProvider.quoteLabel)")
        titleLabel.font = NSFont.systemFont(ofSize: 10, weight: .semibold)
        titleLabel.textColor = ThemeCatalog.current.accentTextColor
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.frame = NSRect(x: 14, y: contentHeight - 23, width: 80, height: 16)
        contentPanel?.addSubview(titleLabel)

        let updated = NSTextField(labelWithString: "")
        updated.font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        updated.alignment = .right
        updated.textColor = ThemeCatalog.current.secondaryTextColor
        updated.isBezeled = false
        updated.drawsBackground = false
        updated.isEditable = false
        updated.frame = NSRect(x: panelW - 124, y: contentHeight - 23, width: 110, height: 16)
        contentPanel?.addSubview(updated)
        updatedLabel = updated

        let bodyHeight = max(contentHeight - headerHeight, 1)
        let rowsHeight = rowHeight * CGFloat(config.cryptos.count)
        let feesHeight = config.showNetworkFees ? networkFeesHeight : 0
        let documentHeight = max(rowsHeight + padding + feesHeight, bodyHeight)
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: panelW, height: bodyHeight))
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = documentHeight > bodyHeight
        scrollView.autohidesScrollers = true
        scrollView.verticalScrollElasticity = .automatic
        contentPanel?.addSubview(scrollView)
        scrollView.tile()

        let documentWidth = max(scrollView.contentSize.width, 1)
        let documentView = FlippedView(frame: NSRect(x: 0, y: 0, width: documentWidth, height: documentHeight))
        scrollView.documentView = documentView
        contentScrollView = scrollView

        for (index, symbol) in config.cryptos.enumerated() {
            let yPos = CGFloat(index) * rowHeight

            let row = CryptoRowView(
                frame: NSRect(x: 0, y: yPos, width: documentWidth, height: rowHeight),
                symbol: symbol,
                showSparkline: config.showSparklines
            )
            row.onClick = { [weak self] _ in
                self?.showChartPopup(for: symbol)
            }
            documentView.addSubview(row)
            cryptoRows[symbol] = row

            if let cached = sparklineCache[symbol]?.values {
                row.setSparkline(cached)
            }
            if let current = latestPrices[symbol] {
                row.update(
                    price: current.price,
                    change: current.change24h,
                    hasError: current.hasError
                )
            }
        }

        if config.showNetworkFees {
            let feeView = NetworkFeesView(
                frame: NSRect(x: 0, y: rowsHeight + padding, width: documentWidth, height: networkFeesHeight)
            )
            if let cached = networkFeeCache,
               Date().timeIntervalSince(cached.updatedAt) < networkFeeRefreshInterval {
                feeView.setData(cached)
            } else if let lastResult = lastNetworkFeeResult,
                      !networkFeeFailureBackoff.allowsAttempt(at: Date()) {
                feeView.setData(lastResult)
            } else {
                feeView.setLoading()
            }
            documentView.addSubview(feeView)
            networkFeesView = feeView
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
            quoteLabel: config.dataProvider.quoteLabel,
            latest: latestPrices[symbol]
        )
        content.backgroundOpacity = CGFloat(config.transparency)
        content.onDismiss = { [weak self] in
            self?.hideChartPopup()
        }
        popup.contentView = content
        content.needsDisplay = true
        chartWindow = popup
        chartContentView = content

        let openingEventTimestamp = NSApp.currentEvent?.timestamp ?? ProcessInfo.processInfo.systemUptime

        popup.displayIfNeeded()
        popup.makeKeyAndOrderFront(nil)
        popup.makeFirstResponder(content)
        installChartDismissalMonitors(ignoringEventsThrough: openingEventTimestamp)

        if let cached = chartCache[symbol], Date().timeIntervalSince(cached.fetchedAt) < 600 {
            content.setPoints(cached.points)
            return
        }

        let generation = marketGeneration
        let provider = config.dataProvider
        CryptoAPI.shared.fetchSevenDayChart(for: symbol, provider: provider) { [weak self, weak content] points in
            guard let self = self,
                  let content = content,
                  generation == self.marketGeneration,
                  provider == self.config.dataProvider,
                  self.activeChartSymbol == symbol,
                  self.chartContentView === content else {
                return
            }
            if !points.isEmpty {
                self.chartCache[symbol] = (points, Date())
            }
            content.setSummary(self.latestPrices[symbol])
            content.setPoints(points)
        }
    }

    func hideChartPopup() {
        removeChartDismissalMonitors()
        chartWindow?.orderOut(nil)
        chartWindow = nil
        chartContentView = nil
        activeChartSymbol = nil
    }

    private func installChartDismissalMonitors(ignoringEventsThrough openingEventTimestamp: TimeInterval) {
        removeChartDismissalMonitors()

        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.chartWindow != nil else { return }

            var monitors: [Any] = []
            if let local = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown], handler: { [weak self] event in
                guard let self = self else { return event }
                guard event.timestamp > openingEventTimestamp else { return event }
                if event.window !== self.chartWindow {
                    self.hideChartPopup()
                }
                return event
            }) {
                monitors.append(local)
            }

            if let global = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown], handler: { [weak self] event in
                guard event.timestamp > openingEventTimestamp else { return }
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
        let widgetAnchor = floatingWidgetScreenOrigin()
        config.isExpanded.toggle()
        config.save()
        updateWindowShadow()

        toggleButton?.isExpanded = config.isExpanded
        expandCollapseItem.title = config.isExpanded ? "Collapse Prices" : "Expand Prices"

        let (width, height) = calculateWindowSize()
        let frame = resizedWindowFrame(
            size: NSSize(width: width, height: height),
            preservingWidgetAt: widgetAnchor
        )

        NSAnimationContext.runAnimationGroup { context in
            context.duration = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : 0.25
            floatingWindow.animator().setFrame(frame, display: true)
        }

        containerView.frame = NSRect(origin: .zero, size: frame.size)
        layoutFloatingWidget()

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
        updateWindowShadow()
        let widgetAnchor = floatingWidgetScreenOrigin()

        let (width, height) = calculateWindowSize()
        let frame = resizedWindowFrame(
            size: NSSize(width: width, height: height),
            preservingWidgetAt: widgetAnchor
        )
        floatingWindow.setFrame(frame, display: true)

        containerView.frame = NSRect(origin: .zero, size: frame.size)
        setupFloatingWidget()

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
        let symbols = config.cryptos
        guard !symbols.isEmpty else {
            latestPrices = [:]
            marqueeWidget?.setMarketData(symbols: config.cryptos, prices: latestPrices)
            updateMenuBarTitle()
            updateAccent()
            updateStatusLabel()
            return
        }

        guard !isPriceRefreshInFlight else {
            isPriceRefreshPending = true
            return
        }

        isPriceRefreshInFlight = true
        let generation = marketGeneration
        let provider = config.dataProvider

        CryptoAPI.shared.fetchAllPrices(for: symbols, provider: provider) { [weak self] prices in
            guard let self = self,
                  generation == self.marketGeneration,
                  provider == self.config.dataProvider,
                  symbols == self.config.cryptos else {
                return
            }

            self.isPriceRefreshInFlight = false
            let mergeResult = PriceSnapshotMerger.merge(
                symbols: symbols,
                incoming: prices,
                previous: self.latestPrices
            )
            let merged = mergeResult.prices

            if mergeResult.successfulCount > 0 {
                self.lastSuccessfulPriceUpdate = Date()
            }
            self.latestPrices = merged
            self.marqueeWidget?.setMarketData(symbols: symbols, prices: merged)

            if self.config.isExpanded {
                for (symbol, data) in merged {
                    self.cryptoRows[symbol]?.update(price: data.price, change: data.change24h, hasError: data.hasError)
                }
            }
            if let activeSymbol = self.activeChartSymbol {
                self.chartContentView?.setSummary(merged[activeSymbol])
            }
            self.updateMenuBarTitle()
            self.updateAccent()
            self.updateStatusLabel()
            if self.config.isExpanded {
                self.refreshSparklines()
                self.refreshNetworkFees()
            }

            if self.isPriceRefreshPending {
                self.isPriceRefreshPending = false
                DispatchQueue.main.async { [weak self] in
                    self?.refreshPrices()
                }
            }
        }
    }

    /// Fetches sparkline data for tracked coins, throttled so each symbol is
    /// only re-fetched roughly every 5 minutes regardless of the price refresh rate.
    func refreshSparklines() {
        guard config.isExpanded, config.showSparklines else { return }

        let now = Date()
        let generation = marketGeneration
        let provider = config.dataProvider
        for symbol in config.cryptos {
            if let cached = sparklineCache[symbol] {
                cryptoRows[symbol]?.setSparkline(cached.values)
                if now.timeIntervalSince(cached.fetchedAt) < 290 { continue }
            }
            if let backoff = sparklineFailureBackoffs[symbol],
               !backoff.allowsAttempt(at: now) {
                continue
            }
            guard sparklineRequestsInFlight.insert(symbol).inserted else { continue }
            CryptoAPI.shared.fetchSparkline(for: symbol, provider: provider) { [weak self] values in
                guard let self = self,
                      generation == self.marketGeneration,
                      provider == self.config.dataProvider else {
                    return
                }
                self.sparklineRequestsInFlight.remove(symbol)
                if !values.isEmpty {
                    self.sparklineFailureBackoffs.removeValue(forKey: symbol)
                    self.sparklineCache[symbol] = (values, Date())
                    self.cryptoRows[symbol]?.setSparkline(values)
                } else {
                    var backoff = self.sparklineFailureBackoffs[symbol] ?? FailureBackoff()
                    backoff.recordFailure()
                    self.sparklineFailureBackoffs[symbol] = backoff
                }
            }
        }
    }

    func refreshNetworkFees(force: Bool = false) {
        guard config.isExpanded, config.showNetworkFees else { return }

        let now = Date()
        if !force,
           let cached = networkFeeCache,
           now.timeIntervalSince(cached.updatedAt) < networkFeeRefreshInterval {
            networkFeesView?.setData(cached)
            return
        }
        if !force, !networkFeeFailureBackoff.allowsAttempt(at: now) {
            if let cached = networkFeeCache {
                networkFeesView?.setData(cached)
            } else if let lastResult = lastNetworkFeeResult {
                networkFeesView?.setData(lastResult)
            }
            return
        }
        guard !isNetworkFeeRefreshInFlight else { return }

        isNetworkFeeRefreshInFlight = true
        networkFeesView?.setLoading()
        let generation = marketGeneration
        let provider = config.dataProvider

        let existingETH = latestPrices["ETH"].flatMap { data -> Double? in
            data.price > 0 ? data.price : nil
        }
        let existingBTC = latestPrices["BTC"].flatMap { data -> Double? in
            data.price > 0 ? data.price : nil
        }

        func fetchFees(ethPrice: Double?, btcPrice: Double?) {
            NetworkFeeAPI.shared.fetchFees(ethPrice: ethPrice, btcPrice: btcPrice) { [weak self] data in
                guard let self = self,
                      generation == self.marketGeneration,
                      provider == self.config.dataProvider else {
                    return
                }
                self.isNetworkFeeRefreshInFlight = false
                self.lastNetworkFeeResult = data
                if !data.hasError {
                    self.networkFeeFailureBackoff.reset()
                    self.networkFeeCache = data
                } else {
                    self.networkFeeFailureBackoff.recordFailure()
                }
                if self.config.isExpanded, self.config.showNetworkFees {
                    self.networkFeesView?.setData(
                        data.hasError ? (self.networkFeeCache ?? data) : data
                    )
                }
            }
        }

        if existingETH != nil && existingBTC != nil {
            fetchFees(ethPrice: existingETH, btcPrice: existingBTC)
            return
        }

        CryptoAPI.shared.fetchAllPrices(for: ["ETH", "BTC"], provider: provider) { [weak self] prices in
            guard let self = self,
                  generation == self.marketGeneration,
                  provider == self.config.dataProvider else {
                return
            }
            let ethPrice = existingETH ?? prices["ETH"].flatMap { (!$0.hasError && $0.price > 0) ? $0.price : nil }
            let btcPrice = existingBTC ?? prices["BTC"].flatMap { (!$0.hasError && $0.price > 0) ? $0.price : nil }
            fetchFees(ethPrice: ethPrice, btcPrice: btcPrice)
        }
    }

    func updateMenuBarTitle() {
        guard let button = statusItem.button else { return }
        if let sym = config.menuBarSymbol, let data = latestPrices[sym], data.price > 0 {
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            button.title = "\(sym) \(PriceFormatter.shared.compact(data.price))"
            button.toolTip = data.hasError ? "\(sym) last known price · reconnecting" : "\(sym) live price"
            button.setAccessibilityValue(
                "\(sym) \(PriceFormatter.shared.format(data.price))"
                    + (data.hasError ? ", last known price" : "")
            )
        } else {
            button.font = NSFont.systemFont(ofSize: 14)
            button.title = "₿"
            button.toolTip = "CryptoFloat"
            button.setAccessibilityValue("Open CryptoFloat menu")
        }
    }

    func updateAccent() {
        let primary = config.menuBarSymbol ?? config.cryptos.first
        if let p = primary, let data = latestPrices[p], !data.hasError {
            toggleButton?.accentChange = data.change24h ?? 0
            marqueeWidget?.accentChange = data.change24h ?? 0
        } else {
            toggleButton?.accentChange = 0
            marqueeWidget?.accentChange = 0
        }
    }

    func updateStatusLabel() {
        guard let label = updatedLabel else { return }
        let symbols = config.cryptos
        if symbols.isEmpty {
            label.stringValue = "No assets"
            label.textColor = ThemeCatalog.current.secondaryTextColor
            return
        }
        let erroredCount = symbols.filter { (latestPrices[$0]?.hasError ?? true) }.count
        let liveCount = symbols.count - erroredCount
        if lastSuccessfulPriceUpdate == nil {
            label.stringValue = "Connecting…"
            label.textColor = ThemeCatalog.current.secondaryTextColor
        } else if liveCount == 0 {
            label.stringValue = "Reconnecting…"
            label.textColor = ThemeCatalog.current.negativeTextColor
        } else if liveCount < symbols.count {
            label.stringValue = "\(liveCount)/\(symbols.count) live · \(timeFormatter.string(from: lastSuccessfulPriceUpdate!))"
            label.textColor = ThemeCatalog.current.warning.color()
        } else {
            label.stringValue = "Updated \(timeFormatter.string(from: lastSuccessfulPriceUpdate!))"
            label.textColor = ThemeCatalog.current.secondaryTextColor
        }
    }

    // MARK: - Actions
    @objc func toggleWindowVisibility() {
        if floatingWindow.isVisible {
            hideChartPopup()
            marqueeWidget?.setPaused(true)
            floatingWindow.orderOut(nil)
            showHideItem.title = "Show Window"
        } else {
            floatingWindow.orderFrontRegardless()
            marqueeWidget?.setPaused(false)
            showHideItem.title = "Hide Window"
        }
    }

    @objc func toggleExpandedFromMenu() {
        toggleExpanded()
    }

    @objc func setFloatingWidgetMode(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let mode = FloatingWidgetMode(rawValue: rawValue),
              mode != config.floatingWidgetMode else {
            return
        }

        hideChartPopup()
        let widgetAnchor = floatingWidgetScreenOrigin()
        config.floatingWidgetMode = mode
        config.save()
        updateFloatingWidgetMenu()
        updateWindowShadow()

        let (width, height) = calculateWindowSize()
        let frame = resizedWindowFrame(
            size: NSSize(width: width, height: height),
            preservingWidgetAt: widgetAnchor
        )
        floatingWindow.setFrame(frame, display: true)

        containerView.frame = NSRect(origin: .zero, size: frame.size)
        setupFloatingWidget()
        setupContentPanel()

        refreshPrices()
    }

    @objc func setTheme(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let themeName = AppThemeName(rawValue: rawValue),
              themeName != config.theme else {
            return
        }

        config.theme = themeName
        ThemeCatalog.current = ThemeCatalog.theme(for: themeName)
        config.save()
        updateThemeMenu()

        if config.isExpanded {
            rebuildWindow()
        } else {
            setupFloatingWidget()
            refreshPrices()
        }

        chartContentView?.needsDisplay = true
        updateStatusLabel()
    }

    @objc func setDataProvider(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let provider = DataProvider(rawValue: rawValue),
              provider != config.dataProvider else {
            return
        }

        hideChartPopup()
        config.dataProvider = provider
        invalidateMarketRequests()
        config.save()
        updateDataProviderMenu()

        marqueeWidget?.setMarketData(symbols: config.cryptos, prices: latestPrices)

        if config.isExpanded {
            rebuildWindow()
        } else {
            refreshPrices()
        }
    }

    @objc func setTransparency(_ sender: NSMenuItem) {
        let level = Double(sender.tag) / 100.0
        config.transparency = level
        config.save()
        floatingWindow.alphaValue = 1
        toggleButton?.backgroundOpacity = CGFloat(level)
        marqueeWidget?.backgroundOpacity = CGFloat(level)
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

    @objc func toggleNetworkFees(_ sender: NSMenuItem) {
        config.showNetworkFees.toggle()
        config.save()
        networkFeesToggleItem.state = config.showNetworkFees ? .on : .off
        rebuildWindow()
        if config.showNetworkFees {
            refreshNetworkFees(force: true)
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
        guard config.cryptos.count < AppConfig.maximumTrackedSymbols else {
            let limitAlert = NSAlert()
            limitAlert.alertStyle = .informational
            limitAlert.messageText = "Tracking Limit Reached"
            limitAlert.informativeText = "CryptoFloat supports up to \(AppConfig.maximumTrackedSymbols) assets at once."
            limitAlert.runModal()
            return
        }

        let alert = NSAlert()
        alert.messageText = "Add Cryptocurrency"
        alert.informativeText = "Enter the trading symbol (e.g., 'BTC', 'ETH', 'SOL', 'DOGE').\n\nKuCoin and Binance use USDT pairs. CoinGecko uses USD aggregate data for supported mapped symbols."
        alert.addButton(withTitle: "Add")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.placeholderString = "e.g., BTC"
        alert.accessoryView = textField
        alert.window.initialFirstResponder = textField

        if alert.runModal() == .alertFirstButtonReturn {
            guard let symbol = AppConfig.normalizedSymbol(textField.stringValue) else {
                let invalidAlert = NSAlert()
                invalidAlert.alertStyle = .warning
                invalidAlert.messageText = "Invalid Symbol"
                invalidAlert.informativeText = "Use 1–15 ASCII letters or numbers, such as BTC, ETH, or 1INCH."
                invalidAlert.runModal()
                return
            }
            guard !config.cryptos.contains(symbol) else {
                let duplicateAlert = NSAlert()
                duplicateAlert.alertStyle = .informational
                duplicateAlert.messageText = "\(symbol) Is Already Tracked"
                duplicateAlert.runModal()
                return
            }

            invalidateMarketRequests(clearPrices: false)
            config.cryptos.append(symbol)
            config.save()
            updateRemoveMenu()
            updateMenuBarMenu()
            rebuildWindow()
            if !config.isExpanded {
                marqueeWidget?.setMarketData(symbols: config.cryptos, prices: latestPrices)
                refreshPrices()
            }
        }
    }

    @objc func removeCrypto(_ sender: NSMenuItem) {
        guard let symbol = sender.representedObject as? String else { return }
        if activeChartSymbol == symbol {
            hideChartPopup()
        }
        invalidateMarketRequests(clearPrices: false)
        config.cryptos.removeAll { $0 == symbol }
        latestPrices[symbol] = nil
        if config.menuBarSymbol == symbol {
            config.menuBarSymbol = nil
        }
        config.save()
        updateRemoveMenu()
        updateMenuBarMenu()
        updateMenuBarTitle()
        rebuildWindow()
        if !config.isExpanded {
            marqueeWidget?.setMarketData(symbols: config.cryptos, prices: latestPrices)
            refreshPrices()
        }
    }

    @objc func resetDefaults() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Reset CryptoFloat?"
        alert.informativeText = "This restores all display, data source, watchlist, refresh, and window settings."
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        hideChartPopup()
        config = AppConfig.default
        invalidateMarketRequests()
        ThemeCatalog.current = ThemeCatalog.theme(for: config.theme)
        config.save()

        updateWindowShadow()
        updateRemoveMenu()
        updateMenuBarMenu()
        updateFloatingWidgetMenu()
        updateThemeMenu()
        updateDataProviderMenu()
        updateMenuBarTitle()

        for item in transparencyMenu.items {
            item.state = item.tag == Int(config.transparency * 100) ? .on : .off
        }
        for item in refreshRateMenu.items {
            item.state = item.tag == config.refreshRate ? .on : .off
        }
        sparklineToggleItem.state = config.showSparklines ? .on : .off
        networkFeesToggleItem.state = config.showNetworkFees ? .on : .off
        expandCollapseItem.title = config.isExpanded ? "Collapse Prices" : "Expand Prices"

        let (width, height) = calculateWindowSize()
        let frame = clampedWindowFrame(
            NSRect(
                x: config.windowX,
                y: config.windowY,
                width: width,
                height: height
            )
        )
        floatingWindow.alphaValue = 1
        floatingWindow.setFrame(frame, display: true)
        containerView.frame = NSRect(origin: .zero, size: frame.size)
        setupFloatingWidget()
        setupContentPanel()

        restartUpdateTimer()
        refreshPrices()
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}
