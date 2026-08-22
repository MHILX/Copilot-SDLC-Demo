<#
.SYNOPSIS
    Scaffolds the Copilot SDLC customization files into a target folder.

.DESCRIPTION
    Copies the .github customization (agents, instructions, prompts,
    copilot-instructions.md) from this repo into a target folder as
    template-owned files, seeds docs/spec.md only if missing (it is
    project-owned state that is never overwritten), and ensures src/ and
    tests/ exist. Template files are synced per file and tracked in
    .github/.sdlc-manifest, so newly added agents are picked up and ones
    renamed or removed upstream are cleaned from the target on the next run,
    while any files you add to those folders yourself are preserved.

.PARAMETER Target
    Path to the repo/folder to scaffold into. Created if it does not exist.

.PARAMETER FromRepo
    Optional git URL of the template source. When given, the template is
    cloned to a temp folder first, so a single command installs into any
    project without a manual clone.

.PARAMETER Force
    Overwrite existing template-owned files without prompting. Never affects
    project-owned docs/spec.md.

.EXAMPLE
    ./scripts/scaffold-sdlc.ps1 -Target ../my-project

.EXAMPLE
    ./scripts/scaffold-sdlc.ps1 -Target C:\code\my-project -Force

.EXAMPLE
    ./scripts/scaffold-sdlc.ps1 -Target ../my-project -FromRepo https://github.com/MHILX/Copilot-SDLC-Demo.git
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Target,

    [string] $FromRepo,

    [switch] $Force
)

$ErrorActionPreference = 'Stop'

# Relative path (under the target) of the manifest that records template-owned files.
$manifestRel = '.github/.sdlc-manifest'

# List the template's current files as target-relative, forward-slashed paths.
function Get-TemplateFiles {
    param([string] $Root, [string[]] $Sources)
    $files = @()
    foreach ($rel in $Sources) {
        $src = Join-Path $Root $rel
        if (Test-Path $src -PathType Container) {
            foreach ($f in Get-ChildItem -Path $src -Recurse -File) {
                $files += ($f.FullName.Substring($Root.Length).TrimStart('\', '/') -replace '\\', '/')
            }
        }
        else {
            $files += $rel
        }
    }
    return $files
}

# Template-owned files: refreshed in place; -Force skips the overwrite prompt.
$templateSources = @(
    '.github/copilot-instructions.md',
    '.github/agents',
    '.github/instructions',
    '.github/prompts'
)

# Project-owned files: created once, then never overwritten (they hold local state).
$projectSources = @(
    'docs/spec.md'
)

# When -FromRepo is given, clone the template into a temp folder and use that as
# the source, so a single command installs into any project without a manual clone.
$TempClone = $null
if ($FromRepo) {
    $TempClone = Join-Path ([System.IO.Path]::GetTempPath()) ("sdlc-" + [System.Guid]::NewGuid().ToString('N'))
    Write-Host "Cloning template from $FromRepo ..."
    git clone --depth 1 $FromRepo $TempClone 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "git clone failed for $FromRepo" }
    $RepoRoot = $TempClone
}
else {
    # Repo root is the parent of this script's folder.
    $RepoRoot = Split-Path -Parent $PSScriptRoot
}

# Verify we are running from a populated source repo.
foreach ($rel in ($templateSources + $projectSources)) {
    $src = Join-Path $RepoRoot $rel
    if (-not (Test-Path $src)) {
        throw "Source not found: $src. Run this script from a clone of the Copilot-SDLC-Demo repo, or pass -FromRepo <url>."
    }
}

# Create the target root.
if (-not (Test-Path $Target)) {
    New-Item -ItemType Directory -Path $Target -Force | Out-Null
}
$TargetRoot = (Resolve-Path $Target).Path

Write-Host "Scaffolding SDLC customization into: $TargetRoot"

try {
    $currentFiles = Get-TemplateFiles -Root $RepoRoot -Sources $templateSources

    # Remove template files renamed or deleted upstream (tracked in the manifest),
    # leaving any files you added to these folders untouched.
    $manifestPath = Join-Path $TargetRoot $manifestRel
    if (Test-Path $manifestPath) {
        $previous = Get-Content $manifestPath | Where-Object { $_ -and -not $_.StartsWith('#') }
        foreach ($rel in ($previous | Where-Object { $currentFiles -notcontains $_ })) {
            $stalePath = Join-Path $TargetRoot $rel
            if (Test-Path $stalePath) {
                Remove-Item -Force $stalePath
                Write-Host "  removed   $rel (no longer in template)"
            }
        }
    }

    # Template-owned files: refreshed per file (prompting per folder unless -Force).
    foreach ($rel in $templateSources) {
        $src = Join-Path $RepoRoot $rel
        $dest = Join-Path $TargetRoot $rel

        if ((Test-Path $dest) -and -not $Force) {
            $answer = Read-Host "Exists: $rel. Overwrite? (y/N)"
            if ($answer -notin @('y', 'Y')) {
                Write-Host "  skipped   $rel"
                continue
            }
        }

        if (Test-Path $src -PathType Container) {
            foreach ($f in Get-ChildItem -Path $src -Recurse -File) {
                $fileRel = $f.FullName.Substring($RepoRoot.Length).TrimStart('\', '/')
                $fileDest = Join-Path $TargetRoot $fileRel
                $fileDestParent = Split-Path -Parent $fileDest
                if (-not (Test-Path $fileDestParent)) {
                    New-Item -ItemType Directory -Path $fileDestParent -Force | Out-Null
                }
                Copy-Item -Path $f.FullName -Destination $fileDest -Force
            }
        }
        else {
            $destParent = Split-Path -Parent $dest
            if (-not (Test-Path $destParent)) {
                New-Item -ItemType Directory -Path $destParent -Force | Out-Null
            }
            Copy-Item -Path $src -Destination $dest -Force
        }
        Write-Host "  copied    $rel"
    }

    # Project-owned files: create once, never clobber existing local state.
    foreach ($rel in $projectSources) {
        $src = Join-Path $RepoRoot $rel
        $dest = Join-Path $TargetRoot $rel
        $destParent = Split-Path -Parent $dest

        if (-not (Test-Path $destParent)) {
            New-Item -ItemType Directory -Path $destParent -Force | Out-Null
        }

        if (Test-Path $dest) {
            Write-Host "  preserved $rel (project-owned)"
            continue
        }

        Copy-Item -Path $src -Destination $destParent -Recurse -Force
        Write-Host "  copied    $rel"
    }

    # Ensure src/ and tests/ exist with a .gitkeep.
    foreach ($dir in @('src', 'tests')) {
        $path = Join-Path $TargetRoot $dir
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
        $gitkeep = Join-Path $path '.gitkeep'
        if (-not (Test-Path $gitkeep)) {
            New-Item -ItemType File -Path $gitkeep -Force | Out-Null
        }
        Write-Host "  ensured   $dir/"
    }

    # Record installed template files so a later run can remove renamed/deleted ones.
    $manifestParent = Split-Path -Parent (Join-Path $TargetRoot $manifestRel)
    if (-not (Test-Path $manifestParent)) {
        New-Item -ItemType Directory -Path $manifestParent -Force | Out-Null
    }
    $manifestHeader = '# Generated by scaffold-sdlc. Tracks template-owned files so re-scaffolding removes renamed or deleted ones. Do not edit.'
    Set-Content -Path (Join-Path $TargetRoot $manifestRel) -Value (@($manifestHeader) + $currentFiles) -Encoding UTF8
}
finally {
    if ($TempClone -and (Test-Path $TempClone)) {
        Remove-Item -Recurse -Force $TempClone -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host "Done. Next steps:"
Write-Host "  1. Open '$TargetRoot' in VS Code."
Write-Host "  2. Reload the window so the agents are picked up."
Write-Host "  3. Select the 'sdlc-supervisor' agent and describe what to build."
