import subprocess
import tempfile
from pathlib import Path

from tools.remediation import DEPLOYMENT_FILE, REPO_ROOT


CHART_DIR = REPO_ROOT / "helm" / "eks-app"


def validate_readiness_probe_change(new_port: int):

    if not 1 <= new_port <= 65535:

        return {

            "valid": False,

            "reason": "Policy violation: port must be between 1 and 65535.",

            "production_changed": False,

        }

    original = DEPLOYMENT_FILE.read_text()
    original = DEPLOYMENT_FILE.read_text()

    modified = original.replace(
        "port: 9999",
        f"port: {new_port}",
        1,
    )

    with tempfile.TemporaryDirectory() as tmpdir:
        temp_chart = Path(tmpdir) / "eks-app"

        subprocess.run(
            ["cp", "-R", str(CHART_DIR), str(temp_chart)],
            check=True,
        )

        temp_deployment = (
            temp_chart / "templates" / "deployment.yaml"
        )

        temp_deployment.write_text(modified)

        lint = subprocess.run(
            ["helm", "lint", str(temp_chart)],
            capture_output=True,
            text=True,
        )

        template = subprocess.run(
            ["helm", "template", "eks-app", str(temp_chart)],
            capture_output=True,
            text=True,
        )

        valid = (
            lint.returncode == 0
            and template.returncode == 0
        )

        return {
            "valid": valid,
            "helm_lint": {
                "passed": lint.returncode == 0,
                "output": lint.stdout + lint.stderr,
            },
            "helm_template": {
                "passed": template.returncode == 0,
                "output": template.stderr,
            },
            "production_changed": False,
        }