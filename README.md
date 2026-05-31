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
- **Optional network fees** - show ETH slow/standard/fast gas and BTC slow/standard/fast fee estimates below the price panel.
- **24h sparklines** - optional mini trend line on each row.
- **Menu-bar ticker** - optionally show one tracked coin's price in the macOS menu bar.
- **Background-only transparency** - the widget background fades from 50% to 100%, while text and charts stay readable.
- **Selectable color themes** - keep the default CryptoFloat look or switch to Tokyo Night, Dracula, Nord, Catppuccin Mocha, One Dark Pro, Everforest Dark, Gruvbox Dark, or Cyberpunk Neon.
- **Selectable data sources** - switch between KuCoin, Binance, and CoinGecko from the menu bar.
- **Color-coded movement** - green/red 24h changes, price-change flashes, arrows, and accent tinting.
- **Resilient updates** - keeps the last known price during network hiccups and shows updated/reconnecting status.
- **Generated app icon** - build script creates and bundles a modern line-chart app icon.
- **Persistent settings** - remembers tracked coins, widget mode, position, refresh rate, transparency, and display preferences.

## Data Source

CryptoFloat can use multiple public market-data providers:

| Provider | Pair/Currency | Notes |
| --- | --- | --- |
| KuCoin | `SYMBOL-USDT` | Default source; exchange-style market stats and candles |
| Binance | `SYMBOLUSDT` | Uses Binance public market-data ticker and kline endpoints |
| CoinGecko | USD | Uses CoinGecko aggregate market data; common symbols are mapped to CoinGecko coin IDs |

Current price and 24h change use the selected provider. Row sparklines and 7-day chart popups also switch with the selected provider.

CoinGecko has broad coverage but public endpoints are IP-rate-limited. Unknown or ambiguous symbols may not resolve unless they are in CryptoFloat's built-in CoinGecko symbol map.

Network fee estimates use public endpoints:

- Ethereum gas uses `eth_feeHistory` through public Ethereum JSON-RPC endpoints.
- Bitcoin fee rates use a conservative multi-source estimate from mempool.space, Blockstream, Blockchair, BlockCypher, and fresh Bitcoiner.live data when available.
- ETH USD estimates assume a standard 21,000 gas ETH transfer.
- BTC USD estimates assume a typical 140 vbyte transaction.

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
| Data Source | Choose KuCoin, Binance, or CoinGecko |
| Transparency | Adjust background opacity from 50% to 100% |
| Refresh Rate | Choose update interval from 5 seconds to 5 minutes |
| Show Sparklines | Toggle row mini charts |
| Show Network Fees | Toggle ETH/BTC fee estimates below the price panel |
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

CryptoFloat tracks the symbol through the currently selected data source. KuCoin and Binance use USDT pairs; CoinGecko uses USD aggregate market data for supported mapped symbols.

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

Any symbol listed against USDT on the selected exchange source should work. CoinGecko works best for common symbols already mapped in the app.

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
  "dataProvider": "kuCoin",
  "floatingWidgetMode": "bitcoin",
  "isExpanded": true,
  "menuBarSymbol": null,
  "refreshRate": 30,
  "showNetworkFees": false,
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

`dataProvider` can be:

- `"kuCoin"` - KuCoin `SYMBOL-USDT`
- `"binance"` - Binance `SYMBOLUSDT`
- `"coinGecko"` - CoinGecko USD aggregate market data

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
- The selected data provider may be temporarily unavailable or region-restricted.
- The symbol may not be listed against USDT on the selected exchange source.
- CoinGecko may not have a built-in mapping for that symbol.
- Use **Refresh Now** from the menu bar.

### Icon Does Not Update Immediately

macOS may cache app icons. Try quitting the app, rebuilding, and opening the fresh `CryptoFloat.app`. If it was copied to `/Applications`, replace the old copy.

## License

MIT License - feel free to modify and distribute.
