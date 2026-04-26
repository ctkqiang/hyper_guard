# HyperGuard 澎湃盾

> **HyperOS 专属蜜罐沙盒安全系统**  
> Xiaomi | Redmi | POCO | BlackShark — HyperOS 1.0 / 2.0 / 3.0 / 4.0

---

## 1. 项目概述

HyperGuard（澎湃盾）是一款专为小米 HyperOS 生态设计的系统级安全工具，对标 Google Play Protect 的运行时威胁检测机制，在应用安装与执行的全链路中构建多层纵深防御体系。其核心能力是在不依赖 Root 权限、不破坏系统完整性的前提下，通过安装拦截钩子 + 蜜罐沙盒虚拟化 + 实时行为审计三重防护，为用户提供对诈骗 APK、隐私窃取类恶意软件的主动免疫能力。

**设计哲学**：将移动安全从"被动查杀"转向"主动诱捕"。传统杀毒软件依赖签名库匹配（Signature-based Detection），对零日攻击和混淆变种无能为力。HyperGuard 采用蜜罐欺骗（Honeypot Deception）策略——让恶意应用在虚拟化环境中"自由活动"，暴露其真实意图，同时用户真实数据完全隔离。

### 1.1 威胁模型

HyperGuard 的威胁模型基于以下假设：

- **攻击者模型**：攻击者能够构造伪装成合法应用的 APK 文件，绕过 Google Play 和 MIUI 应用商店的审核机制
- **攻击向量**：社交工程诱导用户侧载（Sideload）APK；第三方应用商店分发恶意载荷
- **攻击目标**：通讯录、短信、通话记录、GPS 位置、IMEI/IMSI 设备标识、相册媒体文件
- **防御前提**：HyperOS 设备无需解锁 Bootloader 或获取 Root 权限；系统级 API 可被合法调用

### 1.2 数学基础

本系统的威胁评分模型基于加权多因素分析（Weighted Multi-Factor Analysis）。对于沙盒内捕获的 APK 应用 \( A \)，定义其威胁评分函数：

\[
S(A) = \min\left(100,\ \sum*{p \in P(A)} w(p) + \alpha \cdot N*{net} + \beta \cdot N\_{block}\right)
\]

其中：

- \( P(A) \) 为 APK 请求的权限集合
- \( w(p) \) 为权限 \( p \) 的风险权重函数，定义如下：

\[
w(p) = \begin{cases}
25 & \text{if } p \in \{\text{SMS, CONTACTS, CALL_LOG}\} \\
15 & \text{if } p \in \{\text{CAMERA, MICROPHONE, LOCATION}\} \\
10 & \text{if } p \in \{\text{STORAGE, PHONE_STATE}\} \\
5 & \text{otherwise}
\end{cases}
\]

- \( \alpha = 3 \) 为网络活动权重系数
- \( \beta = 15 \) 为拦截操作权重系数
- \( N*{net}, N*{block} \) 分别为网络请求数量和拦截操作数量

威胁分级依据威胁评分 \( S(A) \) 映射到四级标注：

\[
\text{Level}(A) = \begin{cases}
\text{SAFE} & S(A) \in [0, 20) \\
\text{SUSPICIOUS} & S(A) \in [20, 40) \\
\text{DANGEROUS} & S(A) \in [40, 70) \\
\text{MALICIOUS} & S(A) \in [70, 100]
\end{cases}
\]

### 1.3 蜜罐理论基础

蜜罐（Honeypot）技术源于网络安全领域的入侵检测理论，由 Lance Spitzner 在 1999 年系统化提出。其核心思想是**欺骗与诱捕**（Deception & Entrapment）：构造一个看似真实但完全受控的虚拟环境，诱使攻击者在其中暴露行为模式，同时完全隔离真实资产。

在本系统中，蜜罐技术的移动化适配面临三个核心挑战：

1. **数据源欺骗**：Android 系统通过 ContentProvider、SystemService 等机制向应用提供数据。沙盒必须拦截这些调用并返回伪造数据。
2. **进程级隔离**：被分析 APK 不得感知自身处于沙盒环境，否则会改变行为模式。
3. **行为可观测性**：所有系统调用、权限请求、网络连接必须在沙盒边界被记录和分析。

---

## 2. 系统架构

HyperGuard 采用四层 MVVM 架构，自底向上分为 Native Layer → Service Layer → Domain/BLoC Layer → Presentation Layer。

```
┌─────────────────────────────────────────────────────────┐
│                Presentation Layer                       │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │  Splash  │ │   Home   │ │ Sandbox  │ │  Report  │  │
│  │  Screen  │ │  Screen  │ │  Screen  │ │  Screen  │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘  │
│         ▲            ▲            ▲           ▲        │
│         │ ThemeColors (context-aware light/dark)       │
├─────────────────────────────────────────────────────────┤
│                BLoC State Management                   │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │ ThemeBloc│ │DeviceBloc│ │SandboxBloc│ │ReportBloc│  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘  │
├─────────────────────────────────────────────────────────┤
│                Service / Data Layer                    │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐              │
│  │  Device  │ │ Sandbox  │ │ Monitor  │              │
│  │ Service  │ │ Service  │ │ Service  │              │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘              │
│       │ MethodChannel Flutter ↔ Android (Kotlin)      │
├───────┼──────────────┼──────────────┼─────────────────┤
│       ▼              ▼              ▼                  │
│  ┌──────────────────────────────────────────────────┐  │
│  │          Android Native Layer (Kotlin)           │  │
│  │  ┌───────────┐ ┌────────────┐ ┌──────────────┐  │  │
│  │  │DeviceUtil │ │Interceptor │ │ ApkAnalyzer   │  │  │
│  │  │.kt        │ │.kt         │ │ HMAC-SHA256   │  │  │
│  │  └───────────┘ └────────────┘ └──────────────┘  │  │
│  └──────────────────────────────────────────────────┘  │
│       │              │              │                  │
│       ▼              ▼              ▼                  │
│  ┌──────────────────────────────────────────────────┐  │
│  │         C++ / NDK Sandbox Engine                 │  │
│  │  ┌──────────┐ ┌────────────┐ ┌───────────────┐  │  │
│  │  │sandbox_  │ │fake_data_  │ │behavior_      │  │  │
│  │  │core.cpp  │ │provider.cpp│ │monitor.cpp    │  │  │
│  │  └──────────┘ └────────────┘ └───────────────┘  │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 2.1 Flutter 端 (Dart)

| 模块       | 文件                               | 职责                                                                                           |
| ---------- | ---------------------------------- | ---------------------------------------------------------------------------------------------- |
| 主题引擎   | `core/theme/app_theme.dart`        | Material 3 亮/暗双色主题，Slate + Blue 色彩体系，完整 Typography 规范                          |
| 上下文颜色 | `core/theme/theme_colors.dart`     | 基于 Brightness 的运行时颜色解析器，避免硬编码颜色值                                           |
| 数据模型   | `data/models/sandbox_app.dart`     | 沙盒应用实体，Equatable + copyWith + JSON 序列化，通用时间戳解析                               |
| 数据模型   | `data/models/security_report.dart` | 安全报告实体，含 PermissionAttempt / NetworkActivity / BehaviorEvent 子模型                    |
| BLoC       | `presentation/bloc/device/`        | 设备验证状态机 (initial → checking → compatible / incompatible / error)                        |
| BLoC       | `presentation/bloc/sandbox/`       | 沙盒生命周期状态机，含实时事件流订阅                                                           |
| BLoC       | `presentation/bloc/report/`        | 报告 CRUD 状态机                                                                               |
| BLoC       | `presentation/bloc/theme/`         | 主题模式状态机 (system / light / dark)                                                         |
| 服务层     | `services/device_service.dart`     | 设备检测 MethodChannel                                                                         |
| 服务层     | `services/sandbox_service.dart`    | 沙盒管理 MethodChannel + 实时事件监听 (BehaviorEvent/NetworkActivity/PermissionAttempt Stream) |
| 服务层     | `services/monitor_service.dart`    | 行为审计 MethodChannel                                                                         |

### 2.2 Android 原生层 (Kotlin)

| 模块                    | 职责                                                                               |
| ----------------------- | ---------------------------------------------------------------------------------- |
| `DeviceUtil.kt`         | 小米/红米设备验证，HyperOS 版本检测（三层回退机制），设备指纹采集                  |
| `InstallInterceptor.kt` | 系统安装拦截器，高优先级 BroadcastReceiver，四级风险校验引擎，HMAC-SHA256 审计日志 |
| `MainActivity.kt`       | FlutterActivity 入口，三通道 MethodChannel 处理，沙盒会话管理，APK 解析，威胁评分  |
| `HyperGuardService.kt`  | 前台服务，持续防护守护进程                                                         |
| `HyperGuardNative.kt`   | JNI 桥接层，Kotlin ↔ C++ 双向调用                                                  |
| `ApkAnalyzer`           | PackageManager 真实 APK 解析，提取包名/权限/版本信息                               |

### 2.3 C++/NDK 沙盒引擎

| 模块                       | 职责                                                              |
| -------------------------- | ----------------------------------------------------------------- |
| `sandbox_core.h/cpp`       | 会话管理、环境初始化、进程隔离、威胁评分算法                      |
| `fake_data_provider.h/cpp` | 全伪造数据生成引擎 (IMEI/AndroidID/MAC/位置/通讯录/短信/文件系统) |
| `behavior_monitor.h/cpp`   | 行为监控引擎，权限请求/网络活动/敏感操作实时拦截                  |
| `jni_bridge.cpp`           | JNI 桥接，Java/Kotlin ↔ C++ 双向通信                              |

---

## 3. 核心功能详细设计

### 3.1 系统级安装拦截

**实现原理**：

Android 系统的包管理流程涉及多个系统组件（PackageManagerService → PackageInstallerActivity → InstallAppProgress）。HyperGuard 在 AndroidManifest.xml 中声明了两个高优先级（`android:priority="999"`）IntentFilter：

```xml
<!-- 拦截 APK 文件打开意图 -->
<intent-filter android:priority="999">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <data android:mimeType="application/vnd.android.package-archive" />
</intent-filter>

<!-- 拦截系统安装包事件 -->
<intent-filter android:priority="999">
    <action android:name="android.intent.action.INSTALL_PACKAGE" />
    <data android:scheme="package" />
</intent-filter>
```

同时注册独立 `BroadcastReceiver` 组件监听 `PACKAGE_ADDED` 和 `PACKAGE_INSTALL` 系统广播，秒级响应安装行为。用户可选择：

- **蜜罐安全安装**：APK 进入沙盒虚拟环境运行，所有数据源被伪造
- **正常安装**：高风险应用强制二次确认，审计日志全程记录
- **取消**：终止当前安装流程

**安全验证流水线**：

```
APK 路径输入
  → ApkAnalyzer.analyze() PackageManager.getPackageArchiveInfo() 真实解析
  → 提取 PackageName / AppName / VersionName / Permissions
  → validateApk() 权限风险评估
     ├── 遍历 requestedPermissions
     ├── 匹配 9 类危险权限 (SMS/CONTACTS/CALL_LOG/CAMERA/MICROPHONE/LOCATION/PHONE/STORAGE/INSTALL_PACKAGES)
     ├── 计算 sensitiveCount
     └── 输出 RiskLevel (LOW / MEDIUM / HIGH / CRITICAL)
  → InstallInterceptor.showInstallDialog() 显示风险评估结果
  → 用户决策 → 审计日志写入 install_audit.log
```

### 3.2 蜜罐沙盒虚拟化

**核心设计**：

沙盒的核心思想是进程级数据隔离与数据源欺骗。在 Android 系统中，应用通过系统服务（SystemService）和内容提供者（ContentProvider）获取设备数据。沙盒在以下维度实现数据隔离：

**假数据供给矩阵**：

| 数据类型    | 真实来源                          | 沙盒伪造值                      | 实现方式        |
| ----------- | --------------------------------- | ------------------------------- | --------------- |
| IMEI        | TelephonyManager.getDeviceId()    | `000000000000000`               | 返回零值数组    |
| Android ID  | Settings.Secure.ANDROID_ID        | 沙盒会话 ID 派生                | UUID → HEX 截断 |
| MAC Address | WifiInfo.getMacAddress()          | `02:00:00:00:00:00`             | 本地管理地址    |
| 电话号码    | TelephonyManager.getLine1Number() | `00000000000`                   | 零值字符串      |
| GPS 位置    | LocationManager                   | (0.0, 0.0)                      | 赤道原点        |
| 通讯录      | ContactsContract                  | 空数组 `[]`                     | 返回零条记录    |
| 短信        | Telephony.Sms                     | 空数组 `[]`                     | 返回零条记录    |
| 文件系统    | File API                          | 空目录 + .hyperguard_guard 标记 | 预生成空目录树  |
| 相册        | MediaStore                        | 空数组 `[]`                     | 返回零条媒体    |
| 设备型号    | Build.MODEL                       | 真实设备型号                    | 保留以免检测    |

每个沙盒会话在 `hyperguard_sandbox/sessions/{appId}/` 下拥有独立的文件系统空间和伪造数据配置文件 `sandbox_profile.json`。

### 3.3 行为审计与分析

**监控维度**：

| 维度     | 监控目标                          | 实现机制                             |
| -------- | --------------------------------- | ------------------------------------ |
| 权限请求 | APP 尝试获取的 Android 权限列表   | PackageManager 静态分析 + 运行时标记 |
| 网络活动 | HTTP/HTTPS 连接目标、方法、状态码 | 网络日志记录                         |
| 敏感行为 | 读取通讯录/短信/GPS/相册的尝试    | 行为事件标记 + 实时推流              |
| 拦截操作 | 被沙盒阻断的敏感操作计数          | 原子计数器 increment                 |

**实时事件流架构**：

```
Native Layer (Kotlin)
  → sendBehaviorEvent()
  → MethodChannel(CHANNEL_SANDBOX).invokeMethod("onBehaviorEvent", data)
  → SandboxService._behaviorStreamController.add(BehaviorEvent)
  → SandboxBloc._onBehavior()
  → BlocBuilder<SandboxBloc, SandboxState> UI 实时更新
```

---

## 4. 技术实现细节

### 4.1 HyperOS 版本检测算法

`DeviceUtil.kt` 实现三层回退检测策略，确保覆盖 HyperOS 1.0 至 4.0 全版本：

**Layer 1 — miui.os.Build 反射**：

```kotlin
Class.forName("miui.os.Build").getField("IS_HYPER_OS").getBoolean(null)
```

这是 HyperOS 官方 SDK 的标准检测方式，优先级最高。

**Layer 2 — SystemProperties 反射**：

```kotlin
Class.forName("android.os.SystemProperties")
    .getMethod("get", String::class.java, String::class.java)
    .invoke(null, "ro.miui.ui.version.name", "")
```

读取系统属性 `ro.miui.ui.version.name`。HyperOS 版本命名规则为 `OS{MAJOR}.{MINOR}.{PATCH}.{BUILD}`（例如 `OS3.0.1.0`），通过解析 `OS` 前缀判定。

**Layer 3 — Build Fingerprint 回退**：

```kotlin
Build.FINGERPRINT.lowercase().contains("os3")
```

在极端情况下（如某些 HyperOS 内测版本），前两层可能失效，此时通过构建指纹中的版本号标记（os2/os3/os4）作为兜底。

**版本号格式化**：

```
OS3.0.1.0 → 3.0
OS2.0.3.0 → 2.0
OS1.0.508.0 → 1.0
```

### 4.2 安装拦截的竞态条件处理

Android 安装流程是异步多组件的，存在 PackageManager 回调时机不确定的问题。HyperGuard 通过以下机制保证拦截的可靠性和原子性：

1. **双通道监听**：同时注册 IntentFilter 和 BroadcastReceiver，确保无论安装触发路径（文件管理器 / 浏览器 / ADB / 第三方市场）都能被拦截
2. **优先级抢占**：`priority="999"` 确保 HyperGuard 在所有同类型接收器中最先获得处理权
3. **pendingApkPath 状态保持**：在弹窗期间通过成员变量保持待安装 APK 路径引用，防止系统回收

### 4.3 APK 解析的真实化实现

`ApkAnalyzer.analyze()` 通过 Android 原生 `PackageManager.getPackageArchiveInfo()` API 实现对 APK 文件的真实解析，提取以下元数据：

- `packageName`：应用唯一标识
- `appName`：通过 `ApplicationInfo.loadLabel()` 获取本地化应用名
- `versionName`：版本字符串
- `requestedPermissions`：AndroidManifest 中声明的权限列表（`PackageManager.GET_PERMISSIONS` 标志）
- `sizeBytes`：APK 文件的物理大小

这是与概念验证级项目（PoC）的本质区别——HyperGuard 不设置模拟路径或固定返回值，而是调用真实系统 API 获取精确数据。

### 4.4 审计日志系统

所有安装拦截事件通过 HMAC 追加式日志写入 `hyperguard_sandbox/audit/install_audit.log`，格式如下：

```
[2026-04-26 21:04:05.123] InstallInterceptor registered
[2026-04-26 21:04:10.456] VALIDATION package=com.freeturn.app risk=MEDIUM issues=3
[2026-04-26 21:04:10.789] INSTALL_DIALOG_SHOWN package=com.freeturn.app risk=MEDIUM
[2026-04-26 21:04:15.012] ACTION selected=SANDBOX package=com.freeturn.app risk=MEDIUM
```

每条日志包含毫秒级时间戳、操作类型、关键参数，支持后期合规审计和安全事件溯源。

---

## 5. 状态管理与数据流

### 5.1 BLoC 状态机

项目使用 `flutter_bloc` 实现严格的单向数据流。四个 BLoC 分别管理独立的关注域：

**DeviceBloc 状态转换图**：

```
initial → checking → compatible    (通行)
                   → incompatible  (拦截)
                   → error         (网络/权限异常)
```

**SandboxBloc 状态转换图**：

```
idle → initializing → ready → installing → ready
                              → running   → stopping → ready
                              → error
```

**ReportBloc 状态转换图**：

```
initial → loading → loaded → exporting → loaded
                         → deleting  → loaded
                         → error
```

**ThemeBloc 状态转换图**：

```
system ←→ light
       ←→ dark
```

### 5.2 事件流架构

沙盒行为监控采用事件驱动架构（Event-Driven Architecture），利用 Dart Stream 实现实时数据推送：

```
Native C++ Monitor
  → JNI callback → Kotlin Handler
  → MethodChannel.invokeMethod("onBehaviorEvent", Map)
  → SandboxService._behaviorStreamController (StreamController.broadcast)
  → SandboxBloc BehaviorEventReceived
  → BlocBuilder 自动重建 Widget
```

---

## 6. UI/UX 设计规范

### 6.1 色彩系统

| Token           | 暗色模式              | 亮色模式              | 用途                        |
| --------------- | --------------------- | --------------------- | --------------------------- |
| `background`    | `#020617`             | `#F8FAFC`             | 脚手架背景                  |
| `surface`       | `#0F172A`             | `#FFFFFF`             | AppBar / NavigationBar 背景 |
| `card`          | `#1A2332`             | `#FFFFFF`             | 卡片容器                    |
| `cardBorder`    | `#334155`             | `#E2E8F0`             | 卡片描边                    |
| `textPrimary`   | `#F1F5F9`             | `#0F172A`             | 主要文字                    |
| `textSecondary` | `#94A3B8`             | `#64748B`             | 辅助文字                    |
| `brand`         | `#60A5FA` / `#2563EB` | `#60A5FA` / `#2563EB` | 品牌色（渐变）              |
| `danger`        | `#F43F5E`             | `#F43F5E`             | 危险/恶意                   |
| `warning`       | `#F59E0B`             | `#F59E0B`             | 警告/可疑                   |
| `success`       | `#10B981`             | `#10B981`             | 安全/成功                   |

### 6.2 主题切换机制

基于 BLoC 的三态主题切换：

- **跟随系统**（`ThemeMode.system`）：默认模式，通过 `WidgetsBinding.instance.platformDispatcher.platformBrightness` 实时获取系统设置
- **浅色模式**（`ThemeMode.light`）：强制亮色
- **深色模式**（`ThemeMode.dark`）：强制暗色

系统导航栏颜色通过 `AnnotatedRegion<SystemUiOverlayStyle>` 与当前主题背景色（`slate900` / `slate50`）动态绑定，实现导航栏与应用界面的无缝视觉融合。

### 6.3 页面结构

```
SplashScreen         设备验证 → 版本检测 → 沙盒初始化
    ↓
HomeScreen (IndexedStack 4-Tab)
    ├── Tab 0: 仪表盘 (状态卡片 + 快捷操作 + 活跃沙盒 + 近期威胁)
    ├── Tab 1: 蜜罐沙盒 (APK 列表 + 点击进入模拟器监控面板)
    ├── Tab 2: 安全报告 (报告列表 + 详情页图表)
    └── Tab 3: 防护设置 (主题切换 + 关于信息)
```

---

## 7. 安全机制

### 7.1 纵深防御层次

| 层级          | 机制                             | 说明                                              |
| ------------- | -------------------------------- | ------------------------------------------------- |
| L1 - 设备准入 | Xiaomi Hardware Feature Check    | `uses-feature com.xiaomi.hardware: required=true` |
| L2 - 系统准入 | HyperOS 版本验证                 | 三层回退检测，禁止非 HyperOS 系统运行             |
| L3 - 安装拦截 | IntentFilter + BroadcastReceiver | priority=999 抢占系统安装流程                     |
| L4 - 安全校验 | APK 权限分析引擎                 | 9 类危险权限匹配 + 风险等级评估                   |
| L5 - 环境隔离 | 蜜罐沙盒虚拟化                   | 全伪造数据环境，零真实数据暴露                    |
| L6 - 行为监控 | 实时事件流                       | 权限请求 / 网络活动 / 敏感操作实时追踪            |
| L7 - 审计留痕 | 毫秒级审计日志                   | 所有决策事件完整记录，支持合规审计                |

### 7.2 权限最小化原则

虽然 HyperGuard 声明了多项权限以支持安全分析，但所有权限的使用严格限定在安全分析上下文中，用户的个人数据绝不会被上传或泄露。应用本身不请求任何第三方网络连接（`network_security_config.xml` 仅信任系统证书锚点）。

---

## 8. 构建与部署

### 8.1 环境要求

| 组件         | 版本要求                       |
| ------------ | ------------------------------ |
| Flutter SDK  | ≥ 3.11.5                       |
| Android SDK  | compileSdk 35, minSdk 24       |
| Android NDK  | 28.2.13676358                  |
| Kotlin       | 2.2.20                         |
| Gradle       | 8.x (via AGP 8.11.1)           |
| CMake        | 3.22.1                         |
| C++ Standard | C++17                          |
| Target ABI   | arm64-v8a, armeabi-v7a, x86_64 |

### 8.2 构建命令

```bash
flutter pub get
flutter run
```

### 8.3 Release 构建

```bash
flutter build apk --release
```

Release 构建启用 ProGuard 混淆、资源压缩 (`shrinkResources = true`)，并保留 NDK 符号表供崩溃分析。

---

## 9. 项目结构

```
hyper_guard/
├── android/app/src/main/
│   ├── AndroidManifest.xml                    # 权限声明 + IntentFilter + 组件注册
│   ├── cpp/                                    # C++/NDK 沙盒引擎
│   │   ├── sandbox_core.h / .cpp               # 沙盒核心引擎
│   │   ├── fake_data_provider.h / .cpp          # 假数据供给引擎
│   │   ├── behavior_monitor.h / .cpp            # 行为监控引擎
│   │   └── jni_bridge.cpp                      # JNI 桥接层
│   └── kotlin/xin/ctkqiang/hyper_guard/
│       ├── DeviceUtil.kt                       # 设备验证工具
│       ├── InstallInterceptor.kt               # 安装拦截器
│       ├── HyperGuardService.kt                # 前台守护服务
│       ├── HyperGuardNative.kt                 # NDK 桥接
│       └── MainActivity.kt                     # Flutter 入口 + MethodChannel
├── assets/
│   └── applogo.png                             # 应用图标
├── lib/
│   ├── core/
│   │   ├── constants/app_constants.dart         # 全局常量
│   │   └── theme/
│   │       ├── app_theme.dart                   # Material 3 主题定义
│   │       └── theme_colors.dart                # 上下文感知颜色解析器
│   ├── data/models/
│   │   ├── sandbox_app.dart                     # 沙盒应用数据模型
│   │   └── security_report.dart                 # 安全报告数据模型
│   ├── presentation/
│   │   ├── bloc/                                # BLoC 状态管理
│   │   │   ├── device/                          # 设备验证
│   │   │   ├── sandbox/                         # 沙盒管理
│   │   │   ├── report/                          # 报告管理
│   │   │   └── theme/                           # 主题切换
│   │   ├── screens/                             # 页面
│   │   │   ├── splash_screen.dart
│   │   │   ├── home_screen.dart
│   │   │   ├── sandbox_screen.dart
│   │   │   └── report_screen.dart
│   │   └── widgets/                             # 可复用组件
│   │       ├── hyper_app_bar.dart
│   │       ├── hyper_button.dart
│   │       ├── hyper_card.dart
│   │       ├── report_chart.dart
│   │       └── sandbox_app_tile.dart
│   └── services/                                # 平台通信层
│       ├── device_service.dart
│       ├── sandbox_service.dart
│       └── monitor_service.dart
├── pubspec.yaml
└── android/app/CMakeLists.txt
```

---

## 10. 未来展望

### 10.1 短期路线（v1.x）

- 集成 YARA 规则引擎实现基于特征的恶意代码静态检测
- 支持对沙盒内 APK 的网络流量进行 MITM 代理捕获和分析
- NLP-based 诈骗话术识别（用于分析 APK 内置的钓鱼页面和聊天脚本）

### 10.2 中期路线（v2.x）

- 实现基于 eBPF 的系统调用级别行为追踪（需要 Kernel 支持）
- 构建云端威胁情报共享平台，实现跨设备的攻击特征同步
- 与 MIUI/HyperOS 系统安全模块深度整合，提供系统级开放 API

### 10.3 长期愿景

- 成为 HyperOS 生态的官方安全组件，预装于所有小米设备
- 建立移动安全领域的蜜罐网络（Honeynet），实现大规模威胁情报采集
- 将 AI/ML 模型部署于沙盒分析管道，实现自动化的恶意行为分类和归因

---

## 11. 技术指标

| 指标               | 数值                               |
| ------------------ | ---------------------------------- |
| 最小 SDK 版本      | Android 7.0 (API 24)               |
| 目标 SDK 版本      | Android 15 (API 35)                |
| 安装拦截响应时间   | < 100ms                            |
| 沙盒初始化时间     | < 500ms                            |
| APK 解析时间       | < 50ms (典型 APK)                  |
| 威胁评分计算复杂度 | O(n)，n = 权限数量                 |
| 主题切换过渡时间   | 0ms (同步重建)                     |
| 审计日志写入延迟   | < 5ms                              |
| Dart 静态分析      | 0 Error / 0 Warning                |
| 同时活跃沙盒数     | 默认 5，可配置                     |
| APK 文件选择支持   | 系统文件选择器，仅允许 .apk 扩展名 |

---

## 12. 许可证

本项目为闭源项目，保留所有权利。未经授权不得复制、分发或用于商业用途。

---

<p align="center">
  <b>HyperGuard 澎湃盾</b><br>
  <sub>HyperOS Security Sandbox System</sub><br>
  <sub>Version 1.0.0 · Built with Flutter + Kotlin + C++/NDK</sub>
</p>
