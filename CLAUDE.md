# CLAUDE.md - redmine_tx_advanced_issue_status

## 개요

Redmine 기본 이슈 상태는 `is_closed` (true/false)만 제공하여 진행 단계를 구분할 수 없음.
이 플러그인은 `issue_statuses` 테이블에 `stage` (integer) 컬럼을 추가하여 9단계 분류 체계를 제공한다.

## 디렉토리 구조

```
├── init.rb                              # 플러그인 등록, 설정 정의, 패치 로딩
├── lib/
│   ├── tx_advanced_issue_status_helper.rb          # Stage 상수, 판별 메서드, 캐싱
│   ├── tx_advanced_issue_status_hook.rb             # 관리자 UI Hook (JS 주입)
│   ├── tx_advanced_issue_status_issue_patch.rb      # Issue 모델 패치 (콜백, 동기화)
│   └── tx_advanced_issue_status_issue_status_patch.rb  # IssueStatus 모델 패치 (API)
├── app/views/
│   ├── settings/_tx_advanced_issue_status.html.erb  # 플러그인 설정 화면
│   └── context_menus/issues.html.erb                # 컨텍스트 메뉴 오버라이드
├── db/migrate/
│   ├── 1_add_stage_to_issue_status.rb               # stage 컬럼 추가
│   └── 2_add_is_paused_to_issue_status.rb           # is_paused 컬럼 추가
├── config/locales/en.yml                # 영어/한국어 번역 (ko 포함)
└── config/routes.rb                     # 빈 파일 (커스텀 라우트 없음)
```

## Stage 단계 정의

`TxAdvancedIssueStatusHelper` 모듈에 상수로 정의됨.

| 상수 | 값 | 의미 |
|------|-----|------|
| `STAGE_DISCARDED` | -2 | 폐기 |
| `STAGE_POSTPONED` | -1 | 보류 |
| `STAGE_NEW` | 0 | 신규 |
| `STAGE_SCOPING` | 1 | 검토중 |
| `STAGE_IN_PROGRESS` | 2 | 진행중 |
| `STAGE_REVIEW` | 3 | 검수중 |
| `STAGE_IMPLEMENTED` | 4 | 구현끝 |
| `STAGE_QA` | 5 | QA |
| `STAGE_COMPLETED` | 6 | 종결 |

`STAGE_OPTIONS` 해시가 stage 값을 i18n 키로 매핑한다.

## 핵심 모듈별 역할

### Helper (`tx_advanced_issue_status_helper.rb`)
- Stage 상수 및 `STAGE_OPTIONS` 정의
- `is_*_stage?(stage)` 클래스 메서드 — stage 값으로 단계 판별
- `all_issue_statuses` — IssueStatus 전체 목록을 5분간 캐싱

주의: `is_in_progress_stage?`는 `STAGE_IN_PROGRESS`와 `STAGE_REVIEW` 둘 다 true를 반환.
주의: `is_implemented_stage?`는 `>= STAGE_IMPLEMENTED`로 판별 (QA, COMPLETED 포함).

### IssueStatus 패치 (`tx_advanced_issue_status_issue_status_patch.rb`)
- 인스턴스 메서드: `stage_name`, `is_new?`, `is_in_progress?`, `is_completed?` 등
- 클래스 메서드: `IssueStatus.is_new?(status_id)`, `IssueStatus.new_ids`, `IssueStatus.get_stage(status_id)` 등
- `safe_attributes`로 `stage`, `is_paused` 추가

### Issue 패치 (`tx_advanced_issue_status_issue_patch.rb`)
- `before_save :before_update_done_ratio` — Hybrid done_ratio 업데이트 + 이전 태그 캡처
- `after_save :after_update_done_ratio` — 태그/버전/우선순위 부모→자식 동기화, 부모 자동 갱신
- `is_new?`, `is_in_progress?` 등 인스턴스 메서드 (내부적으로 `IssueStatus.get_stage` 사용)

### Hook (`tx_advanced_issue_status_hook.rb`)
- `view_layouts_base_html_head` 훅으로 `/issue_statuses` 관리자 페이지에 JS 주입
- index 페이지: Stage, Is Paused 컬럼 동적 삽입
- edit/new 페이지: stage 드롭다운, is_paused 체크박스 폼 필드 삽입

## 플러그인 설정값

`Setting.plugin_redmine_tx_advanced_issue_status`로 접근.

| 키 | 기본값 | 설명 |
|----|--------|------|
| `enable_hybrid_logic` | true | 상태 변경 시 리프 일감의 done_ratio 자동 갱신 |
| `enable_parent_auto_update` | false | 자식 시작 시 부모 상태 자동 변경 |
| `enable_auto_sync_target_version` | false | 목표버전 부모→자식 동기화 |
| `enable_auto_sync_priority` | false | 우선순위 부모→자식 동기화 |
| `enable_auto_sync_tag` | false | 태그 부모→자식 동기화 (느림 주의) |

## DB 스키마 변경

`issue_statuses` 테이블에 2개 컬럼 추가:
- `stage` (integer) — Stage 단계 값
- `is_paused` (boolean, default: false) — 일시정지 여부

## 빌드/테스트

```bash
# 마이그레이션
bundle exec rake redmine:plugins:migrate NAME=redmine_tx_advanced_issue_status RAILS_ENV=production

# 테스트 (test/test_helper.rb만 존재, 실제 테스트 미작성)
bundle exec rake redmine:plugins:test NAME=redmine_tx_advanced_issue_status
```

## 의존성

- Redmine 코어 (`Issue`, `IssueStatus`, `Setting`)
- `redmine_tx_0_base` — 공용 헬퍼 (간접 의존)
- `redmineup_tags` — 태그 동기화 기능 사용 시 필요 (`RedmineupTags::JournalHelper`)

## 개발 시 주의사항

- 레드마인 전역 설정에서 "이슈 상태에 따른 진척도"를 **꺼야** hybrid logic이 정상 동작
- `all_issue_statuses` 캐시는 5분 TTL — IssueStatus 변경 후 즉시 반영 안 될 수 있음
- 태그 동기화(`enable_auto_sync_tag`)는 자식마다 DB 조회하므로 성능 이슈 있음
- Hook에서 JS를 문자열로 직접 생성하므로 XSS에 주의 (현재 i18n 값만 사용)
- `is_implemented?`는 `stage >= 4`이므로 QA(5), COMPLETED(6)도 포함됨
- 커스텀 라우트 없음 — 모든 UI 확장은 Hook 기반
