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


def list_pods(namespace="default"):
    config.load_kube_config()

    v1 = client.CoreV1Api()
    pods = v1.list_namespaced_pod(namespace).items

    result = []

    for pod in pods:
        result.append(
            {
                "name": pod.metadata.name,
                "status": pod.status.phase,
                "node": pod.spec.node_name,
            }
        )

    return result


def get_pod_logs(name: str, namespace: str, tail_lines: int = 100):
    config.load_kube_config()

    v1 = client.CoreV1Api()

    logs = v1.read_namespaced_pod_log(
        name=name,
        namespace=namespace,
        tail_lines=tail_lines,
    )

    return {
        "pod": name,
        "namespace": namespace,
        "logs": logs,
    }

def describe_pod(name: str, namespace: str):
    config.load_kube_config()

    v1 = client.CoreV1Api()

    pod = v1.read_namespaced_pod(
        name=name.strip(),
        namespace=namespace.strip(),
    )

    containers = []

    for container_status in pod.status.container_statuses or []:
        containers.append(
            {
                "name": container_status.name,
                "ready": container_status.ready,
                "restart_count": container_status.restart_count,
                "image": container_status.image,
            }
        )

    conditions = []

    for condition in pod.status.conditions or []:
        conditions.append(
            {
                "type": condition.type,
                "status": condition.status,
                "reason": condition.reason,
                "message": condition.message,
            }
        )

    return {
        "name": pod.metadata.name,
        "namespace": pod.metadata.namespace,
        "phase": pod.status.phase,
        "node": pod.spec.node_name,
        "pod_ip": pod.status.pod_ip,
        "containers": containers,
        "conditions": conditions,
    }