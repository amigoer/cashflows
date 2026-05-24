# CashFlows

**English** · [中文](./README.zh-CN.md)

A native iOS app for tracking personal cash flow against installment debts. Snap a screenshot of your installment bill and CashFlows auto-fills the data — no typing, no cloud.

## Why

Most consumer finance apps focus on expense tracking. They don't answer the question this app exists to solve:

> After my salary lands and I deduct every installment platform's monthly payment, how much spendable cash do I actually have left this month?

Manual entry is the friction that kills any tracker. CashFlows uses on-device OCR (Apple Vision) so you upload a screenshot of your Huabei / JD Baitiao / credit-card installment page and the platform, principal, total periods, monthly payment, and first due date are filled in automatically.

## Features

- **Screenshot import** — Apple Vision text recognition + per-platform parsers for Huabei, JD Baitiao, and credit-card installment. Fully on-device.
- **Manual fallback** — every field can still be entered or corrected by hand.
- **Repayment scheduling** — creating a debt plan auto-generates the full installment timeline.
- **Mark-as-paid** — tap any installment to flag it paid; overdue items are highlighted.
- **Salary entries** — amount, paid date, period (monthly / biweekly / one-off), note.
- **Monthly dashboard** — income, repayment, net cash flow, per-platform totals.
- **Repayment calendar** — month grid with per-day income/repayment markers and tappable day details.
- **JSON / CSV backup** — full JSON export & import; CSV export of all three tables via the share sheet.
- **Real Liquid Glass UI** — uses iOS 26+ `.glassEffect()` natively.

## Privacy

Everything stays on your device. The app does not make a single network request. Vision OCR runs locally; backup files are produced on demand and shared through the standard iOS share sheet.

## Tech Stack

| Layer | Choice |
|------|------|
| Language | Swift 6 (strict concurrency) |
| UI | SwiftUI on iOS 26+ |
| Persistence | SwiftData (`@Model` + `@Query`) |
| OCR | Vision framework (`RecognizeTextRequest`, zh-Hans + en) |
| Photo input | PhotosUI `PhotosPicker` |
| Backup / share | `ShareLink` + `.fileImporter` |
| Project generation | XcodeGen (`project.yml`) |

## Requirements

- macOS 15+ with Xcode 17+ (Swift 6 toolchain)
- iOS 26+ device or simulator
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## Build & Run

```bash
# Generate the .xcodeproj from project.yml
xcodegen generate

# Open in Xcode
open CashFlows.xcodeproj

# Or build & run on simulator from CLI
xcodebuild \
  -project CashFlows.xcodeproj \
  -scheme CashFlows \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  build

# Install + launch on a booted simulator
APP=$(find ~/Library/Developer/Xcode/DerivedData/CashFlows-* -name "CashFlows.app" -path "*Debug-iphonesimulator*" | head -1)
xcrun simctl install booted "$APP"
xcrun simctl launch booted com.amigoer.cashflows
```

The `.xcodeproj` is generated; do not edit it directly. Make changes in `project.yml` and re-run `xcodegen generate`.

## Project Layout

```
CashFlows/
├── App/
│   ├── CashFlowsApp.swift           # @main, wires the SwiftData ModelContainer
│   └── RootView.swift               # 5-tab TabView
├── Components/                      # Reusable UI: GlassCard, AmountText, MonthSwitcher, etc.
├── Features/
│   ├── Dashboard/                   # Month switcher + income/repayment/net cards + platform totals
│   ├── Salary/                      # Salary list + add/edit form
│   ├── Debts/                       # Debt list, detail, add/edit form, repayment row
│   ├── Calendar/                    # Month grid with per-day markers
│   ├── Settings/                    # JSON / CSV export + JSON import
│   └── Import/                      # Screenshot OCR import flow
├── Lib/                             # Money formatting, date helpers
├── Models/                          # SwiftData @Model classes + enums
├── Services/
│   ├── OCRService.swift             # Vision wrapper
│   ├── RepaymentScheduler.swift     # Generates installment schedule
│   ├── ExportService.swift          # JSON / CSV codable round-trip
│   └── Parsers/                     # BillParser (heuristic) + DebtPlanDraft
└── Resources/                       # Info.plist, entitlements, Assets.xcassets
```

## Data Model

```
Salary
  amountCents      Int
  paidAt           Date
  period           monthly | biweekly | oneOff
  note             String?
  createdAt        Date

DebtPlan
  platform                String        // e.g. 花呗 / 京东白条 / 信用卡分期
  principalCents          Int
  totalPeriods            Int
  monthlyPaymentCents     Int
  firstDueDate            Date
  aprBps                  Int           // annual rate in basis points
  note                    String?
  archived                Bool
  createdAt               Date
  repayments              -> [Repayment]  (cascade delete)

Repayment
  periodIndex      Int
  dueDate          Date
  amountCents      Int
  status           pending | paid | overdue
  paidAt           Date?
```

All monetary values are stored as integer cents to avoid floating-point error.

## Roadmap

- Emergency-fund buffer alerts
- Early-repayment simulator
- Multiple accounts (salary card / repayment card)
- SQLCipher-style database encryption
- iCloud / system auto-backup
- Live screen-capture import (Screen Recording API)

## License

Personal use only. Not open-sourced.
