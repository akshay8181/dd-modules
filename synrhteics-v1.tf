# Pull all available synthetics locations (managed + private)
data "datadog_synthetics_locations" "all" {}

locals {
  # Keep only Private Locations.
  # Datadog private location IDs are prefixed with "pl:".
  private_location_ids = [
    for id, loc in data.datadog_synthetics_locations.all.locations :
    id
    if startswith(id, "pl:")
  ]
}


locals {
  synthetics_raw = yamldecode(
    file("${path.module}/datadog_config/synthetics.yaml")
  )

  synthetics_map = {
    for k, v in local.synthetics_raw.synthetics :
    k => merge(
      v,
      {
        # Force all tests to run on ALL private locations
        locations = local.private_location_ids

        tags = concat(
          lookup(v, "tags", []),
          [
            "cluster:${var.cluster_name}",
            "managed_by:terraform",
            "team:platform",
            "edx_application:kobai",
            "cp_label:${var.dd_cp_label}",
            "cpi_label:${var.dd_cpi_label}",
            "env:${var.dd_environment}"
          ]
        )
      }
    )
  }
}

