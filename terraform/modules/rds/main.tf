resource "random_password" "db" {
    length = 20
    special = true
    min_numeric = 2
    min_lower = 2
    min_upper = 2
    override_special = "!#$%^&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db" {
    name = "${var.name}-db-password-3"

    tags = {
        Name = "${var.name}-db-password-3"
    }
}

resource "aws_secretsmanager_secret_version" "db" {
    secret_id = aws_secretsmanager_secret.db.id
    secret_string = jsonencode({
        dbname = var.db_name,
        username = var.username,
        password = random_password.db.result
    })
}

resource "aws_security_group" "rds" {
    name = "${var.name}-rds-sg"
    vpc_id = var.vpc_id
    description = "Allow only backend to connect the rds"

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]  
    }
}

resource "aws_security_group_rule" "db_ingress_sg" {
    count = length(var.db_ingress_sg)
    type = "ingress"
    security_group_id = aws_security_group.rds.id
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    source_security_group_id = var.db_ingress_sg[count.index]
}


resource "aws_security_group_rule" "db_ingress_cidr" {
    count = length(var.db_ingress_cidr) > 0 ? 1 : 0
    type = "ingress"
    security_group_id = aws_security_group.rds.id
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = var.db_ingress_cidr
}


resource "aws_db_subnet_group" "rds" {
    name = "${var.name}-db-subnet-group"
    subnet_ids = var.private_subnet_ids

    tags = {
      Name = "${var.name}-db-subnet-group"
    }
}

resource "aws_db_instance" "rds" {
    identifier = "${var.name}-db"
    engine = "postgres"
    engine_version = "18.3"
    allocated_storage = 20
    storage_type =  "gp3"
    instance_class = "db.t3.micro"

    db_name = var.db_name
    username = var.username
    password = random_password.db.result

    db_subnet_group_name = aws_db_subnet_group.rds.name
    vpc_security_group_ids = [aws_security_group.rds.id]

    backup_retention_period = 0
    multi_az = false
    deletion_protection = false
    skip_final_snapshot = true
    publicly_accessible = false

    tags = {
        Name = "${var.name}-db"
    }
}