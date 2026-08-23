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

        if unhealthy:
            unhealthy_pods.append(
                {
                    "name": pod["name"],
                    "details": details,
                    "events": get_pod_events(
                        pod["name"],
                        namespace,
                    ),
                    "logs": get_pod_logs(
                        pod["name"],
                        namespace,
                        tail_lines=50,
                    ),
                }
            )
        else:
            healthy_count += 1

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
        issues.append("ArgoCD application is unhealthy")

    if unhealthy_pods:
        issues.append(
            f"{len(unhealthy_pods)} unhealthy pod(s) detected"
        )

    if total_restarts > 0:
        issues.append(
            f"{total_restarts} container restart(s) detected"
        )

    overall_status = "Healthy" if not issues else "NeedsAttention"

    return {
        "application": app_name,
        "namespace": namespace,
        "overall_status": overall_status,
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
        "unhealthy_pods": unhealthy_pods,
    }