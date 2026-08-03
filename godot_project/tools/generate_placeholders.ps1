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

Write-Output "完成。"
