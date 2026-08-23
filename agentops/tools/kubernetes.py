from kubernetes import client, config


def get_cluster_health():
    config.load_kube_config()

    v1 = client.CoreV1Api()

    nodes = v1.list_node().items

    result = {
        "total_nodes": len(nodes),
        "ready_nodes": 0,
        "not_ready_nodes": [],
    }

    for node in nodes:
        node_name = node.metadata.name

        ready_condition = next(
            (
                condition
                for condition in node.status.conditions
                if condition.type == "Ready"
            ),
            None,
        )

        if ready_condition and ready_condition.status == "True":
            result["ready_nodes"] += 1
        else:
            result["not_ready_nodes"].append(node_name)

    return result