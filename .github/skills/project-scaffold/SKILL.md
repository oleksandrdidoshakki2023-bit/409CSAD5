---
name: project-scaffold
description: "Use when creating or checking the initial Java Hello World project structure, source code, README, or .gitignore."
---

# Project Scaffold

## Призначення

Створити початкову структуру кросплатформного Java Hello World проєкту, початковий README та `.gitignore`.

## Вхідні дані

- Мова: Java.
- Назва проєкту: `hello-world-java`.
- Пакет: `edu.lab.hello`.

Якщо назва або пакет не вказані, попроси уточнення перед створенням файлів.

## Результат

Створи або доповни:

- `src/main/java/edu/lab/hello/HelloWorld.java` із методом `greeting()`, що повертає `Hello, World!`, і `main`, який виводить це повідомлення.
- `README.md` з описом Java-проєкту, Maven, JUnit, запуску AI-агента, тестування та запуску застосунку.
- `.gitignore` з правилами для `target/`, `build/`, `*.class` і `.env`.

У README наведи команди:

```bash
mvn package
java -cp target/classes edu.lab.hello.HelloWorld
```

Якщо README уже існує, збережи всі наявні дані студента, групи й корисний текст; доповнюй, а не замінюй файл повністю.

## Перевірка

- Переконайся, що Java-файл існує, має пакет `edu.lab.hello`, `greeting()` і `main`.
- Переконайся, що README містить команди складання та запуску застосунку.
- Переконайся, що `.gitignore` виключає `target/`.
- Не запускай Maven-збірку на цьому етапі; її виконує skill `build-and-test`.

## Помилки та повторний запуск

Перед змінами перевір кожен файл. Якщо файл уже існує, переглянь його та не перезаписуй без пояснення й підтвердження користувача. Якщо потрібні файли вже відповідають вимогам, залиш їх без змін. Повторний запуск не повинен створювати дублікати записів у `.gitignore` або втрачати наявні дані.
