import sys
from pathlib import Path

import yaml


def valid_port(port):
    if isinstance(port, str):
        # Named Kubernetes ports are valid.
        return True

    return isinstance(port, int) and 1 <= port <= 65535


def check_container(container, resource_name):
    errors = []

    for port in container.get("ports", []):
        container_port = port.get("containerPort")

        if container_port is not None and not valid_port(container_port):
            errors.append(
                f"{resource_name}: invalid containerPort {container_port}"
            )

    for probe_name in ("readinessProbe", "livenessProbe", "startupProbe"):
        probe = container.get(probe_name, {})
        http_get = probe.get("httpGet", {})

        if "port" in http_get and not valid_port(http_get["port"]):
            errors.append(
                f"{resource_name}: {probe_name} has invalid port "
                f"{http_get['port']}"
            )

    security_context = container.get("securityContext", {})

    if security_context.get("privileged") is True:
        errors.append(
            f"{resource_name}: privileged containers are not permitted"
        )

    return errors


def main():
    if len(sys.argv) != 2:
        print("Usage: policy_check.py <rendered-yaml>")
        sys.exit(2)

    path = Path(sys.argv[1])

    with path.open() as file:
        resources = list(yaml.safe_load_all(file))

    errors = []

    for resource in resources:
        if not resource:
            continue

        metadata = resource.get("metadata", {})
        name = metadata.get("name", "unknown")

        spec = resource.get("spec", {})

        if spec.get("hostNetwork") is True:
            errors.append(f"{name}: hostNetwork is not permitted")

        pod_spec = None

        if resource.get("kind") == "Pod":
            pod_spec = spec

        elif resource.get("kind") in {
            "Deployment",
            "StatefulSet",
            "DaemonSet",
            "ReplicaSet",
        }:
            pod_spec = (
                spec
                .get("template", {})
                .get("spec", {})
            )

        if not pod_spec:
            continue

        for container in pod_spec.get("containers", []):
            errors.extend(check_container(container, name))

    if errors:
        print("POLICY CHECK FAILED")
        for error in errors:
            print(f"- {error}")

        sys.exit(1)

    print("POLICY CHECK PASSED")


if __name__ == "__main__":
    main()