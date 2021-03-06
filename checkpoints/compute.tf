# A Backend Service defines a group of virtual machines
# that will serve traffic for load balancing
resource "google_compute_backend_service" "react-web" {
  name        = "cp-lb"
  description = "CP Load Balancer"
  port_name   = "customhttps"
  protocol    = "HTTPS"
  enable_cdn  = false

  backend {
    group = "${google_compute_instance_group_manager.cp-react-app-server-group-manager.instance_group}"
  }

  session_affinity = "GENERATED_COOKIE"
  timeout_sec      = 0

  health_checks = ["${google_compute_https_health_check.cp-app-healthcheck.self_link}"]
}

# when auto scaling, VMs could be created to handle
# increased load, these new VMs use the instance template
# defined below
resource "google_compute_instance_group_manager" "cp-react-app-server-group-manager" {
  name               = "cp-react-app-server-group-manager"
  base_instance_name = "cp-app-instance"
  instance_template  = "${google_compute_instance_template.cp-react-server-template.self_link}"
  zone               = "${var.zone}"
  update_strategy    = "NONE"

  named_port {
    name = "customhttps"
    port = 80
  }
}

resource "google_compute_instance_template" "cp-react-server-template" {
  name_prefix          = "cp-react-server-template-"
  machine_type         = "${var.machine_type}"
  region               = "${var.region}"
  description          = "Base template to create cp react instances"
  instance_description = "Instance created from base template"
  depends_on           = ["google_sql_database_instance.cp-database-instance", "random_id.cp-db-user-password"]
  tags                 = ["${var.env_name}-vof-app-server", "vof-app-server"]

  network_interface {
    subnetwork    = "${google_compute_subnetwork.cp-private-subnetwork.name}"
    access_config = {}
  }

  disk {
    source_image = "${var.vof_disk_image}"
    auto_delete  = true
    boot         = true
    disk_type    = "${var.vof_disk_type}"
    disk_size_gb = "${var.vof_disk_size}"
  }

  metadata {
    databaseUser     = "${random_id.vof-db-user.b64}"
    databasePassword = "${random_id.vof-db-user-password.b64}"
    databaseHost     = "${google_sql_database_instance.vof-database-instance.ip_address.0.ip_address}"
    databasePort     = "5432"
    databaseName     = "andela-flask-api"

    # startup-script     = "/home/vof/start_vof.sh"
    serial-port-enable = 1
  }

  lifecycle {
    create_before_destroy = true
  }

  # the email is the service account email whose service keys have all the roles suffiecient enough
  # for the project to interract with all the APIs it does interract with.
  # the scopes are those that we need for logging and monitoring, they are a must for logging to
  # be carried out.
  # the whole service account argument is required for identity and authentication reasons, if it is
  # not included here, the default service account is used instead.
  service_account {
    email = "${var.service_account_email}"

    scopes = ["https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.read",
      "https://www.googleapis.com/auth/logging.write",
    ]
  }
}

# A Compute Engine Autoscaler automatically adds or removes 
# virtual machines from a managed instance group based on 
# increases or decreases in load. This allows your applications
# to gracefully handle increases in traffic and reduces cost
# when the need for resources is lower. You just define the
# autoscaling policy and the autoscaler performs automatic
# scaling based on the measured load
resource "google_compute_autoscaler" "cp-react-app-autoscaler" {
  name   = "cp-react-app-autoscaler"
  zone   = "${var.zone}"
  target = "${google_compute_instance_group_manager.cp-react-app-server-group-manager.self_link}"

  autoscaling_policy = {
    max_replicas    = "${var.max_instances}"
    min_replicas    = "${var.min_instances}"
    cooldown_period = 60

    cpu_utilization {
      target = 0.7
    }
  }
}

resource "google_compute_https_health_check" "cp-react-app-healthcheck" {
  name                = "cp-react-app-healthcheck"
  port                = 80
  request_path        = "${var.request_path}"
  check_interval_sec  = "${var.check_interval_sec}"
  timeout_sec         = "${var.timeout_sec}"
  unhealthy_threshold = "${var.unhealthy_threshold}"
  healthy_threshold   = "${var.healthy_threshold}"
}
