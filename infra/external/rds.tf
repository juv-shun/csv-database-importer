resource "aws_db_instance" "default" {
  identifier              = "${var.service_name}-sample"
  engine                  = "mysql"
  engine_version          = "5.7"
  allocated_storage       = 10
  storage_type            = "gp2"
  instance_class          = "db.t3.micro"
  username                = "user"
  db_name                 = "sample"
  password                = var.db_password
  parameter_group_name    = "default.mysql5.7"
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_default_security_group.default.id]
  db_subnet_group_name    = aws_db_subnet_group.subnet_group.id
  backup_retention_period = 1
}

resource "aws_db_subnet_group" "subnet_group" {
  name        = "${var.service_name}-sample"
  description = "subnet group for ${var.service_name}"

  subnet_ids = [
    aws_subnet.private_subnet_az1.id,
    aws_subnet.private_subnet_az2.id,
  ]
}
