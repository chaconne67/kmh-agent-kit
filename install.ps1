# kmh-agent-kit installer for Windows Git Bash.
# Directories use junctions and files use hardlinks, so no Developer Mode is required.

[CmdletBinding()]
param(
    [string]$Agent,
    [string]$Gbrain,
    [string]$Project,
    [string]$ProfileName,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

$repoDir    = $PSScriptRoot
$homeDir    = $env:USERPROFILE
$claudeHome = if ($env:CLAUDE_HOME) { $env:CLAUDE_HOME } else { Join-Path $homeDir '.claude' }
$codexHome  = if ($env:CODEX_HOME)  { $env:CODEX_HOME }  else { Join-Path $homeDir '.codex' }
$agentsHome = Join-Path $homeDir '.agents'
$stamp      = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = Join-Path $homeDir ".kmh-agent-kit-backup-$stamp"

function Show-Usage {
    @'
KMH Agent Kit (Windows Git Bash)

최초 설치 또는 재연결:
  ~/kmh-agent-kit/install.sh gram17
  ~/kmh-agent-kit/install.sh venture

프로젝트 프로필 연결:
  ~/kmh-agent-kit/install.sh --project ~/projects/rndlog rndlog

이후 동기화:
  kitpull
  kitpush "변경 설명"
'@ | Write-Host
}

function Assert-Name {
    param([string]$Name, [string]$Kind)
    if (-not $Name -or $Name -notmatch '^[a-z0-9]([a-z0-9-]{0,30}[a-z0-9])?$') {
        throw "[error] $Kind 이름은 영문 소문자·숫자·중간 하이픈으로 된 1~32자여야 합니다: $Name"
    }
}

function Invoke-KitGit {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    & git -C $repoDir @Arguments
    if ($LASTEXITCODE -ne 0) { throw "[error] git 명령 실패: git -C $repoDir $($Arguments -join ' ')" }
}

function Backup-Entry {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $backupRoot)) {
        New-Item -ItemType Directory -Path $backupRoot | Out-Null
    }
    $flat = if ($Path.StartsWith($homeDir, 'OrdinalIgnoreCase')) {
        $Path.Substring($homeDir.Length)
    } else {
        $Path -replace '^[A-Za-z]:', ''
    }
    $flat = $flat.TrimStart('\').Replace('\', '_')
    Move-Item -LiteralPath $Path -Destination (Join-Path $backupRoot $flat) -Force
    Write-Host "  backup: $Path"
}

function Resolve-ProfileTarget {
    param([string]$Entry)

    $item = Get-Item -LiteralPath $Entry -Force
    if ($item.PSIsContainer) { return $item.FullName }
    if ($item.LinkType) { return (Resolve-Path -LiteralPath $item.Target[0]).Path }
    if ($item.Length -ge 4096) { return $null }

    $text = (Get-Content -LiteralPath $Entry -Raw -Encoding UTF8).Trim()
    if (-not $text -or $text.Contains("`n") -or -not $text.StartsWith('..')) { return $null }
    $resolved = Join-Path (Split-Path $Entry -Parent) $text
    if (Test-Path -LiteralPath $resolved) { return (Resolve-Path -LiteralPath $resolved).Path }
    return $null
}

function Link-Entry {
    param([string]$Target, [string]$Link)

    $target = (Resolve-Path -LiteralPath $Target).Path
    $targetIsDir = (Get-Item -LiteralPath $target -Force).PSIsContainer
    if (Test-Path -LiteralPath $Link) {
        $existing = Get-Item -LiteralPath $Link -Force
        if ($existing.LinkType -eq 'Junction' -and $existing.Target -and
            ($existing.Target[0]).TrimEnd('\') -eq $target.TrimEnd('\')) { return }

        if ($existing.LinkType -eq 'Junction') {
            [System.IO.Directory]::Delete($Link)
        } elseif ($existing.LinkType -eq 'HardLink' -and -not $targetIsDir -and
                  (Get-FileHash -LiteralPath $Link).Hash -eq (Get-FileHash -LiteralPath $target).Hash) {
            # Git checkout은 원본 inode를 바꿀 수 있다. 내용이 같아도 매번 현재 원본에 다시 건다.
            [System.IO.File]::Delete($Link)
        } else {
            Backup-Entry -Path $Link
        }
    }

    $parent = Split-Path $Link -Parent
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $type = if ($targetIsDir) { 'Junction' } else { 'HardLink' }
    New-Item -ItemType $type -Path $Link -Target $target | Out-Null
    Write-Host "  $type  $Link -> $target"
}

function Link-Profile {
    param([string]$Profile, [string]$Live)

    if (-not (Test-Path -LiteralPath $Profile)) { return }
    if (-not (Test-Path -LiteralPath $Live)) {
        New-Item -ItemType Directory -Path $Live -Force | Out-Null
    }

    $linked = @{}
    foreach ($entry in Get-ChildItem -LiteralPath $Profile -Force) {
        $target = Resolve-ProfileTarget -Entry $entry.FullName
        if (-not $target) {
            Write-Warning "  skip (대상 해석 실패): $($entry.Name)"
            continue
        }
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

function Get-Python {
    foreach ($name in 'python', 'python3', 'py') {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd -and $cmd.Source -and $cmd.Source -notmatch '\\WindowsApps\\') { return $cmd.Source }
    }
    return $null
}

function Convert-ToGitBashPath {
    param([string]$Path)

    $cygpath = Get-Command cygpath.exe -ErrorAction SilentlyContinue
    if ($cygpath) { return (& $cygpath.Source -u $Path).Trim() }
    $full = [System.IO.Path]::GetFullPath($Path)
    if ($full -match '^([A-Za-z]):(.*)$') {
        return '/' + $matches[1].ToLowerInvariant() + ($matches[2] -replace '\\', '/')
    }
    return ($full -replace '\\', '/')
}

function Write-Utf8NoBom {
    param([string]$Path, [string]$Content)
    $parent = Split-Path $Path -Parent
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($Path, $Content, (New-Object System.Text.UTF8Encoding($false)))
}

function Add-ShellLine {
    param([string]$Path, [string]$Marker, [string]$Line)

    $content = if (Test-Path -LiteralPath $Path) {
        Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    } else { '' }
    if ($content -match [regex]::Escape($Marker)) { return }
    if ($content -and -not $content.EndsWith("`n")) { $content += "`r`n" }
    $content += "`r`n# $Marker`r`n$Line`r`n"
    Write-Utf8NoBom -Path $Path -Content $content
    Write-Host "  shell source: $Path"
}

function Install-ShellCommands {
    $bashRepo = Convert-ToGitBashPath -Path $repoDir
    $aliasLine = '[ -f "' + $bashRepo + '/shell/kit-aliases.sh" ] && . "' + $bashRepo + '/shell/kit-aliases.sh"'
    Add-ShellLine -Path (Join-Path $homeDir '.bashrc') -Marker 'kmh-agent-kit aliases' -Line $aliasLine
    Add-ShellLine -Path (Join-Path $homeDir '.bash_profile') -Marker 'load ~/.bashrc for kmh-agent-kit' -Line '[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"'
}

function Install-Global {
    Remove-KitSkillLinks -Live "$codexHome\skills"
    Write-Host "[claude] $claudeHome\skills"
    Link-Profile -Profile "$repoDir\claude\skills" -Live "$claudeHome\skills"
    Write-Host "[codex] $agentsHome\skills"
    Link-Profile -Profile "$repoDir\codex\skills" -Live "$agentsHome\skills"

    Write-Host '[instructions]'
    Link-Entry -Target "$repoDir\claude\CLAUDE.md" -Link "$claudeHome\CLAUDE.md"
    Link-Entry -Target "$repoDir\codex\AGENTS.md" -Link "$codexHome\AGENTS.md"
    Install-ShellCommands

    $python = Get-Python
    if ($python) {
        $env:PYTHONIOENCODING = 'utf-8'
        & $python "$repoDir\scripts\check-skill-deps.py"
        if ($LASTEXITCODE -ne 0) { throw '[error] 스킬 의존성 검사 실패' }
    } else {
        Write-Warning 'python 미발견 — check-skill-deps.py 건너뜀'
    }
}

function Install-ProjectProfile {
    param([string]$ProjectPath, [string]$Profile)

    Assert-Name -Name $Profile -Kind '프로필'
    $profileDir = Join-Path $repoDir "projects\$Profile"
    if (-not (Test-Path -LiteralPath $profileDir -PathType Container)) {
        throw "[error] 프로젝트 프로필 없음: $profileDir"
    }
    if (-not (Test-Path -LiteralPath $ProjectPath -PathType Container)) {
        throw "[error] 프로젝트 경로 없음: $ProjectPath"
    }
    $projectPath = (Resolve-Path -LiteralPath $ProjectPath).Path

    Remove-KitSkillLinks -Live "$projectPath\.codex\skills"
    if (Test-Path -LiteralPath "$profileDir\skills") {
        Link-Profile -Profile "$profileDir\skills" -Live "$projectPath\.claude\skills"
        Link-Profile -Profile "$profileDir\skills" -Live "$projectPath\.agents\skills"
    }
    foreach ($file in 'CLAUDE.md', 'AGENTS.md') {
        if (Test-Path -LiteralPath "$profileDir\$file") {
            Link-Entry -Target "$profileDir\$file" -Link "$projectPath\$file"
        }
    }
    Write-Host "project '$Profile' linked into $projectPath"
}

function Register-ProjectProfile {
    param([string]$ProjectPath, [string]$Profile)
    $projectPath = (Resolve-Path -LiteralPath $ProjectPath).Path
    Invoke-KitGit config --local --replace-all "kmh-agent-kit.project.$Profile" $projectPath
    Write-Host "project '$Profile' registered at $projectPath"
}

function Register-KnownProjects {
    param([string]$AgentName)

    if ($AgentName -eq 'main') {
        foreach ($profile in Get-ChildItem -LiteralPath "$repoDir\projects" -Directory) {
            $projectPath = Join-Path $homeDir "projects\$($profile.Name)"
            if (Test-Path -LiteralPath $projectPath -PathType Container) {
                Register-ProjectProfile -ProjectPath $projectPath -Profile $profile.Name
            }
        }
    } elseif ($AgentName -eq 'fundkeeper') {
        $projectPath = Join-Path $homeDir 'fundkeeper'
        if (Test-Path -LiteralPath $projectPath -PathType Container) {
            Register-ProjectProfile -ProjectPath $projectPath -Profile 'fundkeeper'
        }
    } else {
        $projectPath = Join-Path $homeDir $AgentName
        if ((Test-Path -LiteralPath "$repoDir\projects\$AgentName" -PathType Container) -and
            (Test-Path -LiteralPath $projectPath -PathType Container)) {
            Register-ProjectProfile -ProjectPath $projectPath -Profile $AgentName
        }
    }
}

function Install-RegisteredProjects {
    $rows = & git -C $repoDir config --local --get-regexp '^kmh-agent-kit\.project\.' 2>$null
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1) { throw '[error] 프로젝트 등록 정보 조회 실패' }
    foreach ($row in $rows) {
        if ($row -notmatch '^(\S+)\s+(.+)$') { continue }
        $profile = ($matches[1] -split '\.')[-1]
        $projectPath = $matches[2]
        if (-not (Test-Path -LiteralPath "$repoDir\projects\$profile" -PathType Container)) {
            Write-Warning "등록된 프로젝트 프로필이 없어 건너뜀: $profile"
            continue
        }
        if (-not (Test-Path -LiteralPath $projectPath -PathType Container)) {
            Write-Warning "등록된 프로젝트 경로가 없어 건너뜀: $projectPath"
            continue
        }
        Install-ProjectProfile -ProjectPath $projectPath -Profile $profile
    }
}

function Install-AgentCard {
    param([string]$AgentName)
    Assert-Name -Name $AgentName -Kind '등록'
    $card = Join-Path $repoDir "gbrain-cards\$AgentName.md"
    if (-not (Test-Path -LiteralPath $card -PathType Leaf)) {
        throw "[error] 등록되지 않은 에이전트: $AgentName"
    }
    Link-Entry -Target $card -Link (Join-Path $homeDir '.gbrain-agent.md')
}

function Assert-Install {
    param([string]$AgentName)

    foreach ($path in "$claudeHome\CLAUDE.md", "$codexHome\AGENTS.md") {
        $item = Get-Item -LiteralPath $path -Force
        if ($item.LinkType -ne 'HardLink') { throw "[error] 하드링크 검증 실패: $path" }
    }
    if ($AgentName) {
        $cardPath = Join-Path $homeDir '.gbrain-agent.md'
        $cardItem = Get-Item -LiteralPath $cardPath -Force
        if ($cardItem.LinkType -ne 'HardLink') { throw "[error] GBrain 카드 하드링크 검증 실패: $cardPath" }
        $savedAgent = (& git -C $repoDir config --local --get kmh-agent-kit.agent).Trim()
        if ($LASTEXITCODE -ne 0 -or $savedAgent -ne $AgentName) {
            throw "[error] 등록 이름 저장 검증 실패: $AgentName"
        }
    }
}

if ($Help) {
    Show-Usage
    exit 0
}
if ($Gbrain) {
    if ($Agent -and $Agent -ne $Gbrain) { throw '[error] -Agent와 -Gbrain 값이 다릅니다.' }
    $Agent = $Gbrain
}
if ($Project -and -not $ProfileName) {
    throw 'usage: .\install.ps1 -Project <경로> -ProfileName <프로필명>'
}
if ($ProfileName -and -not $Project) {
    throw '[error] -ProfileName에는 -Project가 필요합니다.'
}
if ($Project -and $Agent) {
    throw '[error] 에이전트 설치와 프로젝트 연결은 한 번에 하나씩 실행하세요.'
}

Invoke-KitGit rev-parse --git-dir | Out-Null
if ($Project) {
    Install-ProjectProfile -ProjectPath $Project -Profile $ProfileName
    Register-ProjectProfile -ProjectPath $Project -Profile $ProfileName
} else {
    Install-Global
    if ($Agent) {
        Install-AgentCard -AgentName $Agent
        Invoke-KitGit config --local kmh-agent-kit.agent $Agent
        Register-KnownProjects -AgentName $Agent
        Install-RegisteredProjects
    }
    Assert-Install -AgentName $Agent
}

Write-Host 'kmh-agent-kit installed (Windows junction/hardlink mode).'
if ($Agent) { Write-Host "등록 이름 저장: $Agent (kitpull·kitpush가 자동 사용)" }
if (Test-Path -LiteralPath $backupRoot) { Write-Host "기존 파일 백업: $backupRoot" }
