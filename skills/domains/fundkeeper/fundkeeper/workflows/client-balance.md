# 수동계좌 잔고 입력 (이미지 기반)

수동 계좌(`ClientAccount`) 보유 종목 + 현금 + 평가액을 스크린샷에서 추출해 DB 업데이트.

## 입력 이미지 형식

보통 7~10장 1세트:
- **요약 1장**: 총 적립금, 입금액(+), 운용수익, 출금액(-), 최종 적립금, 수익률
- **원리금보장형 1장**: 현금성 자산 (예: 삼성생명 고유대) - 적립금 = `ClientCash.value`
- **ETF 카드 N장**: 종목명, 적립금, 수익률, 좌수, 기준가

## 데이터 추출 + 도메인 공식

ETF 카드에서:
- `qty` = 좌수
- 평가액 = 적립금 (검증: `qty × 기준가 ≈ 적립금`)
- **`avg_price = 기준가 / (1 + 수익률)`** ← 사용자 합의 공식 (수익률은 음수면 음수 그대로)

전체 검증: `Σ ETF 평가액 + 현금 = 총 적립금`

## DB 모델 (FK 주의)

| 모델 | 앱 | 필드 | 비고 |
|---|---|---|---|
| `ClientAccount` | `myaccount.models` | `value` | 평가액 갱신 필수 |
| `ClientCash` | `myfriends.models` | `account` FK, `value`, `currency='krw'` | 현금성 자산 |
| `ClientTicker` | `myfriends.models` | `account` FK, `ticker` FK→`simulation.Asset`, `qty`, `avg_price` | ETF 보유 |

종목 매칭: `Asset.objects.get(ticker='6자리코드')`. 코드 안 보이면 `description__icontains`.

## 절차

1. 고객명으로 `ClientAccount` 조회 (`fkuser__name=...`) — PK 확정
2. 이미지가 전체 보유 종목 세트인지 확인하고 데이터 추출 + 검증 (표시된 총 종목 수, 합계, qty×기준가)
3. 현재 DB와 비교표 출력 (신규·변경·삭제 종목, qty/avg_price/현금/평가액 차이)
4. **사용자 승인** 받고 진행
5. `transaction.atomic()` 안에서 Django shell로 전체 종목 세트를 동기화:
   - `ClientTicker.objects.update_or_create(account=c, ticker=asset, defaults={'qty':..., 'avg_price':...})`
   - 승인된 전체 종목 코드에 없는 기존 `ClientTicker` 삭제
   - `ClientCash` `value` 갱신
   - `ClientAccount.value` 갱신 (잊지 말 것)
6. DB를 다시 조회해 종목 코드 집합·qty·avg_price·현금·평가액이 승인값과 모두 같은지 검증
7. 결과 보고

## 함정

- **`ClientAccount.value` 갱신 누락**: 안내문/리포트 평가액과 어긋남
- **신규 매수 종목**: `ClientTicker`에 없으면 `create`. `Asset` 매칭 실패 시 사용자 확인 (티커 신규 등록 필요할 수도)
- **매도 완료 종목**: 전체 보유 종목 세트에서 사라진 기존 `ClientTicker`는 비교표에 삭제 대상으로 표시하고 승인 후 삭제
- **부분 이미지**: 전체 종목 수와 페이지 구성이 확인되지 않으면 기존 종목을 삭제하거나 DB를 갱신하지 않음
- **avg_price**: 누적 가중평균 아님. 매번 위 공식으로 재계산 (수익률 시점 평단가)
- **현금 단위**: 화면 "원" 단위 그대로 정수로 입력 (`ClientCash.value` 는 `IntegerField`)
