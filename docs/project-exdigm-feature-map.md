# Exdigm Feature Map

검색 앵커: project/exdigm-feature-map, Exdigm 기능 지도, 프로젝트 화면, 후보자, 이력서, 알림, 뉴스, 액션.

## Purpose

Exdigm 기능별 첫 조사 위치를 담는 distilled feature map이다. Raw 파일 목록이 아니라 에이전트가 잘못된 실행 경로로 가지 않게 하는 시작점만 남긴다.

## Main Topics

- `프로젝트`: 프로젝트 상세, 후보자 추천과 제출 흐름
- `프로젝트 진행 단계`: 지원자 stage, 되돌리기, 탈락, 복원, 채용
- `프로젝트 후보자 발굴`: JD 기반 후보자 검색·매칭
- `이력서 생성`: 제출용/추천 이력서 생성과 다운로드
- `알림`: 알림벨, 다운로드 링크, Telegram 알림
- `인터뷰 관리`: 인터뷰 일정과 결과
- `액션·리마인더`: 할 일, 자동 액션, 리마인더
- `뉴스`: 뉴스 수집, 번역, 큐레이션

## First Targets

- Views: `projects/views/`
- Services: `projects/services/`
- Templates: `projects/templates/projects/`
- Lifecycle: `projects/services/application_lifecycle.py`
- Actions: `projects/services/action_lifecycle.py`
- Search: `projects/services/searching.py`

## Reuse Rules

- Candidate, ProjectBasketItem, Application을 구분한다.
- 단계 변경과 액션 변경은 lifecycle service를 우회하지 않는다.
- UI 변경은 실제 partial 사용 경로와 시각 검증을 확인한다.
- 후보자 매칭/추천은 기존 searching/recommendation service를 먼저 본다.
