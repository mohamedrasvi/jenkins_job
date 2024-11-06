# terraform/gcs-website/outputs.tf
output "bucket_url" {
  value = google_storage_bucket.website_bucket.url
}
