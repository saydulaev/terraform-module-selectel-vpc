locals {
  _subnets = flatten(
    [for subnet_group in keys(var.subnets) :
      [for idx, cidr in var.subnets[subnet_group].cidrs :
        merge(
          {
            name              = format("%s-%s", subnet_group, idx)
            description       = try(var.subnets[subnet_group].description, null)
            cidr              = cidr
            prefix_length     = var.create_subnetpool ? try(var.subnets[subnet_group].prefix_length, 24) : null
            ipv6_address_mode = try(var.subnets[subnet_group].ipv6_address_mode, null)
            ipv6_ra_mode      = try(var.subnets[subnet_group].ipv6_ra_mode, null)
            allocation_pool   = try(var.subnets[subnet_group].allocation_pool, null)
            gateway_ip        = try(var.subnets[subnet_group].gateway_ip, null)
            no_gateway        = try(var.subnets[subnet_group].no_gateway, null)
            enable_dhcp       = try(var.subnets[subnet_group].enable_dhcp, true)
            dns_nameservers   = try(var.subnets[subnet_group].dns_nameservers, null)
            value_specs       = try(var.subnets[subnet_group].value_specs, null)
            ip_version        = try(var.subnets[subnet_group].ip_version, null)
            tenant_id         = try(var.subnets[subnet_group].tenant_id, null)
            subnetpool_id     = var.create_subnetpool ? openstack_networking_subnetpool_v2.this[coalesce(try(var.subnets[subnet_group].subnetpool_name, null), var.subnetpools[0].name)].id : null
            network_id        = openstack_networking_network_v2.this.id
            acl_group         = subnet_group
            subnet_group      = subnet_group
            default_routes    = setsubtract(var.subnets[subnet_group].cidrs, [cidr])
            tags = [
              "SubnetGroup=${lower(subnet_group)}",
              "Network=${lower(var.name)}"
            ]
          }
        )
      ]
    ]
  )

  subnet_routes = flatten(
    [for subnet_group in keys(var.subnets) :
      [for idx, cidr in var.subnets[subnet_group].cidrs :
        try(var.subnets[subnet_group].routes, []) != null ?
        [for route in setsubtract(var.subnets[subnet_group].routes, var.subnets[subnet_group].cidrs) :
          merge({
            cidr             = cidr
            destination_cidr = route
            next_hop         = cidrhost(cidr, 1)
          })
        ] : []
      ]
    ]
  )

  subnets     = { for subnet in local._subnets : subnet.cidr => subnet }
  subnetpools = { for pool in var.subnetpools : pool.name => pool }
}


// Create a network.
resource "openstack_networking_network_v2" "this" {
  name                    = var.name
  description             = var.description
  shared                  = var.shared
  external                = var.external
  tenant_id               = var.tenant_id
  admin_state_up          = var.admin_state_up
  value_specs             = var.value_specs
  availability_zone_hints = var.availability_zone_hints
  transparent_vlan        = var.transparent_vlan
  port_security_enabled   = var.port_security_enabled
  mtu                     = var.mtu
  dns_domain              = var.dns_domain
  qos_policy_id           = var.qos_policy_id

  dynamic "segments" {
    for_each = var.segments != null ? [1] : []
    content {
      physical_network = var.segments.physical_network
      segmentation_id  = var.segments.segmentation_id
      network_type     = var.segments.network_type
    }
  }

  tags = setunion(var.tags)
}

// Create a subnet pool.
resource "openstack_networking_subnetpool_v2" "this" {
  for_each = var.create_subnetpool ? local.subnetpools : {}

  name              = each.key
  region            = try(each.value.region, null)
  prefixes          = try(each.value.prefixes, [])
  default_prefixlen = try(each.value.default_prefixlen, 24)
  min_prefixlen     = try(each.value.min_prefixlen, 16)
  max_prefixlen     = try(each.value.max_prefixlen, 32)
  shared            = try(each.value.shared, false)
  description       = try(each.value.description, null)
  is_default        = try(each.value.is_default, false)
  value_specs       = try(each.value.value_specs, null)
  default_quota     = try(each.value.default_quota, null)
  project_id        = coalesce(try(each.value.project_id, null), each.value.tenant_id)
  address_scope_id  = try(each.value.address_scope_id, null)

  tags = setunion(var.tags)
}

// Create a network subnets.
resource "openstack_networking_subnet_v2" "this" {
  for_each = local.subnets

  name              = each.value.name
  description       = each.value.description
  network_id        = each.value.network_id
  cidr              = each.value.cidr
  prefix_length     = each.value.prefix_length
  ipv6_address_mode = each.value.ipv6_address_mode
  ipv6_ra_mode      = each.value.ipv6_ra_mode
  gateway_ip        = each.value.gateway_ip
  no_gateway        = each.value.no_gateway
  enable_dhcp       = each.value.enable_dhcp
  dns_nameservers   = each.value.dns_nameservers
  value_specs       = each.value.value_specs
  ip_version        = each.value.ip_version
  subnetpool_id     = each.value.subnetpool_id
  tenant_id         = each.value.tenant_id
  dynamic "allocation_pool" {
    for_each = try(each.value.allocation_pool, null) != null ? each.value.allocation_pool : []
    iterator = pool
    content {
      start = pool.value.start
      end   = pool.value.end
    }
  }

  tags = setunion(concat(var.tags, try(each.value.tags, [])))

  depends_on = [
    openstack_networking_network_v2.this
  ]

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

// Create a router.
resource "openstack_networking_router_v2" "this" {
  name                = var.name
  description         = "Router ${var.name}"
  admin_state_up      = var.router_admin_state_up
  distributed         = var.router_distributed
  external_network_id = var.router_external_network_id
  enable_snat         = var.router_enable_snat
  dynamic "external_fixed_ip" {
    for_each = var.router_external_fixed_ip != null ? var.router_external_fixed_ip : {}
    content {
      subnet_id  = try(external_fixed_ip.value.subnet_id, null)
      ip_address = try(external_fixed_ip.value.ip_address, null)
    }
  }
  external_subnet_ids = var.router_external_subnet_ids
  tenant_id           = var.router_tenant_id
  value_specs         = var.router_value_specs
  vendor_options {
    set_router_gateway_after_create = true
  }
  availability_zone_hints = var.availability_zone_hints
  tags                    = setunion(var.tags)

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

// Create a router port with fixed IP in each subnet.
resource "openstack_networking_port_v2" "this" {
  for_each = var.create_router_port_for_subnet ? local.subnets : {}

  name       = "${var.name}-${each.value.cidr}"
  network_id = openstack_networking_network_v2.this.id
  tenant_id  = each.value.tenant_id

  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.this[each.value.cidr].id
    ip_address = cidrhost(each.value.cidr, 1)
  }
}

// Attach a router to subnet
resource "openstack_networking_router_interface_v2" "this" {
  for_each = local.subnets

  router_id = openstack_networking_router_v2.this.id
  subnet_id = var.create_router_port_for_subnet ? null : openstack_networking_subnet_v2.this[each.value.cidr].id
  port_id   = var.create_router_port_for_subnet ? openstack_networking_port_v2.this[each.value.cidr].id : null
}

// Create subnet routes.
resource "openstack_networking_subnet_route_v2" "this" {
  for_each = length(local.subnet_routes) > 0 ? { for r in local.subnet_routes : r.cidr => r } : {}

  subnet_id        = openstack_networking_subnet_v2.this[each.key].id
  destination_cidr = each.value.destination_cidr
  next_hop         = each.value.next_hop

  depends_on = [
    openstack_networking_subnet_v2.this
  ]
}

// Create additional Neutron router route entries.
resource "openstack_networking_router_route_v2" "this" {
  for_each = var.router_routes != null ? toset(var.router_routes) : []

  router_id        = openstack_networking_router_v2.this.id
  destination_cidr = each.value.destination_cidr
  next_hop         = each.value.next_hop

  depends_on = [
    openstack_networking_router_interface_v2.this
  ]
}

// Create a default SG.
resource "openstack_networking_secgroup_v2" "this" {
  count = var.create_network_default_secgroup ? 1 : 0

  name        = "${var.name}-default-secgroup"
  description = "${var.name}-default-secgroup"
  tenant_id   = var.tenant_id

  tags = setunion(var.tags)

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

// Create SG rules.
resource "openstack_networking_secgroup_rule_v2" "rule" {
  for_each = var.create_network_default_secgroup && length(var.network_default_secgroup_rules) > 0 ? toset(var.network_default_secgroup_rules) : []

  direction         = each.value.direction
  ethertype         = each.value.ethertype
  protocol          = each.value.protocol
  port_range_min    = each.value.port_range_min
  port_range_max    = each.value.port_range_max
  remote_ip_prefix  = each.value.remote_ip_prefix
  security_group_id = one(openstack_networking_secgroup_v2.this[*].id)
  tenant_id         = try(each.value.tenant_id, null)

  depends_on = [
    openstack_networking_secgroup_v2.this
  ]
}
