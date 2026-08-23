from tools.argocd import get_argocd_app_health
from tools.kubernetes import (
    list_pods,
    describe_pod,
    get_pod_logs,
    get_pod_events,
)
from tools.prometheus import query_prometheus


def investigate_application(app_name: str, namespace: str):
    argocd = get_argocd_app_health(app_name)
    pods = list_pods(namespace)

    unhealthy_pods = []
    healthy_count = 0
    findings = {}

    for pod in pods:
        details = describe_pod(pod["name"], namespace)

        unhealthy = (
            details["phase"] != "Running"
            or any(
                not container["ready"]
                or container["restart_count"] > 0
                for container in details["containers"]
            )
        )

        if not unhealthy:
            healthy_count += 1
            continue

        events = get_pod_events(pod["name"], namespace)
        logs = get_pod_logs(
            pod["name"],
            namespace,
            tail_lines=30,
        )

        unhealthy_pods.append(
            {
                "name": pod["name"],
                "details": details,
                "events": events,
                "logs": logs,
            }
        )

        for event in events:
            if event["type"] != "Warning":
                continue

            key = (
                event["reason"],
                _normalise_event_message(event["message"]),
            )

            if key not in findings:
                findings[key] = {
                    "severity": "warning",
                    "reason": event["reason"],
                    "message": _normalise_event_message(
                        event["message"]
                    ),
                    "affected_pods": [],
                }

            findings[key]["affected_pods"].append(pod["name"])

    restart_metrics = query_prometheus(
        f'sum(kube_pod_container_status_restarts_total{{namespace="{namespace}"}})'
    )

    total_restarts = 0

    if restart_metrics:
        total_restarts = int(float(restart_metrics[0]["value"][1]))

    issues = []

    if argocd["sync_status"] != "Synced":
        issues.append("ArgoCD application is out of sync")

    if argocd["health_status"] != "Healthy":
        issues.append(
            f"ArgoCD application health is {argocd['health_status']}"
        )

    if unhealthy_pods:
        issues.append(
            f"{len(unhealthy_pods)} unhealthy pod(s) detected"
        )

    if total_restarts > 0:
        issues.append(
            f"{total_restarts} container restart(s) detected"
        )

    representative = None

    if unhealthy_pods:
        first = unhealthy_pods[0]

        representative = {
            "pod": first["name"],
            "phase": first["details"]["phase"],
            "containers": first["details"]["containers"],
            "logs": first["logs"]["logs"],
        }

    return {
        "application": app_name,
        "namespace": namespace,
        "overall_status": (
            "Healthy" if not issues else "NeedsAttention"
        ),
        "argocd": {
            "sync_status": argocd["sync_status"],
            "health_status": argocd["health_status"],
            "revision": argocd["revision"],
        },
        "pods": {
            "total": len(pods),
            "healthy": healthy_count,
            "unhealthy": len(unhealthy_pods),
        },
        "restart_count": total_restarts,
        "issues": issues,
        "findings": list(findings.values()),
        "representative_evidence": representative,
    }


def _normalise_event_message(message: str):
    if not message:
        return ""

    if "Readiness probe failed" in message:
        if "connection refused" in message:
            return (
                "Readiness probe failed because the configured "
                "endpoint refused the connection"
            )

        return "Readiness probe failed"

    return message