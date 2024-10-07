locals {
  s3_origin_id   = "${var.s3_name}-origin"
  s3_domain_name = "${var.s3_name}.s3.${var.region}.amazonaws.com"  # Change to bucket endpoint (not website)
}

# Data block to fetch the current account ID
data "aws_caller_identity" "current" {}

resource "aws_cloudfront_distribution" "this" {
  enabled = true

  origin {
    origin_id   = local.s3_origin_id
    domain_name = local.s3_domain_name

    # Use the custom origin config for non-website endpoint
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "match-viewer"  # Match HTTP or HTTPS based on viewer request
      origin_ssl_protocols   = ["TLSv1.2"]  # Use secure TLS
    }
  }

  default_cache_behavior {
    target_origin_id = local.s3_origin_id
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  price_class = "PriceClass_200"

  # Default root object for serving the website
  default_root_object = "index.html"
}
