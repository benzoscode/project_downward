# 机制断言验证：运行 tools/verify/ 下的验证脚本，出现 [FAIL] 即失败。
# 两种模式：script: 前缀走 --script（SceneTree，无 Autoload）；
# 其余走 verify_host 场景（真实运行环境，Autoload 可用）。
# 用法（godot_project/ 下）：powershell -File tools/run_verify.ps1
param(
    [string[]]$VerifyScripts = @(
        "script:tools/verify/verify_player.gd",
        "script:tools/verify/verify_camera.gd",
        "script:tools/verify/verify_tileset.gd",
        "tools/verify/verify_mechanisms.gd",
        "tools/verify/verify_traversal.gd",
        "tools/verify/verify_lighting.gd",
        "tools/verify/verify_double_jump.gd",
        "tools/verify/verify_mouse.gd",
        "tools/verify/verify_mechanisms2.gd",
        "tools/verify/verify_mechanisms3.gd",
        "tools/verify/verify_boss.gd",
        "tools/verify/verify_rooms.gd"
    )
)

$Godot = "C:\softwares\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe"
$failed = $false
foreach ($entry in $VerifyScripts) {
    Write-Output "== $entry =="
    if ($entry.StartsWith("script:")) {
        $path = $entry.Substring(7)
        $out = & $Godot --headless --script $path 2>&1 | Out-String
    } else {
        $out = & $Godot --headless res://scenes/test/verify_host.tscn -- "res://$entry" 2>&1 | Out-String
    }
    Write-Output $out
    if ($out -match "\[FAIL\]" -or $out -notmatch "VERIFY RESULT") {
        $failed = $true
    }
}

if ($failed) {
    Write-Output "VERIFY FAILED"
    exit 1
}
Write-Output "VERIFY PASSED"
exit 0
