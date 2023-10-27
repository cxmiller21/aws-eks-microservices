# Roadmap

## Priorities

- Handle EKS cluster deletion (Lambda function or through Terraform)
- Verify ArgoCD application YAML file - deployment and link an app to a repo
- Create Google Microservice application for ArgoCD to link to
- Separate Grafana and ArgoCD TF `./terraform/eks` --> `./terraform/eks-apps`
- Add auth to sign into kubernetes dashboard
- Recreate Grafana resources as an ArgoCD Application

## Repository Management

- [ ] Create project diagrams with draw.io
  - [x] High level project diagram showing main components (`./docs/images/eks-demo-high-level.png`)
  - [ ] AWS EKS cluster - Auth, EC2/Fargate, ALBs, Logging, Monitoring, Grafana, etc
  - [ ] Online Boutique application - Show how pods interact with EKS, Grafana, S3, alerting
    - [ ] Copy GKE image to repo
  - [ ] Diagrams are saved in the `./docs/diagrams` directory
  - [ ] Diagrams are referenced in the README.md
- [ ] Organize project folder/file structure
  - [ ] Sort helm, kubernetes, and release folders
- [ ] Revise readme format for AWS CodeCommit (it's not loading html correctly)
- [ ] Decouple Grafana and ArgoCD TF into their own folders for easier management

## Misc

- [ ] Confirm permissions that are needed for AWS EKS cluster to assume role in Org account for ArgoCD application to link to CodeCommit repo
  - [ ] Create new repo in sandbox for ArgoCD to pull from?

## Terraform

- [ ] Automate EKS cluster deletion with a Lambda function (Spin down resources each night and **MANUALLY** spin them back up in the morning)
- [x] Validate project spins up successfully with Terraform
- x ] Validate EKS cluster logging and monitoring
  - [x] Grafana collects logs and metrics and stores them in S3
  - [x] Logs and metrics and are viewable in Grafana dashboards
- [ ] Remove Grafana from Terraform management
- [ ] Recreate Grafana resources as an ArgoCD Application

## EKS

- [ ] Review EKS security best practices
- [ ] Review EKS cluster sizing best practices
- [ ] Review EKS cluster logging and monitoring best practices
- [ ] Review EKS compute taints and tolerations to ensure pods are scheduled on the correct nodes to follow K8 best practices
- [ ] Add auth (oauth?) to sign into kubernetes dashboard
- [ ] Add a cost optimization tool like kube cost

## CI/CD

- [ ] Create GitHub Actions workflow to build and push Docker images to ECR
- [ ] Create GitHub Actions workflow to deploy Terraform changes
- [ ] Create GitHub Actions workflow to deploy Kubernetes changes

- [ ] Set up EC2 instance with GitLab to run CI/CD pipelines to avoid Code* apps??

## ArgoCD

- [ ] Create ArgoCD application to deploy Online Boutique application
- [ ] Create ArgoCD application to deploy Grafana (LGTM) dashboards
- [ ] Review notification options for ArgoCD
- [ ] Track [DORA metrics](https://thenewstack.io/4-ways-to-measure-your-software-delivery-performance/) for the Online Boutique application
  - [ ] Deployment Frequency
  - [ ] Lead Time for Changes
  - [ ] Mean Time to Recovery
  - [ ] Change Failure Rate
