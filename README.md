<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a name="readme-top"></a>


<!-- PROJECT LOGO -->
<br />
<div align="center">
  <!-- <a href="https://github.com/othneildrew/Best-README-Template">
    <img src="images/logo.png" alt="Logo" width="80" height="80">
  </a> -->

  <h3 align="center">AWS EKS Microservice Application</h3>

  <!-- <p align="center">
    Placeholder note/brief description
  </p> -->
</div>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

![EKS Project Diagram (TODO build diagram)][product-screenshot]

Project details

<p align="right">(<a href="#readme-top">back to top</a>)</p>



### Built With

* [![Python][Python.py]][Python-url]
  * [![Java][Java.java]][Java-url] (Application alternative/incomplete example)
* [![EKS][EKS.aws]][EKS-url]
* [![ECR][ECR.aws]][ECR-url]
* [![OpenTelemetry][OpenTelemetry.aws]][OpenTelemetry-url]
* [![S3][S3.aws]][S3-url]
* [![SNS][SNS.aws]][SNS-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Getting Started

This is an example of how you may give instructions on setting up your project locally.
To get a local copy up and running follow these simple example steps.

### Prerequisites

This is an example of how to list things you need to use the software and how to install them.
* AWS Account - [Sign up](https://aws.amazon.com/free)
  * [Create User](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html)
  * [Configure Credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
* AWS CLI - [Install steps](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* Terraform - [Install steps](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
* Python - [Install steps](https://www.python.org/downloads/)
  * Macs can use `brew install python`
* Docker - [Install steps](https://docs.docker.com/get-docker/)
* Kind - [Install steps](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)

### Getting Started

#### Locally

1. Clone the repo
   ```sh
   git clone https://github.com/cxmiller21/aws-eks-microservices.git
   ```
2. Create the Kind Kubernetes cluster
   ```sh
   # Creates a local Kubernetes cluster using Docker containers
   # Creates the Grafa LGTM (Loki, Grafana, Tempo, and Mimir/Prometheus - aka "Looks Good to Me") Stack
   ./scripts/create-kind-cluster.sh
   ```
3. Create Online Boutique microservices application in the Kind cluster
   ```sh
   # View Grafana at 127.0.0.1:3000 (username: admin, password: prom-operator)
   # Start online-boutique application
   kubectl apply -f ./kubernetes/local/online-boutique.yaml
   # Expose the application via a NodePort
   kubectl port-forward service/frontend-service 8080:8080 -n online-boutique
   ```
4. Cleanup
   ```sh
   kind get clusters # List clusters (should be names demo-cluster)
   kind delete cluster --name demo-cluster
   ```

#### Deploy to AWS EKS
1. Clone the repo
   ```sh
   git clone https://github.com/cxmiller21/aws-eks-microservices.git
   ```
2. Create Terraform AWS Resources (~20 minutes)
   ```sh
   cd ./terraform
   terraform init
   terraform plan # Confirm resources
   terraform apply # Enter `yes` when prompted
   ```
3. Allow local connections to EKS cluster (if not done already)
   ```sh
   # Add the EKS Cluster to the ~/.kube/conf file to execute local kubectl commands
   aws eks --region us-east-1 update-kubeconfig --name eks-microservices-default
   ```
4. Install the AWS ALB Controller in the EKS Cluster (run from project root)
   ```sh
   ./scripts/install-eks-alb-controller.sh
   ```
5. Install Prometheus and Grafana via Helm (TBD)
   ```sh
    # Install the Grafana LGTM (Loki, Grafana, Tempo, and Mimir/Prometheus - aka "Looks Good to Me") Stack
    ./scripts/install-grafana-lgtm-stack.sh
    # View the Grafana dashboard via the AWS Load Balancer DNS address
    ```
6.  Create the Online Boutique microservices application in the EKS Cluster (run from project root)
   ```sh
   ./scripts/install-online-boutique.sh
   ```
7. View the "Online Boutique" from the ALB URL output in the previous step and start shopping!

Congrats! The project is now up and running!

### Grafana Dashboards

#### Data Sources

1. Add the Loki data source
   1. Name: `Loki`
   2. Type: `Loki`
   3. URL: `http://loki-distributed-gateway.monitoring.svc.cluster.local:80`
   4. Access: `Server`
   5. Save & Test
2. Add the Tempo data source
   1. Name: `Tempo`
   2. Type: `Tempo`
   3. URL: `http://tempo-query-frontend.monitoring.svc.cluster.local:3100`
   4. Access: `Server`
   5. Trace to Logs
      1. datasource: `Loki`
      2. spanEndTimeShift: `5m`
      3. Tags: `http.status as http_status`, `component as ""`
      4. Custom query: `{${__tags}}|="${__trace.traceId}"`
   6. Service graph: Prometheus data source
   7. Save & Test
3. Add the Mimir data source
   1. Name: `Mimir`
   2. Type: `Prometheus`
   3. URL: `http://mimir-nginx.monitoring.svc:80/prometheus`
   4. Access: `Server`
   5. Save & Test

#### Dashboards

1. View the Grafana dashboard via the AWS Load Balancer DNS address
2. Add new dashboards to view Loki logs and Tempo traces (Dashboards --> New --> Import)
   1. [Loki stack monitoring (Promtail, Loki)](https://grafana.com/grafana/dashboards/14055-loki-stack-monitoring-promtail-loki/) Dashboard ID: 14055
   2. [Loki Logs/App](https://grafana.com/grafana/dashboards/13639-logs-app/) Dashboard ID: 13639

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- USAGE EXAMPLES -->
## Usage

Examples TBD

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ROADMAP -->
## Roadmap

- [ ] Validate EKS cluster logging and monitoring
- [ ] Create AWS EKS cluster with Terraform and validate logging, monitoring, and tracing
- [ ] Create AWS EKS cluster diagram that shows key Cluster components (Auth, ALBs, Logging, Monitoring, and Tracing)
- [ ] Create diagram that shows the Online Boutique microservices application components

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTACT -->
<!-- ## Contact

Crow Manufacturing - [@crow_manufacturing](https://twitter.com/crow_manufacturing) - thebestturntables@crowmanufacturing.com


<p align="right">(<a href="#readme-top">back to top</a>)</p> -->



<!-- ACKNOWLEDGMENTS -->
<!-- ## Acknowledgments

The following resources were used to help build out this project:

* [AWS Kinesis Producer - KPL Java Sample Application](https://github.com/awslabs/amazon-kinesis-producer/tree/master/java/amazon-kinesis-producer-sample)
* [othneildrew Best-README-Template](https://github.com/othneildrew/Best-README-Template)

<p align="right">(<a href="#readme-top">back to top</a>)</p> -->



<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[product-screenshot]: images/product-screenshot.png
[Python.py]: https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white
[Python-url]: https://www.python.org/
[EKS.aws]: https://img.shields.io/badge/AWS%20EKS-4A4A55?style=for-the-badge&logo=amazonaws&logoColor=FF3E00
[EKS-url]: https://aws.amazon.com/eks/
[ECR.aws]: https://img.shields.io/badge/AWS%20ECR-4A4A55?style=for-the-badge&logo=amazonaws&logoColor=FF3E00
[ECR-url]: https://aws.amazon.com/ecr/
[AWSMG.aws]: https://img.shields.io/badge/AWS%Grafana-4A4A55?style=for-the-badge&logo=amazonaws&logoColor=FF3E00
[AWSMG-url]: https://aws.amazon.com/grafana/
[AWSPM.aws]: https://img.shields.io/badge/AWS%20Prometheus-4A4A55?style=for-the-badge&logo=amazonaws&logoColor=FF3E00
[AWSPM-url]: https://aws.amazon.com/prometheus/
[OpenTelemetry.aws]: https://img.shields.io/badge/OpenTelemetry-4A4A55?style=for-the-badge&logo=amazonaws&logoColor=FF3E00
[OpenTelemetry-url]: https://aws.amazon.com/opentelemetry/
[S3.aws]: https://img.shields.io/badge/AWS%20S3-4A4A55?style=for-the-badge&logo=amazonaws&logoColor=FF3E00
[S3-url]: https://aws.amazon.com/s3/
[SNS.aws]: https://img.shields.io/badge/AWS%20SNS-4A4A55?style=for-the-badge&logo=amazonaws&logoColor=FF3E00
[SNS-url]: https://aws.amazon.com/sns/

