# E1 - Repository and workspace foundation

**Goal.** A repository which builds green with an empty core - locally AND in GitHub Actions at
`pbinitiative/zenbpm-vanillabp-adapter` - is part of the local workspace, carries the
documents every adapter carries, and can start the ZenBPM engine from a test.

**Why first.** Every later story adds tests which need the coverage gate, the Spotless rules, the
container helper and a green pull-request check; adding those later means touching every module
twice. And because the repository builds against `io.vanillabp:*` snapshots which live in ANOTHER
organisation's GitHub Packages, the CI's access to them is the first thing which can fail, so it is
proven before any Java exists.

**Done when.** `mvn install` is green in the new repo, the pull-request workflow is green on GitHub,
snapshots and coverage pages are published from `main`, the local workspace builds it after the
platform, and one test has talked to a ZenBPM container.

The repository already exists (`https://github.com/pbinitiative/zenbpm-vanillabp-adapter`, default
branch `main`, `LICENSE` = MIT, a one-line `README.md`, a Java `.gitignore`) and is checked out in
the workspace; the plan lives in its `docs/` folder. Stories below start from that state.

Conventions for every story of this plan: Java 21, Spotless with the copied `formatting_conventions.xml`
(import order `java,javax,org,com,at.phactum`, one fluent call per line, `String#formatted`, text
blocks), every test class starts with `@ExtendWith(SuppressOutputExtension.class)`, names read like
sentences, no citation but `see decision N in the repository's DECISIONS.md`, and every README or
wiki sentence promising behaviour names the test which holds it.

---

## F1.1 Repository skeleton

### S1.1.1 Create the repository and its build

- [ ] **Depends on:** nothing.

**Instructions**

1. In the existing checkout: keep `LICENSE` (MIT); add `LICENSE-APACHE-2.0` (the Apache licence
   text) and a `NOTICE` naming `vanillabp/camunda8-adapter` and
   `vanillabp/process-engine-api-adapter` as the origin of adapted code (draft decision 17); copy
   from `camunda8-adapter`: `formatting_conventions.xml`, the Maven parts of `.gitignore` (merge
   into the existing Java one, keep `/zenbpm-vanillabp-adapter.iml`), `test-coverage-report/` (three
   modules). Rename every `camunda8`/`Camunda8` occurrence. The Camunda 8 Java files carry no
   header, so a copied Java file gets one naming its origin with `SPDX-License-Identifier:
   Apache-2.0`, and every new file gets the MIT header (`AGENTS.md` shows both). `readme/` is not
   copied: it holds the VanillaBP headline and the Phactum logo, and this README shows no images.
   The workflows are F1.3, not copied here.
2. Root `pom.xml`: groupId `org.pbinitiative.zenbpm` (the group of the engine's Java client; the
   root package stays `org.pbinitiative.zenbpmadapter`), artifactId
   `zenbpm-vanillabp-adapter-parent`, version `${revision}` with
   `<revision>2.0.0-SNAPSHOT</revision>`, `flatten-maven-plugin` in mode `oss` (the published POM
   stands on its own: no parent, every version written out, as `camunda8-adapter` does it),
   modules `core`, `spring-boot`, `smoke-test`, `quarkus/runtime`, `quarkus/deployment`,
   `quarkus/integration-tests`, `test-coverage-report`. Import the Spring Boot BOM and the Quarkus
   BOM in the versions the platform uses (read them from `adapter-platform-integration/pom.xml` at
   the time of the story), manage `spi-for-java`, `vanillabp-adapter-spi`,
   `vanillabp-spring-boot-integration`, `vanillabp-quarkus-integration`,
   `vanillabp-quarkus-integration-deployment`, `test-utils`, `testcontainers`,
   `testcontainers-junit-jupiter`, `grpc-*`, `protobuf-java`. Properties
   `coverage.threshold.spring-boot` = `coverage.threshold.quarkus` = 85, `coverage.rule` = 90; the
   engine pin (`zenbpm.commit`, `zenbpm.image`) is S1.2.1's, so this story needs no engine. No
   `line-*` profiles, no `build-helper` per-line sources.
3. Copy the Spotless, JaCoCo (`@{jacoco.agent}`, excludes `**/it/**`, `**/test/**`), surefire and
   failsafe configuration from the Camunda 8 parent; add `**/generated-sources/**` to the Spotless
   excludes (S1.2.2 puts stubs there).
4. `core/pom.xml`: artifactId `zenbpm-vanillabp-adapter`, dependencies `vanillabp-adapter-spi`,
   `spi-for-java`, `slf4j-api`, `jackson-databind` (provided by both platforms; declare it `compile`
   here, the platforms manage the version), `grpc-netty-shaded`, `grpc-protobuf`, `grpc-stub`,
   `protobuf-java`, `lombok` `provided` (Maven does not copy the optional flag out of a
   `dependencyManagement`, so `optional` would leave Lombok in the published POM); resource
   filtering on for
   `META-INF/vanillabp/adapter-zenbpm.properties`:

   ```properties
   adapter.version=${project.version}
   platform.version=${adapter-platform.version}
   ```

   S1.2.1 adds `zenbpm.engine=${zenbpm.commit}` together with the pin.

5. `core/src/main/java/org/pbinitiative/zenbpmadapter/ZenBpmAdapter.java` with `ADAPTER_TYPE =
   "zenbpm"` and a javadoc saying what the type means (the id defaults to it).
6. Root documents: `AGENTS.md` (copy the Camunda 8 one, adjust names, add one paragraph: this
   repository is owned by the ZenBPM maintainers, follows the VanillaBP adapter conventions by
   decision 16, and the engine's Go conventions do not apply), `DECISIONS.md` with the entries 1, 3,
   13, 15, 16 and 17 of `architecture/02-design-decisions.md` (the ones this story already relies
   on), `GAPS.md` with the header and entries 11-14, 18 and 21 (the ones which need no code to be
   true), `UPGRADE.md` with a header only, `README.md` replacing the one-liner: Status "Skeleton",
   the module table, the build order (`spi-for-java` -> `adapter-platform-integration` -> this
   repository, with the note that the two upstream repositories are VanillaBP's and their snapshots
   come from GitHub Packages), a "Supported engine version" heading saying "not pinned yet" (S1.2.1
   fills it), a "Licence" section (MIT plus the Apache-2.0 attribution) and a "Test coverage"
   section copied and adjusted. The `docs/` folder stays as the plan; the README links it.
7. `renovate.json` of the repository's own (`config:recommended`, Maven and GitHub Actions managers,
   `dependencyDashboard`). VanillaBP's shared preset is not used: it carries rules for VanillaBP's
   own release trains. The engine pin is NOT left to Renovate while it is a `main` commit: the pin,
   the image digest and the two contract copies move together in one hand-made commit (S1.2.1 says
   how). A `customManagers` entry for engine releases is added once the pin is a release tag
   (S12.3.1).

**Tests**

- `test-coverage-report/coverage-gate`: `CoverageGateTest` (with `@PrintsWhenPassing`) and
  `TestClassConventionsTest`, copied from Camunda 8. With no production code the gate has nothing to
  measure. The Camunda 8 gate reads an empty report as 0 % and would fail; here the two threshold
  tests print why and are reported as skipped, like a run which stops before `verify`, so an empty
  report neither fails the build nor reads as a checked one. `PublishedPomsTest` comes along too.

**Acceptance criteria**

- [ ] `mvn install` is green from a clean local repository which holds `spi-for-java` and
  `adapter-platform-integration` installed.
- [ ] `mvn spotless:check` passes; a deliberately misformatted file fails the build.
- [ ] Both coverage reports and the gate module exist and run.
- [ ] `META-INF/vanillabp/adapter-zenbpm.properties` in the built core jar carries resolved values.
- [ ] `DECISIONS.md`, `GAPS.md`, `AGENTS.md`, `README.md`, `UPGRADE.md`, `NOTICE`,
  `LICENSE-APACHE-2.0` exist with the content above.

### S1.1.2 Finish the workspace membership, locally

- [ ] **Depends on:** S1.1.1 pushed to `main`.

**Instructions**

The workspace superproject is `vanillabp/development-workspace`, which the VanillaBP project owns.
Nothing about the two pbinitiative repositories is committed there, and no pull request to it is
planned: `zenbpm` and `zenbpm-vanillabp-adapter` are plain clones next to the submodules, with no
gitlink in the superproject's index, and their directories stay ignored by the top-level `/*` of
`.gitignore`. So `.gitmodules` entries for them do nothing for `git submodule`, the superproject's
CI (`update-submodules.yml`) never sees them, and a recursive clone of the workspace does not get
them. Everything below stays an uncommitted change of the local workspace, as the root `AGENTS.md`
and the two `zenbpm-*` skills already are.

1. Local `.gitmodules`: both pbinitiative entries say `branch = master`, but the default branch of
   `zenbpm` and of `zenbpm-vanillabp-adapter` is `main`. Change both to `main`, so the file does not
   say something wrong, even though no `git submodule` command uses the entries yet.
2. Wiki: clone `git@github.com:pbinitiative/zenbpm-vanillabp-adapter.wiki.git` next to the adapter
   as `zenbpm-vanillabp-adapter.wiki/` (the wiki exists since 2026-10-04 with a `Home` page). The
   top-level `/*` ignores it like the adapter.
3. Local root `AGENTS.md`: the paragraph which names `zenbpm` as a locally checked out member gains
   `zenbpm-vanillabp-adapter` and its wiki (owned by pbinitiative, Java, follows the VanillaBP
   adapter conventions, builds with `cd zenbpm-vanillabp-adapter && mvn install` after the platform,
   ITs need Docker for `ghcr.io/pbinitiative/zenbpm`). The root `README.md` stays untouched: its
   submodule table lists what a recursive clone gets, and neither pbinitiative repository is part of
   one.
4. Optional, for those who use the devcontainer warmup: in the local
   `dev-containers/devcontainers-config.json`, `repos` gains `zenbpm-vanillabp-adapter` (`main`) and
   `zenbpm-vanillabp-adapter.wiki` (`master`), and `builds` gains
   `{ "repo": "zenbpm-vanillabp-adapter", "mvn-goal": "compile" }` after the platform. A missing
   source repository is skipped silently by the tooling.
5. Skills (open question 8): draft the two changes as uncommitted edits in the workspace, where
   agents working there read them at once. In
   `.claude/skills/vanillabp-bpms-characteristics/SKILL.md` replace the "ZenBPM (future)" section
   and the cheat-sheet column with the facts of `analysis/01-zenbpm-capabilities.md` (remote, REST +
   gRPC stream, at-least-once, job lock per subscription and extendable (E13.1), no listeners, no
   signals, no tenant, `use-prefix` default, owned by pbinitiative) and replace "Decided: built on
   the PEA adapter" with decision 1's outcome; in `vanillabp-adapter-building` add
   `zenbpm-vanillabp-adapter` to the repository list with its organisation and groupId and mention
   the raw-XML model type as the third shape next to Camunda's model and PEA's bytes. The skills
   live in the superproject, so the edits stay local like the rest of this story.

**Acceptance criteria**

- [ ] `git status` of the superproject shows no new tracked path and no gitlink for either
  pbinitiative repository; `git -C zenbpm-vanillabp-adapter pull` advances the adapter on `main`.
- [ ] The local `.gitmodules` names `main` for both pbinitiative entries.
- [ ] `zenbpm-vanillabp-adapter.wiki/` is checked out and ignored by the superproject.
- [ ] Where the devcontainer config was changed, it builds the adapter after the platform (verify by
  reading the config; a spawn is optional).
- [ ] Both skill changes are drafted locally; the "built on PEA" sentence is gone or marked
  superseded in the local copy.

---

## F1.3 GitHub workflows from the first commit

The repository lives at `pbinitiative`, builds against snapshots published by `vanillabp`, and tests
against an engine image published by `pbinitiative`. Three things therefore have to be proven before
the first Java class: the pull-request check can read VanillaBP's snapshots, it can run Docker, and
`main` publishes what a consumer and a badge read. The workflows are shaped further in E4 (Docker ITs
appear), E11 (nightly and native), E12 (release) and E13 (a trigger from the engine's CI).

### S1.3.1 Pull-request and main check

- [ ] **Depends on:** S1.1.1 (a POM to build).

**Instructions**

1. `.github/workflows/settings.xml` (Maven settings, committed), shaped like
   `camunda8-adapter/.github/workflows/github-packages-settings.xml`: an active profile with
   `central` plus two snapshot-only repository entries, `vanillabp-adapter-platform-integration`
   (`https://maven.pkg.github.com/vanillabp/adapter-platform-integration`: adapter SPI, both
   platform integrations, `test-utils`) and `vanillabp-spi-for-java`
   (`https://maven.pkg.github.com/vanillabp/spi-for-java`), and one `<server>` per entry with
   `${env.VANILLABP_PACKAGES_USER}` / `${env.VANILLABP_PACKAGES_TOKEN}`, so
   `io.vanillabp:*:2.0.0-SNAPSHOT` resolves. One entry per repository, not a `vanillabp/*` wildcard:
   that is the form the Camunda 8 CI proves every day. GitHub Packages needs a token even for public
   packages, and only a CLASSIC personal access token: fine-grained tokens are refused by the Maven
   registry. A classic token with nothing but `read:packages`, of ANY GitHub account, works (open
   question 16 asks the VanillaBP project whether a dedicated read-only account should be provided;
   until then a maintainer's own PAT is stored as the two repository secrets
   `VANILLABP_PACKAGES_USER` and `VANILLABP_PACKAGES_TOKEN`).
2. `.github/workflows/checks.yaml`, `on: [pull_request, push: {branches: [main]},
   workflow_dispatch]`, `concurrency` per ref cancelling in-progress runs on pull requests only (a
   commit on `main` keeps its result), `permissions: contents: read`. One job `build` on
   `ubuntu-latest` (Docker is available there) with `timeout-minutes: 45`: `actions/checkout@v7`
   with `persist-credentials: false`, `actions/setup-java@v6` (Temurin 25.0.4, `cache: maven`; the
   classes are compiled with `--release 21`, as in the VanillaBP repositories),
   `docker/login-action` for `ghcr.io` with the workflow's `GITHUB_TOKEN` (pulls of the public
   engine image stay under the rate limit), then `mvn -B -s .github/workflows/settings.xml
   --update-snapshots install` (this runs Spotless `check`, unit tests, the ITs once E4 adds them,
   and the coverage gate). The package token is handed to that step only. A pull request from a fork
   gets no secrets; there the job builds `spi-for-java` and `adapter-platform-integration` from
   source (`install -DskipTests`) and runs the build without the settings file. On failure upload
   `**/target/surefire-reports`, `**/target/failsafe-reports`, `**/target/site/jacoco*` and
   `test-coverage-report/*/report` as the artifact `test-reports` (`actions/upload-artifact@v7`,
   `if-no-files-found: warn`), the way `process-engine-api-adapter` does. The same job runs a second
   time on Temurin 21 (`build on Java 21`, not required), because compiling with `--release 21` does
   not prove that the dependencies run on 21. A second job `workflow-lint` runs `actionlint` over
   the workflows, which Spotless does not read.
3. Branch protection on `main` requires the `build` check (documented in the README's "Contributing"
   section; the setting itself is done in the repository settings by a maintainer).
4. The README gets a build badge for `checks.yaml`.

**Acceptance criteria**

- [ ] A pull request with the S1.1.1 skeleton is green on a runner with an empty Maven cache,
  without building the VanillaBP snapshots from source. The log cannot show the downloads (the build
  runs with `--no-transfer-progress`), but no `io.vanillabp` `2.0.0-SNAPSHOT` exists on Maven
  Central, so such a run can only have read them from `maven.pkg.github.com` with the token.
- [ ] The fork path (no package token) is green: proven by a pull request from a fork.
- [ ] A deliberately misformatted file on a branch turns the check red at the Spotless step.
- [ ] The failure artifact is uploaded on a red run (prove it once with the misformatted branch plus a
  failing test).

### S1.3.2 Snapshot publication and coverage pages

- [ ] **Depends on:** S1.3.1.

**Instructions**

1. `.github/workflows/publish-snapshots.yaml`, `on: push: {branches: [main]}` and
   `workflow_dispatch`,
   `permissions: {contents: read, packages: write, pages: write, id-token: write}`: build as in
   S1.3.1, then `mvn -B -s .github/workflows/settings.xml deploy -DskipTests` to
   `https://maven.pkg.github.com/pbinitiative/zenbpm-vanillabp-adapter` (the
   `distributionManagement` of the root POM names it; the `GITHUB_TOKEN` authenticates through a
   second `<server id="github">` in the same settings file), then publish
   `test-coverage-report/spring-boot/report` and the Quarkus twin (the `outputDirectory` of both
   report POMs, not `target/site`) to GitHub
   Pages as `spring-boot-report/` and `quarkus-report/` (`actions/upload-pages-artifact` +
   `actions/deploy-pages`, Pages source "GitHub Actions").
2. The README gets the two coverage badges reading
   `https://pbinitiative.github.io/zenbpm-vanillabp-adapter/spring-boot-report/index.html` and
   `.../quarkus-report/index.html` with the regex of the Camunda 8 badges.
3. Consumers of the snapshot need the same kind of token for `pbinitiative`'s packages; the README's
   coordinates section says so and shows the `settings.xml` snippet.

**Acceptance criteria**

- [ ] After a push to `main`, `zenbpm-vanillabp-adapter-parent:2.0.0-SNAPSHOT` is listed under the
  repository's Packages and both report pages answer.
- [ ] The badges render on the README.

---

## F1.2 Engine test infrastructure

### S1.2.1 Pin the engine contract and start it from a test

- [ ] **Depends on:** S1.1.1.

**Instructions**

1. Take the pin (open question 9): the newest commit of the engine's `main` at the time this story
   runs, not a release tag. `v1.8.0` (2026-09-14) predates E13.1 (engine commit `071460cc`,
   2026-09-23: lock per subscription, lock extension, `lock_until`), which the adapter requires
   (decision 15), and E13.3 (job retries) is about to be merged to `main` as well; never pin
   `v1.8.0` or older. The engine's CI publishes every `main` commit as the MOVING tag
   `ghcr.io/pbinitiative/zenbpm:dev` (`release-dev.yaml`), so the pin is that image's digest, taken
   together with the commit it was built from:

   ```bash
   docker pull ghcr.io/pbinitiative/zenbpm:dev
   docker inspect --format '{{index .RepoDigests 0}}' ghcr.io/pbinitiative/zenbpm:dev
   docker inspect --format '{{index .Config.Labels "org.opencontainers.image.revision"}}' \
     ghcr.io/pbinitiative/zenbpm:dev
   ```

The revision label is the commit; check that it is the head of `origin/main` (a commit whose
`release-dev` run was cancelled by a newer push has no image, so take the newest one which has).
Write both ONCE in the root POM (S1.1.1 left them out) and add `zenbpm.engine=${zenbpm.commit}` to
`adapter-zenbpm.properties`: `zenbpm.commit` = the full 40-character commit and `zenbpm.image` =
`ghcr.io/pbinitiative/zenbpm@sha256:<digest>` (no tag in front of the `@`: Testcontainers'
`DockerImageName` refuses `name:tag@digest`). Moving the pin later repeats these steps and step 2 in
one commit. When the engine tags a release containing the pinned commit, the pin becomes that tag
(S12.4.1 does it at the latest).
2. Copy `openapi/api.yaml` and `pkg/zenclient/proto/zenbpm.proto` of exactly that commit
   (`git -C zenbpm show <commit>:openapi/api.yaml`, not the working tree) to
   `core/src/main/zenbpm/api.yaml` and `core/src/main/proto/zenbpm.proto`, each with a header line
   naming the commit, its date and the image digest. These copies ARE the contract the adapter is
   written against (decision 3).
3. New module `engine-test-support` (artifact `zenbpm-vanillabp-adapter-engine-test-support`, listed
   in the coverage gate's exceptions as a test-only module) holding `EngineUnderTest`: a
   Testcontainers `GenericContainer` on the image, env `REST_API_ADDR=:8080`, `GRPC_API_ADDR=:9090`,
   `CLUSTER_RAFT_BOOTSTRAP_EXPECT=1`, `POLL_TIMER_DELAY_SECONDS=1`,
   `PERSISTENCE_INSTANCE_HISTORY_TTL=0`, exposed ports 8080 and 9090, wait strategy HTTP
   `/system/health/ready` = 200, and accessors `restAddress()`, `grpcAddress()`. Read the image from
   a filtered `zenbpm-engine.properties` (`engine.image=${zenbpm.image}`), never from a literal
   (Camunda 8's `camunda8-cluster.properties` pattern). Provide `EngineLog` which attaches a log
   consumer at DEBUG only, so a failing test can print the engine's log through
   `SuppressOutputExtension`.
4. A `logback-test.xml` template quieting `org.testcontainers`, `tc`, `com.github.dockerjava` at WARN,
   to be copied into every module with ITs.
5. One IT in `engine-test-support` itself: `EngineUnderTestIT` boots the container and asserts
   `/system/health/ready` answers 200 and that `git.commitId` of `/system/status` (the engine
   reports the commit shortened) is a prefix of `zenbpm.commit`. Not `build.version`: on `main` it
   names the last release's `VERSION` and cannot tell two `main` builds apart.
   `@Testcontainers(disabledWithoutDocker = true)`, `SuppressOutputExtension` FIRST.

**Acceptance criteria**

- [ ] `mvn install` with Docker runs the IT green; without Docker it is skipped, not failed.
- [ ] The image in the log of the IT is `zenbpm.image`, the commit the engine reports is
  `zenbpm.commit`; no test file contains a commit, digest or version.
- [ ] `api.yaml` and `zenbpm.proto` are present with their provenance header, taken from
  `zenbpm.commit`.
- [ ] README section "Supported engine version" names the commit and the digest, says "tested, not
  newer", and says that the pin is a `main` build until the engine tags a release containing it.

### S1.2.2 Generate the gRPC stubs from the pinned proto

- [ ] **Depends on:** S1.2.1.

**Instructions**

1. In `core/pom.xml` add `io.github.ascopes:protobuf-maven-plugin` (or `org.xolstice`'s, whichever
   the Quarkus BOM plays with; verify a Quarkus build of `quarkus/runtime` still resolves the
   generated classes) generating Java and gRPC stubs from `src/main/proto/zenbpm.proto` into
   `target/generated-sources/protobuf`, package `org.pbinitiative.zenbpmadapter.client.grpc` (set
   `option java_package` in the copied proto; the header names this as the one deliberate edit).
2. Spotless excludes generated sources; JaCoCo excludes
   `org/pbinitiative/zenbpmadapter/client/grpc/**` (the report would otherwise count unused stub
   methods as missed).
3. A unit test `ZenBpmGrpcStubsTest` asserting the stub class `ZenBpmGrpc` has the `JobStream`
   method descriptor (proves the generation ran, and fails when the proto is replaced by one which
   renamed it).

**Acceptance criteria**

- [ ] `mvn install` compiles the stubs without a locally installed `protoc`.
- [ ] `mvn spotless:check` ignores the generated code.
- [ ] The coverage gate does not count stub classes.
