resource "aws_instance" "bastion" {
  ami                  = "ami-01c36f3329957b16a" # Ubuntu Server 18.04 LTS (HVM), SSD Volume Type
  instance_type        = "t2.micro"
  key_name             = aws_key_pair.sample_key.id
  subnet_id            = aws_subnet.public_subnet_az1.id
  iam_instance_profile = aws_iam_instance_profile.bastion_profile.name
  vpc_security_group_ids = [
    aws_default_security_group.default.id,
    aws_security_group.ssh.id,
  ]
  associate_public_ip_address = true
  user_data                   = <<EOF
#!/bin/bash
sudo timedatectl set-timezone Asia/Tokyo
EOF

  tags = {
    Name = "[${var.service_name}] bastion"
  }
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "${var.service_name}-bastion"
  role = aws_iam_role.bastion_role.name
}

resource "aws_iam_role" "bastion_role" {
  name = "${var.service_name}-bastion"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bastion-attach-ro" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_security_group" "ssh" {
  name        = "ssh"
  description = "Allow ssh access"
  vpc_id      = aws_vpc.default.id

  lifecycle {
    ignore_changes = [ingress]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "[${var.service_name}] ssh"
  }
}

resource "aws_key_pair" "sample_key" {
  key_name   = var.service_name
  public_key = file("./key_pairs/sample.pub")
}
