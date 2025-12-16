# 📜 CHANGELOG

This document records the version history of the **Photo & Video Rename + Copy Tool**.

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

### 📖 Documentation Updates
- Updated README and HowToUse for v6.9 features
- Added detailed explanations for Resume and progress display

---

## v6.7 (2025-12)

### ⚡ Performance Optimization & Large-Scale Processing
- Existing-file caching using HashSet
- Skip-log summary mode
- Reduced log I/O overhead

### ⏱️ Enhanced Progress Display
- Elapsed time, ETA, and total estimated duration

---

## v6.5 (2025-12)

### 📁 Simplified Folder Structure & PNG Support
- Finalized `PHOTO / VIDEO / YYYY / MM / DD` layout
- Added PNG support

---

## v6.3 (2025-12)

### 🎥 Enhanced Video Metadata Handling (MOV Optimized)
- QuickTime-based capture time prioritization
- Fixed MOV date sorting issues
