provider "aws" {
  region  = local.region
  profile = "aws-eks-demo"
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}
data "aws_region" "current" {}

locals {
  account_id     = data.aws_caller_identity.current.account_id
  region         = "us-east-1"
  project_prefix = "${local.name}-${terraform.workspace}"
  # s3_bucket_name = "${local.project_prefix}-${local.region}-${local.account_id}"

  ssm_parameter_prefix = replace(replace(local.project_prefix, "aws-", ""), "-", "_") # replace(local.project_prefix, "aws-", "")

  cluster_version = "1.28"

  # EKS Node Group Settings
  eks_managed_node_instance_types    = ["t3.small"]
  eks_worker_node_group_min_size     = 1
  eks_worker_node_group_max_size     = 3
  eks_worker_node_group_desired_size = 3
  eks_worker_node_group_disk_size    = 8

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
}

################################################################################
# EKS Module
################################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true

  # IPV4
  cluster_ip_family = "ipv4"

  cluster_addons = {
    kube-proxy = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
    # Might need to remove and re-add this addon
    # the cert-manager resources are a pre-req for the adot addon
    # kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.yaml
    # adot = {
    #   # most_recent = true
    #   addon_version = "v0.76.1-eksbuild.1"
    # }
    vpc-cni = {
      most_recent              = true
      before_compute           = true
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  manage_aws_auth_configmap = true

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = local.eks_managed_node_instance_types

    # We are using the IRSA created below for permissions
    # However, we have to deploy with the policy attached FIRST (when creating a fresh cluster)
    # and then turn this off after the cluster/node group is created. Without this initial policy,
    # the VPC CNI fails to assign IPs and nodes cannot join the cluster
    # See https://github.com/aws/containers-roadmap/issues/1666 for more context
    iam_role_attach_cni_policy = true

    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      EksEbsCsi                    = aws_iam_policy.eks_ebs_csi_policy.arn
      EksWorkerNodeGroupPolicy     = aws_iam_policy.eks_worker_node_group_policy.arn
    }
  }

  ########################################
  # Fargate
  ########################################
    # Fargate profiles use the cluster primary security group so these are not utilized
  # create_cluster_security_group = false
  # create_node_security_group    = false

  # fargate_profile_defaults = {
  #   iam_role_additional_policies = {
  #     additional = aws_iam_policy.additional.arn
  #   }
  # }

  # fargate_profiles = merge(
  #   {
  #     example = {
  #       name = "example"
  #       selectors = [
  #         {
  #           namespace = "backend"
  #           labels = {
  #             Application = "backend"
  #           }
  #         },
  #         {
  #           namespace = "app-*"
  #           labels = {
  #             Application = "app-wildcard"
  #           }
  #         }
  #       ]

  #       # Using specific subnets instead of the subnets supplied for the cluster itself
  #       subnet_ids = [module.vpc.private_subnets[1]]

  #       tags = {
  #         Owner = "secondary"
  #       }

  #       timeouts = {
  #         create = "20m"
  #         delete = "20m"
  #       }
  #     }
  #   },
  #   { for i in range(3) :
  #     "kube-system-${element(split("-", local.azs[i]), 2)}" => {
  #       selectors = [
  #         { namespace = "kube-system" }
  #       ]
  #       # We want to create a profile per AZ for high availability
  #       subnet_ids = [element(module.vpc.private_subnets, i)]
  #     }
  #   }
  # )
  ########################################

  eks_managed_node_groups = {
    worker_node_group = {
      min_size      = local.eks_worker_node_group_min_size
      max_size      = local.eks_worker_node_group_max_size     # 4
      desired_size  = local.eks_worker_node_group_desired_size # 3
      disk_size     = local.eks_worker_node_group_disk_size    # 8
      capacity_type = "ON_DEMAND"
    }
  }

  aws_auth_accounts = [
    local.account_id
  ]

  aws_auth_users = [
    {
      # Allows an IAM user access to view resources in the EKS cluster from the AWS console
      # without this, in AWS console --> EKS --> Cluster --> Resources (etc), the user will see "Access Denied"
      userarn  = "arn:aws:iam::${local.account_id}:role/${var.federated_role_name}"
      username = "admin"
      groups   = ["system:masters"]
    },
  ]

  tags = local.tags

  # depends_on = [
  #   module.vpc,
  # ]
}

################################################################################
# Supporting Resources
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
  intra_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 52)]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  enable_ipv6            = false
  create_egress_only_igw = true

  # public_subnet_ipv6_prefixes                    = [0, 1, 2]
  # public_subnet_assign_ipv6_address_on_creation  = true
  # private_subnet_ipv6_prefixes                   = [3, 4, 5]
  # private_subnet_assign_ipv6_address_on_creation = true
  # intra_subnet_ipv6_prefixes                     = [6, 7, 8]
  # intra_subnet_assign_ipv6_address_on_creation   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}

module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix      = "VPC-CNI-IRSA"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true
  vpc_cni_enable_ipv6   = false

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = local.tags
}

################################################################################
# Tags for the ASG to support cluster-autoscaler scale up from 0
################################################################################

locals {

  # We need to lookup K8s taint effect from the AWS API value
  taint_effects = {
    NO_SCHEDULE        = "NoSchedule"
    NO_EXECUTE         = "NoExecute"
    PREFER_NO_SCHEDULE = "PreferNoSchedule"
  }

  cluster_autoscaler_label_tags = merge([
    for name, group in module.eks.eks_managed_node_groups : {
      for label_name, label_value in coalesce(group.node_group_labels, {}) : "${name}|label|${label_name}" => {
        autoscaling_group = group.node_group_autoscaling_group_names[0],
        key               = "k8s.io/cluster-autoscaler/node-template/label/${label_name}",
        value             = label_value,
      }
    }
  ]...)

  cluster_autoscaler_taint_tags = merge([
    for name, group in module.eks.eks_managed_node_groups : {
      for taint in coalesce(group.node_group_taints, []) : "${name}|taint|${taint.key}" => {
        autoscaling_group = group.node_group_autoscaling_group_names[0],
        key               = "k8s.io/cluster-autoscaler/node-template/taint/${taint.key}"
        value             = "${taint.value}:${local.taint_effects[taint.effect]}"
      }
    }
  ]...)

  cluster_autoscaler_asg_tags = merge(local.cluster_autoscaler_label_tags, local.cluster_autoscaler_taint_tags)
}

resource "aws_autoscaling_group_tag" "cluster_autoscaler_label_tags" {
  for_each = local.cluster_autoscaler_asg_tags

  autoscaling_group_name = each.value.autoscaling_group

  tag {
    key   = each.value.key
    value = each.value.value

    propagate_at_launch = false
  }
}
# */
