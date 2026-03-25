# Сравнительный обзор пяти планов adaptive-planning skill

## Карта планов

| # | Файл | Платформа | Нейминг режимов | Формат плана | Язык |
|---|------|-----------|-----------------|--------------|------|
| 1 | `omp-5.4/PLAN.md` | Generic agent | Mode 0–4 | Design doc | EN |
| 2 | `omp-opus/PLAN.md` | OMP (Oh My Pi) | Tier 0–4 | Design doc + рецепты | EN |
| 3 | `pi-5.4-pro-high/execplan/…` | Pi | P0–P4 | ExecPlan (живой) | RU |
| 4 | `pi-execplan-5.4/execplan/…` | Pi | quickstrike–mega | ExecPlan (живой) | EN |
| 5 | `pi-execplan-opus/execplan/…` | Pi | quickstrike–mega | ExecPlan (живой) | EN |

---

## 1. omp-5.4 — «Архитектурный чертёж без привязки»

### Сильные стороны
- **Чистая архитектура.** Единая ExecPlan-схема с policy-layer для выбора глубины — элегантная идея, которая убирает дублирование.
- **Три варианта реализации.** Явно сравнивает pure-markdown, markdown+config и code-centric подходы, обосновывает выбор. Ни один другой план не делает этого.
- **Формальные review-гейты.** Completeness gate, blind-spot gate, execution gate, escalation gate — чёткая таксономия проверок.
- **Хорошая рубрика выбора режима.** 8 осей (ambiguity, novelty, blast radius, reversibility, research need, user input need, size, dependency complexity) + escalation rules + auto-escalation при отсутствии acceptance criteria.
- **Явный self-review контракт** с классификацией находок: blocker / nice-to-have / execution-time watchout.

### Слабые стороны
- **Не привязан к платформе.** Не знает ни Pi, ни OMP. Нет конкретных tool invocations, нет субагентных рецептов. Нельзя взять и реализовать — нужен большой translation layer.
- **Нет конкретного формата live plan.** Есть список секций (15 штук), но нет шаблона, нет примера заполнения, нет lifecycle (statuses, transitions).
- **Нет примеров.** Вообще. Описывает «добавить примеры» как будущую фазу.
- **Нет RPD.** Нет концепции быстрой дистилляции проблемы перед стартом планирования.
- **Нет context reset / handoff.** Полностью игнорирует проблему исчерпания контекста.
- **Нет HITL-механики.** Говорит «pause for approval», но не описывает как — через какой инструмент, в каком формате.

### Вердикт
Хорош как white paper, слаб как blueprint для реализации.

---

## 2. omp-opus — «Боевой рецепт для OMP»

### Сильные стороны
- **Максимальная конкретность.** Содержит copy-paste рецепты вызовов oracle, librarian, reviewer с точным JSON. Самый "бери и делай" из всех планов.
- **Правильно использует платформу.** Знает про `exit_plan_mode`, `local://PLAN.md`, `explore`, `oracle`, `librarian`, `reviewer`, `task`/`quick_task`, TTSR. Каждый tier говорит какие агенты вызывать и в каком порядке.
- **Один файл.** Вся skill — один `SKILL.md`. Предельная простота поставки. Осознанное решение, обоснованное.
- **Хорошая summary-таблица.** Quick reference таблица tier×свойства — мгновенно считывается.
- **«When in doubt, pick one tier higher»** — простое, но мощное правило для edge cases.

### Слабые стороны
- **Привязан к OMP, а не к Pi.** Все рецепты используют OMP-специфичные вещи (`exit_plan_mode`, `local://`, агенты `explore`/`oracle`/`librarian`). Непереносим на Pi без переписывания.
- **Нет progressive disclosure.** Всё в одном файле. Для сложного skill это приведёт к раздутому системному промту. Pi/OMP загрузит весь body — это дорого по контексту.
- **Нет context reset.** Явно говорит «OMP handles it via TTSR» и закрывает тему. Это ошибка — TTSR не решает проблему передачи контекста между сессиями.
- **ExecPlan-формат неполный.** Есть Task/Edge Cases/Validation/Action Log/Open Questions, но нет Decision Log, Surprises, Handoff Note, RPD.
- **Нет RPD.** Нет fast problem framing.
- **Tier selection слишком поверхностен.** Всего одна таблица сигналов. Нет escalation/de-escalation rules, нет anti-patterns.
- **Нет backpressure.** Нет явных точек, где агент обязан остановиться при недостатке контекста.

### Вердикт
Лучший для OMP «здесь и сейчас». Для Pi бесполезен. Формат live plan слишком тонкий.

---

## 3. pi-5.4-pro-high — «Энциклопедический план с RPD и backpressure»

### Сильные стороны
- **RPD как концепция.** Единственный (вместе с #5, который заимствовал) план, где быстрая дистилляция проблемы — отдельная явная фаза. Goal, Constraints, Repo Facts, Unknowns, Proof, Chosen Mode.
- **Backpressure как концепция.** Самое подробное описание: что это, зачем, по каждому режиму P0–P4 — где ставится обязательная точка остановки. Другие планы упоминают HITL, но не формализуют backpressure.
- **Meta overlay.** Уникальная идея: если неопределённость не в реализации, а в выборе подхода — сначала meta planning, потом implementation plan. Накладывается поверх P2–P4.
- **Restart-from-plan.** Самое детальное описание: обнови Progress, Action Log, Surprises, Decision Log, Validation, точный Next Step. Либо subagent, либо ручной рестарт.
- **Хорошая файловая структура.** 6 reference-файлов + assets/examples. Progressive disclosure по всем правилам skill-creator.
- **Подробные milestone'ы с внятной приёмкой.** Каждый milestone кончается observable acceptance, а не «файл написан».
- **Именование live plan'ов.** `execplan/2026-03-08-p3-background-jobs-feature.md` — простая, понятная конвенция.

### Слабые стороны
- **Нет конкретного формата live plan.** Секции перечислены абстрактно в «references/live-plan-template.md», но сам шаблон не написан — только описание того, что туда положить. Сравните с #5, где формат расписан до полей.
- **Нет tool-specific рецептов.** Не упоминает `interview` для HITL. Не описывает, как вызвать `subagent` (JSON или текстом). Для Pi-skill'а это пробел.
- **Вербозен.** Самый длинный текст из пяти. Много повторений одних и тех же идей. Нуждается в редактуре на ~30%.
- **Режимы P0–P4 описаны кратко.** 1–2 предложения на режим, подробности уходят в будущие reference-файлы. Но reference-файлы не написаны.
- **Нет anti-patterns.** Нет примеров «что НЕ делать» при выборе режима.
- **Нет примеров запросов.** Validation scenarios — todo-пункт, а не контент.

### Вердикт
Самый концептуально богатый. Лучшие идеи (RPD, backpressure, meta overlay, restart-from-plan), но остаётся на уровне «подробное ТЗ, а не спецификация».

---

## 4. pi-execplan-5.4 — «Рабочий план с пробелами»

### Сильные стороны
- **Pi-native.** Знает про Pi skill discovery, frontmatter, validate_skill.py, `--no-skills --skill`, `/skill:`. Готов к реализации в Pi.
- **Хорошие имена режимов.** quickstrike / guided / research / feature / mega — коротко, запоминаемо, в порядке возрастания.
- **Конкретные шаги.** 14 пронумерованных шагов от `mkdir -p` до ручного прогона пяти сценариев.
- **Правильная файловая структура.** Такая же, как у #3 — references + assets/templates.
- **Context reset.** Упоминает file-based handoff + fresh subagent. Менее детально, чем #3, но присутствует.

### Слабые стороны
- **Формат live plan не специфицирован.** Есть абзац «формат должен быть совместим с ExecPlan», но конкретных секций/полей нет.
- **Tier selection vague.** Написано «prose-first rubric» — но сама рубрика отложена в reference-файл, который не написан. Ни осей, ни порогов, ни anti-patterns.
- **Self-review не определён.** Упоминается, но нет чек-листа, нет описания что проверять.
- **Subagent стратегии абстрактны.** «Three strategies» названы, но без деталей и рецептов вызова.
- **Нет RPD.** Термин не появляется.
- **Нет backpressure.** Термин не появляется.
- **Пересечение с #3.** Видно, что план #4 — более ранняя/упрощённая версия. #3 добавил RPD, backpressure, meta overlay и restart policy, которых здесь нет.

### Вердикт
Минимально жизнеспособный, но существенно уступает #3 и #5 по глубине.

---

## 5. pi-execplan-opus — «Самый зрелый план»

### Сильные стороны
- **Конкретный формат live plan.** Расписан до полей: Status (planning/awaiting-review/approved/in-progress/blocked/done), Purpose, RPD, Assumptions & Constraints, Blind Spots Addressed, Approach, Validation & Acceptance, Action Log, Decision Log, Surprises & Discoveries, Self-Review, Next Steps, Handoff Note. + описан lifecycle перехода статусов.
- **Явное использование `interview` для HITL.** Единственный план, который конкретно говорит: используй `interview` tool для plan approval и structured questions. Это правильный ответ на вопрос «как HITL в Pi».
- **Три именованных subagent-стратегии** с конкретным описанием: single reviewer pass, parallel council, oracle query. + context reset protocol.
- **Per-tier question budgets.** quickstrike=0, guided=0, research=1-3, feature=unbounded, mega=strategic. Числа, а не «ограниченное количество».
- **Развёрнутые примеры.** 5 worked examples с reasoning — почему именно этот tier, какие blind spots, какие шаги. Самые детальные примеры из всех планов.
- **Anti-patterns в mode selection.** «Don't use mega for a task that's just big but not complex», «don't use quickstrike if you've never worked in this codebase before». Ни один другой план этого не делает.
- **Explicit awareness of prior plan gaps.** Surprises section содержит конкретный анализ слабых мест предыдущего плана (#4) и осознанно закрывает каждый пробел.
- **RPD встроен как первый шаг каждого tier'а,** а не как отдельная фаза. Правильный баланс.
- **Оценки объёма файлов.** SKILL.md ~150-200 lines, mode-selection ~150 lines и т.д. Даёт имплементатору ориентир.
- **6-dimensional rubric.** scope, unknowns, risk, integration surface, user alignment, validation complexity — с escalation и de-escalation rules.

### Слабые стороны
- **Нет meta overlay.** Идея из #3 (сначала meta planning для выбора подхода, потом implementation plan) не подхвачена.
- **Нет явного backpressure.** Context reset и self-review есть, но нет формализованного понятия «обязательная точка остановки при недостатке контекста». #3 сделал это лучше.
- **Нет naming convention для plan files.** #3 предложил `execplan/2026-03-08-p3-…`, здесь — только `execplan/<slug>.md`. Мелочь, но полезная.
- **Mega child plans — только deferred creation.** Решение «создавать child plan только при старте milestone» верное, но нет naming convention: `execplan/<mega-slug>-m<N>-<name>.md` упомянут, но не закреплён как правило.
- **Не упоминает `explore`-style быстрый скаутинг.** #2 использует параллельные `explore`-агенты для быстрого сканирования кодовой базы — полезный паттерн, которого здесь нет.

### Вердикт
Самый зрелый, самый конкретный, самый готовый к реализации.

---

## Сводная таблица: покрытие ключевых аспектов

| Аспект | #1 omp-5.4 | #2 omp-opus | #3 pi-5.4-pro | #4 pi-exec-5.4 | #5 pi-exec-opus |
|--------|:----------:|:-----------:|:-------------:|:---------------:|:---------------:|
| Конкретный формат live plan | ○ | ◐ | ○ | ○ | ● |
| RPD | ✗ | ✗ | ● | ✗ | ● |
| Backpressure формализован | ◐ | ✗ | ● | ✗ | ◐ |
| Meta overlay | ✗ | ✗ | ● | ✗ | ✗ |
| Context reset / handoff | ✗ | ✗ | ● | ◐ | ● |
| HITL-механика (конкретный tool) | ✗ | ● (OMP) | ✗ | ✗ | ● (interview) |
| Subagent-рецепты | ○ | ● (OMP) | ◐ | ◐ | ● |
| Mode selection rubric | ● | ◐ | ◐ | ✗ | ● |
| Escalation/de-escalation | ● | ◐ | ◐ | ✗ | ● |
| Anti-patterns | ✗ | ✗ | ✗ | ✗ | ● |
| Worked examples | ✗ | ✗ | ✗ | ◐ | ● |
| Self-review checklist | ● | ◐ | ◐ | ✗ | ◐ |
| Progressive disclosure | ◐ | ✗ | ● | ● | ● |
| Naming conventions | ✗ | ✗ | ● | ✗ | ◐ |
| Варианты реализации | ● | ✗ | ✗ | ✗ | ✗ |
| Pi/OMP native | ✗ | ● (OMP) | ● (Pi) | ● (Pi) | ● (Pi) |
| Validation scenarios | ◐ | ● | ◐ | ◐ | ● |

● = полноценно | ◐ = частично | ○ = упомянуто, но не специфицировано | ✗ = отсутствует

---

## Итоговый рейтинг: лучший план как основа для реализации

### 🥇 #5 pi-execplan-opus

Лучший по совокупности. Единственный, кто одновременно:
- Pi-native и знает инструменты
- Имеет конкретный формат live plan с lifecycle
- Даёт развёрнутые примеры по каждому tier'у
- Специфицирует question budgets числами
- Использует `interview` для HITL
- Имеет 6-мерную рубрику выбора с anti-patterns
- Осознанно закрывает пробелы предшественника

### 🥈 #3 pi-5.4-pro-high

Второй. Уникальные идеи (RPD, backpressure, meta overlay, naming conventions), которых нет в #5. Но слабее по конкретике — формат плана, примеры, tool-рецепты не доведены до реализуемого состояния.

### 🥉 #2 omp-opus

Третий. Самый практичный из «чужих» платформ — содержит copy-paste рецепты, но всё привязано к OMP. Ценен как source of concrete invocation patterns.

### 4-е место: #1 omp-5.4

Хорош как архитектурный обзор. Review gates и сравнение package formats полезны. Но слишком абстрактен для реализации.

### 5-е место: #4 pi-execplan-5.4

Подмножество #5. Всё, что в нём есть, есть и в #5, но лучше.

---

## Рекомендуемый гибрид

Взять **#5 pi-execplan-opus** как базу и обогатить из остальных:

### Заимствовать из #3 (pi-5.4-pro-high):

1. **Meta overlay.** Если главная неопределённость — «как решать», а не «как реализовать», сначала meta planning (исследование подходов и критериев выбора), потом implementation plan. Добавить как опциональный этап перед P2–P4.

2. **Формализованный backpressure.** Описать по каждому tier'у конкретные обязательные точки остановки: для quickstrike — проверка side effects до выполнения; для guided — запрет на код до approval; для research — запрет на план до закрытия ключевых unknowns; для feature — запрет на реализацию до написания validation strategy; для mega — запрет на дочернюю реализацию до approved master plan.

3. **Naming convention для plan files.** `execplan/<date>-<tier>-<slug>.md` и `execplan/<initiative>/<milestone>.md` для mega.

### Заимствовать из #2 (omp-opus):

4. **Параллельные explore/scout агенты.** Перед планированием в guided+ — запуск параллельных `subagent` на быстрое сканирование разных частей кодовой базы. Это ускоряет context gathering.

5. **Quick reference таблица** tier×{plan file, HITL, questions, research, subagents} — одна таблица для быстрой навигации.

6. **«When in doubt, pick one tier higher»** — добавить как явное правило.

### Заимствовать из #1 (omp-5.4):

7. **Review gates taxonomy.** Completeness gate / blind-spot gate / execution gate / escalation gate — структурировать self-review не как плоский чек-лист, а как систему из четырёх типов гейтов.

8. **Self-review finding classification.** Blocker before approval / nice-to-have / execution-time watchout — для guided+ это ценнее, чем простой pass/fail.

### Что НЕ заимствовать

- Из #2: OMP-специфичные invocations (`exit_plan_mode`, `local://`, `explore` agent) — не применимы к Pi.
- Из #1: YAML/JSON config layer — преждевременно для v1 skill-only решения.
- Из #3: Чрезмерную вербозность и повторения. Брать идеи, не текст.
- Из #4: Ничего — #5 уже является его улучшенной версией.

### Итоговая формула

```
гибрид = #5 (база + структура + конкретика + примеры)
       + #3.meta_overlay
       + #3.backpressure_per_tier
       + #3.naming_convention
       + #2.parallel_scouts
       + #2.quick_ref_table
       + #2.tier_up_rule
       + #1.review_gates_taxonomy
       + #1.finding_classification
```

Это даст план, который:
- Конкретен до уровня «бери и пиши файлы» (от #5)
- Концептуально полон: RPD + backpressure + meta overlay + context reset (от #3 + #5)
- Имеет лучшие UX-решения: таблица, правило «tier up», `interview` для HITL (от #2 + #5)
- Имеет зрелую систему review: 4 типа гейтов + классификация находок (от #1)
