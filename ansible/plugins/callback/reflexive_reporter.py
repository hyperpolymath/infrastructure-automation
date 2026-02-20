# SPDX-License-Identifier: PMPL-1.0-or-later
# Reflexive Reporter — Ansible Callback Plugin
#
# This plugin implements the REFLEXIVE design principle:
# the system observes and records its own state transitions.
#
# Every task execution is logged with:
#   - What changed (or didn't)
#   - On which host
#   - At what time
#   - With what result
#
# The system's audit trail IS its self-knowledge.
#
# Usage: Enabled automatically via ansible.cfg callback_plugins setting.
# Output: /tmp/ansible-reflexive-report.json

from __future__ import annotations

import json
import os
from datetime import datetime, timezone

from ansible.plugins.callback import CallbackBase

DOCUMENTATION = """
  name: reflexive_reporter
  type: notification
  short_description: Records all state transitions for reflexive self-inspection
  version_added: "1.0.0"
  description:
    - Implements the reflexive design principle by recording every
      state transition during playbook execution.
    - Produces a JSON report at /tmp/ansible-reflexive-report.json
      that the system can query to understand its own history.
  author: Jonathan D.A. Jewell
"""

REPORT_PATH = os.environ.get(
    "ANSIBLE_REFLEXIVE_REPORT",
    "/tmp/ansible-reflexive-report.json",
)


class CallbackModule(CallbackBase):
    """Reflexive reporter: the system records its own state transitions."""

    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = "notification"
    CALLBACK_NAME = "reflexive_reporter"
    CALLBACK_NEEDS_ENABLED = True

    def __init__(self):
        super().__init__()
        self.report = {
            "meta": {
                "tool": "ansible",
                "plugin": "reflexive_reporter",
                "description": "Self-inspection report — the system's record of its own changes",
                "generated_at": None,
                "playbook": None,
            },
            "summary": {
                "total_tasks": 0,
                "changed": 0,
                "ok": 0,
                "failed": 0,
                "skipped": 0,
                "unreachable": 0,
            },
            "transitions": [],
        }

    def _timestamp(self):
        return datetime.now(timezone.utc).isoformat()

    def _record(self, status, result, **kwargs):
        host = result._host.get_name() if result._host else "unknown"
        task = result._task.get_name() if result._task else "unknown"

        entry = {
            "timestamp": self._timestamp(),
            "host": host,
            "task": task,
            "status": status,
            "changed": result._result.get("changed", False),
        }

        if status == "failed":
            entry["msg"] = result._result.get("msg", "")

        entry.update(kwargs)
        self.report["transitions"].append(entry)
        self.report["summary"]["total_tasks"] += 1
        self.report["summary"][status] = self.report["summary"].get(status, 0) + 1

    def v2_playbook_on_start(self, playbook):
        self.report["meta"]["playbook"] = str(playbook._file_name)
        self.report["meta"]["generated_at"] = self._timestamp()

    def v2_runner_on_ok(self, result, **kwargs):
        status = "changed" if result._result.get("changed", False) else "ok"
        self._record(status, result)

    def v2_runner_on_failed(self, result, ignore_errors=False, **kwargs):
        self._record("failed", result, ignored=ignore_errors)

    def v2_runner_on_skipped(self, result, **kwargs):
        self._record("skipped", result)

    def v2_runner_on_unreachable(self, result, **kwargs):
        self._record("unreachable", result)

    def v2_playbook_on_stats(self, stats):
        self.report["meta"]["completed_at"] = self._timestamp()

        try:
            with open(REPORT_PATH, "w") as f:
                json.dump(self.report, f, indent=2)
            self._display.display(
                f"\n[reflexive] Report written to {REPORT_PATH} "
                f"({self.report['summary']['total_tasks']} tasks, "
                f"{self.report['summary'].get('changed', 0)} changes)",
                color="cyan",
            )
        except OSError as e:
            self._display.warning(f"[reflexive] Could not write report: {e}")
