# 📷 사진 · 영상 파일명 변경 & 정리 도구 (v6.9)

PowerShell과 **exiftool**을 사용하여 사진과 영상 파일을  
촬영 시간 기준으로 자동 파일명 변경 및 폴더 정리를 수행하는 Windows용 도구입니다.

GUI 기반으로 동작하여 **더블클릭만으로 실행**할 수 있습니다.

---

## ✨ 주요 기능 (v6.9)

- 사진 / 영상 파일 자동 탐색 및 처리
- EXIF / QuickTime 메타데이터 기반 촬영 시간 추출
- Canon EOS R7 / EOS 200D II / **iPhone 자동 인식**
- 인식되지 않는 기기는 `UNKNOWN` 처리
- 규칙 기반 파일명 자동 변경
- **PHOTO / VIDEO 폴더로만 분류 (카메라별 폴더 미생성)**
- PNG 사진 포맷 지원
- MP4 / MOV / WMV 영상 지원
- 기존 파일 **HashSet 캐싱 기반 초고속 스킵**
- **중단 복구(Resume) 기능**
  - 이전 실행에서 처리된 파일은 자동 스킵
- 진행률 표시
  - 현재 진행률(%)
  - 경과 시간 / 남은 시간(ETA)
  - 평균 처리 속도 (files/sec)
- 로그 기록 모드 선택 가능
  - `SUMMARY` (기본): ERROR만 기록
  - `FULL`: COPY / SKIP / ERROR 모두 기록
  - `OFF`: 파일 로그 미작성 (최고 속도)

---

## 📁 지원 파일 형식

### 📸 사진
- CR3
- JPG / JPEG
- PNG

### 🎥 영상
- MP4
- MOV
- WMV

---

## 🏷️ 파일명 규칙

```
YYYY-MM-DD_HH-mm-ss_<ID>_<DEVICE>.EXT
```

### ID 생성 규칙
- `IMG_0300.JPG` → `0300` 유지
- 그 외 파일 → **원본파일명 + 파일크기 기반 해시(6자리)**

### DEVICE 값
- `EOSR7`
- `200D2`
- `IPHONE`
- `UNKNOWN`

---

## 🕒 촬영 시간 추출 우선순위

### 사진
1. DateTimeOriginal
2. LastWriteTime (Fallback)

### 영상 (MOV 최적화)
1. QuickTime:CreateDate
2. QuickTime:MediaCreateDate
3. MediaCreateDate
4. CreateDate
5. LastWriteTime (Fallback)

---

## 🗂️ 폴더 구조

```
<DESTINATION>
├─ PHOTO
│  └─ YYYY / MM / DD
└─ VIDEO
   └─ YYYY / MM / DD
```

---

## 📌 권장 사용 환경
- Windows 10 / 11
- PowerShell 5.x 이상
- exiftool (스크립트 폴더 내 `exiftool/`)

---

## 📜 라이선스
개인 사용 및 학습 목적 자유 사용
