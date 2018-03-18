resource "google_compute_backend_service" "redis-front" {
  name        = "vof-redis-server-lb"
  description = "VOF Redis server Load Balancer"
  port_name   = "customhttps"
  protocol    = "HTTPS"
  enable_cdn  = false

  backend {
    group = "${google_compute_instance_group_manager.vof-redis-server-group-manager.instance_group}"
  }

  session_affinity = "GENERATED_COOKIE"

  timeout_sec   = 0
  health_checks = ["${google_compute_https_health_check.vof-redis-server-healthcheck.self_link}"]
}

resource "google_compute_instance_group_manager" "vof-redis-server-group-manager" {
  name               = "vof-redis-server-group-manager"
  base_instance_name = "vof-redis-server"
  instance_template  = "${google_compute_instance_template.vof-redis-server-template.self_link}"
  zone               = "${var.zone}"
  update_strategy    = "NONE"

  named_port {
    name = "customhttps"
    port = 7379
  }
}

resource "google_compute_instance_template" "vof-redis-server-template" {
  name_prefix          = "vof-redis-server-template"
  machine_type         = "${var.small_machine_type}"
  region               = "${var.region}"
  description          = "Base template to create redis instances"
  instance_description = "Instance created from base redis template"
  tags                 = ["redis-server"]

  network_interface {
    subnetwork    = "${google_compute_subnetwork.vof-private-subnetwork.name}"
    access_config = {}
  }

  disk {
    source_image = "${var.redis_disk_image}"
    auto_delete  = true
    boot         = true
    disk_type    = "${var.redis_disk_type}"
    disk_size_gb = "${var.redis_disk_size}"
  }

  lifecycle {
    create_before_destroy = true
  }

  service_account {
    email = "${var.service_account_email}"

    scopes = ["https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.read",
      "https://www.googleapis.com/auth/logging.write",
    ]
  }
}

resource "google_compute_autoscaler" "vof-redis-server-autoscaler" {
  name   = "vof-redis-server-autoscaler"
  zone   = "${var.zone}"
  target = "${google_compute_instance_group_manager.vof-redis-server-group-manager.self_link}"

  autoscaling_policy = {
    max_replicas    = "${var.max_redis_instances}"
    min_replicas    = "${var.min_redis_instances}"
    cooldown_period = 60

    cpu_utilization {
      target = 0.7
    }
  }
}

resource "google_compute_https_health_check" "vof-redis-server-healthcheck" {
  name                = "vof-redis-server-healthcheck"
  port                = 7379
  request_path        = "${var.redis_request_path}"
  check_interval_sec  = "${var.check_interval_sec}"
  timeout_sec         = "${var.timeout_sec}"
  unhealthy_threshold = "${var.unhealthy_threshold}"
  healthy_threshold   = "${var.healthy_threshold}"
}

resource "google_compute_firewall" "vof-redis-traffic-firewall" {
  name    = "vof-redis-firewall"
  network = "${google_compute_network.vof-network.name}"

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  allow {
    protocol = "tcp"
    ports    = ["7379"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["redis-server"]
}
