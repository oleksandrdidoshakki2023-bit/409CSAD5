# Архітектура AI-агента

## Призначення

Агент допомагає створити й перевірити кросплатформний застосунок Hello World на Java. Для складання використовується Maven, для юніт-тестів — JUnit.

## Складові

| Складова | Розташування | Призначення |
|---|---|---|
| Agent manifest | `.github/agents/build-engineer.agent.md` | Роль агента, обмеження та критерії завершення |
| Skill `project-scaffold` | `.github/skills/project-scaffold/SKILL.md` | Початкова структура Java-проєкту |
| Skill `build-and-test` | `.github/skills/build-and-test/SKILL.md` | Maven-збірка та JUnit-тести |
| Skill `github-actions` | `.github/skills/github-actions/SKILL.md` | CI workflow для Windows, Linux і macOS |
| Commands | `.github/prompts/*.prompt.md` | Окремі операції агента |
| Orchestrator | `.github/prompts/init.prompt.md` | Послідовний запуск повного сценарію |

## Команди

- `git-init` — перевіряє Git-репозиторій і `.gitignore`.
- `create-project` — створює структуру та Hello World.
- `create-build` — налаштовує Maven і JUnit.
- `create-actions` — створює GitHub Actions workflow.
- `check` — перевіряє файли, збірку, тести та workflow.
- `init` — виконує команди послідовно: `git-init`, `create-project`, `create-build`, `create-actions`, `check`.

## Передавання результатів і помилки

Кожна команда перевіряє передумови, виконує свою операцію та повідомляє створені або перевірені файли. Оркестратор переходить до наступної команди лише після успішного завершення поточної. При помилці він зупиняється, показує команду та повідомлення про помилку; автоматично не приховує проблему й не видаляє файли.

## Перевірка результату

Команда `check` перевіряє наявність manifest, skills, commands, вихідного коду, тестів і workflow, а також запускає Maven-тести та збірку. Повторний запуск `init` не повинен перезаписувати наявні файли без перевірки.