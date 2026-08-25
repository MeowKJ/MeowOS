# Meow OS 统一应用设计规范 (Unified Application Design Guide)

## 1. 设计愿景与原则 (Vision & Principles)

Meow OS 是运行在 1280×800 嵌入式触摸屏上的现代化设备系统。所有应用程序必须遵循统一的设计规范，确保用户在任何应用中都能获得一致、流畅、直观的触控体验。

### 核心原则
1. **触控优先 (Touch-First)**：所有交互目标（按键、列表项、滑块）最小触控区域不得小于 48×48 dp，推荐使用 54~62 dp 高度。
2. **轻量与清晰 (Light & Crisp)**：以浅色画布为基底，搭配高对比度文字与柔和的多彩点缀色（紫色、薄荷绿、粉色、天蓝）。
3. **始终可返回 (Always Navigable)**：任何层级均支持左侧边缘滑动返回（92px 触发）、物理 Esc 键以及统一的顶部返回与退出按钮。
4. **即时反馈 (Instant Feedback)**：按键按下时提供缩放（Scale 0.94~0.96）与颜色高亮反馈，操作完成展示非阻塞式 Toast。

---

## 2. 视觉设计变量 (Design Tokens)

### 2.1 颜色系统 (Color Tokens)

| Token 名称 | 颜色值 | 说明 |
|---|---|---|
| `window.canvas` | `#F8F6F8` | 全局浅色画布底色 |
| `window.card` | `#FFFFFF` | 卡片、容器与设置面板底色 |
| `window.ink` | `#242028` | 主标题与主要文本高对比色 |
| `window.secondary` | `#8C8694` | 副标题、辅助说明与未选中文本 |
| `window.purple` | `#7B6DF0` | 系统主强调色（品牌紫） |
| `window.pink` | `#FF7FA7` | 辅助强调色（活力粉） |
| `window.mint` | `#49B990` | 状态良好、已连接、成功（薄荷绿） |
| `window.blue` | `#5E93E8` | 存储与传输强调色（天蓝） |
| `window.separator` | `#ECE8EE` | 列表与卡片分割线 |
| `window.danger` | `#EB4D5C` | 危险操作、断开、删除（玫瑰红） |

### 2.2 排版层级 (Typography Tokens)

- **字体系列**：统一采用系统无衬线字体 `window.uiFont`。
- **字号阶梯**：
  - `Hero Title` (36px, Bold)：点击测试、欢迎标语等大视觉文字。
  - `Page Title` (28~32px, Bold)：应用顶部导航栏标题。
  - `Section / Card Title` (20~24px, DemiBold)：卡片分区标题。
  - `Body / ListItem` (16~18px, Medium/Regular)：正文列表项、按键主文字。
  - `Caption` (13~14px, Regular)：辅助说明、状态标签。

---

## 3. 标准组件规范 (Standard Components)

### 3.1 应用容器与导航 (`AppHeader`)
每个独立应用页面根节点必须设置 `objectName: "meow-app-page"`，并包含标准 `AppHeader`：
- **高度**：`66px`
- **左侧**：`CompactBackButton`（当存在上一级页面时显示）
- **中间**：应用大标题与副标题（`title` & `subtitle`）
- **右侧**：尾部操作（`trailingText`，如“清除”、“刷新”）与“退出”按钮（返回主页桌面）

### 3.2 卡片容器 (`AppCard` / `IosGroup`)
- **圆角**：`22~26px`
- **边框**：`1px` 细描边，颜色为 `window.separator`
- **背景**：`window.card` (`#FFFFFF`)

### 3.3 触控按键 (`AppButton` / `KeyboardKey`)
- **默认高度**：`48~58px`
- **圆角**：`12~16px`
- **状态动画**：
  ```qml
  scale: pressed ? 0.94 : 1.0
  Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
  ```

---

## 4. 虚拟键盘与输入法交互规范 (Input Method Guidelines)

1. **外观风格**：深邃黑曜石渐变（`#1C182E` -> `#25203D`），立体磨砂浮雕键帽。
2. **顶部工具条**：
   - 左侧：输入法标识与语言指示符（如 🐾 `Meow Keyboard (EN)`）。
   - 右侧：清空（`清空 ✕`）与收起键盘（`收起 ⌄`）。
3. **关闭逻辑**：
   - 点击暗色遮罩（Backdrop）立即关闭输入法。
   - 点击键盘顶部控制条空白处或收起按钮立即收起。
   - 动作键（如“连接”、“完成”、“取消”）执行对应逻辑后平滑收起。
