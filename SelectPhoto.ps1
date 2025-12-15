# PowerShell 5.1 - ASCII-only
# Copies selected JPG (from 02_Selected_JPG) and matching CR3 (from 01_All)
# into 03_Selected_JPG+RAW. Does NOT touch 01_All other than reading.
# Adds completion popup with summary.

Add-Type -AssemblyName System.Windows.Forms

function PickFolder($desc) {
  $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
  $dlg.Description = $desc
  $dlg.ShowNewFolderButton = $true
  $r = $dlg.ShowDialog()
  if ($r -ne [System.Windows.Forms.DialogResult]::OK -or [string]::IsNullOrWhiteSpace($dlg.SelectedPath)) {
    throw ("Folder selection canceled: " + $desc)
  }
  return $dlg.SelectedPath
}

function EnsureDir($p) {
  if (-not (Test-Path -LiteralPath $p)) {
    New-Item -ItemType Directory -Force -Path $p | Out-Null
  }
}

function Log($msg) {
  $ts = Get-Date -Format "HH:mm:ss"
  Write-Host ("[{0}] {1}" -f $ts, $msg)
}

try {
  Log "Select folders."

  $allDir = PickFolder "Select 01_All (source: JPG+CR3)"
  $selDir = PickFolder "Select 02_Selected_JPG (selected JPG only)"

  $baseDir = Split-Path $allDir -Parent
  $outDir = Join-Path $baseDir "03_Selected_JPG+RAW"
  EnsureDir $outDir

  Log ("01_All: " + $allDir)
  Log ("02_Selected_JPG: " + $selDir)
  Log ("03_Selected_JPG+RAW: " + $outDir)

  # Read selected JPGs (top-level only)
  $selectedJpgs = Get-ChildItem -LiteralPath $selDir -File | Where-Object { $_.Extension -match '\.(jpg|jpeg)$' }
  if (-not $selectedJpgs -or $selectedJpgs.Count -eq 0) {
    throw "No JPG/JPEG files found in 02_Selected_JPG."
  }

  Log ("Selected JPG count: " + $selectedJpgs.Count)

  # Index CR3 in 01_All (BaseName -> FullPath)
  Log "Indexing CR3 under 01_All..."
  $rawIndex = @{}
  $dupRaw = 0

  $rawList = Get-ChildItem -LiteralPath $allDir -Recurse -File | Where-Object { $_.Extension -match '\.(cr3)$' }
  $rawTotal = 0
  if ($rawList) { $rawTotal = $rawList.Count }

  $i = 0
  foreach ($r in $rawList) {
    $i += 1
    if ($rawTotal -gt 0) {
      $pct = [int](($i * 100) / $rawTotal)
      Write-Progress -Activity "Indexing CR3" -Status ("{0}/{1}" -f $i, $rawTotal) -PercentComplete $pct
    }

    $k = $r.BaseName.ToLowerInvariant()
    if (-not $rawIndex.ContainsKey($k)) {
      $rawIndex[$k] = $r.FullName
    } else {
      $dupRaw += 1
    }
  }
  Write-Progress -Activity "Indexing CR3" -Completed

  Log ("CR3 indexed: " + $rawIndex.Count + " (raw files scanned: " + $rawTotal + ")")
  if ($dupRaw -gt 0) {
    Log ("WARN: duplicate CR3 basenames found: " + $dupRaw + " (first one used)")
  }

  # Copy selected JPG + matching CR3 to output
  Log "Copying selected set to 03_Selected_JPG+RAW..."

  $copiedJ = 0
  $copiedR = 0
  $missingR = 0

  $totalSel = $selectedJpgs.Count
  $n = 0

  foreach ($j in $selectedJpgs) {
    $n += 1
    $pct2 = [int](($n * 100) / $totalSel)
    Write-Progress -Activity "Copying selected files" -Status ("{0}/{1}  {2}" -f $n, $totalSel, $j.Name) -PercentComplete $pct2

    # Copy JPG from 02 to 03
    $dstJ = Join-Path $outDir $j.Name
    Copy-Item -LiteralPath $j.FullName -Destination $dstJ -Force
    $copiedJ += 1

    # Copy matching CR3 from 01 to 03
    $key = $j.BaseName.ToLowerInvariant()
    if ($rawIndex.ContainsKey($key)) {
      $srcR = $rawIndex[$key]
      $dstR = Join-Path $outDir (Split-Path $srcR -Leaf)
      Copy-Item -LiteralPath $srcR -Destination $dstR -Force
      $copiedR += 1
    } else {
      $missingR += 1
      Log ("WARN: missing CR3 for: " + $j.BaseName)
    }
  }
  Write-Progress -Activity "Copying selected files" -Completed

  Log ("Copied to 03_Selected_JPG+RAW: JPG=" + $copiedJ + ", CR3=" + $copiedR + ", MissingCR3=" + $missingR)

  # Open output folder
  Log "Opening output folder..."
  Invoke-Item $outDir

  # Completion popup
  $msg = "Completed.`n`nOutput:`n" + $outDir + "`n`nCopied:`nJPG: " + $copiedJ + "`nCR3: " + $copiedR + "`nMissing CR3: " + $missingR
  [System.Windows.Forms.MessageBox]::Show($msg, "SelectBySelectedJpg - Done", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null

  Log "DONE (01_All unchanged)."

} catch {
  Write-Host ""
  Write-Host ("ERROR: " + $_.Exception.Message) -ForegroundColor Red
  Write-Host ""

  # Error popup
  [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "SelectBySelectedJpg - ERROR", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null

  throw
}
