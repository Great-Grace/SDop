# SDop! — Stop Dopamine

> 도파민을 원하면, 그에 따른 책임을 져라.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    SDop! Main App                        │
│  ┌──────────┐  ┌──────────────┐  ┌───────────────────┐  │
│  │Onboarding│  │  Dashboard   │  │ Reading Challenge  │  │
│  │  Screen  │  │  (Toggle+    │  │ (Book Content +    │  │
│  │          │  │   Stats)     │  │  Quiz + Timer)     │  │
│  └──────────┘  └──────────────┘  └───────────────────┘  │
│  ┌──────────┐  ┌──────────────┐  ┌───────────────────┐  │
│  │ Settings │  │  Content     │  │  App Selection     │  │
│  │ (Time    │  │  Library     │  │  (FamilyControls   │  │
│  │  limits) │  │  (Books)     │  │   picker)          │  │
│  └──────────┘  └──────────────┘  └───────────────────┘  │
└────────────────────┬────────────────────────────────────┘
                     │ FamilyControls Authorization
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Apple Screen Time System                     │
│  ┌─────────────────┐  ┌──────────────────────────────┐  │
│  │ ManagedSettings  │  │   DeviceActivityMonitor      │  │
│  │ (Shield Config)  │  │   (Extension — separate proc)│  │
│  └─────────────────┘  └──────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Key Frameworks

| Framework | Purpose |
|-----------|---------|
| `FamilyControls` | Request authorization to monitor/restrict apps |
| `ManagedSettings` | Apply shield overlays on target apps |
| `DeviceActivityMonitor` | Extension to monitor app usage events |
| `SwiftUI` | UI framework |
| `SwiftData` | Local data persistence |

## App Flow

### 1. Onboarding
- Explain SDop concept
- Request FamilyControls authorization
- User selects target apps (Instagram, YouTube, etc.)
- User sets time limits (30min, 1hr, etc.)
- User selects reading content category

### 2. Normal Operation
- SDop applies shields via ManagedSettings to selected apps
- Shield appears when user tries to open target app
- Shield shows "Read to unlock" with SDop branding

### 3. Reading Challenge
- User taps shield → Opens SDop reading view
- Must scroll through 10-20 pages of content
- Minimum reading time enforced (e.g., 5 min per 10 pages)
- Comprehension quiz at the end (3-5 questions)
- Must pass quiz (>60%) to unlock target app
- Unlock is temporary (configurable: 30min, 1hr, etc.)

### 4. Time Limit Reached
- DeviceActivityMonitor detects threshold
- Shield reappears on target app
- User must complete another reading challenge

## Content Strategy (MVP)

### Phase 1: Korean Public Domain Classics
- Source: Project Gutenberg (ko), 한국 고전 문학
- 저작권 만료된 작품 (사후 70년)
- Examples: 춘향전, 흥부전, 홍길동전, 토지(박경리 — 아직 안됨), 이광수 작품들
- Format: Chapter-based, 10-20 page segments

### Phase 2: Expanded Content
- News articles (partnered or public domain)
- English learning materials
- Educational content
- User-uploaded content

### Content Format
```swift
struct ReadingContent {
    let id: UUID
    let title: String           // "춘향전 - 제1장"
    let author: String          // "작자 미상"
    let category: ContentCategory  // .koreanClassic, .news, .english
    let pages: [Page]           // 10-20 pages
    let quiz: [QuizQuestion]    // 3-5 comprehension questions
    let difficulty: Difficulty  // .easy, .medium, .hard
}

struct Page {
    let pageNumber: Int
    let content: String         // Plain text, ~500 words per page
}

struct QuizQuestion {
    let question: String
    let options: [String]       // 4 options
    let correctIndex: Int
    let explanation: String
}
```

## Shield Configuration

### ShieldConfigurationExtension
Customizes the appearance of the system shield:
- SDop branding (logo, colors)
- Motivational message: "도파민을 원하면 책임을 져라!"
- "책 읽고 해제하기" button
- Remaining reading progress indicator

### DeviceActivityMonitor Extension
Monitors app usage:
- `intervalDidStart` — Schedule started
- `intervalDidEnd` — Schedule ended
- `eventDidReachThreshold` — Time limit hit → re-apply shield
- `intervalWillStartWarning` / `intervalWillEndWarning` — Pre-warnings

## Data Model (SwiftData)

```swift
@Model
class UserProfile {
    var name: String
    var isActive: Bool
    var selectedApps: [Application]  // FamilyControls tokenized
    var timeLimits: [TimeLimit]
    var totalReadingPages: Int
    var streakDays: Int
}

@Model
class ReadingSession {
    var contentId: UUID
    var startTime: Date
    var endTime: Date?
    var pagesRead: Int
    var quizScore: Double
    var passed: Bool
}

@Model
class TimeLimit {
    var appToken: ApplicationToken
    var dailyLimit: TimeInterval
    var challengeInterval: TimeInterval  // Re-challenge after this time
}
```

## Business Model

### Free Tier
- 3 target apps
- Basic classics library
- 30min default time limit

### Premium (구독)
- Unlimited target apps
- Expanded content library (news, English, educational)
- Custom time limits
- Statistics & insights
- Streak tracking & gamification

### B2B (Future)
- Corporate digital wellbeing
- School/institution licenses
- Custom content packages

## Technical Requirements

- iOS 16.0+ (FamilyControls stable)
- Xcode 15+
- Swift 5.9+
- No third-party dependencies (MVP)

## Entitlement Required

`com.apple.developer.family-controls`

Apply at: https://developer.apple.com/contact/request/family-controls

Justification: Digital wellbeing / self-discipline tool for adults.
