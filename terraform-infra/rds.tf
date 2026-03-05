resource "aws_db_subnet_group" "flask_db_sg" {
    name       = "db-subnet"
    subnet_ids = aws_subnet.private[*].id
}

#tfsec:ignore:aws-rds-enable-performance-insights-encryption
resource "aws_db_instance" "flask_rds" {
    identifier             = "flask-db"
    allocated_storage      = 20
    storage_type           = "gp3"
    engine                 = "postgres"
    instance_class         = "db.t3.micro"
    db_name                = "flask_db"
    username               = var.db_username
    password               = var.rds_password
    skip_final_snapshot    = true
    db_subnet_group_name   = aws_db_subnet_group.flask_db_sg.name
    vpc_security_group_ids = [aws_security_group.rds_sg.id]
    publicly_accessible    = false
    storage_encrypted      = true
    backup_retention_period = 7
    iam_database_authentication_enabled = true
    performance_insights_enabled = true
    #tfsec:ignore:aws-rds-enable-deletion-protection
    deletion_protection    = false
}