output "network" {
  description = "All atributes exported from network resource."
  value       = openstack_networking_network_v2.this
}

output "subnets" {
  description = "Subnets exported attributes."
  value       = { for subnet in local.subnets : subnet.cidr => openstack_networking_subnet_v2.this[subnet.cidr] }
}

output "subnetpool" {
  description = "Subnet pools exported attributes."
  value       = var.create_subnetpool ? { for pool in var.subnetpools : pool.name => openstack_networking_subnetpool_v2.this[pool.name] } : {}
}

output "default_network_secgroup" {
  description = "Security group exported attributes."
  value       = one(openstack_networking_secgroup_v2.this[*])
}

output "secgroup_rules" {
  description = "Security group rules exported attributes."
  value       = one(openstack_networking_secgroup_rule_v2.rule[*])
}

output "router" {
  description = "Network router exported attributes."
  value       = openstack_networking_router_v2.this
}

output "router_interfaces" {
  description = "Network router interfaces exported attributes."
  value       = [for subnet in local.subnets : openstack_networking_router_interface_v2.this[subnet.cidr]]
}

output "locals_debug" {
  description = "Show module local vars from parent module."
  value = {
    raw_subnets   = var.subnets
    subnets       = local.subnets
    subnet_routes = local.subnet_routes
    subnetpools   = local.subnetpools
  }
}