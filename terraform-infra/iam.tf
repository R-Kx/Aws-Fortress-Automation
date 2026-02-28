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

resource "aws_iam_role_policy" "api_custom_policy" {
    name = "${var.project_name}-custom-permissions"
    role = aws_iam_role.api_role.id

    policy = jsonencode({
        Version    = "2012-10-17"
        Statement = [
            {
                Effect   = "Allow"
                Action   = ["secretsmanager:GetSecretValue"]
                Resource = [aws_secretsmanager_secret.db_secret_pass.arn]
            },
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
