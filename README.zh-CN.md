# CashFlows

[English](./README.md) · **中文**

原生 iOS 现金流管理 App，专注分期债务追踪和工资流水汇总。**上传账单截图自动识别，不用手动录入**。所有数据本地存储，零云端。

## 背景

市面记账类 App 大多偏「消费记录」，对「分期债务 + 多笔工资到账时间」的现金流模型支持差。本项目要回答一个具体问题：

> 每个月工资到账后，扣除各分期平台的还款，到底还剩多少可支配资金？

手动录入数据是任何记账工具的最大门槛。CashFlows 用 Apple Vision 在本地做 OCR，你上传花呗 / 京东白条 / 信用卡分期账单截图，平台名、本金、期数、月供、首期还款日自动填好。

## 功能

- **截图识别**：Apple Vision 文字识别 + 平台特化解析器（花呗 / 京东白条 / 信用卡分期），完全本地运行
- **手动兜底**：每个字段都可以手动录入或修改
- **自动生成还款计划**：新增分期时按月自动生成全部期次
- **标记已还**：点任意一期切换已还/待还状态，逾期项目自动高亮
- **工资明细**：金额、到账日期、周期（每月 / 每两周 / 一次性）、备注
- **月度仪表盘**：本月收入、还款、净现金流，各平台债务汇总
- **还款日历**：月视图，每日标记收入/还款，点击查看详情
- **JSON / CSV 备份**：JSON 全量导出/导入；CSV 三张表导出，通过系统分享面板
- **真正的 Liquid Glass**：使用 iOS 26+ 系统级 `.glassEffect()`

## 隐私

所有数据存在你的设备本地。App 不发起任何网络请求。Vision OCR 完全本地运行，备份文件按需生成并通过系统分享面板发送。

## 技术栈

| 层 | 选型 |
|------|------|
| 语言 | Swift 6（strict concurrency） |
| UI | SwiftUI（iOS 26+） |
| 持久化 | SwiftData（`@Model` + `@Query`） |
| OCR | Vision 框架（`RecognizeTextRequest`，zh-Hans + en） |
| 图片选择 | PhotosUI `PhotosPicker` |
| 备份/分享 | `ShareLink` + `.fileImporter` |
| 项目生成 | XcodeGen（`project.yml`） |

## 环境要求

- macOS 15+，Xcode 17+（带 Swift 6 工具链）
- iOS 26+ 真机或模拟器
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)：`brew install xcodegen`

## 构建运行

```bash
# 从 project.yml 生成 .xcodeproj
xcodegen generate

# 在 Xcode 中打开
open CashFlows.xcodeproj

# 或者用命令行构建运行
xcodebuild \
  -project CashFlows.xcodeproj \
  -scheme CashFlows \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  build

# 装到已经启动的模拟器并打开
APP=$(find ~/Library/Developer/Xcode/DerivedData/CashFlows-* -name "CashFlows.app" -path "*Debug-iphonesimulator*" | head -1)
xcrun simctl install booted "$APP"
xcrun simctl launch booted com.amigoer.cashflows
```

`.xcodeproj` 是生成出来的，不要直接改。改动写在 `project.yml`，再 `xcodegen generate` 重新生成。

## 项目结构

```
CashFlows/
├── App/
│   ├── CashFlowsApp.swift           # @main 入口，注入 SwiftData ModelContainer
│   └── RootView.swift               # 底部 5 个 Tab
├── Components/                      # 通用 UI：GlassCard、AmountText、MonthSwitcher 等
├── Features/
│   ├── Dashboard/                   # 月份切换 + 收入/还款/净流入卡片 + 平台汇总
│   ├── Salary/                      # 工资列表 + 新增/编辑表单
│   ├── Debts/                       # 债务列表、详情、新增/编辑表单、还款行
│   ├── Calendar/                    # 月历视图，每日标记
│   ├── Settings/                    # JSON / CSV 导出 + JSON 导入
│   └── Import/                      # 截图 OCR 导入流程
├── Lib/                             # 金额格式化、日期工具
├── Models/                          # SwiftData @Model 类 + 枚举
├── Services/
│   ├── OCRService.swift             # Vision 封装
│   ├── RepaymentScheduler.swift     # 生成还款计划
│   ├── ExportService.swift          # JSON / CSV 编解码
│   └── Parsers/                     # BillParser（启发式）+ DebtPlanDraft
└── Resources/                       # Info.plist、entitlements、Assets.xcassets
```

## 数据模型

```
Salary
  amountCents      Int
  paidAt           Date
  period           monthly | biweekly | oneOff
  note             String?
  createdAt        Date

DebtPlan
  platform                String        // 花呗 / 京东白条 / 信用卡分期 ...
  principalCents          Int
  totalPeriods            Int
  monthlyPaymentCents     Int
  firstDueDate            Date
  aprBps                  Int           // 年化利率，万分比
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

金额一律以「分」为单位的整数存储，避免浮点误差。

## 后续规划

- 应急资金缓冲提醒
- 提前还款模拟
- 多账户（工资卡 / 还款卡）支持
- 数据库加密（SQLCipher 之类）
- iCloud / 系统自动备份
- 屏幕录制实时识别

## License

仅供个人使用，未开源许可。
