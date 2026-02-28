resource "random_password" "db-pass" {
    length  = 14
    special = true
    override_special = "_!%^"
}

resource "aws_secretsmanager_secret" "db_secret_pass" {
    name                    = "db-pass-${random_id.s3_bucket_id.hex}"
    recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_pass_ver" {
    secret_id     = aws_secretsmanager_secret.db_secret_pass.id
    secret_string = random_password.db-pass.result
}