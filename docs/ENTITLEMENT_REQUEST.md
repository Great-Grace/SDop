# FamilyControls Entitlement 신청 가이드

## 신청 방법

1. https://developer.apple.com/contact/request/family-controls 접속
2. Apple Developer 계정으로 로그인
3. 아래 정보 입력

## 입력 정보

### App Name
SDop! (Stop Dopamine)

### Bundle Identifier
com.greatgrace.sdop

### App Description (영문 — Apple 제출용)

SDop! is a digital wellbeing app that helps users build healthier screen time habits by requiring them to complete reading challenges before accessing distracting apps like social media and video platforms.

**Core Concept:** "Earn your dopamine" — before opening apps like Instagram, YouTube, or TikTok, users must read 10-20 pages of curated educational content and pass a comprehension quiz. This creates a productive friction that transforms mindless scrolling time into learning opportunities.

**How it works:**
1. Users select which apps they want to manage (social media, video, games)
2. When they try to open a managed app, SDop presents a reading challenge
3. Users must read through book content and answer quiz questions
4. Only after passing the quiz can they access the managed app
5. After their configured time limit, the challenge repeats

**Content:** MVP features Korean translations of public domain classical literature (Chunhyangjeon, Heungbujeon, Honggildongjeon, etc.) with plans to expand to news articles, educational content, and language learning materials.

**Target Audience:** Adults (18+) who want to reduce mindless screen time and replace it with productive reading. This is NOT a parental control app — it's a self-discipline tool for adults who want to be more intentional about their digital consumption.

**Privacy:**
- All data stored locally on device (SwiftData)
- No user accounts or server communication required
- FamilyControls used solely to monitor the user's own app usage
- No data shared with third parties

### Why FamilyControls is Required

The FamilyControls framework is essential because SDop needs to:
1. Monitor when the user opens their selected apps (DeviceActivityMonitor)
2. Present a shield/overlay before the app launches (ManagedSettings)
3. Track usage duration to trigger re-challenges

Without FamilyControls, we cannot detect app launches or present timely interventions. The ManagedSettings shield is the only way to intercept app launches on iOS without jailbreaking.

### Korean Description (내부 참고용)

SDop!은 소셜 미디어 및 동영상 앱 사용 전에 독서 챌린지를 완료하도록 요구하여 건전한 스크린 타임 습관을 형성하는 디지털 웰빙 앱입니다.

사용자가 인스타그램, 유튜브 등의 앱을 열려고 하면, SDop이 저작권이 만료된 고전 문학 작품 10~20페이지를 제시합니다. 독서를 완료하고 이해도 퀴즈를 통과해야만 해당 앱을 사용할 수 있습니다.

이를 통해 무의미한 스크롤링 시간을 생산적인 독서 시간으로 전환합니다.

## 대안: 없을 경우의 폴백 플랜

만약 FamilyControls entitlement가 거부된다면:

### Plan B: Safari Content Blocker
- Safari에서만 작동하지만 별도 entitlement 불필요
- `SFContentBlockerManager` + `SFContentBlockerRuleList`
- 웹 기반 SNS (인스타그램 웹, 유튜브 웹) 차단 가능
- 네이티브 앱은 차단 불가

### Plan C: Focus Filter + App Intent
- iOS 16+ Focus Filter API 활용
- 사용자가 직접 Focus 모드를 활성화
- SDop이 Focus 상태에서 콘텐츠 제공
- 자동 차단은 불가하지만 UX로 보완

## 참조: 승인된 유사 앱들

- **Opal** — Screen time management with FamilyControls
- **One Sec** — Adds breathing exercise before opening apps
- **ScreenZen** — Adds delay/custom screen before apps
- **Clearspace** — Mindfulness-based app blocking

이 앱들이 승인되었다는 점을 근거로 SDop의 승인 가능성은 높음.
