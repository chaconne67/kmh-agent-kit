---
name: fundkeeper
description: FundKeeper 퀀트 동적 자산배분 & 리밸런싱 운영 시스템
---

# FundKeeper Skill - 퀀트 동적 자산배분 & 리밸런싱 운영 시스템

## 프로젝트 개요

**FundKeeper (coconut.im)** - 모멘텀에셋이 운영하는 로보어드바이저 플랫폼.
코스콤 로보어드바이저 테스트베드 2차에서 검증 중인 퀀트 동적 자산배분 웹 + 리밸런싱 운영 시스템.

**관련 스킬**: `testbed-base` (테스트베드 계좌/전략/서류), `fundkeeper-deploy` (배포/운영)

## 접속 정보

| 항목 | 값 |
|---|---|
| 앱 서버 | 49.247.38.186 (SSH root) - Django + Docker + Nginx |
| DB 서버 | 49.247.45.243 - MySQL 3306 (user: chaconne) |
| 프로젝트 경로 | `/home/work/fundkeeper` |
| Docker 경로 | `/home/docker/fundkeeper` |
| 도메인 | coconut.im |
| 개발 포트 | 8800 |
| 프로덕션 포트 | 443 (SSL) → 8000 (gunicorn) |
| DB 1 | `fundkeeper` - Django ORM (사용자, 포트폴리오, 주문 등) |
| DB 2 | `price` - OHLCV 시장 가격 데이터 (SQLAlchemy/pymysql) |

## 기술 스택

| 영역 | 기술 |
|---|---|
| Backend | Django 4.1.13, DRF, Python 3.11+ |
| DB | MySQL (utf8mb4) - `fundkeeper`(ORM) + `price`(OHLCV) 2개 DB |
| Frontend | Django templates + Tailwind CSS + HTMX + ApexCharts |
| 패키지매니저 | uv (uv.lock) |
| 배포 | Docker Swarm, gunicorn → Nginx(SSL) |
| Settings | `fundkeeper/settings/` - base.py, local.py(dev), deploy.py(prod) |
| AI/ML | Anthropic, OpenAI, Gemini, TensorFlow, scikit-learn, LightGBM, XGBoost, Optuna |
| 트레이딩 | KIS API (한국투자증권), WebSocket 실시간, pykrx |

## Django 앱 구조 (20개)

### 핵심 포트폴리오 앱
| 앱 | 설명 | 핵심 파일 |
|---|---|---|
| `simulation` | 백테스팅 엔진, `Simulation` 베이스 클래스 (833줄) | simulation.py, tools.py(567줄), calc.py, charts.py, fetch_price.py |
| `myportfolio` | 포트폴리오 CRUD, `MyPortfolioHandler`→`Simulation` 상속 | myportfolio.py, models.py |
| `portfolio_awt` | AWT(Aggressive Weight Timing) 전략 | views.py |
| `portfolio_baa` | BAA(Bold Asset Allocation) 전략 | views.py |
| `portfolio_mix` | Mixed 전략 (서브 포트폴리오 조합) | views.py |
| `rebalancing_info` | 리밸런싱 스케줄 및 실행 (855줄) | rebalancing.py |

### 사용자/계좌 앱
| 앱 | 설명 |
|---|---|
| `fkuser` | 인증 (카카오 OAuth), 사용자 관리, 결제 상태 |
| `myaccount` | 증권 계좌 연동 (KIS API), 자동매매 실행 기록, 오토봇 주문 라이프사이클 |
| `order` | 리밸런싱 주문 관리 (OrderList, OrderAccounts, RebalancingSchedule) |
| `userprofile` | 사용자 프로필 |
| `myfriends` | 친구/어드바이저 기능 |

### 유틸리티 앱
| 앱 | 설명 |
|---|---|
| `etfs` | ETF 종목 데이터 |
| `krx_filter` | KRX 종목 스크리닝 |
| `recipe` | ETF 배분 레시피 |
| `monthly_report` | 월간 포트폴리오 리포트 |
| `pay` | 카카오페이 결제 |
| `config` | 전역 설정, .env 로드 (`config/info.py`) |
| `custom_tags` | Django 템플릿 태그/필터 |
| `retire` | 은퇴 설계 |
| `support` | 고객 지원 |

## 클래스 상속 구조

```
Tools (simulation/tools.py) - 데이터 페칭, 시장 유틸리티
  └── Simulation (simulation/simulation.py) - 백테스팅 엔진
       └── MyPortfolioHandler (myportfolio/myportfolio.py) - 포트폴리오 CRUD
            └── 각 포트폴리오 뷰 (portfolio_awt, portfolio_baa, portfolio_mix)
```

## 핵심 모델 관계도

```
Fkuser (사용자)
  ├── MyAccount (증권계좌) ──── MyAccountAuth (API 키: appkey, appsecret, access_token)
  │     ├── CashFlow (입출금)
  │     ├── TradeHistory (매매내역)
  │     ├── ValueHistory (계좌수익률)
  │     ├── AutoBotRun (자동매매 실행)
  │     │     ├── AutoBotOrderLifecycle (주문 라이프사이클: pending→accepted→filled)
  │     │     ├── AutoBotSignalEvent (신호 이벤트)
  │     │     └── AutoBotPositionDaily (일별 포지션)
  │     └── OrderAccounts / OrderList (리밸런싱 주문)
  ├── MyPortfolios (포트폴리오)
  │     ├── Backtest → BacktestTicker, BacktestCMS(CAGR/MDD/Sharpe), BacktestMonthWt
  │     ├── PortfolioCMS (포트폴리오 성과지표)
  │     ├── MasterDataFrame (JSON 캐시)
  │     ├── MyPortfolioManager (믹스 포트폴리오 하위 관계)
  │     └── Recipe (배분 레시피)
  ├── ClientAccount (수동 계좌)
  └── MyPortfolioLink (포트폴리오 공유)

Asset (ETF/종목: ticker, asset_class, currency, market, pension, svr)
  └── AssetCMS (종목별 성과지표 + mmt_score)

RebalancingSchedule (rday, tday, market, code)
  └── OrderAccounts / OrderList / TestBedBalance
```

## xmodules/ (비-Django 고급 모듈)

### autobot/kosdaqpi_v3/ - 실시간 변동성 돌파 트레이딩봇
| 파일 | 줄수 | 설명 |
|---|---|---|
| realtime_trader.py | 1,014 | WebSocket 기반 실시간 트레이더 |
| trading_bot_v2.py | 1,574 | 주문 실행 엔진 |
| strategy.py | 622 | 돌파 시그널, 손절, 필터 |
| backtest_final.py | - | 통합 백테스팅 |
| optimizer_ultimate.py | - | Optuna 하이퍼파라미터 튜닝 |
| settings.py | - | 봇 설정 |

### 기타 xmodules
| 모듈 | 설명 |
|---|---|
| `machine/` | ML 모델 (LSTM, 앙상블, 리스크 감지, 마켓 레짐) |
| `system/` | 시스템 유지보수 (가격DB 업데이트, 캐시 갱신) |
| `analysis/` | 리밸런싱 갭 분석 |
| `research/` | 백테스트/KRX 리서치 도구 |
| `order/` | 포트폴리오 주문 관리 |
| `sh/` | 배포/운영 셸 스크립트 (시스템 업데이트, Docker 정리, certbot 갱신) |
| `test_bed/` | 테스트베드 자료 생성/운용 (`testbed-base` 참조) |

## URL 라우팅

| Prefix | App | 설명 |
|---|---|---|
| `/` | home | 메인 |
| `/myportfolio/` | myportfolio | 포트폴리오 관리 |
| `/awt/` | portfolio_awt | AWT 전략 |
| `/baa/` | portfolio_baa | BAA 전략 |
| `/mix/` | portfolio_mix | Mixed 전략 |
| `/simulation/` | simulation | 백테스트 |
| `/rebalancing_info/` | rebalancing_info | 리밸런싱 |
| `/order/` | order | 주문 |
| `/etf/` | etfs | ETF 데이터 |
| `/fkuser/` | fkuser | 인증 |
| `/myaccount/` | myaccount | 계좌 |
| `/review/` | monthly_report | 월간 리포트 |
| `/krx_filter/` | krx_filter | KRX 필터 |
| `/recipe/` | recipe | 레시피 |
| `/pay/` | pay | 결제 |
| `/userprofile/` | userprofile | 프로필 |
| `/myfriends/` | myfriends | 친구 |
| `/retire/` | retire | 은퇴 |
| `/support/` | support | 고객지원 |

## 코딩 컨벤션
- 코드 최소화 원칙 - 불필요한 주석, 예외처리, 디버깅 코드 금지
- 기존 파일 수정 우선, 새 파일 생성 최소화
- 기존 코드 대규모 변경 시 확인 필요
- UI 텍스트, 주석, git 커밋 메시지: 한국어
- 월간 리포트 HTML: `docs/report_design_guide.md` 디자인 가이드 준수
