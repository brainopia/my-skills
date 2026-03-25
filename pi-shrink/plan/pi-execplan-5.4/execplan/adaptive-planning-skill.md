# Build the `adaptive-planning` Pi skill for agent-first planning

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

Maintained in accordance with `execplan/references/PLANS.md` from the repository root (`/home/bot/projects/pi-skills-with-self-analysis/execplan/references/PLANS.md`).

## Purpose / Big Picture

После выполнения этого плана в рабочем дереве появится новый Pi skill `adaptive-planning`, который помогает агенту выбирать подходящий режим планирования под конкретную задачу, а не пытаться решать все одинаково. Пользователь сможет получить один из пяти режимов: быстрый старт без human-in-the-loop для совсем простых действий, сохраненный план с human-in-the-loop для простых, research-first план для задач средней сложности, глубокий feature plan для сложных фич и mega-plan для больших инициатив с разбиением на подзадачи.

Главный пользовательский эффект: агент начнет заранее устранять blind spots, встраивать validation и self-review, спрашивать только действительно нужные вопросы, сохранять живой план в файл там, где это оправдано, и при необходимости выносить research, review или second opinion в subagents. Проверить это можно серией из пяти сценариев: для каждого сценария агент должен выбрать правильный режим, создать ожидаемый артефакт плана или сознательно не создавать его, затем либо сразу перейти к исполнению, либо остановиться на human-in-the-loop, как требует режим.

## Progress

- [x] (2026-03-08 18:12 UTC+8) Прочитаны методология ExecPlan, документация Pi по skills и локальные материалы `extending-pi/skill-creator`.
- [x] (2026-03-08 18:24 UTC+8) Выбран формат решения: один skill `adaptive-planning` с несколькими режимами планирования и живым планом для режимов, где нужен файл.
- [x] (2026-03-08 18:30 UTC+8) Составлен и сохранен первоначальный ExecPlan в `execplan/adaptive-planning-skill.md`.
- [ ] Создать каркас skill-пакета `adaptive-planning/` с `SKILL.md`, `README.md`, `references/`, `assets/`.
- [ ] Написать trigger description и основной текст `SKILL.md`, чтобы skill reliably auto-activated на запросы о планировании, research, milestones, human-in-the-loop и decomposition.
- [ ] Добавить reference-файлы с mode selection rubric, live plan format, research/subagent protocol, question protocol и примерами.
- [ ] Добавить template assets для live plan и mega plan, чтобы агенту не приходилось каждый раз изобретать структуру.
- [ ] Провести валидацию формата skill, загрузку в Pi и поведенческие прогоны по пяти целевым сценариям.
- [ ] Доработать skill по результатам прогонов и зафиксировать итог в ретроспективе.

## Surprises & Discoveries

- Observation: Рабочая директория `/home/bot/projects/pi-skills-with-self-analysis/plan/pi-execplan-5.4/` фактически пустая, поэтому новый skill нужно создавать с нуля, а не встраивать в уже существующую локальную структуру.
  Evidence: `find . -maxdepth 3 -type f` в текущей директории не вернул проектных файлов.

- Observation: Ограничение “все должно работать на уровне скиллов” исключает жесткое enforcement через hooks, UI policy и автоматическое принудительное переключение режима. Значит v1 должен опираться на strong instructions, file-based live plans и subagents, а не на extension API.
  Evidence: `extending-pi/SKILL.md` прямо рекомендует skill, когда хватает `bash` + instructions, и extension только когда нужны hooks, typed tools или policy enforcement.

- Observation: Для skill quality критичен frontmatter `description`, потому что именно он управляет автозагрузкой skill.
  Evidence: `docs/skills.md` и `extending-pi/skill-creator/SKILL.md` указывают, что body читается слишком поздно, а решение о загрузке skill принимается по description.

## Decision Log

- Decision: Делать v1 как один адаптивный skill `adaptive-planning`, а не как набор отдельных skill-файлов под каждый режим.
  Rationale: Пользователь просит разные виды планов, но все “на уровне скиллов”. Один skill с явной mode-selection rubric проще обнаруживается, легче поддерживается и лучше соответствует progressive disclosure: короткое ядро в `SKILL.md`, детали в `references/`.
  Date/Author: 2026-03-08 / pi

- Decision: Оставить решение в границах skill, не переходя к extension.
  Rationale: Нужно научить агента лучше планировать, задавать вопросы, делать research, сохранять live plan, использовать nested subagents и self-review. Все это достижимо инструкциями и существующими инструментами `read`, `write`, `edit`, `bash`, `subagent`. Жесткое enforcement можно добавить позже отдельным extension only if практика покажет, что инструкций мало.
  Date/Author: 2026-03-08 / pi

- Decision: Ввести пять режимов: `quickstrike`, `guided`, `research`, `feature`, `mega`.
  Rationale: Эти режимы напрямую покрывают пользовательские требования: от мгновенного выполнения с self-review до крупной декомпозиции инициативы на меньшие feature plans.
  Date/Author: 2026-03-08 / pi

- Decision: Для `quickstrike` не требовать обязательный plan file; для `guided` и выше всегда сохранять живой план в `execplan/`.
  Rationale: Пользователь явно хочет, чтобы для супер-простых действий агент сразу переходил к реализации после краткого продумывания blind spots. Для остальных режимов ценность файла плана выше стоимости его создания.
  Date/Author: 2026-03-08 / pi

- Decision: Делать live plan в стиле “OpenAI ExecPlan with action log”: текущий статус, решения, сюрпризы, reason-for-change, validation, next steps.
  Rationale: Пользователь прямо отметил предпочтение к живому плану, который отражает изменения, причины, surprises и action log. Это также совпадает с философией `PLANS.md`.
  Date/Author: 2026-03-08 / pi

- Decision: Не добавлять scripts/ в v1, а вынести знания в `references/` и `assets/templates/`.
  Rationale: Этот skill в первую очередь про когнитивный workflow агента, а не про deterministic automation. Скрипты сейчас усложнят пакет без обязательной пользы. Если позже понадобится scaffold generator, его можно добавить без поломки интерфейса.
  Date/Author: 2026-03-08 / pi

- Decision: Поддержать second opinion через subagents как опциональный паттерн `supervisor`, `council`, `oracle`, а не как обязательный шаг.
  Rationale: Дополнительная модель или коллективное мнение полезны не для каждой задачи. Обязательное использование удорожит простые кейсы. Skill должен явно объяснять, когда стоит вызывать subagent reviewer/planner/researcher или несколько агентов параллельно.
  Date/Author: 2026-03-08 / pi

- Decision: Для “restart agent if context is low” использовать file-based handoff и новый subagent run, а не пытаться измерять реальный context window модели.
  Rationale: Skill не имеет надежного low-level доступа к фактическому заполнению контекста. Но он может требовать: если план распух, research уже собран, или reasoning начинает ссылаться на слишком много источников, обнови plan file, сохрани handoff summary и продолжай в свежем subagent, который читает только нужные файлы.
  Date/Author: 2026-03-08 / pi

## Outcomes & Retrospective

Начальный результат этой стадии: найдена реалистичная, skill-only архитектура для “оптимального планирования” без перехода к extension. Еще ничего не реализовано, но теперь есть конкретный план, который определяет границы решения, целевые режимы, файловую структуру и критерии приемки. Главный урок подготовительной стадии: сила такого skill будет не в длинном SKILL.md, а в удачном разделении на краткое ядро, reference playbooks и reusable templates.

## Context and Orientation

Текущая рабочая директория проекта: `/home/bot/projects/pi-skills-with-self-analysis/plan/pi-execplan-5.4/`. Сейчас это пустой sandbox внутри большего git-репозитория `/home/bot/projects/pi-skills-with-self-analysis/`. Реализацию нового skill нужно делать в текущей рабочей директории, чтобы она была изолирована от существующих skills в корне родительского репозитория.

Новый артефакт, который мы создаем, — это Pi skill. Pi skill — это директория с обязательным файлом `SKILL.md`; Pi решает, когда загрузить skill, на основе frontmatter `description`, а дополнительные знания можно хранить в `references/` и `assets/`. Важные для этой работы правила уже проверены по документации: имя skill должно совпадать с именем директории, использовать только lowercase letters, digits and hyphens, а `README.md` полезен и для людей, и для локального валидатора.

В рамках этого проекта нужно создать такую целевую структуру:

    /home/bot/projects/pi-skills-with-self-analysis/plan/pi-execplan-5.4/
    ├── execplan/
    │   └── adaptive-planning-skill.md          # Этот living plan
    └── adaptive-planning/
        ├── SKILL.md                            # Основные инструкции для агента
        ├── README.md                           # Краткое описание, установка, примеры
        ├── references/
        │   ├── mode-selection.md               # Как выбрать режим
        │   ├── live-plan.md                    # Формат живого плана и action log
        │   ├── research-and-subagents.md       # Когда и как делать research и nested subagents
        │   ├── questions-and-alignment.md      # Когда задавать вопросы, когда не задавать
        │   └── examples.md                     # Примеры запросов и ожидаемого поведения
        └── assets/
            └── templates/
                ├── live-plan-template.md       # Шаблон плана для guided/research/feature
                └── mega-plan-template.md       # Шаблон верхнеуровневого mega plan

Смысл каждого режима нужно определить прямо в skill:

`quickstrike` — режим для супер-простого действия. Агент обязан кратко продумать blind spots и validation, но не обязан сохранять файл плана и не ждет human-in-the-loop. После исполнения всегда делает короткий self-review.

`guided` — режим для простого действия, где нужен saved plan и human-in-the-loop, но на этапе планирования не нужны дополнительные вопросы. Агент пишет plan file, включает self-review уже в сам план и останавливается перед исполнением.

`research` — режим для задачи посложнее, где перед нормальным планом допустимы targeted questions и дополнительное research. После этого остается один главный plan file и тот же human-in-the-loop перед исполнением.

`feature` — режим для сложной фичи. Нужны более широкое исследование, больше вопросов, проработка рисков, validation/backpressure, возможные supporting notes, но один основной файл плана остается главным источником истины.

`mega` — режим для большой сложной инициативы. Сначала формируется общий план и разбиение на меньшие feature-sized chunks. Каждая дочерняя часть должна затем решаться по правилам `feature`, но верхнеуровневый mega plan остается маршрутизатором всей работы.

Также нужно прямо описать используемые в skill термины. “Blind spot” — это аспект задачи, который легко забыть: миграции, обратная совместимость, observability, rollback, тесты, документация, permission model, performance, UX side effects. “Validation” — проверка наблюдаемого результата, а не только компиляции. “Backpressure” — обязательные точки, где агент останавливается или снижает уверенность, если не собран достаточный контекст, не определены acceptance criteria или слишком высок риск ошибки. “RPD” в рамках этого skill лучше трактовать как rapid problem definition: короткое уточнение исходной задачи, ограничений, окружения и definition of done перед детальным планированием. “ask_question” — это не общий чат, а осознанный шаг skill, который задается только тогда, когда ответ materially changes architecture, scope, risk or validation.

## Plan of Work

Сначала нужно создать skeleton skill-пакета и сразу зафиксировать его публичный интерфейс: имя `adaptive-planning`, trigger description, README, набор references и templates. Это даст стабильную оболочку, в которую можно затем вложить сами planning playbooks.

После этого нужно написать `adaptive-planning/SKILL.md` как короткий orchestrator document. В нем не надо пытаться уместить все детали. Он должен объяснить агенту главную идею: сначала классифицируй задачу по сложности и риску, затем выбирай режим, затем следуй протоколу этого режима. Там же надо перечислить обязательные инварианты для всех режимов: устранить blind spots, включить validation, поддерживать alignment, использовать subagents там, где это уменьшает риск или расход контекста, и делать self-review в конце планирования или исполнения в зависимости от режима.

Далее нужно создать reference-файлы. `mode-selection.md` должен содержать рубрику выбора режима, признаки escalation и de-escalation и короткие counterexamples. `live-plan.md` должен задавать единый формат живого плана: purpose, current status, assumptions, action log, decision log, surprises, validation, next steps, handoff note. `research-and-subagents.md` должен описывать, когда использовать встроенных subagents `researcher`, `planner`, `reviewer`, а когда запускать parallel council. Там же нужно описать “context reset by handoff”: сохрани live plan, сохрани краткую summary note и продолжай в fresh subagent, если исследование разрослось. `questions-and-alignment.md` должен определить, когда агент обязан спросить пользователя, а когда обязан принять решение сам. `examples.md` должен дать по крайней мере по одному примеру на каждый из пяти режимов.

После reference-файлов нужно добавить template assets. Это не документы для постоянного чтения, а заготовки, которые агент может копировать при создании plan file. `live-plan-template.md` должен соответствовать guided, research и feature режимам. `mega-plan-template.md` должен добавлять блок decomposition: milestone map, dependency order, per-milestone exit criteria и правила, когда создавать child plans.

Затем нужно сделать validation in behavior, а не только validation in syntax. Сначала проверить skill validator и загрузку skill в Pi. Потом прогнать пять контрольных запросов. Если skill выбирает неправильный режим, задает лишние вопросы, не создает файл там, где должен, или не делает self-review, правки нужно вносить либо в trigger description, либо в mode-selection rubric, либо в reference playbooks. До завершения работы acceptance достигается только тогда, когда все пять сценариев стабильно ведут к ожидаемому типу поведения.

## Concrete Steps

1. Рабочая директория для реализации:

       cd /home/bot/projects/pi-skills-with-self-analysis/plan/pi-execplan-5.4

2. Создать директории для skill и living plan:

       mkdir -p execplan adaptive-planning/references adaptive-planning/assets/templates

   После выполнения структура `find . -maxdepth 3 -type d | sort` должна включать `./execplan`, `./adaptive-planning/references` и `./adaptive-planning/assets/templates`.

3. Создать `adaptive-planning/README.md` с коротким human-oriented описанием, разделом Installation и пятью примерами use cases. README должен объяснять, что skill не заменяет мышление агента, а задает protocol for choosing the right planning depth.

4. Создать `adaptive-planning/SKILL.md`. В frontmatter указать:

       ---
       name: adaptive-planning
       description: Adaptive planning for coding and execution tasks. Use when a request needs choosing between immediate execution, a saved plan with approval, research-first planning, feature decomposition, live plan updates, clarifying questions, or subagent-assisted planning.
       ---

   В body описать:
   - цель skill;
   - общий алгоритм “classify -> plan -> validate -> execute or pause”; 
   - пять режимов и их инварианты;
   - когда читать каждый reference-файл;
   - обязательный self-review protocol.

5. Создать `adaptive-planning/references/mode-selection.md`. Он должен содержать prose-first rubric: какие признаки переводят задачу в `quickstrike`, `guided`, `research`, `feature`, `mega`; когда повышать режим; когда понижать; как оценивать blind spots, unknowns, user alignment risk, integration surface, rollback cost и validation complexity.

6. Создать `adaptive-planning/references/live-plan.md`. В нем зафиксировать канонический формат plan file. Формат должен быть совместим с идеей live ExecPlan: отражать изменения, причины, surprises и action log. Для guided/research/feature режимов plan file создается в `execplan/<slug>.md`. Для mega режима сначала создается top-level plan file в `execplan/<slug>-mega.md`, а child plans допускаются позже по мере старта отдельных milestones.

7. Создать `adaptive-planning/references/research-and-subagents.md`. Указать, что:
   - research нужен, если без него выбор архитектуры, API, dependency или rollout strategy будет гаданием;
   - nested subagents уместны для literature scan, alternative comparison, reviewer pass, council pass;
   - optional roles `supervisor`, `council`, `oracle` реализуются через existing `subagent` workflows, а не через отдельный runtime;
   - context reset делается через updated plan file + handoff summary + fresh subagent.

8. Создать `adaptive-planning/references/questions-and-alignment.md`. Определить строгие правила, когда задавать вопросы: если ответ materially changes scope, architecture, safety, timeline, external dependency or acceptance. Для `guided` режима явно зафиксировать: на этапе планирования вопросы не задаются, агент сам принимает reasonable assumptions и записывает их в plan.

9. Создать `adaptive-planning/references/examples.md`. Добавить как минимум такие запросы и ожидаемое поведение:

       “Rename a component and update imports” -> quickstrike
       “Add a CLI flag with minor parser changes” -> guided
       “Integrate OAuth into an existing app” -> research
       “Build billing and subscription management” -> feature
       “Split a monolith into multi-service architecture” -> mega

10. Создать template assets:

       adaptive-planning/assets/templates/live-plan-template.md
       adaptive-planning/assets/templates/mega-plan-template.md

    В шаблонах должны быть placeholders для purpose, assumptions, blind spots, validation, decision log, surprises, action log и next steps.

11. Проверить формат skill локальным валидатором из родительского репозитория:

       python /home/bot/projects/pi-skills-with-self-analysis/extending-pi/skill-creator/scripts/validate_skill.py /home/bot/projects/pi-skills-with-self-analysis/plan/pi-execplan-5.4/adaptive-planning

    Ожидаемый успешный результат:

       Skill is valid!

12. Проверить загрузку skill в Pi в изоляции:

       cd /home/bot/projects/pi-skills-with-self-analysis/plan/pi-execplan-5.4
       pi --no-skills --skill ./adaptive-planning

    Внутри Pi явно вызвать:

       /skill:adaptive-planning

    Или дать один из тестовых запросов. Ожидаемое наблюдение: агент применяет mode-selection rubric из skill, читает нужные references и не смешивает все режимы в один шаблон.

13. Прогнать пять контрольных сценариев и после каждого вручную проверить:
   - выбран ли ожидаемый режим;
   - создан ли plan file там, где он нужен;
   - не создан ли plan file там, где он не нужен;
   - были ли заданы только необходимые вопросы;
   - появился ли self-review в правильной точке процесса;
   - если был research или subagent, отражено ли это в plan/action log.

14. После каждого прогона обновлять `adaptive-planning/SKILL.md` или reference-файлы до тех пор, пока все сценарии не проходят стабильно.

## Validation and Acceptance

Приемка этой работы должна опираться на наблюдаемое поведение, а не только на наличие файлов.

Синтаксическая приемка: валидатор `validate_skill.py` завершается строкой `Skill is valid!` без ошибок.

Поведенческая приемка для `quickstrike`: при запросе вроде “rename two files and update imports” агент выбирает `quickstrike`, кратко перечисляет blind spots и validation, не создает plan file, сразу выполняет работу и завершает коротким self-review.

Поведенческая приемка для `guided`: при запросе вроде “add a small CLI flag” агент выбирает `guided`, создает plan file в `execplan/`, не задает уточняющих вопросов на этапе планирования, включает assumptions и self-review в план, затем ждет human-in-the-loop перед реализацией.

Поведенческая приемка для `research`: при запросе вроде “add OAuth with provider tradeoffs” агент выбирает `research`, задает ограниченное число действительно влияющих на решение вопросов, делает research, создает один основной plan file и ждет подтверждения перед реализацией.

Поведенческая приемка для `feature`: при запросе сложной фичи агент выбирает `feature`, проводит расширенный discovery, покрывает blind spots по интеграциям, rollout, observability, testing и rollback, при необходимости создает supporting notes, но сохраняет один основной plan file как source of truth.

Поведенческая приемка для `mega`: при запросе уровня крупной инициативы агент выбирает `mega`, создает top-level mega plan, разбивает работу на feature-sized milestones, задает больше стратегических вопросов, определяет research tracks и exit criteria, но не пытается реализовать все как одну плоскую задачу.

Приемка по subagents: хотя second opinion не обязателен, в сценарии с высокой неопределенностью skill должен подталкивать к использованию `subagent` для research, reviewer pass или council comparison, а не заставлять основного агента делать все в одном контексте.

Приемка по context reset: в одном из сложных сценариев агент должен иметь ясный protocol “persist plan -> write handoff summary -> continue in fresh subagent”, даже если сам reset запускается вручную или по эвристике, а не по точному числу токенов.

## Idempotence and Recovery

Создание директории `adaptive-planning/` и ее подпапок идемпотентно через `mkdir -p`. Повторная запись файлов допустима, если содержимое обновляется осознанно. Валидация skill повторяема и безопасна.

Если `SKILL.md` не проходит валидатор, сначала нужно исправить frontmatter, имя директории или README, затем повторить запуск валидатора. Это безопасный цикл, не затрагивающий другие части репозитория.

Если автозагрузка skill работает плохо, первым местом для исправления должен быть frontmatter `description`, а не разрастание `SKILL.md`. Это самый безопасный и локальный путь recovery, потому что меняет trigger semantics без ломки reference-файлов.

Если один из пяти сценариев выбирает неправильный режим, recovery делается в таком порядке: обновить `mode-selection.md`, затем при необходимости скорректировать примеры в `examples.md`, затем упростить или уточнить тело `SKILL.md`, чтобы агент читал нужный reference раньше.

Если выяснится, что skill-only решения недостаточно для принудительного pause, hard gating или точного context budget detection, это не повод ломать v1. Нужно зафиксировать ограничение в `Surprises & Discoveries` и вынести возможный extension-based follow-up в отдельный будущий план.

## Artifacts and Notes

Ожидаемое минимальное дерево после реализации:

    .
    ├── execplan/
    │   └── adaptive-planning-skill.md
    └── adaptive-planning/
        ├── README.md
        ├── SKILL.md
        ├── references/
        │   ├── mode-selection.md
        │   ├── live-plan.md
        │   ├── research-and-subagents.md
        │   ├── questions-and-alignment.md
        │   └── examples.md
        └── assets/
            └── templates/
                ├── live-plan-template.md
                └── mega-plan-template.md

Пример ожидаемого фрагмента из `SKILL.md` body по смыслу, а не как точный текст:

    Before acting, classify the request into one of five modes: quickstrike, guided,
    research, feature, or mega. Choose the lightest mode that still removes blind spots.
    Always define validation before execution. Ask questions only if the answer would
    materially change scope, architecture, risk, or acceptance.

Пример expected behavior note для `guided`:

    Create execplan/<slug>.md before implementation. Record assumptions instead of asking
    planning-time questions. Include validation and self-review sections in the plan.
    Pause for human approval before execution.

Пример expected behavior note для context reset:

    If the plan has become the main source of truth and the current context is crowded,
    update the plan file, append a short handoff summary, and continue via a fresh
    subagent that reads only the required files.

## Interfaces and Dependencies

Главная внешняя зависимость этой работы — формат Pi skills, описанный в `/home/bot/.local/share/pnpm/global/5/.pnpm/@mariozechner+pi-coding-agent@0.57.1_ws@8.19.0_zod@3.25.76/node_modules/@mariozechner/pi-coding-agent/docs/skills.md`. Для реализации важно только то, что уже зафиксировано в этом плане: обязательны `name` и `description`, имя должно совпадать с директорией, а agent activation зависит от `description`.

Локальная зависимость для валидации — `/home/bot/projects/pi-skills-with-self-analysis/extending-pi/skill-creator/scripts/validate_skill.py`. Этот скрипт проверяет frontmatter и наличие `README.md` с разделом Installation, поэтому `README.md` в новом skill не является опциональным для нашего рабочего процесса.

Новый интерфейс skill должен состоять из следующих стабильных файлов и ролей:

В `adaptive-planning/SKILL.md` должны существовать:

    frontmatter.name = "adaptive-planning"
    frontmatter.description = "Adaptive planning for coding and execution tasks..."

    A short body that tells the agent to:
      1. classify the task;
      2. choose one of five modes;
      3. eliminate blind spots;
      4. define validation and backpressure;
      5. ask questions only when necessary;
      6. use research/subagents when justified;
      7. execute immediately only in quickstrike;
      8. perform self-review in every mode.

В `adaptive-planning/references/mode-selection.md` должны быть явно описаны пять режимов, признаки выбора, escalation rules, de-escalation rules и anti-patterns.

В `adaptive-planning/references/live-plan.md` должен быть прописан формат plan file с такими обязательными полями по смыслу:

    title
    purpose
    selected mode
    assumptions / constraints
    blind spots checklist
    validation / acceptance
    action log
    decision log
    surprises
    next steps
    handoff note

В `adaptive-planning/references/research-and-subagents.md` должны быть описаны как минимум три стратегии:

    single reviewer pass
    parallel council comparison
    research handoff to fresh subagent

В `adaptive-planning/references/questions-and-alignment.md` должны быть заданы правила для:

    no-questions planning
    limited targeted questions
    strategic discovery questions

В `adaptive-planning/assets/templates/live-plan-template.md` и `mega-plan-template.md` должны существовать copyable templates, чтобы агент мог создавать consistent plan files без повторного изобретения структуры.

---

Revision note (2026-03-08): Initial ExecPlan created to capture the skill-only architecture, the five planning modes, the live-plan format, and the validation strategy before implementation begins. The reason for this revision is the user request to think through and save a detailed plan using the execplan methodology.