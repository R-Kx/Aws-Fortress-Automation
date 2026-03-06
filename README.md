
``` mermaid
graph TD
    subgraph AWS_Cloud [AWS Cloud - Region: eu-central-1]
        subgraph VPC [VPC: 10.0.0.0/16]
            IGW[Internet Gateway]
            WAF[AWS WAF]
            ALB[Application Load Balancer]
            NAT[NAT Gateway]

            subgraph Public_Subnets [Public Subnets - Multi-AZ]
                ALB_Node[ALB Instance]
                NAT_Node[NAT Gateway Instance]
            end

            subgraph Private_Subnets [Private Subnets - Multi-AZ]
                Flask[Flask App - EC2 ASG]
                RDS[(PostgreSQL RDS)]
            end

            subgraph Endpoints [VPC Endpoints - Private Link]
                S3_EP[S3 Gateway]
                Secrets_EP[Secrets Manager EP]
            end
        end
    end

    User((User)) --> WAF
    WAF --> ALB
    ALB --> Flask
    Flask --> RDS
    Flask -.-> S3_EP
    Flask -.-> Secrets_EP
    NAT -.-> IGW
    IGW --> User
```
