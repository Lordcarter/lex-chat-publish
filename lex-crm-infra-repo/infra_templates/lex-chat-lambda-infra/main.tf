terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket = "<bucket>"
    key    = "lexinfrastate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

module "s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "2.6.0"
  for_each = toset( var.s3_bukets )
  bucket= each.key

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "lambda-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "CustLambdaAccess" {
  statement {
    actions   = ["logs:*","s3:*","dynamodb:*","cloudwatch:*","sns:*","lambda:*"]
    effect   = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_role" "LexCrmRoleCust" {
    name               = "LexCrmRoleCust"
    assume_role_policy = data.aws_iam_policy_document.lambda-assume-role-policy.json
    inline_policy {
        name   = "policy-8675309"
        policy = data.aws_iam_policy_document.CustLambdaAccess.json
    }

}

