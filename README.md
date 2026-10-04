# VanillaBP adapter for ZenBPM

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)

This is the [VanillaBP](https://www.vanillabp.io) adapter for the
[ZenBPM](https://github.com/pbinitiative/zenbpm) engine (VanillaBP Version 2). It lets a VanillaBP
business application run its workflows on a ZenBPM engine without the business code depending on
the ZenBPM API. It is owned by the ZenBPM maintainers at pbinitiative and follows the conventions
of the VanillaBP adapters.

This `README.md` is aimed at contributors. Users will find the documentation in the
[wiki](https://github.com/pbinitiative/zenbpm-vanillabp-adapter/wiki); the VanillaBP concepts it
builds on are documented in the [VanillaBP wiki](https://github.com/vanillabp/adapter-platform-integration/wiki).

## Status

**Skeleton.** The repository builds, measures coverage per platform and gates on it, but the
adapter does nothing yet. What is built next, and in which order, is the implementation plan in
[`docs/`](docs/README.md).

## Modules

|                Module                |                   Artifact                    |                                    Purpose                                    |
|--------------------------------------|-----------------------------------------------|-------------------------------------------------------------------------------|
| `core`                               | `zenbpm-vanillabp-adapter`                    | the platform-neutral adapter: deployment, task delivery, REST and gRPC client |
| `spring-boot`                        | `zenbpm-vanillabp-adapter-spring-boot`        | Spring Boot auto-configuration                                                |
| `smoke-test`                         | (not published)                               | discovery, health and startup validation on Spring Boot without an engine     |
| `quarkus/runtime`                    | `zenbpm-vanillabp-adapter-quarkus`            | Quarkus extension, runtime part                                               |
| `quarkus/deployment`                 | `zenbpm-vanillabp-adapter-quarkus-deployment` | Quarkus extension, build-time part                                            |
| `quarkus/integration-tests`          | (not published)                               | end-to-end tests on a booted Quarkus application                              |
| `test-coverage-report/spring-boot`   | (not published)                               | aggregated coverage of the core and the Spring Boot modules                   |
| `test-coverage-report/quarkus`       | (not published)                               | aggregated coverage of the core and the Quarkus modules                       |
| `test-coverage-report/coverage-gate` | (not published)                               | breaks the build below the coverage threshold, last module of the reactor     |

All artifacts have the groupId `org.pbinitiative.zenbpm`, the Java packages start with
`org.pbinitiative.zenbpmadapter`.

## Supported engine version

Not pinned yet. The adapter is tested against exactly one ZenBPM engine build and supports that
one, nothing newer; this section names it once the engine test infrastructure exists.

## Building

The build depends on two repositories of the VanillaBP project, which have to be in the local Maven
repository first, in this order:

1. [`spi-for-java`](https://github.com/vanillabp/spi-for-java) (`mvn install`)
2. [`adapter-platform-integration`](https://github.com/vanillabp/adapter-platform-integration)
   (`./mvnw install`)

Both are `2.0.0-SNAPSHOT` and VanillaBP publishes their snapshots to its GitHub Packages, so instead
of building them they can be resolved from there with a GitHub token which may read packages. Then:

```bash
mvn install
```

`install` and not `install verify`: install runs every phase verify has, so naming both walks the
lifecycle twice. Spotless checks the formatting in every build; `mvn spotless:apply` fixes it.

Working rules for this repository, for people and coding agents alike, are in
[`AGENTS.md`](./AGENTS.md). The decisions the code relies on are in [`DECISIONS.md`](./DECISIONS.md),
what the engine cannot do and how the adapter answers it in [`GAPS.md`](./GAPS.md).

## Test coverage

`mvn install` builds one aggregated JaCoCo report per platform:

1. **Spring Boot** (core + Spring Boot integration) - into `test-coverage-report/spring-boot/report`
2. **Quarkus** (core + Quarkus extension) - into `test-coverage-report/quarkus/report`

Coverage is measured separately per platform, because a platform's tests never cover the other
platform's code.

The build breaks below the line: `test-coverage-report/coverage-gate` is the last module of the
reactor, reads both reports and fails whenever a platform is below its threshold in the root POM
(`coverage.threshold.spring-boot`, `coverage.threshold.quarkus`, in percent of covered
instructions). Both properties hold 85, the number every VanillaBP adapter gates on, and that is not
the target: the rule is 90 per platform, so a report between 85 and 90 passes the build and still
names a gap. The gate also compares every module producing a `jacoco.exec` against the two
aggregates, so a module added to the build without being added to its report cannot stay
unnoticed. Both are `CoverageGateTest`. The conventions every test class of this repository follows
are checked by `TestClassConventionsTest`, and what the published POMs hand an application by
`PublishedPomsTest`.

The gate reports what it measured on every run, green ones included. The angle brackets stand for
the numbers of the run:

```
coverage gate | Spring Boot: <percent> % instructions (<missed> of <total> missed) | at the rule of 90 %
coverage gate | Quarkus: <percent> % instructions (<missed> of <total> missed) | <gap> points below the rule of 90 %, build breaks below 85 %
```

A report without a single instruction passes with the line
`no instruction to measure yet, so nothing can be below the threshold`, which is what the skeleton
prints today. A build which stops before `verify` never writes the reports; the gate then says that
the coverage was not checked, and those two tests are reported as skipped.

## Licence

This repository is licensed under the [MIT License](./LICENSE).

Parts of it are copied and adapted from the VanillaBP adapters
[`camunda8-adapter`](https://github.com/vanillabp/camunda8-adapter) and
[`process-engine-api-adapter`](https://github.com/vanillabp/process-engine-api-adapter), which are
licensed under the Apache License, Version 2.0. Those files keep that licence: each carries a header
naming its origin and `SPDX-License-Identifier: Apache-2.0`, the licence text is in
[`LICENSE-APACHE-2.0`](./LICENSE-APACHE-2.0), and [`NOTICE`](./NOTICE) names both origins. Every
other file is MIT. Decision 17 in [`DECISIONS.md`](./DECISIONS.md) says why.
