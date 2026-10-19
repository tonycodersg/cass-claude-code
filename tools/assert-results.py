#!/usr/bin/env python3
"""
tools/assert-results.py
Mechanical assertions against a test case's results.json + expected.json.

Usage:
  python3 tools/assert-results.py \
    --results  /tmp/cass-test-xxx/all-pass/results.json \
    --expected tests/doctor/all-pass/3-answers-and-expected/expected.json \
    --work-dir /tmp/cass-test-xxx/all-pass \
    --test-name "doctor — all-pass"

Exit 0 = all assertions pass.
Exit 1 = one or more assertions failed.
"""

from __future__ import annotations
import argparse
import json
import os
import sys

PASS = "\033[32m✓\033[0m"
FAIL = "\033[31m✗\033[0m"
SEP  = "─" * 49


def load_json(path: str, label: str) -> dict:
    try:
        with open(path) as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Error: {label} not found: {path}", file=sys.stderr)
        sys.exit(2)
    except json.JSONDecodeError as e:
        print(f"Error: {label} is not valid JSON: {e}", file=sys.stderr)
        sys.exit(2)


def assert_files(file_specs: list, work_dir: str) -> list[tuple[bool, str]]:
    results = []
    for spec in file_specs:
        path = spec.get("path", "")
        full = os.path.join(work_dir, path)
        exists_expected = spec.get("exists")
        contains_str = spec.get("contains")

        if exists_expected is not None:
            actual_exists = os.path.isfile(full)
            if exists_expected:
                ok = actual_exists
                msg = f"file exists: {path}"
                if not ok:
                    msg += "  (not found)"
            else:
                ok = not actual_exists
                msg = f"file absent: {path}"
                if not ok:
                    msg += "  (found but should not exist)"
            results.append((ok, msg))

        if contains_str is not None:
            if not os.path.isfile(full):
                results.append((False, f"file content check skipped — not found: {path}"))
            else:
                content = open(full).read()
                ok = contains_str in content
                msg = f"file {path} contains {contains_str!r}"
                if not ok:
                    msg += "  (string not found)"
                results.append((ok, msg))

    return results


def assert_output(output_spec: dict, text_response: str) -> list[tuple[bool, str]]:
    results = []
    for s in output_spec.get("contains", []):
        ok = s in text_response
        msg = f"output contains {s!r}"
        if not ok:
            msg += "  (not found)"
        results.append((ok, msg))
    for s in output_spec.get("not_contains", []):
        ok = s not in text_response
        msg = f"output does not contain {s!r}"
        if not ok:
            msg += "  (found but should not be present)"
        results.append((ok, msg))
    return results


def assert_tool_calls(tool_specs: list, tool_calls: list) -> list[tuple[bool, str]]:
    results = []
    for spec in tool_specs:
        tool_name = spec.get("tool", "")
        input_contains = spec.get("input_contains")
        count_expected = spec.get("count")

        matching = [
            tc for tc in tool_calls
            if tc.get("name", tc.get("tool", "")) == tool_name
        ]

        if count_expected is not None:
            ok = len(matching) == count_expected
            msg = f"tool {tool_name} called {count_expected}x  (actual: {len(matching)})"
            if not ok:
                msg = f"tool {tool_name} count mismatch: expected {count_expected}, got {len(matching)}"
            results.append((ok, msg))

        if input_contains is not None:
            found = any(
                input_contains in json.dumps(tc.get("input", tc.get("parameters", {})))
                for tc in matching
            )
            ok = found
            msg = f"tool {tool_name} input contains {input_contains!r}"
            if not ok:
                msg += "  (not found in any matching call)"
            results.append((ok, msg))

    return results


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--results",   required=True)
    parser.add_argument("--expected",  required=True)
    parser.add_argument("--work-dir",  required=True)
    parser.add_argument("--test-name", default="")
    args = parser.parse_args()

    results  = load_json(args.results,  "results.json")
    expected = load_json(args.expected, "expected.json")

    test_name    = args.test_name or results.get("test", "unknown")
    text_response = results.get("text_response", "")
    tool_calls   = results.get("tool_calls", [])
    debug_dir    = args.work_dir

    assertions: list[tuple[bool, str]] = []

    assertions += assert_files(expected.get("files", []), args.work_dir)
    assertions += assert_output(expected.get("output", {}), text_response)
    assertions += assert_tool_calls(expected.get("tool_calls", []), tool_calls)

    passed  = sum(1 for ok, _ in assertions if ok)
    failed  = sum(1 for ok, _ in assertions if not ok)
    all_ok  = failed == 0

    print(SEP)
    print(f"TEST: {test_name}")
    for ok, msg in assertions:
        mark = PASS if ok else FAIL
        print(f"  {mark}  {msg}")

    if all_ok:
        print(f"Result:    {PASS} pass")
    else:
        print(f"Result:    {FAIL} fail  ({failed} assertion(s) failed)")
        print(f"           Debug: {debug_dir}/")
    print(SEP)

    sys.exit(0 if all_ok else 1)


if __name__ == "__main__":
    main()
