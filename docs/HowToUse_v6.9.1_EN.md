# 📘 How To Use (Beginner Guide) – v6.9.1

This document explains how to use **Photo & Video Rename + Copy Tool (v6.9.1)**  
step by step, even for first-time users.

👉 **No command-line knowledge required. Just double-click to run.**

---

## 1️⃣ Requirements

The following files and folders must be located in the **same directory**:

```
RenamePhoto.bat
RenamePhoto.ps1
tools/
 ├─ exiftool/
 │  └─ exiftool*.exe
 └─ magick/
    └─ magick.exe
```

- ImageMagick is required for HEIC processing

---

## 2️⃣ How to Run

1. Double-click **RenamePhoto.bat**
2. Two folder selection dialogs will appear:
   - 📂 Source folder (original photos/videos)
   - 📂 Destination folder (organized output)
3. Processing starts automatically.

---

## 3️⃣ While Running

The progress window shows:

- Overall progress (%)
- Current / total file count
- COPY / SKIP / ERROR counts
- ⏱ Elapsed time
- ⏳ Estimated remaining time (ETA)
- ⚡ Average speed (files/sec)

---

## 4️⃣ HEIC Processing (v6.9.1)

- HEIC files are automatically converted to JPG.
- Conversion quality: **quality 92**
- Metadata is copied from the original HEIC to the JPG.
- The converted JPG is then processed as a normal photo.

---

## 5️⃣ Skip & Resume Handling

### ✅ Fast Skip
- Existing destination files are cached once at startup (HashSet).
- Skip checks are done in memory for maximum speed.

### 🔁 Resume Support
- Files processed in previous runs are skipped automatically.
- Restarting the tool continues from where it stopped.

---

## 6️⃣ Logging Modes

- `SUMMARY` (default)
  - COPY counted only
  - ERROR written to file
- `FULL`
  - COPY / SKIP / ERROR all logged
- `OFF`
  - No log file (fastest)

---

## 7️⃣ When Finished

- Completion popup is shown
- Average speed and total elapsed time displayed
- Destination folder opens automatically

---

## 8️⃣ Result Folder Structure

```
<DESTINATION>
├─ PHOTO
│  └─ YYYY / MM / DD
└─ VIDEO
   └─ YYYY / MM / DD
```

---

## 9️⃣ FAQ

### ❓ Are original files deleted?
No. All operations are **copy-only**.
