resource "aws_iam_instance_profile" "api_instance_profile" {
    name = "${var.project_name}-instance-profile"
    role = aws_iam_role.api_role.name
}

data "aws_ami" "ubuntu" {
    most_recent = true
    owners      = ["099720109477"]

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}

resource "aws_key_pair" "aws_auth" {
    key_name   = var.key_name
    public_key = file(var.pub_key_path) 
}

resource "aws_launch_template" "flask_api_lt" {
    name_prefix   = "${var.project_name}-flask-lt"
    image_id      = data.aws_ami.ubuntu.id
    instance_type = var.instance_type
    key_name      = aws_key_pair.aws_auth.key_name

    iam_instance_profile {
      name = aws_iam_instance_profile.api_instance_profile.id
    }

    vpc_security_group_ids = [aws_security_group.ec2_sg.id]

    user_data = base64encode(<<-EOF
#!/bin/bash
apt-get update
apt-get install -y python3-pip
echo "Server is ready for Ansible"
EOF
)
}

resource "aws_autoscaling_group" "flask_asg" {
    name              = "${var.project_name}-flask-asg"
    desired_capacity  = 2
    max_size          = 4
    min_size          = 1
    target_group_arns = [aws_lb_target_group.flask_tg_group.arn]
    vpc_zone_identifier = aws_subnet.private[*].id

    launch_template {
        id      = aws_launch_template.flask_api_lt.id
        version = "$Latest"
    }
}
