
# S3
resource "aws_s3_bucket" "aws-cloudfront-s3-static-web" {
  bucket = "static-web-hosting-patterns-aws-cloudfront-s3-static-web"
}

resource "aws_s3_bucket_website_configuration" "aws-cloudfront-s3-static-web" {
  bucket = aws_s3_bucket.aws-cloudfront-s3-static-web.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_ownership_controls" "aws-cloudfront-s3-static-web" {
  bucket = aws_s3_bucket.aws-cloudfront-s3-static-web.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "aws-cloudfront-s3-static-web" {
  bucket = aws_s3_bucket.aws-cloudfront-s3-static-web.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "aws-cloudfront-s3-static-web" {
  depends_on = [
    aws_s3_bucket_ownership_controls.aws-cloudfront-s3-static-web,
    aws_s3_bucket_public_access_block.aws-cloudfront-s3-static-web,
  ]

  bucket = aws_s3_bucket.aws-cloudfront-s3-static-web.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "aws-cloudfront-s3-static-web" {
  bucket = aws_s3_bucket.aws-cloudfront-s3-static-web.id
  policy = data.aws_iam_policy_document.aws-cloudfront-s3-static-web.json
}

data "aws_iam_policy_document" "aws-cloudfront-s3-static-web" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.aws-cloudfront-s3-static-web.arn}/*",
    ]
  }
}

# CloudFront
resource "aws_cloudfront_distribution" "aws-cloudfront-s3-static-web" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_200"

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  origin {
    domain_name = aws_s3_bucket_website_configuration.aws-cloudfront-s3-static-web.website_endpoint
    origin_id   = "static_files"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    # CachingOptimized
    cache_policy_id  = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    target_origin_id = "static_files"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]

    viewer_protocol_policy = "redirect-to-https"
  }
}

resource "aws_cloudfront_origin_access_identity" "aws-cloudfront-s3-static-web" {
}

output "aws-cloudfront-s3-static-web-domain" {
  value = aws_cloudfront_distribution.aws-cloudfront-s3-static-web.domain_name
}

# Contents
resource "aws_s3_object" "aws-cloudfront-s3-static-web" {
  for_each = fileset("../contents", "**/*")

  bucket = aws_s3_bucket.aws-cloudfront-s3-static-web.id
  key    = each.value
  source = "../contents/${each.value}"

  content_type = "text/html"
}