---
name: exdigm-design
description: Use when working on exdigm UI/templates — adding screens, styling, refactoring layouts, picking color/typography/spacing tokens, building cards/sidebar/header/calendar/buttons, or anything touching Tailwind classes, Pretendard font, ink/ink2/ink3/muted/faint/hair/line/canvas/surface tokens, eyebrow/chip/tag/status-dot/progress patterns, or HTML mockups under `assets/ui-sample/`. Single source of truth for exdigm's **visual system** and **UI/UX principles** — do not duplicate rules elsewhere.
---

# exdigm 디자인 시스템

이 스킬은 exdigm UI 작업의 **단일 진실 소스**다. 시각과 UX 두 축을 한 곳에서 보고, 한 화면을 만들 때 양쪽을 동시에 적용한다. Codex에서 디자인·UI·UX 관련 새 지침을 받으면 다른 문서에 흩어 쓰지 말고 이 스킬을 갱신한다.

## 0. 헌장 — 이 스킬을 쓰는 법

### 두 축

| 축 | 다루는 것 | 섹션 |
|---|---|---|
| **A. 시각 시스템 (디자인)** | 폰트·색·간격·그림자·반경·모션·컴포넌트 시각 명세 | §1 ~ §5 |
| **B. UI/UX 원칙 (사용)** | 화면 구조·정보 계층·인터랙션·라벨 톤·검수 기준 | §6 ~ §9 |

**한 화면을 만들 때 반드시 두 축을 함께 본다.** §10 "통합 패턴"에 두 축이 동시에 작동하는 화면 단위 케이스를 모아 두었다. 운영 템플릿을 쓸 때는 §10을 먼저 찾고, 토큰·컴포넌트 시각 명세는 §1~§5로, 흐름·인터랙션 원칙은 §6~§9로 내려가서 본다.

### 원천 우선순위 (코드가 진실)

1. **`tailwind.config.js`** + **`static/css/input.css`** — 디자인 토큰의 단일 진실. 본 스킬 §1~§5는 이 두 파일을 사람이 읽기 좋게 옮긴 사본이다.
2. **`templates/` 및 각 앱의 `templates/`** — 실제 운영 템플릿. 컴포넌트가 어떻게 조합되는지의 실사용 사례.
3. **`assets/ui-sample/*.html`** — 화면 의도 reference. 인라인 `<style>` 블록은 mockup이 독립 실행 가능하도록 두는 **예외**다 (§7.8 참조).
4. **본 스킬** — 위 셋을 의미 단위로 묶은 요약.

**불일치 시 코드가 승.** 코드가 바뀌면 본 스킬을 즉시 갱신한다(§13).

### 예외 — 사이드바 메뉴 아이콘

`templates/common/nav_sidebar.html`의 `<svg>` 아이콘 세트를 유지한다. 도메인 의미에 맞춰 이미 선택된 것이라 mockup 아이콘으로 교체하지 않는다.

---

# 축 A — 시각 시스템

## 1. Foundations

### 1.1 Font

```
"Pretendard Variable", Pretendard, -apple-system, BlinkMacSystemFont, system-ui, sans-serif
```

CDN: `https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/variable/pretendardvariable-dynamic-subset.min.css`

- **전역 antialiasing:** `-webkit-font-smoothing: antialiased`
- **Tabular numerals:** 숫자 카운터/금액/통계에 `.tnum` 유틸 적용. `font-feature-settings: "tnum" 1, "ss01" 1; font-variant-numeric: tabular-nums`

### 1.2 Color Tokens

`tailwind.config.theme.extend.colors`에 정의된 값 그대로:

| Token | Hex | 용도 |
|---|---|---|
| `canvas` | `#F8FAFC` | 페이지 배경, 셀 hover, 헤더 행 배경 |
| `surface` | `#FFFFFF` | 카드, 셀, 상단 헤더 |
| `ink` | `#0F172A` | 사이드바 배경, 다크 강조 카드(KPI), 본문 강조 텍스트. **버튼·토글에는 사용 금지** |
| `ink2` | `#1E293B` | 사이드바 hover/active, 버튼 hover, 아바타 배경 |
| `ink3` | `#334155` | **모든 primary 버튼 / active 토글의 기본 배경**, 본문 텍스트 2차, 진행바 default fill |
| `muted` | `#475569` | 본문 보조 텍스트, ghost 버튼 텍스트 |
| `faint` | `#64748B` | 메타 텍스트, 라벨, eyebrow, placeholder, 아이콘 secondary |
| `hair` | `#d8dee6` | 카드 외곽선, border default |
| `line` | `#F1F5F9` | 카드 내부 옅은 디바이더, chip 배경, 페일 배경 tint |
| `success` | `#10B981` | active 상태, 성공 |
| `warning` | `#F59E0B` | review 상태, 주의 |
| `info` | `#6366F1` | completed/info 상태, 차트 보조 |
| `danger` | `#EF4444` | 에러, deadline 경고 |

**캘린더 전용 보더 색:** `#EEF2F7` (hair보다 한 단계 연함). 입력창·tabs·workspace modal 보더는 `#E2E8F0`.

#### 의미적 계층 — dark 잉크 톤

| 톤 | 용도 |
|---|---|
| `ink` (`#0F172A`) | 사이드바 배경, 페이지 내 단 1개의 다크 강조 KPI 카드 (예: 대시보드 Estimated Revenue) |
| `ink2` (`#1E293B`) | 위 두 가지의 hover, 버튼 hover, 헤더 사용자 아바타 배경 |
| `ink3` (`#334155`) | **모든 primary 버튼 / FAB / active 토글 / 다크 칩**의 기본 배경 |

- 버튼·토글에 절대 `ink`를 쓰지 말 것 — 너무 진해 사이드바와 시각적으로 충돌.
- 버튼은 `ink3` → hover `ink2` — 한 단계 진해지는 자연스러운 hover 피드백.
- 다크 잉크(`ink`)는 강조 1개당 1개만 — 페이지 내 다크 카드는 시선 앵커이므로 남발 금지.
- 브랜드 컬러는 잉크 톤 — 별도 brand purple/blue 없음. 액션·CTA는 모두 슬레이트 계열.
- 상태 컬러는 의미 전용 — success/warning/info/danger를 장식으로 쓰지 말 것.

### 1.3 Spacing

`4px` 베이스, `8px` 그리드. Tailwind 기본 스케일 사용.

| Token | px | 용도 |
|---|---|---|
| `space-1` | 4 | tag 내부, icon gap, dot 마진 |
| `space-2` | 8 | 버튼 v-padding, 이벤트 pill 위 마진 |
| `space-3` | 12 | 컨테이너 내부 작은 gap, 사이드바 link gap |
| `space-4` | 16 | 컴포넌트 내부 gap, 컨트롤 padding |
| `space-5` | 20 | 통계 카드 내부 vertical gap |
| `space-6` | 24 | **카드 padding 표준, 그리드 gap 표준, 사이드바 v-padding** |
| `space-8` | 32 | 메인 컨텐츠 edge padding |

**고정 패턴:** 카드 `p-6` · 메인 영역 `px-8 py-8` · 그리드 `gap-6` · 사이드바 nav `px-4 py-6`.

### 1.4 Border Radius

`tailwind.config.theme.extend.borderRadius.card = '16px'`.

| Token | px | 용도 |
|---|---|---|
| `rounded-lg` | 8 | 사이드바 link, 작은 inner 컨테이너, workspace 모달 내부 카드 |
| `rounded-card` | 16 | **모든 일반 카드** (통계, 리스트, 캘린더 카드) |
| `rounded-full` | 9999 | 아바타, status dot, chip/pill, FAB, 알림 버튼, 진행바 |

`rounded-md` (6px)는 일관성을 위해 사용하지 않는다.

### 1.5 Shadows

`tailwind.config.theme.extend.boxShadow`에 정의된 값 그대로:

```js
{
  card:      '0 2px 4px -1px rgba(15,23,42,0.08), 0 4px 12px -2px rgba(15,23,42,0.10)',
  lift:      '0 4px 6px -1px rgba(15,23,42,0.08), 0 2px 4px -2px rgba(15,23,42,0.04)',
  fab:       '0 10px 15px -3px rgba(15,23,42,0.15), 0 4px 6px -2px rgba(15,23,42,0.08)',
  searchbar: '0 10px 40px -10px rgba(15,23,42,0.18), 0 4px 12px -4px rgba(15,23,42,0.08)',
}
```

| Token | 용도 |
|---|---|
| `shadow-card` | 모든 일반 카드의 기본 그림자 |
| `shadow-lift` | 다크 강조 카드, 한 단계 더 떠 있는 요소 |
| `shadow-fab` | 플로팅 액션 버튼 |
| `shadow-searchbar` | 보이스/명령 검색 바, 떠 있는 입력 |

**hover lift — `<a>` / `<button>`에 붙은 `.rounded-card`에만 적용** (정적 `section`/`div`에는 hover 효과 없음). `transform` 금지. `position: relative` + `top` 으로만 lift 한다 — `translateY`/`translate3d`는 hover 시점에 텍스트 안티앨리어싱 모드를 바꿔 글자가 흐려진다.

```css
a.rounded-card, button.rounded-card {
  position: relative;
  top: 0;
  transition: top 200ms cubic-bezier(0.4,0,0.2,1),
              box-shadow 200ms cubic-bezier(0.4,0,0.2,1);
}
a.rounded-card:hover, button.rounded-card:hover {
  top: -2px;
  box-shadow: 0 12px 24px -10px rgba(15,23,42,0.18),
              0 4px 8px -4px rgba(15,23,42,0.08);
}
a.bg-ink.rounded-card:hover, button.bg-ink.rounded-card:hover {
  box-shadow: 0 16px 32px -12px rgba(15,23,42,0.45),
              0 6px 12px -6px rgba(15,23,42,0.2);
}
```

### 1.6 Motion · Focus · Reduced Motion

- **Easing:** `cubic-bezier(0.4, 0, 0.2, 1)` (ease-out 표준)
- **Transitions:**
  - **150ms** (`.15s ease`): 색상 변화 (사이드바 link, 셀 hover, 칩 토글)
  - **200ms** (`cubic-bezier(0.4,0,0.2,1)`): 카드 lift (top + shadow)
- **Focus visible (전역):**
  ```css
  *:focus-visible { outline: 2px solid #334155; outline-offset: 2px; border-radius: 4px; }
  input:focus-visible, select:focus-visible, textarea:focus-visible { outline: none; }
  .sidebar-tab:focus-visible { outline: none; }
  ```
- **Reduced motion (전역):**
  ```css
  @media (prefers-reduced-motion: reduce) {
    *, *::before, *::after {
      animation-duration: 0.01ms !important;
      animation-iteration-count: 1 !important;
      transition-duration: 0.01ms !important;
    }
  }
  ```
- **Safe area:** 모바일 하단 패딩은 `.safe-area-pb { padding-bottom: env(safe-area-inset-bottom); }`
- 과시적 애니메이션 금지. 진입은 fade, 상태 변화는 색·그림자만.

---

## 2. Typography Scale

Tailwind 기본 스케일(`text-xs` ~ `text-5xl`)을 적극 사용. 커스텀 클래스(`input.css` `@layer components`)의 `font-size`도 기본 스케일에 맞춰 `@apply text-xs` 같이 토큰 참조. **인라인 arbitrary `text-[Xpx]`는 쓰지 않는다.**

| Role | 클래스 | size | weight | 용도 |
|---|---|---|---|---|
| Hero / Stat number | `text-4xl font-bold tnum` | 36 | 700 | 대시보드 핵심 KPI |
| Page title | `text-3xl font-bold tracking-tight` | 30 | 700 | 페이지 상단 H1 |
| Section / subtitle | `text-2xl font-bold` | 24 | 700 | 주요 섹션 head, 프로젝트 상세 타이틀 |
| Stat secondary | `text-xl font-bold tnum` | 20 | 700 | sub stat |
| Subheading / Logo | `text-lg font-semibold` | 18 | 600 | 서브 헤딩, 사이드바 로고 |
| Card title | `text-base font-bold` | 16 | 700 | 카드 내 주요 문구 |
| Body | `text-sm` | 14 | 400 | 일반 본문, 버튼, 메뉴 |
| Body strong | `text-sm font-semibold` | 14 | 600 | 이름, 강조 |
| Body small | `text-xs` | 12 | 400~700 | 메타, 날짜, 보조 정보 |
| Eyebrow (en) | `.eyebrow` | 12 | 700 | UPPERCASE 섹션 라벨, `letter-spacing: 0.08em`, color `faint` |
| Eyebrow (ko) | `.eyebrow-ko` | 12 | 600 | 한글 섹션 라벨, no uppercase, no letter-spacing |
| Chip / Tag / Badge | `.chip` `.tag` `.badge` | 12 | 500~700 | pill 류 |
| Avatar initials | `.av-stack > *` | 12 | 700 | 이니셜 (28px 원) |

### 변형
- **진한 eyebrow** (요일 헤더 등): `class="eyebrow !text-ink3"`
- **dark 카드 내부 eyebrow:** `style="color:#64748B"` (ink2 위에서 가독성)
- **한국어 라벨**은 `eyebrow-ko`를 우선 — UPPERCASE는 한글에 의미 없음.

---

## 3. Layout

### 3.1 Page Skeleton

```
┌─────────────────────────────────────────────┐
│  body (bg: canvas)                          │
│  ┌──────────┬─────────────────────────────┐ │
│  │ Sidebar  │  Right column               │ │
│  │ 260px    │  flex-1 (header + main)     │ │
│  │ ink bg   │                             │ │
│  │          │  ┌─────────────────────────┐│ │
│  │ logo     │  │ Header 72h (full width) ││ │
│  │ nav      │  └─────────────────────────┘│ │
│  │          │  ┌─────────────────────────┐│ │
│  │ settings │  │ Main max-w 1280         ││ │
│  └──────────┴──┴─────────────────────────┘ │
└─────────────────────────────────────────────┘
```

```html
<body class="min-h-screen">
  <div class="flex min-h-screen">
    <aside class="w-[260px] shrink-0 bg-ink text-white flex flex-col">…</aside>
    <div class="flex-1 min-w-0 flex flex-col">
      <header class="h-[72px] bg-surface border-b border-hair px-8 flex items-center justify-between">…</header>
      <main class="w-full max-w-[1280px] flex flex-col">
        <div class="px-8 py-8 space-y-6 flex-1">…sections…</div>
      </main>
    </div>
  </div>
</body>
```

**고정값:** 사이드바 `260px` · 헤더 `72px` · 메인 `max-width: 1280px` · 메인 padding `px-8 py-8` · 섹션 간격 `space-y-6`.

### 3.2 Grid

- **표준:** `grid grid-cols-12 gap-6`
- **컬럼 분할 패턴:**
  - 3-up 통계: `col-span-4` × 3
  - 메인 + 사이드: `col-span-8` + `col-span-4`
  - 일정 + 캘린더: `col-span-4` + `col-span-8`

---

## 4. Iconography

- **라이브러리:** Lucide (인라인 SVG)
- **공통 속성:** `fill="none"` · `stroke="currentColor"` · `stroke-width="2"` (디테일 강조 시 2.2~2.5) · `stroke-linecap="round" stroke-linejoin="round"`
- **사이즈:**
  - 14×14 — 인라인 컨트롤, activity item 내부
  - 16×16 — 카드 우상단 데코 아이콘
  - 18×18 — 사이드바 nav, 헤더 액션 버튼
  - 22×22 — FAB
- **컬러:** 카드 데코는 `faint` (`#64748B`), 인터랙티브는 `text-muted`/`text-ink`/semantic
- **예외:** `templates/common/nav_sidebar.html`의 사이드바 메뉴 아이콘 세트는 도메인 의미에 맞춰 선택돼 있으므로 mockup 아이콘으로 교체하지 않는다.

---

## 5. 컴포넌트 시각 명세

본 절은 `static/css/input.css` `@layer components`의 클래스를 의미 단위로 그룹화한 것이다. 정확한 픽셀 값은 `input.css`가 진실.

### 5.1 Sidebar

```css
.sidebar-link {
  @apply flex items-center text-sm font-medium;
  gap: 12px; padding: 10px 14px; border-radius: 8px;
  color: #94A3B8;  /* 다크 배경 위 비활성 톤 */
  transition: background .15s ease, color .15s ease;
}
.sidebar-link:hover, .sidebar-link.is-active { background: #1E293B; color: #fff; }
.sidebar-link .dot { width: 3px; height: 18px; border-radius: 2px; background: transparent; margin-right: -8px; }
.sidebar-link.is-active .dot { background: #fff; }
```

- 로고 영역: `px-6 py-6`, 하단 `border-b border-white/5`
- Nav padding: `px-4 py-6 space-y-1`
- active: 좌측 `3×18` 흰색 dot + 배경 `ink2`

### 5.2 Top Header

- 높이 `72px` 고정, `bg-surface border-b border-hair px-8`
- 좌측: eyebrow 브래드크럼 + H1 `text-2xl` (24px) / 700
- 우측: 32×32 둥근 아이콘 버튼들 + 좌측 디바이더 + 사용자 영역 (아바타 40×40 `bg-ink2`)

### 5.3 Card (Standard)

```html
<article class="bg-surface rounded-card shadow-card p-6">
  <div class="flex items-start justify-between">
    <div class="eyebrow">Section Label</div>
    <svg width="16" height="16">…</svg>
  </div>
  …
</article>
```

- 컨테이너: `bg-surface rounded-card shadow-card p-6`
- 상단: eyebrow 라벨 + 우측 16px 아이콘 (color: `faint`)
- hover: 클릭 가능한(`<a>`/`<button>`) 카드에만 자동 lift

### 5.4 Card (Dark Accent)

페이지 내 **단 하나** 사용. 핵심 KPI 강조용.

```html
<article class="bg-ink text-white rounded-card shadow-lift p-6 flex flex-col">
  <div class="eyebrow" style="color:#64748B">Estimated Revenue</div>
  <div class="text-4xl leading-none font-bold tnum mt-6">₩ 842,500</div>
  <div class="mt-auto pt-6">
    <div class="progress dark"><span style="width:76%"></span></div>
  </div>
</article>
```

- 배경 `bg-ink`, eyebrow는 `#64748B`로 가독성 확보
- 내부 progress 트랙은 `#1E293B` (`.progress.dark`), fill은 `#fff`

### 5.5 Stat Number

```html
<div class="flex items-baseline gap-3">
  <span class="text-4xl leading-none font-bold tnum">24</span>
  <span class="text-sm text-muted">Projects Closed</span>
</div>
```

### 5.6 Status Dot

```css
.status-dot { width: 6px; height: 6px; border-radius: 999px; display: inline-block; }
```

success/warning/info/danger 색을 직접 부여.

### 5.7 Progress Bar

```css
.progress { height: 4px; border-radius: 999px; background: #E2E8F0; overflow: hidden; }
.progress > span { display: block; height: 100%; background: #334155; border-radius: 999px; }
.progress.success > span { background: #10B981; }
.progress.info    > span { background: #6366F1; }
.progress.muted   > span { background: #64748B; }
.progress.dark    { background: #1E293B; }
.progress.dark > span { background: #FFFFFF; }
```

### 5.8 Avatar · Avatar Stack

- 표준: 44×44 (`w-11 h-11`) gradient
- 헤더 사용자: 40×40 (`w-10 h-10`, `bg-ink2`)
- Stack(`.av-stack`): 28×28 원, 흰 2px 보더, `-6px` overlap. 담당자별 gradient 6종(`.av-1`~`.av-6`)을 forloop 인덱스로 부여.

### 5.9 Chip · Pill · Badge · Tag · Meta-pill

`input.css`에 모두 정의됨. 의미 구분:

| 클래스 | 용도 | 시각 |
|---|---|---|
| `.chip` | 카테고리 토글 (검색·필터) | `line` 배경 + `ink3` 텍스트, active 시 `ink3` 배경 + 흰색 |
| `.col-pill` | 칸반 컬럼 헤더 내 상태 카운트 | `searching/screening/closed` variant — 컨테이너보다 진한 색 |
| `.cat-chip` | 카테고리 칩 (Reference 페이지) | 보더 transparent, hover시 line 배경, active 시 ink3 배경 + 흰색 |
| `.badge` | 프로젝트/응용 상태 뱃지 | UPPERCASE, dot prefix, variant: `sourcing/screening/closed-success/urgent` + 회사 size variant (`enterprise/midcap/sme/foreign/startup`) |
| `.meta-pill` | 프로젝트/후보자 헤더의 메타정보 (연봉·수수료·마감) | `line` 배경 + `ink3` 텍스트, variant `success/danger` |
| `.tag` | skill / keyword chip | `line` 배경 + `muted` 텍스트, radius 6px |
| `.pill` | 작은 semantic 배지 (tier/listed/size/cert-level) | 10px font, 다양한 색상 variant — Reference 페이지 전용 |
| `.strength-tag` | 대학 강점 분야 표시 | 10px, line 배경 |

### 5.10 Calendar

```css
.cal-day {
  aspect-ratio: 1/1;
  display: flex; flex-direction: column;
  padding: 12px 14px;
  border: 2px solid #EEF2F7;  /* hair보다 한 단계 연함 */
  background: #FFFFFF;
  transition: background .15s ease;
}
.cal-day:hover { background: #F8FAFC; }
.cal-day > .tnum { font-size: 14px; font-weight: 600; color: #0F172A; line-height: 1; }
.cal-day.muted > .tnum { color: #CBD5E1; font-weight: 500; }
.cal-day.today > .tnum {
  display: inline-flex; align-items: center; justify-content: center;
  width: 26px; height: 26px;
  background: #0F172A; color: #fff;
  border-radius: 999px; font-size: 12px;
  margin: -5px -6px;
}
.cal-event {
  margin-top: 8px; padding: 4px 10px;
  font-size: 10px; border-radius: 999px;
  background: #F1F5F9; color: #334155; font-weight: 600;
}
.cal-day.today .cal-event { background: #0F172A; color: #fff; }

/* 주말 컬러 */
.cal-day:nth-child(7n+1):not(.today) > .tnum { color: #DC2626; }  /* 일요일 red */
.cal-day:nth-child(7n):not(.today)   > .tnum { color: #2563EB; }  /* 토요일 blue */

/* 내부 보더만 — 4면 외곽은 0 */
.cal-day:nth-child(-n+7)     { border-top: 0; }
.cal-day:nth-child(7n+1)     { border-left: 0; }
.cal-day:nth-child(7n)       { border-right: 0; }
.cal-day:nth-last-child(-n+7){ border-bottom: 0; }
```

- 카드는 `overflow-hidden`로 모서리 클리핑
- today: 셀 전체가 아닌 **숫자만** ink 원형 칩 (26×26)
- today의 이벤트 pill만 ink 반전

### 5.11 Stage Progress (Application 카드)

7개 추천업무단계(발굴→연락→이력서→사전 미팅→추천→면접→입사) 위에 시각화:

```css
.stage-progress { display: flex; gap: 0; margin-top: 8px; position: relative; }
.stage-progress::before {
  content: ''; position: absolute;
  top: 14px; left: 27px; right: 27px;
  height: 2px; background: #E2E8F0;
}
.stage-step { display: flex; flex-direction: column; align-items: center; gap: 6px; min-width: 54px; color: #64748B; }
.stage-step .dot {
  width: 28px; height: 28px; border-radius: 999px;
  background: #F1F5F9; border: 2px solid #E2E8F0;
  color: #64748B;
}
.stage-step.passed .dot { background: #10B981; border-color: #10B981; color: #fff; }
.stage-step.current .dot {
  background: #0F172A; border-color: #0F172A; color: #fff;
  box-shadow: 0 0 0 4px rgba(15,23,42,0.12);
}
.stage-step.passed, .stage-step.current { color: #0F172A; }
```

`.application-stage-legend` + `.application-progress-row`는 grid template으로 (라벨 column · 트랙 column · 현재 단계 column · 액션 column) 정렬. 900px 이하에서 legend 숨김, 480px 이하에서 2행 grid.

### 5.12 Kanban Column (col-container / col-pill)

```css
.col-container { border-radius: 14px; padding: 14px; }
.col-container-searching { background: #FDF2F8; }   /* pink 50 */
.col-container-screening { background: #EFF6FF; }   /* blue 50 */
.col-container-closed    { background: #F0FDF4; }   /* green 50 */

.col-pill { @apply inline-flex items-center text-xs font-semibold; padding: 3px 10px; border-radius: 6px; }
.col-pill-searching { background: #FCE7F3; color: #BE185D; }
.col-pill-screening { background: #DBEAFE; color: #1E40AF; }
.col-pill-closed    { background: #D1FAE5; color: #047857; }
```

Django 템플릿이 `col-pill-{{ column_key }}` / `col-container-{{ column_key }}`로 만들기 때문에 `tailwind.config.safelist`에 등록되어 있다.

### 5.13 Workspace Modal (`.workspace-modal.*`)

`assets/ui-sample/application-workspace-modal.html`과 `input.css`의 `.workspace-modal` 네임스페이스가 진실. 핵심 토큰:

- 모달 그림자: `.shadow-modal` = `0 30px 80px -30px rgba(15,23,42,0.65)`
- 모달 내부 독립 카드 보더 반경: 8px (전역 `rounded-card` 16px과 다름). 반복 항목을 습관적으로 박스로 감싸는 용도가 아니다.
- eyebrow: 11px / weight 900 / letter-spacing .14em / color faint
- badge: 11px / weight 900 / radius 6px / variants `muted` / `good`
- icon-btn: 36×36 / radius 8px / hover `bg-line + text-ink`
- 단계 tabs (`.workspace-stage-tab`): 36px 높이, 12px font, 보더 `#E2E8F0`, active 시 `ink3` 배경
- 필드 (`.field`): 40px 높이, radius 8px, focus 시 `ink3` 보더 + 3px ring
- 버튼 (`.btn` / `.btn-primary` / `.btn-ghost` / `.btn-danger`): 40px 높이, 13px / weight 800
- 사전 미팅 레이아웃: 1024px↑에서 우측 300px 컬럼 + 1px 디바이더
- 모바일 760px 이하 처리: header/footer/body padding 20px, 단계 tab 폭 좁힘, anywhere wrap
- send-icon: 38×38 보더 + tooltip (`::after`로 dark ink 풍선)

### 5.14 References Page (ref-tab / ref-table / filter-input / filter-select)

밑줄 3-탭 셀렉터 (`.ref-tab`): 16px padding, `faint` → hover `ink3` → active `ink` + bottom 2px line. 카운트 칩은 line 배경, active 시 ink 배경.

필터 입력 (`.filter-input`): 40px 높이, radius 10px, 좌측 38px padding(아이콘 자리), focus 시 `ink3` 보더 + 3px ring.

`.ref-table`: header 10px UPPERCASE faint, `border-bottom: 1px solid hair`, hover row `canvas` 배경. `primary` 컬럼 14px/700 `ink`. tnum 컬럼은 우측 정렬 + tabular-nums.

회사 로고 타일 (`.client-logo-tile` 56×56 / `.rlogo` 36×36): 8종 gradient variant (`-1`~`-8`).

### 5.15 추가 클래스 인덱스

`input.css`에 정의된 보조 클래스. 필요할 때 grep해서 확인:

`view-toggle` · `col-header` · `col-title` · `meta-tag` · `stat` · `pill` (variants 다수) · `rank` · `cat-divider` · `candidate-detail-drawer` · `candidate-search-loading-dot-delay-*` · `hide-scrollbar` · `flex-center`/`-start`/`-end`/`-between`

---

# 축 B — UI/UX 원칙

## 6. 화면 설계 6원칙

UI는 작동 여부가 아니라 **사용자가 화면의 의미와 다음 행동을 오해 없이 이해하는지**를 기준으로 판단한다.

1. **화면 영역은 사용자 업무 단위로 나눈다.** 사용자가 맡은 업무와 현재 판단 대상을 화면 분할만 보고도 알 수 있게 한다.
2. **선택지는 같은 층위끼리 묶는다.** 상위 선택과 하위 선택이 같은 무게로 섞여 보이지 않게 배치한다.
3. **선택지는 선택 전에 의미·결과를 예측할 수 있어야 한다.** 이름·설명·위치가 그 역할을 한다.
4. **버튼 문구·위치·강조는 누른 뒤 실제로 일어나는 일과 일치시킨다.** "다음", "+" 같은 모호한 라벨로 책임 회피하지 않는다.
5. **책임이 다른 행동은 다른 무게로 보이게 한다.** "조회 / 선택 / 저장 / 확정 / 제출"이 같은 무게면 사용자가 잘못 누를 수 있다.
6. **화면 흐름은 사용자가 판단·행동하는 순서**에 맞춘다 — 기획자의 설명 순서나 데이터 모델의 순서가 아니다.

---

## 7. 인터랙션 원칙

### 7.1 활성 버튼 = 보이는 결과

활성 버튼은 반드시 다음 중 하나로 끝난다:
- 화면 상태가 바뀐다
- 모달이나 다음 패널이 열린다
- 서버에 저장된다 (성공·실패 모두 화면에 반영)
- 파일/PDF가 열린다 (별도 탭 또는 다운로드)

"눌렀는데 아무 일도 없어 보이는 버튼"은 금지. 빈 응답으로 끝나는 저장도 마찬가지 — 성공이어도 사용자에게는 무반응으로 느껴진다.

### 7.2 미구현 = 비활성 표시

실제 기능이 아직 없는 버튼은 활성처럼 보이지 않게 한다. 비활성 상태 또는 "준비 중" 안내로 보여 사용자가 누를지 말지 판단할 수 있게 한다.

### 7.3 저장 응답 기준

| 상황 | 응답 |
|---|---|
| 작업공간 유지해야 하는 저장 | 작업공간 전체를 다시 보여준다 |
| 하위 모달만 닫혀야 하는 저장 | 하위 모달을 닫고 작업공간을 유지한다 |
| 후보자 행 상태가 바뀌는 저장 | 후보자 행도 함께 갱신한다 |
| 액션 상태가 바뀌는 저장 | 관련 액션 목록도 함께 갱신한다 |
| 저장 실패 | 사용자가 읽을 수 있는 오류 메시지를 같은 흐름 안에서 보여준다 |
| 외부 파일/PDF | 모달 안에 억지로 넣지 않고 별도 탭 또는 다운로드로 처리 |

### 7.4 모달 계층

- 하위 모달은 상위 작업공간을 통째로 밀어내지 않는다.
- 하위 모달을 닫으면 사용자가 원래 작업하던 위치로 돌아온다.
- 저장 후 닫혀야 하는 모달과 유지되어야 하는 작업공간을 명확히 구분한다.

### 7.5 프로젝트 메뉴 — 한 화면 두 영역

**모든 프로젝트 업무는 프로젝트 메뉴 안에서 끝난다.** 다른 화면으로 빠지지 않는다.

| 영역 | 내용 |
|---|---|
| **영역 1 — 후보자 검색·바구니·추천 선정** | 모달. 보이스 채팅 검색 → 바구니 → 트랙 진입(Application 생성)까지 한 화면 모달에서 끝낸다. |
| **영역 2 — 후보자별 진행 한눈에 보기** | 후보자 1명 = **한 줄 카드 = 이름 + 프로그레스 바 + 우측 세팅 아이콘**. 모든 카드가 동시에 한 화면. 세팅 아이콘 클릭 → 후보자 상세 모달. 모달 닫으면 카드 list로 돌아온다. |

후보자별로 따로 들어가서 처리하는 기존 페이지형 템플릿은 폐기.

`_Avoid_`: "후보자 추가"(=좁은 표현), "후보자 상세 페이지로 이동"(=메뉴 벗어남)

### 7.6 보이스 우선 검색

- 검색·조작 기본 인터페이스는 **음성 또는 텍스트 자연어 입력**.
- 시스템이 의도·엔티티를 파악해 검색·이동·기록·후보자/프로젝트 조작으로 연결한다.
- **전통적인 필터 UI를 새로 추가하기 전에 voice-first 방향과 충돌하지 않는지 확인.**
- STT는 OpenAI Whisper, 메인 LLM은 Codex CLI 우선 (`common/llm.py`).
- 관련 위치: `projects/views_voice.py`, `projects/services/voice/`, `candidates/static/candidates/voice-input.js`

### 7.7 HTMX 컨벤션

- **페이지 네비게이션:** `hx-get` + `hx-target="main"` + `hx-push-url="true"`
- **Form 제출:** `hx-post` + specific target

### 7.8 Tailwind 사용 규칙

**운영 템플릿** (`templates/`, 각 앱의 `templates/`)에서:

선호:
- Tailwind 유틸리티 클래스로 표현
- `text-ink`/`text-muted`/`text-faint`/`bg-canvas`/`bg-surface`/`bg-line`/`border-hair`/`border-line` 등 디자인 토큰
- `input.css`에 이미 정의된 공통 컴포넌트 클래스(`.eyebrow`/`.chip`/`.badge`/`.tag`/`.stage-step` 등)

금지:
- 페이지 단위 `<style>` 블록
- 임의 커스텀 CSS 클래스 (운영 템플릿 안에서 새로 만드는 것)
- 디자인 토큰을 우회한 hex 색상 하드코딩

**예외 — `assets/ui-sample/*.html` mockup**: 독립 실행 가능해야 하므로 인라인 `tailwind.config` + `<style>` 블록을 허용. 단 토큰 값은 본 스킬 §1과 동기화되어야 하며 mismatch 시 코드가 승.

**예외 — Tailwind config로 표현하기 어려운 전역 CSS feature**: `base.html` 안의 `#page-loading-bar` 같은 전역 컨트롤은 인라인 hex 허용. 단 토큰 값 (`#334155` 등)을 그대로 사용.

---

## 8. 라벨·문구 톤

UX 용어는 **사람 중심**. 버튼 라벨·상태 문구는 처음 보는 사용자도 의도를 즉시 이해할 수 있어야 한다.

금지:
- 영어 직역: "드롭", "에스컬레이션"
- 업계 은어: "내부 양식 변환"
- 의미 불명: "+", "액션"
- 코드 어감 단어: fraud / dropped / timeout / orphan / stale / artifact

좋은 예: "탈락 처리", "할 일 추가", "이력서 정리하기", "사장님께 보고"

알림 톤: **일상 한국어로 풀어서.** *"챙겨봐라"* 신호처럼 들리게.

모든 버튼은 `title` 속성에 구체 설명을 넣어 hover 시 맥락을 준다.

### 8.1 템플릿 항목 추가 기준

템플릿에 새 배지·칩·라벨·상태 항목을 추가할 때는 사용자가 그 항목만 보고 업무 판단을 할 수 있어야 한다.

코드 내부 상태명, 개발자 관점의 검증명, 의미가 애매한 영어 라벨은 운영 템플릿에 노출하지 않는다.

사용자에게 필요하지만 내부 상태명이 애매하면 사람이 이해하는 한국어 업무 의미로 바꾸고, 필요하지 않으면 표시하지 않는다.

### 8.2 Workspace 박스와 버튼 배치 기준

Workspace/modal 안에서 반복 항목은 기본적으로 박스로 감싸지 않는다. 특히 `border border-hair bg-white px-4 py-4` 같은 항목 전체 박스는 정보 경계가 꼭 필요할 때만 쓴다. 기본 구분은 간격, 구분선, 라벨, 타이포 굵기, 배경 tint 없는 행 구조로 만든다.

박스 안에 박스 구조는 사용자가 정보 위계를 다시 해석하게 만든다. 내부 박스는 경고, 독립 선택 카드, 첨부 파일 카드, 외부 제출 미리보기, 접힌 상세 패널처럼 하나의 독립 의미나 독립 행동 단위일 때만 쓴다.

버튼은 가능하면 해당 섹션의 바깥 액션 영역에 둔다. 저장, 취소, 확정, 위험 액션은 입력/정보 박스 안에 가두지 말고 섹션 하단이나 modal footer/danger zone에 배치한다. 버튼을 박스 안에 넣는 경우는 그 박스 자체가 하나의 독립 form 또는 독립 실행 단위일 때로 제한한다.

---

## 9. UX 검수 기준 (UI 작업 완료 판정)

다음 질문에 화면만 보고 답할 수 없으면 UI 작업은 완료로 보지 않는다.

- "이 버튼을 누르면 무엇이 일어나는가?"를 설명 없이 알 수 있는가?
- "이 선택지는 다른 선택지와 같은 종류인가, 상위/하위인가?"가 배치에서 드러나는가?
- "지금 해야 할 일"과 "나중에 볼 정보"가 화면에서 구분되는가?
- "이 배지·칩·라벨이 사용자의 업무 판단에 필요한가?"를 설명할 수 있는가?
- 모바일 폭에서 닫기·스크롤·하단 액션이 막히지 않는가?

프론트엔드 UI/CSS/탭/모달/폼을 수정한 후에는 **실제 브라우저에서 확인**한다. 코드와 테스트만 보고 완료로 판단하지 않는다. 사용자가 스크린샷으로 UI 문제를 지적한 경우에는 같은 경로와 비슷한 화면 상태를 브라우저에서 재현한 뒤 고친다.

개발 서버와 Tailwind 실행은 사용자의 `go` 명령이 관리한다. UI·디자인·프론트엔드 수정 후에도 Tailwind build/watch나 `manage.py runserver`를 자발적으로 새로 실행하지 않는다. 서버가 이미 떠 있으면 `http://localhost:8000/...` 기준으로 브라우저 검증과 보고를 진행한다.

원격 작업공간의 화면 링크는 사용자의 SSH 터널 기준 `http://localhost:8000/...` 주소를 우선한다. 목업도 가능하면 기존 Django 경로에서 보이게 하고, 임의 정적 서버를 띄우려면 먼저 이유를 설명한다.

배포에서만 UI가 깨지면 개발/배포 빌드 경로 차이를 먼저 의심한다.
Docker 안에서 별도 Tailwind 빌드 같은 이중 빌드 파이프라인을 만들지 않는다. 인라인 스타일이나 하드코딩으로 증상만 덮지 말고 원인을 해결한다.

---

# 통합 — 두 축 함께 적용

## 10. 화면 단위 통합 패턴

화면을 만들 때 시각(축 A) + UX(축 B)가 동시에 작동하는 케이스. 각 항목은 **[시각]** 블록과 **[UX]** 블록을 함께 본다.

### 10.1 프로젝트 메뉴 (한 화면 두 영역)

**[UX]** §7.5 — 영역 1(검색·바구니·트랙 진입 모달) + 영역 2(후보자별 한 줄 카드 list). 후보자별로 다른 페이지로 빠지지 않음. 영역 1에서 검색은 §7.6 보이스 우선.

**[시각]**
- 영역 2 후보자 카드: `bg-surface rounded-card shadow-card p-6`, 한 줄 = 이름(`text-sm font-semibold`) + `.stage-progress` (6 단계, 발굴 제외) + 우측 32×32 round icon button
- 카드 자체는 hover lift (a/button 형태)
- 영역 1 모달: `.shadow-modal` + workspace 모달 네임스페이스 사용 가능, 또는 별도 검색 모달 (보이스 입력 바는 `shadow-searchbar`)

### 10.2 후보자 작업공간 (Workspace Modal)

**[UX]**
- 한 후보자 1명을 연락→사전 미팅→추천→면접→Closing까지 진행하는 화면.
- §7.1 활성 버튼 = 보이는 결과, §7.2 미구현 = 비활성, §7.3 저장 응답 기준, §7.4 모달 계층 모두 적용.
- 단계 표시: 현재 단계만 기본으로 열림. 다른 단계도 펼침으로 확인 가능. 현재/대기/드롭/입사 확정이 시각적으로 구분.
- 진입과 닫기: X, 하단 닫기, 배경 클릭, ESC 모두 작동. 내부 클릭은 닫힘으로 처리 X.

**[시각]**
- §5.13 `.workspace-modal.*` 네임스페이스 사용
- 모달: `.shadow-modal`, body padding-bottom 32px
- 단계 tabs: `.workspace-stage-tab`, active 시 `ink3` 배경 + 흰색
- 독립 내부 카드: `border-radius: 8px` (전역 16px과 다름). 반복 항목 전체를 다시 박스로 치지 않고, form/alert/선택 카드처럼 독립 의미가 있을 때만 사용.
- 사전 미팅 레이아웃: 1024px↑에서 우측 300px 컬럼 + 1px 디바이더, 모바일 단일 컬럼
- 버튼: `.btn-primary` (ink3) / `.btn-ghost` (line + muted) / `.btn-danger` (rose 보더 + rose 텍스트)
- send-icon tooltip: dark ink 배경 풍선

### 10.3 검색 영역 (보이스 + 결과)

**[UX]**
- 음성 또는 텍스트 자연어 입력이 1차. 전통 필터 UI 추가 금지 (§7.6).
- 검색 결과 → 바구니 → 트랙 진입까지 한 모달 안에서 끝난다 (§7.5 영역 1).

**[시각]**
- 검색 입력 바: `shadow-searchbar`, focus 시 `ink3` 보더 + ring
- 결과 row hover: `canvas` 배경
- 카테고리 칩: `.cat-chip` (보더 transparent → hover line → active ink3)
- 결과 컬럼 분리는 §3.2 grid 사용

### 10.4 알림·상태 표시

**[UX]**
- §7.1 보이는 결과 원칙 + §8 사람 중심 라벨 톤
- 채널: 웹 시스템 알림함 = 모든 알림. 텔레그램 = 시간 민감·결정 필요만.
- 코드 어감 단어 금지 — 일상 한국어로.

**[시각]**
- 상태 dot: §5.6 (success/warning/info/danger 직접 color)
- 상태 뱃지: §5.9 `.badge.sourcing` / `.badge.urgent` 등 의미별 variant
- 본문 안의 한국어 라벨은 `.eyebrow-ko` 우선 (`.eyebrow` UPPERCASE는 한글에 의미 없음)

### 10.5 칸반 / Application Track

**[UX]**
- 영역 2 카드(§7.5)의 list 형태. 카드 하나 = Application 하나 = `.stage-progress` 시각화(§5.11).
- 7개 단계 중 영역 2에 그릴 것은 발굴 제외 6개(연락→이력서→사전 미팅→추천→면접→입사).
- 단계는 모두 건너뛰기 가능. `passed` / `current` / 미진입의 시각 구분이 §5.11에 정의.

**[시각]**
- 칼럼(`.col-container-*`) 배경 색은 상태별 50 톤, 카드는 흰색으로 대비
- 컬럼 헤더 pill (`.col-pill-*`) 색은 컨테이너보다 한 단계 진함

### 10.6 References 페이지

**[UX]**
- 3-탭 (대학 / 기업 / 자격증) 가로 셀렉터. 한 탭당 표 1개.
- 표는 정렬 가능한 컬럼 + tnum 우측 정렬 + hover row 강조.

**[시각]**
- §5.14 `.ref-tab` / `.ref-table` / `.filter-input` / `.filter-select`
- 회사 로고 타일: `.client-logo-tile` (56×56, 8 gradient) — 카드 list / `.rlogo` (36×36) — 표 안 row 로고

### 10.7 Card hover

**[UX]**
- hover lift는 **클릭 가능한 카드에만** — 정적 카드를 들썩이면 사용자가 클릭을 기대했다 실망한다.
- 클릭 가능 여부는 `<a>` / `<button>` 마크업으로 표시 (시각 + 시맨틱 동시 만족).

**[시각]**
- §1.5 `transform` 금지 / `position: relative + top` 기반 lift
- 다크 카드는 hover 시 더 큰 그림자 (§1.5 마지막 블록)

---

## 11. Do / Don't (양 축 통합)

### Do
- 카드 padding은 항상 `p-6`
- 그리드 gap은 항상 `gap-6`
- 숫자 표시는 항상 `.tnum`
- 모든 카드에 `rounded-card shadow-card`
- 섹션 라벨은 `eyebrow` / 한글 라벨은 `eyebrow-ko`
- hover lift는 클릭 가능한 카드에만 자동 적용
- 컴포넌트는 `input.css`의 기존 클래스를 먼저 찾아 재사용
- 한 화면 만들 때 시각(§A)과 UX(§B)를 동시에 확인
- Workspace 반복 항목은 박스 대신 간격·구분선·타이포 계층으로 구분
- 저장/취소/확정/위험 버튼은 기본적으로 섹션 바깥 액션 영역이나 modal footer/danger zone에 배치

### Don't
- 카드에 `rounded-lg`/`rounded-xl` 직접 사용 금지 → `rounded-card`
- 임의의 그림자 정의 금지 → `shadow-card`/`shadow-lift`/`shadow-fab`/`shadow-searchbar`
- 임의 컬러 hex 금지 → 토큰 사용 (Tailwind 클래스 또는 토큰값 인용)
- 다크 카드 2개 이상 금지 (강조 분산)
- `Inter`/`Roboto`/`Noto Sans` 등 다른 폰트 사용 금지 → Pretendard 고정
- 보라/파랑 그라디언트 CTA 금지 → ink 단색
- 카드·컨테이너 좌측 컬러 스트라이프 금지 — `border-l-{N} border-l-{color}` 또는 좌측 box-shadow로 컬러 세로 막대 만들지 않음. 상태·긴급도 표시는 뱃지·pill·배경 tint·아이콘으로 대체. 타임라인 vertical rail도 border-l 금지
- 인라인 arbitrary 폰트 크기 금지 — `text-[10px]` 같은 임의값 쓰지 않고 Tailwind 기본 스케일 사용
- 운영 템플릿에 페이지 단위 `<style>` 블록 추가 금지 (mockup만 예외, §7.8)
- 디자인 토큰을 우회한 인라인 hex 금지 (`base.html` 같은 전역 컨트롤만 예외)
- 활성 버튼이 무반응 금지 — 미구현이면 비활성 표시 (§7.1, §7.2)
- 하위 모달이 상위 작업공간을 통째로 덮음 금지 (§7.4)
- 박스 안에 박스 반복 금지 — 항목 전체에 `border border-hair bg-white px-4 py-4`를 습관적으로 붙이지 않음 (§8.2)
- 버튼을 내용 박스 안에 숨기기 금지 — 독립 form/독립 실행 단위일 때만 예외 (§8.2)
- 후보자 처리를 별도 페이지로 빼서 프로젝트 메뉴 벗어남 금지 (§7.5)
- 코드 어감 라벨(드롭/timeout/orphan/fraud/stale) 사용 금지 (§8)
- 코드 내부 상태명이나 개발자 관점 검증명을 운영 템플릿 배지·칩·라벨로 노출 금지 (§8.1)
- 전통적 필터 UI를 보이스 검색 대신 추가하기 전에 §7.6 확인

---

## 12. Tailwind 설정 참고

코드 원천 그대로의 사본 (`tailwind.config.js`):

```js
{
  theme: {
    extend: {
      fontFamily: {
        sans: ['"Pretendard Variable"', 'Pretendard', '-apple-system',
               'BlinkMacSystemFont', 'system-ui', 'sans-serif'],
      },
      colors: {
        canvas: '#F8FAFC', surface: '#FFFFFF',
        ink:   '#0F172A', ink2: '#1E293B', ink3: '#334155',
        muted: '#475569', faint: '#64748B',
        hair:  '#d8dee6', line: '#F1F5F9',
        success: '#10B981', warning: '#F59E0B',
        info:    '#6366F1', danger:  '#EF4444',
      },
      boxShadow: {
        card:      '0 2px 4px -1px rgba(15,23,42,0.08), 0 4px 12px -2px rgba(15,23,42,0.10)',
        lift:      '0 4px 6px -1px rgba(15,23,42,0.08), 0 2px 4px -2px rgba(15,23,42,0.04)',
        fab:       '0 10px 15px -3px rgba(15,23,42,0.15), 0 4px 6px -2px rgba(15,23,42,0.08)',
        searchbar: '0 10px 40px -10px rgba(15,23,42,0.18), 0 4px 12px -4px rgba(15,23,42,0.08)',
      },
      borderRadius: { card: '16px' },
      keyframes: { 'pulse-hint': { '0%, 100%': { opacity: '1' }, '50%': { opacity: '0.2' } } },
      animation:  { 'pulse-hint': 'pulse-hint 1.5s cubic-bezier(0.4,0,0.6,1) infinite' },
    },
  },
}
```

---

## 13. 토큰 출처와 갱신 규칙

**원천**: `tailwind.config.js` + `static/css/input.css`. 본 스킬의 §1~§5는 이 두 파일의 사람이 읽기 좋은 사본이다.

**갱신 순서**: 코드 수정 → 본 스킬 §1~§5 동기화 → (선택) `assets/ui-sample/*.html` mockup의 인라인 tailwind config 동기화. 운영 템플릿은 코드 토큰을 자동으로 받는다(Tailwind class).

**불일치 발견 시**: 코드가 승. 본 스킬을 코드 값으로 정정한다.

**디자인 / UX 룰을 다른 문서에 복제 금지**:
- `CONTEXT.md` 안의 도메인 어휘 옆에 UI 원칙을 함께 넣으려면, "UI 설계는 `exdigm-design` 스킬 참조" 한 줄만 두고 본문은 여기로.
- `CLAUDE.md`의 HTMX 패턴도 §7.7로 흡수됨. CLAUDE.md에서는 한 줄 ref만.
- `AGENTS.md` (`/home/chaconne/exdigm/AGENTS.md`)의 화면 흐름 문서는 본 스킬 §10에 흡수.
- Claude MEMORY · Codex `~/.codex/memories/` 안의 voice-first / Tailwind 원칙 / 사람 중심 라벨 등 UI 룰은 본 스킬을 ref만 한다. 본문 복제 금지.
- Codex의 단일 기준 위치는 `/home/chaconne/.codex/skills/exdigm-design/SKILL.md`다. 디자인·UI·UX 관련 사용자 지침이 추가되면 이 파일을 갱신하고, 다른 Codex 메모리·프로젝트 지침에는 참조만 남긴다.

---

## 14. 변경 이력

- **2026-06-13**: Workspace/modal 박스 중첩 금지와 버튼 배치 기준 추가. 반복 항목은 기본적으로 박스로 감싸지 않고, 저장·취소·확정·위험 버튼은 섹션 바깥 액션 영역이나 footer/danger zone에 둔다.
- **2026-05-21**: 템플릿 항목 추가 기준 추가. 배지·칩·라벨은 사용자 업무 판단에 필요한 정보만 노출하고, 코드 내부 상태명이나 개발자 관점 검증명을 그대로 표시하지 않도록 명시.
- **2026-05-21**: Claude Code의 `exdigm-design`을 Codex 스킬로 설치. Codex에서 디자인·UI·UX 지침을 추가할 때 본 스킬을 단일 기준으로 갱신하도록 명시. UI 검증 환경(`go` 명령, Tailwind/watch, SSH 터널 기준 localhost URL)을 §9에 흡수. Codex 메모리와 프로젝트 `AGENTS.md`에 남은 디자인 중간 문서를 제거.
- **2026-05-20**: 두 축(시각 + UI/UX) 구조로 재작성. 디자인 토큰 값을 코드 원천(`tailwind.config.js` + `static/css/input.css`)에 맞춰 정정 — hair `#E2E8F0`→`#d8dee6`, muted `#64748B`→`#475569`, faint `#94A3B8`→`#64748B`. `shadow-card` 코드값으로 정정. `shadow-searchbar` 추가. UX 원칙 흡수: 화면 설계 6원칙 + 검수 기준 / 활성 버튼·미구현·저장 응답·모달 계층 / 프로젝트 메뉴 두 영역 / HTMX 패턴 / 보이스 우선 검색 / 사람 중심 라벨 톤. §10에 화면 단위 통합 패턴 신설.
- **2026-04-30**: 스킬로 분리. 종전 `docs/design-system.md`를 본 스킬 본문으로 흡수. 사본 제거.
