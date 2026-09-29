---
name: build-and-test
description: "Use when configuring Maven, Java compilation, JUnit tests, or checking project build and test results."
---

# Build and Test

## Призначення

Налаштувати збірку Java-проєкту через Maven і юніт-тестування через JUnit 5.

## Передумови

- Існує вихідний код `src/main/java/edu/lab/hello/HelloWorld.java`.
- Проєкт має пакет `edu.lab.hello`.
- Доступні JDK 17 або новіший і Maven.
- Перед зміною перевір, чи вже існує `pom.xml`; не перезаписуй наявний файл без підтвердження.

## Виходи

Створи або доповни:

- `pom.xml` з координатами проєкту, Java release 17, JUnit Jupiter і Maven Surefire Plugin.
- `src/main/java/edu/lab/hello/BasicAddition.java` з методом додавання двох цілих чисел.
- `src/test/java/edu/lab/hello/BasicAdditionTest.java` з JUnit-тестом `BasicAddition`, який перевіряє, що `2 + 3` дорівнює `5`.
- `src/test/java/edu/lab/hello/HelloWorldTest.java`, який перевіряє, що `HelloWorld.greeting()` повертає `Hello, World!`.

Використовуй узгоджену версію JUnit 5 і налаштуй Surefire так, щоб Maven виявляв та запускав тести.

## Перевірка

Із кореня проєкту виконай:

```bash
mvn test
mvn package
