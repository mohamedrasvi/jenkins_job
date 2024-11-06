# Use the Module in Your Project:
# main.tf
module "gcs_website" {
  source      = "./terraform/gcs-website"
  bucket_name = "my-website-bucket"
}