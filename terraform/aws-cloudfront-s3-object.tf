
# S3
resource "aws_s3_bucket" "aws-cloudfront-s3-object" {
  bucket = "static-web-hosting-patterns-aws-cloudfront-s3-object"
}

data "aws_iam_policy_document" "aws-cloudfront-s3-object_cdn_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.aws-cloudfront-s3-object.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.aws-cloudfront-s3-object.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "aws-cloudfront-s3-object_cdn_policy" {
  bucket = aws_s3_bucket.aws-cloudfront-s3-object.id
  policy = data.aws_iam_policy_document.aws-cloudfront-s3-object_cdn_policy.json
}

# CloudFront
resource "aws_cloudfront_distribution" "aws-cloudfront-s3-object" {
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
    domain_name = aws_s3_bucket.aws-cloudfront-s3-object.bucket_regional_domain_name
    origin_id   = "static_files"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.aws-cloudfront-s3-object.cloudfront_access_identity_path
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

resource "aws_cloudfront_origin_access_identity" "aws-cloudfront-s3-object" {
}

# Contents
resource "aws_s3_object" "aws-cloudfront-s3-objec" {
  for_each = fileset("../contents", "**/*")

  bucket = aws_s3_bucket.aws-cloudfront-s3-object.id
  key    = each.value
  source = "../contents/${each.value}"
  
  content_type = "text.html"
}