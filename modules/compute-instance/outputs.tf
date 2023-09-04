###############################################################################
# Google Compute Instance Configuration Module
# -----------------------------------------------------------------------------
# outputs.tf
###############################################################################

output "disk_boot" {
  value = {
    size = var.disk_boot_size
  }
}

output "disk_storage" {
  value = {
    enabled    = var.disk_storage_enabled
    mount_path = var.disk_storage_mount_path
    size       = var.disk_storage_size
  }
}

output "dns" {
  value = {
    create_record = var.dns_create_record
    ttl           = var.dns_create_record ? var.dns_ttl : "null"
    zone_fqdn     = var.dns_create_record ? data.google_dns_managed_zone.dns_zone[0].dns_name : "null"
    zone_name     = var.dns_create_record ? data.google_dns_managed_zone.dns_zone[0].name : "null"
    instance_fqdn = var.dns_create_record ? "${var.instance_name}.${data.google_dns_managed_zone.dns_zone[0].dns_name}" : "null"
  }
}

output "gcp" {
  value = {
    deletion_protection = var.gcp_deletion_protection
    image               = var.gcp_image
    machine_type        = var.gcp_machine_type
    project             = var.gcp_project
    region              = var.gcp_region
    region_zone         = var.gcp_region_zone
  }
}

output "instance" {
  value = {
    description = google_compute_instance.instance.description
    hostname    = google_compute_instance.instance.hostname
    id          = google_compute_instance.instance.id
    name        = google_compute_instance.instance.name
    self_link   = google_compute_instance.instance.self_link
  }
}

output "labels" {
  value = var.labels
}

output "network" {
  value = {
    external_ip = google_compute_address.external_ip.address
    internal_ip = google_compute_instance.instance.network_interface[0].network_ip
    subnetwork  = var.gcp_subnetwork
    tags        = var.gcp_network_tags
  }
}
