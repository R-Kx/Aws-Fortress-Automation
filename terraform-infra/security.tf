resource "aws_security_group" "alb_sg" {
    name        = "alb_sg"
    description = "access to ALB"
    vpc_id      = aws_vpc.flask_vpc.id

    ingress {
        protocol    = "tcp"
        from_port   = 80
        to_port     = 80
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "ec2_sg" {
    name        = "ec2_sg"
    description = "allow inbound access from ALB"
    vpc_id      = aws_vpc.flask_vpc.id

    ingress {
        protocol  = "tcp"
        from_port = 5000
        to_port   = 5000
        security_groups = [aws_security_group.alb_sg.id]
    }

    egress {
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "rds_sg" {
    name        = "rds_sg"
    description = "allow inbound access from ec2 only"
    vpc_id      = aws_vpc.flask_vpc.id

    ingress {
      protocol        = "tcp"
      from_port       = 5432
      to_port         = 5432
      security_groups = [aws_security_group.ec2_sg.id]
    }

    egress {
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        cidr_blocks = ["0.0.0.0/0"]
    }
}

/*resource "aws_network_acl" "main_nacl" {
    vpc_id     = aws_vpc.flask_vpc.id
    subnet_ids = aws_subnet.private[*].id

    ingress {
        protocol   = "tcp"
        rule_no    = 100
        action     = "deny"
        cidr_block = "0.0.0.0/0"
        from_port  = 23
        to_port    = 23
    }

    ingress {
        protocol   = "tcp"
        rule_no    = 110
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 80
        to_port    = 80
    }

    ingress {
        protocol   = "tcp"
        rule_no    = 120
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 443
        to_port    = 443
    }

    ingress {
        protocol   = "tcp"
        rule_no    = 130
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 1024
        to_port    = 65535
    }

    ingress {
        protocol   = "tcp"
        rule_no    = 140
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 5000
        to_port    = 5000
    }

    ingress {
        protocol   = "tcp"
        rule_no    = 150
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 5432
        to_port    = 5432
    }

    egress {
        protocol   = "tcp"
        rule_no    = 160
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 5000
        to_port    = 5000
    }

    egress {
        protocol   = "tcp"
        rule_no    = 170
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 5432
        to_port    = 5432

    }

    egress {
        protocol   = "tcp"
        rule_no    = 180
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 1024
        to_port    = 65535
    }

    egress {
        protocol   = "tcp"
        rule_no    = 190
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 80
        to_port    = 80
    }

    egress {
        protocol   = "tcp"
        rule_no    = 200
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 443
        to_port    = 443
    }
}*/

resource "aws_wafv2_web_acl" "flask_waf" {
    count       = var.enable_waf ? 1 : 0
    name        = "flask_waf"
    description = "aws managed rules for flask app"
    scope       = "REGIONAL"

    default_action {
        allow {}
    }

    rule {
        name     = "AWS-AWSManagedRulesCommonRuleSet"
        priority = 1

        override_action {
            none {}
        }

        statement {
            managed_rule_group_statement {
                name        = "AWSManagedRulesCommonRuleSet"
                vendor_name = "AWS"
            }
        }

        visibility_config {
            cloudwatch_metrics_enabled = true
            metric_name                = "aws-common-rules"
            sampled_requests_enabled   = true
        }
    }

    rule {
        name     = "AWS-AWSManagedRulesAmazonIpReputationList"
        priority = 2

        override_action {
            none {}
        }

        statement {
            managed_rule_group_statement {
                name        = "AWSManagedRulesAmazonIpReputationList"
                vendor_name = "AWS"
            }
        }

        visibility_config {
            cloudwatch_metrics_enabled = true
            metric_name                = "aws-ip-reputation"
            sampled_requests_enabled    = true
        }
    }

    visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "flask-waf-main"
        sampled_requests_enabled   = true 
    }
}

resource "aws_wafv2_web_acl_association" "waf_alb_asso" {
    count        = var.enable_waf ? 1 : 0
    resource_arn = aws_lb.flask_alb.arn
    web_acl_arn  = aws_wafv2_web_acl.flask_waf[0].arn
}

resource "aws_security_group" "secrets_sg" {
    name        = "secrets-endpoint-sg"
    description = "Allow HTTPS Inbound from VPC"
    vpc_id      = aws_vpc.flask_vpc.id

    ingress {
        protocol    = "tcp"
        from_port   = 443
        to_port     = 443
        cidr_blocks = [aws_vpc.flask_vpc.cidr_block]
    }

    egress {
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        cidr_blocks = ["0.0.0.0/0"]
    }
}