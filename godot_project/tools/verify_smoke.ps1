# 冒烟验证：headless 导入检查 + 逐场景运行 N 帧，任何脚本错误即失败。
# 用法（godot_project/ 下）：powershell -File tools/verify_smoke.ps1 [-Scenes "res://...", "..."]
param(
    [string]$Scenes = "res://scenes/templates/room_base.tscn",
    [int]$Frames = 120
)
$SceneList = $Scenes -split ","

$ErrorActionPreference = "Continue"
$Godot = "C:\Editors\godot\Godot_v4.7-stable_win64\Godot_v4.7-stable_win64_console.exe"
$ErrorPattern = "SCRIPT ERROR|Parse Error|Failed loading resource|Cannot load|Invalid call|Attempt to call"
$failed = $false

Write-Output "== [1/2] headless import =="
$importOut = & $Godot --headless --import 2>&1 | Out-String
if ($importOut -match $ErrorPattern) {
    Write-Output "FAIL: import errors found"
    ($importOut -split "`n") | Select-String -Pattern $ErrorPattern | ForEach-Object { Write-Output $_.Line }
    $failed = $true
} else {
    Write-Output "OK: import clean"
}

Write-Output "== [2/2] scene smoke ($Frames frames) =="
foreach ($scene in $SceneList) {
    $runOut = & $Godot --headless --quit-after $Frames $scene 2>&1 | Out-String
    if ($runOut -match $ErrorPattern) {
        Write-Output "FAIL: $scene"
        ($runOut -split "`n") | Select-String -Pattern $ErrorPattern | ForEach-Object { Write-Output $_.Line }
        $failed = $true
    } else {
        Write-Output "OK: $scene"
    }
}

if ($failed) { exit 1 } else { Write-Output "ALL PASSED"; exit 0 }
