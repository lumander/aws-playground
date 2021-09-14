resource "aws_s3_bucket" "static_assets" {
  bucket = format("static-%s-%s-%s", var.project, var.environment, substr(uuid(),0,6))
  acl    = "public-read"

  lifecycle {
    prevent_destroy = false
    ignore_changes = [ bucket ]
  }

}

resource "aws_s3_bucket_object" "object" {
  bucket = aws_s3_bucket.static_assets.id
  key    = "assets/images/awsLogo.jpeg"
  source = "../../../docs/awsLogo.jpeg"
  acl    = "public-read"

  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }
}

resource "aws_cloudfront_origin_access_identity" "cf" {}

resource "aws_cloudfront_distribution" "cf" {
  enabled          = true

  origin {
    domain_name = aws_alb.frontend-alb.dns_name
    origin_id   = aws_alb.frontend-alb.name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2", "SSLv3"]
    }
  }

  origin {
    domain_name = aws_s3_bucket.static_assets.bucket_domain_name
    origin_id   = aws_s3_bucket.static_assets.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cf.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_alb.frontend-alb.name

    forwarded_values {
      query_string = true
      headers      = ["*"]

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  ordered_cache_behavior {
    path_pattern           = "assets/images/*"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.static_assets.id
    viewer_protocol_policy = "redirect-to-https"   
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }

}