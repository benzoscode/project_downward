# 生成全部占位素材：纯色极简剪影。
# 尺寸规范见 AGENTS.md §7——替换美术时同路径同尺寸覆盖文件即可，场景零改动。
# 用法：在 godot_project/ 下执行  powershell -File tools/generate_placeholders.ps1

Add-Type -AssemblyName System.Drawing

$OutDir = Join-Path $PSScriptRoot "..\assets\placeholder"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function Color([int]$r, [int]$g, [int]$b, [int]$a = 255) {
    [System.Drawing.Color]::FromArgb($a, $r, $g, $b)
}

function New-Png([string]$name, [int]$w, [int]$h, [scriptblock]$draw) {
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
    $g.Clear([System.Drawing.Color]::Transparent)
    & $draw $g
    $path = Join-Path $OutDir $name
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
    Write-Output "  $name ($w x $h)"
}

function Fill-Rect($g, [int]$x, [int]$y, [int]$w, [int]$h, $color) {
    $brush = New-Object System.Drawing.SolidBrush($color)
    $g.FillRectangle($brush, $x, $y, $w, $h)
    $brush.Dispose()
}

Write-Output "生成占位素材 -> $OutDir"

# ---- 地形图集：4×2 块 16×16 瓦片 ----
# 上行：带碰撞地形（实岩 / 砖块 / 平台 / 暗岩）；下行：无碰撞装饰（苔藓 / 碎石 / 裂纹 / 空）
New-Png "tile_terrain_atlas.png" 64 32 {
    param($g)
    Fill-Rect $g 0 0 16 16 (Color 58 63 74)
    Fill-Rect $g 0 0 16 2 (Color 86 93 107)
    Fill-Rect $g 16 0 16 16 (Color 74 64 56)
    Fill-Rect $g 16 7 16 1 (Color 50 43 38)
    Fill-Rect $g 24 0 1 7 (Color 50 43 38)
    Fill-Rect $g 20 8 1 8 (Color 50 43 38)
    Fill-Rect $g 32 0 16 16 (Color 90 81 72)
    Fill-Rect $g 32 0 16 3 (Color 120 108 95)
    Fill-Rect $g 48 0 16 16 (Color 46 49 56)
    Fill-Rect $g 48 0 16 1 (Color 70 74 84)
    Fill-Rect $g 2 18 5 3 (Color 47 74 58)
    Fill-Rect $g 9 22 4 3 (Color 47 74 58)
    Fill-Rect $g 18 20 3 3 (Color 70 66 60)
    Fill-Rect $g 26 24 2 2 (Color 70 66 60)
    Fill-Rect $g 35 17 1 12 (Color 96 102 116)
    Fill-Rect $g 35 22 6 1 (Color 96 102 116)
}

# ---- 玩家：16×24 剪影（判定 12×20）----
New-Png "char_player_idle.png" 16 24 {
    param($g)
    Fill-Rect $g 3 2 10 8 (Color 158 164 176)
    Fill-Rect $g 2 10 12 10 (Color 128 134 148)
    Fill-Rect $g 3 20 4 4 (Color 108 114 128)
    Fill-Rect $g 9 20 4 4 (Color 108 114 128)
}
New-Png "char_player_run.png" 16 24 {
    param($g)
    Fill-Rect $g 4 2 10 8 (Color 158 164 176)
    Fill-Rect $g 3 10 12 10 (Color 128 134 148)
    Fill-Rect $g 2 20 4 4 (Color 108 114 128)
    Fill-Rect $g 11 20 4 4 (Color 108 114 128)
}
New-Png "char_player_jump.png" 16 24 {
    param($g)
    Fill-Rect $g 3 1 10 8 (Color 158 164 176)
    Fill-Rect $g 2 9 12 10 (Color 128 134 148)
    Fill-Rect $g 4 19 3 4 (Color 108 114 128)
    Fill-Rect $g 9 19 3 4 (Color 108 114 128)
}

# ---- 老鼠：8×8 ----
New-Png "char_mouse_idle.png" 8 8 {
    param($g)
    Fill-Rect $g 1 3 6 4 (Color 150 140 130)
    Fill-Rect $g 6 2 2 2 (Color 150 140 130)
    Fill-Rect $g 0 6 1 2 (Color 120 110 100)
}

# ---- 道具：16×16 ----
New-Png "item_lamp.png" 16 16 {
    param($g)
    Fill-Rect $g 6 1 4 3 (Color 120 100 70)
    Fill-Rect $g 4 4 8 9 (Color 240 200 90)
    Fill-Rect $g 5 13 6 2 (Color 120 100 70)
}
New-Png "item_boots.png" 16 16 {
    param($g)
    Fill-Rect $g 2 4 5 9 (Color 110 130 170)
    Fill-Rect $g 2 11 8 3 (Color 110 130 170)
    Fill-Rect $g 9 4 5 9 (Color 110 130 170)
    Fill-Rect $g 9 11 8 3 (Color 110 130 170)
}
New-Png "item_whistle.png" 16 16 {
    param($g)
    Fill-Rect $g 3 6 10 5 (Color 220 215 200)
    Fill-Rect $g 3 4 4 2 (Color 220 215 200)
    Fill-Rect $g 10 7 3 2 (Color 90 85 75)
}
New-Png "item_key.png" 16 16 {
    param($g)
    # 钥匙（第 4 房间宝箱 → 第 3 房间钥匙门）
    $brush = New-Object System.Drawing.SolidBrush((Color 240 200 80))
    $g.FillEllipse($brush, 2, 5, 6, 6)
    $brush.Dispose()
    Fill-Rect $g 7 7 7 2 (Color 240 200 80)
    Fill-Rect $g 11 9 2 3 (Color 240 200 80)
    Fill-Rect $g 13 9 2 2 (Color 240 200 80)
}
foreach ($gem in @(@("jade", 80, 200, 130), @("amber", 230, 170, 60), @("violet", 170, 110, 220))) {
    $name = $gem[0]; $r = [int]$gem[1]; $gg = [int]$gem[2]; $b = [int]$gem[3]
    New-Png "item_gem_$name.png" 16 16 ([scriptblock]::Create(@"
        param(`$g)
        `$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, $r, $gg, $b))
        `$pts = [System.Drawing.Point[]]@(
            (New-Object System.Drawing.Point(8, 1)),
            (New-Object System.Drawing.Point(14, 8)),
            (New-Object System.Drawing.Point(8, 15)),
            (New-Object System.Drawing.Point(2, 8))
        )
        `$g.FillPolygon(`$brush, `$pts)
        `$brush.Dispose()
"@))
}

# ---- 门 32×48 / 宝箱 32×32 / 石像 32×32 ----
New-Png "door_question.png" 32 48 {
    param($g)
    Fill-Rect $g 0 0 32 48 (Color 60 52 46)
    Fill-Rect $g 3 3 26 42 (Color 40 34 30)
    Fill-Rect $g 13 10 6 6 (Color 140 190 120)
    Fill-Rect $g 15 18 2 4 (Color 140 190 120)
    Fill-Rect $g 15 25 2 2 (Color 140 190 120)
}
New-Png "chest_wood.png" 32 32 {
    param($g)
    Fill-Rect $g 2 8 28 20 (Color 122 84 52)
    Fill-Rect $g 2 8 28 6 (Color 150 105 66)
    Fill-Rect $g 14 12 4 6 (Color 220 190 90)
}
New-Png "statue_lamp.png" 32 32 {
    param($g)
    Fill-Rect $g 8 20 16 10 (Color 90 88 96)
    Fill-Rect $g 11 6 10 14 (Color 110 108 118)
    Fill-Rect $g 20 4 8 6 (Color 240 210 110)
}

# ---- 地刺 16×16 / 狮子头按钮 16×16 双态 / 宝箱开盖 32×32 ----
New-Png "prop_spikes.png" 16 16 {
    param($g)
    foreach ($x in @(1, 6, 11)) {
        $brush = New-Object System.Drawing.SolidBrush((Color 170 175 190))
        $pts = [System.Drawing.Point[]]@(
            (New-Object System.Drawing.Point($x, 16)),
            (New-Object System.Drawing.Point(($x + 2), 6)),
            (New-Object System.Drawing.Point(($x + 4), 16))
        )
        $g.FillPolygon($brush, $pts)
        $brush.Dispose()
    }
    Fill-Rect $g 0 14 16 2 (Color 90 95 108)
}
New-Png "prop_button_up.png" 16 16 {
    param($g)
    Fill-Rect $g 2 4 12 12 (Color 96 90 84)
    Fill-Rect $g 4 6 8 8 (Color 180 70 60)
}
New-Png "prop_button_down.png" 16 16 {
    param($g)
    Fill-Rect $g 2 4 12 12 (Color 96 90 84)
    Fill-Rect $g 4 9 8 5 (Color 120 45 40)
}
New-Png "chest_wood_open.png" 32 32 {
    param($g)
    Fill-Rect $g 2 8 28 20 (Color 122 84 52)
    Fill-Rect $g 2 8 28 6 (Color 40 30 24)
    Fill-Rect $g 2 2 28 5 (Color 150 105 66)
}

# ---- 光照贴图：64×64 径向渐变（白芯透明边），供 PointLight2D 使用 ----
New-Png "light_radial.png" 64 64 {
    param($g)
    for ($r = 31; $r -ge 0; $r--) {
        $alpha = [int](255 * (1.0 - $r / 32.0) * (1.0 - $r / 32.0))
        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, 255, 250, 235))
        $g.FillEllipse($brush, 32 - $r, 32 - $r, $r * 2, $r * 2)
        $brush.Dispose()
    }
}

# ---- 光敏水晶 16×16 双态：熄灭（暗青）/ 激活（亮青发光）----
New-Png "prop_crystal_off.png" 16 16 {
    param($g)
    $brush = New-Object System.Drawing.SolidBrush((Color 40 80 85))
    $pts = [System.Drawing.Point[]]@(
        (New-Object System.Drawing.Point(8, 1)),
        (New-Object System.Drawing.Point(13, 7)),
        (New-Object System.Drawing.Point(11, 15)),
        (New-Object System.Drawing.Point(5, 15)),
        (New-Object System.Drawing.Point(3, 7))
    )
    $g.FillPolygon($brush, $pts)
    $brush.Dispose()
}
New-Png "prop_crystal_on.png" 16 16 {
    param($g)
    $brush = New-Object System.Drawing.SolidBrush((Color 90 230 220))
    $pts = [System.Drawing.Point[]]@(
        (New-Object System.Drawing.Point(8, 1)),
        (New-Object System.Drawing.Point(13, 7)),
        (New-Object System.Drawing.Point(11, 15)),
        (New-Object System.Drawing.Point(5, 15)),
        (New-Object System.Drawing.Point(3, 7))
    )
    $g.FillPolygon($brush, $pts)
    $brush.Dispose()
    Fill-Rect $g 7 4 2 8 (Color 220 255 250)
}

# ---- 锥形灯贴图：128×128，顶点在图中心（64,64），60° 锥形向 +X 展开，随距离衰减 ----
# 供玩家照明灯 PointLight2D 使用：texture_scale = 射程px / 64
New-Png "light_cone.png" 128 128 {
    param($g)
    $halfAngle = [math]::PI / 6.0 # 30°，锥形全角 60°（策划案 §二(二)1）
    for ($y = 0; $y -lt 128; $y++) {
        for ($x = 64; $x -lt 128; $x++) {
            $dx = $x - 64; $dy = $y - 64
            $dist = [math]::Sqrt($dx * $dx + $dy * $dy)
            if ($dist -lt 1) { continue }
            $ang = [math]::Atan2($dy, $dx)
            if ([math]::Abs($ang) -gt $halfAngle) { continue }
            $falloff = 1.0 - $dist / 64.0
            $edge = 1.0 - [math]::Abs($ang) / $halfAngle # 锥缘软化
            $alpha = [int](255 * $falloff * (0.45 + 0.55 * $edge))
            if ($alpha -le 0) { continue }
            $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($alpha, 255, 246, 220))
        }
    }
}

# ---- 洞窟背景 480×270：暗色垂直渐变 + 稀疏噪点，感光（被灯光照亮以显现光形） ----
New-Png "bg_cave.png" 480 270 {
    param($g)
    $rng = New-Object System.Random(42)
    for ($y = 0; $y -lt 270; $y++) {
        $t = $y / 270.0
        $r = [int](36 - 10 * $t); $gg = [int](33 - 9 * $t); $b = [int](41 - 11 * $t)
        for ($x = 0; $x -lt 480; $x++) {
            $n = $rng.Next(-4, 5)
            $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255,
                [math]::Max(0, $r + $n), [math]::Max(0, $gg + $n), [math]::Max(0, $b + $n)))
        }
    }
}

# ---- 压力板：小型 8×4（仅老鼠）/ 大型 16×4（人鼠皆可）----
New-Png "prop_plate_small.png" 8 4 {
    param($g)
    Fill-Rect $g 0 1 8 3 (Color 120 90 130)
    Fill-Rect $g 1 0 6 1 (Color 170 130 185)
}
New-Png "prop_plate_large.png" 16 4 {
    param($g)
    Fill-Rect $g 0 1 16 3 (Color 120 90 130)
    Fill-Rect $g 1 0 14 1 (Color 170 130 185)
}

# ---- M6：交替平台 48×8 双色 / 摇杆 16×16 / 草丛 16×16 / 彩色按钮 16×16（白底供调色） ----
New-Png "prop_platform_red.png" 48 8 {
    param($g)
    Fill-Rect $g 0 0 48 8 (Color 150 60 55)
    Fill-Rect $g 0 0 48 2 (Color 200 95 85)
}
New-Png "prop_platform_green.png" 48 8 {
    param($g)
    Fill-Rect $g 0 0 48 8 (Color 70 140 75)
    Fill-Rect $g 0 0 48 2 (Color 110 190 115)
}
New-Png "prop_lever.png" 16 16 {
    param($g)
    Fill-Rect $g 3 10 10 5 (Color 90 88 96)
    Fill-Rect $g 7 4 2 8 (Color 150 145 130)
    Fill-Rect $g 5 2 6 4 (Color 200 80 70)
}
New-Png "prop_grass.png" 16 16 {
    param($g)
    Fill-Rect $g 1 6 3 10 (Color 60 110 60)
    Fill-Rect $g 5 3 3 13 (Color 75 130 70)
    Fill-Rect $g 9 5 3 11 (Color 60 110 60)
    Fill-Rect $g 12 8 3 8 (Color 85 145 80)
}
New-Png "prop_button_color.png" 16 16 {
    param($g)
    Fill-Rect $g 2 4 12 12 (Color 96 90 84)
    Fill-Rect $g 4 6 8 8 (Color 235 235 235)
}

# ---- 告示牌 16×16：木牌+立柱，E 查看文字 ----
New-Png "prop_sign.png" 16 16 {
    param($g)
    Fill-Rect $g 2 2 12 8 (Color 122 84 52)
    Fill-Rect $g 3 3 10 1 (Color 150 105 66)
    Fill-Rect $g 7 10 2 6 (Color 96 66 42)
    Fill-Rect $g 4 5 8 1 (Color 70 50 34)
    Fill-Rect $g 4 7 6 1 (Color 70 50 34)
}

# ---- Boss（地底猎食者）：128×128 剪影（约玩家 8 倍，AGENTS.md §7）----
New-Png "char_boss_idle.png" 128 128 {
    param($g)
    # 躯体：大椭圆甲壳
    $brush = New-Object System.Drawing.SolidBrush((Color 44 40 52))
    $g.FillEllipse($brush, 16, 40, 96, 72)
    $brush.Dispose()
    # 头部（盲眼，感光斑点点缀）
    Fill-Rect $g 20 52 28 36 (Color 52 48 62)
    Fill-Rect $g 24 58 3 3 (Color 120 160 170)
    Fill-Rect $g 30 66 3 3 (Color 120 160 170)
    Fill-Rect $g 25 76 3 3 (Color 120 160 170)
    # 触须（头顶下垂三条）
    Fill-Rect $g 26 30 3 24 (Color 70 76 96)
    Fill-Rect $g 34 24 3 30 (Color 70 76 96)
    Fill-Rect $g 42 32 3 22 (Color 70 76 96)
    # 步足四对
    foreach ($x in @(28, 48, 68, 88)) {
        Fill-Rect $g $x 104 5 20 (Color 56 52 66)
    }
}

Write-Output "完成。"
