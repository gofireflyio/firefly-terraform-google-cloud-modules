# Create additional disk volume for instance
resource "google_compute_disk" "storage_disk" {
  count = var.disk_storage_enabled ? 1 : 0

  labels = var.labels
  name   = "${var.instance_name}-storage-disk"
  size   = var.disk_storage_size
  type   = "pd-ssd"
  zone   = var.gcp_region_zone
}

# Create an external IP for the instance
resource "google_compute_address" "external_ip" {
  address_type = "EXTERNAL"
  description  = "External IP for ${var.instance_description}"
  name   = "${var.instance_name}-network-ip"
  region = var.gcp_region
}

# Create a Google Compute Engine VM instance
resource "google_compute_instance" "instance" {
  description         = var.instance_description
  deletion_protection = var.gcp_deletion_protection
  hostname            = var.dns_create_record ? trimsuffix("${var.instance_name}.${data.google_dns_managed_zone.dns_zone[0].dns_name}", ".") : null
  name                = var.instance_name
  machine_type        = var.gcp_machine_type
  zone                = var.gcp_region_zone

  # Base disk for the OS
  boot_disk {
    initialize_params {
      type  = "pd-ssd"
      image = var.gcp_image
      size  = var.disk_boot_size
    }
    auto_delete = "true"
  }

  dynamic "attached_disk" {
    for_each = google_compute_disk.storage_disk
    content {
      source = attached_disk.value.self_link
      mode   = "READ_WRITE"
      device_name = "storage-disk"
    }
  }

  labels = var.labels

  # Attach the primary network interface to the VM
  network_interface {
    subnetwork = var.gcp_subnetwork
    access_config {
      nat_ip = google_compute_address.external_ip.address
    }
  }

  # This sets a custom SSH key on the instance and prevents the OS Login and GCP
  # project-level SSH keys from working. This is commented out since we use
  # project-level SSH keys.
  # https://console.cloud.google.com/compute/metadata?project=my-project-name&authuser=1&supportedpurview=project
  #
  # metadata {
  #   sshKeys = "ubuntu:${file("keys/${var.ssh_public_key}.pub")}"
  # }

  # Execute the script to format & mount /var/opt
  metadata = {
    startup-script = var.disk_storage_enabled ? file("${path.module}/init/mnt_dir.sh") : null
    MOUNT_DIR      = var.disk_storage_mount_path
    REMOTE_FS      = "/dev/disk/by-id/google-storage-disk"
  }

  scheduling {
    on_host_maintenance = "MIGRATE"
    automatic_restart   = var.gcp_preemptible ? "false" : "true"
    preemptible         = var.gcp_preemptible
  }

  # Tags in GCP are only used for network and firewall rules. Any metadata is
  # defined as a label (see above).
  tags = var.gcp_network_tags

}