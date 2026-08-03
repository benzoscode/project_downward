# 机制断言验证：运行 tools/verify/ 下的验证脚本，出现 [FAIL] 即失败。
# 用法（godot_project/ 下）：powershell -File tools/run_verify.ps1 [-VerifyScript "tools/verify/verify_player.gd"]
param(
    [string]$VerifyScript = "tools/verify/verify_player.gd"
)

$Godot = "C:\Editors\godot\Godot_v4.7-stable_win64\Godot_v4.7-stable_win64_console.exe"
$out = & $Godot --headless --script $VerifyScript 2>&1 | Out-String
Write-Output $out

if ($out -match "\[FAIL\]" -or $out -notmatch "VERIFY RESULT") {
    Write-Output "VERIFY FAILED"
    exit 1
}
Write-Output "VERIFY PASSED"
exit 0
