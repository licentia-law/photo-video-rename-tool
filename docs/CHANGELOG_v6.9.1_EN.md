# 📜 CHANGELOG

This document records the version history of the **Photo & Video Rename + Copy Tool**.

---

## v6.9.1 (2025-12)

### 🆕 Format & Tool Compatibility Improvements
- **Official HEIC support**
  - Real JPG conversion using ImageMagick (`magick.exe`)
  - Conversion quality: quality 92
  - Metadata copied from original HEIC to converted JPG
- **Automatic tool discovery**
  - Auto-detect `tools/exiftool/exiftool*.exe`
  - Use `tools/magick/magick.exe`

---

## v6.9 (2025-12)

### 🚀 Execution Stability & UX Improvements
- **Resume (Interrupted Run Recovery) support**
  - Automatically skips files already processed in previous runs
  - Safely continues processing after interruption
- Stabilized end-of-run MessageBox handling
  - Fixed string interpolation issues
  - Proper use of MessageBox enum types

### ⏱️ Enhanced Progress Information
- Progress window now displays:
  - Elapsed time
  - Estimated remaining time (ETA)
  - Average processing speed (files/sec)
- Improves predictability for large-scale jobs

### ⚡ Performance Optimization
- Combined HashSet-based caching with Resume logic
- Already processed files are skipped without disk access
- Noticeable speed improvements in skip-heavy scenarios

---
