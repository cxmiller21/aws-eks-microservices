"""
Delete EKS ALB Ingress Controller and security groups
to allow for a successful Terraform destroy.

NEEDS TO BE TESTED!!!
"""
import boto3
import subprocess

EKS_SG_PREFIX = "tbd"
ec2 = boto3.client("ec2")


def run_subprocess(cmd: str) -> None:
    """
    Run a subprocess
    """
    split_cmd = cmd.split(" ")
    subprocess.run(split_cmd)


def get_aws_eks_sg_ids():
    """
    Get the EKS EC2 security groups
    """
    response = ec2.describe_security_groups(
        Filters=[
            {
                "Name": "group-name",
                "Values": [
                    "eksctl-eks-cluster-addon-iamserviceaccount-dc-aws-alb-ingress-controller",
                ],
            },
        ]
    )
    return response["SecurityGroups"]


def delete_aws_sgs(sg_ids: list[str]) -> None:
    """
    Delete the EKS EC2 security groups
    """
    for sg in sg_ids:
        print(f"Deleting security group {sg}")
        ec2.delete_security_group(GroupId=sg)


def remove_eks_ingress_finalizers() -> None:
    """
    Remove finalizer from ALB Ingress Controller
    """
    # run subprocess to remove finalizers
    prefix = "kubectl patch ing"
    suffix = '-p \'{"metadata":{"finalizers":null}}\' --type=merge'
    argocd_cmd = f"{prefix} -n argocd ingress-argocd {suffix}"
    grafana_cmd = f"{prefix} -n monitoring ingress-grafana {suffix}"
    run_subprocess(argocd_cmd)
    run_subprocess(grafana_cmd)


def main():
    eks_ingress_sg_ids = get_aws_eks_sg_ids(EKS_SG_PREFIX)
    print(f"Deleting AWS SG IDs: {eks_ingress_sg_ids}")
    delete_aws_sgs(eks_ingress_sg_ids)

    print("Removing finalizers from ALB Ingress Controller")
    remove_eks_ingress_finalizers()


if __name__ == "__main__":
    main()
