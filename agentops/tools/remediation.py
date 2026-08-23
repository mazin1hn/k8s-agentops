from pathlib import Path
from difflib import unified_diff
import re


REPO_ROOT = Path(__file__).resolve().parents[2]

DEPLOYMENT_FILE = (
    REPO_ROOT
    / "helm"
    / "eks-app"
    / "templates"
    / "deployment.yaml"
)
def propose_readiness_probe_port_fix(new_port: int):
    if not 1 <= new_port <= 65535:
        return {
            "allowed": False,
            "reason": "Port must be between 1 and 65535.",
        }

    if not DEPLOYMENT_FILE.exists():
        return {
            "allowed": False,
            "reason": "Deployment manifest does not exist.",
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
            "allowed": False,
            "reason": "Readiness probe port could not be found.",
        }

    current_port = int(match.group(2))

    if current_port == new_port:
        return {
            "allowed": False,
            "reason": f"Readiness probe already uses port {new_port}.",
        }

    proposed = re.sub(
        pattern,
        lambda m: f"{m.group(1)}{new_port}",
        content,
        count=1,
    )

    diff = "".join(
        unified_diff(
            content.splitlines(keepends=True),
            proposed.splitlines(keepends=True),
            fromfile=str(DEPLOYMENT_FILE),
            tofile=str(DEPLOYMENT_FILE),
        )
    )

    return {
        "allowed": True,
        "change_type": "readiness_probe_port",
        "file": str(DEPLOYMENT_FILE),
        "current_port": current_port,
        "proposed_port": new_port,
        "diff": diff,
        "action": "proposal_only",
        "requires_validation": True,
        "requires_human_approval": True,
    }