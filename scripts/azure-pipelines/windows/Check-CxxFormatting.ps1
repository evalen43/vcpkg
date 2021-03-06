[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [string]$Root,
    [Parameter()]
    [switch]$IgnoreErrors # allows one to just format
)

$clangFormat = 'C:\Program Files\LLVM\bin\clang-format.exe'
if (-not (Test-Path $clangFormat))
{
    Write-Error "clang-format not found; is it installed in the CI machines?"
    throw
}

$toolsrc = Get-Item "$Root/toolsrc"
Push-Location $toolsrc

try
{
    $files = Get-ChildItem -Recurse -LiteralPath "$toolsrc/src" -Filter '*.cpp'
    $files += Get-ChildItem -Recurse -LiteralPath "$toolsrc/include/vcpkg" -Filter '*.h'
    $files += Get-ChildItem -Recurse -LiteralPath "$toolsrc/include/vcpkg-test" -Filter '*.h'
    $files += Get-Item "$toolsrc/include/pch.h"
    $fileNames = $files.FullName

    & $clangFormat -style=file -i @fileNames

    $changedFiles = & "$PSScriptRoot/Get-ChangedFiles.ps1" -Directory $toolsrc
    if (-not $IgnoreErrors -and $null -ne $changedFiles)
    {
        $msg = @(
            "",
            "The formatting of the C++ files didn't match our expectation.",
            "If your build fails here, you need to format the following files with:"
        )
        $msg += "    $(& $clangFormat -version)"
        $msg += "    $changedFiles"
        $msg += ""

        $msg += "clang-format should produce the following diff:"
        $msg += git diff $toolsrc

        Write-Error ($msg -join "`n")
        throw
    }
}
finally
{
    Pop-Location
}
