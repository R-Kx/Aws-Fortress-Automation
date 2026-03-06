# 🛡️ AWS Fortress: DevSecOps Automated Infrastructure Platform

[![Terraform](https://img.shields.io/badge/Terraform-1.14+-623CE4.svg?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900.svg?logo=amazon-aws)](https://aws.amazon.com/)
[![Ansible](https://img.shields.io/badge/Ansible-SSM_Managed-EE0000.svg?logo=ansible)](https://www.ansible.com/)
[![Security](https://img.shields.io/badge/Security-tfsec_|_WAF-brightgreen.svg)]()

A highly available, strictly secured, and fully automated infrastructure platform deployed on AWS. This project demonstrates modern **DevSecOps** principles, focusing on Zero-Trust connectivity, automated provisioning, and robust monitoring.

## 🌟 Project Overview
This repository contains the complete Infrastructure as Code (IaC) and Configuration Management setup required to host a Flask web application in a production-ready environment. The architecture is designed with security as a first-class citizen, completely eliminating the need for public SSH access or long-lived AWS credentials.

## 🚀 Key Features & Security Posture

* **Zero-SSH / Zero-Trust Access:** Port 22 is completely closed across all Security Groups. Server configuration is handled entirely via **Ansible over AWS Systems Manager (SSM)**.
* **Keyless Authentication (OIDC):** GitHub Actions CI/CD pipeline authenticates with AWS using OpenID Connect (OIDC) via `sts:AssumeRoleWithWebIdentity`, eliminating the risk of leaked IAM Access Keys.
* **Edge Protection:** The Application Load Balancer (ALB) is protected by **AWS WAFv2** implementing AWS Managed Rules (Common Rule Set & IP Reputation List) to mitigate common web exploits.
* **Private Network Isolation:** * Application (EC2 Auto Scaling Group) and Database (RDS PostgreSQL) reside in **Private Subnets** across Multiple Availability Zones.
    * AWS services (S3, Secrets Manager) are accessed securely via **VPC Endpoints (PrivateLink & Gateway)** to keep traffic off the public internet.
* **Automated Incident Response:** Integration of CloudWatch Logs with AWS Lambda. Any `ERROR` found in the application logs automatically triggers a Lambda function to send alerts to a Slack channel. CloudWatch Alarms trigger SNS notifications for high CPU utilization.
* **Continuous Compliance & Security Scanning:** Infrastructure code is heavily validated using `tfsec`, ensuring compliance before any infrastructure is provisioned. 
* **Cost Optimization:** AWS ECR lifecycle policies are configured to keep only the last 5 Docker images.

## 🛠️ Technology Stack

* **Infrastructure Provisioning:** Terraform (with S3 backend and state locking)
* **Configuration Management:** Ansible (with Dynamic Inventory `aws_ec2` plugin)
* **CI/CD Pipeline:** GitHub Actions
* **Compute & Networking:** AWS VPC, EC2 ASG, ALB, NAT Gateway
* **Database:** Amazon RDS (PostgreSQL)
* **Security:** AWS WAF, IAM OIDC, Secrets Manager, Security Groups
* **Observability:** CloudWatch, AWS Lambda, SNS

## ⚙️ Deployment Prerequisites

1.  **AWS Account** with sufficient permissions to create the required resources.
2.  **GitHub Repository** properly configured with OIDC to assume the `github_actions_role`.
3.  **Terraform Backend:** An existing S3 bucket (`r-kx-terraform-storage-123`) and DynamoDB table for state locking.
4.  **Secrets:** A valid Ansible Vault password stored in AWS Secrets Manager and a Slack Webhook URL provided as a variable.

---

## 🗺️ Architecture & Flow Diagrams

```mermaid
graph TB
    subgraph GitHub_Actions [GitHub Actions Environment]
        OIDC[OIDC Role Assumption] --> Actions[Runner: Lint/Test/Sec-Scan]
    end

    subgraph AWS_Cloud [AWS Cloud - eu-central-1]
        
        subgraph Security_Identity [Security & Identity]
            WAF[AWS WAF: flask_waf]
            IAM[IAM Roles: api_role & github_role]
            SM[Secrets Manager: Ansible Vault Pass]
        end

        subgraph Management_Monitoring [Monitoring & Alerts]
            CW_Logs[CloudWatch Logs: api-logs]
            CW_Metric[CloudWatch Metric: CPU Alert]
            SNS[SNS Topic: cpu_alert]
            Lambda[Lambda: slack-notifier]
            Slack((Slack Channel))

            CW_Logs -->|Filter: Error| Lambda
            CW_Metric -->|Threshold > 70%| SNS
            Lambda --> Slack
            SNS -->|Email Alert| User((Admin))
        end

        subgraph VPC [VPC: 10.0.0.0/16]
            IGW[Internet Gateway]
            NAT[NAT Gateway]
            
            subgraph Public_Zones [Public Subnets - Multi-AZ]
                ALB[Application Load Balancer]
            end

            subgraph Private_Zones [Private Subnets - Multi-AZ]
                ASG[EC2 ASG: Flask App Instances]
                RDS[(PostgreSQL RDS: Multi-AZ)]
            end

            subgraph VPC_Endpoints [VPC Endpoints - Private Link]
                S3_GW[S3 Gateway Endpoint]
                SM_EP[Secrets Manager Interface EP]
            end
        end

        ECR[ECR: flask-project] -->|Scan on Push| ASG
        ECR -.->|Lifecycle Policy| ECR_Cleanup[Keep Last 5 Images]
    end

    %% Connections
    Actions -->|Terraform Apply| AWS_Cloud
    Actions -->|Docker Push| ECR
    
    User -->|HTTP:80| WAF
    WAF --> ALB
    ALB -->|Port:5000| ASG
    ASG -->|Port:5432| RDS
    ASG -.-> S3_GW
    ASG -.-> SM_EP
    SM_EP -.-> SM
    NAT --> IGW
```
```mermaid
graph LR
    subgraph Development [Local Dev]
        Code[Git Push]
    end

    subgraph CI_Stage [CI: Quality & Security]
        Lint[Lint-Job: Flake8]
        Test[Unit-Test: Pytest]
        TfSec[Security: tfsec Scan]
        IAM_Val[IAM Policy Validator]
        
        Code --> Lint
        Lint --> Test
        Test --> TfSec
        TfSec --> IAM_Val
    end

    subgraph Build_Stage [Build & Artifacts]
        Docker[Docker Build]
        ECR[Push to AWS ECR]
        
        IAM_Val --> Docker
        Docker --> ECR
    end

    subgraph CD_Stage [CD: Provision & Deploy]
        TfApply[Terraform Apply]
        Ansible[Ansible via SSM]
        App((Flask App Live))
        
        ECR --> TfApply
        TfApply --> Ansible
        Ansible --> App
    end

    style TfSec fill:#f96,stroke:#333,stroke-width:2px
    style IAM_Val fill:#f96,stroke:#333,stroke-width:2px
    style Ansible fill:#69f,stroke:#333,stroke-width:2px
```
```mermaid
graph LR
    subgraph GitHub_Runner [GitHub Actions Runner]
        Ansible[Ansible Playbook]
        DynInv[<b>Dynamic Inventory</b><br/>aws_ec2 plugin]
        SSM_Plugin[AWS SSM Plugin]
        
        Ansible --> DynInv
        DynInv -->|Fetch Running Instances| AWS_API
        Ansible --> SSM_Plugin
    end

    subgraph AWS_Control_Plane [AWS Global Infrastructure]
        AWS_API((AWS EC2 API))
        SSM_Service((AWS Systems Manager))
    end

    subgraph Private_Network [VPC: Private Subnet]
        direction TB
        subgraph EC2_Instance [Target: Flask Server]
            Agent[SSM Agent]
            Docker[Docker Engine]
        end
        FW[Security Group: Port 22 CLOSED]
    end

    %% Connectivity Flow
    SSM_Plugin -->|HTTPS:443| SSM_Service
    SSM_Service -->|Secure Tunnel| Agent
    Agent -->|Execute Commands| Docker
```
