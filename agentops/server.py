from mcp.server import MCPServer
from tools.kubernetes import (
    get_cluster_health,
    list_pods,
    get_pod_logs,
    describe_pod,
    get_pod_events,
)

from tools.argocd import get_argocd_app_health

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


if __name__ == "__main__":
    mcp.run()