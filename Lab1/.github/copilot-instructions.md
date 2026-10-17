# Copilot instructions for this repository

## Project overview

This repository is a small teaching-focused Java 17/Maven project centered on the `edu.lab.hello` package. The intended application is intentionally narrow: a minimal Hello World class plus a simple arithmetic helper, with matching JUnit 5 tests.

The repo is designed around a standard Maven layout:

- `src/main/java/edu/lab/hello/HelloWorld.java` holds the greeting logic and the `main` entry point.
- `src/main/java/edu/lab/hello/BasicAddition.java` is a tiny integer-addition helper.
- `src/test/java/edu/lab/hello/*Test.java` contains the JUnit checks for the public behavior.
- `pom.xml` defines the Java 17 target, Maven coordinates, and JUnit 5 dependency.
- `.github/workflows/ci.yml` runs the same verification flow across multiple operating systems.
- `ci.sh` and `ci.bat` provide the local repo-native validation commands.

Keep changes consistent with this teaching assignment. Avoid adding extra frameworks, packages, or app layers unless the task explicitly requires them.

## Build, test, and validation commands

Run commands from the repository root. There is no separate lint configuration; Maven verification is the authoritative build/test path.

```bash
# Full test suite
mvn test

# Full verification pipeline used by CI
mvn -B clean verify

# Produce the JAR artifact
mvn package

# Run the application after packaging
java -cp target/classes edu.lab.hello.HelloWorld
```

Run a single test method with Surefire:

```bash
mvn -Dtest=BasicAdditionTest#addsTwoIntegers test
mvn -Dtest=HelloWorldTest#returnsExpectedGreeting test
```

Local validation scripts:

```bash
./ci.sh
```

```bat
ci.bat
```

The Windows script checks `PATH` first and then falls back to common JetBrains IntelliJ Maven installations before failing; do not re-implement this logic elsewhere.

## High-level architecture

This is a deliberately minimal Maven Java project with one functional split:

- `HelloWorld` is the user-facing entry point and the source of the greeting message.
- `BasicAddition` is a standalone utility used by tests and should stay focused on its arithmetic contract.
- The test suite validates the public behavior rather than implementation details, matching the small teaching scope.

The repository intentionally keeps its architecture simple: one app package, one test package, and standard Maven build/test wiring. Prefer small, direct edits that preserve that structure.

## Key conventions

- Keep Java classes under the `edu.lab.hello` package and in the matching Maven source roots.
- Match the existing naming pattern: JUnit 5 `*Test` classes with `@Test` methods.
- Preserve existing student metadata and project context in `README.md`; do not overwrite it without checking the current content.
- Prefer the repo-native verification flow from `ci.sh` / `ci.bat` over duplicating build logic in unrelated files.
- Keep generated output under `target/`; it is ignored by Git and should not be edited or committed.
- Do not stage, publish, switch branches, or delete files as part of routine work unless the user explicitly asks for it.
- When working on scaffolding or build-check tasks, prefer the project-native guidance in `.github/agents/build-engineer.agent.md`, `.github/skills/*/SKILL.md`, and `.github/prompts/*.prompt.md` over generic advice.

## Existing repo guidance to follow

This repository already includes the relevant automation guidance and should be treated as the source of truth for project setup and validation:

- `.github/agents/build-engineer.agent.md`
- `.github/skills/project-scaffold/SKILL.md`
- `.github/skills/build-and-test/SKILL.md`
- `.github/skills/github-actions/SKILL.md`
- `.github/prompts/*.prompt.md`

Use those instructions when creating or validating the Java project, build configuration, or CI pipeline.
