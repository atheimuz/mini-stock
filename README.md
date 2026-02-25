# StealthStockWidget

macOS 데스크탑에 상주하는 초소형 주식 위젯.
한국투자증권(KIS) Open API를 통해 국내 주식 시세를 실시간으로 모니터링합니다.

28×28px 타일 하나에 종목 하나. 화면 한쪽에 조용히 붙여두고 작업하면서 시세를 확인할 수 있습니다.

## 주요 기능

- **타일 그리드** — 관심 종목을 28×28px 컬러 타일로 표시. 상승(주황), 하락(초록), 보합(회색)
- **호버 팝오버** — 마우스를 올리면 현재가, 등락률, 전일 대비 등 상세 시세 표시
- **드래그 앤 드롭** — 타일을 끌어서 순서 변경
- **종목 검색** — KRX 전 종목(2,300+) 이름/코드로 검색 및 추가 (최대 20개)
- **커스텀 라벨** — 우클릭 > "Edit label"로 타일 표시 텍스트 변경
- **삭제 취소** — 종목 삭제 시 5초 이내 Undo 가능
- **자동 새로고침** — 5분 간격 자동 갱신
- **윈도우 기억** — 위치와 크기를 앱 종료 후에도 유지
- **리사이즈 지원** — 윈도우 크기에 따라 그리드 자동 조정

## 기술 스택

| 항목 | 기술 |
|------|------|
| 언어 | Swift 5.9 |
| UI | SwiftUI + AppKit (NSPanel) |
| 빌드 | Swift Package Manager |
| 플랫폼 | macOS 14 (Sonoma)+ |
| API | 한국투자증권 KIS Open Trading API |
| 데이터 | UserDefaults (관심 종목), KRX 종목 CSV (번들 리소스) |

## 프로젝트 구조

```
StealthStockWidget/
├── App/
│   ├── StealthStockWidgetApp.swift   # @main 진입점
│   └── AppDelegate.swift             # NSPanel 윈도우 설정
├── Models/
│   └── Stock.swift                   # StockInfo, StockQuote, WatchedStock
├── Services/
│   ├── KISAuthService.swift          # OAuth 토큰 관리 (Actor)
│   ├── KISQuoteService.swift         # 시세 조회 API
│   ├── KeychainService.swift         # 인증 정보 저장
│   └── StockSearchService.swift      # CSV 기반 종목 검색
├── Stores/
│   └── StockStore.swift              # @Observable 상태 관리
├── Views/
│   ├── Widget/                       # 메인 위젯 (그리드, 타일, 팝오버, 헤더)
│   ├── Search/                       # 종목 검색 패널
│   └── Settings/                     # API 설정 패널
├── Extensions/
│   ├── Color+Token.swift             # 디자인 토큰 (다크 테마)
│   └── Font+Token.swift              # 타이포그래피 토큰
└── Resources/
    └── krx_stocks.csv                # KRX 전 종목 데이터
```

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

| 항목 | 설명 |
|------|------|
| App Key | [한국투자증권 OpenAPI](https://apiportal.koreainvestment.com/)에서 발급 |
| App Secret | 위와 동일 |
| 계좌번호 | 종합계좌번호 8자리 |

인증 정보 입력 후 종목을 검색하여 추가하면 시세가 표시됩니다.

## 요구사항

- macOS 14 (Sonoma) 이상
- 한국투자증권 OpenAPI 계정 (실전/모의 모두 가능)

## 빌드

```bash
# 개발 실행
swift build && swift run

# 릴리스 빌드 (유니버설 바이너리 DMG 생성)
./scripts/build-release.sh 1.0.0
```

빌드 스크립트는 arm64 + x86_64 유니버설 바이너리를 생성하고, `.app` 번들 조립 후 DMG로 패키징합니다.

## 릴리스

Git 태그를 push하면 GitHub Actions가 자동으로 DMG를 빌드하고 Release를 생성합니다:

```bash
git tag v1.0.0
git push origin v1.0.0
```

## 라이선스

MIT
