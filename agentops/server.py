from mcp.server import MCPServer
from tools.kubernetes import get_cluster_health

mcp = MCPServer("AgentOps")


@mcp.tool()
def cluster_health():
    """
    Return Kubernetes cluster health.
    """
    return get_cluster_health()


if __name__ == "__main__":
    mcp.run()