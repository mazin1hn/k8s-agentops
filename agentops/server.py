from mcp.server.fastmcp import FastMCP
from tools.kubernetes import get_cluster_health

mcp = FastMCP("AgentOps")


@mcp.tool()
def cluster_health():
    """
    Return Kubernetes cluster health.
    """
    return get_cluster_health()


if __name__ == "__main__":
    mcp.run()