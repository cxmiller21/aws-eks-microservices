# # IAM Policy to attach to the EKS cluster role
# data "aws_iam_policy_document" "eks_elb_assume_role" {
#   statement {
#     actions = ["sts:AssumeRoleWithWebIdentity"]

#     principals {
#       type        = "Federated"
#       identifiers = ["${module.eks.oidc_provider_arn}"]
#     }

#     condition {
#       test     = "StringEquals"
#       variable = "${replace(module.eks.oidc_provider, "arn:aws:iam::${local.account_id}:", "")}:sub"
#       values = [
#         "system:serviceaccount:kube-system:aws-load-balancer-controller"
#       ]
#     }

#     condition {
#       test     = "StringEquals"
#       variable = "${replace(module.eks.oidc_provider, "arn:aws:iam::${local.account_id}:", "")}:aud"
#       values = [
#         "sts.amazonaws.com"
#       ]
#     }
#   }
# }

# resource "aws_iam_role" "eks_elb_role" {
#   name               = "${local.project_prefix}-eks-elb-role"
#   assume_role_policy = data.aws_iam_policy_document.eks_elb_assume_role.json
# }

# # Policy for EKS ALB Ingress Controller
# # https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
# resource "aws_iam_policy" "eks_elb_policy" {
#   name        = "${local.project_prefix}-eks-elb-policy"
#   path        = "/"
#   description = "AWS EKS ELB Policy"

#   policy = <<EOF
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Effect": "Allow",
#             "Action": [
#                 "iam:CreateServiceLinkedRole"
#             ],
#             "Resource": "*",
#             "Condition": {
#                 "StringEquals": {
#                     "iam:AWSServiceName": "elasticloadbalancing.amazonaws.com"
#                 }
#             }
#         },
#         {
#             "Effect": "Allow",
#             "Action": [
#                 "ec2:DescribeAccountAttributes",
#                 "ec2:DescribeAddresses",
#                 "ec2:DescribeAvailabilityZones",
#                 "ec2:DescribeInternetGateways",
#                 "ec2:DescribeVpcs",
#                 "ec2:DescribeVpcPeeringConnections",
#                 "ec2:DescribeSubnets",
#                 "ec2:DescribeSecurityGroups",
#                 "ec2:DescribeInstances",
#                 "ec2:DescribeNetworkInterfaces",
#                 "ec2:DescribeTags",
#                 "ec2:GetCoipPoolUsage",
#                 "ec2:DescribeCoipPools",
#                 "elasticloadbalancing:DescribeLoadBalancers",
#                 "elasticloadbalancing:DescribeLoadBalancerAttributes",
#                 "elasticloadbalancing:DescribeListeners",
#                 "elasticloadbalancing:DescribeListenerCertificates",
#                 "elasticloadbalancing:DescribeSSLPolicies",
#                 "elasticloadbalancing:DescribeRules",
#                 "elasticloadbalancing:DescribeTargetGroups",
#                 "elasticloadbalancing:DescribeTargetGroupAttributes",
#                 "elasticloadbalancing:DescribeTargetHealth",
#                 "elasticloadbalancing:DescribeTags"
#             ],
#             "Resource": "*"
#         },
#         {
#             "Effect": "Allow",
#             "Action": [
#                 "cognito-idp:DescribeUserPoolClient",
#                 "acm:ListCertificates",
#                 "acm:DescribeCertificate",
#                 "iam:ListServerCertificates",
#                 "iam:GetServerCertificate",
#                 "waf-regional:GetWebACL",
#                 "waf-regional:GetWebACLForResource",
#                 "waf-regional:AssociateWebACL",
#                 "waf-regional:DisassociateWebACL",
#                 "wafv2:GetWebACL",
#                 "wafv2:GetWebACLForResource",
#                 "wafv2:AssociateWebACL",
#                 "wafv2:DisassociateWebACL",
#                 "shield:GetSubscriptionState",
#                 "shield:DescribeProtection",
#                 "shield:CreateProtection",
#                 "shield:DeleteProtection"
#             ],
#             "Resource": "*"
#         },
#         {
#             "Effect": "Allow",
#             "Action": [
#                 "ec2:AuthorizeSecurityGroupIngress",
#                 "ec2:RevokeSecurityGroupIngress"
#             ],
#             "Resource": "*"
#         },
#         {
#             "Effect": "Allow",
#             "Action": [
#                 "ec2:CreateSecurityGroup"
#             ],
#             "Resource": "*"
#         },
#         {
#             "Effect": "Allow",
#             "Action": [
#                 "ec2:CreateTags"
#             ],
#             "Resource": "arn:aws:ec2:*:*:security-group/*",
#             "Condition": {
#                 "StringEquals": {
#                     "ec2:CreateAction": "CreateSecurityGroup"
#                 },
#                 "Null": {
#                     "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
#                 }
#             }
#         },
#         {
#             "Effect": "Allow",
#             "Action": [
#                 "ec2:CreateTags",
#                 "ec2:DeleteTags"
#             ],
#             "Resource": "arn:aws:ec2:*:*:security-group/*",
#             "Condition": {
#                 "Null": {
#                     "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
#                     "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
#                 }
#             }
#         },
#         {
#             "Effect": "Allow",
#             "Action": [
#                 "ec2:AuthorizeSecurityGroupIngress",
#                 "ec2:RevokeSecurityGroupIngress",
#                 "ec2:DeleteSecurityGroup"
#             ],
#             "Resource": "*",
#             "Condition": {
#                 "Null": {
#                     "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
#                 }
#             }
#         },
#         {
#             "Effect": "Allow",
#             "Action": [
#                 "elasticloadbalancing:CreateLoadBalancer",
#                 "elasticloadbalancing:CreateTargetGroup"
#             ],
#             "Resource": "*",
#             "Condition": {
#                 "Null": {
#                     "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
#                 }
#             }
#         },
#         {
#             "Effect": "Allow",
#             "Action": [
#                 "elasticloadbalancing:CreateListener",
#                 "elasticloadbalancing:DeleteListener",
#                 "elasticloadbalancing:CreateRule",
#                 "elasticloadbalancing:DeleteRule"
#             ],
#             "Resource": "*"
#         },
#         {
#             "Effect": "Allow",
#             "Action": [
#                 "elasticloadbalancing:AddTags",
#                 "elasticloadbalancing:RemoveTags"
#             ],
#             "Resource": [
#                 "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
#                 "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
#                 "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
#             ],
#             "Condition": {
#                 "Null": {
#                     "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
#                     "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
#                 }
#             }
#         },
#         {
#             "Effect": "Allow",
#             "Action": [
#                 "elasticloadbalancing:AddTags",
#                 "elasticloadbalancing:RemoveTags"
#             ],
#             "Resource": [
#                 "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
#                 "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
#                 "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
#                 "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
#             ]
#         },
#         {
#             "Effect": "Allow",
#             "Action": [
#                 "elasticloadbalancing:AddTags"
#             ],
#             "Resource": [
#                 "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
#                 "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
#                 "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
#             ],
#             "Condition": {
#                 "StringEquals": {
#                     "elasticloadbalancing:CreateAction": [
#                         "CreateTargetGroup",
#                         "CreateLoadBalancer"
#                     ]
#                 },
#                 "Null": {
#                     "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
#                 }
#             }
#         },
#         {
#             "Effect": "Allow",
#             "Action": [
#                 "elasticloadbalancing:ModifyLoadBalancerAttributes",
#                 "elasticloadbalancing:SetIpAddressType",
#                 "elasticloadbalancing:SetSecurityGroups",
#                 "elasticloadbalancing:SetSubnets",
#                 "elasticloadbalancing:DeleteLoadBalancer",
#                 "elasticloadbalancing:ModifyTargetGroup",
#                 "elasticloadbalancing:ModifyTargetGroupAttributes",
#                 "elasticloadbalancing:DeleteTargetGroup"
#             ],
#             "Resource": "*",
#             "Condition": {
#                 "Null": {
#                     "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
#                 }
#             }
#         },
#         {
#             "Effect": "Allow",
#             "Action": [
#                 "elasticloadbalancing:RegisterTargets",
#                 "elasticloadbalancing:DeregisterTargets"
#             ],
#             "Resource": "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
#         },
#         {
#             "Effect": "Allow",
#             "Action": [
#                 "elasticloadbalancing:SetWebAcl",
#                 "elasticloadbalancing:ModifyListener",
#                 "elasticloadbalancing:AddListenerCertificates",
#                 "elasticloadbalancing:RemoveListenerCertificates",
#                 "elasticloadbalancing:ModifyRule"
#             ],
#             "Resource": "*"
#         },
#                 {
#             "Effect": "Allow",
#             "Action": [
#                 "ec2:CreateTags",
#                 "ec2:DeleteTags"
#             ],
#             "Resource": "arn:aws:ec2:*:*:security-group/*",
#             "Condition": {
#                 "Null": {
#                     "aws:ResourceTag/ingress.k8s.aws/cluster": "false"
#                 }
#             }
#         },
#         {
#             "Effect": "Allow",
#             "Action": [
#                 "elasticloadbalancing:AddTags",
#                 "elasticloadbalancing:RemoveTags",
#                 "elasticloadbalancing:DeleteTargetGroup"
#             ],
#             "Resource": [
#                 "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
#                 "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
#                 "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
#             ],
#             "Condition": {
#                 "Null": {
#                     "aws:ResourceTag/ingress.k8s.aws/cluster": "false"
#                 }
#             }
#         }
#     ]
# }
# EOF
# }

# # Policy for EKS EBS CSI Driver
# # https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/docs/example-iam-policy.json
# resource "aws_iam_policy" "eks_worker_node_group_policy" {
#   name        = "${local.project_prefix}-eks-worker-node-group-policy"
#   path        = "/"
#   description = "AWS EKS Worker Node Group Policy"

#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#         {
#             "Effect": "Allow",
#             "Action": [
#               "s3:*"
#             ],
#             "Resource": [
#                 "arn:aws:s3:::${local.project_prefix}-loki-bucket",
#                 "arn:aws:s3:::${local.project_prefix}-loki-bucket/*",
#                 "arn:aws:s3:::${local.project_prefix}-otel-tempo-bucket",
#                 "arn:aws:s3:::${local.project_prefix}-otel-tempo-bucket/*",
#                 "arn:aws:s3:::${local.project_prefix}-mimir-bucket",
#                 "arn:aws:s3:::${local.project_prefix}-mimir-bucket/*"
#             ]
#         },
#         {
#             "Effect": "Allow",
#             "Action": [
#               "dynamodb:*"
#             ],
#             "Resource": [
#               "arn:aws:dynamodb:${var.region}:${local.account_id}:table/*"
#             ]
#         },
#         {
#             "Effect": "Allow",
#             "Action": [
#               "ec2:*"
#             ],
#             "Resource": [
#               "arn:aws:ec2:${var.region}:${local.account_id}:*"
#             ]
#         }
#   ]
# }
# EOF
# }

# # Policy for EKS EBS CSI Driver
# # https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/docs/example-iam-policy.json
# resource "aws_iam_policy" "eks_ebs_csi_policy" {
#   name        = "${local.project_prefix}-eks-ebs-csi-policy"
#   path        = "/"
#   description = "AWS EKS EBS CSI Policy"

#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "ec2:CreateSnapshot",
#         "ec2:AttachVolume",
#         "ec2:DetachVolume",
#         "ec2:ModifyVolume",
#         "ec2:DescribeAvailabilityZones",
#         "ec2:DescribeInstances",
#         "ec2:DescribeSnapshots",
#         "ec2:DescribeTags",
#         "ec2:DescribeVolumes",
#         "ec2:DescribeVolumesModifications"
#       ],
#       "Resource": "*"
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "ec2:CreateTags"
#       ],
#       "Resource": [
#         "arn:aws:ec2:*:*:volume/*",
#         "arn:aws:ec2:*:*:snapshot/*"
#       ],
#       "Condition": {
#         "StringEquals": {
#           "ec2:CreateAction": [
#             "CreateVolume",
#             "CreateSnapshot"
#           ]
#         }
#       }
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "ec2:DeleteTags"
#       ],
#       "Resource": [
#         "arn:aws:ec2:*:*:volume/*",
#         "arn:aws:ec2:*:*:snapshot/*"
#       ]
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "ec2:CreateVolume"
#       ],
#       "Resource": "*",
#       "Condition": {
#         "StringLike": {
#           "aws:RequestTag/ebs.csi.aws.com/cluster": "true"
#         }
#       }
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "ec2:CreateVolume"
#       ],
#       "Resource": "*",
#       "Condition": {
#         "StringLike": {
#           "aws:RequestTag/CSIVolumeName": "*"
#         }
#       }
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "ec2:DeleteVolume"
#       ],
#       "Resource": "*",
#       "Condition": {
#         "StringLike": {
#           "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
#         }
#       }
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "ec2:DeleteVolume"
#       ],
#       "Resource": "*",
#       "Condition": {
#         "StringLike": {
#           "ec2:ResourceTag/CSIVolumeName": "*"
#         }
#       }
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "ec2:DeleteVolume"
#       ],
#       "Resource": "*",
#       "Condition": {
#         "StringLike": {
#           "ec2:ResourceTag/kubernetes.io/created-for/pvc/name": "*"
#         }
#       }
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "ec2:DeleteSnapshot"
#       ],
#       "Resource": "*",
#       "Condition": {
#         "StringLike": {
#           "ec2:ResourceTag/CSIVolumeSnapshotName": "*"
#         }
#       }
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "ec2:DeleteSnapshot"
#       ],
#       "Resource": "*",
#       "Condition": {
#         "StringLike": {
#           "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
#         }
#       }
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_role_policy_attachment" "eks_elb" {
#   role       = aws_iam_role.eks_elb_role.name
#   policy_arn = aws_iam_policy.eks_elb_policy.arn
# }

# resource "aws_iam_role_policy_attachment" "eks_ebs_csi" {
#   role       = aws_iam_role.eks_elb_role.name
#   policy_arn = aws_iam_policy.eks_ebs_csi_policy.arn
# }
