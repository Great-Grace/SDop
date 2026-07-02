# SDop! — Stop Dopamine 📖

> 도파민을 원하면, 그에 따른 책임을 져라.

## What is SDop?

SDop! is an iOS app that forces you to **read before you scroll**. Before opening distracting apps (Instagram, YouTube, TikTok, etc.), you must complete a reading challenge:

1. 📱 Open a shielded app → SDop intercepts
2. 📖 Read 10-20 pages of curated content
3. ✅ Pass a comprehension quiz
4. 🎉 App unlocked for your configured duration
5. 🔁 After time limit → challenge repeats

## Architecture

- **FamilyControls + ManagedSettings** — System-level app shielding
- **DeviceActivityMonitor** — Usage time tracking
- **SwiftUI + SwiftData** — Modern iOS stack (iOS 17+)
- **No third-party dependencies** — Pure Apple frameworks

## Project Structure

```
SDop/
├── App/                          # Main app entry
├── Core/
│   ├── Models/                   # Data models (ReadingContent, UserProfile)
│   ├── Services/                 # ShieldManager, ContentService
│   └── Extensions/               # ApplicationToken helpers
├── Features/
│   ├── Onboarding/               # First-launch setup
│   ├── Dashboard/                # Main screen with toggle + stats
│   ├── ReadingChallenge/         # Book reader + quiz
│   ├── ContentLibrary/           # Book browsing
│   └── Settings/                 # App configuration
├── Resources/Books/              # JSON book content
├── Config/                       # Entitlements
├── SDopShieldExtension/          # ManagedSettings shield UI
└── SDopDeviceActivityExtension/  # Usage monitor
```

## Content (MVP)

Korean translations of public domain classics:
- 춘향전 (Chunhyangjeon)
- 흥부전 (Heungbujeon)
- 홍길동전 (Honggildongjeon)

## Business Model

| Tier | Price | Features |
|------|-------|----------|
| Free | ₩0 | 3 target apps, basic classics |
| Premium | Subscription | Unlimited apps, expanded library, stats |

## Building

```bash
# Generate Xcode project (requires xcodegen)
brew install xcodegen
xcodegen generate

# Open in Xcode
open SDop.xcodeproj
```

**Note:** FamilyControls entitlement must be approved by Apple before the app can function. See `docs/ENTITLEMENT_REQUEST.md`.

## Requirements

- iOS 17.0+
- Xcode 15+
- Swift 5.9+
- FamilyControls entitlement (apply via Apple Developer)

## License

Proprietary — Great-Grace
