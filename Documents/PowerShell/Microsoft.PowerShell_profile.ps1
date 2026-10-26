# ===== 인코딩 =====
[Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# ===== 편집기 =====
if (-not $env:EDITOR) { $env:EDITOR = if (Get-Command vim -ErrorAction Ignore) { 'vim' } else { 'notepad' } }
$env:VISUAL = $env:EDITOR

# ===== 키 바인딩 / 히스토리 (zsh 설정과 맞춤) =====
Set-PSReadLineOption -EditMode Emacs -HistoryNoDuplicates -BellStyle None
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward     # 위 화살표: 접두어 히스토리 검색
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward    # 아래 화살표: 접두어 히스토리 검색
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# ===== 별칭: 파일 목록 =====
function ll { Get-ChildItem -Force @args }
function la { Get-ChildItem -Force @args }
function lt { Get-ChildItem -Force @args | Sort-Object LastWriteTime -Descending }   # 최근 수정순 정렬

# ===== 별칭: 디렉터리 이동 =====
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }

# ===== 별칭: 기타 =====
Set-Alias cls Clear-Host -Option AllScope -Force
function path { $env:Path -split ';' }               # PATH를 한 줄씩 출력
function reload { & pwsh -NoLogo; exit }             # pwsh 재시작
function profileconfig { & $env:EDITOR $PROFILE }

# ===== Starship 프롬프트 =====
Invoke-Expression (&starship init powershell)
