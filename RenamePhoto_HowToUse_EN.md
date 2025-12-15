# 📘 How To Use (Beginner Guide)

This document explains **how to use the Photo & Video Rename Tool** step by step.  
No command-line knowledge is required.

---

## 1️⃣ Requirements

Make sure the following files are located **in the same folder**:

```
RenamePhoto.bat
RenamePhoto.ps1
exiftool/
 └─ exiftool.exe
```

> ⚠️ The tool will not work without **exiftool.exe**.

---

## 2️⃣ How to Run

1. Double-click **RenamePhoto.bat**
2. When prompted:
   - Select the **SOURCE folder** (original photos/videos)
   - Select the **DESTINATION folder** (organized output)
3. Processing starts automatically.

---

## 3️⃣ While Running

- A progress bar shows current progress (%)
- Status text shows:
  - Copied files
  - Skipped files
  - Errors

⚠️ Do **not close the window** until the process finishes.

---

## 4️⃣ When Finished

- A completion popup appears
- The destination folder opens automatically
- A log file is created

Example log file:
```
rename_copy_log_20251215_110827.txt
```

---

## 5️⃣ Result Example

```
EOSR7
 └─ PHOTO
    └─ 2025
       └─ 12
          └─ 15
             └─ 2025-12-15_11-08-27_0300_EOSR7.JPG
```

---

## 6️⃣ Frequently Asked Questions

### ❓ Will original files be deleted?
No.  
**Files are copied only. Originals remain untouched.**

---

### ❓ What if many files have the same timestamp?
The tool automatically generates **unique IDs**, so no overwriting occurs.

---

### ❓ What if camera information is missing?
Files are marked as:
```
UNKNOWN
```

This applies to both file names and folder structure.

---

## 7️⃣ Troubleshooting

1. Check the log file first
2. If the issue persists:
   - Take a screenshot of the error
   - Open a GitHub Issue with the log attached

---

## ✅ Summary

- Run BAT → Select 2 folders → Done
- No configuration required
- Safe for beginners

Enjoy organizing your photos and videos 📸🎥
