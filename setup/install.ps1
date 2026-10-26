# Windows 11 개발환경 설치 스크립트 (win-4090-dt)
# scoop 우선, scoop에 없는 것만 winget. 일반 권한 PowerShell에서 실행 (scoop은 관리자 실행을 거부함)
# 관리자 권한이 필요한 구간은 UAC로 따로 띄움. 멱등성 유지 — 중단 후 재실행 가능
#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

# ===== 유틸 =====
function Log($msg)  { Write-Host "[*] $msg" -ForegroundColor Blue }
function Warn($msg) { Write-Host "[!] $msg" -ForegroundColor Yellow }
function Refresh-Env {
    # 설치 직후 새 PATH·환경 변수를 현재 세션에 반영
    foreach ($k in [Environment]::GetEnvironmentVariables('User').Keys) {
        if ($k -ne 'Path') { Set-Item "env:$k" ([Environment]::GetEnvironmentVariable($k, 'User')) }
    }
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'User') + ';' + [Environment]::GetEnvironmentVariable('Path', 'Machine')
}

# ===== scoop =====
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Log "scoop 설치"
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
    Refresh-Env
} else {
    Log "scoop 이미 설치됨 — 건너뜀"
}

# SSH 세션은 scoop의 apps\<앱>\current 링크 폴더(junction)를 따라가지 못함.
# shim·PATH가 버전 경로를 직접 가리키도록 설정 (앱 설치 전에 켜야 함)
scoop config no_junction true | Out-Null

# 버킷 추가에 git이 필요
scoop install git 7zip

$buckets = @('extras', 'java', 'nerd-fonts')
$existing = (scoop bucket list | ForEach-Object { $_.Name })
foreach ($b in $buckets) {
    if ($existing -notcontains $b) { Log "버킷 추가: $b"; scoop bucket add $b }
}

# ===== scoop 앱 =====
$apps = @(
    # 셸·기본 CLI
    'pwsh', 'starship', 'git-lfs', 'gh', 'chezmoi', '1password-cli', 'innounp', 'dark',
    # 런타임 매니저
    'uv', 'nvm',
    # 폰트 (scoop 이름은 D2Coding이지만 실제 패밀리명은 D2Koding)
    'nerd-fonts/D2Coding-NF', 'nerd-fonts/D2Coding-NF-Mono',
    # 개발 부가 도구
    'rust', 'openjdk25', 'postgresql', 'cloudflared', 'rclone',
    # 에디터·분석
    'zed', 'dnspyex', 'ilspy',
    # 일반 앱
    'powertoys', 'blender', 'obs-studio', 'imageglass', 'calibre', 'omegat'
)
$installed = (scoop export | ConvertFrom-Json).apps.Name
$todo = $apps | Where-Object { $installed -notcontains ($_ -split '/')[-1] }
if ($todo) { Log "scoop 앱 설치: $($todo -join ', ')"; scoop install @todo } else { Log "scoop 앱 모두 설치됨 — 건너뜀" }
Refresh-Env

# ===== Python (uv) =====
Log "Python 3.13 (uv) 설치 + 전역 기본값 지정"
uv python install 3.13 --default
uv python pin --global 3.13

# ===== Node (nvm-windows) =====
if (-not (nvm list 2>$null | Select-String '\d+\.\d+\.\d+')) {
    Log "Node LTS (nvm) 설치"
    nvm install lts
    nvm use lts
} else {
    Log "Node 이미 설치됨 — 건너뜀"
}

# ===== 관리자 권한 구간 =====
# - winget: 1Password, Epic Games Launcher, Visual Studio 2026 (UE 5.8 구성 요소)
# - 빠른 시작/최대 절전 끄기 (켜져 있으면 Linux에서 D:가 읽기 전용으로 마운트됨)
# - 개발자 모드, OpenSSH 서버 + 기본 셸 pwsh
$pwshShim = Join-Path $env:USERPROFILE 'scoop\shims\pwsh.exe'
$admin = @"
`$ErrorActionPreference = 'Continue'
foreach (`$id in 'AgileBits.1Password', 'EpicGames.EpicGamesLauncher') {
    winget install --id `$id --source winget --accept-package-agreements --accept-source-agreements --silent
}
# UE 5.8 Engine\Config\Windows\Windows_SDK.json의 VisualStudioSuggestedComponents 기준
# (VC.14.50.18.0 구성 요소는 UE가 차단한 14.50.35717을 설치하므로 제외)
winget install --id Microsoft.VisualStudio.Community --source winget --accept-package-agreements --accept-source-agreements --override '--wait --passive --norestart --add Microsoft.VisualStudio.Workload.NativeGame --add Microsoft.VisualStudio.Workload.NativeDesktop --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows11SDK.26100 --add Microsoft.Net.Component.4.6.2.TargetingPack --add Microsoft.VisualStudio.Component.VC.Llvm.Clang --add Component.Unreal.Ide --add Component.Unreal.Debugger --includeRecommended'

powercfg /h off
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name HiberbootEnabled -Value 0 -Type DWord

`$k = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
if (-not (Test-Path `$k)) { New-Item `$k -Force | Out-Null }
Set-ItemProperty `$k -Name AllowDevelopmentWithoutDevLicense -Value 1 -Type DWord

Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Out-Null
Set-Service sshd -StartupType Automatic
Start-Service sshd
if (-not (Test-Path HKLM:\SOFTWARE\OpenSSH)) { New-Item HKLM:\SOFTWARE\OpenSSH -Force | Out-Null }
Set-ItemProperty HKLM:\SOFTWARE\OpenSSH -Name DefaultShell -Value '$pwshShim' -Type String
"@
Log "관리자 권한 구간 실행 (UAC 승인 필요)"
$enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($admin))
Start-Process powershell.exe -Verb RunAs -Wait -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $enc"

# ===== 마무리 =====
Write-Host @"

===============================================
설치 완료. 다음 단계를 수동으로 진행하세요:

1. dotfiles 적용 (pwsh 프로필, starship, Windows Terminal, .gitconfig):
     chezmoi init --apply git@github.com:myjung/dotfiles.git

2. 1Password 앱 로그인 → 설정 > 개발자에서
   'SSH agent 사용'과 'CLI 연동'을 켜고 gh 로그인:
     gh auth login

3. sshd 접속 키 등록 (관리자 PowerShell, 키는 1Password에서 생성):
     op read "op://Personal/<항목>/public key" >> C:\ProgramData\ssh\administrators_authorized_keys
   파일 권한은 SYSTEM·Administrators만 (setup/README.md 참고)

4. OBS 가상 카메라 등록·Spout 플러그인 설치 (setup/README.md 참고)

5. 재부팅 (Visual Studio 설치 마무리)
===============================================
"@
