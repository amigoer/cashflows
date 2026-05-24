# CashFlows

**English** · [中文](./README.zh-CN.md)

A personal cash flow tracker for installment debts and salary. All data stays on your device — no cloud, no telemetry.

## Why

Most consumer finance apps focus on expense tracking. They don't fit the cash flow model where you need to answer one specific question:

> After my salary lands and I deduct every installment platform's monthly payment, how much spendable cash do I actually have left this month?

CashFlows is built around that question.

## Features (v0.1.0)

- [x] **Salary entries** — amount, paid date, period (monthly / biweekly / one-off), note
- [x] **Installment debts** — platform, principal, total periods, monthly payment, first due date, APR; **repayment schedule generated automatically**
- [x] **Repayment calendar** — month grid with per-day income/repayment dots, tap a day for details
- [x] **Dashboard** — this month's income, repayment, net cash flow; per-platform debt overview
- [x] **Backup & restore** — JSON full export / import, CSV three-table export, system share sheet
- [x] **iOS Liquid Glass cards** (iOS 26+) with automatic fallback on Android
- [x] **Dark / light mode** following system, Chinese UI

## Roadmap (v0.2+)

- [ ] Emergency-fund buffer alerts
- [ ] Early-repayment simulator
- [ ] Multiple accounts (salary card / repayment card)
- [ ] Database encryption (SQLCipher)
- [ ] iCloud / system auto-backup
- [ ] HarmonyOS support

## Tech Stack

| Layer | Choice |
|------|------|
| Framework | Expo SDK 56 + React Native 0.85 (New Architecture) |
| Language | TypeScript 6 |
| Routing | Expo Router 56 (file-based + native tabs) |
| State | Zustand + TanStack Query |
| Local DB | Drizzle ORM + expo-sqlite |
| UI | `expo-glass-effect` (Liquid Glass) + `expo-symbols` (SF / Material Symbols) |
| Date | date-fns (zh-CN locale) |
| i18n | i18next + expo-localization |
| File I/O | expo-file-system + expo-sharing |
| Build | EAS Build |
| Package manager | pnpm |

### Why Expo (not Flutter)

- Native UI primitives — iOS 26+ apps automatically get real `UIVisualEffectView` Liquid Glass, no manual simulation
- New Architecture (Fabric + TurboModules) brings near-native performance
- File-based routing is straightforward; EAS Build produces iOS IPAs without a local Xcode install
- End-to-end type safety with TypeScript and Drizzle's type-safe SQL

### Why local-only storage

Financial data is sensitive. Nothing is uploaded to any third-party server. Backups are user-initiated through file export and the system share sheet.

## Target Platforms

- iOS 15.1+ (Liquid Glass automatically enabled on iOS 26+, gracefully falls back to a regular frosted surface on older versions)
- Android 8.0+ (API 26+)
- HarmonyOS (planned)

## Project Layout

```
cashflows/
├── src/
│   ├── app/                       # Expo Router file routes
│   │   ├── _layout.tsx            # Root layout (providers, theme, DB migrations)
│   │   ├── (tabs)/                # Bottom tab bar
│   │   │   ├── _layout.tsx
│   │   │   ├── index.tsx          # Dashboard
│   │   │   ├── salary.tsx         # Salary list
│   │   │   ├── debts.tsx          # Debts list
│   │   │   ├── calendar.tsx       # Calendar
│   │   │   └── settings.tsx       # Settings
│   │   ├── salary/                # Salary new / edit modals
│   │   └── debts/                 # Debts new / detail / edit
│   ├── db/                        # Drizzle schema, client, generated migrations
│   ├── features/                  # Domain modules (hooks, forms, row components)
│   │   ├── salary/
│   │   ├── debts/
│   │   ├── calendar/
│   │   ├── dashboard/
│   │   └── settings/
│   ├── components/                # Generic UI (GlassCard, AmountText, FAB, form inputs)
│   ├── lib/                       # Pure utilities (money, date)
│   ├── providers/                 # AppProviders (i18n, Query, theme, migration gate)
│   ├── i18n/                      # Translations (zh-CN)
│   ├── constants/                 # Colors, spacing, fonts
│   ├── hooks/                     # use-theme, use-color-scheme
│   └── types/                     # Ambient declarations (css, sql)
├── assets/images/                 # App icon, splash
├── app.json
├── eas.json
├── babel.config.js
├── drizzle.config.ts
├── eslint.config.js
├── metro.config.js
├── package.json
└── tsconfig.json
```

## Development

### Requirements

- Node.js 20+ (22 LTS recommended)
- pnpm 9+
- For Android dev: Android Studio + Android SDK 34+
- For iOS dev (optional): Xcode 16+

### Install

```bash
pnpm install
```

### Run

```bash
pnpm start           # Start Metro, then press a / i / w to pick a platform
pnpm android         # Open in Android emulator/device directly
pnpm ios             # Open in iOS simulator (needs Xcode)
pnpm web             # Browser preview (some native pieces degrade)
```

> For physical devices or to test Liquid Glass + other native modules, build a dev client once:
> `pnpm dlx eas build --profile development --platform android`

### Database Migrations

The schema lives in [src/db/schema.ts](src/db/schema.ts). After editing it:

```bash
pnpm db:generate     # Generate a new SQL migration under src/db/drizzle/
```

The `useMigrations` hook applies pending migrations on app startup (see [providers/app-providers.tsx](src/providers/app-providers.tsx)).

### Code Quality

```bash
pnpm typecheck       # TypeScript
pnpm lint            # ESLint
pnpm format          # Prettier
```

## Building Release Artifacts

### Android APK (via EAS Build)

```bash
pnpm dlx eas login
pnpm dlx eas build --profile preview --platform android
```

When the build finishes, download the APK from the Expo dashboard and sideload it.

### iOS

```bash
pnpm dlx eas build --profile preview --platform ios
```

Run `eas credentials` first to set up your Apple Developer signing keys.

## Data Model

```ts
salaries
  id              integer (pk, auto)
  amount_cents    integer
  paid_at         integer (epoch ms)
  period          'monthly' | 'biweekly' | 'one_off'
  note            text?
  created_at      integer

debt_plans
  id                       integer (pk, auto)
  platform                 text                    // e.g. Huabei / JD Baitiao / credit-card installment
  principal_cents          integer
  total_periods            integer
  monthly_payment_cents    integer
  first_due_date           integer (epoch ms)
  apr_bps                  integer                 // annual percentage rate, basis points
  note                     text?
  archived                 boolean
  created_at               integer

repayments
  id              integer (pk, auto)
  debt_plan_id    integer (fk → debt_plans, cascade delete)
  period_index    integer
  due_date        integer (epoch ms)
  amount_cents    integer
  status          'pending' | 'paid' | 'overdue'
  paid_at         integer?
```

All monetary values are stored as integer cents to avoid floating-point error.

## License

Personal use only. Not open-sourced.
