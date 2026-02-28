resource "aws_ecr_repository" "flask_app" {
    name                 = var.project_name
    image_tag_mutability = "MUTABLE"
    force_delete         = true

    image_scanning_configuration {
        scan_on_push = true
    }
}

resource "aws_ecr_lifecycle_policy" "image_cleanup" {
    repository = aws_ecr_repository.flask_app.name

    policy     = jsonencode({
        rules = [{
            rulePriority = 1
            description = "Keep Only Last 5 Images"
            selection = {
                tagStatus   = "any"
                countType   = "imageCountMoreThan"
                countNumber = 5
            }
            action = {
                type = "expire"
            }
        }]
    })
}