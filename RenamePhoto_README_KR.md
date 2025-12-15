# 📷 Photo & Video Rename + Copy Tool

PowerShell과 **exiftool**을 이용해 사진·영상 파일을  
**촬영 시간 / 카메라 / 미디어 유형 기준으로 자동 정리**하는 Windows용 도구입니다.

GUI(폴더 선택 창) 기반으로 동작하여  
👉 **명령어 입력 없이 더블클릭만으로 사용**할 수 있습니다.

---

## ✨ 주요 기능

- 사진 / 영상 파일 자동 탐색
- EXIF / QuickTime 메타데이터 기반 촬영 시간 추출
- Canon EOS R7 / EOS 200D II 카메라 자동 인식
- 규칙 기반 파일명 자동 변경
- 카메라 / 사진·영상 / 날짜별 폴더 자동 분류
- 중복 파일 안전 처리 (Overwrite 방지)
- 진행률 표시 (Progress Bar)
- 처리 결과 로그 자동 생성

---

## 📁 지원 파일 형식

### 📸 사진 (PHOTO)
- CR3
- JPG / JPEG

### 🎥 영상 (VIDEO)
- MP4
- MOV
- WMV

---

## 🏷️ 파일명 규칙

```
YYYY-MM-DD_HH-mm-ss_<ID>_<CAM>.EXT
```

### 예시
```
2025-12-15_11-08-27_0300_EOSR7.JPG
2025-12-15_14-03-11_A3F9C2_UNKNOWN.MOV
```

---

## 🔑 ID 생성 규칙

### 1️⃣ `IMG_####` 형식 파일
- 예: `IMG_0300.JPG`
- → **0300 그대로 사용**

### 2️⃣ 그 외 파일명
- ID = `hash6("원본파일명|파일크기")`
- 실행할 때마다 **항상 동일한 ID 생성**
- 동일 촬영 시각 파일 간 **충돌 / 무한 루프 방지**

---

## 📷 카메라 판별 규칙

| 카메라 모델 | 폴더/파일 표기 |
|------------|---------------|
| Canon EOS R7 | EOSR7 |
| Canon EOS 200D II | 200D2 |
| 기타 / 인식 불가 | UNKNOWN |

---

## 🕒 촬영 시간 추출 우선순위

### 📸 사진
1. DateTimeOriginal
2. LastWriteTime (Fallback)

### 🎥 영상
1. QuickTime:CreateDate
2. QuickTime:MediaCreateDate
3. MediaCreateDate
4. CreateDate
5. LastWriteTime (Fallback)

---

## 🗂️ 폴더 구조

```
<DESTINATION>
 └─ EOSR7
    ├─ PHOTO
    │  └─ YYYY / MM / DD
    └─ VIDEO
       └─ YYYY / MM / DD
```

---

## ▶ 실행 방법

1. `RenamePhoto.bat` 더블 클릭
2. 원본 폴더 선택
3. 대상 폴더 선택
4. 자동 처리 시작
5. 완료 후 결과 폴더 자동 열림

👉 자세한 설명은 **RenamePhoto_HowToUse.md** 참고

---

## 🔧 요구 사항 (Requirements)

- Windows 10 / 11
- PowerShell 5.1 이상
- **exiftool**
  - https://exiftool.org/
  - `exiftool/exiftool.exe` 경로에 배치

> ⚠️ exiftool 바이너리는 라이선스 이슈로 저장소에 포함하지 않습니다.

---

## 📄 라이선스

- 이 프로젝트의 스크립트 코드는 **MIT License** 권장
- exiftool은 별도의 라이선스를 따릅니다

---

## 📌 참고 문서

- [HowToUse.md](./RenamePhoto_HowToUse.md)
- [CHANGELOG.md](./RenamePhoto_CHANGELOG.md)

---

### 📎 처리 흐름 다이어그램

![Flow Diagram](./docs/RenamePhoto_FlowDiagram.png)
