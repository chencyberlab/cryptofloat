# CryptoFloat (Swift Version)

A native macOS menu bar app for tracking cryptocurrency prices with a floating, collapsible window.
<img width="1318" height="662" alt="CleanShot 2026-02-13 at 09 44 41@2x" src="https://github.com/user-attachments/assets/a56095d0-de24-4570-a9b8-db548b1bb353" />


## Features

- **Native Swift** – No Python dependencies, runs natively on macOS
- **Collapsible Toggle Button** – Click the ₿ button to expand/collapse, with a hover glow and an accent ring that turns green/red with the market
- **Floating Window** – Always-on-top with liquid-glass styling
- **Sparklines** – A 24h mini trend line on each row (toggleable)
- **Menu-Bar Price Ticker** – Optionally show any tracked coin's live price right in the menu bar
- **Hover Highlights** – Rows light up as you mouse over them
- **Resilient** – Keeps the last known price (dimmed) during a network blip instead of blanking to "Error", and shows a live "updated / reconnecting…" status
- **Menu Bar Controls** – All settings accessible from the menu bar
- **Adjustable Transparency** – 50% to 100% opacity
- **Adjustable Refresh Rate** – 5 seconds to 5 minutes (default 30s)
- **24h Change** – Color-coded price changes (green/red) with up/down tick animations
- **Draggable** – Position the window anywhere on screen
- **Persistent Settings** – Remembers your preferences (and tolerates older/partial config files)

## Data Source

Prices come from the **public KuCoin API** (`api.kucoin.com`). Each coin is tracked
as a `SYMBOL-USDT` trading pair, and sparklines use hourly candles.

## Requirements

- macOS 11.0 (Big Sur) or later
- Xcode Command Line Tools

## Quick Start

### Step 1: Install Xcode Command Line Tools (if not already installed)

```bash
xcode-select --install
```

### Step 2: Download and extract the files

Put `CryptoFloat.swift` and `build.sh` in a folder, e.g.:
```
~/Desktop/Development/crypto_float/
```

### Step 3: Build the app

```bash
cd ~/Desktop/Development/crypto_float
chmod +x build.sh
./build.sh
```

### Step 4: Run the app

```bash
open CryptoFloat.app
```

Or double-click `CryptoFloat.app` in Finder.

### Step 5: (Optional) Install to Applications

```bash
cp -r CryptoFloat.app /Applications/
```

## Usage

### Toggle Button
- **Click the ₿ button** to expand/collapse the price panel
- **Drag** anywhere on the window background to reposition
- The ring around the button is tinted by the primary coin's 24h direction (green = up, red = down)

### Menu Bar (₿ icon)
| Menu Item | Description |
|-----------|-------------|
| Show/Hide Window | Toggle window visibility |
| Expand/Collapse Prices | Same as clicking the button |
| Transparency | Adjust window opacity (50%–100%) |
| Refresh Rate | How often prices update (5s–5min) |
| Show Sparklines | Toggle the 24h mini charts |
| Menu Bar Display | Show a coin's price in the menu bar, or just the ₿ icon |
| Add Cryptocurrency… | Add by trading symbol (paired with USDT) |
| Remove Cryptocurrency | Remove a tracked coin |
| Reset to Defaults | Restore BTC, ETH, SOL |
| Refresh Now | Force a price refresh (⌘R) |
| Quit CryptoFloat | Exit the app (⌘Q) |

### Adding Cryptocurrencies

1. Click ₿ in the menu bar
2. Select "Add Cryptocurrency…"
3. Enter the **trading symbol** (it is automatically paired with USDT)

**Common symbols:**
- `BTC` – Bitcoin
- `ETH` – Ethereum
- `SOL` – Solana
- `ADA` – Cardano
- `DOGE` – Dogecoin
- `XRP` – Ripple
- `DOT` – Polkadot

Any symbol that KuCoin lists against USDT will work (e.g. `AVAX`, `LINK`, `MATIC`).

## Configuration

Settings are stored in: `~/.cryptofloat_config.json`

```json
{
  "cryptos": ["BTC", "ETH", "SOL"],
  "transparency": 0.85,
  "windowX": 100,
  "windowY": 100,
  "isExpanded": true,
  "refreshRate": 30,
  "showSparklines": true,
  "menuBarSymbol": null
}
```

The config loader is tolerant: if a key is missing or a new version adds fields,
your existing settings are preserved and only the missing values fall back to defaults.

## Troubleshooting

### "App is damaged" or won't open

```bash
xattr -cr CryptoFloat.app
open CryptoFloat.app
```

### Build fails

Make sure Xcode Command Line Tools are installed:
```bash
xcode-select --install
```

### Prices show "—" or "reconnecting…"

- Check your internet connection
- The KuCoin API might be temporarily unavailable, or the symbol may not be listed against USDT
- Click "Refresh Now" to retry (the last known price stays visible, dimmed, during outages)

## License

MIT License – Feel free to modify and distribute.
