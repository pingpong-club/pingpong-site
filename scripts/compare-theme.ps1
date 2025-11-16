param(
  [Parameter(Mandatory=$true)] [string]$LocalThemePath,   # e.g. .\site\themes\FixIt
  [Parameter(Mandatory=$true)] [string]$UpstreamRepo,     # e.g. https://github.com/hugo-fixit/FixIt
  [Parameter(Mandatory=$true)] [string]$Tag,              # e.g. v0.3.12
  [string]$ReportPath = ".\theme-diff.txt"
)

function Get-FileMap($root) {
  $exclude = @('\\.git($|\\)', 'node_modules($|\\)', '^\.DS_Store$', '\\.map$', '^\.gitignore$', '\\.gitattributes$')
  $files = Get-ChildItem -Path $root -Recurse -File -Force
  $map = @{}
  foreach ($f in $files) {
    $rel = Resolve-Path $f.FullName | ForEach-Object {
      $_.Path.Substring($root.Length).TrimStart('\\','/')
    }
    if ($exclude | Where-Object { $rel -match $_ }) { continue }
    $hash = (Get-FileHash -Path $f.FullName -Algorithm SHA256).Hash
    $map[$rel] = $hash
  }
  return $map
}

$Temp = Join-Path $env:TEMP ("theme-upstream-" + [guid]::NewGuid())
try {
  git clone $UpstreamRepo $Temp --branch $Tag --depth 1 | Out-Null
} catch {
  Write-Error "Failed to clone $UpstreamRepo@$Tag. Ensure git is installed and the tag exists."
  exit 1
}

$upstreamRoot = $Temp  # adjust if the theme lives in a subfolder
$localRoot = (Resolve-Path $LocalThemePath).Path

$upMap = Get-FileMap $upstreamRoot
$localMap = Get-FileMap $localRoot

$upKeys = $upMap.Keys
$localKeys = $localMap.Keys

$added    = $localKeys | Where-Object { -not $upKeys.Contains($_) } | Sort-Object
$removed  = $upKeys | Where-Object { -not $localKeys.Contains($_) } | Sort-Object
$modified = $localKeys | Where-Object { $upKeys.Contains($_) -and ($localMap[$_] -ne $upMap[$_]) } | Sort-Object

"Theme Diff Report (`$LocalThemePath` vs $UpstreamRepo@$Tag)" | Out-File $ReportPath
"Generated: $(Get-Date)" | Out-File $ReportPath -Append
"-----------------------------------------------------" | Out-File $ReportPath -Append

"Added (local only):" | Out-File $ReportPath -Append
if ($added.Count -eq 0) { "  (none)" | Out-File $ReportPath -Append } else { $added | ForEach-Object { "  $_" | Out-File $ReportPath -Append } }

"`nRemoved (only in upstream):" | Out-File $ReportPath -Append
if ($removed.Count -eq 0) { "  (none)" | Out-File $ReportPath -Append } else { $removed | ForEach-Object { "  $_" | Out-File $ReportPath -Append } }

"`nModified (same path, different content):" | Out-File $ReportPath -Append
if ($modified.Count -eq 0) { "  (none)" | Out-File $ReportPath -Append } else { $modified | ForEach-Object { "  $_" | Out-File $ReportPath -Append } }

"`nDone. Report: $ReportPath" | Out-File $ReportPath -Append

Remove-Item -Recurse -Force $Temp
Write-Host "Report written to $ReportPath"