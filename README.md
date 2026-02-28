# AWS Hybrid Cloud Automation: Terraform & Ansible (Work-in-Progress 🛠️)

This repository contains a production-grade infrastructure automation project using **Terraform** for IaaS and **Ansible** for configuration management. It demonstrates a secure, multi-tier AWS environment designed for containerized applications.

## 🏗️ Project Architecture


- [cite_start]**IaC (Terraform):** Full VPC orchestration including Public/Private subnets, ALB, RDS, and ECR. [cite: 43, 44]
- [cite_start]**Configuration (Ansible):** Automated Docker Engine setup and security hardening. [cite: 60]
- **Secure Management:** SSH-over-SSM (Systems Manager) tunneling to manage private instances without exposing Port 22.

## 🚀 Current Status: PENDING / IN-DEVELOPMENT
The infrastructure layer is **100% complete and verified**. The project is currently in the "Last Mile" phase:
- [x] [cite_start]**VPC & Security:** Multi-tier networking and NACL/SG rules configured. [cite: 44, 45]
- [x] [cite_start]**Resource Provisioning:** EC2, RDS, and S3 integration via Terraform. [cite: 46, 47]
- [x] [cite_start]**Ansible Core:** Successfully established secure connectivity and bootstrapping. [cite: 58, 59]
- [ ] **CI/CD Integration:** Finalizing GitHub Actions workflow for automated ECR pushes and remote deployment.
- [ ] **App Deployment:** Transitioning from Docker-Compose to full ECS/EKS orchestration (Roadmap).

## 🛠️ Tech Stack
- [cite_start]**Cloud:** AWS (EC2, VPC, IAM, S3, ECR, RDS). [cite: 14, 15]
- [cite_start]**IaC:** Terraform. [cite: 43]
- [cite_start]**Automation:** Ansible & Bash Scripting. [cite: 21, 56]
- [cite_start]**Containers:** Docker & Docker-Compose. [cite: 16, 17]

---
*Note: This project is part of my DevOps portfolio and is updated daily as I refine the CI/CD logic.*
