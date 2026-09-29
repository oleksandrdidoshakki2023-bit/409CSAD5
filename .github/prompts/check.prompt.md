---
description: "Перевіряє структуру агента, Maven, JUnit, GitHub Actions і Git-ігнорування без змін вихідних файлів."
agent: "Build Engineer"
---

Виконай read-only перевірку проєкту. Не редагуй, не видаляй і не додавай до staging жодних файлів; не створюй комітів і не перемикай гілки. Maven може створювати лише ігноровані артефакти в `target/`.

Перевір:

1. Manifest `.github/agents/build-engineer.agent.md` містить роль, область відповідальності, правила безпеки та критерії завершення.
2. Існують три skills за точними шляхами: `.github/skills/project-scaffold/SKILL.md`, `.github/skills/build-and-test/SKILL.md`, `.github/skills/github-actions/SKILL.md`. Кожен має призначення, входи, виходи, перевірки та обробку помилок.
3. Існують prompt-файли `.github/prompts/git-init.prompt.md`, `create-project.prompt.md`, `create-build.prompt.md`, `create-actions.prompt.md`, `check.prompt.md` та `init.prompt.md`.
4. Є `pom.xml` для Java 17 і JUnit 5, вихідні файли Hello World та BasicAddition і відповідні JUnit-тести.
5. Workflow `.github/workflows/ci.yml` реагує на `push` і `pull_request` до `develop` та `master`, має одну job із matrix для Ubuntu, Windows і macOS, налаштовує JDK 17 та викликає платформні CI-скрипти.
6. `ci.sh` і `ci.bat` запускають `mvn -B clean verify`; workflow зберігає JAR як artifact.
7. `target/`, `build/`, `*.class` і `.env` ігноруються Git; `target/` не відстежується Git.

Виконай `mvn -B verify` і перевір, що всі тести проходять та JAR створено. Перевір YAML за допомогою доступного YAML-парсера або linter. Якщо жодного немає, явно познач YAML-перевірку як непідтверджену, не заявляй про повний успіх. Також покажи `git status --short --branch` і `git diff --check`.

На першій помилці зупинись, вкажи точний файл або команду та результат. Наприкінці наведи короткий звіт PASS/FAIL для кожного пункту; не приховуй неперевірені критерії.