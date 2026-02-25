# StealthStockWidget

macOS 데스크탑 주식 위젯. 한국투자증권(KIS) Open API를 통해 실시간 국내 주식 시세를 모니터링합니다.

## 기능

- 관심 종목 시세를 컴팩트한 그리드 타일로 표시
- 드래그 앤 드롭으로 종목 순서 변경
- 마우스 호버 시 상세 시세 팝오버
- 종목 검색 및 추가 (종목명/코드)
- 5분 간격 자동 새로고침

## 설치

### DMG 다운로드

[Releases](../../releases) 페이지에서 최신 DMG를 다운로드합니다.

### 첫 실행 (Gatekeeper)

이 앱은 Apple 공증을 받지 않았으므로 macOS가 첫 실행을 차단합니다.

1. DMG를 열고 `StealthStockWidget.app`을 `Applications`로 드래그
2. Applications에서 앱을 **우클릭(Control-클릭)** > **열기**
3. 대화상자에서 **열기** 클릭

이후부터는 정상적으로 실행됩니다.

또는 터미널에서:
```bash
xattr -dr com.apple.quarantine /Applications/StealthStockWidget.app
```

## 설정

앱 실행 후 설정 패널에서 KIS Open API 인증 정보를 입력합니다:

- **App Key** / **App Secret**: [한국투자증권 OpenAPI](https://apiportal.koreainvestment.com/) 발급
- **계좌번호**: 종합계좌번호 (8자리)

## 요구사항

- macOS 14 (Sonoma) 이상
- 한국투자증권 OpenAPI 계정

## 빌드 (개발자)

```bash
# 실행
swift build && swift run

# 릴리스 빌드 (DMG 생성)
./scripts/build-release.sh 1.0.0
```
