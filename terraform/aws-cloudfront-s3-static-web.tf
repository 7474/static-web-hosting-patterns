
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

data "aws_iam_policy_document" "aws-cloudfront-s3-static-web_cdn_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.aws-cloudfront-s3-static-web.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.aws-cloudfront-s3-static-web.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "aws-cloudfront-s3-static-web_cdn_policy" {
  bucket = aws_s3_bucket.aws-cloudfront-s3-static-web.id
  policy = data.aws_iam_policy_document.aws-cloudfront-s3-static-web_cdn_policy.json
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
    domain_name = aws_s3_bucket_website_configuration.aws-cloudfront-s3-static-web.website_domain
    origin_id   = "static_files"
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