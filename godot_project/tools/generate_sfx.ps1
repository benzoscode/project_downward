# 生成占位音效（WAV 16-bit 单声道 22050Hz，短促、音量低调、贴合地底幽暗氛围）
# 用法（godot_project/ 下）：powershell -ExecutionPolicy Bypass -File tools/generate_sfx.ps1
# 未来替换：同名同格式覆盖 assets/audio/sfx/*.wav 即可，代码零改动。
$ErrorActionPreference = "Stop"
$SR = 22050
$out = "C:\projects\gamejam\project_downward\godot_project\assets\audio\sfx"
New-Item -ItemType Directory -Path $out -Force | Out-Null

function Bytes([string]$s) { return [System.Text.Encoding]::ASCII.GetBytes($s) }
function Write-Wav([string]$name, [double[]]$s) {
    $n = $s.Length
    $data = New-Object byte[] (44 + $n * 2)
    # RIFF header
    [Array]::Copy((Bytes "RIFF"), 0, $data, 0, 4)
    [BitConverter]::GetBytes([int](36 + $n * 2)).CopyTo($data, 4)
    [Array]::Copy((Bytes "WAVE"), 0, $data, 8, 4)
    [Array]::Copy((Bytes "fmt "), 0, $data, 12, 4)
    [BitConverter]::GetBytes([int]16).CopyTo($data, 16)
    [BitConverter]::GetBytes([int16]1).CopyTo($data, 20)
    [BitConverter]::GetBytes([int16]1).CopyTo($data, 22)
    [BitConverter]::GetBytes([int]$SR).CopyTo($data, 24)
    [BitConverter]::GetBytes([int]($SR * 2)).CopyTo($data, 28)
    [BitConverter]::GetBytes([int16]2).CopyTo($data, 32)
    [BitConverter]::GetBytes([int16]16).CopyTo($data, 34)
    [Array]::Copy((Bytes "data"), 0, $data, 36, 4)
    [BitConverter]::GetBytes([int]($n * 2)).CopyTo($data, 40)
    for ($i = 0; $i -lt $n; $i++) {
        $v = $s[$i]
        if ($v -gt 1) { $v = 1 } elseif ($v -lt -1) { $v = -1 }
        [BitConverter]::GetBytes([int16]([int]($v * 32767))).CopyTo($data, 44 + $i * 2)
    }
    [System.IO.File]::WriteAllBytes((Join-Path $out $name), $data)
}

function New-Tone([double]$duration, [double]$freq, [double]$vol, [int]$shape, [double]$decay, [int]$freqEnd) {
    $n = [int]($SR * $duration)
    $s = New-Object double[] $n
    $phaseInc = 2.0 * [Math]::PI * $freq / $SR
    $phaseIncEnd = 2.0 * [Math]::PI * $freqEnd / $SR
    $phase = 0.0
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / $n
        $inc = $phaseInc + ($phaseIncEnd - $phaseInc) * $t
        $phase += $inc
        $w = 0.0
        if ($shape -eq 0) { $w = [Math]::Sin($phase) }                # sine
        elseif ($shape -eq 1) { $w = [Math]::Sin($phase) + 0.3 * [Math]::Sin(2 * $phase) } # 带泛音
        else { $w = [Math]::Sign([Math]::Sin($phase)) * 0.6 }         # 方波
        $env = [Math]::Exp(-$t * $decay)
        $fade = if ($t -gt 0.85) { (1 - $t) / 0.15 } else { 1.0 }
        $s[$i] = $w * $vol * $env * $fade
    }
    return $s
}

# —— 逐一生成，音量 0.15~0.35，避免喧宾夺主 ——
Write-Wav "jump.wav"        (New-Tone 0.18 420 0.28 1 5.0 0)
Write-Wav "double_jump.wav" (New-Tone 0.20 620 0.28 1 5.0 0)
Write-Wav "land.wav"        (New-Tone 0.10 110 0.22 2 9.0 0)
Write-Wav "lamp_on.wav"     (New-Tone 0.16 760 0.20 1 6.0 0)
Write-Wav "lamp_off.wav"    (New-Tone 0.14 520 0.20 1 6.0 0)
Write-Wav "whistle.wav"     (New-Tone 0.34 1400 0.20 0 4.0 0)
Write-Wav "switch_control.wav" (New-Tone 0.12 880 0.18 1 7.0 0)
Write-Wav "interact.wav"    (New-Tone 0.08 500 0.20 2 10.0 0)
Write-Wav "door_open.wav"   (New-Tone 0.42 150 0.26 1 3.0 0)
Write-Wav "door_close.wav"  (New-Tone 0.34 120 0.22 1 3.5 0)
Write-Wav "pickup.wav"      (New-Tone 0.16 900 0.26 1 5.0 0)
Write-Wav "chest_open.wav"  (New-Tone 0.30 260 0.24 1 4.0 0)
Write-Wav "plate_press.wav" (New-Tone 0.09 340 0.18 2 10.0 0)
Write-Wav "crystal_activate.wav" (New-Tone 0.40 660 0.24 0 3.0 0)
Write-Wav "orb_launch.wav"  (New-Tone 0.20 300 0.22 1 5.0 0)
Write-Wav "gem_embed.wav"   (New-Tone 0.20 220 0.30 2 6.0 0)
Write-Wav "gate_open.wav"   (New-Tone 0.60 90 0.28 1 2.5 0)
Write-Wav "checkpoint.wav"  (New-Tone 0.30 760 0.22 1 3.5 0)
Write-Wav "boss_roar.wav"   (New-Tone 0.50 110 0.34 1 3.0 0)
Write-Wav "player_die.wav"  (New-Tone 0.45 300 0.30 1 4.0 120)
Write-Wav "lever.wav"       (New-Tone 0.22 180 0.22 1 5.0 0)

Write-Output ("生成完成: " + $out)
(Get-ChildItem $out -Filter *.wav).Count
