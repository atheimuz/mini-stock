---
globs: "**/*Service*.swift"
description: 한국투자증권 Open Trading API 호출 시 참조
---

# KIS Open Trading API Reference

공식 문서 (한국투자증권_오픈API_전체문서) 기반. KIS API 엔드포인트 추가/수정 시 참조.

---

## 1. Base URLs

| 환경 | REST | WebSocket |
|------|------|-----------|
| 실전 | `https://openapi.koreainvestment.com:9443` | `ws://ops.koreainvestment.com:21000` |
| 모의 | `https://openapivts.koreainvestment.com:29443` | `ws://ops.koreainvestment.com:31000` |

---

## 2. Authentication

### REST 접근토큰 발급 (인증-001)

```
POST /oauth2/tokenP
Body: { "grant_type": "client_credentials", "appkey": "...", "appsecret": "..." }
Response: { "access_token": "...", "token_type": "Bearer", "expires_in": 7776000 }
```

- 항상 `KISAuthService.shared.getToken()` 사용 (23h 캐싱)
- 토큰 재발급: 1분당 1회 제한
- 토큰 오류(401, EGW 계열) → `invalidateToken()` 후 1회만 재시도

### 접근토큰 폐기 (인증-002)
```
POST /oauth2/revokeP
Body: { "appkey": "...", "appsecret": "...", "token": "..." }
```

### WebSocket 접속키 (실시간-000)
```
POST /oauth2/Approval
Body: { "grant_type": "client_credentials", "appkey": "...", "secretkey": "..." }
Response: { "approval_key": "..." }
```
WebSocket 헤더에 approval_key 사용 (Bearer 토큰 아님).

### Hashkey
```
POST /uapi/hashkey
Body: 해시 대상 데이터
```
POST 요청 시 body 무결성 검증용. 주문 API에서 필요할 수 있음.

---

## 3. Credentials

`KeychainService` (UserDefaults 기반)로 로드. 하드코딩 금지.
- `.appKey` → appkey 헤더
- `.appSecret` → appsecret 헤더
- `.accountNumber` → CANO 필드 (8자리)

---

## 4. Request Construction

### URL 패턴
```
/uapi/{market}/{version}/{category}/{operation}
```

### 필수 헤더 (모든 인증 요청)
```
Content-Type: application/json; charset=utf-8
authorization: Bearer {token}
appkey: {appKey}
appsecret: {appSecret}
tr_id: {TR_ID}
```

### 선택 헤더
| 헤더 | 값 | 용도 |
|------|-----|------|
| custtype | P(개인) / B(법인) | 주문/잔고 API 필수 |
| tr_cont | 공백(초회) / N(다음) | 연속조회 |

### GET 요청
- `URLComponents.queryItems`에 파라미터 설정
- 파라미터명 **대문자** (FID_INPUT_ISCD, CANO 등)

### POST 요청
- JSON body, 키 **대문자** (CANO, PDNO, ORD_QTY 등)
- `custtype: "P"` 헤더 필수

---

## 5. Response Parsing

### 성공 확인
```swift
guard let rtCd = json["rt_cd"] as? String, rtCd == "0" else {
    // json["msg_cd"], json["msg1"] 로 에러 확인
    throw KISError.quoteFailed("\(msgCd): \(msg1)")
}
```
- `rt_cd` == `"0"` → 성공, 그 외 → 실패

### Output 구조
- 단건: `json["output"] as? [String: Any]`
- 목록: `json["output1"] as? [[String: Any]]`
- 복합: `output1`(종목별) + `output2`(요약)

### 페이지네이션
- 응답 헤더 `tr_cont`: `F` 또는 `M` → 다음 페이지 있음, `D` 또는 `E` → 마지막
- 다음 요청: `tr_cont` 헤더를 `"N"`, 이전 응답의 `ctx_area_fk100`, `ctx_area_nk100` 전달

---

## 6. Rate Limiting

| 환경 | 간격 |
|------|------|
| 실전 | 50ms (~20 req/s) |
| 모의 | 500ms (~2 req/s) |

```swift
try? await Task.sleep(for: .milliseconds(50))
```
- 루프에서 반드시 sleep 적용
- `async let` / `TaskGroup` 병렬 호출 금지 (계정 단위 rate limit)

---

## 7. Error Handling

1. HTTP 200이 아니면 throw
2. `rt_cd == "0"` 확인 후 output 읽기
3. 토큰 오류 → `invalidateToken()` + 1회 재시도
4. 새 에러는 `KISError` enum에 case 추가

현재 KISError (`KISAuthService.swift`):
- `missingCredentials`, `authFailed`, `invalidResponse`, `quoteFailed(String)`

---

## 8. 전체 API 목록

### OAuth 인증

| TR ID | API명 | Method | URL |
|-------|-------|--------|-----|
| - | Hashkey | POST | /uapi/hashkey |
| - | 접근토큰발급(P) | POST | /oauth2/tokenP |
| - | 접근토큰폐기(P) | POST | /oauth2/revokeP |
| - | 웹소켓 접속키 발급 | POST | /oauth2/Approval |

### [국내주식] 주문/계좌

| 실전 TR ID | 모의 TR ID | API명 | Method | URL |
|------------|-----------|-------|--------|-----|
| TTTC0012U(매수) TTTC0011U(매도) | VTTC0012U / VTTC0011U | 주식주문(현금) | POST | /uapi/domestic-stock/v1/trading/order-cash |
| TTTC0013U | VTTC0013U | 주식주문(정정취소) | POST | /uapi/domestic-stock/v1/trading/order-rvsecncl |
| TTTC0051U(매도) TTTC0052U(매수) | 미지원 | 주식주문(신용) | POST | /uapi/domestic-stock/v1/trading/order-credit |
| CTSC0008U | 미지원 | 주식예약주문 | POST | /uapi/domestic-stock/v1/trading/order-resv |
| CTSC0009U/CTSC0013U | 미지원 | 주식예약주문정정취소 | POST | /uapi/domestic-stock/v1/trading/order-resv-rvsecncl |
| TTTC8434R | VTTC8434R | 주식잔고조회 | GET | /uapi/domestic-stock/v1/trading/inquire-balance |
| TTTC8494R | 미지원 | 주식잔고조회_실현손익 | GET | /uapi/domestic-stock/v1/trading/inquire-balance-rlz-pl |
| TTTC8908R | VTTC8908R | 매수가능조회 | GET | /uapi/domestic-stock/v1/trading/inquire-psbl-order |
| TTTC8408R | 미지원 | 매도가능수량조회 | GET | /uapi/domestic-stock/v1/trading/inquire-psbl-sell |
| TTTC0081R(3개월이내) CTSC9215R(이전) | VTTC0081R / VTSC9215R | 주식일별주문체결조회 | GET | /uapi/domestic-stock/v1/trading/inquire-daily-ccld |
| TTTC0084R | 미지원 | 주식정정취소가능주문조회 | GET | /uapi/domestic-stock/v1/trading/inquire-psbl-rvsecncl |
| CTSC0004R | 미지원 | 주식예약주문조회 | GET | /uapi/domestic-stock/v1/trading/order-resv-ccnl |
| CTRP6548R | 미지원 | 투자계좌자산현황조회 | GET | /uapi/domestic-stock/v1/trading/inquire-account-balance |
| TTTC8715R | 미지원 | 기간별매매손익현황조회 | GET | /uapi/domestic-stock/v1/trading/inquire-period-trade-profit |
| TTTC8708R | 미지원 | 기간별손익일별합산조회 | GET | /uapi/domestic-stock/v1/trading/inquire-period-profit |
| CTRGA011R | 미지원 | 기간별계좌권리현황조회 | GET | /uapi/domestic-stock/v1/trading/period-rights |

### [국내주식] 기본시세

| 실전 TR ID | 모의 TR ID | API명 | Method | URL |
|------------|-----------|-------|--------|-----|
| FHKST01010100 | FHKST01010100 | 주식현재가 시세 | GET | /uapi/domestic-stock/v1/quotations/inquire-price |
| FHPST01010000 | 미지원 | 주식현재가 시세2 | GET | /uapi/domestic-stock/v1/quotations/inquire-price-2 |
| FHKST01010200 | FHKST01010200 | 주식현재가 호가/예상체결 | GET | /uapi/domestic-stock/v1/quotations/inquire-asking-price-exp-ccn |
| FHKST01010300 | FHKST01010300 | 주식현재가 체결 | GET | /uapi/domestic-stock/v1/quotations/inquire-ccnl |
| FHKST01010400 | FHKST01010400 | 주식현재가 일자별 | GET | /uapi/domestic-stock/v1/quotations/inquire-daily-price |
| FHKST01010600 | FHKST01010600 | 주식현재가 회원사 | GET | /uapi/domestic-stock/v1/quotations/inquire-member |
| FHKST01010900 | FHKST01010900 | 주식현재가 투자자 | GET | /uapi/domestic-stock/v1/quotations/inquire-investor |
| FHKST03010200 | FHKST03010200 | 주식당일분봉조회 | GET | /uapi/domestic-stock/v1/quotations/inquire-time-itemchartprice |
| FHKST03010100 | FHKST03010100 | 국내주식기간별시세(일/주/월/년) | GET | /uapi/domestic-stock/v1/quotations/inquire-daily-itemchartprice |
| FHKST03010230 | 미지원 | 주식일별분봉조회 | GET | /uapi/domestic-stock/v1/quotations/inquire-time-dailychartprice |
| FHPST01060000 | FHPST01060000 | 주식현재가 당일시간대별체결 | GET | /uapi/domestic-stock/v1/quotations/inquire-time-itemconclusion |
| FHPST02300000 | 미지원 | 국내주식 시간외현재가 | GET | /uapi/domestic-stock/v1/quotations/inquire-overtime-price |
| FHPST02300400 | 미지원 | 국내주식 시간외호가 | GET | /uapi/domestic-stock/v1/quotations/inquire-overtime-asking-price |
| FHPST02310000 | FHPST02310000 | 주식현재가 시간외시간별체결 | GET | /uapi/domestic-stock/v1/quotations/inquire-time-overtimeconclusion |
| FHPST02320000 | FHPST02320000 | 주식현재가 시간외일자별주가 | GET | /uapi/domestic-stock/v1/quotations/inquire-daily-overtimeprice |
| FHKST117300C0 | 미지원 | 국내주식 장마감 예상체결가 | GET | /uapi/domestic-stock/v1/quotations/exp-closing-price |

### [국내주식] 종목정보

| 실전 TR ID | API명 | Method | URL |
|------------|-------|--------|-----|
| CTPF1002R | 주식기본조회 | GET | /uapi/domestic-stock/v1/quotations/search-stock-info |
| CTPF1604R | 상품기본조회 | GET | /uapi/domestic-stock/v1/quotations/search-info |
| FHKST66430100 | 국내주식 대차대조표 | GET | /uapi/domestic-stock/v1/finance/balance-sheet |
| FHKST66430200 | 국내주식 손익계산서 | GET | /uapi/domestic-stock/v1/finance/income-statement |
| FHKST66430300 | 국내주식 재무비율 | GET | /uapi/domestic-stock/v1/finance/financial-ratio |
| FHKST66430400 | 국내주식 수익성비율 | GET | /uapi/domestic-stock/v1/finance/profit-ratio |
| FHKST66430600 | 국내주식 안정성비율 | GET | /uapi/domestic-stock/v1/finance/stability-ratio |
| FHKST66430800 | 국내주식 성장성비율 | GET | /uapi/domestic-stock/v1/finance/growth-ratio |
| FHKST66430500 | 국내주식 기타주요비율 | GET | /uapi/domestic-stock/v1/finance/other-major-ratios |
| HHKST668300C0 | 국내주식 종목추정실적 | GET | /uapi/domestic-stock/v1/quotations/estimate-perform |
| FHKST663300C0 | 국내주식 종목투자의견 | GET | /uapi/domestic-stock/v1/quotations/invest-opinion |
| FHKST663400C0 | 국내주식 증권사별 투자의견 | GET | /uapi/domestic-stock/v1/quotations/invest-opbysec |

### [국내주식] 업종/기타

| 실전 TR ID | API명 | Method | URL |
|------------|-------|--------|-----|
| FHKUP03500100 | 국내주식업종기간별시세 | GET | /uapi/domestic-stock/v1/quotations/inquire-daily-indexchartprice |
| FHPUP02100000 | 국내업종 현재지수 | GET | /uapi/domestic-stock/v1/quotations/inquire-index-price |
| FHPUP02120000 | 국내업종 일자별지수 | GET | /uapi/domestic-stock/v1/quotations/inquire-index-daily-price |
| FHPUP02140000 | 국내업종 구분별전체시세 | GET | /uapi/domestic-stock/v1/quotations/inquire-index-category-price |
| CTCA0903R | 국내휴장일조회 | GET | /uapi/domestic-stock/v1/quotations/chk-holiday |
| FHPST01390000 | 변동성완화장치(VI) 현황 | GET | /uapi/domestic-stock/v1/quotations/inquire-vi-status |
| FHPST01710000 | 거래량순위 | GET | /uapi/domestic-stock/v1/quotations/volume-rank |

### [국내주식] 순위분석

| 실전 TR ID | API명 | URL |
|------------|-------|-----|
| FHPST01700000 | 등락률 순위 | /uapi/domestic-stock/v1/ranking/fluctuation |
| FHPST01710000 | 거래량순위 | /uapi/domestic-stock/v1/quotations/volume-rank |
| FHPST01740000 | 시가총액 상위 | /uapi/domestic-stock/v1/ranking/market-cap |
| FHPST01680000 | 체결강도 상위 | /uapi/domestic-stock/v1/ranking/volume-power |
| FHPST01720000 | 호가잔량 순위 | /uapi/domestic-stock/v1/ranking/quote-balance |
| FHPST01730000 | 수익자산지표 순위 | /uapi/domestic-stock/v1/ranking/profit-asset-index |
| FHPST01750000 | 재무비율 순위 | /uapi/domestic-stock/v1/ranking/finance-ratio |
| FHPST01790000 | 시장가치 순위 | /uapi/domestic-stock/v1/ranking/market-value |
| FHPST01870000 | 신고/신저근접종목 상위 | /uapi/domestic-stock/v1/ranking/near-new-highlow |
| FHPST02340000 | 시간외등락율순위 | /uapi/domestic-stock/v1/ranking/overtime-fluctuation |
| FHPST02350000 | 시간외거래량순위 | /uapi/domestic-stock/v1/ranking/overtime-volume |

### [국내주식] 시세분석

| 실전 TR ID | API명 | URL |
|------------|-------|-----|
| FHPTJ04040000 | 시장별 투자자매매동향(일별) | /uapi/domestic-stock/v1/quotations/inquire-investor-daily-by-market |
| FHPTJ04030000 | 시장별 투자자매매동향(시세) | /uapi/domestic-stock/v1/quotations/inquire-investor-time-by-market |
| FHPTJ04400000 | 국내기관_외국인 매매종목가집계 | /uapi/domestic-stock/v1/quotations/foreign-institution-total |
| FHPST04760000 | 국내주식 신용잔고 일별추이 | /uapi/domestic-stock/v1/quotations/daily-credit-balance |
| FHPST04830000 | 국내주식 공매도 일별추이 | /uapi/domestic-stock/v1/quotations/daily-short-sale |
| HHKST03900300 | 종목조건검색 목록조회 | /uapi/domestic-stock/v1/quotations/psearch-title |
| HHKST03900400 | 종목조건검색조회 | /uapi/domestic-stock/v1/quotations/psearch-result |
| FHKST11300006 | 관심종목(멀티종목) 시세조회 | /uapi/domestic-stock/v1/quotations/intstock-multprice |

### [국내주식] 실시간 WebSocket

| TR ID | 모의 TR ID | API명 |
|-------|-----------|-------|
| H0STCNT0 | H0STCNT0 | 실시간체결가 (KRX) |
| H0STASP0 | H0STASP0 | 실시간호가 (KRX) |
| H0STCNI0 | H0STCNI9 | 실시간체결통보 |
| H0NXCNT0 | 미지원 | 실시간체결가 (NXT) |
| H0NXASP0 | 미지원 | 실시간호가 (NXT) |
| H0UNCNT0 | 미지원 | 실시간체결가 (통합) |
| H0UNASP0 | 미지원 | 실시간호가 (통합) |
| H0STANC0 | 미지원 | 실시간예상체결 (KRX) |
| H0STMKO0 | 미지원 | 장운영정보 (KRX) |
| H0STPGM0 | 미지원 | 실시간프로그램매매 (KRX) |
| H0STOAC0 | 미지원 | 시간외 실시간예상체결 (KRX) |
| H0STOAA0 | 미지원 | 시간외 실시간호가 (KRX) |
| H0STOUP0 | 미지원 | 시간외 실시간체결가 (KRX) |
| H0STNAV0 | 미지원 | 국내ETF NAV추이 |
| H0UPCNT0 | 미지원 | 국내지수 실시간체결 |
| H0UPANC0 | 미지원 | 국내지수 실시간예상체결 |

### [해외주식] 주문/계좌

| 실전 TR ID | 모의 TR ID | API명 | Method | URL |
|------------|-----------|-------|--------|-----|
| TTTT1002U(매수) TTTT1006U(매도) | VTTT1002U / VTTT1001U | 해외주식 주문(미국) | POST | /uapi/overseas-stock/v1/trading/order |
| TTTT1004U | VTTT1004U | 해외주식 정정취소(미국) | POST | /uapi/overseas-stock/v1/trading/order-rvsecncl |
| TTTS6036U(매수) TTTS6037U(매도) | 미지원 | 해외주식 미국주간주문 | POST | /uapi/overseas-stock/v1/trading/daytime-order |
| TTTS6038U | 미지원 | 해외주식 미국주간정정취소 | POST | /uapi/overseas-stock/v1/trading/daytime-order-rvsecncl |
| TTTS3012R | VTTS3012R | 해외주식 잔고 | GET | /uapi/overseas-stock/v1/trading/inquire-balance |
| CTRP6504R | VTRP6504R | 해외주식 체결기준현재잔고 | GET | /uapi/overseas-stock/v1/trading/inquire-present-balance |
| TTTS3007R | VTTS3007R | 해외주식 매수가능금액조회 | GET | /uapi/overseas-stock/v1/trading/inquire-psamount |
| TTTS3018R | 미지원 | 해외주식 미체결내역 | GET | /uapi/overseas-stock/v1/trading/inquire-nccs |
| TTTS3035R | VTTS3035R | 해외주식 주문체결내역 | GET | /uapi/overseas-stock/v1/trading/inquire-ccnl |
| TTTS3039R | 미지원 | 해외주식 기간손익 | GET | /uapi/overseas-stock/v1/trading/inquire-period-profit |

해외주식 아시아 거래소별 주문 TR ID:
| 거래소 | 코드 | 매수 | 매도 |
|--------|------|------|------|
| 홍콩 | SEHK | TTTS1002U | TTTS1001U |
| 상해 | SHAA | TTTS0202U | TTTS1005U |
| 심천 | SZAA | TTTS0305U | TTTS0304U |
| 일본 | TKSE | TTTS0308U | TTTS0307U |
| 베트남 | HASE/VNSE | TTTS0311U | TTTS0310U |

모의투자: 첫 글자 `T` → `V` 치환.

### [해외주식] 기본시세

| 실전 TR ID | 모의 TR ID | API명 | URL |
|------------|-----------|-------|-----|
| HHDFS00000300 | HHDFS00000300 | 해외주식 현재체결가 | /uapi/overseas-price/v1/quotations/price |
| HHDFS76200200 | 미지원 | 해외주식 현재가상세 | /uapi/overseas-price/v1/quotations/price-detail |
| HHDFS76200100 | 미지원 | 해외주식 현재가 호가 | /uapi/overseas-price/v1/quotations/inquire-asking-price |
| HHDFS76200300 | 미지원 | 해외주식 체결추이 | /uapi/overseas-price/v1/quotations/inquire-ccnl |
| HHDFS76240000 | HHDFS76240000 | 해외주식 기간별시세 | /uapi/overseas-price/v1/quotations/dailyprice |
| HHDFS76950200 | 미지원 | 해외주식분봉조회 | /uapi/overseas-price/v1/quotations/inquire-time-itemchartprice |
| FHKST03030100 | FHKST03030100 | 해외주식 종목/지수/환율기간별시세 | /uapi/overseas-price/v1/quotations/inquire-daily-chartprice |
| HHDFS76410000 | HHDFS76410000 | 해외주식조건검색 | /uapi/overseas-price/v1/quotations/inquire-search |
| CTPF1702R | 미지원 | 해외주식 상품기본정보 | /uapi/overseas-price/v1/quotations/search-info |

### [해외주식] 실시간 WebSocket

| TR ID | API명 |
|-------|-------|
| HDFSCNT0 | 해외주식 실시간지연체결가 |
| HDFSASP0 | 해외주식 실시간호가 |
| HDFSASP1 | 해외주식 지연호가(아시아) |
| H0GSCNI0 (모의: H0GSCNI9) | 해외주식 실시간체결통보 |

### ETF/ETN

| 실전 TR ID | API명 | URL |
|------------|-------|-----|
| FHPST02400000 | ETF/ETN 현재가 | /uapi/etfetn/v1/quotations/inquire-price |
| FHKST121600C0 | ETF 구성종목시세 | /uapi/etfetn/v1/quotations/inquire-component-stock-price |
| FHPST02440000 | NAV 비교추이(종목) | /uapi/etfetn/v1/quotations/nav-comparison-trend |

---

## 9. 주요 API 파라미터 상세

### 주식주문(현금) — POST /uapi/domestic-stock/v1/trading/order-cash

Request Body:
| 필드 | 필수 | 설명 |
|------|------|------|
| CANO | Y | 종합계좌번호 (8자리) |
| ACNT_PRDT_CD | Y | 계좌상품코드 (2자리, 보통 "01") |
| PDNO | Y | 종목코드 (6자리, ETN 7자리) |
| ORD_DVSN | Y | 주문구분 (아래 코드표) |
| ORD_QTY | Y | 주문수량 (문자열) |
| ORD_UNPR | Y | 주문단가 (문자열, 시장가 시 "0") |
| SLL_TYPE | N | 매도유형 (01:일반매도, 미입력 시 01) — 매도 시에만 |
| EXCG_ID_DVSN_CD | N | KRX / NXT / SOR (미입력 시 KRX) |
| CNDT_PRIC | N | 조건가격 (스탑지정가 ORD_DVSN=22 시) |

Response: `output.KRX_FWDG_ORD_ORGNO`, `output.ODNO`(주문번호), `output.ORD_TMD`

### ORD_DVSN 주문구분 코드
| 코드 | 설명 |
|------|------|
| 00 | 지정가 |
| 01 | 시장가 |
| 02 | 조건부지정가 |
| 03 | 최유리지정가 |
| 04 | 최우선지정가 |
| 05 | 장전 시간외 |
| 06 | 장후 시간외 |
| 07 | 시간외 단일가 |
| 22 | 스탑지정가 (CNDT_PRIC 필수) |

### 주식주문(정정취소) — POST /uapi/domestic-stock/v1/trading/order-rvsecncl

추가 필드:
| 필드 | 필수 | 설명 |
|------|------|------|
| KRX_FWDG_ORD_ORGNO | Y | 한국거래소전송주문조직번호 |
| ORGN_ODNO | Y | 원주문번호 |
| RVSE_CNCL_DVSN_CD | Y | 01:정정, 02:취소 |
| QTY_ALL_ORD_YN | Y | Y:전량, N:일부 |

### 주식잔고조회 — GET /uapi/domestic-stock/v1/trading/inquire-balance

Query Parameters:
| 필드 | 필수 | 설명 |
|------|------|------|
| CANO | Y | 계좌번호 (8자리) |
| ACNT_PRDT_CD | Y | 계좌상품코드 (2자리) |
| AFHR_FLPR_YN | Y | N:기본, Y:시간외단일가, X:NXT정규장 |
| INQR_DVSN | Y | 01:대출일별, 02:종목별 |
| UNPR_DVSN | Y | 01:기본값 |
| FUND_STTL_ICLD_YN | Y | N:미포함, Y:포함 |
| FNCG_AMT_AUTO_RDPT_YN | Y | N:기본값 |
| PRCS_DVSN | Y | 00:전일매매포함, 01:미포함 |
| CTX_AREA_FK100 | N | 연속조회키 (다음페이지) |
| CTX_AREA_NK100 | N | 연속조회키 (다음페이지) |

Response output1 (종목별):
| 필드 | 설명 |
|------|------|
| pdno | 종목번호 (6자리) |
| prdt_name | 종목명 |
| hldg_qty | 보유수량 |
| ord_psbl_qty | 주문가능수량 |
| pchs_avg_pric | 매입평균가격 |
| pchs_amt | 매입금액 |
| prpr | 현재가 |
| evlu_amt | 평가금액 |
| evlu_pfls_amt | 평가손익금액 |
| evlu_pfls_rt | 평가손익율 |
| fltt_rt | 등락율 |
| bfdy_cprs_icdc | 전일대비증감 |

Response output2 (계좌 요약):
| 필드 | 설명 |
|------|------|
| dnca_tot_amt | 예수금총금액 |
| nxdy_excc_amt | 익일정산금액(D+1) |
| prvs_rcdl_excc_amt | 가수도정산금액(D+2) |
| tot_evlu_amt | 총평가금액 |
| pchs_amt_smtl_amt | 매입금액합계 |
| evlu_amt_smtl_amt | 평가금액합계 |
| evlu_pfls_smtl_amt | 평가손익합계 |

### 주식현재가 시세 — GET /uapi/domestic-stock/v1/quotations/inquire-price

Query: `FID_COND_MRKT_DIV_CODE=J`, `FID_INPUT_ISCD={종목코드}`
TR ID: FHKST01010100

주요 응답 필드 매핑:
| API 필드 | Swift 이름 | 타입 | 설명 |
|----------|-----------|------|------|
| stck_prpr | currentPrice | Int | 현재가 |
| prdy_vrss | priceChange | Int | 전일 대비 |
| prdy_ctrt | changeRate | Double | 등락률 (%) |
| prdy_vrss_sign | direction | String | 1,2→rise / 3→flat / 4,5→fall |
| hts_kor_isnm | name | String | 종목명 |
| rprs_mrkt_kor_name | marketName | String | 시장명 |

### 종목 상세 정보 — GET /uapi/domestic-stock/v1/quotations/search-stock-info

Query: `PDNO={종목코드}`, `PRDT_TYPE_CD=300`
TR ID: CTPF1002R

| 필드 | 설명 |
|------|------|
| prdt_abrv_name | 종목 약어명 (우선 사용) |
| prdt_name | 종목 전체명 (폴백) |
| prdt_eng_name | 종목 영문명 |
| mket_id_cd | STK:유가증권, KSQ:코스닥 |
| scty_grp_id_cd | ST:주권, EF:ETF, EN:ETN |
| lstg_stqt | 상장주수 |

---

## 10. 기존 프로젝트 패턴

### 구현된 API
- `KISAuthService.swift` — Actor singleton, 토큰 캐싱 (23h), `getToken()` / `invalidateToken()`
- `KISQuoteService.swift` — singleton, `fetchQuote()` (FHKST01010100), `fetchStockName()` (CTPF1002R), `fetchQuotes()` (배치+rate limit)
- `KeychainService.swift` — UserDefaults 기반, `.appKey` / `.appSecret` / `.accountNumber`
- `Stock.swift` — `StockQuote.from(apiResponse:code:)` 정적 팩토리 패턴

### 새 엔드포인트 추가 체크리스트
- [ ] TR ID/URL 확인 (위 테이블)
- [ ] HTTP method (GET=조회, POST=주문)
- [ ] Service에 메서드 추가 (조회→KISQuoteService, 주문→새 Service)
- [ ] `KeychainService.load`로 인증 정보 로드
- [ ] `KISAuthService.shared.getToken()`으로 Bearer 토큰
- [ ] POST: body 키 **대문자**, `custtype: "P"` 헤더
- [ ] `rt_cd == "0"` 체크 후 output 파싱
- [ ] 루프 시 50ms sleep
- [ ] `KISError` enum에 case 추가
- [ ] 응답 모델에 `static from(apiResponse:)` 파서 (StockQuote 패턴)
