---
name: build-and-test
description: "Use when configuring Maven, Java compilation, JUnit tests, or checking project build and test results."
---

# Build and Test

## Призначення

Налаштувати збірку Java-проєкту через Maven і юніт-тестування через JUnit 5.

## Вхідні дані та передумови

- Корінь Maven-проєкту.
- Java package: `edu.lab.hello`.
- Цільова версія Java: 17.
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
```

Переконайся, що обидві команди завершилися успішно, Maven виявив обидва JUnit-тести без помилок і створив `target/hello-world-1.0-SNAPSHOT.jar`.

## Обробка помилок

- Якщо `mvn` або потрібна версія JDK недоступні, покажи команду перевірки та зупинись; не стверджуй, що збірка пройшла.
- Якщо Maven не може завантажити залежності, повідом про помилку й попроси перевірити мережу або Maven repository; не змінюй залежності навмання.
- Якщо компіляція чи тест падають, наведи назву тесту та повідомлення Maven, виправляй лише після визначення причини й повтори ту саму перевірку.
- Якщо наявний `pom.xml` або вихідний файл треба змінити, спершу поясни необхідну зміну й отримай підтвердження користувача.

## Повторний запуск

Перед кожною зміною перевір наявні файли. Якщо вони вже відповідають вимогам, залиш їх без змін. Не додавай дублікати залежностей, плагінів, класів або тестів. Після будь-якої дозволеної зміни повторно виконай `mvn test` і `mvn package`; не додавай `target/` до Git.
