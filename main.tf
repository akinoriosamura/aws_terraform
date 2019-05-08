module "dev_server" {
  source        = "./http_server"
  instance_type = "t2.micro"
}

module "describe_regions_for_ec2" {
  source     = "./iam_role"
  name       = "describe-regions-for-ec2"
  identifier = "ec2.amazonaws.com"
  policy     = "${data.aws_iam_policy_document.allow_describle_regions.json}"
}

data "aws_iam_policy_document" "allow_describle_regions" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeRegions"]
    resources = ["*"]
  }
}

resource "aws_s3_bucket" "private" {
  bucket = "osamura-private-pragmatic-terraform-on-aws"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "private" {
  bucket                  = "${aws_s3_bucket.private.id}"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "alb_log" {
  bucket = "osamura-alb-log-pragmatic-terraform-on-aws"

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}

data "aws_iam_policy_document" "alb_log" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

    principals {
      type        = "AWS"
      identifiers = ["582318560864"]
    }
  }
}

resource "aws_s3_bucket_policy" "alb_log" {
  bucket = "${aws_s3_bucket.alb_log.id}"
  policy = "${data.aws_iam_policy_document.alb_log.json}"
}

output "public_dns" {
  value = "${module.dev_server.public_dns}"
}

output "iam_role_arn" {
  value = "${module.describe_regions_for_ec2.iam_role_arn}"
}

output "iam_role_name" {
  value = "${module.describe_regions_for_ec2.iam_role_name}"
}
