# 机制断言验证：运行 tools/verify/ 下的验证脚本，出现 [FAIL] 即失败。
# 用法（godot_project/ 下）：powershell -File tools/run_verify.ps1
param(
    [string[]]$VerifyScripts = @("tools/verify/verify_player.gd", "tools/verify/verify_camera.gd")
)

$Godot = "C:\softwares\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe"
$failed = $false
foreach ($script in $VerifyScripts) {
    Write-Output "== $script =="
    $out = & $Godot --headless --script $script 2>&1 | Out-String
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
