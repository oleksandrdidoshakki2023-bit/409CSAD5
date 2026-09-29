---
description: "Перевіряє та налаштовує кросплатформний GitHub Actions CI за skill github-actions."
agent: "Build Engineer"
---

Виконай інструкції з [skill github-actions](../skills/github-actions/SKILL.md).

Перед змінами перевір наявність `.github/workflows/ci.yml`, `ci.sh` і `ci.bat`. Якщо файли вже існують, переглянь їх і збережи відповідні вимогам налаштування; не перезаписуй без пояснення та підтвердження.

Переконайся, що workflow запускається на `push` і `pull_request` до `develop` та `master`, має одну job із matrix для `ubuntu-latest`, `windows-latest` і `macos-latest`, налаштовує JDK 17 та викликає `ci.bat` на Windows і `ci.sh` на Linux/macOS. Переконайся, що JAR зберігається як artifact після успішної збірки.

Перевір YAML і відповідність скриптів поточній ОС. Скрипти мають запускати `mvn -B clean verify`; workflow не повинен дублювати Maven-команди. При помилці зупинись і покажи її.

Не додавай файли до staging, не створюй коміти, не публікуй гілки та не додавай секрети.