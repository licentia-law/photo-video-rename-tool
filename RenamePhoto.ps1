#requires -version 3
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Security

# =========================
# RenamePhoto v6.9 (UTF-8 filename charset fix)
#
# exiftool path:
#   <scriptDir>\exiftool\exiftool.exe
#
# GUI:
#   pick source folder -> pick destination folder
#
# Supports:
#   PHOTO: CR3/JPG/JPEG/PNG
#   VIDEO: MP4/MOV/WMV
#
# Rename format:
#   YYYY-MM-DD_HH-mm-ss_<ID>_<DEVICE>.EXT
#   - If filename matches IMG_#### -> ID = #### (keep digits)
#   - Else -> ID = hash6("filename|filesize")  (stable across runs)
#   - DEVICE = EOSR7 / 200D2 / IPHONE, else UNKNOWN
#
# Video timestamp priority (MOV-friendly):
#   QuickTime:CreateDate
#   QuickTime:MediaCreateDate
#   MediaCreateDate
#   CreateDate
#   (fallback) LastWriteTime
#
# Folder structure (no device folders):
#   <DST>\PHOTO\YYYY\MM\DD
#   <DST>\VIDEO\YYYY\MM\DD
#
# LogMode:
#   SUMMARY (default) : ERROR only (copy/skip are counters)
#   FULL             : COPY/SKIP/ERROR logged
#   OFF              : no log file (fastest)
#
# Resume:
#   enabled by default (can be turned off)
#   uses resume state file to skip already-processed sources
# =========================

# -------------------------
# USER OPTIONS
# -------------------------
$LogMode      = "SUMMARY"   # "SUMMARY" | "FULL" | "OFF"
$EnableResume = $true

# Optional: log sampling for COPY lines in SUMMARY mode (0 = no sampling)
# Example: 0.01 => log about 1% of COPY lines
$CopySampleRate = 0.0

# -------------------------
# Paths
# -------------------------
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$exiftool  = Join-Path $scriptDir "exiftool\exiftool.exe"
if (!(Test-Path -LiteralPath $exiftool)) {
    throw ("exiftool.exe not found: " + $exiftool)
}

# -------------------------
# Helpers
# -------------------------
function Pick-Folder([string]$title) {
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = $title
    $dlg.ShowNewFolderButton = $true

    # Prevent "2nd dialog not showing" by using an invisible TopMost owner form
    $owner = New-Object System.Windows.Forms.Form
    $owner.TopMost = $true
    $owner.StartPosition = "Manual"
    $owner.Location = New-Object System.Drawing.Point(-2000, -2000)
    $owner.Size = New-Object System.Drawing.Size(1, 1)
    $owner.Show()
    $owner.Activate()

    try {
        $r = $dlg.ShowDialog($owner)
        if ($r -ne [System.Windows.Forms.DialogResult]::OK) { return $null }
        return $dlg.SelectedPath
    }
    finally {
        $dlg.Dispose()
        $owner.Close()
        $owner.Dispose()
    }
}

function Try-ParseExifDate([string]$s) {
    if ([string]::IsNullOrWhiteSpace($s)) { return $null }
    try { return [datetime]::ParseExact($s, "yyyy:MM:dd HH:mm:ss", $null) } catch { return $null }
}

function Get-DeviceTag([hashtable]$meta) {
    # Try to identify iPhone via Make/Model if available; otherwise use Canon model mapping.
    $modelRaw = $meta.model
    $makeRaw  = $meta.make

    $m = ""
    $k = ""
    if ($modelRaw) { $m = $modelRaw.ToLower() }
    if ($makeRaw)  { $k = $makeRaw.ToLower() }

    # iPhone detection
    if (($k -like "*apple*") -or ($m -like "*iphone*")) { return "IPHONE" }

    # Canon mapping
    if ($m -like "*eos r7*") { return "EOSR7" }

    if ($m -like "*200d*" -and ($m -like "*ii*" -or $m -like "*mark ii*" -or $m -like "*mkii*" -or $m -like "*mark2*" -or $m -like "*mark 2*")) {
        return "200D2"
    }
    if ($m -like "*eos 200d*" -or ($m -like "*200d*" -and -not ($m -like "*r7*"))) { return "200D2" }

    return "UNKNOWN"
}

function Get-Sha1Hex([string]$text) {
    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
        $hash  = $sha1.ComputeHash($bytes)
        return ([System.BitConverter]::ToString($hash) -replace "-", "").ToLower()
    }
    finally {
        $sha1.Dispose()
    }
}

function Get-IdSmartHash([System.IO.FileInfo]$file) {
    if ($null -eq $file) { return "000000" }

    # IMG_0300.JPG => 0300
    if ($file.BaseName -match '^IMG_(\d+)$') {
        return $Matches[1]
    }

    # stable hash6(filename|filesize)
    $seed = ($file.Name + "|" + $file.Length)
    $hex  = Get-Sha1Hex $seed
    return $hex.Substring(0, 6).ToUpper()
}

# Fast metadata via exiftool -T
# NOTE: Added -charset filename=utf8 to remove "FileName encoding must be specified" warnings.
# Order:
#   DateTimeOriginal | Make | Model |
#   QuickTime:CreateDate | QuickTime:MediaCreateDate |
#   MediaCreateDate | CreateDate
function Read-MetaFast([string]$path) {
    $line = & $exiftool `
        -charset filename=utf8 `
        -s -s -s -T `
        -DateTimeOriginal -Make -Model `
        -QuickTime:CreateDate -QuickTime:MediaCreateDate `
        -MediaCreateDate -CreateDate `
        $path

    $parts = $line -split "`t", -1
    while ($parts.Count -lt 7) { $parts += "" }

    return @{
        dto   = $parts[0]
        make  = $parts[1]
        model = $parts[2]
        qtcd  = $parts[3]
        qtmcd = $parts[4]
        mcd   = $parts[5]
        cd    = $parts[6]
    }
}

function Get-VideoDateTime([hashtable]$meta) {
    $dt = Try-ParseExifDate $meta.qtcd
    if (-not $dt) { $dt = Try-ParseExifDate $meta.qtmcd }
    if (-not $dt) { $dt = Try-ParseExifDate $meta.mcd }
    if (-not $dt) { $dt = Try-ParseExifDate $meta.cd }
    return $dt
}

function New-DirIfMissing([string]$p) {
    if (!(Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Path $p | Out-Null }
}

# -------------------------
# GUI input
# -------------------------
$srcRoot = Pick-Folder "Select SOURCE folder (where photos/videos are)"
if (-not $srcRoot) { return }

$dstRoot = Pick-Folder "Select DEST folder (where to copy renamed files)"
if (-not $dstRoot) { return }
New-DirIfMissing $dstRoot

# -------------------------
# Logs & Resume files
# -------------------------
$ts = Get-Date -Format "yyyyMMdd_HHmmss"

$logPath    = $null
$errLogPath = $null

if ($LogMode -ne "OFF") {
    $logPath    = Join-Path $dstRoot ("rename_copy_log_{0}.txt" -f $ts)
    $errLogPath = Join-Path $dstRoot ("rename_copy_error_{0}.txt" -f $ts)

    ("Start: " + (Get-Date)) | Out-File -FilePath $logPath -Encoding utf8
    ("SCRIPT: " + $scriptDir) | Out-File -FilePath $logPath -Append -Encoding utf8
    ("EXIFTOOL: " + $exiftool) | Out-File -FilePath $logPath -Append -Encoding utf8
    ("SRC: " + $srcRoot) | Out-File -FilePath $logPath -Append -Encoding utf8
    ("DST: " + $dstRoot) | Out-File -FilePath $logPath -Append -Encoding utf8
    ("LogMode: " + $LogMode) | Out-File -FilePath $logPath -Append -Encoding utf8
    ("Resume: " + $EnableResume) | Out-File -FilePath $logPath -Append -Encoding utf8
    "" | Out-File -FilePath $logPath -Append -Encoding utf8

    ("Start: " + (Get-Date)) | Out-File -FilePath $errLogPath -Encoding utf8
}

# Resume state file (store processed source file fingerprints)
$resumePath = Join-Path $dstRoot "resume_state_v6.9.txt"
$resumeSet = New-Object "System.Collections.Generic.HashSet[string]"
if ($EnableResume -and (Test-Path -LiteralPath $resumePath)) {
    try {
        Get-Content -LiteralPath $resumePath -Encoding UTF8 | ForEach-Object {
            if ($_) { [void]$resumeSet.Add($_) }
        }
    } catch { }
}

# Existing destination cache (HashSet)
$existingSet = New-Object "System.Collections.Generic.HashSet[string]"
# We'll cache only file names (case-insensitive) within PHOTO/VIDEO.
# For Windows this is usually enough and very fast.
function Cache-Existing([string]$root) {
    $photo = Join-Path $root "PHOTO"
    $video = Join-Path $root "VIDEO"
    if (Test-Path -LiteralPath $photo) {
        Get-ChildItem -LiteralPath $photo -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
            [void]$existingSet.Add($_.FullName.ToLower())
        }
    }
    if (Test-Path -LiteralPath $video) {
        Get-ChildItem -LiteralPath $video -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
            [void]$existingSet.Add($_.FullName.ToLower())
        }
    }
}
Cache-Existing $dstRoot

# -------------------------
# Collect files
# -------------------------
$files = Get-ChildItem -LiteralPath $srcRoot -Recurse -File | Where-Object {
    $_.Extension -match '^\.(CR3|JPG|JPEG|PNG|MP4|MOV|WMV)$'
}

$total = $files.Count
$idx = 0

# -------------------------
# Counters
# -------------------------
$copied = 0
$skipped = 0
$resumeSkipped = 0
$errors = 0
$fallback = 0

# Timing
$start = Get-Date
$lastProgressUpdate = Get-Date

# helper: format time span
function Format-TS([TimeSpan]$ts) {
    return "{0:00}:{1:00}:{2:00}" -f [int]$ts.TotalHours, $ts.Minutes, $ts.Seconds
}

# optional: should we log copy line (sampling)
function Should-LogCopySample([double]$rate) {
    if ($rate -le 0) { return $false }
    return ((Get-Random) / 2147483647.0) -lt $rate
}

# fingerprint for resume
function Get-ResumeKey([System.IO.FileInfo]$f) {
    # stable enough fingerprint for "same source file"
    return ("{0}|{1}|{2}" -f $f.FullName, $f.Length, $f.LastWriteTimeUtc.Ticks)
}

# -------------------------
# Main loop
# -------------------------
foreach ($f in $files) {
    $idx++

    # Resume skip check
    $resumeKey = $null
    if ($EnableResume) {
        $resumeKey = Get-ResumeKey $f
        if ($resumeSet.Contains($resumeKey)) {
            $resumeSkipped++
            continue
        }
    }

    try {
        $ext = $f.Extension.ToUpper()
        $isVideo = ($ext -in @(".MP4", ".MOV", ".WMV"))
        $mediaFolder = $(if ($isVideo) { "VIDEO" } else { "PHOTO" })

        # Read metadata
        $meta = Read-MetaFast $f.FullName
        $device = Get-DeviceTag $meta

        # Timestamp
        $dt = $null
        if ($isVideo) {
            $dt = Get-VideoDateTime $meta
        } else {
            $dt = Try-ParseExifDate $meta.dto
        }
        if (-not $dt) {
            $dt = $f.LastWriteTime
            $fallback++
        }

        # ID
        $id = Get-IdSmartHash $f

        # Destination directory: <DST>\PHOTO|VIDEO\YYYY\MM\DD
        $dstDir = Join-Path $dstRoot (Join-Path $mediaFolder (Join-Path ($dt.ToString("yyyy")) (Join-Path ($dt.ToString("MM")) ($dt.ToString("dd")))))
        New-DirIfMissing $dstDir

        # Filename: YYYY-MM-DD_HH-mm-ss_<ID>_<DEVICE>.EXT
        $base = ("{0}_{1}_{2}_{3}" -f $dt.ToString("yyyy-MM-dd"), $dt.ToString("HH-mm-ss"), $id, $device)
        $target = Join-Path $dstDir ($base + $ext)

        # Fast skip by cached set
        if ($existingSet.Contains($target.ToLower()) -or (Test-Path -LiteralPath $target)) {
            $skipped++
            if ($LogMode -eq "FULL" -and $logPath) {
                ("SKIP: " + $f.FullName + " -> " + $target) | Out-File -FilePath $logPath -Append -Encoding utf8
            }
            if ($EnableResume -and $resumeKey) { [void]$resumeSet.Add($resumeKey) }
            continue
        }

        # If collision, add suffix
        $i = 1
        while (Test-Path -LiteralPath $target) {
            $target = Join-Path $dstDir (("{0}_{1:D2}{2}" -f $base, $i, $ext))
            $i++
        }

        Copy-Item -LiteralPath $f.FullName -Destination $target
        $copied++

        # Update existing cache
        [void]$existingSet.Add($target.ToLower())

        # Log
        if ($LogMode -eq "FULL" -and $logPath) {
            ("COPY: " + $f.FullName + " -> " + $target) | Out-File -FilePath $logPath -Append -Encoding utf8
        }
        elseif ($LogMode -eq "SUMMARY" -and $logPath -and (Should-LogCopySample $CopySampleRate)) {
            ("COPY(sample): " + $f.FullName + " -> " + $target) | Out-File -FilePath $logPath -Append -Encoding utf8
        }

        # Resume state append (write-through in memory; flush periodically to file)
        if ($EnableResume -and $resumeKey) {
            if ($resumeSet.Add($resumeKey)) {
                # append to resume file directly for crash safety (small text line)
                try { $resumeKey | Out-File -FilePath $resumePath -Append -Encoding utf8 } catch { }
            }
        }
    }
    catch {
        $errors++
        $msgErr = ("ERROR: " + $f.FullName + " -> " + $_.Exception.Message)

        if ($LogMode -ne "OFF" -and $errLogPath) {
            $msgErr | Out-File -FilePath $errLogPath -Append -Encoding utf8
        }
        if ($LogMode -eq "FULL" -and $logPath) {
            $msgErr | Out-File -FilePath $logPath -Append -Encoding utf8
        }
    }

    # Progress + timing
    $now = Get-Date
    $elapsed = $now - $start
    $elapsedSec = [Math]::Max(0.001, $elapsed.TotalSeconds)

    $done = $idx
    $rate = $done / $elapsedSec
    $remaining = [Math]::Max(0, ($total - $done))
    $etaSec = $(if ($rate -gt 0) { $remaining / $rate } else { 0 })
    $eta = [TimeSpan]::FromSeconds($etaSec)
    $totalEst = [TimeSpan]::FromSeconds($elapsed.TotalSeconds + $eta.TotalSeconds)

    $pct = 0
    if ($total -gt 0) { $pct = [int](($done / [double]$total) * 100) }

    Write-Progress -Activity "Renaming and copying..." `
        -Status ("{0}/{1} copied:{2} skipped:{3} resumeSkip:{4} errors:{5} | elapsed:{6} ETA:{7} total(est):{8}" -f `
            $done,$total,$copied,$skipped,$resumeSkipped,$errors,(Format-TS $elapsed),(Format-TS $eta),(Format-TS $totalEst)) `
        -PercentComplete $pct
}

Write-Progress -Activity "Renaming and copying..." -Completed

# Final timing
$end = Get-Date
$elapsedAll = $end - $start
$elapsedAllStr = Format-TS $elapsedAll
$avgSpeed = 0.0
if ($total -gt 0 -and $elapsedAll.TotalSeconds -gt 0) {
    $avgSpeed = [Math]::Round($total / $elapsedAll.TotalSeconds, 2)
}

if ($LogMode -ne "OFF" -and $logPath) {
    ("End: " + (Get-Date)) | Out-File -FilePath $logPath -Append -Encoding utf8
    ("Summary: total={0} copied={1} skipped={2} resumeSkip={3} fallback={4} errors={5} elapsed={6} avg={7} files/sec" -f `
        $total,$copied,$skipped,$resumeSkipped,$fallback,$errors,$elapsedAllStr,$avgSpeed) | Out-File -FilePath $logPath -Append -Encoding utf8
}

# SAFE MessageBox (no parsing issues)
$mainLogText = $(if ($logPath) { $logPath } else { "(OFF)" })
$resumeText  = $(if ($EnableResume) { $resumePath } else { "(disabled)" })

$msg = @"
Done! (v6.9)

Total: $total
Copied: $copied
Skipped: $skipped
ResumeSkipped: $resumeSkipped
Fallback(LastWriteTime): $fallback
Errors: $errors
Elapsed: $elapsedAllStr
AvgSpeed: $avgSpeed files/sec

DST: $dstRoot
MainLog: $mainLogText
ErrorLog: $errLogPath
ResumeState: $resumeText
"@

[void][System.Windows.Forms.MessageBox]::Show(
    $msg,
    "Rename Copy Finished",
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
)

Start-Process explorer.exe $dstRoot
