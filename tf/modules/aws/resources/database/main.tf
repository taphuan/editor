resource "aws_db_instance" "database" {
  identifier     = var.name
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class
  allocated_storage = var.allocated_storage

  db_name  = var.engine == "postgres" ? var.name : null
  username = var.username
  password = var.password
  port     = var.port

  db_subnet_group_name   = var.subnet_group_name
  vpc_security_group_ids = var.security_group_ids

  publicly_accessible = false
  skip_final_snapshot = true
  storage_encrypted   = true

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

