# Meow OS

一个面向 Radxa Cubie A5E 的轻量 Qt Quick 设备系统。第一版将显示、触摸、开机界面、系统设置和背板硬件服务固定下来，应用层可以继续扩展。

## 当前能力

- 1280×800 原生横屏 Qt Quick UI，逆时针 90° 映射到 800×1280 物理面板
- A5E Mali-G57/Panfrost + EGLFS 硬件渲染，保留 Linux framebuffer 软件回退
- JD9366T + Linux evdev/libinput 触摸输入
- 读取并调节真实 PWM 背光亮度，设置页限制最低 10% 防止黑屏
- 无动画的圆形 MeowKJ 头像启动画面与“关于本机”资料卡
- 模型驱动的可扩展应用主页、点击测试、双栏系统设置
- 不可触摸的系统状态栏与紧凑返回组件
- NetworkManager Wi-Fi 扫描、连接、忘记网络、信号/信道/频段/速率显示与 iPadOS 风格英文触摸键盘（两级数字/符号页）
- 为设备用户配置最小化 NetworkManager 授权；扫描和连接失败会显示可执行的中文原因
- Wi-Fi 连接/忘记期间显示阻断式进度提示；已保存网络可长按重新输入密码或忘记
- 双有线网口状态页：分别显示 eth0/eth1 的链路、地址、协商速率、双工、MAC 与 MTU
- 系统盘与 NVMe 的真实容量、挂载状态和 macOS 风格彩色使用量条
- 非阻塞电池状态采集：电量、精确温度、充电安全温区与外部电源状态
- 电池共享I²C使用100kHz engine mode，兼容电量计的时钟拉伸
- “隔空喵传”入口、A5E I²S 内置扬声器设备树覆盖层、ALSA 软件音量与短促猫咪提示音
- 设置页常驻缓存；Wi-Fi、音量与硬件状态查询均在工作线程执行
- 本地打包的 Lucide SVG 图标
- systemd 图形模式启动、关闭 tty 光标

完整产品目标、页面结构、硬件数据边界和验收标准见 [docs/MEOW_OS_DESIGN.md](docs/MEOW_OS_DESIGN.md)。

## 构建

在 A5E Debian 11 上安装 Qt 5 开发包后：

```sh
qmake meow-os.pro
make -j2
./build/meow-os
```

`MEOW_QPA_PLATFORM` 可覆盖显示后端：`linuxfb:fb=/dev/fb0`、`eglfs`、`wayland` 或 `xcb`。

## 项目边界

仓库只保存 Meow OS 层的代码、启动配置和镜像装配脚本。Radxa 内核、U-Boot 和芯片厂商驱动仍由上游发行版提供；A5E 的 WX101/JD9366T 覆盖层及 Jadard 模块作为板级 profile 注入，不把供应商内核树复制进仓库。

## 许可

本仓库代码使用 MIT。Lucide 图标声明见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)；Radxa、Qt、字体和面板厂商文件分别遵循其原始许可。
