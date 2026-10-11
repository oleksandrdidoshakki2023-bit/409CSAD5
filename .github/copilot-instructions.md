# Repository Guidelines

## Build and test

Run commands from the repository root:

```bash
mvn test
mvn package
mvn -B clean verify
```

Run one test method with Surefire, for example:

```bash
mvn -Dtest=BasicAdditionTest#addsTwoIntegers test
mvn -Dtest=HelloWorldTest#returnsExpectedGreeting test
```

The platform scripts run the full verification lifecycle: `ci.bat` on Windows and `bash ./ci.sh` on Linux/macOS. On Windows, `ci.bat` also checks `MAVEN_HOME` and common IntelliJ IDEA Maven locations when `mvn` is not on `PATH`.

Run the application after packaging with:

```bash
java -cp target/classes edu.lab.hello.HelloWorld
```

## Architecture

This is a Java 17 Maven project in package `edu.lab.hello`. `HelloWorld` provides the greeting and executable `main`; `BasicAddition` contains the small addition operation exercised by `BasicAdditionTest`. `HelloWorldTest` checks the greeting. JUnit Jupiter is configured in `pom.xml`, and Maven Surefire discovers the `*Test` classes.

GitHub Actions uses a single build job with an Ubuntu, Windows, and macOS matrix. It sets up JDK 17, delegates verification to the OS-specific CI script, then uploads the generated JAR. The workflow currently runs on pushes to `develop`, `main`, and `feature/**`, and on pull requests targeting `develop` and `main`.

The Build Engineer agent orchestrates `git-init`, `create-project`, `create-build`, `create-actions`, and `check`. See `.github/agents/build-engineer.agent.md`, `.github/prompts/`, and `docs/architecture.md` for the workflow and component responsibilities.

## Repository-specific conventions

- Keep application and test classes in package `edu.lab.hello`, under the matching Maven source roots.
- Keep the Java release, JUnit Jupiter version, and Maven plugins aligned with `pom.xml`; the target release is 17.
- Keep CI build/test execution in `ci.bat` and `ci.sh`; the workflow should call those scripts rather than duplicate Maven build commands.
- Preserve existing project files and student details. The Build Engineer instructions require checking existing content and getting confirmation before overwriting it.
- Do not stage, commit, publish, switch branches, or delete files as part of agent work unless the user explicitly asks.
- Keep Maven output under `target/`; it is ignored by Git.
