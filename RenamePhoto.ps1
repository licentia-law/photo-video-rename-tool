#requires -version 3
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Security

# =========================
# v6.3 - Rename + Copy Tool
#
# exiftool path:
#   <scriptDir>\exiftool\exiftool.exe
#
# GUI:
#   pick source folder -> pick destination folder
#
# Supports:
#   PHOTO: CR3/JPG/JPEG
#   VIDEO: MP4/MOV/WMV
#
# Rename format:
#   YYYY-MM-DD_HH-mm-ss_<ID>_<CAM>.EXT
#   - If filename matches IMG_#### -> ID = #### (keep as-is)
#   - Else -> ID = hash6( "filename|filesize" )  (stable across runs)
#   - CAM = EOSR7 or 200D2, else UNKNOWN
#
# Video timestamp priority (MOV-friendly):
#   QuickTime:CreateDate
#   QuickTime:MediaCreateDate
#   MediaCreateDate
#   CreateDate
#   (fallback) LastWriteTime
# =========================

# --- exiftool: script folder relative ---
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$exiftool  = Join-Path $scriptDir "exiftool\exiftool.exe"
if (!(Test-Path -LiteralPath $exiftool)) {
    throw ("exiftool.exe not found: " + $exiftool)
}

function Pick-Folder([string]$title) {
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = $title
    $dlg.ShowNewFolderButton = $true

    # Make sure dialog is visible (prevents "second dialog not showing")
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
    # exiftool typical format: yyyy:MM:dd HH:mm:ss
    try { return [datetime]::ParseExact($s, "yyyy:MM:dd HH:mm:ss", $null) } catch { return $null }
}

# 모델명 -> EOSR7/200D2만 인정, 아니면 UNKNOWN
function Get-CameraKeyOrUnknown([string]$modelRaw) {
    if ([string]::IsNullOrWhiteSpace($modelRaw)) { return "UNKNOWN" }
    $m = $modelRaw.ToLower()

    if ($m -like "*eos r7*") { return "EOSR7" }

    if ($m -like "*200d*" -and ($m -like "*ii*" -or $m -like "*mark ii*" -or $m -like "*mkii*" -or $m -like "*mark2*" -or $m -like "*mark 2*")) {
        return "200D2"
    }
    if ($m -like "*eos 200d*" -or ($m -like "*200d*" -and -not ($m -like "*r7*"))) {
        return "200D2"
    }

    return "UNKNOWN"
}

# SHA1 -> hex string
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

# ID rule:
# - IMG_0300 => 0300 (keep as-is)
# - else => hash6("filename|filesize")
function Get-IdSmartHash([System.IO.FileInfo]$file) {
    if ($null -eq $file) { return "000000" }

    if ($file.BaseName -match '^IMG_(\d+)$') {
        return $Matches[1]
    }

    $seed = ($file.Name + "|" + $file.Length)  # Option C
    $hex  = Get-Sha1Hex $seed
    return $hex.Substring(0, 6).ToUpper()
}

# Fast metadata via exiftool -T
# Order:
#   DateTimeOriginal | Model |
#   QuickTime:CreateDate | QuickTime:MediaCreateDate |
#   MediaCreateDate | CreateDate
function Read-MetaFast([string]$path) {
    $line = & $exiftool -s -s -s -T `
        -DateTimeOriginal -Model `
        -QuickTime:CreateDate -QuickTime:MediaCreateDate `
        -MediaCreateDate -CreateDate `
        $path

    $parts = $line -split "`t", -1
    while ($parts.Count -lt 6) { $parts += "" }

    return @{
        dto   = $parts[0]
        model = $parts[1]
        qtcd  = $parts[2]   # QuickTime:CreateDate
        qtmcd = $parts[3]   # QuickTime:MediaCreateDate
        mcd   = $parts[4]   # MediaCreateDate
        cd    = $parts[5]   # CreateDate
    }
}

function Get-VideoDateTime([hashtable]$meta) {
    # Priority for video:
    # 1) QuickTime:CreateDate
    # 2) QuickTime:MediaCreateDate
    # 3) MediaCreateDate
    # 4) CreateDate
    $dt = Try-ParseExifDate $meta.qtcd
    if (-not $dt) { $dt = Try-ParseExifDate $meta.qtmcd }
    if (-not $dt) { $dt = Try-ParseExifDate $meta.mcd }
    if (-not $dt) { $dt = Try-ParseExifDate $meta.cd }
    return $dt
}

# ===== GUI input (2 folder pickers) =====
$srcRoot = Pick-Folder "Select SOURCE folder (where photos/videos are)"
if (-not $srcRoot) { return }

$dstRoot = Pick-Folder "Select DEST folder (where to copy renamed files)"
if (-not $dstRoot) { return }

if (!(Test-Path $dstRoot)) { New-Item -ItemType Directory -Path $dstRoot | Out-Null }

# ===== counters & log =====
$copied = 0
$skipped = 0
$errors = 0
$fallback = 0

$logPath = Join-Path $dstRoot ("rename_copy_log_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
("Start: " + (Get-Date)) | Out-File -FilePath $logPath -Encoding utf8
("SCRIPT: " + $scriptDir) | Out-File -FilePath $logPath -Append -Encoding utf8
("EXIFTOOL: " + $exiftool) | Out-File -FilePath $logPath -Append -Encoding utf8
("SRC: " + $srcRoot) | Out-File -FilePath $logPath -Append -Encoding utf8
("DST: " + $dstRoot) | Out-File -FilePath $logPath -Append -Encoding utf8
"" | Out-File -FilePath $logPath -Append -Encoding utf8

# ===== collect files =====
$files = Get-ChildItem $srcRoot -Recurse -File | Where-Object {
    $_.Extension -match '^\.(CR3|JPG|JPEG|MP4|MOV|WMV)$'
}

$total = $files.Count
$idx = 0

foreach ($f in $files) {
    $idx++
    $pct = 0
    if ($total -gt 0) { $pct = [int](($idx / [double]$total) * 100) }

    Write-Progress -Activity "Renaming and copying..." `
        -Status ("{0}/{1} copied:{2} skipped:{3} errors:{4}" -f $idx,$total,$copied,$skipped,$errors) `
        -PercentComplete $pct

    try {
        $ext = $f.Extension.ToUpper()
        $isVideo = ($ext -in @(".MP4", ".MOV", ".WMV"))
        $mediaFolder = $(if ($isVideo) { "VIDEO" } else { "PHOTO" })

        # Read metadata
        $meta = Read-MetaFast $f.FullName
        $cam  = Get-CameraKeyOrUnknown $meta.model

        # Decide timestamp
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

        # ID (IMG_#### keep digits, else hash6(filename|filesize))
        $id = Get-IdSmartHash $f

        # Destination folder: CAM\PHOTO|VIDEO\YYYY\MM\DD
        $dstDir = Join-Path $dstRoot (Join-Path $cam (Join-Path $mediaFolder (Join-Path ($dt.ToString("yyyy")) (Join-Path ($dt.ToString("MM")) ($dt.ToString("dd"))))))
        if (!(Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir | Out-Null }

        # Filename format
        $base = ("{0}_{1}_{2}_{3}" -f $dt.ToString("yyyy-MM-dd"), $dt.ToString("HH-mm-ss"), $id, $cam)
        $target = Join-Path $dstDir ($base + $ext)

        # Existing -> skip, conflict -> suffix
        if (Test-Path $target) {
            $skipped++
            ("SKIP: " + $f.FullName + " -> " + $target) | Out-File -FilePath $logPath -Append -Encoding utf8
            continue
        }

        $i = 1
        while (Test-Path $target) {
            $target = Join-Path $dstDir (("{0}_{1:D2}{2}" -f $base, $i, $ext))
            $i++
        }

        Copy-Item -LiteralPath $f.FullName -Destination $target
        $copied++
        ("COPY: " + $f.FullName + " -> " + $target) | Out-File -FilePath $logPath -Append -Encoding utf8
    }
    catch {
        $errors++
        ("ERROR: " + $f.FullName + " -> " + $_.Exception.Message) | Out-File -FilePath $logPath -Append -Encoding utf8
    }
}

Write-Progress -Activity "Renaming and copying..." -Completed
("End: " + (Get-Date)) | Out-File -FilePath $logPath -Append -Encoding utf8

$msg =
    "Done!" + "`r`n`r`n" +
    ("Copied: {0}`r`n" -f $copied) +
    ("Skipped: {0}`r`n" -f $skipped) +
    ("Fallback(LastWriteTime): {0}`r`n" -f $fallback) +
    ("Errors: {0}`r`n`r`n" -f $errors) +
    ("DST: {0}`r`n" -f $dstRoot) +
    ("Log: {0}" -f $logPath)

[void][System.Windows.Forms.MessageBox]::Show($msg, "Rename Copy Finished", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
Start-Process explorer.exe $dstRoot
