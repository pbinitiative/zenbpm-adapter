#!/usr/bin/env bash
#
# Copyright (c) 2026 Process Builders Initiative
# SPDX-License-Identifier: MIT
#
# Proves what publish-snapshots.yaml relies on, without GitHub and without credentials:
#
#   1. A green build deploys exactly the published artifacts: the parent, the core, the Spring
#      Boot module and the two Quarkus modules. Nothing of the test, report or gate modules.
#   2. A red coverage gate deploys nothing at all, although every module before the gate built.
#
# Both runs work on a copy of the working tree (tracked and modified files) and deploy into a
# directory of their own. Neither installs into the local Maven repository, so the untested
# method of the second run never reaches ~/.m2. PublicationSafetyTest checks on every build that
# the settings this rests on are still there; run this script after changing anything about
# deploying, the module order or the gate. It needs spi-for-java and adapter-platform-integration
# in the local Maven repository, like any build here, and takes two full builds.
set -euo pipefail

root="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

copy_working_tree() {
  local target="$1"
  mkdir -p "$target"
  (cd "$root" && git ls-files -z --cached --others --exclude-standard | xargs -0 cp --parents --target-directory="$target")
}

deploy() {
  local source="$1" destination="$2" log="$3"
  (cd "$source" && mvn --batch-mode --no-transfer-progress \
    -Dmaven.install.skip=true \
    -DaltDeploymentRepository="github::file://$destination" \
    deploy) > "$log" 2>&1
}

expected="zenbpm-vanillabp-adapter
zenbpm-vanillabp-adapter-parent
zenbpm-vanillabp-adapter-quarkus
zenbpm-vanillabp-adapter-quarkus-deployment
zenbpm-vanillabp-adapter-spring-boot"

echo "1/2 green build: deploys exactly the published artifacts"
copy_working_tree "$work/green-source"
if ! deploy "$work/green-source" "$work/green" "$work/green.log"; then
  tail -40 "$work/green.log"
  echo "FAILED: the green build did not succeed, see the log above" >&2
  exit 1
fi
deployed="$(ls "$work/green/org/pbinitiative/zenbpm" | sort)"
if [ "$deployed" != "$expected" ]; then
  echo "FAILED: the green build deployed" >&2
  echo "$deployed" >&2
  echo "instead of" >&2
  echo "$expected" >&2
  exit 1
fi
echo "    ok: $(echo "$deployed" | tr '\n' ' ')"

echo "2/2 red coverage gate: deploys nothing"
copy_working_tree "$work/red-source"
cat > "$work/red-source/core/src/main/java/org/pbinitiative/zenbpmadapter/UntestedProbe.java" <<'JAVA'
/*
 * Copyright (c) 2026 Process Builders Initiative
 * SPDX-License-Identifier: MIT
 */
package org.pbinitiative.zenbpmadapter;

/**
 * Written by bin/check-deploy-safety.sh into a copy of the repository: code no test covers.
 */
public final class UntestedProbe {

  private UntestedProbe() {
  }

  /**
   * Never called by a test.
   *
   * @return always true
   */
  public static boolean isNeverTested() {
    return true;
  }

}
JAVA
if deploy "$work/red-source" "$work/red" "$work/red.log"; then
  echo "FAILED: the build with an untested method passed the coverage gate" >&2
  exit 1
fi
if ! grep -q "coverage gate | Spring Boot: 0.00 %" "$work/red.log"; then
  tail -40 "$work/red.log"
  echo "FAILED: the build failed, but not at the coverage gate, see the log above" >&2
  exit 1
fi
if [ -n "$(find "$work/red" -type f 2>/dev/null)" ]; then
  echo "FAILED: a red coverage gate left artifacts deployed:" >&2
  find "$work/red" -type f >&2
  exit 1
fi
echo "    ok: the gate failed and nothing was deployed"
