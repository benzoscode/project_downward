# AGENTS.md — 《downward》AI 开发准则

本文件是 AI 代理在本仓库工作的**最高优先级约束**。任何任务开始前必须先读本文件。
策划案全文见 `proposal/downward_游戏开发策划案.md`，代码中的设计参数应与策划案保持一致并在注释中引用对应章节。

## 1. 项目概况

- 2D 横板像素风地底探索解谜游戏（类银河城），核心机制为光暗二元博弈
- 引擎：Godot 4.x，语言：GDScript（必须静态类型标注）
- 目标平台：Windows 桌面（GameJam 作品，暂不考虑移动端实机）

## 2. 运行环境

- 引擎可执行文件：`C:\Editors\godot\Godot_v4.7-stable_win64\Godot_v4.7-stable_win64_console.exe`
  （console 版用于捕获 stdout/stderr；无 GUI 环境一律用 `--headless`）
- 工程根目录：`godot_project/`（即 `project.godot` 所在目录）
- 引擎版本：Godot 4.7 stable，与 `project.godot` features 标记一致

### 常用验证命令（在 `godot_project/` 下执行）

```powershell
# 全项目脚本静态检查（导入资源并检查脚本错误）
& "C:\Editors\godot\Godot_v4.7-stable_win64\Godot_v4.7-stable_win64_console.exe" --headless --import
# 冒烟测试：运行指定场景 N 帧后退出，检查运行时错误
& "C:\Editors\godot\Godot_v4.7-stable_win64\Godot_v4.7-stable_win64_console.exe" --headless --quit-after 60 res://scenes/rooms/room_01.tscn
# 截图（配合 tools/ 下的截图脚本，用于人类审阅）
```

## 3. 协作工作流：集中交付协议

人类只负责审阅，AI 必须做到**全程无需人工介入**：

1. 每个工作周期开始时，与人类确认本轮任务清单与验收标准，然后一次性执行到底
2. 执行中**禁止**向人类提问中断；遇到歧义时选择最符合策划案的方案，并在交付说明中记录决策点供审阅
3. 每个任务完成后必须自我验证（见 §8），**未通过验证不得声称完成**
4. 交付时输出：完成清单、验证证据（命令输出/截图路径）、遗留问题、给人类的审阅要点
5. 人类反馈后统一修改，全部通过后共同规划下一周期

## 4. 目录结构

```
godot_project/
├── project.godot
├── scenes/            # 场景
│   ├── rooms/         # 房间（room_01.tscn ... room_12.tscn，由策划搭建）
│   ├── interactables/ # 可复用机关积木（按钮、门、水晶、水体、地刺……）
│   ├── characters/    # 玩家、老鼠、Boss
│   └── templates/     # room_base.tscn 等模板
├── scripts/           # 与场景对应的脚本，目录层级镜像 scenes/
│   └── autoload/      # 全局单例（GameState 等）
├── assets/
│   ├── placeholder/   # AI 生成的占位素材（未来整体替换，见 §7）
│   └── audio/
├── tools/             # 开发工具脚本（截图、验证），不进游戏包
└── docs/              # 架构文档（architecture.md 等，随里程碑更新）
```

仓库根目录的 `docs/`（若存在）放项目级文档；引擎内文档放 `godot_project/docs/`。

## 5. 代码规范（GDScript）

- **必须静态类型**：所有变量、参数、返回值标注类型；禁止省略返回类型的函数
- 命名：`snake_case` 变量/函数/文件，`PascalCase` 类名（`class_name`）与场景节点，`_private` 前缀私有成员，`SCREAMING_SNAKE_CASE` 常量
- 信号驱动解耦：机关之间、角色与系统之间优先用信号，禁止跨场景直接引用节点路径（`get_node("../../..")` 一律禁止）
- 面向策划设计：可调参数一律 `@export` 暴露到 Inspector，带 `@export_range`/`@export_category` 组织；参数默认值取策划案数值
- 每帧逻辑放 `_physics_process`，禁止在 `_process` 里做移动；移动速度单位用"格/秒"，代码内换算（1 格 = 16px）
- 注释：**中文**，只写"为什么"和设计参数依据（例：`# 0.8s 操控延迟，见策划案 §二(二)3`），不写复述代码的废话注释

## 6. 场景规范（人类可搭建是第一目标）

关卡由人类策划搭建，AI 交付的是**积木而非成品关卡**：

- 每个机关是独立 `.tscn`（`scenes/interactables/`），要求：
  - 拖入即用的合理默认值；必要关联（如按钮→门）通过 `@export var door_id: StringName` 或导出 NodePath 完成
  - 提供编辑器可视化辅助（`@tool` + 绘制感应范围/移动路径）
- `scenes/templates/room_base.tscn`：房间模板，内置出生点标记、出入口触发区、相机边界（`Camera2D` limits）、环境光配置节点；策划复制改名即新房间
- TileMapLayer 节点命名约定：`TileMapTerrain`（物理碰撞）、`TileMapDecor`（无碰撞装饰）、`TileMapMechanismMarkers`（机关占位标记）；配套 TileSet 需含物理层
- 房间尺寸 120×67 格（1920×1080 逻辑），瓦片 16×16
- 节点树层级约定：静态几何 → 机关 → 角色 → 灯光 → UI，层级名用语义命名

## 7. 占位素材规范（"未来一定会替换"）

- 渲染方案：**480×270 原生分辨率 + 整数倍缩放**（`viewport` 拉伸 + `keep` 比例 + 像素 snapping），瓦片逻辑尺寸 16×16
- 所有占位素材放 `assets/placeholder/`，AI 生成的极简剪影/纯色图，**替换 = 同路径同尺寸覆盖文件，场景零改动**
- 尺寸表（画布固定，替换时必须一致）：

| 素材 | 尺寸(px) | 备注 |
|---|---|---|
| 地形瓦片 | 16×16 | TileSet 用 |
| 玩家 | 16×24 | 判定 12×20 |
| 老鼠 | 8×8 | 判定 6×6 |
| Boss | 128×128 | 约玩家 8 倍 |
| 道具/按钮/水晶 | 16×16 | |
| 门 | 32×48 | 2×3 格 |
| 宝箱/石像 | 32×32 | |

- 动画：横向序列帧，帧尺寸固定；同一素材的替换图必须同帧数同尺寸
- 素材命名：`{类别}_{名称}_{状态}.png`，如 `char_player_idle.png`、`tile_terrain_cave.png`

## 8. 自我验证要求（声称完成前必须执行）

1. 运行 §2 的 `--headless --import`，确认 0 脚本错误、0 资源加载失败
2. 对改动涉及的每个场景跑冒烟测试（`--quit-after 60`），确认无运行时错误
3. 涉及视觉/手感的改动：用 `tools/` 截图脚本产出截图或 GIF，路径写入交付说明
4. 可断言的机制（跳跃高度、速度、状态机切换）优先写成可自动跑的验证场景（`tools/verify/`），人类审阅时可一键复验
5. 以上全部通过后，在交付说明中附关键输出摘录；**禁止仅凭"代码看起来对"声称完成**

## 9. Git 规范

- 分支：功能分支 `feat/{名称}`，从 `develop` 切出；完成后合回 `develop`
- AI 只在**任务验证通过后**提交；提交信息用中文，格式 `{类型}: {简述}`（类型：feat/fix/refactor/docs/chore）
- 每个逻辑任务一个提交，禁止把多个不相关改动塞进一个提交
- 禁止 force-push、禁止改 git config、禁止提交 `godot_project/.godot/` 等缓存目录

## 10. 文档维护

- `godot_project/docs/architecture.md`：架构总览（场景树结构、Autoload 职责、信号流、状态机、机关协议），**每个里程碑更新**
- 新增机关积木时，同步更新 `godot_project/docs/building_blocks.md`（策划搭建手册：每个积木的用途、参数、连线方式）
- 重要设计决策（如分辨率方案、机关通信协议）记录在 `godot_project/docs/decisions.md`，含日期与理由
