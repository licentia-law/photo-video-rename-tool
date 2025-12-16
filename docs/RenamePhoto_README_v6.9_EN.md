# 📷 Photo & Video Rename & Organizer Tool (v6.9)

This Windows tool uses **PowerShell** and **exiftool**  
to automatically rename and organize photo and video files  
based on capture time.

It runs with a GUI — **just double-click to use**.

---

## ✨ Key Features (v6.9)

- Automatic photo & video scanning
- Capture time extraction via EXIF / QuickTime metadata
- Canon EOS R7 / EOS 200D II / **iPhone detection**
- Unknown devices handled as `UNKNOWN`
- Rule-based automatic file renaming
- **PHOTO / VIDEO only folder structure (no camera folders)**
- PNG photo support
- MP4 / MOV / WMV video support
- **High-speed skip using HashSet caching**
- **Resume support**
  - Already processed files are skipped automatically
- Progress display
  - Percentage
  - Elapsed time / ETA
  - Average processing speed (files/sec)
- Configurable log modes
  - `SUMMARY` (default): ERROR only
  - `FULL`: COPY / SKIP / ERROR
  - `OFF`: No file logging (maximum speed)

---

## 📁 Supported File Types

### 📸 Photos
- CR3
- JPG / JPEG
- PNG

### 🎥 Videos
- MP4
- MOV
- WMV

---

## 🏷️ File Naming Rule

```
YYYY-MM-DD_HH-mm-ss_<ID>_<DEVICE>.EXT
```

### ID Rules
- `IMG_0300.JPG` → keeps `0300`
- Other files → **6-digit stable hash (filename + filesize)**

### DEVICE Values
- `EOSR7`
- `200D2`
- `IPHONE`
- `UNKNOWN`

---

## 🕒 Capture Time Priority

### Photos
1. DateTimeOriginal
2. LastWriteTime (fallback)

### Videos (MOV optimized)
1. QuickTime:CreateDate
2. QuickTime:MediaCreateDate
3. MediaCreateDate
4. CreateDate
5. LastWriteTime (fallback)

---

## 🗂️ Folder Structure

```
<DESTINATION>
├─ PHOTO
│  └─ YYYY / MM / DD
└─ VIDEO
   └─ YYYY / MM / DD
```

---

## 📌 Recommended Environment
- Windows 10 / 11
- PowerShell 5.x+
- exiftool (bundled under `exiftool/` folder)

---

## 📜 License
Free for personal and educational use
