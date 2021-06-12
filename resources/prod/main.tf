locals {
  stage = "prod"
  app = "sesStats"
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket = "as-terraform-backends"
    key = "state/leadGen/ses_stats.prod.tfstate"
    region = "eu-west-1"
    profile = "AudienceServAWS"
  }
}

provider "aws" {
  region = "eu-west-1"
  profile = "AudienceServAWS"
  default_tags {
    tags = {
      terraform = "true"
      project = local.app,
      service = "main"
      stage = local.stage
    }
  }
}

resource "aws_sqs_queue" "external_events" {
  name = "${local.app}-${local.stage}-event-queue"
}

resource "aws_sns_topic_subscription" "mein_gratis_produkt" {
  topic_arn = "arn:aws:sns:eu-west-1:913157718210:MeinGratisProdukt"
  endpoint = aws_sqs_queue.external_events.arn
  protocol = "sqs"
}

resource "aws_sns_topic_subscription" "produktegratis" {
  topic_arn = "arn:aws:sns:eu-west-1:913157718210:ProdukteGratis"
  endpoint = aws_sqs_queue.external_events.arn
  protocol = "sqs"
}

resource "aws_sns_topic_subscription" "aktuelledeals" {
  topic_arn = "arn:aws:sns:eu-west-1:913157718210:aktuelledeals_com"
  endpoint = aws_sqs_queue.external_events.arn
  protocol = "sqs"
}

resource "aws_sns_topic_subscription" "megalos24" {
  topic_arn = "arn:aws:sns:eu-west-1:913157718210:Megalos24"
  endpoint = aws_sqs_queue.external_events.arn
  protocol = "sqs"
}

resource "aws_sns_topic_subscription" "coyote_doi" {
  topic_arn = "arn:aws:sns:eu-west-1:913157718210:CoyoteDOI"
  endpoint = aws_sqs_queue.external_events.arn
  protocol = "sqs"
}

resource "aws_ssm_parameter" "event_queue_arn" {
  name = "/${local.app}/${local.stage}/event_queue_arn"
  type = "String"
  value = aws_sqs_queue.external_events.arn
}

################################################################################
# RDS Aurora Module - MySQL
################################################################################

module "aurora_mysql" {
  source = "terraform-aws-modules/rds-aurora/aws"
  version = "5.2.0"

  name              = lower("${local.app}-mysql")
  engine            = "aurora-mysql"
  engine_mode       = "serverless"
  storage_encrypted = true

  vpc_id                 = "vpc-08c0103512db40f17"
  subnets                = ["subnet-016fd7e4fb8d73fbd", "subnet-0a4f03eb9efe1e1f6", "subnet-0d399b50fceccbc9c"]
  vpc_security_group_ids = ["sg-068897276d41ca309"]
  create_security_group  = false

  replica_scale_enabled = false
  replica_count         = 0

  monitoring_interval = 60

  apply_immediately   = true
  skip_final_snapshot = true

  db_parameter_group_name         = aws_db_parameter_group.example_mysql.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.example_mysql.id
  # enabled_cloudwatch_logs_exports = # NOT SUPPORTED

  scaling_configuration = {
    auto_pause               = true
    min_capacity             = 1
    max_capacity             = 16
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }
}

resource "aws_db_parameter_group" "example_mysql" {
  name        = lower("${local.app}-aurora-db-mysql-parameter-group")
  family      = "aurora-mysql5.7"
  description = "${local.app}-aurora-db-mysql-parameter-group"
}

resource "aws_rds_cluster_parameter_group" "example_mysql" {
  name        = lower("${local.app}-aurora-mysql-cluster-parameter-group")
  family      = "aurora-mysql5.7"
  description = "${local.app}-aurora-mysql-cluster-parameter-group"
}

resource "aws_ssm_parameter" "rds_cluster_endpoint" {
  name = "/${local.app}/${local.stage}/rds_cluster_endpoint"
  type = "String"
  value = module.aurora_mysql.rds_cluster_endpoint
}

resource "aws_ssm_parameter" "rds_cluster_master_username" {
  name = "/${local.app}/${local.stage}/rds_cluster_master_username"
  type = "String"
  value = module.aurora_mysql.rds_cluster_master_username
}

resource "aws_ssm_parameter" "rds_cluster_master_password" {
  name = "/${local.app}/${local.stage}/rds_cluster_master_password"
  type = "String"
  value = module.aurora_mysql.rds_cluster_master_password
}