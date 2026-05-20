Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$gamePath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR'
$bcPath   = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppBroadcast\GlobalSettings'
$dbgPath  = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR\Debug'

function Get-DVR($n, $d)   { try { (Get-ItemProperty -Path $gamePath -Name $n -EA Stop).$n } catch { $d } }
function Set-DVR($n, $v, $t) { if (-not (Test-Path $gamePath)) { New-Item -Path $gamePath | Out-Null }; Set-ItemProperty -Path $gamePath -Name $n -Value $v -Type $t }
function Get-BC($n, $d)    { try { (Get-ItemProperty -Path $bcPath -Name $n -EA Stop).$n } catch { $d } }
function Set-BC($n, $v, $t) { if (-not (Test-Path $bcPath)) { New-Item -Path $bcPath | Out-Null }; Set-ItemProperty -Path $bcPath -Name $n -Value $v -Type $t }
function Get-Dbg($n, $d)   { try { (Get-ItemProperty -Path $dbgPath -Name $n -EA Stop).$n } catch { $d } }
function Set-Dbg($n, $v, $t) { if (-not (Test-Path $dbgPath)) { New-Item -Path $dbgPath | Out-Null }; Set-ItemProperty -Path $dbgPath -Name $n -Value $v -Type $t }

# --- backup on launch ---
try {
    $ts = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $scriptDir = if ($PSCommandPath) { Split-Path $PSCommandPath -Parent } else { [Environment]::GetFolderPath('Desktop') }
    $bkDir = Join-Path $scriptDir 'reg_backups'
    if (-not (Test-Path $bkDir)) { [void](New-Item -Path $bkDir -ItemType Directory -Force) }
    $bkPath = Join-Path $bkDir ('GameDVR_Config_backup_' + $ts + '.reg')
    if (-not (Test-Path $bkPath)) {
        $reg = @"
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR]
"@
        $gp = Get-ItemProperty -Path $gamePath -ErrorAction SilentlyContinue
        if ($gp) { $gp | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -notlike 'PS*' } | ForEach-Object {
            $n = $_.Name; $v = (Get-ItemProperty -Path $gamePath).$n
            if ($v -is [int])    { $reg += "`"$n`"=dword:$($v.ToString('X8'))`r`n" }
            elseif ($v -is [long]) { $b = [BitConverter]::GetBytes($v); $reg += "`"$n`"=hex(b):$(($b|%{$_.ToString('X2')})-join',')`r`n" }
            elseif ($v -is [string]) { $reg += "`"$n`"=`"$v`"`r`n" }
        } }
        $reg += @"

[HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\AppBroadcast\GlobalSettings]
"@
        $gp = Get-ItemProperty -Path $bcPath -EA SilentlyContinue; if ($gp) { $gp | Get-Member -MemberType NoteProperty -EA SilentlyContinue | Where-Object { $_.Name -notlike 'PS*' } | ForEach-Object {
            $n = $_.Name; $v = (Get-ItemProperty -Path $bcPath).$n
            if ($v -is [int])    { $reg += "`"$n`"=dword:$($v.ToString('X8'))`r`n" }
            elseif ($v -is [long]) { $b = [BitConverter]::GetBytes($v); $reg += "`"$n`"=hex(b):$(($b|%{$_.ToString('X2')})-join',')`r`n" }
            elseif ($v -is [string]) { $reg += "`"$n`"=`"$v`"`r`n" }
        } }
        $reg += @"

[HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR\Debug]
"@
        $gp = Get-ItemProperty -Path $dbgPath -EA SilentlyContinue; if ($gp) { $gp | Get-Member -MemberType NoteProperty -EA SilentlyContinue | Where-Object { $_.Name -notlike 'PS*' } | ForEach-Object {
            $n = $_.Name; $v = (Get-ItemProperty -Path $dbgPath).$n
            if ($v -is [int])    { $reg += "`"$n`"=dword:$($v.ToString('X8'))`r`n" }
            elseif ($v -is [long]) { $b = [BitConverter]::GetBytes($v); $reg += "`"$n`"=hex(b):$(($b|%{$_.ToString('X2')})-join',')`r`n" }
            elseif ($v -is [string]) { $reg += "`"$n`"=`"$v`"`r`n" }
        } }
        [System.IO.File]::WriteAllText($bkPath, $reg)
    }
} catch {}

# --- styles ---
$bg  = [System.Drawing.Color]::FromArgb(45,45,48)
$pnl = [System.Drawing.Color]::FromArgb(55,55,60)
$fg  = [System.Drawing.Color]::WhiteSmoke
$inp = [System.Drawing.Color]::FromArgb(66,66,66)
$acc = [System.Drawing.Color]::FromArgb(0,120,215)
$grn = [System.Drawing.Color]::FromArgb(0,128,0)
$fn  = New-Object System.Drawing.Font('Segoe UI',10)
$fnH = New-Object System.Drawing.Font('Segoe UI',12,[System.Drawing.FontStyle]::Bold)

# --- form ---
$f = New-Object System.Windows.Forms.Form
$f.Text = 'Game DVR Config'
$f.ClientSize = New-Object System.Drawing.Size(760,540)
$f.StartPosition = 'CenterScreen'
$f.BackColor = $bg; $f.ForeColor = $fg; $f.Font = $fn
$f.FormBorderStyle = 'FixedSingle'; $f.MaximizeBox = $false

$tab = New-Object System.Windows.Forms.TabControl; $tab.Dock = 'Fill'; $tab.Font = $fn
$f.Controls.Add($tab)

# --- helpers ---
function New-Tab($t) {
    $p = New-Object System.Windows.Forms.TabPage
    $p.Text = $t; $p.BackColor = $bg; $p.AutoScroll = $true
    $tab.Controls.Add($p); return $p
}
function New-Section($tab, $title, $y, $w) {
    $h = New-Object System.Windows.Forms.Label
    $h.Text = $title; $h.Font = $fnH; $h.ForeColor = $acc
    $h.AutoSize = $true; $h.Location = New-Object System.Drawing.Point(12,$y)
    $tab.Controls.Add($h)
    $p = New-Object System.Windows.Forms.Panel
    $p.BackColor = $pnl
    $p.Location = New-Object System.Drawing.Point(12,($y+26))
    $p.Width = $w; $p.Height = 160
    $tab.Controls.Add($p)
    return @{ Panel=$p; Y=8 }
}
function Chk($s, $text) {
    $c = New-Object System.Windows.Forms.CheckBox
    $c.Text = $text; $c.ForeColor = $fg; $c.Font = $fn; $c.FlatStyle = 'Flat'; $c.AutoSize = $true
    $c.Location = New-Object System.Drawing.Point(10, $s.Y)
    $s.Panel.Controls.Add($c); $s.Y += 28; return $c
}
function Drp($s, $label, $items) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $label; $l.ForeColor = $fg; $l.Font = $fn; $l.AutoSize = $true
    $l.Location = New-Object System.Drawing.Point(10, ($s.Y+4))
    $s.Panel.Controls.Add($l)
    $cb = New-Object System.Windows.Forms.ComboBox
    $cb.Font = $fn; $cb.BackColor = $inp; $cb.ForeColor = $fg
    $cb.DropDownStyle = 'DropDownList'; $cb.FlatStyle = 'Flat'; $cb.Width = 140; $cb.Height = 26
    $cb.Left = $s.Panel.Width - 160; $cb.Top = $s.Y
    $s.Panel.Controls.Add($cb); $s.Y += 32
    foreach ($i in $items) { [void]$cb.Items.Add($i) }; return $cb
}
function Txt($s, $label, $default) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $label; $l.ForeColor = $fg; $l.Font = $fn; $l.AutoSize = $true
    $l.Location = New-Object System.Drawing.Point(10, ($s.Y+4))
    $s.Panel.Controls.Add($l)
    $tb = New-Object System.Windows.Forms.TextBox
    $tb.Text = $default; $tb.Font = $fn; $tb.BackColor = $inp; $tb.ForeColor = $fg
    $tb.BorderStyle = 'FixedSingle'; $tb.Width = 140; $tb.Height = 26
    $tb.Left = $s.Panel.Width - 160; $tb.Top = $s.Y
    $s.Panel.Controls.Add($tb); $s.Y += 32; return $tb
}
function Size-Section($s) { $s.Panel.Height = $s.Y + 8 }

$PW = 720

# ====================== TAB 1: Recording ======================
$t1 = New-Tab 'Recording'
$sDVR = New-Section $t1 'Game DVR' 10 $PW
$chkDVR = Chk $sDVR 'Enable Game DVR (Win+G)'
Size-Section $sDVR; $nextY = $sDVR.Panel.Bottom + 18

$sRec = New-Section $t1 'Background Recording' $nextY $PW
$chkBg  = Chk $sRec 'Record game in the background'
$txtBuf = Txt $sRec 'Record the last (seconds):' '15'
$cmbBufU = Drp $sRec 'Buffer unit:' @('seconds','megabytes')
$chkBat = Chk $sRec 'Record while on battery'
$chkWrl = Chk $sRec 'Record while using wireless display'
Size-Section $sRec

# ====================== TAB 2: Encoding ======================
$t2 = New-Tab 'Encoding'
$sBr = New-Section $t2 'Bitrate' 10 $PW
$cmbABr = Drp $sBr 'Audio bitrate:' @('96','128','160','192')
$txtVBr = Txt $sBr 'Video bitrate (kbps):' '4000'
Size-Section $sBr; $nextY = $sBr.Panel.Bottom + 18

$sVid = New-Section $t2 'Video' $nextY $PW
$cmbFPS = Drp $sVid 'Recording frame rate:' @('30 fps','60 fps')
$chkRes = Chk $sVid 'Resize video'
$txtW   = Txt $sVid 'Width:' '1280'
$txtH   = Txt $sVid 'Height:' '720'
$chkMFT = Chk $sVid 'Force software MFT (16 FPS + VBR)'
Size-Section $sVid; $nextY = $sVid.Panel.Bottom + 18

$sEnc = New-Section $t2 'Encoding Extras' $nextY $PW
$chkOvr = Chk $sEnc 'Override hardware encoder detection'
$txtMax = Txt $sEnc 'Max recording length (sec, 0=unlimited):' '0'
Size-Section $sEnc

# ====================== TAB 3: Audio & Capture ======================
$t3 = New-Tab 'Audio & Capture'
$sAud = New-Section $t3 'Audio' 10 $PW
$chkAud = Chk $sAud 'Enable audio capture'
$chkMic = Chk $sAud 'Enable microphone capture'
$chkEco = Chk $sAud 'Echo cancellation'
$chkPAA = Chk $sAud 'Enable per-app audio'
Size-Section $sAud; $nextY = $sAud.Panel.Bottom + 18

$sGain = New-Section $t3 'Audio Gains' $nextY $PW
$txtSysGain = Txt $sGain 'System volume gain (%):' '100'
$txtMicGain = Txt $sGain 'Microphone gain (%):' '100'
Size-Section $sGain; $nextY = $sGain.Panel.Bottom + 18

$sCur = New-Section $t3 'Cursor' $nextY $PW
$chkCBl = Chk $sCur 'Disable cursor blending'
$chkCCp = Chk $sCur 'Enable cursor capture'
Size-Section $sCur; $nextY = $sCur.Panel.Bottom + 18

$sCam = New-Section $t3 'Camera Overlay' $nextY $PW
$chkCamDef = Chk $sCam 'Enable camera by default'
$cmbCamLoc = Drp $sCam 'Overlay position:' @('Top-Left','Top-Right','Bottom-Left','Bottom-Right','Center','Top-Center','Bottom-Center','Left-Center','Right-Center')
$cmbCamSz  = Drp $sCam 'Overlay size:' @('Small','Medium','Large')
$chkMicDef = Chk $sCam 'Microphone enabled by default'
Size-Section $sCam

# ====================== TAB 4: Debug ======================
$t4 = New-Tab 'Debug'
$sDbWarn = New-Section $t4 'Warning' 10 $PW
$lblWarn = New-Object System.Windows.Forms.Label
$lblWarn.Text = "These are undocumented Microsoft internal debug flags.`nIf these break anything, that's on you -- not the repo owner."
$lblWarn.ForeColor = [System.Drawing.Color]::Orange
$lblWarn.Font = New-Object System.Drawing.Font('Segoe UI',10,[System.Drawing.FontStyle]::Bold)
$lblWarn.AutoSize = $true
$lblWarn.Location = New-Object System.Drawing.Point(10,8)
$sDbWarn.Panel.Controls.Add($lblWarn)
$sDbWarn.Y += 50; Size-Section $sDbWarn; $nextY = $sDbWarn.Panel.Bottom + 18

$sDbg = New-Section $t4 'Debug Flags (GameDVR\Debug)' $nextY $PW
$chkTrace = Chk $sDbg 'TraceOn - enable capture trace logging'
$chkDumpCam = Chk $sDbg 'DumpCameraFramesToDisk - dump raw NV12 frames to disk (fills drive fast)'
$lblDumpPath = New-Object System.Windows.Forms.Label
$lblDumpPath.Text = '      Path: %LOCALAPPDATA%\Packages\Microsoft.XboxGameOverlay_*\LocalState\'
$lblDumpPath.ForeColor = [System.Drawing.Color]::Gray
$lblDumpPath.Font = New-Object System.Drawing.Font('Segoe UI',8)
$lblDumpPath.AutoSize = $true
$lblDumpPath.Location = New-Object System.Drawing.Point(10, $sDbg.Y)
$sDbg.Panel.Controls.Add($lblDumpPath)
$sDbg.Y += 18
$chkFrag = Chk $sDbg 'UseFragmentedMP4Writer - use fragmented MP4 writer'
$chkVerbCam = Chk $sDbg 'VerboseCameraEnumeration - verbose camera logging'
$chkDbgMode = Chk $sDbg 'InDebugMode - suppress silent abort errors'
$chkDynBr = Chk $sDbg 'EnableDynamicBitrateUpdate - live bitrate changes without restart'
Size-Section $sDbg

# ====================== TAB 5: Backup + Restore ======================
$t5 = New-Tab 'Backup + Restore'
$sBk = New-Section $t5 'Recovery' 10 $PW
$lblBk = New-Object System.Windows.Forms.Label
$lblBk.Text = "A dated .reg backup is saved on every launch.`nDouble-click any .reg file to restore, or use the buttons below."
$lblBk.ForeColor = $fg; $lblBk.Font = $fn; $lblBk.AutoSize = $true
$lblBk.Location = New-Object System.Drawing.Point(10,8)
$sBk.Panel.Controls.Add($lblBk)
$sBk.Y += 50

$btnRes = New-Object System.Windows.Forms.Button
$btnRes.Text = 'Restore from backup ...'; $btnRes.Font = $fn; $btnRes.FlatStyle = 'Flat'
$btnRes.ForeColor = [System.Drawing.Color]::White; $btnRes.BackColor = $grn
$btnRes.Size = New-Object System.Drawing.Size(180,32)
$btnRes.Location = New-Object System.Drawing.Point(10, $sBk.Y)
$sBk.Panel.Controls.Add($btnRes)

$btnDef = New-Object System.Windows.Forms.Button
$btnDef.Text = 'Restore defaults'; $btnDef.Font = $fn; $btnDef.FlatStyle = 'Flat'
$btnDef.ForeColor = [System.Drawing.Color]::White
$btnDef.BackColor = [System.Drawing.Color]::FromArgb(160,80,0)
$btnDef.Size = New-Object System.Drawing.Size(140,32)
$btnDef.Location = New-Object System.Drawing.Point(200, $sBk.Y)
$sBk.Panel.Controls.Add($btnDef)

$btnDir = New-Object System.Windows.Forms.Button
$btnDir.Text = 'Open backups folder'; $btnDir.Font = $fn; $btnDir.FlatStyle = 'Flat'
$btnDir.ForeColor = [System.Drawing.Color]::White
$btnDir.BackColor = [System.Drawing.Color]::FromArgb(80,80,80)
$btnDir.Size = New-Object System.Drawing.Size(150,32)
$btnDir.Location = New-Object System.Drawing.Point(350, $sBk.Y)
$sBk.Panel.Controls.Add($btnDir)
$sBk.Y += 40; Size-Section $sBk

# ====================== Load Registry Values ======================
$chkDVR.Checked   = (Get-DVR 'AppCaptureEnabled' 1) -eq 1
$chkBg.Checked    = (Get-DVR 'HistoricalCaptureEnabled' 0) -eq 1
$txtBuf.Text      = [string](Get-DVR 'HistoricalBufferLength' 15)
$chkBat.Checked   = (Get-DVR 'HistoricalCaptureOnBatteryAllowed' 1) -eq 1
$chkWrl.Checked   = (Get-DVR 'HistoricalCaptureOnWirelessDisplayAllowed' 1) -eq 1

$ab = Get-DVR 'AudioEncodingBitrate' 192000
$cmbABr.SelectedItem = [string]($ab/1000)
if ($cmbABr.SelectedIndex -eq -1) { $cmbABr.SelectedIndex = 3 }

$vb = Get-DVR 'CustomVideoEncodingBitrate' 4000000
$txtVBr.Text = [string]($vb/1000)

$cmbFPS.SelectedIndex = if ((Get-DVR 'VideoEncodingFrameRateMode' 0) -eq 0) { 0 } else { 1 }
$chkRes.Checked = (Get-DVR 'VideoEncodingResolutionMode' 2) -eq 0
$txtW.Text = [string](Get-DVR 'CustomVideoEncodingWidth' 1280)
$txtH.Text = [string](Get-DVR 'CustomVideoEncodingHeight' 720)
$chkMFT.Checked = (Get-DVR 'ForceSoftwareMFT' 0) -eq 1
$chkOvr.Checked = (Get-DVR 'OverrideHasHardwareEncoder' 1) -eq 1

$maxLen = [long](Get-DVR 'MaximumRecordLength' 0)
$txtMax.Text = [string]([int]($maxLen/10000000))

$bu = Get-DVR 'HistoricalBufferLengthUnit' 0
$cmbBufU.SelectedIndex = if ($bu -lt 2) { $bu } else { 0 }

$chkAud.Checked = (Get-DVR 'AudioCaptureEnabled' 1) -eq 1
$chkMic.Checked = (Get-DVR 'MicrophoneCaptureEnabled' 0) -eq 1
$chkEco.Checked = (Get-DVR 'EchoCancellationEnabled' 0) -eq 1
$chkPAA.Checked = (Get-DVR 'EnablePerAppAudio' 0) -eq 1
$sg = [long](Get-DVR 'SystemAudioGain' 10000); $txtSysGain.Text = [string]($sg/100)
$mg = [long](Get-DVR 'MicrophoneGain' 10000); $txtMicGain.Text = [string]($mg/100)
$chkCBl.Checked = (Get-DVR 'DisableCursorBlending' 0) -eq 1
$chkCCp.Checked = (Get-DVR 'CursorCaptureEnabled' 1) -eq 1

$chkCamDef.Checked = (Get-BC 'CameraCaptureEnabledByDefault' 0) -eq 1
$cl = Get-BC 'CameraOverlayLocation' 0
if ($cl -lt 0 -or $cl -gt 8) { $cl = 0 }
$cmbCamLoc.SelectedIndex = $cl
$cs = Get-BC 'CameraOverlaySize' 1
if ($cs -lt 0 -or $cs -gt 2) { $cs = 1 }
$cmbCamSz.SelectedIndex = $cs
$chkMicDef.Checked = (Get-BC 'MicrophoneCaptureEnabledByDefault' 0) -eq 1

$chkTrace.Checked   = (Get-Dbg 'TraceOn' 0) -eq 1
$chkDumpCam.Checked = (Get-Dbg 'DumpCameraFramesToDisk' 0) -eq 1
$chkFrag.Checked    = (Get-Dbg 'UseFragmentedMP4Writer' 0) -eq 1
$chkVerbCam.Checked = (Get-Dbg 'VerboseCameraEnumeration' 0) -eq 1
$chkDbgMode.Checked = (Get-Dbg 'InDebugMode' 0) -eq 1
$chkDynBr.Checked   = (Get-Dbg 'EnableDynamicBitrateUpdate' 0) -eq 1

$txtW.Enabled = $txtH.Enabled = $chkRes.Checked
$chkBat.Enabled = $chkWrl.Enabled = $txtBuf.Enabled = $cmbBufU.Enabled = $chkBg.Checked
Set-DVR 'VideoEncodingBitrateMode' 0 'DWord'

# ====================== Event Handlers ======================
$chkDVR.Add_CheckedChanged({ Set-DVR 'AppCaptureEnabled' ([int]$this.Checked) 'DWord' })
$chkBg.Add_CheckedChanged({
    Set-DVR 'HistoricalCaptureEnabled' ([int]$this.Checked) 'DWord'
    $chkBat.Enabled = $chkWrl.Enabled = $txtBuf.Enabled = $cmbBufU.Enabled = $this.Checked
})
$txtBuf.Add_TextChanged({ $s=15; try{$s=[int]$this.Text}catch{}; Set-DVR 'HistoricalBufferLength' $s 'DWord' })
$cmbBufU.Add_SelectedIndexChanged({ Set-DVR 'HistoricalBufferLengthUnit' $this.SelectedIndex 'DWord' })
$chkBat.Add_CheckedChanged({ Set-DVR 'HistoricalCaptureOnBatteryAllowed' ([int]$this.Checked) 'DWord' })
$chkWrl.Add_CheckedChanged({ Set-DVR 'HistoricalCaptureOnWirelessDisplayAllowed' ([int]$this.Checked) 'DWord' })
$cmbABr.Add_SelectedIndexChanged({ Set-DVR 'AudioEncodingBitrate' ([int]$this.SelectedItem*1000) 'DWord' })
$txtVBr.Add_TextChanged({ $v=4000000; try{$v=[int]$this.Text*1000}catch{}; if($v -gt 30000000){$v=30000000}; Set-DVR 'CustomVideoEncodingBitrate' $v 'DWord' })
$cmbFPS.Add_SelectedIndexChanged({ Set-DVR 'VideoEncodingFrameRateMode' $this.SelectedIndex 'DWord' })
$chkRes.Add_CheckedChanged({
    Set-DVR 'VideoEncodingResolutionMode' $(if($this.Checked){0}else{2}) 'DWord'
    $txtW.Enabled = $txtH.Enabled = $this.Checked
})
$txtW.Add_TextChanged({ $w=1280; try{$w=[int]$this.Text}catch{}; if($w -gt 1920){$w=1920}; Set-DVR 'CustomVideoEncodingWidth' $w 'DWord' })
$txtH.Add_TextChanged({ $h=720; try{$h=[int]$this.Text}catch{}; if($h -gt 1080){$h=1080}; Set-DVR 'CustomVideoEncodingHeight' $h 'DWord' })
$chkMFT.Add_CheckedChanged({
    Set-DVR 'ForceSoftwareMFT' ([int]$this.Checked) 'DWord'
    Set-DVR 'AllowSoftwareEncode' ([int]$this.Checked) 'DWord'
})
$chkOvr.Add_CheckedChanged({ Set-DVR 'OverrideHasHardwareEncoder' ([int]$this.Checked) 'DWord' })
$txtMax.Add_TextChanged({ $l=0L; try{$l=[long]$this.Text*10000000L}catch{}; Set-DVR 'MaximumRecordLength' $l 'QWord' })
$chkAud.Add_CheckedChanged({ Set-DVR 'AudioCaptureEnabled' ([int]$this.Checked) 'DWord' })
$chkMic.Add_CheckedChanged({ Set-DVR 'MicrophoneCaptureEnabled' ([int]$this.Checked) 'DWord' })
$chkEco.Add_CheckedChanged({ Set-DVR 'EchoCancellationEnabled' ([int]$this.Checked) 'DWord' })
$chkPAA.Add_CheckedChanged({ Set-DVR 'EnablePerAppAudio' ([int]$this.Checked) 'DWord' })
$txtSysGain.Add_TextChanged({ $g=10000; try{$g=[int]($this.Text)*100}catch{}; if($g -lt 0){$g=0}; if($g -gt 20000){$g=20000}; Set-DVR 'SystemAudioGain' ([long]$g) 'QWord' })
$txtMicGain.Add_TextChanged({ $g=10000; try{$g=[int]($this.Text)*100}catch{}; if($g -lt 0){$g=0}; if($g -gt 20000){$g=20000}; Set-DVR 'MicrophoneGain' ([long]$g) 'QWord' })
$chkCBl.Add_CheckedChanged({ Set-DVR 'DisableCursorBlending' ([int]$this.Checked) 'DWord' })
$chkCCp.Add_CheckedChanged({ Set-DVR 'CursorCaptureEnabled' ([int]$this.Checked) 'DWord' })
$chkCamDef.Add_CheckedChanged({ Set-BC 'CameraCaptureEnabledByDefault' ([int]$this.Checked) 'DWord' })
$cmbCamLoc.Add_SelectedIndexChanged({ Set-BC 'CameraOverlayLocation' $this.SelectedIndex 'DWord' })
$cmbCamSz.Add_SelectedIndexChanged({ Set-BC 'CameraOverlaySize' $this.SelectedIndex 'DWord' })
$chkMicDef.Add_CheckedChanged({ Set-BC 'MicrophoneCaptureEnabledByDefault' ([int]$this.Checked) 'DWord' })
$chkTrace.Add_CheckedChanged({ Set-Dbg 'TraceOn' ([int]$this.Checked) 'DWord' })
$chkDumpCam.Add_CheckedChanged({ Set-Dbg 'DumpCameraFramesToDisk' ([int]$this.Checked) 'DWord' })
$chkFrag.Add_CheckedChanged({ Set-Dbg 'UseFragmentedMP4Writer' ([int]$this.Checked) 'DWord' })
$chkVerbCam.Add_CheckedChanged({ Set-Dbg 'VerboseCameraEnumeration' ([int]$this.Checked) 'DWord' })
$chkDbgMode.Add_CheckedChanged({ Set-Dbg 'InDebugMode' ([int]$this.Checked) 'DWord' })
$chkDynBr.Add_CheckedChanged({ Set-Dbg 'EnableDynamicBitrateUpdate' ([int]$this.Checked) 'DWord' })

$btnRes.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = 'Registry files (*.reg)|*.reg'
    $dir = if($PSCommandPath){Join-Path (Split-Path $PSCommandPath -Parent) 'reg_backups'}else{[Environment]::GetFolderPath('Desktop')}
    $dlg.InitialDirectory = $dir
    if ($dlg.ShowDialog() -eq 'OK') {
        & regedit.exe /s $dlg.FileName
        [System.Windows.Forms.MessageBox]::Show('Registry restored. Restart to see changes.','Restored')
    }
})

$btnDef.Add_Click({
    $r = [System.Windows.Forms.MessageBox]::Show('Reset all GameDVR values to Windows defaults?','Restore Defaults','YesNo','Warning')
    if ($r -eq 'Yes') {
        Set-DVR 'AppCaptureEnabled' 1 'DWord'
        Set-DVR 'AudioCaptureEnabled' 1 'DWord'
        Set-DVR 'MicrophoneCaptureEnabled' 0 'DWord'
        Set-DVR 'AudioEncodingBitrate' 192000 'DWord'
        Set-DVR 'CustomVideoEncodingBitrate' 4000000 'DWord'
        Set-DVR 'VideoEncodingResolutionMode' 2 'DWord'
        Set-DVR 'CustomVideoEncodingWidth' 1280 'DWord'
        Set-DVR 'CustomVideoEncodingHeight' 720 'DWord'
        Set-DVR 'ForceSoftwareMFT' 0 'DWord'
        Set-DVR 'AllowSoftwareEncode' 0 'DWord'
        Set-DVR 'DisableCursorBlending' 0 'DWord'
        Set-DVR 'HistoricalCaptureEnabled' 0 'DWord'
        Set-DVR 'HistoricalBufferLength' 15 'DWord'
        Set-DVR 'HistoricalCaptureOnBatteryAllowed' 1 'DWord'
        Set-DVR 'HistoricalCaptureOnWirelessDisplayAllowed' 1 'DWord'
        Set-DVR 'VideoEncodingBitrateMode' 0 'DWord'
        Set-DVR 'VideoEncodingFrameRateMode' 0 'DWord'
        Set-DVR 'EchoCancellationEnabled' 0 'DWord'
        Set-DVR 'CursorCaptureEnabled' 1 'DWord'
        Set-DVR 'EnablePerAppAudio' 0 'DWord'
        Set-DVR 'MaximumRecordLength' 0 'QWord'
        Set-DVR 'HistoricalBufferLengthUnit' 0 'DWord'
        Set-DVR 'SystemAudioGain' 10000 'QWord'
        Set-DVR 'MicrophoneGain' 10000 'QWord'
        [System.Windows.Forms.MessageBox]::Show('Defaults restored. Restart the tool to see changes.','Done')
    }
})

$btnDir.Add_Click({
    $dir = if($PSCommandPath){Join-Path (Split-Path $PSCommandPath -Parent) 'reg_backups'}else{[Environment]::GetFolderPath('Desktop')}
    Start-Process explorer.exe $dir
})

$f.Add_Shown({ $f.Activate() })
[void]$f.ShowDialog()
