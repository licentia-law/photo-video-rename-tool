# 📷 Photo & Video Rename Tool (v6.9.1)

This tool is a Windows utility built with PowerShell and **exiftool**  
that automatically renames and organizes photo and video files based on capture time.

It runs with a GUI and can be executed by double-click.

---

## ✨ Key Features

- Automatic scan and batch processing of photo and video files
- Capture time extraction using EXIF / QuickTime metadata
- Automatic detection of Canon EOS R7 / EOS 200D II / iPhone
- Unsupported devices labeled as `UNKNOWN`
- Rule-based filename renaming
- PHOTO / VIDEO folder separation
- Progress %, elapsed time, ETA, average speed (files/sec)
- Resume (crash recovery) support
- Fast skip using HashSet cache for existing files

---

## 🆕 v6.9.1 Updates

- **Official HEIC support**
  - Real JPG conversion using ImageMagick (`magick.exe`)
  - Conversion quality: quality 92
  - Metadata copied from original HEIC to converted JPG
- **Automatic tool discovery**
  - Auto-detect `tools\exiftool\exiftool*.exe`
  - Use `tools\magick\magick.exe` for HEIC conversion
- Stable processing even with non-ASCII (e.g., Korean) paths

---

## 📁 Supported File Types

### Photos
- CR3
- JPG / JPEG
- PNG
- HEIC (converted)

### Videos
- MP4
- MOV
- WMV

---

## 🏷️ Filename Format

```
YYYY-MM-DD_HH-mm-ss_<ID>_<DEVICE>.EXT
```

### ID Rules
- `IMG_0300.JPG` → keep `0300`
- Other files → 6-character stable hash based on filename + size

### DEVICE Values
- EOSR7
- 200D2
- IPHONE
- UNKNOWN

---

## 🗂️ Folder Structure

```
DESTINATION
├─ PHOTO
│  └─ YYYY / MM / DD
└─ VIDEO
   └─ YYYY / MM / DD
```

---

## 📝 Log Modes

- SUMMARY (default)
  - Only ERROR written to file
  - COPY / SKIP are counters only
- FULL
  - COPY / SKIP / ERROR logged
- OFF
  - No log file (fastest)

---

## ⚙️ Requirements

- Windows 10 / 11
- PowerShell 3.0 or later
- exiftool
- ImageMagick (for HEIC conversion)
