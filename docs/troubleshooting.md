# Troubleshooting

## Bun Install Fails Because unzip Is Missing

현상:

```text
error: unzip is required to install bun
```

해결:

```bash
sudo apt-get update
sudo apt-get install -y unzip
curl -fsSL https://bun.sh/install | bash
```

## GBrain Uses The Wrong Database

현상: Exdigm `.env`의 `DATABASE_URL`이 GBrain subprocess에 섞여 들어갑니다.

해결: 직접 `gbrain`을 실행하지 말고 래퍼를 사용합니다.

```bash
~/.gbrain/bin/gbrain_with_google_env.sh doctor --fast
```

래퍼는 `DATABASE_URL`과 `OPENAI_API_KEY`를 제거합니다.

## Embedding Is Disabled

현상:

```text
embed=0%
embedding_disabled: true
stale chunks
```

원인: 검색용 임베딩 설정이 꺼져 있거나 provider/dimensions/schema가 맞지 않습니다. Distillation 모델 설정과는 별개입니다.

확인:

```bash
~/.gbrain/bin/gbrain_with_google_env.sh config show
~/.gbrain/bin/gbrain_with_google_env.sh embed --stale --dry-run
~/.gbrain/bin/gbrain_with_google_env.sh doctor --fast
```

## Daily Report Keeps Asking

`memory_distill.py check-pending`은 `~/.gbrain/reports/index.json`의 `last_prompted_date`를 보고 같은 날짜에는 한 번만 묻습니다.

리뷰 후 상태 표시:

```bash
python3 ~/.gbrain/bin/memory_distill.py mark YYYY-MM-DD --status reviewed --decision "accepted"
```
