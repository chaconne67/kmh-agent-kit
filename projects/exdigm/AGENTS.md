# Project Agent Notes

- Project location: `/home/chaconne/exdigm`.
- 코드 지식의 공식 실행 경로는 `uv run --locked python -m tools.code_knowledge` 하나다.

## Agent Start Navigation

1. `git status --short`로 기존 사용자 변경을 확인하고 보존한다.
2. 가장 가까운 업무 표현이나 파일을 최소 코드 목차에서 조회한다.

```bash
uv run --locked python -m tools.code_knowledge code_query --query "<자연어·파일·심볼>" --format json
```

3. 사람이 읽을 때도 같은 질의를 사용하고 출력 형식만 바꾼다.

```bash
uv run --locked python -m tools.code_knowledge code_query --query "<자연어·파일·심볼>" --format markdown
```

4. 반환된 관계·확인 위치·실행 기능·코드 단서를 탐색 출발점으로 삼고 `rg`로 현재 코드를 확인한다. 지도는 경로 선택을 돕지만 현재 코드의 route·schema·권한·실제 데이터 동작을 대신하지 않는다.
5. 종료 코드 `3`은 후보가 애매하다는 뜻이므로 표현을 구체화한다. 종료 코드 `4`는 등록된 주제가 없다는 뜻이며 `rg --files`와 코드 검색으로 계속 탐색한다.

## Completion Gate

1. 변경 파일과 `rg`로 확인한 직접 관련 코드를 검증한다.
2. 코드를 수정한 모든 작업은 경량 목차 갱신을 실행한다.

```bash
uv run --locked python -m tools.code_knowledge catalog_update
```

3. 이 명령은 Git 변경분만 읽어 이동한 파일 힌트를 교체하고 삭제된 파일 힌트를 제거한다. 출력된 깨진 참조와 영향 topic을 보고 새 대표 위치·이름·사용자 표현이 생겼으면 같은 작업에서 `catalog.json`의 최소 힌트를 갱신하고 명령을 다시 실행한다. 의미와 관계는 명령이 자동 생성하지 않는다.
4. 정책·판단 기준이 바뀌었으면 관련 canonical GBrain page를 갱신한다. 코드 위치는 GBrain에 기록하지 않는다.
5. 결함·장애를 수정한 작업의 최종 보고에는 재발 판정을 함께 적는다: 
    - 수정한 작업이 같은 원인의 재발 경로를 닫는가? 
        ⓐ 닫힘: 근거 한 줄
        ⓑ 열림: 남은 경로와 방지 제안(방지책 구현은 별도 승인).

## 테스트 실행
- 테스트는 `uv` 환경에서 실행한다.
- 모든 `pytest` 실행은 공유 테스트 DB 충돌을 막기 위해 다음 공용 잠금 명령만 사용한다: `flock -E 75 -w 55 /tmp/exdigm-pytest.lock uv run --locked pytest -q`
- 집중 테스트는 위 명령의 `-q` 뒤에 테스트 경로를 덧붙인다.
- 공용 잠금 명령이 종료 코드 `75`를 반환하면 다른 테스트가 실행 중이다. 잠금 없이 새 테스트를 시작하지 말고 기존 실행을 확인·대기한 뒤 같은 명령을 다시 실행한다.
- `pytest` 준비만을 위한 별도 `uv sync`는 실행하지 않는다. `uv run`이 프로젝트의 기본 개발 의존성을 준비한다.
