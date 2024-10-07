terraform {
  backend "s3" {
    bucket         = "terraform-bucket-envxchange"   # Your existing bucket
    key            = "cloudfront-s3.tfstate"     # Define the path within the bucket
    region         = "us-east-1"                     # Replace with your region
  }
}
