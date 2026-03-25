# Сравнительный анализ пяти планов для skill адаптивного планирования

## Общие сведения

Все пять планов решают одну и ту же задачу: **создать Pi skill, который помогает агенту выбирать подходящую глубину планирования** — от мгновенного выполнения до масштабной декомпозиции. Планы лежат в пяти папках:

| # | Папка | Формат | Инструмент/модель | Язык |
|---|-------|--------|-------------------|------|
| 1 | `omp-5.4` | Свободный PLAN.md | OMP (Sonnet 4) | EN |
| 2 | `omp-opus` | Свободный PLAN.md | OMP (Opus) | EN |
| 3 | `pi-5.4-pro-high` | ExecPlan | Pi + Gemini 2.5 Pro | RU |
| 4 | `pi-execplan-5.4` | ExecPlan | Pi + Sonnet 4 (ExecPlan skill) | RU/EN mix |
| 5 | `pi-execplan-opus` | ExecPlan | Pi + Opus (ExecPlan skill) | EN |

---

## Что совпадает во всех пяти планах

### 1. Пять уровней планирования
Все планы единогласно выделяют **пять уровней** (tiers/modes) планирования:

| Уровень | omp-5.4 | omp-opus | pi-5.4-pro-high | pi-execplan-5.4 | pi-execplan-opus |
|---------|---------|----------|------------------|-----------------|------------------|
| 0 | Mode 0: Instant | Tier 0: Micro | P0 direct | quickstrike | quickstrike |
| 1 | Mode 1: Simple HITL | Tier 1: Simple | P1 quick-plan | guided | guided |
| 2 | Mode 2: Moderate | Tier 2: Moderate | P2 research-plan | research | research |
| 3 | Mode 3: Deep feature | Tier 3: Complex | P3 feature-plan | feature | feature |
| 4 | Mode 4: Mega-plan | Tier 4: Mega | P4 program-plan | mega | mega |

### 2. Реализация как skill, а не extension
Все планы выбирают **skill-level решение** (markdown-инструкции без hooks и extension API). Обоснование одинаковое: для v1 достаточно инструкций + существующих инструментов (read, write, bash, subagent), а extension можно добавить позже, если инструкций окажется мало.

### 3. Human-in-the-loop (HITL)
Во всех планах:
- **Уровень 0**: HITL **нет** — агент действует сразу
- **Уровни 1–4**: HITL **обязателен** — план показывается пользователю до реализации

### 4. Self-review обязателен для всех уровней
Все планы требуют self-review даже на самом лёгком уровне. Разница только в глубине:
- Уровень 0: post-execution review
- Уровни 1–4: review плана + review реализации

### 5. Один основной файл плана
Все планы сходятся: для уровней 1–3 должен быть **один главный файл плана**. Дополнительные файлы допустимы только для уровня 4 (mega/program) и для research evidence на уровне 3.

### 6. Опциональные helper-агенты (subagents)
Все планы предлагают использовать дополнительных агентов (reviewer, researcher, oracle, council), но делают это **опциональным**, чтобы не замедлять простые задачи.

### 7. Blind spots как центральная концепция
Все планы акцентируют необходимость проверки "слепых зон" (миграции, обратная совместимость, rollback, тесты, безопасность, производительность) до начала реализации.

### 8. Validation / backpressure
Все планы требуют определить критерии приёмки и валидацию **до** начала реализации. Backpressure (обязательные точки остановки при недостатке контекста) упоминается во всех, хотя в разной степени детализации.

---

## Ключевые различия

### 1. Формат и структура самого плана

**OMP-планы (omp-5.4, omp-opus)** — это свободный markdown без фиксированной структуры ExecPlan. Они описывают *проект skill'а* как design document, но сами не являются живыми планами.

**Pi ExecPlan-ы (pi-5.4-pro-high, pi-execplan-5.4, pi-execplan-opus)** — используют формализованную структуру ExecPlan с обязательными секциями: Progress, Action Log, Surprises & Discoveries, Decision Log, Outcomes & Retrospective, Validation and Acceptance, Idempotence and Recovery. Они сами являются примером того, что хотят создать.

### 2. Глубина проработки mode-selection rubric

| Аспект | omp-5.4 | omp-opus | pi-5.4-pro-high | pi-execplan-5.4 | pi-execplan-opus |
|--------|---------|----------|------------------|-----------------|------------------|
| Оси оценки для выбора режима | 8 осей (ambiguity, novelty, blast radius, reversibility, research need, user input need, size, dependency graph) | Таблица с 6 колонками (HITL, plan file, oracle, questions, research) | Сигналы: размер, файлы, обратимость, новизна, зависимости, согласование | Аналогично pi-5.4, но менее детально | 6 осей (scope, unknowns, risk, integration surface, user alignment, validation complexity) + escalation/de-escalation + anti-patterns |
| Конкретность порогов | Общие ("low across all axes → Mode 0") | Числовые лимиты (≤5 tool calls, ≤3 questions) | Описательные | Описательные | Числовые + описательные |

**omp-opus** — самый конкретный в числовых лимитах (≤5 tool calls для Tier 0, ≤3 вопросов для Tier 2, ≤5 для Tier 3).
**pi-execplan-opus** — самый системный: 6 именованных осей + правила эскалации/деэскалации + антипаттерны.

### 3. Архитектура файлов skill'а

| Plan | Архитектура |
|------|-------------|
| **omp-5.4** | Markdown-first + structured config (YAML/JSON). Несколько файлов: SKILL.md, templates/, checklists/, config/modes.yaml, prompts/, examples/. **Самая сложная структура** — 15+ файлов |
| **omp-opus** | **Единственный SKILL.md**. Всё в одном файле. Никаких references, templates, config. Максимальная простота |
| **pi-5.4-pro-high** | SKILL.md + references/ (7 файлов) + assets/examples/. Прогрессивное раскрытие |
| **pi-execplan-5.4** | SKILL.md + references/ (5 файлов) + assets/templates/ (2 файла). Аналогично pi-5.4-pro-high |
| **pi-execplan-opus** | SKILL.md + references/ (5 файлов) + assets/templates/ (2 файла). Идентичная структура с pi-execplan-5.4, но более подробное описание содержимого каждого файла |

**Ключевое расхождение**: omp-opus утверждает, что **один файл** достаточен. omp-5.4 предлагает **15+ файлов**. Pi-планы выбирают золотую середину: ~8–10 файлов с progressive disclosure.

### 4. Платформенная привязка

- **omp-5.4**: платформо-агностичен. Рассматривает 3 варианта пакетирования (markdown, markdown+config, code-centric). Не привязан к OMP или Pi.
- **omp-opus**: **жёстко привязан к OMP**. Использует OMP-специфичные концепции: `exit_plan_mode`, `local://PLAN.md`, `task { agent: "oracle" }`, `plan` model role. Не переносим на Pi.
- **pi-5.4-pro-high**: привязан к Pi, но мягко. Упоминает `subagent`, `interview`, `execplan/` как конвенции.
- **pi-execplan-5.4**: привязан к Pi. Ссылается на конкретные пути Pi skills, валидатор.
- **pi-execplan-opus**: привязан к Pi. Наиболее явно описывает Pi-специфичные инструменты (subagent, interview) и даёт конкретные вызовы.

### 5. Live plan format

| Plan | Формат живого плана |
|------|---------------------|
| **omp-5.4** | 15 секций: Header → Request summary → Mode → Outcome/acceptance → Context → Assumptions → Risks/blind spots → Research → Approach → Plan of work → Validation → Progress → Surprises → Decisions → Handoff notes |
| **omp-opus** | Свой compact-формат: Goal, Constraints, Approach, Tasks (dependency-annotated), Edge Cases, Validation, Action Log, Open Questions |
| **pi-5.4-pro-high** | ExecPlan-совместимый + Action Log + RPD |
| **pi-execplan-5.4** | Ссылается на ExecPlan + additions: action log, RPD, handoff note |
| **pi-execplan-opus** | **Самый детальный**: Purpose, RPD, Assumptions, Blind Spots Addressed, Approach, Validation & Acceptance, Action Log, Decision Log, Surprises, Self-Review, Next Steps, Handoff Note + lifecycle statuses (planning → awaiting-review → approved → in-progress → done) |

### 6. Meta-plan / RPD

- **omp-5.4**: упоминает meta-plan как опциональный вариант (когда неясен сам подход, а не реализация).
- **omp-opus**: не упоминает meta-plan или RPD.
- **pi-5.4-pro-high**: вводит **meta overlay** (накладывается поверх P2–P4 при неопределённости подхода) и **RPD** (Rapid Problem Distillation) как обязательный элемент.
- **pi-execplan-5.4**: упоминает RPD, но менее детально.
- **pi-execplan-opus**: вводит RPD как **первый шаг каждого уровня**, но трактует его как "rapid problem definition" (не "distillation"). Нет отдельного meta-plan — RPD и research tier покрывают эту потребность.

### 7. Context reset / restart-from-plan

| Plan | Описание context reset |
|------|------------------------|
| **omp-5.4** | "Handoff notes for fresh-session execution" — упоминается, но без протокола |
| **omp-opus** | Явно **исключает** из scope: "OMP's TTSR mechanism handles context overflow automatically" |
| **pi-5.4-pro-high** | **Подробный протокол**: обновить live plan → записать следующий шаг → передать через subagent или сообщить пользователю. Описан как "нормальный путь, не авария" |
| **pi-execplan-5.4** | Упоминает file-based handoff + fresh subagent, но менее детально |
| **pi-execplan-opus** | **Полный протокол**: update plan → write handoff note → spawn fresh subagent. Эвристический триггер: если агент забывает контекст, reasoning circular, или прочитано 15+ файлов |

### 8. Использование `interview` tool

- **omp-5.4, omp-opus, pi-5.4-pro-high**: не упоминают `interview` как инструмент для HITL.
- **pi-execplan-5.4**: упоминает `interview` кратко (для P3–P4 вопросов).
- **pi-execplan-opus**: **активно интегрирует** `interview` для structured HITL: показ плана с опциями approve/revise, пакетированные вопросы, targeted questions для research tier.

### 9. Примеры и validation scenarios

| Plan | Примеры |
|------|---------|
| **omp-5.4** | Нет конкретных примеров запросов; есть описание верификации по 8 пунктам |
| **omp-opus** | 5 конкретных prompt-примеров (rename → Tier 0, refactor config → Tier 1, pagination → Tier 2, OAuth → Tier 3, notifications → Tier 4) |
| **pi-5.4-pro-high** | 5 сценариев описаны концептуально, без конкретных prompt'ов |
| **pi-execplan-5.4** | 5 конкретных prompt-примеров с ожидаемым режимом |
| **pi-execplan-opus** | 5 **развёрнутых** примеров: prompt + tier + reasoning + step-by-step agent behavior + artifacts |

### 10. Naming (имена уровней)

| Plan | Имена |
|------|-------|
| omp-5.4 | Mode 0–4 (числовые) |
| omp-opus | Tier 0–4: Micro, Simple, Moderate, Complex, Mega |
| pi-5.4-pro-high | P0–P4: direct, quick-plan, research-plan, feature-plan, program-plan |
| pi-execplan-5.4 | quickstrike, guided, research, feature, mega |
| pi-execplan-opus | quickstrike, guided, research, feature, mega |

Pi ExecPlan-планы (5.4 и opus) сошлись на одних и тех же именах (`quickstrike`, `guided`, `research`, `feature`, `mega`), что говорит о стабильности этого набора.

---

## Уникальные элементы каждого плана

### omp-5.4 (Sonnet 4, OMP)
- **Три варианта пакетирования** с подробным сравнением (pure markdown vs markdown+config vs code-centric). Единственный план, который формально анализирует trade-offs формата.
- **Structured config (YAML/JSON)** для mode policies, gating rules, helper-role triggers — не просто инструкции, а конфигурируемая система.
- Раздел **"Sources informing this plan"** со ссылкой на OpenAI community discussion.

### omp-opus (Opus, OMP)
- **Radical simplicity**: один файл SKILL.md, без references, без templates, без config. "All conventions are self-contained."
- **OMP-native recipes**: конкретный JSON-код для вызова oracle, librarian, reviewer через `task {}` syntax.
- **Явная таблица quick reference** (Tier × Feature matrix) для быстрого выбора.
- Раздел **Resolved Open Questions** — показывает, какие решения были приняты и почему.

### pi-5.4-pro-high (Gemini 2.5 Pro, Pi)
- **Meta overlay** — уникальная концепция: когда главная неопределённость в самом подходе, а не в реализации, skill сначала исследует варианты решения.
- **RPD (Rapid Problem Distillation)** как обязательная мини-секция с полями: Goal, Constraints, Repo Facts, Unknowns, Proof, Chosen Mode.
- **Самый подробный раздел Validation and Acceptance** — каждый уровень P0–P4 имеет детальные acceptance criteria с описанием "что считается провалом".
- **Backpressure как явный mechanism** с конкретными правилами для каждого уровня.
- **Restart-from-plan** описан подробнее всех остальных: обновить все живые секции плана, явно записать Next Step, и только потом handoff.

### pi-execplan-5.4 (Sonnet 4, Pi ExecPlan)
- **Наименее детализированный** из трёх Pi-планов. Выглядит как "первый проход", который pi-execplan-opus затем улучшил.
- Упоминает **question-playbook** с числовыми лимитами по уровням (P0: 0, P1: 0, P2: до 3, P3: пакетированные, P4: стратегические + по milestone).

### pi-execplan-opus (Opus, Pi ExecPlan)
- **Явный анализ недостатков предыдущего плана** (pi-execplan-5.4): "mode descriptions are 1-2 sentences each, no escalation/de-escalation criteria, no examples of what self-review looks like, no handoff protocol."
- **Три названных subagent-стратегии**: single reviewer pass, parallel council, oracle query — каждая с конкретным описанием.
- **Interview tool** как ключевой инструмент для structured HITL.
- **Lifecycle statuses** для плана: planning → awaiting-review → approved → in-progress → blocked → done.
- **Оценки объёма** каждого файла в строках (~150 SKILL.md, ~100 live-plan.md, ~200 examples.md и т.д.).
- **Anti-patterns** в mode selection и question protocol.

---

## Сводная таблица различий

| Критерий | omp-5.4 | omp-opus | pi-5.4-pro | pi-exec-5.4 | pi-exec-opus |
|----------|---------|----------|------------|--------------|--------------|
| Количество файлов skill | 15+ | 1 | ~10 | ~10 | ~10 |
| Platform lock-in | Нет | OMP | Pi (мягко) | Pi | Pi |
| Structured config | Да (YAML/JSON) | Нет | Нет | Нет | Нет |
| Meta-plan/overlay | Упомянут | Нет | Да, отдельная концепция | Нет | Нет (покрыто RPD) |
| RPD | Нет | Нет | Да, подробно | Да, кратко | Да, встроен в каждый tier |
| Context reset protocol | Упомянут | Исключён | Подробный | Средний | Подробный |
| interview tool | Нет | Нет | Нет | Кратко | Ключевой |
| Числовые лимиты | Нет | Да (tool calls, questions) | Нет | Да (questions) | Да (questions) |
| Примеры запросов | Нет | 5 кратких | 5 концептуальных | 5 кратких | 5 развёрнутых |
| Escalation/de-escalation | Да, правила | Нет | Да, как сигналы | Общие | Да + anti-patterns |
| Live plan lifecycle | Нет | Нет | Нет | Нет | Да (5 статусов) |
| Анализ предыдущих планов | Нет | Нет | Нет | Нет | Да |
| Язык | EN | EN | RU | RU/EN | EN |

---

## Мои мысли

### Какой план лучший?

**pi-execplan-opus** — самый зрелый и детальный план из пяти. Он единственный:
- Явно анализирует слабости предыдущей итерации
- Предлагает конкретные инструменты для HITL (interview)
- Описывает три конкретных стратегии subagent'ов
- Даёт lifecycle для plan file
- Включает anti-patterns
- Оценивает размеры файлов

Это ожидаемо — Opus + ExecPlan дают самое сильное сочетание. Opus привносит глубину анализа, а ExecPlan-формат заставляет явно фиксировать решения, сюрпризы и recovery.

### Недооценённый план: pi-5.4-pro-high

pi-5.4-pro-high (Gemini 2.5 Pro) — неожиданно сильный. Его **meta overlay** — это единственная идея, которой нет ни в одном другом плане. Концепция правильная: иногда основная неопределённость не в "как сделать", а в "что вообще делать". Ни один другой план не покрывает этот edge case.

Также pi-5.4-pro-high даёт самые подробные **критерии провала** для каждого уровня ("если агент начинает длинное планирование для P0, это провал"). Это полезнее, чем описание успеха — negative examples лучше калибруют поведение.

### Радикализм omp-opus: правильная ли простота?

omp-opus предлагает **один файл на всё**. Это элегантно, но рискованно:
- Pro: минимум навигации для агента, skill загружается целиком.
- Con: если skill-файл вырастет до 500+ строк (а для 5 tier-протоколов + execplan format + oracle recipe + research recipe + self-review protocol это легко), он будет постоянно тратить контекст, даже когда агенту нужен только quickstrike.

Pi-планы с progressive disclosure (SKILL.md ~150 строк + references по запросу) решают эту проблему лучше. Агент читает компактный SKILL.md, а детали подгружает только когда нужно.

### Что стоило бы объединить

Идеальный план взял бы:
- **Из pi-execplan-opus**: общую структуру, interview-интеграцию, subagent-стратегии, lifecycle statuses, anti-patterns, размерные ориентиры
- **Из pi-5.4-pro-high**: meta overlay, подробные acceptance criteria с описанием провалов, RPD с конкретными полями, backpressure как explicit mechanism
- **Из omp-5.4**: формальное сравнение вариантов пакетирования (даже если выбран markdown-first, важно зафиксировать *почему* отвергнуты альтернативы), а также ссылки на источники
- **Из omp-opus**: конкретные числовые лимиты (≤5 tool calls, ≤3 questions), quick reference table, resolved open questions
- **Из pi-execplan-5.4**: числовые question-лимиты по каждому уровню

### Системное наблюдение

Интересен паттерн: **OMP-планы** — это планы-проекты ("вот как skill должен быть устроен"), а **Pi ExecPlan-планы** — это планы-инструкции ("вот как его построить шаг за шагом"). Оба вида нужны, но для непосредственной реализации ExecPlan-формат намного практичнее: он содержит Concrete Steps, Progress tracking, Recovery protocol — всё что нужно, чтобы *начать работать* прямо сейчас.

Также заметно, что **Opus-модели** (omp-opus и pi-execplan-opus) производят более продуманные планы с большей глубиной анализа, но omp-opus направила эту мощность в лаконичность (один файл), а pi-execplan-opus — в детализацию (560 строк). Оба подхода имеют смысл, но для сложного skill с 5 режимами детализация pi-execplan-opus выигрывает.

### Чего не хватает во всех пяти планах

1. **Метрики эффективности**: ни один план не предлагает, как измерять, что skill *улучшает* результат агента. Сколько blind spots ловится? Сколько переделок экономится? Без метрик невозможно итерировать.

2. **Обратная связь и адаптация**: все планы статичны — они описывают v1, но не механизм обучения skill'а на собственном опыте. Что если skill систематически overplans или underplans? Как это обнаружить и поправить?

3. **Конфликт с другими skills**: ни один план не обсуждает, как adaptive-planning взаимодействует с уже существующим `execplan` skill. Будет ли конфликт при автозагрузке? Нужно ли заменять execplan или дополнять?

4. **Пользовательский override**: все планы позволяют user escalation ("пользователь может попросить спланировать"), но ни один не описывает **user de-escalation** ("просто сделай, не планируй"). Для реальной работы это критично — иногда пользователь хочет быстрый результат, даже если задача формально тянет на research.

5. **Тестирование на реальных задачах**: все планы обещают "ручные прогоны", но ни один не содержит результатов таких прогонов. Это нормально для стадии планирования, но говорит о том, что ни один план ещё не прошёл проверку реальностью.
