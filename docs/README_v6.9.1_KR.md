# 📷 사진 · 영상 파일명 변경 & 정리 도구 (v6.9.1)

이 도구는 PowerShell과 **exiftool**을 사용하여 사진과 영상 파일을  
촬영 시간 기준으로 파일명을 변경하고, 날짜별 폴더 구조로 자동 정리하는 Windows용 유틸리티입니다.

GUI 기반으로 동작하며, 더블 클릭만으로 실행할 수 있습니다.

---

## ✨ 주요 기능

- 사진 / 영상 파일 자동 탐색 및 일괄 처리
- EXIF / QuickTime 메타데이터 기반 촬영 시간 추출
- Canon EOS R7 / EOS 200D II / iPhone 자동 인식
- 인식 불가 기기는 `UNKNOWN` 처리
- 규칙 기반 파일명 자동 변경
- PHOTO / VIDEO 기준 폴더 분리
- 진행률, 경과 시간, 남은 시간(ETA), 평균 처리 속도(files/sec) 표시
- 중단 복구(Resume) 기능 지원
- 기존 파일 HashSet 캐싱으로 스킵 속도 최적화

---

## 🆕 v6.9.1 업데이트 사항

- **HEIC 포맷 정식 지원**
  - ImageMagick(`magick.exe`)을 이용한 실제 JPG 변환
  - 변환 품질: quality 92
  - 변환 후 원본 HEIC → JPG 메타데이터 복사
- **도구 경로 자동 탐색**
  - `tools\exiftool\exiftool*.exe` 자동 검색
  - `tools\magick\magick.exe` 자동 사용
- 한글 폴더/파일명이 포함된 경로에서도 안정적으로 처리

---

## 📁 지원 파일 형식

### 사진
- CR3
- JPG / JPEG
- PNG
- HEIC (변환 후 처리)

### 영상
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
- 그 외 파일 → 파일명 + 파일 크기 기반 6자리 해시 (실행 간 동일)

### DEVICE 값
- EOSR7
- 200D2
- IPHONE
- UNKNOWN

---

## 🗂️ 폴더 구조

```
DESTINATION
├─ PHOTO
│  └─ YYYY / MM / DD
└─ VIDEO
   └─ YYYY / MM / DD
```

---

## 📝 로그 모드

- SUMMARY (기본)
  - ERROR만 파일 기록
  - COPY / SKIP은 카운트만 증가
- FULL
  - COPY / SKIP / ERROR 모두 기록
- OFF
  - 로그 파일 미생성 (최고 속도)

---

## ⚙️ 실행 환경

- Windows 10 / 11
- PowerShell 3.0 이상
- exiftool
- ImageMagick (HEIC 변환용)
