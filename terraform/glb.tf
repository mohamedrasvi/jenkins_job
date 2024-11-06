resource "google_compute_global_address" "static_ip" {
  name = "static-ip"
}

resource "google_compute_managed_ssl_certificate" "website_ssl" {
  name = "website-ssl-cert"
  managed {
    domains = ["example.com"]  # Replace with your domain or IP
  }
}

resource "google_compute_backend_bucket" "website_backend" {
  name   = "website-backend"
  bucket_name = module.gcs_website.bucket_name
}

resource "google_compute_url_map" "website_url_map" {
  name            = "website-url-map"
  default_service = google_compute_backend_bucket.website_backend.self_link
}

resource "google_compute_target_https_proxy" "https_proxy" {
  name             = "https-proxy"
  url_map          = google_compute_url_map.website_url_map.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.website_ssl.self_link]
}

resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
  name        = "https-forwarding-rule"
  target      = google_compute_target_https_proxy.https_proxy.self_link
  port_range  = "443"
  ip_address  = google_compute_global_address.static_ip.address
}
