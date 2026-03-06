resource "aws_iam_role" "api_role" {
    name = "${var.project_name}-api-role"

    assume_role_policy = jsonencode({
        Version       = "2012-10-17"
        Statement    = [{
            Action    = "sts:AssumeRole"
            Effect    = "Allow"
            Principal = { Service = "ec2.amazonaws.com" }
        }] 
    })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
    role       = aws_iam_role.api_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecr_policy" {
    role       = aws_iam_role.api_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "cw_policy" {
    role       = aws_iam_role.api_role.name
    policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_role_policy" "api_custom_policy" {
    name = "${var.project_name}-custom-permissions"
    role = aws_iam_role.api_role.id

    policy = jsonencode({
        Version    = "2012-10-17"
        Statement = [
            /*{
                Effect   = "Allow"
                Action   = ["secretsmanager:GetSecretValue"]
                Resource = [aws_secretsmanager_secret.db_secret_pass.arn]
            },*/
            {
                Effect   = "Allow"
                Action   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
                Resource = [
                    aws_s3_bucket.flask_bucket.arn,
                    "${aws_s3_bucket.flask_bucket.arn}/*"
                ]
            }
        ]
    })
}

resource "aws_iam_role" "lambda_role" {
    name = "${var.project_name}-lambda-role"

    assume_role_policy = jsonencode({
        Version       = "2012-10-17"
        Statement    = [{
            Action    = "sts:AssumeRole"
            Effect    = "Allow"
            Principal = { Service = "lambda.amazonaws.com" } 
        }] 
    })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
    role       = aws_iam_role.lambda_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_role_policy" "lambda_custom_policy" {
    name = "${var.project_name}-lambda-custom"
    role = aws_iam_role.lambda_role.id

    policy = jsonencode({
        Version  = "2012-10-17"
        Statement = [
          {
            Effect   = "Allow"
            Action   = ["s3:GetObject", "s3:PutObject"]
            Resource = ["${aws_s3_bucket.flask_bucket.arn}/*"]
          }
        ]
    })    
}

resource "aws_iam_openid_connect_provider" "github" {
    url             = "https://token.actions.githubusercontent.com"
    client_id_list  = ["sts.amazonaws.com"]
    thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_actions_role" {
    name = "${var.project_name}-github-actions-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action = "sts:AssumeRoleWithWebIdentity"
            Effect = "Allow"
            Principal = {
                Federated = aws_iam_openid_connect_provider.github.arn
            }
            Condition = {
                StringLike = {
                    "token.actions.githubusercontent.com:sub" = "repo:R-Kx/Aws-Fortress-Automation:*"
                }
                StringEquals ={
                    "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
                }
            }
        }]
    })
}


#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_role_policy" "github_action_policy" {
    name = "${var.project_name}-github-action-policy"
    role = aws_iam_role.github_actions_role.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            { Effect   = "Allow"
              Action   = ["secretsmanager:GetSecretValue"]
              Resource = ["${aws_secretsmanager_secret.ansible_vault_pass.arn}-*"]

            },
            {
                Effect   = "Allow"
                Action   = ["ecr:GetAuthorizationToken"]
                Resource = "*"
            },
            {
                Effect = "Allow"
                Action = [
                    "ecr:BatchCheckLayerAvailability",
                    "ecr:PutImage",
                    "ecr:InitiateLayerUpload",
                    "ecr:UploadLayerPart",
                    "ecr:CompleteLayerUpload"
                ]
                Resource = [aws_ecr_repository.flask_app.arn]
            },
            {
                Effect = "Allow"
                Action = [
                    "ssm:StartSession",
                    "ssm:SendCommand",
                    "ec2:DescribeInstances"
                ]
                Resource = ["arn:aws:ec2:*:*:instance/*"]
            },
            {
                Effect = "Allow"
                Action = [
                    "s3:ListBucket"
                ]
                Resource = ["arn:aws:s3:::r-ks-terraform-storage-123"]
            },
            {
                Effect = "Allow"
                Action = [
                    "s3:GetObject",
                    "s3:PutObject",
                    "s3:DeleteObject"
                ]
                Resource = ["arn:aws:s3:::r-kx-terraform-storage-123/*"]
            },
            {
                Effect = "Allow"
                Action = [
                    "ec2:Describe*",
                    "iam:Get*",
                    "iam:List*",
                    "s3:Get*",
                    "s3:List*",
                    "elasticloadbalancing:Describe*",
                    "sns:Get*",
                    "sns:List*",
                    "logs:Describe*",
                    "logs:List*",
                    "secretsmanager:DescribeSecret",
                    "secretsmanager:GetResourcePolicy",
                    "tag:GetResources",
                    "ecr:Describe*",
                    "ecr:List*",
                    "lambda:Get*",
                    "lambda:List*",
                    "rds:Describe*",
                    "rds:List*",
                    "autoscaling:Describe*",
                    "cloudwatch:Describe*",
                    "cloudwatch:ListTagsForResource",
                    "ecr:GetLifecyclePolicy",
                    "access-analyzer:ValidatePolicy"
                ]
                Resource = "*" 
            },
            {
                Effect = "Allow"
                Action = [
                    "ec2:*",
                    "rds:*",
                    "s3:*",
                    "elasticloadbalancing:*",
                    "autoscaling:*",
                    "cloudwatch:*",
                    "logs:*",
                    "sns:*",
                    "secretsmanager:*",
                    "ecr:*"
                ]
                Resource = "*"  
            },
            {
                Effect    = "Allow"
                NotAction = ["iam:PassRole"]
                Resource  = "*"
            },
            {
                Effect    = "Allow"
                Action    = ["iam:PassRole"]
                Resource  = "*"
                Condition = {
                    StringEquals: {
                        "iam:PassedToService" = [
                            "ec2.amazonaws.com",
                            "lambda.amazonaws.com",
                            "rds.amazonaws.com"
                        ]
                    }
                }
            }
        ]
    })
}