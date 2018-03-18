# Begin HTTP
resource "google_compute_global_forwarding_rule" "cp-http" {
  name       = "cp-http-fr"
  ip_address = "${var.reserved_env_ip}"
  target     = "${google_compute_target_http_proxy.cp-http-proxy.self_link}"
  port_range = "80"
}

resource "google_compute_target_http_proxy" "cp-http-proxy" {
  name    = "cp-http-proxy"
  url_map = "${google_compute_url_map.cp-http-url-map.self_link}"
}

# End HTTP

# Begin HTTPS
resource "google_compute_global_forwarding_rule" "cp-https" {
  name       = "cp-https-fr"
  ip_address = "${var.reserved_env_ip}"
  target     = "${google_compute_target_https_proxy.cp-https-proxy.self_link}"
  port_range = "443"
}

resource "google_compute_ssl_certificate" "cp-ssl-certificate" {
  name_prefix = "cp-certificate-"
  description = "CP HTTPS certificate"
  private_key = "${file("../shared/andela_key.key")}"
  certificate = "${file("../shared/andela_certificate.crt")}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_target_https_proxy" "cp-https-proxy" {
  name             = "cp-https-proxy"
  url_map          = "${google_compute_url_map.cp-http-url-map.self_link}"
  ssl_certificates = ["${google_compute_ssl_certificate.cp-ssl-certificate.self_link}"]
}

# End HTTPS

resource "google_compute_url_map" "cp-http-url-map" {
  name            = "cp-url-map"
  default_service = "${google_compute_backend_service.web.self_link}"

  host_rule {
    hosts        = ["${var.reserved_env_ip}"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = "${google_compute_backend_service.web.self_link}"

    path_rule {
      paths   = ["/*"]
      service = "${google_compute_backend_service.web.self_link}"
    }
  }
}

resource "google_compute_firewall" "cp-internal-firewall" {
  name    = "cp-internal-network"
  network = "${google_compute_network.cp-network.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = ["${var.ip_cidr_range}",
    "${google_compute_instance.vof-jumpbox.network_interface.0.access_config.0.assigned_nat_ip}",
  ]
}

resource "google_compute_firewall" "cp-public-firewall" {
  name    = "cp-public-firewall"
  network = "${google_compute_network.cp-network.name}"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["cp-lb"]
}

resource "google_compute_firewall" "cp-allow-healthcheck-firewall" {
  name    = "cp-allow-healthcheck-firewall"
  network = "${google_compute_network.vof-network.name}"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.env_name}-vof-app-server", "vof-app-server"]
}

resource "google_compute_firewall" "cp-ssh-firewall" {
  name    = "cp-ssh-firewall"
  network = "${google_compute_network.vof-network.name}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}
