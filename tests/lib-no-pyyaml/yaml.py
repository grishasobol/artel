"""Stand-in for PyYAML on a development host without it, used only by tests/*.sh: the test configs are written in
JSON, and every JSON document is a YAML document, so the same file is read by the real module where it exists."""
import json


def safe_load(text):
    return json.loads(text) if text.strip() else None
