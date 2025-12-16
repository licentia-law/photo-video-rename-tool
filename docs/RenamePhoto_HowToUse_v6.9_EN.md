# 📘 How To Use (Beginner Guide) – v6.9

This document explains how to use **Photo & Video Rename + Copy Tool (v6.9)**  
step by step, even for first-time users.

👉 **No command-line knowledge required. Just double-click to run.**

---

## 1️⃣ Requirements

Make sure the following files are located in the **same folder**:

```
RenamePhoto.bat
RenamePhoto.ps1
exiftool/
 └─ exiftool.exe
```

⚠️ The tool will not run without **exiftool.exe**.

---

## 2️⃣ How to Run

1. Double-click **RenamePhoto.bat**
2. Two folder selection dialogs will appear:
   - 📂 Source folder (original photos/videos)
   - 📂 Destination folder (organized output)
3. Processing starts automatically.

---

## 3️⃣ While Running (v6.9 Improvements)

The console progress window shows:

- Overall progress (%)
- Current / total file count
- COPY count
- SKIP count
- ERROR count
- ⏱ **Elapsed time**
- ⏳ **Estimated remaining time (ETA)**
- ⚡ **Average processing speed (files/sec)**

⚠️ Do not close the window until processing finishes.

---

## 4️⃣ Skip & Resume Handling (v6.9 Key Features)

### ✅ High-speed Skip
- Existing destination files are **cached once at startup (HashSet)**
- File existence checks are performed in memory
- Remains fast even with large collections

### 🔁 Resume Support
- Uses logs from previous runs
- **Already processed files are skipped automatically**
- Restarting the tool continues from where it stopped

---

## 5️⃣ Logging Strategy (Recommended)

The default logging strategy prioritizes performance.

- `SUMMARY` (default)
  - COPY counted only
  - ERROR written to file
- `FULL`
  - COPY / SKIP / ERROR all logged (debug use)
- `OFF`
  - No log file (maximum speed)

👉 **SUMMARY mode is recommended** for most users.

---

## 6️⃣ When Finished

After completion:

- Completion popup shows
  - Total files
  - Average speed
  - Total elapsed time
- Destination folder opens automatically
- Log file is created (depending on mode)

Example:
```
rename_copy_log_20251216_135703.txt
```

---

## 7️⃣ Result Folder Structure

```
<DESTINATION>
├─ PHOTO
│  └─ YYYY
│     └─ MM
│        └─ DD
└─ VIDEO
   └─ YYYY
      └─ MM
         └─ DD
```

---

## 8️⃣ FAQ

### ❓ Are original files deleted?
No.  
👉 All operations are **copy-only**. Originals remain untouched.

---

### ❓ What if many files share the same timestamp?
No problem.

- `IMG_####` filenames keep their number
- Other files receive a unique hash-based ID

👉 This guarantees safe, collision-free filenames.

---

## ✅ Summary

- Double-click → Select 2 folders → Done
- Optimized for large photo/video collections
- Safe resume after interruption
- Beginner-friendly
