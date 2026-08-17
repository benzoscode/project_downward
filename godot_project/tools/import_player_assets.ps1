# 导入主角素材：待机/走路 × 无灯/有灯，纵向 16x192（8 帧 16x24）转横向序列帧。
# 命名规范 AGENTS.md §7：char_{角色}_{状态}.png；帧画布 16x24 与占位一致。
# 跳跃动画用走路第 1 帧充当（2026-08-17 用户确认），在 build_player_sprites.gd 里组帧。
# 用法（godot_project/ 下）：powershell -File tools/import_player_assets.ps1

Add-Type -AssemblyName System.Drawing

$Src = "C:\Users\Admin（无密码）\Downloads\小人"
$OutDir = Join-Path $PSScriptRoot "..\assets\characters"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function Convert-Strip([string]$srcName, [string]$dstName) {
    $bmp = New-Object System.Drawing.Bitmap((Join-Path $Src $srcName))
    $frames = $bmp.Height / 24
    if ($bmp.Width -ne 16) { throw "$srcName 宽度 $($bmp.Width) != 16" }
    $outW = 16 * $frames
    $out = New-Object System.Drawing.Bitmap($outW, 24)
    $g = [System.Drawing.Graphics]::FromImage($out)
    for ($i = 0; $i -lt $frames; $i++) {
        $dstX = 16 * $i
        $srcY = 24 * $i
        $dstRect = New-Object System.Drawing.Rectangle($dstX, 0, 16, 24)
        $srcRect = New-Object System.Drawing.Rectangle(0, $srcY, 16, 24)
        $g.DrawImage($bmp, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
    }
    $g.Dispose()
    $out.Save((Join-Path $OutDir $dstName), [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output "  $srcName  ->  $dstName（$frames 帧）"
    $bmp.Dispose()
    $out.Dispose()
}

Convert-Strip "小人待机无灯 (3).png" "char_player_idle.png"
Convert-Strip "小人待机有灯 (2).png" "char_player_idle_lamp.png"
Convert-Strip "走路无灯 (2).png" "char_player_run.png"
Convert-Strip "走路有灯.png" "char_player_run_lamp.png"
Write-Output "完成。"
