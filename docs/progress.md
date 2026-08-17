# 进度与计划 — 《downward》

> 交接文档：新对话从这里恢复上下文。最后更新：2026-08-17（M7 合入后）。
> 详细规范见根目录 `AGENTS.md`；架构细节见 `godot_project/docs/architecture.md`。

## 1. 当前状态快照

- **分支**：所有已验收工作均在 `develop`（本地）。远程推送因网络问题待补（见 §5）。
- **里程碑**：M0/M1 已验收；M2-M6 内容完成并通过基础验收（`[~]` 待归档）；**M7（Boss AI）内容完成并通过基础验收**，标 `[~]`。
- **自动验证**：`tools/run_verify.ps1` 一键复验，当前 **55 项全绿**（玩家 6 / 相机 2 / 机关 5 / 穿越 7 / 光照 4 / 二段跳 4 / 老鼠 11 / 机关二批 8 / Boss 12）。
- **可玩入口**：
  - `scenes/rooms/demo_room.tscn`（主场景，F5）：M2/M3 全链路
  - `scenes/test/mechanism_lab.tscn`（F6）：M4-M6 全能力试验场，出生给齐靴/哨/灯
  - `scenes/test/boss_lab.tscn`：M7 Boss 试验场（巡逻路径+绕障高台+环境光区），出生给灯/哨

## 2. 已实现机制速查

| 系统 | 入口 | 要点 |
|---|---|---|
| 玩家控制器 | `scripts/characters/player.gd` | 3格/秒、3格跳、二段跳5格（靴）、攀爬、水域、死亡重生、`input_delay`（致幻） |
| 老鼠 | `scripts/characters/mouse.gd` + `ControlManager` | 5.2格/秒、2+1.5格跳、6×6判定、窄缝、0.8s 延迟参数 |
| 灯光 | `scripts/characters/lamp.gd` + `LightSystem` | F 开关、60°/6格、鼠标跟随、`is_point_lit`/`is_point_lit_ambient`/`has_clear_line` API |
| Boss | `scripts/characters/boss.gd`（M7） | 五状态机（巡逻/警戒/追击/搜索/分心）、老鼠优先、接触扑杀、搜索10s超时；手册见 building_blocks.md |
| 机关通信 | `MechanismBus` | `trigger/release/is_triggered`，StringName ID，状态跨重生保留 |
| 积木 16 个 | `scenes/interactables/` | 手册：`godot_project/docs/building_blocks.md`（每个积木的参数与连线） |
| TileSet | `assets/tiles/tileset_cave.tres` | 4 分区（source 1 泥土/2 石质带碰撞+遮光，3 装饰16px/4 装饰32px）；布局改动走 `tools/build_tileset.gd` |
| HUD | `scripts/autoload/hud.gd` | 占位：拾取弹窗+持有图标栏，M10 重做 |

## 3. 下一步计划（按依赖顺序）

1. ~~M7 Boss AI~~（2026-08-17 完成：五状态机+全转换验证 12 项，分支 `feat/m7-boss`）
2. **策划人工环节**：用积木搭建房间 1-11（积木已全部就绪，Boss 与环境光源积木见 building_blocks.md「角色积木（M7）」）
3. **M8 房间连通**：12 房间过渡+检查点+连通性断言（注意：当前死亡重生仅单房间版；Boss 跨房间重置逻辑随 M8 设计）
4. **M9 结局关卡**（AI 灰盒，第 12 房间三层结构+Boss 追赶路径记录/光敏屏障，见策划案 §三房间12 与阶段三清单）→ **M10 打磨**（可裁剪）

## 4. 关键设计决策（勿轻易推翻，详见 decisions.md）

- 渲染：480×270 原生 + 整数倍缩放 + **亚像素渲染**（不开像素吸附！低速移动抖动根源）+ 全局物理插值
- 灯光：鼠标实时跟随（策划案原设定，可指任意角度；朝向跟随方案试过已回退）
- 致幻：渲染延迟降级为**输入延迟**（`player.input_delay`），里程碑预案允许
- 人鼠碰撞分层：地形/门=层1、玩家=层2、老鼠=层3、交互区 mask=6；Boss=层4（值8）仅撞地形
- Boss 感知补充规则（警戒封顶 12 格/开灯不看锥向/搜索态也可被分心/扑杀仅限攻击态）见 decisions.md 2026-08-17
- 草丛光透=纯视觉遮盖（秘密通道本来就能走）
- 关卡由策划用积木搭建，AI 不交付成品关卡（M9 灰盒除外）

## 5. 遗留问题

- [ ] **push 到 origin**（代理关闭后 GitHub 连不上；恢复后 `git push origin develop`，并删除远程残留的 `feat/m3-mechanisms` 分支——若已删请忽略）
- [ ] 光敏水晶在黑暗中难发现（可加微弱自发光轮廓，用户暂缓）
- [ ] 灯光朝向混合方案（朝向+鼠标自动切换）备选未做
- [ ] 相机边界：pcam 直写坐标会绕过 Camera2D limit 钳制（已知，M8 房间过渡时处理）
- [ ] paint/capture 工具走 `--script` 模式无 Autoload，引用 Autoload 的脚本（M5 起）在其中编译失败——场景能画出但脚本不运行；重生成 mechanism_lab 等需改造走宿主模式（decisions.md 2026-08-17）
- [ ] Boss 追击为直线+跳跃绕障简化版；第 12 房间"沿玩家路径追赶/屏障阻挡"在 M9 专项实现（策划案阶段三清单）

## 6. 常用命令（godot_project/ 下）

```powershell
$godot = "C:\softwares\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe"
& $godot --headless --import                                    # 静态检查
powershell -ExecutionPolicy Bypass -File tools/run_verify.ps1   # 全部机制断言（应 VERIFY PASSED）
& $godot --headless --quit-after 120 res://scenes/rooms/demo_room.tscn  # 冒烟
```
