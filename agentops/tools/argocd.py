from kubernetes import client, config


def get_argocd_app_health(app_name: str, namespace: str = "argocd"):
    config.load_kube_config()

    api = client.CustomObjectsApi()

    app = api.get_namespaced_custom_object(
        group="argoproj.io",
        version="v1alpha1",
        namespace=namespace.strip(),
        plural="applications",
        name=app_name.strip(),
    )

    status = app.get("status", {})

    return {
        "name": app.get("metadata", {}).get("name"),
        "sync_status": status.get("sync", {}).get("status"),
        "health_status": status.get("health", {}).get("status"),
        "revision": status.get("sync", {}).get("revision"),
        "message": status.get("operationState", {}).get("message"),
    }

def list_argocd_apps(namespace: str = "argocd"):
    config.load_kube_config()

    api = client.CustomObjectsApi()

    apps = api.list_namespaced_custom_object(
        group="argoproj.io",
        version="v1alpha1",
        namespace=namespace.strip(),
        plural="applications",
    )

    result = []

    for app in apps.get("items", []):
        status = app.get("status", {})
        name = app.get("metadata", {}).get("name")

        sync_status = status.get("sync", {}).get("status")
        health_status = status.get("health", {}).get("status")

        result.append(
            {
                "name": name,
                "sync_status": sync_status,
                "health_status": health_status,
                "needs_attention": (
                    sync_status != "Synced"
                    or health_status != "Healthy"
                ),
            }
        )

    return result