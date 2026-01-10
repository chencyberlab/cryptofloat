# CryptoFloat (Swift Version)

A native macOS menu bar app for tracking cryptocurrency prices with a floating, collapsible window.

## Features

- **Native Swift** - No Python dependencies, runs natively on macOS
- **Collapsible Toggle Button** - Click the ₿ button to expand/collapse
- **Floating Window** - Always-on-top with liquid glass styling
- **Menu Bar Controls** - All settings accessible from menu bar
- **Adjustable Transparency** - 50% to 100% opacity
- **Real-time Updates** - Prices refresh every 60 seconds
- **24h Change** - Color-coded price changes (green/red)
- **Draggable** - Position window anywhere on screen
- **Persistent Settings** - Remembers your preferences

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
- **Drag** anywhere on the window to reposition

### Menu Bar (₿ icon)
| Menu Item | Description |
|-----------|-------------|
| Show/Hide Window | Toggle window visibility |
| Expand/Collapse Prices | Same as clicking the button |
| Transparency | Adjust window opacity |
| Add Cryptocurrency... | Add by CoinGecko ID |
| Remove Cryptocurrency | Remove tracked crypto |
| Reset to Defaults | Restore BTC, ETH, SOL |
| Refresh Now | Force price refresh |
| Quit CryptoFloat | Exit the app |

### Adding Cryptocurrencies

1. Click ₿ in menu bar
2. Select "Add Cryptocurrency..."
3. Enter the CoinGecko ID

**Common IDs:**
- `bitcoin` - BTC
- `ethereum` - ETH
- `solana` - SOL
- `cardano` - ADA
- `dogecoin` - DOGE
- `ripple` - XRP
- `polkadot` - DOT

Find more at [coingecko.com](https://coingecko.com) - the ID is in the URL.

## Configuration

Settings are stored in: `~/.cryptofloat_config.json`

```json
{
  "cryptos": ["bitcoin", "ethereum", "solana"],
  "transparency": 0.85,
  "windowX": 100,
  "windowY": 100,
  "isExpanded": true
}
```

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

### Prices show "Error"

- Check your internet connection
- CoinGecko API might be temporarily unavailable
- Click "Refresh Now" to retry

## License

MIT License - Feel free to modify and distribute.
