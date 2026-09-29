---
description: "Перевіряє Maven і JUnit за skill build-and-test."
agent: "Build Engineer"
---

Виконай skill [build-and-test](../skills/build-and-test/SKILL.md).

Спочатку переглянь наявні `pom.xml`, `BasicAddition.java`, `BasicAdditionTest.java` і `HelloWorldTest.java`. Якщо вони відповідають вимогам, не перезаписуй їх.

Переконайся, що Maven налаштований на Java 17 і JUnit 5, а тести перевіряють `2 + 3 = 5` та `HelloWorld.greeting() == "Hello, World!"`. Запусти `mvn test` і `mvn package`; покажи результати й зупинись при помилці.

Не змінюй Git staging, не створюй комітів і не створюй GitHub Actions на цьому кроці.