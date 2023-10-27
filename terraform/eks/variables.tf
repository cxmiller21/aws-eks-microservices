variable "eks_worker_group_instance_type" {
  type    = string
  default = "t2.small"
}

variable "vpc_cidr" {
  type = string
  # default = "10.0.0.0/16"
  # Issue with Loki and EKS subnet addresses
  # https://github.com/grafana/helm-charts/issues/1584#issuecomment-1346109116
  default = "198.19.0.0/16"
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["198.19.1.0/24", "198.19.2.0/24", "198.19.3.0/24"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["198.19.4.0/24", "198.19.5.0/24", "198.19.6.0/24"]
}

variable "federated_role_name" {
  type        = string
  description = "SSO Federated Administrato Role Name"
  default = ""
}
