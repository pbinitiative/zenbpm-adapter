/*
 * Copyright (c) 2026 Process Builders Initiative
 * SPDX-License-Identifier: MIT
 */
package org.pbinitiative.zenbpmadapter.coverage;

import static org.junit.jupiter.api.Assertions.fail;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;

import io.vanillabp.integration.test.utils.SuppressOutputExtension;

/**
 * Fails on purpose, so the check proves it uploads the reports of a red run. Never merged.
 */
@ExtendWith(SuppressOutputExtension.class)
public class RedRunProofTest {

  @Test
  public void failsOnPurpose() {

    fail("deliberate failure: the check has to attach this report as the artifact 'test-reports'");

  }

}
