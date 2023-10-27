"""
Lambda function to find and delete running EKS clusters
that match a given name prefix.
"""
import boto3
import json
import logging
import os
import sleep

if len(logging.getLogger().handlers) > 0:
    logging.getLogger().setLevel(logging.INFO)
else:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    )

log = logging.getLogger(__name__)
log.info("Starting Lambda function")

EKS_CLUSTER_PREFIX = os.environ["EKS_CLUSTER_PREFIX"]
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]

sns = boto3.client("sns")
eks = boto3.client("eks")
rds = boto3.client("rds")

eks_cluster_waiter = eks.get_waiter('cluster_deleted')
eks_ng_waiter = eks.get_waiter('nodegroup_deleted')



def get_eks_demo_cluster(prefix: str) -> str:
    """Get the name of the EKS demo project cluster

    Returns:
      str: Name of the EKS demo project cluster OR empty string if not found
    """
    clusters = eks.list_clusters()["clusters"]
    log.info(f"Found {len(clusters)} EKS clusters")
    log.info(f"Clusters: {clusters}")
    demo_cluster = [c for c in clusters if c.startswith(prefix)]
    return demo_cluster[0] if demo_cluster else ""


def get_eks_node_groups(cluster_name: str) -> list:
    """Get the names of the EKS cluster's Node Groups

    Returns:
      list: List of Node Group names
    """
    node_groups = eks.list_nodegroups(clusterName=cluster_name)["nodegroups"]
    return node_groups


def delete_eks_node_groups(cluster_name: str, node_groups: list) -> None:
    """Delete the EKS cluster's Node Groups

    Args:
      cluster_name (str): Name of the EKS cluster
      node_groups (list): List of Node Group names
    """
    for node_group in node_groups:
        log.info(f"Deleting EKS node group: {node_group}")
        eks.delete_nodegroup(
            clusterName=cluster_name, nodegroupName=node_group
        )
        eks_ng_waiter.wait(
            clusterName=cluster_name,
            nodegroupName=node_group,
            WaiterConfig={
                'Delay': 10,
                'MaxAttempts': 30
            }
        )
    return None


def get_eks_demo_rds_instances(prefix: str) -> list:
    """Get the names of the RDS instances associated with the EKS demo project cluster

    Returns:
      list: List of RDS instance names that match the prefix
    """
    rds_instances = rds.describe_db_instances()["DBInstances"]
    log.info(f"Found {len(rds_instances)} RDS instances")
    log.info(f"RDS instances: {rds_instances}")
    demo_rds_instances = [
        r["DBInstanceIdentifier"]
        for r in rds_instances
        if r["DBInstanceIdentifier"].startswith(prefix)
    ]
    return demo_rds_instances


def lambda_handler(event, context):
    log.info(f"Checking for EKS clusters with prefix: {EKS_CLUSTER_PREFIX}")

    cluster_deleted = False
    rds_instances_deleted = False
    sns_message_sent = False

    demo_cluster = get_eks_demo_cluster(EKS_CLUSTER_PREFIX)
    if not demo_cluster:
        log.info("EKS demo project cluster not found. Nothing to delete")
    else:
        node_groups = get_eks_node_groups(demo_cluster)
        if node_groups:
          delete_eks_node_groups(demo_cluster, node_groups)
        log.info(f"EKS demo project cluster found: {demo_cluster}. Deleting...")
        log.info(f"Deleting EKS cluster: {demo_cluster}")

        eks.delete_cluster(name=demo_cluster)
        eks_cluster_waiter.wait(
            name=demo_cluster,
            WaiterConfig={
                'Delay': 10,
                'MaxAttempts': 30
            }
        )
        cluster_deleted = True

    rds_instances = get_eks_demo_rds_instances(EKS_CLUSTER_PREFIX)
    if not rds_instances:
        log.info("EKS demo project rds instances not found. Nothing to delete")
    else:
        log.info(f"EKS demo project rds instances found: {demo_cluster}. Deleting...")
        for rds_instance in rds_instances:
            log.info(f"Deleting RDS instance: {rds_instance}")
            # rds.delete_db_instance(
            #     DBInstanceIdentifier=rds_instance,
            #     SkipFinalSnapshot=True,
            #     DeleteAutomatedBackups=True,
            # )
        rds_instances_deleted = True

    results = {
        "cluster_deleted": cluster_deleted,
        "rds_instances_deleted": rds_instances_deleted,
        "sns_message_sent": sns_message_sent,
    }

    log.info(f"Sending SNS message to {SNS_TOPIC_ARN} with results: {results}")
    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject="AWS EKS Cleanup Lambda Results",
        Message=json.dumps(results),
    )
    results["sns_message_sent"] = True

    results = {
        "results": results,
        "status": "success",
    }
    return results
