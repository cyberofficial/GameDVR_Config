# Game DVR Config

> **PowerShell Edition is the current version. The C# edition is kept for legacy purposes and is being phased out.**

Configuration tool for Windows Game DVR (Xbox Game Bar) recording settings.
Fork of [FunkyFr3sh/GameDVR_Config](https://github.com/FunkyFr3sh/GameDVR_Config).

Available as both a C# WinForms app and a **PowerShell script** (no compilation needed).

## PowerShell Edition (Recommended)

`GameDVR_Config.ps1` - single portable script, no install required.

### How to Run

Right-click `GameDVR_Config.ps1` -> Run with PowerShell

If blocked by execution policy:
```powershell
powershell -ExecutionPolicy Bypass -File GameDVR_Config.ps1
```

### Features (5 Tabs)

| Tab | Settings |
|-----|----------|
| **Recording** | Game DVR on/off, background recording, buffer length, battery/wireless recording |
| **Encoding** | Audio/video bitrate, resolution, 30/60 fps, Force Software MFT, override HW encoder detection |
| **Audio & Capture** | Audio/mic capture, echo cancellation, per-app audio, system/mic gain (%), cursor settings, camera overlay position/size |
| **Debug** | Undocumented MS internal flags (with warning) |
| **Backup + Restore** | Auto-backup on launch, restore from backup, reset to Windows defaults |

### Auto-Backup

Every launch saves all registry keys to `reg_backups\GameDVR_Config_backup_YYYY-MM-DD_HH-MM-SS.reg`.

### All Configurable Values

Over 25 registry values found via reverse engineering `bcastdvruserservice.dll` (Windows 11 build 22000.1):

- AppCaptureEnabled, AudioCaptureEnabled, MicrophoneCaptureEnabled
- AudioEncodingBitrate, CustomVideoEncodingBitrate
- VideoEncodingResolutionMode, VideoEncodingFrameRateMode
- CustomVideoEncodingWidth, CustomVideoEncodingHeight
- ForceSoftwareMFT, AllowSoftwareEncode, OverrideHasHardwareEncoder
- HistoricalCaptureEnabled, HistoricalBufferLength, HistoricalBufferLengthUnit
- HistoricalCaptureOnBatteryAllowed, HistoricalCaptureOnWirelessDisplayAllowed
- MaximumRecordLength, VideoEncodingBitrateMode
- EchoCancellationEnabled, CursorCaptureEnabled, EnablePerAppAudio, DisableCursorBlending
- SystemAudioGain, MicrophoneGain
- CameraCaptureEnabledByDefault, CameraOverlayLocation, CameraOverlaySize
- MicrophoneCaptureEnabledByDefault

## C# Edition (Deprecated)

Original WinForms app (.NET Framework 4.8). Lacks the newer registry values found via reverse engineering. Being phased out in favor of the PowerShell edition.

## Help

To change keybinds, press `Win+I` -> Gaming -> Game Bar.

## Support

Open an [issue](https://github.com/cyberofficial/GameDVR_Config/issues).