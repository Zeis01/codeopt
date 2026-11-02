$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not ([Security.Principal.WindowsPrincipal]$identity).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if ($PSCommandPath) {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    } else {
        Write-Host '  Run this script as Administrator.' -ForegroundColor Red
        [void][Console]::ReadKey($true)
    }
    exit
}

$G = @{
    TL = [string][char]0x2554; TR = [string][char]0x2557; BL = [string][char]0x255A; BR = [string][char]0x255D
    H = [string][char]0x2550; V = [string][char]0x2551; L = [string][char]0x2500
    Ptr = [string][char]0x25BA; On = [string][char]0x25A0; Full = [string][char]0x2588; Shade = [string][char]0x2591
    Up = [string][char]0x2191; Dn = [string][char]0x2193; Lf = [string][char]0x2190; Rt = [string][char]0x2192
    Dot = [string][char]0x2022; Ok = [string][char]0x2714; Tri = [string][char]0x25B2; TriD = [string][char]0x25BC
}

$script:Bg = 'Black'
$script:W = 80

function Set-Reg {
    param([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord')
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

function Disable-Svc {
    param([string[]]$Names)
    foreach ($n in $Names) {
        Stop-Service -Name $n -Force -ErrorAction SilentlyContinue
        Set-Service -Name $n -StartupType Disabled -ErrorAction SilentlyContinue
    }
}

function Disable-Tasks {
    param([string[]]$Paths)
    foreach ($p in $Paths) { schtasks.exe /Change /TN $p /Disable 2>$null | Out-Null }
}

function Remove-Apps {
    param([string[]]$Names)
    foreach ($a in $Names) {
        Get-AppxPackage -AllUsers -Name $a | Remove-AppxPackage -AllUsers
        Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $a | Remove-AppxProvisionedPackage -Online | Out-Null
    }
}

function Set-PowerValue {
    param([string]$Sub, [string]$Setting, [int]$Value)
    powercfg /setacvalueindex scheme_current $Sub $Setting $Value | Out-Null
    powercfg /setdcvalueindex scheme_current $Sub $Setting $Value | Out-Null
    powercfg /setactive scheme_current | Out-Null
}

$Tweaks = [System.Collections.Generic.List[object]]::new()
function T {
    param([string]$Cat, [string]$Name, [string]$Desc, [bool]$Rec, [scriptblock]$Do)
    $Tweaks.Add([pscustomobject]@{ Cat = $Cat; Name = $Name; Desc = $Desc; Rec = $Rec; Do = $Do; Sel = $false })
}

T 'Safety' 'Create System Restore Point' 'Creates a restore point so every change can be rolled back from System Restore.' $true {
    Enable-ComputerRestore -Drive "$env:SystemDrive\"
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore' 'SystemRestorePointCreationFrequency' 0
    Checkpoint-Computer -Description 'CodeOpt' -RestorePointType 'MODIFY_SETTINGS'
}
T 'Safety' 'Backup Registry Hives' 'Exports HKLM\SYSTEM and HKCU\Software to Documents\CodeOpt-Backup.' $false {
    $dir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) ('CodeOpt-Backup\' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    reg.exe export 'HKLM\SYSTEM\CurrentControlSet' "$dir\System.reg" /y | Out-Null
    reg.exe export 'HKCU\Software' "$dir\UserSoftware.reg" /y | Out-Null
    reg.exe export 'HKCU\Control Panel' "$dir\ControlPanel.reg" /y | Out-Null
}

T 'Power' 'Ultimate Performance Plan' 'Unlocks and activates a tuned Ultimate Performance power plan.' $true {
    $out = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
    $guid = [regex]::Match(($out -join ' '), '[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}').Value
    if ($guid) {
        powercfg -changename $guid 'CodeOpt Ultimate' 'Maximum performance plan by CodeOpt' | Out-Null
        powercfg -setactive $guid | Out-Null
    }
    Set-PowerValue 'SUB_PROCESSOR' 'PROCTHROTTLEMIN' 100
    Set-PowerValue 'SUB_DISK' 'DISKIDLE' 0
    Set-PowerValue 'SUB_SLEEP' 'STANDBYIDLE' 0
}
T 'Power' 'Disable Core Parking' 'Keeps all CPU cores awake to avoid wake-up latency.' $true {
    Set-PowerValue 'SUB_PROCESSOR' 'CPMINCORES' 100
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583' 'ValueMax' 0
}
T 'Power' 'Disable USB Selective Suspend' 'Prevents USB devices like mice and headsets from sleeping.' $true {
    Set-PowerValue '2a737441-1930-4402-8d77-b2bebba308a3' '48e6b7a6-50f5-4782-a5d4-53bb8f07e226' 0
}
T 'Power' 'Disable PCIe Link State Power Saving' 'Turns off ASPM so GPU and NVMe links stay at full speed.' $true {
    Set-PowerValue 'SUB_PCIEXPRESS' 'ASPM' 0
}
T 'Power' 'Disable Power Throttling' 'Stops Windows from throttling background processes.' $true {
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' 'PowerThrottlingOff' 1
}
T 'Power' 'Disable Hibernation' 'Turns off hibernation and deletes hiberfil.sys to free disk space.' $true {
    powercfg -h off | Out-Null
}
T 'Power' 'Disable Fast Startup' 'Forces a clean boot each time, fixing driver and uptime issues.' $true {
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'HiberbootEnabled' 0
}

T 'Gaming' 'Enable Game Mode' 'Lets Windows prioritize the game and pause background updates.' $true {
    Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1
    Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AllowAutoGameMode' 1
}
T 'Gaming' 'Disable Game Bar & Game DVR' 'Removes background recording and the Xbox Game Bar overlay.' $true {
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' 'AllowGameDVR' 0
    Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'UseNexusForGameBarEnabled' 0
    Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'ShowStartupPanel' 0
}
T 'Gaming' 'Disable Fullscreen Optimizations' 'Uses true exclusive fullscreen for lower input latency.' $true {
    $p = 'HKCU:\System\GameConfigStore'
    Set-Reg $p 'GameDVR_FSEBehaviorMode' 2
    Set-Reg $p 'GameDVR_FSEBehavior' 2
    Set-Reg $p 'GameDVR_HonorUserFSEBehaviorMode' 1
    Set-Reg $p 'GameDVR_DXGIHonorFSEWindowsCompatible' 1
    Set-Reg $p 'GameDVR_EFSEFeatureFlags' 0
}
T 'Gaming' 'Optimizations for Windowed Games' 'Enables flip-model presentation for borderless and windowed games.' $true {
    Set-Reg 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' 'DirectXUserGlobalSettings' 'SwapEffectUpgradeEnable=1;' 'String'
}
T 'Gaming' 'Hardware-Accelerated GPU Scheduling' 'Lets the GPU manage its own memory scheduling. Needs a supported GPU.' $false {
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2
}
T 'Gaming' 'MMCSS Game Priority' 'Raises GPU and CPU scheduling priority for games.' $true {
    $p = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'
    Set-Reg $p 'GPU Priority' 8
    Set-Reg $p 'Priority' 6
    Set-Reg $p 'Scheduling Category' 'High' 'String'
    Set-Reg $p 'SFIO Priority' 'High' 'String'
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness' 0
}
T 'Gaming' 'CPU Priority Separation' 'Short, variable quantums favoring the foreground app (0x26).' $true {
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' 'Win32PrioritySeparation' 38
}
T 'Gaming' 'Global Timer Resolution' 'Allows high timer resolution requests to apply system-wide.' $true {
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel' 'GlobalTimerResolutionRequests' 1
}
T 'Gaming' 'Disable Dynamic Tick' 'Keeps the system timer ticking at a constant rate.' $false {
    bcdedit /set disabledynamictick yes | Out-Null
}
T 'Gaming' 'Disable HPET Platform Clock' 'Removes forced HPET usage for a faster timer source.' $false {
    bcdedit /deletevalue useplatformclock | Out-Null
    bcdedit /set useplatformtick yes | Out-Null
}
T 'Gaming' 'Disable Multiplane Overlay (MPO)' 'Fixes flicker and stutter on some NVIDIA and multi-monitor setups.' $false {
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' 'OverlayTestMode' 5
}
T 'Gaming' 'Disable VBS & Memory Integrity' 'Gains FPS on some CPUs but lowers system security.' $false {
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' 'EnableVirtualizationBasedSecurity' 0
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' 'Enabled' 0
}
T 'Gaming' 'Disable NVIDIA Telemetry' 'Disables NVIDIA telemetry tasks, service and opt-in.' $true {
    Get-ScheduledTask -TaskName 'NvTmRep*' | Disable-ScheduledTask | Out-Null
    Get-ScheduledTask -TaskName 'NvTmMon*' | Disable-ScheduledTask | Out-Null
    Disable-Svc @('NvTelemetryContainer')
    Set-Reg 'HKLM:\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client' 'OptInOrOutPreference' 0
}

T 'Input' 'Disable Mouse Acceleration' 'Turns off Enhance Pointer Precision for 1:1 aim.' $true {
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0' 'String'
}
T 'Input' 'Mouse & Keyboard Data Queue' 'Lowers input buffer sizes for faster input processing.' $false {
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters' 'MouseDataQueueSize' 20
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters' 'KeyboardDataQueueSize' 20
}
T 'Input' 'Fast Keyboard Repeat' 'Shortest repeat delay and fastest repeat rate.' $true {
    Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardDelay' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardSpeed' '31' 'String'
}
T 'Input' 'Disable Sticky/Filter/Toggle Keys' 'Stops accessibility pop-ups when pressing Shift repeatedly in games.' $true {
    Set-Reg 'HKCU:\Control Panel\Accessibility\StickyKeys' 'Flags' '506' 'String'
    Set-Reg 'HKCU:\Control Panel\Accessibility\Keyboard Response' 'Flags' '122' 'String'
    Set-Reg 'HKCU:\Control Panel\Accessibility\ToggleKeys' 'Flags' '58' 'String'
}

T 'Network' "Disable Nagle's Algorithm" 'Sends small packets immediately for lower online latency.' $true {
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' | ForEach-Object {
        Set-Reg $_.PSPath 'TcpAckFrequency' 1
        Set-Reg $_.PSPath 'TCPNoDelay' 1
        Set-Reg $_.PSPath 'TcpDelAckTicks' 0
    }
}
T 'Network' 'Disable Network Throttling' 'Removes the multimedia network throttling limit.' $true {
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 0xffffffff
}
T 'Network' 'Optimize TCP Stack' 'Tunes auto-tuning, RSS, heuristics and timestamps.' $true {
    netsh int tcp set global autotuninglevel=normal | Out-Null
    netsh int tcp set global rss=enabled | Out-Null
    netsh int tcp set heuristics disabled | Out-Null
    netsh int tcp set global timestamps=disabled | Out-Null
    netsh int tcp set global initialRto=2000 | Out-Null
    netsh int tcp set global nonsackrttresiliency=disabled | Out-Null
}
T 'Network' 'Disable Adapter Power Saving' 'Stops network adapters from sleeping or reducing speed.' $true {
    Get-NetAdapter -Physical | ForEach-Object {
        Disable-NetAdapterPowerManagement -Name $_.Name -NoRestart
        Set-NetAdapterAdvancedProperty -Name $_.Name -RegistryKeyword '*EEE' -RegistryValue 0 -NoRestart
        Set-NetAdapterAdvancedProperty -Name $_.Name -RegistryKeyword 'EnableGreenEthernet' -RegistryValue 0 -NoRestart
    }
}
T 'Network' 'Disable Interrupt Moderation' 'Lower network latency at the cost of slightly more CPU usage.' $false {
    Get-NetAdapter -Physical | ForEach-Object {
        Set-NetAdapterAdvancedProperty -Name $_.Name -RegistryKeyword '*InterruptModeration' -RegistryValue 0 -NoRestart
    }
}
T 'Network' 'Disable Large Send Offload' 'Fixes latency spikes on some network drivers.' $false {
    Get-NetAdapter -Physical | ForEach-Object { Disable-NetAdapterLso -Name $_.Name -NoRestart }
}
T 'Network' 'Remove QoS Bandwidth Reserve' 'Frees the bandwidth Windows reserves for QoS.' $true {
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched' 'NonBestEffortLimit' 0
}
T 'Network' 'Disable Delivery Optimization P2P' 'Stops uploading Windows updates to other PCs.' $true {
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' 'DODownloadMode' 0
}
T 'Network' 'Set Cloudflare DNS' 'Uses 1.1.1.1 and 1.0.0.1 on active adapters.' $false {
    Get-NetAdapter -Physical | Where-Object Status -eq 'Up' | ForEach-Object {
        Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses @('1.1.1.1', '1.0.0.1')
    }
}
T 'Network' 'Flush DNS & ARP Cache' 'Clears stale DNS and ARP entries.' $true {
    ipconfig /flushdns | Out-Null
    netsh interface ip delete arpcache | Out-Null
}

T 'Privacy' 'Disable Telemetry' 'Sets telemetry to minimum and disables tracking services.' $true {
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' 'AllowTelemetry' 0
    Disable-Svc @('DiagTrack', 'dmwappushservice')
}
T 'Privacy' 'Disable Telemetry Tasks' 'Disables CEIP, Compatibility Appraiser and diagnostic tasks.' $true {
    Disable-Tasks @(
        '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser',
        '\Microsoft\Windows\Application Experience\ProgramDataUpdater',
        '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator',
        '\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip',
        '\Microsoft\Windows\Autochk\Proxy',
        '\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector',
        '\Microsoft\Windows\Feedback\Siuf\DmClient',
        '\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload'
    )
}
T 'Privacy' 'Disable Advertising ID' 'Stops apps from using your advertising ID.' $true {
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo' 'DisabledByGroupPolicy' 1
}
T 'Privacy' 'Disable Activity History' 'Stops Windows from collecting and uploading activity history.' $true {
    $p = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
    Set-Reg $p 'EnableActivityFeed' 0
    Set-Reg $p 'PublishUserActivities' 0
    Set-Reg $p 'UploadUserActivities' 0
}
T 'Privacy' 'Disable Bing in Start Search' 'Start menu search only shows local results.' $true {
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' 0
    Set-Reg 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 1
}
T 'Privacy' 'Disable Copilot & Recall' 'Turns off Windows Copilot and Recall snapshots.' $true {
    Set-Reg 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'DisableAIDataAnalysis' 1
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'AllowRecallEnablement' 0
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowCopilotButton' 0
}
T 'Privacy' 'Disable Error Reporting' 'Stops sending crash reports to Microsoft.' $true {
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting' 'Disabled' 1
    Disable-Svc @('WerSvc')
}
T 'Privacy' 'Disable Feedback Prompts' 'Never ask for Windows feedback.' $true {
    Set-Reg 'HKCU:\Software\Microsoft\Siuf\Rules' 'NumberOfSIUFInPeriod' 0
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'DoNotShowFeedbackNotifications' 1
}
T 'Privacy' 'Disable Location Tracking' 'Turns off system-wide location services.' $false {
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocation' 1
    Disable-Svc @('lfsvc')
}

T 'System' 'Performance Visual Effects' 'Disables animations while keeping smooth fonts and thumbnails.' $true {
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 3
    Set-Reg 'HKCU:\Control Panel\Desktop' 'UserPreferencesMask' ([byte[]](0x90, 0x12, 0x03, 0x80, 0x10, 0x00, 0x00, 0x00)) 'Binary'
    Set-Reg 'HKCU:\Control Panel\Desktop\WindowMetrics' 'MinAnimate' '0' 'String'
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAnimations' 0
    Set-Reg 'HKCU:\Software\Microsoft\Windows\DWM' 'EnableAeroPeek' 0
}
T 'System' 'Disable Transparency' 'Turns off acrylic and blur effects.' $false {
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0
}
T 'System' 'Disable Background Apps' 'Stops Store apps from running in the background.' $true {
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' 'GlobalUserDisabled' 1
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy' 'LetAppsRunInBackground' 2
}
T 'System' 'Remove Startup Delay' 'Launches startup apps immediately after login.' $true {
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize' 'StartupDelayInMSec' 0
}
T 'System' 'Instant Menus' 'Removes the menu show delay and speeds up shutdown.' $true {
    Set-Reg 'HKCU:\Control Panel\Desktop' 'MenuShowDelay' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Desktop' 'WaitToKillAppTimeout' '2000' 'String'
    Set-Reg 'HKCU:\Control Panel\Desktop' 'HungAppTimeout' '1000' 'String'
    Set-Reg 'HKCU:\Control Panel\Desktop' 'AutoEndTasks' '1' 'String'
}
T 'System' 'Disable Memory Compression' 'Less CPU overhead. Best with 16 GB RAM or more.' $false {
    Disable-MMAgent -MemoryCompression
}
T 'System' 'Keep Kernel in RAM' 'Prevents drivers and kernel from being paged to disk.' $false {
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'DisablePagingExecutive' 1
}
T 'System' 'Disable SysMain (Superfetch)' 'Reduces disk activity. Recommended on SSD systems.' $false {
    Disable-Svc @('SysMain')
}
T 'System' 'Disable Search Indexing' 'Stops background file indexing. Search gets slower.' $false {
    Disable-Svc @('WSearch')
}
T 'System' 'NTFS Optimizations' 'Disables last-access timestamps and 8.3 short names.' $true {
    fsutil behavior set disablelastaccess 1 | Out-Null
    fsutil behavior set disable8dot3 1 | Out-Null
}
T 'System' 'Disable Unneeded Services' 'Fax, Remote Registry, Maps, Retail Demo, Insider and others.' $true {
    Disable-Svc @('Fax', 'RemoteRegistry', 'MapsBroker', 'RetailDemo', 'WMPNetworkSvc', 'wisvc', 'WpcMonSvc')
}
T 'System' 'Disable Tips & Suggestions' 'Removes ads, suggested apps and silent app installs.' $true {
    $p = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    foreach ($n in @('SystemPaneSuggestionsEnabled', 'SilentInstalledAppsEnabled', 'SoftLandingEnabled', 'SubscribedContent-338388Enabled', 'SubscribedContent-338389Enabled', 'SubscribedContent-353694Enabled', 'SubscribedContent-353696Enabled', 'PreInstalledAppsEnabled', 'OemPreInstalledAppsEnabled')) { Set-Reg $p $n 0 }
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 1
}
T 'System' 'Disable Widgets' 'Removes the Widgets board and its background process.' $true {
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0
}
T 'System' 'Classic Context Menu' 'Restores the full right-click menu on Windows 11.' $false {
    reg.exe add 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' /f /ve | Out-Null
}
T 'System' 'Show File Extensions' 'Always shows file extensions in Explorer.' $true {
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideFileExt' 0
}
T 'System' 'Disable Edge Background Running' 'Stops Edge Startup Boost and background mode.' $true {
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'StartupBoostEnabled' 0
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'BackgroundModeEnabled' 0
}

T 'Cleanup' 'Clean Temp Files' 'Deletes user and system temporary files.' $true {
    Remove-Item -Path "$env:TEMP\*", "$env:windir\Temp\*" -Recurse -Force
}
T 'Cleanup' 'Clear Shader Caches' 'Clears DirectX, NVIDIA and AMD shader caches.' $false {
    Remove-Item -Path "$env:LOCALAPPDATA\D3DSCache\*", "$env:LOCALAPPDATA\NVIDIA\DXCache\*", "$env:LOCALAPPDATA\NVIDIA\GLCache\*", "$env:LOCALAPPDATA\AMD\DxCache\*" -Recurse -Force
}
T 'Cleanup' 'Clear Windows Update Cache' 'Removes downloaded update files.' $true {
    Stop-Service -Name wuauserv, bits -Force
    Remove-Item -Path "$env:windir\SoftwareDistribution\Download\*" -Recurse -Force
    Start-Service -Name wuauserv, bits
}
T 'Cleanup' 'Empty Recycle Bin' 'Permanently deletes everything in the Recycle Bin.' $false {
    Clear-RecycleBin -Force
}
T 'Cleanup' 'DISM Component Cleanup' 'Shrinks the WinSxS folder. Can take several minutes.' $false {
    Dism.exe /Online /Cleanup-Image /StartComponentCleanup /NoRestart | Out-Null
}

T 'Debloat' 'Remove Bloatware Apps' 'News, Weather, Solitaire, Clipchamp, Tips, Feedback Hub and more.' $false {
    Remove-Apps @(
        'Microsoft.BingNews', 'Microsoft.BingWeather', 'Microsoft.GetHelp', 'Microsoft.Getstarted',
        'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.People', 'Microsoft.WindowsFeedbackHub',
        'Microsoft.ZuneVideo', 'Microsoft.MicrosoftOfficeHub', 'Clipchamp.Clipchamp', 'Microsoft.Todos',
        'Microsoft.PowerAutomateDesktop', 'Microsoft.WindowsMaps', 'Microsoft.549981C3F5F10',
        'MicrosoftTeams', 'MSTeams', 'Microsoft.BingSearch', 'Microsoft.MixedReality.Portal', 'Microsoft.SkypeApp'
    )
}
T 'Debloat' 'Remove Xbox Apps' 'Removes Xbox app and overlays. Breaks Game Pass.' $false {
    Remove-Apps @('Microsoft.XboxApp', 'Microsoft.GamingApp', 'Microsoft.XboxGamingOverlay', 'Microsoft.XboxGameOverlay', 'Microsoft.XboxSpeechToTextOverlay')
}
T 'Debloat' 'Uninstall OneDrive' 'Removes OneDrive. Synced files stay on your PC.' $false {
    Stop-Process -Name OneDrive -Force
    $setup = "$env:SystemRoot\System32\OneDriveSetup.exe"
    if (-not (Test-Path $setup)) { $setup = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" }
    if (Test-Path $setup) { Start-Process $setup -ArgumentList '/uninstall' -Wait }
    else { winget uninstall --id Microsoft.OneDrive --silent --accept-source-agreements | Out-Null }
}

$Cats = @('Safety', 'Power', 'Gaming', 'Input', 'Network', 'Privacy', 'System', 'Cleanup', 'Debloat')

$os = ((Get-CimInstance Win32_OperatingSystem).Caption -replace 'Microsoft ', '')
$cpu = ((Get-CimInstance Win32_Processor | Select-Object -First 1).Name -replace '\s+', ' ').Trim()
if ($cpu.Length -gt 38) { $cpu = $cpu.Substring(0, 38) }
$ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)

function S { param($t, $f = 'Gray', $b = $null) @{ t = [string]$t; f = $f; b = $b } }

function Out-Line {
    param([object[]]$Seg)
    $left = $script:W
    foreach ($s in $Seg) {
        if ($left -le 0) { break }
        $t = $s.t
        if ($t.Length -gt $left) { $t = $t.Substring(0, $left) }
        $b = if ($s.b) { $s.b } else { $script:Bg }
        Write-Host $t -ForegroundColor $s.f -BackgroundColor $b -NoNewline
        $left -= $t.Length
    }
    if ($left -gt 0) { Write-Host (' ' * $left) -BackgroundColor $script:Bg -NoNewline }
    Write-Host ''
}

function Show-Banner {
    $in = 64
    $title = ' C O D E O P T '
    $sub = 'Windows Tweaks & Optimizer ' + $G.Dot + ' v2.0'
    $gap = $in - $title.Length - $sub.Length - 2
    Out-Line @((S ('  ' + $G.TL + ($G.H * $in) + $G.TR) 'Blue'))
    Out-Line @((S ('  ' + $G.V + ' ') 'Blue'), (S $title 'White' 'DarkBlue'), (S (' ' * $gap)), (S $sub 'Cyan'), (S ' '), (S $G.V 'Blue'))
    Out-Line @((S ('  ' + $G.BL + ($G.H * $in) + $G.BR) 'Blue'))
    Out-Line @((S '   OS ' 'DarkCyan'), (S $os 'White'), (S '   CPU ' 'DarkCyan'), (S $cpu 'White'), (S '   RAM ' 'DarkCyan'), (S "$ram GB" 'White'))
}

function Show-Rule { Out-Line @((S ('  ' + ($G.L * 66)) 'DarkBlue')) }

function Draw {
    param($Items, $Rows)
    [Console]::SetCursorPosition(0, 0)
    Show-Banner
    Out-Line @((S ''))
    $seg = [System.Collections.Generic.List[object]]::new()
    $seg.Add((S '  '))
    for ($k = 0; $k -lt $Cats.Count; $k++) {
        $cnt = @($Tweaks | Where-Object { $_.Cat -eq $Cats[$k] -and $_.Sel }).Count
        $label = if ($cnt -gt 0) { " $($Cats[$k]) $cnt " } else { " $($Cats[$k]) " }
        if ($k -eq $script:c) { $seg.Add((S $label 'White' 'DarkBlue')) }
        elseif ($cnt -gt 0) { $seg.Add((S $label 'Cyan')) }
        else { $seg.Add((S $label 'DarkCyan')) }
        $seg.Add((S ' '))
    }
    Out-Line $seg
    Show-Rule
    $more = $script:top -gt 0
    Out-Line @((S $(if ($more) { "    $($G.Tri) more" } else { '' }) 'DarkBlue'))
    for ($r = 0; $r -lt $Rows; $r++) {
        $j = $script:top + $r
        if ($j -lt $Items.Count) {
            $t = $Items[$j]
            $cur = ($j -eq $script:i)
            $box = if ($t.Sel) { '[' + $G.On + ']' } else { '[ ]' }
            $bf = if ($t.Sel) { 'Cyan' } else { 'DarkGray' }
            $rec = if ($t.Rec) { ' REC' } else { '' }
            if ($cur) {
                Out-Line @((S ('  ' + $G.Ptr + ' ') 'Cyan'), (S $box $bf 'DarkBlue'), (S (' ' + $t.Name.PadRight(42)) 'White' 'DarkBlue'), (S $rec 'DarkCyan'))
            } else {
                $nf = if ($t.Sel) { 'White' } else { 'Gray' }
                Out-Line @((S '    '), (S $box $bf), (S (' ' + $t.Name.PadRight(42)) $nf), (S $rec 'DarkBlue'))
            }
        } else {
            Out-Line @((S ''))
        }
    }
    $less = ($script:top + $Rows) -lt $Items.Count
    Out-Line @((S $(if ($less) { "    $($G.TriD) more" } else { '' }) 'DarkBlue'))
    Show-Rule
    $desc = if ($Items.Count) { $Items[$script:i].Desc } else { '' }
    Out-Line @((S ('  ' + [string][char]0x00BB + ' ') 'Cyan'), (S $desc 'Gray'))
    $sel = @($Tweaks | Where-Object Sel).Count
    Out-Line @((S '  Selected ' 'DarkCyan'), (S "$sel" 'White'), (S " of $($Tweaks.Count)" 'DarkCyan'), (S "   Category $($script:c + 1)/$($Cats.Count)" 'DarkCyan'))
    Out-Line @((S "  $($G.Up)$($G.Dn) " 'Cyan'), (S 'move  ' 'DarkGray'), (S "$($G.Lf)$($G.Rt) " 'Cyan'), (S 'tab  ' 'DarkGray'), (S 'Space ' 'Cyan'), (S 'toggle  ' 'DarkGray'), (S 'A ' 'Cyan'), (S 'all  ' 'DarkGray'), (S 'R ' 'Cyan'), (S 'recommended  ' 'DarkGray'), (S 'C ' 'Cyan'), (S 'clear  ' 'DarkGray'), (S 'Enter ' 'Cyan'), (S 'apply  ' 'DarkGray'), (S 'Esc ' 'Cyan'), (S 'exit' 'DarkGray'))
}

function Invoke-Apply {
    $list = @($Tweaks | Where-Object Sel)
    if ($list.Count -eq 0) { return }
    Clear-Host
    Show-Banner
    Out-Line @((S ''))
    Out-Line @((S '  Ready to apply ' 'Gray'), (S "$($list.Count)" 'White'), (S ' tweaks.  ' 'Gray'), (S 'Enter ' 'Cyan'), (S 'confirm   ' 'DarkGray'), (S 'Esc ' 'Cyan'), (S 'cancel' 'DarkGray'))
    while ($true) {
        $k = [Console]::ReadKey($true).Key
        if ($k -eq 'Escape') { Clear-Host; return }
        if ($k -eq 'Enter') { break }
    }
    Out-Line @((S ''))
    $n = $list.Count; $k = 0; $ok = 0
    foreach ($t in $list) {
        $k++
        Write-Host ('  ' + ("[$k/$n]").PadRight(8)) -ForegroundColor DarkCyan -NoNewline
        Write-Host $t.Name.PadRight(44) -ForegroundColor White -NoNewline
        try {
            & $t.Do *> $null
            Write-Host " $($G.Ok) done" -ForegroundColor Cyan
            $ok++
        } catch {
            Write-Host ' x failed' -ForegroundColor Red
        }
        $t.Sel = $false
    }
    $barW = 50
    $fill = [int][math]::Round($barW * $ok / $n)
    Write-Host ''
    Write-Host '  ' -NoNewline
    Write-Host ($G.Full * $fill) -ForegroundColor Blue -NoNewline
    Write-Host ($G.Shade * ($barW - $fill)) -ForegroundColor DarkBlue -NoNewline
    Write-Host "  $ok/$n" -ForegroundColor White
    Write-Host ''
    Write-Host '  Restart your PC to apply all changes.' -ForegroundColor Cyan
    Write-Host '  Press any key to return to the menu...' -ForegroundColor DarkGray
    [void][Console]::ReadKey($true)
    Clear-Host
}

$Host.UI.RawUI.WindowTitle = 'CodeOpt'
$Host.UI.RawUI.BackgroundColor = 'Black'
[Console]::CursorVisible = $false
Clear-Host

$script:c = 0; $script:i = 0; $script:top = 0
$lastW = 0; $lastH = 0
$run = $true

while ($run) {
    if ([Console]::WindowWidth -ne $lastW -or [Console]::WindowHeight -ne $lastH) {
        $lastW = [Console]::WindowWidth; $lastH = [Console]::WindowHeight
        $script:W = [Math]::Max(40, $lastW - 1)
        Clear-Host
    }
    $items = @($Tweaks | Where-Object { $_.Cat -eq $Cats[$script:c] })
    $rows = [Math]::Max(4, [Console]::WindowHeight - 17)
    if ($script:i -ge $items.Count) { $script:i = [Math]::Max(0, $items.Count - 1) }
    if ($script:i -lt $script:top) { $script:top = $script:i }
    if ($script:i -ge $script:top + $rows) { $script:top = $script:i - $rows + 1 }
    Draw $items $rows
    $key = [Console]::ReadKey($true)
    switch ($key.Key) {
        'UpArrow' { $script:i = ($script:i - 1 + $items.Count) % $items.Count }
        'DownArrow' { $script:i = ($script:i + 1) % $items.Count }
        'LeftArrow' { $script:c = ($script:c - 1 + $Cats.Count) % $Cats.Count; $script:i = 0; $script:top = 0 }
        'RightArrow' { $script:c = ($script:c + 1) % $Cats.Count; $script:i = 0; $script:top = 0 }
        'Tab' { $script:c = ($script:c + 1) % $Cats.Count; $script:i = 0; $script:top = 0 }
        'Home' { $script:i = 0 }
        'End' { $script:i = $items.Count - 1 }
        'Spacebar' { $items[$script:i].Sel = -not $items[$script:i].Sel }
        'A' {
            $all = @($items | Where-Object { -not $_.Sel }).Count -eq 0
            foreach ($t in $items) { $t.Sel = -not $all }
        }
        'R' { foreach ($t in $Tweaks) { $t.Sel = $t.Rec } }
        'C' { foreach ($t in $Tweaks) { $t.Sel = $false } }
        'Enter' { Invoke-Apply; $lastW = 0 }
        'Escape' { $run = $false }
        'Q' { $run = $false }
    }
}

[Console]::CursorVisible = $true
[Console]::ResetColor()
Clear-Host
Write-Host ''
Write-Host '  CodeOpt closed. Restart to apply all changes.' -ForegroundColor Cyan
Write-Host ''
