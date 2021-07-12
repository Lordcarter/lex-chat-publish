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

locals {
    s3_origin_id = "lexS3Origin"
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${var.s3_bucket}/*",
    ]
  }
}

module "s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "2.6.0"
  bucket= var.s3_bucket
  attach_policy = true
  policy        = data.aws_iam_policy_document.bucket_policy.json

  website = {
    index_document = "index.html"
    error_document = "error.html"
  }
}


resource "aws_cloudfront_origin_access_identity" "lex_ui_origin_access" {
  comment = "For Lex UI"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
    
     origin {
        domain_name = module.s3-bucket.s3_bucket_bucket_domain_name
        origin_id   = local.s3_origin_id

        s3_origin_config {
        origin_access_identity = ""
        }
  }

  enabled   = true
  default_root_object = "index.html"
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

}