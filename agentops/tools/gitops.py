import re
import subprocess

from tools.remediation import DEPLOYMENT_FILE, REPO_ROOT
from tools.validation import validate_readiness_probe_change


def _run_git(*args):
    result = subprocess.run(
        ["git", *args],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
    )

    return result


def prepare_readiness_fix(new_port: int):
    validation = validate_readiness_probe_change(new_port)

    if not validation.get("valid"):
        return {
            "prepared": False,
            "reason": "Validation failed.",
            "validation": validation,
            "production_changed": False,
        }

    status = _run_git("status", "--porcelain")

    if status.returncode != 0:
        return {
            "prepared": False,
            "reason": status.stderr.strip(),
            "production_changed": False,
        }

    if status.stdout.strip():
        return {
            "prepared": False,
            "reason": (
                "Repository has uncommitted changes. "
                "Refusing to modify a dirty working tree."
            ),
            "production_changed": False,
        }

    branch_name = f"agent/readiness-port-{new_port}"

    branch = _run_git(
        "checkout",
        "-b",
        branch_name,
    )

    if branch.returncode != 0:
        return {
            "prepared": False,
            "reason": branch.stderr.strip(),
            "production_changed": False,
        }

    content = DEPLOYMENT_FILE.read_text()

    pattern = (
        r"(readinessProbe:\s*\n"
        r"\s+httpGet:\s*\n"
        r"\s+path:\s*[^\n]+\n"
        r"\s+port:\s*)(\d+)"
    )

    match = re.search(pattern, content)

    if not match:
        return {
            "prepared": False,
            "reason": "Readiness probe port could not be found.",
            "production_changed": False,
        }

    current_port = int(match.group(2))

    modified = re.sub(
        pattern,
        lambda m: f"{m.group(1)}{new_port}",
        content,
        count=1,
    )

    DEPLOYMENT_FILE.write_text(modified)

    add = _run_git(
        "add",
        str(DEPLOYMENT_FILE.relative_to(REPO_ROOT)),
    )

    if add.returncode != 0:
        return {
            "prepared": False,
            "reason": add.stderr.strip(),
            "production_changed": False,
        }

    commit = _run_git(
        "commit",
        "-m",
        f"fix: set readiness probe port to {new_port}",
    )

    if commit.returncode != 0:
        return {
            "prepared": False,
            "reason": commit.stderr.strip(),
            "production_changed": False,
        }

    commit_sha = _run_git(
        "rev-parse",
        "--short",
        "HEAD",
    )

    return {
        "prepared": True,
        "branch": branch_name,
        "commit": commit_sha.stdout.strip(),
        "previous_port": current_port,
        "new_port": new_port,
        "validation": validation,
        "pushed": False,
        "pull_request_created": False,
        "production_changed": False,
        "next_action": "Human approval required before push/PR.",
    }