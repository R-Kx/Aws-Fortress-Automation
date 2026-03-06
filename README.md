
``` mermaid
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
