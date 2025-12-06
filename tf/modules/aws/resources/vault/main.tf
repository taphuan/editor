resource "aws_secretsmanager_secret" "vault" {
  name = var.name

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

