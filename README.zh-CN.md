# CashFlows

[English](./README.md) · **中文**

个人现金流管理 App，专注分期债务追踪和工资流水汇总。所有数据本地存储，不依赖任何云端服务。

## 背景

市面的记账类 App 大多偏「消费记录」，对「分期债务 + 多笔工资到账时间」这种现金流模型支持不好。本项目用来回答一个具体问题：

> 每个月工资到账后，扣除各分期平台的还款，到底还剩多少可支配资金？

CashFlows 就围绕这个问题构建。

## 功能（v0.1.0 已实现）

- [x] **工资明细录入**：金额、发放日期、发放周期（月薪 / 双周 / 一次性）、备注
- [x] **分期债务录入**：平台、本金、期数、月供、首期还款日、利率，**自动生成等额还款计划**
- [x] **还款日历**：按月展示每天的应还 / 应收金额，点选某日看明细
- [x] **仪表盘**：本月总收入、总还款、净现金流，各平台债务总览
- [x] **数据导出 / 导入**：JSON 全量备份 / 恢复，CSV 三表导出，走系统分享
- [x] **iOS Liquid Glass 卡片**（iOS 26+ 系统级毛玻璃），Android 自动降级到主题卡片
- [x] **中文 UI**，暗色 / 亮色模式跟随系统

## 后续规划（v0.2+）

- [ ] 应急资金缓冲提醒
- [ ] 提前还款模拟
- [ ] 多账户（工资卡 / 还款卡）支持
- [ ] 数据加密（SQLCipher）
- [ ] iCloud / 系统自动备份
- [ ] 鸿蒙（HarmonyOS）适配

## 技术栈

| 类别 | 选型 |
|------|------|
| 框架 | Expo SDK 56 + React Native 0.85（New Architecture） |
| 语言 | TypeScript 6 |
| 路由 | Expo Router 56（文件路由 + 原生 Tab） |
| 状态管理 | Zustand + TanStack Query |
| 本地数据库 | Drizzle ORM + expo-sqlite |
| UI | `expo-glass-effect`（Liquid Glass） + `expo-symbols`（SF / Material Symbols） |
| 日期 | date-fns（zh-CN locale） |
| 国际化 | i18next + expo-localization |
| 文件读写 | expo-file-system + expo-sharing |
| 构建 | EAS Build |
| 包管理 | pnpm |

### 为什么选 Expo（而不是 Flutter）

- 原生 UI 控件，iOS 26+ 自动获得真实的 `UIVisualEffectView` Liquid Glass，无需手动模拟
- New Architecture (Fabric + TurboModules) 下性能接近原生
- 文件路由清晰；EAS Build 不依赖本地完整 Xcode 链就能打 iOS IPA
- TypeScript 全栈类型安全，Drizzle 提供类型安全 SQL

### 为什么纯本地存储

财务数据敏感，不上传任何第三方服务器。备份由用户主动通过导出文件 + 系统分享完成。

## 目标平台

- iOS 15.1+（Liquid Glass 在 iOS 26+ 自动启用，更早版本降级为普通毛玻璃）
- Android 8.0+ (API 26+)
- HarmonyOS（未来规划）

## 项目结构

```
cashflows/
├── src/
│   ├── app/                       # Expo Router 文件路由
│   │   ├── _layout.tsx            # 根布局（Provider、主题、迁移）
│   │   ├── (tabs)/                # 底部 5 个 Tab
│   │   │   ├── _layout.tsx
│   │   │   ├── index.tsx          # 仪表盘
│   │   │   ├── salary.tsx         # 工资列表
│   │   │   ├── debts.tsx          # 债务列表
│   │   │   ├── calendar.tsx       # 还款日历
│   │   │   └── settings.tsx       # 设置
│   │   ├── salary/                # 工资新增 / 编辑（模态）
│   │   └── debts/                 # 债务新增 / 详情 / 编辑
│   ├── db/                        # Drizzle schema + 客户端 + 生成的迁移
│   ├── features/                  # 业务模块（hooks、表单、行组件）
│   │   ├── salary/
│   │   ├── debts/
│   │   ├── calendar/
│   │   ├── dashboard/
│   │   └── settings/
│   ├── components/                # 通用 UI（GlassCard、AmountText、FAB、表单输入）
│   ├── lib/                       # 工具函数（money、date）
│   ├── providers/                 # AppProviders（i18n、Query、主题、迁移闸门）
│   ├── i18n/                      # 翻译文件（zh-CN）
│   ├── constants/                 # 颜色 / 间距 / 字体
│   ├── hooks/                     # use-theme、use-color-scheme
│   └── types/                     # 全局类型声明（css、sql）
├── assets/images/                 # 应用图标 / Splash
├── app.json
├── eas.json
├── babel.config.js
├── drizzle.config.ts
├── eslint.config.js
├── metro.config.js
├── package.json
└── tsconfig.json
```

## 开发环境

### 依赖

- Node.js 20+（推荐 22 LTS）
- pnpm 9+
- 调试 Android：Android Studio + Android SDK 34+
- 调试 iOS（可选）：Xcode 16+

### 安装

```bash
pnpm install
```

### 运行

```bash
pnpm start           # 启动 Metro，按 a / i / w 选择平台
pnpm android         # 直接打开 Android 模拟器
pnpm ios             # 直接打开 iOS 模拟器（需 Xcode）
pnpm web             # 浏览器预览（部分原生组件会降级）
```

> 首次跑真机或要用 Liquid Glass 等原生模块时，需要构建一次开发版客户端：
> `pnpm dlx eas build --profile development --platform android`

### 数据库迁移

Schema 在 [src/db/schema.ts](src/db/schema.ts)。改完执行：

```bash
pnpm db:generate     # 生成新的 SQL 迁移到 src/db/drizzle/
```

App 启动时由 `useMigrations` hook 自动应用所有未执行的迁移（见 [providers/app-providers.tsx](src/providers/app-providers.tsx)）。

### 代码质量

```bash
pnpm typecheck       # TS 类型检查
pnpm lint            # ESLint
pnpm format          # Prettier
```

## 打包发布

### Android APK（推荐用 EAS Build）

```bash
pnpm dlx eas login
pnpm dlx eas build --profile preview --platform android
```

构建完成后从 Expo Dashboard 下载 APK 装机即可。

### iOS

```bash
pnpm dlx eas build --profile preview --platform ios
```

需要先用 `eas credentials` 配置 Apple Developer 证书。

## 数据模型

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
  platform                 text                    // 花呗 / 京东白条 / 信用卡分期 ...
  principal_cents          integer
  total_periods            integer
  monthly_payment_cents    integer
  first_due_date           integer (epoch ms)
  apr_bps                  integer                 // 年化利率，万分比
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

金额一律以「分」为单位的整数存储，避免浮点误差。

## License

仅供个人使用，未开源许可。
