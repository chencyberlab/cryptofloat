# CryptoFloat

A native macOS menu bar app for tracking cryptocurrency prices in a floating, draggable widget.

<img width="1318" height="662" alt="CryptoFloat screenshot" src="https://github.com/user-attachments/assets/a56095d0-de24-4570-a9b8-db548b1bb353" />

## Features

- **Native Swift** - no Python runtime or web UI required.
- **Two floating widget modes** - choose between the compact Bitcoin button or a scrolling marquee ticker.
- **Marquee price widget** - shows tracked symbols, live prices, and 24h percentage changes while the main panel is collapsed.
- **Dropdown price panel** - expands from the floating widget and stays always on top.
- **7-day chart popup** - click any crypto row to open a small chart popup; click anywhere to hide it.
- **Interactive chart hover** - move over the 7-day chart to see historical candle prices and times.
- **24h sparklines** - optional mini trend line on each row.
- **Menu-bar ticker** - optionally show one tracked coin's price in the macOS menu bar.
- **Background-only transparency** - the widget background fades from 50% to 100%, while text and charts stay readable.
- **Selectable color themes** - keep the default CryptoFloat look or switch to Tokyo Night, Dracula, Nord, Catppuccin Mocha, One Dark Pro, Everforest Dark, Gruvbox Dark, or Cyberpunk Neon.
- **Color-coded movement** - green/red 24h changes, price-change flashes, arrows, and accent tinting.
- **Resilient updates** - keeps the last known price during network hiccups and shows updated/reconnecting status.
- **Generated app icon** - build script creates and bundles a modern line-chart app icon.
- **Persistent settings** - remembers tracked coins, widget mode, position, refresh rate, transparency, and display preferences.

## Data Source

Prices come from the public KuCoin API (`api.kucoin.com`). Each coin is tracked as a `SYMBOL-USDT` trading pair.

- Current price and 24h change use KuCoin market stats.
- Row sparklines use hourly candle data.
- The detail popup uses 2-hour candles across roughly 7 days.

## Requirements

- macOS 11.0 Big Sur or later
- Xcode Command Line Tools

Install command line tools if needed:

```bash
xcode-select --install
```

## Quick Start

Put `CryptoFloat.swift`, `generate_icon.swift`, and `build.sh` in the same folder, then build:

```bash
chmod +x build.sh
./build.sh
```

Run the app:

```bash
open CryptoFloat.app
```

Optional install:

```bash
cp -r CryptoFloat.app /Applications/
```

## Usage

### Floating Widget

- Drag the floating widget to reposition the app.
- Click the widget to expand or collapse the price panel.
- In **Simple Bitcoin** mode, the widget is a compact Bitcoin button.
- In **Marquee Prices** mode, the widget scrolls tracked coins horizontally with price and 24h change.
- In marquee mode, the expanded price panel drops down below the marquee bar and matches its width.

### Price Panel

- Hover rows for a subtle highlight.
- Click a row to open a 7-day chart popup.
- Move over the chart line to inspect historical price points.
- Click anywhere outside the chart popup to dismiss it.
- If sparklines are enabled, each row shows a small 24h trend chart.

### Menu Bar

| Menu Item | Description |
| --- | --- |
| Show/Hide Window | Toggle floating window visibility |
| Expand/Collapse Prices | Same as clicking the floating widget |
| Floating Widget | Choose Simple Bitcoin or Marquee Prices |
| Theme | Choose the active color scheme |
| Transparency | Adjust background opacity from 50% to 100% |
| Refresh Rate | Choose update interval from 5 seconds to 5 minutes |
| Show Sparklines | Toggle row mini charts |
| Menu Bar Display | Show a coin's price in the macOS menu bar, or only the Bitcoin symbol |
| Add Cryptocurrency... | Add a tracked symbol paired with USDT |
| Remove Cryptocurrency | Remove a tracked symbol |
| Reset to Defaults | Restore BTC, ETH, SOL and default settings |
| Refresh Now | Force a price refresh |
| Quit CryptoFloat | Exit the app |

### Adding Cryptocurrencies

1. Open the menu bar item.
2. Select **Add Cryptocurrency...**.
3. Enter a trading symbol such as `BTC`, `ETH`, `SOL`, or `DOGE`.

CryptoFloat automatically tracks the symbol as `SYMBOL-USDT` on KuCoin.

Common symbols:

- `BTC` - Bitcoin
- `ETH` - Ethereum
- `SOL` - Solana
- `ADA` - Cardano
- `DOGE` - Dogecoin
- `XRP` - XRP
- `DOT` - Polkadot
- `AVAX` - Avalanche
- `LINK` - Chainlink

Any symbol listed on KuCoin against USDT should work.

## Build Output

The build script creates:

- `CryptoFloat.app`
- `AppIcon.icns`
- `AppIcon.iconset/`

`generate_icon.swift` draws the app icon and `iconutil` packages it into the macOS `.icns` format. The generated icon is copied into `CryptoFloat.app/Contents/Resources/` and referenced by `Info.plist`.

## Configuration

Settings are stored at:

```text
~/.cryptofloat_config.json
```

Example:

```json
{
  "cryptos": [
    "BTC",
    "ETH",
    "SOL"
  ],
  "floatingWidgetMode": "bitcoin",
  "isExpanded": true,
  "menuBarSymbol": null,
  "refreshRate": 30,
  "showSparklines": true,
  "theme": "cryptoFloat",
  "transparency": 0.85,
  "windowX": 100,
  "windowY": 100
}
```

`floatingWidgetMode` can be:

- `"bitcoin"` - compact Bitcoin button
- `"marquee"` - scrolling price ticker

`theme` can be:

- `"cryptoFloat"` - the default theme
- `"tokyoNight"`
- `"dracula"`
- `"nord"`
- `"catppuccinMocha"`
- `"oneDarkPro"`
- `"everforestDark"`
- `"gruvboxDark"`
- `"cyberpunkNeon"`

The config loader is tolerant: missing or malformed keys fall back to defaults, so older config files still work.

## Troubleshooting

### App Is Damaged Or Will Not Open

```bash
xattr -cr CryptoFloat.app
open CryptoFloat.app
```

### Build Fails

Make sure Xcode Command Line Tools are installed:

```bash
xcode-select --install
```

### Prices Show `-` Or `reconnecting...`

- Check your internet connection.
- KuCoin may be temporarily unavailable.
- The symbol may not be listed against USDT.
- Use **Refresh Now** from the menu bar.

### Icon Does Not Update Immediately

macOS may cache app icons. Try quitting the app, rebuilding, and opening the fresh `CryptoFloat.app`. If it was copied to `/Applications`, replace the old copy.

## License

MIT License - feel free to modify and distribute.
