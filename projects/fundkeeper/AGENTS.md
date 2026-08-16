# FundKeeper 중앙 제어 프로젝트

## 목적

- 이 폴더는 FundKeeper의 프로젝트 지식과 에이전트 작업 문맥만 관리합니다.
- 애플리케이션 소스·Git 저장소·가상환경·운영 데이터는 원격 서버에만 둡니다.
- 원격 Codex와 Claude에는 프로젝트 지침·스킬·GBrain을 설치하지 않습니다.

## 원격 정본

| 항목 | 값 |
|---|---|
| SSH | `chaconne@49.247.38.186` |
| 실제 저장소 | `/home/chaconne/fundkeeper` |
| 운영 호환 경로 | `/home/work/fundkeeper` → 실제 저장소 심볼릭 링크 |
| 원격 Codex | `/home/chaconne/.npm-global/bin/codex` |
| 원격 Claude | `/usr/bin/claude` |
| Docker 작업 경로 | `/home/docker` |
| 운영 도메인 | `coconut.im` |

## 작업 경로

1. 작업 전 원격 저장소의 브랜치와 변경 상태를 확인합니다.
2. 사용자 변경·미추적 파일은 보존하고 요청 범위의 파일만 수정합니다.
3. 코드 검색·수정·Git·테스트·배포 명령은 SSH를 통해 원격 서버에서 실행합니다.
4. 이 중앙 폴더에는 애플리케이션 코드를 복제하거나 실행 환경을 만들지 않습니다.
5. 배포와 데이터 변경은 주인님의 명시적 요청이 있을 때만 실행합니다.

## 안전 경계

- `.env`, `.venv`, `data/`, 운영 DB, Docker Swarm, 예약 작업은 요청 없이 변경하지 않습니다.
- `xmodules/sh/`는 운영 예약 작업에서 직접 호출되므로 수정 전 실행 주체와 호출 경로를 확인합니다.
- 원격 저장소의 에이전트 지침 파일과 원격 사용자 영역의 에이전트 스킬을 다시 만들지 않습니다.
- 프로젝트 판단 전 GBrain의 `project/fundkeeper-operating-context`를 확인합니다.

## 프로젝트 지식

- 일반 구조와 개발 지식은 중앙 `fundkeeper` 스킬을 사용합니다.
- 운영·배포 절차는 중앙 `fundkeeper-deploy` 스킬을 사용합니다.
- 현재 코드가 기록된 지식과 다르면 원격 코드를 기준으로 검증합니다.
