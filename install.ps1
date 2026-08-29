# kmh-agent-kit installer for Windows PowerShell, Command Prompt, and Git Bash.
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

function Get-KitGitExecutable {
    $candidates = @()
    $command = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($command -and $command.Source) { $candidates += $command.Source }
    if ($env:LOCALAPPDATA) {
        $candidates += (Join-Path $env:LOCALAPPDATA 'hermes\git\cmd\git.exe')
        $candidates += (Join-Path $env:LOCALAPPDATA 'hermes\git\bin\git.exe')
    }
    if ($env:ProgramFiles) { $candidates += (Join-Path $env:ProgramFiles 'Git\cmd\git.exe') }
    if (${env:ProgramFiles(x86)}) { $candidates += (Join-Path ${env:ProgramFiles(x86)} 'Git\cmd\git.exe') }

    foreach ($candidate in $candidates | Select-Object -Unique) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    throw '[error] Git을 찾지 못했습니다. kitpush에 Git이 필요합니다.'
}

function Invoke-BootstrapCheckout {
    param([hashtable]$ForwardedParameters)

    if (-not $env:USERPROFILE) { throw '[error] USERPROFILE이 없습니다.' }
    $checkout = Join-Path $env:USERPROFILE 'kmh-agent-kit'
    $git = Get-KitGitExecutable
    if ((Test-Path -LiteralPath $checkout) -and
        -not (Test-Path -LiteralPath (Join-Path $checkout '.git') -PathType Container)) {
        throw "[error] 설치 경로가 이미 있지만 Git 저장소가 아닙니다: $checkout"
    }

    if (Test-Path -LiteralPath (Join-Path $checkout '.git') -PathType Container) {
        $dirty = & $git -C $checkout status --porcelain=v1 --untracked-files=normal
        if ($LASTEXITCODE -ne 0) { throw '[error] 기존 키트 상태 확인 실패' }
        if ($dirty) { throw "[error] 기존 키트에 로컬 변경이 있어 자동 설치를 중단합니다: $checkout" }
        & $git -C $checkout fetch --prune origin
        if ($LASTEXITCODE -ne 0) { throw '[error] origin 갱신 실패' }
        & $git -C $checkout show-ref --verify --quiet refs/remotes/origin/main
        if ($LASTEXITCODE -ne 0) { throw '[error] 원격 origin/main 브랜치가 없습니다.' }
        & $git -C $checkout show-ref --verify --quiet refs/heads/main
        if ($LASTEXITCODE -eq 0) {
            & $git -C $checkout checkout main
        } else {
            & $git -C $checkout checkout -b main --track origin/main
        }
        if ($LASTEXITCODE -ne 0) { throw '[error] main 브랜치 전환 실패' }
        & $git -C $checkout merge --ff-only origin/main
        if ($LASTEXITCODE -ne 0) { throw '[error] 기존 키트 fast-forward 실패' }
    } else {
        & $git clone --branch main --single-branch git@github.com:chaconne67/kmh-agent-kit.git $checkout
        if ($LASTEXITCODE -ne 0) { throw '[error] kmh-agent-kit clone 실패' }
    }

    & (Join-Path $checkout 'install.ps1') @ForwardedParameters
    if (-not $?) { throw '[error] 체크아웃된 설치기 실행 실패' }
}

$forwardedParameters = @{}
foreach ($key in $PSBoundParameters.Keys) { $forwardedParameters[$key] = $PSBoundParameters[$key] }
$isRepositoryInstaller = $MyInvocation.MyCommand.Path -and $PSScriptRoot -and
    (Test-Path -LiteralPath (Join-Path $PSScriptRoot '.git') -PathType Container) -and
    (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'manifests\skills.json') -PathType Leaf)
if (-not $isRepositoryInstaller) {
    Invoke-BootstrapCheckout -ForwardedParameters $forwardedParameters
    return
}

$repoDir    = $PSScriptRoot
$homeDir    = $env:USERPROFILE
$claudeHome = if ($env:CLAUDE_HOME) { $env:CLAUDE_HOME } else { Join-Path $homeDir '.claude' }
$codexHome  = if ($env:CODEX_HOME)  { $env:CODEX_HOME }  else { Join-Path $homeDir '.codex' }
$agentsHome = Join-Path $homeDir '.agents'
$hermesHome = if ($env:HERMES_HOME) { $env:HERMES_HOME } elseif ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA 'hermes' } else { Join-Path $homeDir '.hermes' }
$script:gitExe = Get-KitGitExecutable
$stamp      = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = Join-Path $homeDir ".kmh-agent-kit-backup-$stamp"

function Show-Usage {
    @'
KMH Agent Kit (Windows PowerShell·Command Prompt·Git Bash)

최초 설치 또는 재연결:
  .\install.ps1 -Agent <등록-이름>

프로젝트 프로필 연결:
  .\install.ps1 -Project "$HOME\projects\rndlog" -ProfileName rndlog

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
    & $script:gitExe -C $repoDir @Arguments
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
    param([string]$Profile, [string]$Live, [switch]$PreserveExisting)

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
        $linkPath = Join-Path $Live $entry.Name
        if ($PreserveExisting -and (Test-Path -LiteralPath $linkPath)) {
            $existing = Get-Item -LiteralPath $linkPath -Force
            $skillsRoot = (Join-Path $repoDir 'skills').TrimEnd('\')
            $managed = $existing.LinkType -eq 'Junction' -and $existing.Target -and
                ($existing.Target[0]).StartsWith($skillsRoot, 'OrdinalIgnoreCase')
            if (-not $managed) {
                Write-Host "  Hermes 기존 스킬 유지: $linkPath"
                $linked[$entry.Name] = $true
                continue
            }
        }
        Link-Entry -Target $target -Link $linkPath
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

function Get-GitBashExecutable {
    $candidates = @()
    if ($env:HERMES_GIT_BASH_PATH) { $candidates += $env:HERMES_GIT_BASH_PATH }
    $gitParent = Split-Path $script:gitExe -Parent
    $gitRoot = Split-Path $gitParent -Parent
    $candidates += (Join-Path $gitRoot 'bin\bash.exe')
    $candidates += (Join-Path $gitRoot 'usr\bin\bash.exe')
    if ($env:LOCALAPPDATA) {
        $candidates += (Join-Path $env:LOCALAPPDATA 'hermes\git\bin\bash.exe')
        $candidates += (Join-Path $env:LOCALAPPDATA 'hermes\git\usr\bin\bash.exe')
    }
    if ($env:ProgramFiles) {
        $candidates += (Join-Path $env:ProgramFiles 'Git\bin\bash.exe')
        $candidates += (Join-Path $env:ProgramFiles 'Git\usr\bin\bash.exe')
    }
    if (${env:ProgramFiles(x86)}) {
        $candidates += (Join-Path ${env:ProgramFiles(x86)} 'Git\bin\bash.exe')
    }
    $command = Get-Command bash.exe -ErrorAction SilentlyContinue
    if ($command -and $command.Source -and $command.Source -notmatch '\\System32\\') {
        $candidates += $command.Source
    }

    foreach ($candidate in $candidates | Select-Object -Unique) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    throw '[error] Git Bash의 bash.exe를 찾지 못했습니다.'
}

function Add-UserPathEntry {
    param([string]$Path)
    $current = [Environment]::GetEnvironmentVariable('Path', 'User')
    $entries = @($current -split ';' | Where-Object { $_ })
    if (-not ($entries | Where-Object { $_.TrimEnd('\') -eq $Path.TrimEnd('\') })) {
        $updated = (@($Path) + $entries) -join ';'
        [Environment]::SetEnvironmentVariable('Path', $updated, 'User')
    }
    if (-not (($env:Path -split ';') | Where-Object { $_.TrimEnd('\') -eq $Path.TrimEnd('\') })) {
        $env:Path = "$Path;$env:Path"
    }
}

function Install-ShellCommands {
    $bashRepo = Convert-ToGitBashPath -Path $repoDir
    $aliasLine = '[ -f "' + $bashRepo + '/shell/kit-aliases.sh" ] && . "' + $bashRepo + '/shell/kit-aliases.sh"'
    Add-ShellLine -Path (Join-Path $homeDir '.bashrc') -Marker 'kmh-agent-kit aliases' -Line $aliasLine
    Add-ShellLine -Path (Join-Path $homeDir '.bash_profile') -Marker 'load ~/.bashrc for kmh-agent-kit' -Line '[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"'

    $commandDir = Join-Path $homeDir '.local\bin'
    if (-not (Test-Path -LiteralPath $commandDir)) {
        New-Item -ItemType Directory -Path $commandDir -Force | Out-Null
    }
    $bash = Get-GitBashExecutable
    $aliasScript = "$bashRepo/shell/kit-aliases.sh"
    $gitDir = Split-Path $script:gitExe -Parent
    foreach ($command in 'kitpull', 'kitpush') {
        $action = if ($command -eq 'kitpull') { 'pull' } else { 'push' }
        $content = "@echo off`r`nset `"PATH=$gitDir;%PATH%`"`r`n`"$bash`" --noprofile --norc `"$aliasScript`" $action %*`r`n"
        Write-Utf8NoBom -Path (Join-Path $commandDir "$command.cmd") -Content $content
    }
    Add-UserPathEntry -Path $commandDir
    Add-UserPathEntry -Path $gitDir
}

function Install-Global {
    Remove-KitSkillLinks -Live "$codexHome\skills"
    Write-Host "[claude] $claudeHome\skills"
    Link-Profile -Profile "$repoDir\claude\skills" -Live "$claudeHome\skills"
    Write-Host "[codex] $agentsHome\skills"
    Link-Profile -Profile "$repoDir\codex\skills" -Live "$agentsHome\skills"
    Write-Host "[hermes] $hermesHome\skills"
    Link-Profile -Profile "$repoDir\codex\skills" -Live "$hermesHome\skills" -PreserveExisting

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
    $rows = & $script:gitExe -C $repoDir config --local --get-regexp '^kmh-agent-kit\.project\.' 2>$null
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
        $savedAgent = (& $script:gitExe -C $repoDir config --local --get kmh-agent-kit.agent).Trim()
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
