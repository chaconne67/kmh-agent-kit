---
name: fundkeeper-deploy
description: FundKeeper 배포/운영 - Docker Swarm & 서버 관리
---

# FundKeeper 배포/운영 - Docker Swarm & 서버 관리

**관련 스킬**: `fundkeeper` (프로젝트 전체), `testbed-base` (테스트베드)

## 주요 커맨드

```bash
# 개발 서버
python manage.py runserver 0.0.0.0:8800

# DB 마이그레이션
python manage.py makemigrations
python manage.py migrate

# Tailwind CSS 빌드
npx tailwindcss -i ./static/input.css -o ./static/output.css

# 정적 파일 수집
python manage.py collectstatic --noinput

# 배포 (commit → Docker build → Swarm deploy)
./deploy.sh

# 트레이딩 봇 - 백테스트
python xmodules/autobot/kosdaqpi_v3/backtest_final.py

# 트레이딩 봇 - 실시간
python xmodules/autobot/kosdaqpi_v3/realtime_trader.py --mode test --account 334
```

## 배포 구조

```
/home/docker/
├── deploy.sh              # 3단계: save_(git+rsync) → build_(Docker) → deploy_(Swarm)
├── docker-stack.yml       # Swarm 스택 정의 (nginx + coconut 서비스)
├── fundkeeper/
│   ├── Dockerfile         # Python 3.12, uv, gunicorn
│   └── fundkeeper/        # rsync로 복사되는 소스
├── nginx/
│   ├── Dockerfile         # nginx:latest
│   ├── nginx.conf         # SSL(Let's Encrypt), upstream coconut:8000
│   └── static/            # collectstatic 결과물
└── scripts/
    ├── certbot_renew.sh   # SSL 인증서 갱신
    └── docker_cleanup.sh  # Docker 정리
```

프로덕션 런타임: `gunicorn --settings=fundkeeper.settings.deploy` → Nginx(443/SSL) → Django(8000)
볼륨 마운트: `/home/work/fundkeeper/data`, `.env`

## 서버 정보

| 항목 | 값 |
|---|---|
| 앱 서버 | 49.247.38.186 (SSH root) |
| DB 서버 | 49.247.45.243 - MySQL 3306 |
| 프로젝트 경로 | `/home/work/fundkeeper` |
| Docker 경로 | `/home/docker/fundkeeper` |
| 도메인 | coconut.im |
| Settings | `fundkeeper/settings/deploy.py` (프로덕션) |
