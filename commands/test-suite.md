---
description: Run the cass end-to-end test suite — discovers all test cases under tests/, runs them in parallel (runner + verifier per case), and prints a final report
argument-hint: "[test-subfolder — omit to run everything]"
allowed-tools: [Bash]
model: haiku
---

Run the suite:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/tools/run-suite.sh" ${ARGUMENTS}
```

Print the full output exactly as returned. Do not summarise or reformat it.
