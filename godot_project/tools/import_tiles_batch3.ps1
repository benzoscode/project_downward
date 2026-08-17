# 导入洞穴素材第三批（水体/草/石砖）：去重 + 规范命名 + 纵向序列帧转横向。
# 命名规则同前两批（{类别}_{名称}_{状态/序号}.png，见 AGENTS.md §7）：
#   地形瓦片 → assets/tiles/tile_*；装饰件 → assets/decor/decor_*
# 用法（godot_project/ 下）：powershell -File tools/import_tiles_batch3.ps1

Add-Type -AssemblyName System.Drawing

$Src = "C:\Users\Admin（无密码）\Documents\Tencent Files\584196082\FileRecv"
$TilesDir = Join-Path $PSScriptRoot "..\assets\tiles"
$DecorDir = Join-Path $PSScriptRoot "..\assets\decor"

function Get-PixelHash([System.Drawing.Bitmap]$bmp, [int]$x0 = 0, [int]$y0 = 0, [int]$w = 0, [int]$h = 0) {
    # 像素级哈希（整图或子区域），用于精确去重
    if ($w -eq 0) { $w = $bmp.Width }
    if ($h -eq 0) { $h = $bmp.Height }
    $ms = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter($ms)
    for ($y = $y0; $y -lt $y0 + $h; $y++) {
        for ($x = $x0; $x -lt $x0 + $w; $x++) {
            $bw.Write($bmp.GetPixel($x, $y).ToArgb())
        }
    }
    $bw.Flush()
    $md5 = [System.Security.Cryptography.MD5]::Create()
    return [System.BitConverter]::ToString($md5.ComputeHash($ms.ToArray())).Replace("-", "")
}

function Copy-Tile([string]$srcName, [string]$dstDir, [string]$dstName, [hashtable]$seen) {
    $path = Join-Path $Src $srcName
    $bmp = New-Object System.Drawing.Bitmap($path)
    $hash = Get-PixelHash $bmp
    $bmp.Dispose()
    if ($seen.ContainsKey($hash)) {
        Write-Output "  跳过（与 $($seen[$hash]) 像素相同）: $srcName"
        return
    }
    $seen[$hash] = $dstName
    Copy-Item $path (Join-Path $dstDir $dstName)
    Write-Output "  $srcName  ->  $dstName"
}

function Split-WaterStrip([string]$srcName, [string]$dstName) {
    # 纵向 16xN 序列帧 → 横向序列帧（AGENTS.md §7：动画横向排布）。
    # 条内帧原样保留——重复帧是动画节奏设计，不得去重（2026-08-17 用户确认）
    $path = Join-Path $Src $srcName
    $bmp = New-Object System.Drawing.Bitmap($path)
    $frames = $bmp.Height / 16
    $outW = 16 * $frames
    $out = New-Object System.Drawing.Bitmap($outW, 16)
    $g = [System.Drawing.Graphics]::FromImage($out)
    for ($i = 0; $i -lt $frames; $i++) {
        $dstX = 16 * $i
        $srcY = 16 * $i
        $dstRect = New-Object System.Drawing.Rectangle($dstX, 0, 16, 16)
        $srcRect = New-Object System.Drawing.Rectangle(0, $srcY, 16, 16)
        $g.DrawImage($bmp, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
    }
    $g.Dispose()
    $out.Save((Join-Path $TilesDir $dstName), [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output "  $srcName  ->  $dstName（$frames 帧，已转横向）"
    $bmp.Dispose()
    $out.Dispose()
}

function Merge-Atlas([string[]]$srcFiles, [string]$dstPath) {
    # 多张 16x16 横向拼成图集（供 TileSet 分区引用，布局见 build_tileset.gd 分区表）
    $count = $srcFiles.Count
    $outW = 16 * $count
    $out = New-Object System.Drawing.Bitmap($outW, 16)
    $g = [System.Drawing.Graphics]::FromImage($out)
    for ($i = 0; $i -lt $count; $i++) {
        $bmp = New-Object System.Drawing.Bitmap((Join-Path $TilesDir $srcFiles[$i]))
        $dstX = 16 * $i
        $dstRect = New-Object System.Drawing.Rectangle($dstX, 0, 16, 16)
        $g.DrawImage($bmp, $dstRect, (New-Object System.Drawing.Rectangle(0, 0, 16, 16)),
            [System.Drawing.GraphicsUnit]::Pixel)
        $bmp.Dispose()
    }
    $g.Dispose()
    $out.Save($dstPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $out.Dispose()
    Write-Output "  图集: $dstPath（$count 格）"
}

Write-Output "== 地形：石砖/水 =="
$seenTiles = @{}
Copy-Tile "地下.png" $TilesDir "tile_stone_brick_01.png" $seenTiles
Copy-Tile "表面砖块.png" $TilesDir "tile_stone_brick_top.png" $seenTiles
Copy-Tile "表面草.png" $TilesDir "tile_stone_brick_grass_01.png" $seenTiles
Copy-Tile "表面草 (2).png" $TilesDir "tile_stone_brick_grass_02.png" $seenTiles
Copy-Tile "表面草 (3).png" $TilesDir "tile_stone_brick_grass_03.png" $seenTiles
Copy-Tile "表面裂纹.png" $TilesDir "tile_stone_brick_crack_01.png" $seenTiles
Copy-Tile "表面裂纹 (2).png" $TilesDir "tile_stone_brick_crack_02.png" $seenTiles
Copy-Tile "表面裂纹 (3).png" $TilesDir "tile_stone_brick_crack_03.png" $seenTiles
Copy-Tile "水体2.png" $TilesDir "tile_water_surface_01.png" $seenTiles

Write-Output "== 水体序列帧（转横向） =="
Split-WaterStrip "平静水体.png" "tile_water_calm_anim.png"
Split-WaterStrip "平静水体 (3).png" "tile_water_calm_anim_long.png"
Split-WaterStrip "水体 (2).png" "tile_water_wave_anim_01.png"
Split-WaterStrip "水体 (3).png" "tile_water_wave_anim_02.png"
# 水体 (3) (1).png 与 水体 (3).png 文件级 MD5 相同，直接不入库
Write-Output "  跳过（文件级重复）: 水体 (3) (1).png"

Write-Output "== 装饰：草丛 =="
$seenDecor = @{}
Copy-Tile "草1.png" $DecorDir "decor_grass_01.png" $seenDecor
Copy-Tile "草2.png" $DecorDir "decor_grass_02.png" $seenDecor
Copy-Tile "草3.png" $DecorDir "decor_grass_03.png" $seenDecor
Copy-Tile "草 (2).png" $DecorDir "decor_grass_04.png" $seenDecor
Copy-Tile "草 (3).png" $DecorDir "decor_grass_05.png" $seenDecor
Copy-Tile "草 (4).png" $DecorDir "decor_grass_06.png" $seenDecor
Copy-Tile "草 (5).png" $DecorDir "decor_grass_07.png" $seenDecor

Write-Output "== 图集拼装（供 TileSet 分区） =="
Merge-Atlas @("tile_stone_brick_01.png", "tile_stone_brick_top.png",
    "tile_stone_brick_grass_01.png", "tile_stone_brick_grass_02.png", "tile_stone_brick_grass_03.png",
    "tile_stone_brick_crack_01.png", "tile_stone_brick_crack_02.png", "tile_stone_brick_crack_03.png") `
    (Join-Path $TilesDir "atlas_brick.png")
$grassFiles = 1..7 | ForEach-Object { "decor_grass_0$_.png" }
$grassPaths = $grassFiles | ForEach-Object { $_ }
# Merge-Atlas 从 tiles 目录读源，草丛在 decor 目录——先复制临时拼合
foreach ($f in $grassPaths) { Copy-Item (Join-Path $DecorDir $f) (Join-Path $TilesDir $f) -Force }
Merge-Atlas $grassPaths (Join-Path $DecorDir "atlas_grass.png")
foreach ($f in $grassPaths) { Remove-Item (Join-Path $TilesDir $f) -Force }

Write-Output "完成。"
