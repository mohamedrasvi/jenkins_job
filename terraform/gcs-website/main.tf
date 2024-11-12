# terraform/gcs-website/main.tf
resource "google_storage_bucket" "website_bucket" {
  name     = var.bucket_name
  location = "US"

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
}

resource "google_storage_bucket_object" "index" {
  name         = "index.html"
  bucket       = google_storage_bucket.website_bucket.name
  source       = "${path.module}/index.html"
  content_type = "text/html"
}

resource "google_storage_bucket_iam_member" "public_rule" {
  bucket = google_storage_bucket.website_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
