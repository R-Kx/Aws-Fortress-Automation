resource "aws_db_subnet_group" "flask_db_sg" {
    name       = "db-subnet"
    subnet_ids = aws_subnet.private[*].id
}

resource "aws_db_instance" "flask_rds" {
    identifier             = "flask-db"
    allocated_storage      = 20
    storage_type           = "gp3"
    engine                 = "postgres"
    instance_class         = "db.t3.micro"
    db_name                = "flask_db"
    username               = var.db_username
    password               = random_password.db-pass.result
    skip_final_snapshot    = true
    db_subnet_group_name   = aws_db_subnet_group.flask_db_sg.name
    vpc_security_group_ids = [aws_security_group.rds_sg.id]
    publicly_accessible    = false
}