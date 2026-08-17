# kmh-agent-kit installer (Windows) — install.sh의 Windows 대응판.
#
# Windows 제약에 맞춘 차이:
#   - POSIX 심링크 생성은 관리자 권한 또는 개발자 모드가 필요하므로,
#     디렉토리는 junction, 파일은 하드링크로 연결한다 (둘 다 권한 불필요, 편집 시 레포 작업트리가 바뀌는 효과는 동일).
#   - git이 core.symlinks=false로 체크아웃한 프로필 항목(대상 경로만 담긴 일반 파일)도 링크로 해석한다.
#   - GBrain 런타임(bash 래퍼·systemd 유닛)과 ~/.bashrc 별칭은 Windows에 해당 없어 건너뛴다.
#
# usage:
#   .\install.ps1                                        # 전역 연결 (claude + codex)
#   .\install.ps1 -Project <경로> -ProfileName <프로필명>  # 프로젝트 프로필 연결
#   .\install.ps1 -Gbrain <에이전트>                       # GBrain 카드 연결 (예: main, rndlog, judy)

[CmdletBinding()]
param(
    [string]$Project,
    [string]$ProfileName,
    [string]$Gbrain
)

$ErrorActionPreference = 'Stop'

# PowerShell 5.1 콘솔은 기본 코드페이지가 CP949라 한글 출력이 깨진다.
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

$repoDir    = $PSScriptRoot
$homeDir    = $env:USERPROFILE
$claudeHome = if ($env:CLAUDE_HOME) { $env:CLAUDE_HOME } else { Join-Path $homeDir '.claude' }
$codexHome  = if ($env:CODEX_HOME)  { $env:CODEX_HOME }  else { Join-Path $homeDir '.codex' }
$agentsHome = Join-Path $homeDir '.agents'
$stamp      = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = Join-Path $homeDir ".kmh-agent-kit-backup-$stamp"

function Backup-Entry {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $backupRoot)) { New-Item -ItemType Directory -Path $backupRoot | Out-Null }
    # -Project 대상은 홈 밖일 수 있으므로 홈 기준 상대화가 항상 성립하지는 않는다.
    $flat = if ($Path.StartsWith($homeDir, 'OrdinalIgnoreCase')) { $Path.Substring($homeDir.Length) } else { $Path -replace '^[A-Za-z]:', '' }
    $flat = $flat.TrimStart('\').Replace('\', '_')
    Move-Item -LiteralPath $Path -Destination (Join-Path $backupRoot $flat) -Force
    Write-Host "  backup: $Path"
}

# 프로필 항목(심링크 또는 대상 경로만 담긴 일반 파일)이 가리키는 실제 원본 경로.
# scripts/check-skill-deps.py의 read_profile_link()와 같은 규칙을 쓴다.
function Resolve-ProfileTarget {
    param([string]$Entry)

    $item = Get-Item -LiteralPath $Entry -Force
    if ($item.PSIsContainer) { return $item.FullName }              # 심링크가 실체화된 clone
    if ($item.LinkType) { return (Resolve-Path -LiteralPath $item.Target[0]).Path }

    if ($item.Length -ge 4096) { return $null }
    $text = (Get-Content -LiteralPath $Entry -Raw -Encoding UTF8).Trim()
    if (-not $text -or $text.Contains("`n") -or -not $text.StartsWith('..')) { return $null }

    $resolved = Join-Path (Split-Path $Entry -Parent) $text
    if (Test-Path -LiteralPath $resolved) { return (Resolve-Path -LiteralPath $resolved).Path }
    return $null
}

# 디렉토리 → junction, 파일 → 하드링크. 이미 올바르게 연결돼 있으면 그대로 둔다.
function Link-Entry {
    param([string]$Target, [string]$Link)

    $targetIsDir = (Get-Item -LiteralPath $Target -Force).PSIsContainer

    if (Test-Path -LiteralPath $Link) {
        $existing = Get-Item -LiteralPath $Link -Force
        if ($existing.LinkType -eq 'Junction' -and $existing.Target -and
            ($existing.Target[0]).TrimEnd('\') -eq $Target.TrimEnd('\')) { return }
        if (-not $existing.PSIsContainer -and -not $targetIsDir) {
            # 하드링크는 원본과 구별되지 않으므로 내용 동일성으로 판단한다.
            if ((Get-FileHash -LiteralPath $Link).Hash -eq (Get-FileHash -LiteralPath $Target).Hash) { return }
        }
        # junction 삭제는 Remove-Item 대신 Directory.Delete로 — 대상 내용까지 지우지 않는다.
        if ($existing.LinkType -eq 'Junction') { [System.IO.Directory]::Delete($Link) }
        else { Backup-Entry -Path $Link }
    }

    $parent = Split-Path $Link -Parent
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }

    $type = if ($targetIsDir) { 'Junction' } else { 'HardLink' }
    New-Item -ItemType $type -Path $Link -Target $Target | Out-Null
    Write-Host "  $type  $Link -> $Target"
}

# 프로필의 모든 항목을 live 디렉토리에 연결하고,
# 프로필에서 사라진 스킬을 가리키는 junction은 정리한다(스킬 삭제의 pull 전파).
function Link-Profile {
    param([string]$Profile, [string]$Live)

    if (-not (Test-Path -LiteralPath $Profile)) { return }
    if (-not (Test-Path -LiteralPath $Live)) { New-Item -ItemType Directory -Path $Live -Force | Out-Null }

    $linked = @{}
    foreach ($entry in Get-ChildItem -LiteralPath $Profile -Force) {
        $target = Resolve-ProfileTarget -Entry $entry.FullName
        if (-not $target) { Write-Warning "  skip (대상 해석 실패): $($entry.Name)"; continue }
        Link-Entry -Target $target -Link (Join-Path $Live $entry.Name)
        $linked[$entry.Name] = $true
    }

    $skillsRoot = (Join-Path $repoDir 'skills').TrimEnd('\')
    foreach ($liveEntry in Get-ChildItem -LiteralPath $Live -Force) {
        if ($liveEntry.LinkType -ne 'Junction' -or $linked.ContainsKey($liveEntry.Name)) { continue }
        if ($liveEntry.Target -and ($liveEntry.Target[0]).StartsWith($skillsRoot, 'OrdinalIgnoreCase')) {
            [System.IO.Directory]::Delete($liveEntry.FullName)
            Write-Host "  remove stale: $($liveEntry.FullName)"
        }
    }
}

function Remove-KitSkillLinks {
    param([string]$Live)

    if (-not (Test-Path -LiteralPath $Live)) { return }
    $skillsRoot = (Join-Path $repoDir 'skills').TrimEnd('\')
    foreach ($entry in Get-ChildItem -LiteralPath $Live -Force) {
        if ($entry.LinkType -ne 'Junction' -or -not $entry.Target) { continue }
        if (($entry.Target[0]).StartsWith($skillsRoot, 'OrdinalIgnoreCase')) {
            [System.IO.Directory]::Delete($entry.FullName)
            Write-Host "  remove legacy Codex user skill: $($entry.FullName)"
        }
    }
}

# python3.exe가 Microsoft Store 리디렉션 stub이면 실행 시 스토어가 열리므로 제외한다.
function Get-Python {
    foreach ($name in 'python', 'python3', 'py') {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd -and $cmd.Source -and $cmd.Source -notmatch '\\WindowsApps\\') { return $cmd.Source }
    }
    return $null
}

# ── GBrain 카드 연결 ────────────────────────────────────────────────────
if ($Gbrain) {
    $card = Join-Path $repoDir "gbrain-cards\$Gbrain.md"
    if (-not (Test-Path -LiteralPath $card)) { throw "[error] 카드 없음: $card" }
    Link-Entry -Target $card -Link (Join-Path $homeDir '.gbrain-agent.md')
    Write-Host "gbrain card '$Gbrain' -> ~\.gbrain-agent.md"
    # SSH 프록시 래퍼(gbrain-remote-proxy)는 bash 스크립트라 Windows에서 링크하지 않는다.
    if (Test-Path -LiteralPath $backupRoot) { Write-Host "기존 파일 백업: $backupRoot" }
    exit 0
}

# ── 프로젝트 프로필 연결 ────────────────────────────────────────────────
if ($Project) {
    if (-not $ProfileName) { throw "usage: .\install.ps1 -Project <경로> -ProfileName <프로필명>" }
    $profileDir = Join-Path $repoDir "projects\$ProfileName"
    if (-not (Test-Path -LiteralPath $profileDir)) { throw "[error] 프로젝트 프로필 없음: $profileDir" }
    if (-not (Test-Path -LiteralPath $Project))    { throw "[error] 프로젝트 경로 없음: $Project" }

    Remove-KitSkillLinks -Live "$Project\.codex\skills"
    if (Test-Path -LiteralPath "$profileDir\skills") {
        Link-Profile -Profile "$profileDir\skills" -Live "$Project\.claude\skills"
        Link-Profile -Profile "$profileDir\skills" -Live "$Project\.agents\skills"
    }
    foreach ($f in 'CLAUDE.md', 'AGENTS.md') {
        if (Test-Path -LiteralPath "$profileDir\$f") { Link-Entry -Target "$profileDir\$f" -Link "$Project\$f" }
    }
    Write-Host "project '$ProfileName' linked into $Project"
    if (Test-Path -LiteralPath $backupRoot) { Write-Host "기존 파일 백업: $backupRoot" }
    exit 0
}

# ── 전역 설치: 스킬 프로필 + 전역 지침 ──────────────────────────────────
Remove-KitSkillLinks -Live "$codexHome\skills"
Write-Host "[claude] $claudeHome\skills"
Link-Profile -Profile "$repoDir\claude\skills" -Live "$claudeHome\skills"
Write-Host "[codex] $agentsHome\skills"
Link-Profile -Profile "$repoDir\codex\skills" -Live "$agentsHome\skills"

Write-Host "[instructions]"
Link-Entry -Target "$repoDir\claude\CLAUDE.md" -Link "$claudeHome\CLAUDE.md"
Link-Entry -Target "$repoDir\codex\AGENTS.md"  -Link "$codexHome\AGENTS.md"

# GBrain 런타임·systemd 유닛·bashrc 별칭은 Linux 전용이라 대상이 아니다.
Write-Host "[skip] GBrain 런타임 / systemd 유닛 / bashrc 별칭 — Linux 전용"

$python = Get-Python
if ($python) {
    $env:PYTHONIOENCODING = 'utf-8'
    & $python "$repoDir\scripts\check-skill-deps.py"
} else {
    Write-Warning "python 미발견 — check-skill-deps.py 건너뜀"
}

Write-Host "kmh-agent-kit installed (junction/hardlink mode)."
if (Test-Path -LiteralPath $backupRoot) { Write-Host "기존 파일 백업: $backupRoot" }
Write-Host "다음: docs\onboarding-new-server.md 참조."
