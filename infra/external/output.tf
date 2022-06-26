output "vpc_settings" {
  value = {
    vpc_id                 = aws_vpc.default.id
    public_subnet_az1      = aws_subnet.public_subnet_az1.id
    public_subnet_az2      = aws_subnet.public_subnet_az2.id
    private_subnet_az1     = aws_subnet.private_subnet_az1.id
    private_subnet_az2     = aws_subnet.private_subnet_az2.id
    default_security_group = aws_default_security_group.default.id
  }
}
