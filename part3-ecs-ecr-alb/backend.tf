terraform {
  backend "s3" {
    # Configure bucket/key/region in backend.hcl before terraform init.
    # S3 bucket must already exist
  see ../state-bootstrap and README.md.
  }
}
