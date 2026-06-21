# Exdigm Extraction Pipeline

검색 앵커: project/exdigm-extraction-pipeline, 데이터 추출, 이력서 추출, 파일 업로드, JD Processor, Mailplug, Drive.

## Purpose

이력서, JD, Mailplug, Drive 입력을 후보자·프로젝트 업무 데이터로 바꾸는 핵심 파이프라인이다. 새 입력 경로를 만들 때도 후보자 매칭, FileData, Drive target, latest resume 정책을 우회하지 않는다.

## First Targets

- code_map topic: `데이터 추출`, `파일 업로드`, `JD Processor`, `후보자 등록`, `이력서 최신 버전`
- Main command: `data_extraction/management/commands/update_candidates.py`
- Pipeline: `data_extraction/services/pipeline.py`
- Decision policy: `data_extraction/services/data_decision_policy.py`
- Extraction routing: `data_extraction/services/extraction/`
- Save path: `data_extraction/services/save.py`
- File upload: `data_extraction/services/upload_resume_file_to_drive.py`
- JD processor: `projects/services/jd_processor.py`

## Reuse Rules

- 수동 업로드, Mailplug/이메일, Drive 변경분은 같은 후보자 매칭 규칙을 따른다.
- 이메일/전화번호로 동일인을 판정하고 이름만으로 후보자를 병합하지 않는다.
- Drive 업로드는 등록된 intake target을 사용한다.
- Mail checker는 JD를 직접 만들지 않고 JD processor가 JobDescription/ProjectCreationRequest를 만든다.

## Validation

- `tests/test_update_candidates_results.py`
- `tests/test_application_lifecycle.py`
- `tests/test_upload_resume_file_to_drive.py`
- `tests/test_save_resume_file_metadata.py`
- `tests/test_jd_processor.py`
