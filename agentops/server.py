from mcp.server import MCPServer
from tools.kubernetes import (
    get_cluster_health,
    list_pods,
    get_pod_logs,
    describe_pod,
    get_pod_events,
)

from tools.argocd import (
    get_argocd_app_health,
    list_argocd_apps,
)

from tools.prometheus import query_prometheus

from tools.investigation import investigate_application

from tools.remediation import propose_readiness_probe_port_fix
from tools.validation import validate_readiness_probe_change

mcp = MCPServer("AgentOps")


@mcp.tool()
def cluster_health():
    """
    Return Kubernetes cluster health.
    """
    return get_cluster_health()


@mcp.tool()
def pods(namespace: str):
    """
    List all pods in a namespace.
    """
    return list_pods(namespace)


@mcp.tool()
def pod_logs(name: str, namespace: str, tail_lines: int = 100):
    """
    Return recent logs for a Kubernetes pod.
    """
    return get_pod_logs(name, namespace, tail_lines)

@mcp.tool()
def pod_details(name: str, namespace: str):
    """
    Return detailed health and runtime information for a Kubernetes pod.
    """
    return describe_pod(name, namespace)

@mcp.tool()
def pod_events(name: str, namespace: str):
    """
    Return Kubernetes events associated with a pod.
    """
    return get_pod_events(name, namespace)

@mcp.tool()
def argocd_app_health(app_name: str):
    """
    Return ArgoCD sync and health status for an application.
    """
    return get_argocd_app_health(app_name)

@mcp.tool()
def argocd_apps():
    """
    List ArgoCD applications and flag unhealthy or out-of-sync apps.
    """
    return list_argocd_apps()

@mcp.tool()
def prometheus_query(query: str):
    """
    Run a read-only Prometheus instant query and return the result.
    """
    return query_prometheus(query)

@mcp.tool()
def investigate_app(app_name: str, namespace: str):
    """
    Investigate an application using ArgoCD, Kubernetes, and Prometheus data.
    Returns concise health context and expands into logs/events only when issues are detected.
    """
    return investigate_application(app_name, namespace)

@mcp.tool()
def propose_readiness_fix(new_port: int):
    """
    Propose a readiness probe port change.
    This does not modify files, Git, ArgoCD, or Kubernetes.
    """
    return propose_readiness_probe_port_fix(new_port)


@mcp.tool()
def validate_readiness_fix(new_port: int):
    """
    Validate a proposed readiness probe port change using
    policy checks and Helm validation without changing production.
    """
    return validate_readiness_probe_change(new_port)


if __name__ == "__main__":
    mcp.run()