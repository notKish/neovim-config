# Direnv + Nix flake examples

Use these in your project’s `.envrc`, then run `direnv allow`.

## Java (Maven/Gradle)

Loads the `java` dev shell: JDK 21, Maven, jdtls, `JAVA_HOME`, and `LOMBOK_JAR`.

```bash
use flake ~/.config/nix#java
```

Use in any Java project (e.g. with `pom.xml` or `build.gradle`). Neovim started from that directory will inherit the env so jdtls and Lombok work.

## Copyable sample

See [java.envrc.sample](./java.envrc.sample) — copy it into your project as `.envrc`:

```bash
cp docs/java.envrc.sample .envrc
direnv allow
```
