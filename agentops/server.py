from mcp.server import MCPServer
from tools.kubernetes import get_cluster_health, list_pods

mcp = MCPServer("AgentOps")


@mcp.tool()
def cluster_health():
    """
    Return Kubernetes cluster health.
    """
    return get_cluster_health()


if __name__ == "__main__":

@mcp.tool()
def pods(namespace: str):
    """
    List all pods in a namespace.
    """
    return list_pods(namespace)
    mcp.run()