variable "name" {
  description = "The name of a new VPC."
  type        = string
}

variable "description" {
  description = "Human-readable description of the network."
  type        = string
  default     = null
}

variable "shared" {
  description = "Specifies whether the network resource can be accessed by any tenant or not."
  type        = bool
  default     = false
}

variable "external" {
  description = "Specifies whether the network resource has the external routing facility."
  type        = bool
  default     = false
}

variable "tenant_id" {
  description = "The owner of the network."
  type        = string
  default     = null
}

variable "admin_state_up" {
  description = "The administrative state of the network."
  type        = bool
  default     = null

  validation {
    condition     = var.admin_state_up == null || (var.admin_state_up == true || var.admin_state_up == false)
    error_message = "Acceptable values are `true` and `false`."
  }
}

variable "segments" {
  description = "An array of one or more provider segment objects."
  type = object({
    physical_network = string // The physical network where this network is implemented.
    segmentation_id  = string // An isolated segment on the physical network.
    network_type     = string // The type of physical network.
  })
  default = null
}

variable "value_specs" {
  description = "Map of additional options."
  type        = map(string)
  default     = null
}

variable "availability_zone_hints" {
  description = "An availability zone is used to make network resources highly available."
  type        = list(string)
  default     = null
}

variable "transparent_vlan" {
  description = "Specifies whether the network resource has the VLAN transparent attribute set."
  type        = bool
  default     = null
}

variable "port_security_enabled" {
  description = "Whether to explicitly enable or disable port security on the network."
  type        = bool
  default     = true
}

variable "mtu" {
  description = <<EOT
    The network MTU.
     Available for read-only, when Neutron net-mtu extension is enabled. 
     Available for the modification, 
     when Neutron net-mtu-writable extension is enabled.
     EOT
  type        = number
  default     = null
}

variable "dns_domain" {
  description = "The network DNS domain."
  type        = string
  default     = null
}

variable "qos_policy_id" {
  description = "Reference to the associated QoS policy."
  type        = string
  default     = null
}

variable "tags" {
  description = "A set of string tags for the network."
  type        = list(string)
  default     = null
}


variable "subnets" {
  description = "Subnets array"
  type = map(object({
    description       = optional(string)       // Human-readable description of the subnet. Changing this updates the name of the existing subnet.
    network_id        = optional(string)       // The UUID of the parent network. Changing this creates a new subnet.
    enable_dhcp       = optional(bool)         // The administrative state of the network. Acceptable values are "true" and "false". Changing this value enables or disables the DHCP capabilities of the existing subnet. Defaults to true.
    subnetpool_name   = optional(string)       // The name of subnet pool from variable `subnetpools`.
    public            = optional(bool)         // Whether subnet is public
    cidrs             = optional(list(string)) // Array of cidrs.
    prefix_length     = optional(number)       // The prefix length to use when creating a subnet from a subnet pool. The default subnet pool prefix length that was defined when creating the subnet pool will be used if not provided. Changing this creates a new subnet.
    ip_version        = optional(string)       //  IP version, either 4 (default) or 6. Changing this creates a new subnet.
    ipv6_address_mode = optional(string)       // The IPv6 address mode. Valid values are `dhcpv6-stateful`, `dhcpv6-stateless`, or `slaac`.
    ipv6_ra_mode      = optional(string)       // The IPv6 Router Advertisement mode. Valid values are `dhcpv6-stateful`, `dhcpv6-stateless`, or `slaac`.
    tenant_id         = optional(string)       // The owner of the subnet. Required if admin wants to create a subnet for another tenant. Changing this creates a new subnet.
    allocation_pool = optional(list(list(object({
      start = string                         // The starting address.
      end   = string                         // The ending address.
    }))))                                    // A block declaring the start and end range of the IP addresses available for use with DHCP in this subnet. Multiple allocation_pool blocks can be declared, providing the subnet with more than one range of IP addresses to use with DHCP. However, each IP range must be from the same CIDR that the subnet is part of. The allocation_pool block is documented below.
    gateway_ip      = optional(string)       // Default gateway used by devices in this subnet. Leaving this blank and not setting no_gateway will cause a default gateway of .1 to be used. Changing this updates the gateway IP of the existing subnet.
    no_gateway      = optional(bool)         // Do not set a gateway IP on this subnet. Changing this removes or adds a default gateway IP of the existing subnet.
    enable_dhcp     = optional(bool)         // The administrative state of the network. Acceptable values are "true" and "false". Changing this value enables or disables the DHCP capabilities of the existing subnet. Defaults to true.
    dns_nameservers = optional(list(string)) // An array of DNS name server names used by hosts in this subnet. Changing this updates the DNS name servers for the existing subnet.
    subnetpool_id   = optional(string)       // The ID of the subnetpool associated with the subnet.
    value_specs     = optional(map(string))  // Map of additional options.
    routes          = optional(list(string)) // List of destination cidrs route for subnet (subnet default router will be used as next_hop).
  }))
  default = {}
}

variable "subnetpools" {
  description = "The pool array."
  type = list(object({
    name              = string                 // The name of the subnetpool. Changing this updates the name of the existing subnetpool.
    default_quota     = optional(string)       // The per-project quota on the prefix space that can be allocated from the subnetpool for project subnets. Changing this updates the default quota of the existing subnetpool.
    project_id        = optional(string)       // The owner of the subnetpool. Required if admin wants to create a subnetpool for another project. Changing this creates a new subnetpool.
    prefixes          = optional(list(string)) // A list of subnet prefixes to assign to the subnetpool. Neutron API merges adjacent prefixes and treats them as a single prefix. Each subnet prefix must be unique among all subnet prefixes in all subnetpools that are associated with the address scope. Changing this updates the prefixes list of the existing subnetpool.
    default_prefixlen = optional(number)       // The size of the prefix to allocate when the cidr or prefixlen attributes are omitted when you create the subnet. Defaults to the MinPrefixLen. Changing this updates the default prefixlen of the existing subnetpool.
    min_prefixlen     = optional(number)       // The smallest prefix that can be allocated from a subnetpool. For IPv4 subnetpools, default is 8. For IPv6 subnetpools, default is 64. Changing this updates the min prefixlen of the existing subnetpool.
    max_prefixlen     = optional(number)       // The maximum prefix size that can be allocated from the subnetpool. For IPv4 subnetpools, default is 32. For IPv6 subnetpools, default is 128. Changing this updates the max prefixlen of the existing subnetpool.
    address_scope_id  = optional(string)       // The Neutron address scope to assign to the subnetpool. Changing this updates the address scope id of the existing subnetpool.
    shared            = optional(bool)         //  Indicates whether this subnetpool is shared across all projects. Changing this updates the shared status of the existing subnetpool.
    description       = optional(string)       // The human-readable description for the subnetpool. Changing this updates the description of the existing subnetpool.
    is_default        = optional(bool)         // Indicates whether the subnetpool is default subnetpool or not. Changing this updates the default status of the existing subnetpool.
    value_specs       = optional(map(string))  // Map of additional options.
  }))
  default = null
}

variable "router_admin_state_up" {
  description = <<EOT
    Administrative up/down status for the router
    (must be "true" or "false" if provided).
    Changing this updates the admin_state_up of an existing router.
  EOT
  type        = bool
  default     = null
}

variable "router_distributed" {
  description = <<EOT
    Indicates whether or not to create a distributed router.
    The default policy setting in Neutron restricts usage of 
    this property to administrative users only.
  EOT
  type        = bool
  default     = null
}

variable "router_external_network_id" {
  description = <<EOT
    The network UUID of an external gateway for the router.
    A router with an external gateway is required if any compute 
    instances or load balancers will be using floating IPs. 
    Changing this updates the external gateway of the router.
  EOT
  type        = string
  default     = null
}

variable "router_enable_snat" {
  description = <<EOT
    Enable Source NAT for the router. 
    Valid values are "true" or "false". 
    An external_network_id has to be set in order to set this property. 
    Changing this updates the enable_snat of the router. 
    Setting this value requires an ext-gw-mode extension to be enabled 
    in OpenStack Neutron.
  EOT
  type        = bool
  default     = null
}

variable "router_external_fixed_ip" {
  description = <<EOT
    An external fixed IP for the router. 
    This can be repeated. The structure is described below. 
    An external_network_id has to be set in order to set this property. 
    Changing this updates the external fixed IPs of the router.
  EOT
  type = object({
    subnet_id  = optional(string) // Subnet in which the fixed IP belongs to.
    ip_address = optional(string) // The IP address to set on the router.
  })
  default = null
}

variable "router_external_subnet_ids" {
  description = <<EOT
    A list of external subnet IDs to try over each to obtain a fixed IP for the router. 
    If a subnet ID in a list has exhausted floating IP pool, 
    the next subnet ID will be tried. This argument is used only during 
    the router creation and allows to set only one external fixed IP. 
    Conflicts with an external_fixed_ip argument.
  EOT
  type        = list(string)
  default     = null
}

variable "router_tenant_id" {
  description = <<EOT
    The owner of the floating IP. 
    Required if admin wants to create a router for another tenant. 
    Changing this creates a new router.
  EOT
  type        = string
  default     = null
}

variable "router_value_specs" {
  description = "Map of additional driver-specific options."
  type        = map(string)
  default     = null
}

variable "create_network_default_secgroup" {
  description = "Whether default SG should be created."
  type        = bool
  default     = false
}

variable "network_default_secgroup_rules" {
  description = "Default SG rules."
  type = list(object({
    description      = optional(string)       // A description of the rule. Changing this creates a new security group rule.
    direction        = string                 // The direction of the rule, valid values are ingress or egress. Changing this creates a new security group rule.
    ethertype        = string                 // The layer 3 protocol type, valid values are IPv4 or IPv6. Changing this creates a new security group rule.
    protocol         = string                 // The layer 4 protocol type, valid values are following. Changing this creates a new security group rule. This is required if you want to specify a port range. [tcp,udp,icmp,ah,dccp,egp,esp,gre,igmp,ipv6-encap,ipv6-frag,ipv6-icmp,ipv6-nonxt,ipv6-opts,ipv6-route,ospf,pgm,rsvp,sctp,udplite,vrrp]
    port_range_min   = number                 // The lower part of the allowed port range, valid integer value needs to be between 1 and 65535. Changing this creates a new security group rule.
    port_range_max   = number                 // The higher part of the allowed port range, valid integer value needs to be between 1 and 65535. Changing this creates a new security group rule.
    remote_ip_prefix = string                 // The remote CIDR, the value needs to be a valid CIDR (i.e. 192.168.0.0/16). Changing this creates a new security group rule.
    tenant_id        = optional(string, null) // Required if admin wants to create a port for another tenant. 
  }))
  default = [{
    direction        = "ingress"
    ethertype        = "IPv4"
    port_range_max   = 22
    port_range_min   = 22
    protocol         = "tcp"
    remote_ip_prefix = "0.0.0.0/0"
  }]
}

variable "create_subnetpool" {
  description = "Create a subnet pool or not."
  type        = bool
  default     = false
}

variable "create_router_port_for_subnet" {
  description = <<EOT
    Create a router port for each subnet 
    with ip assigned by `cidrhost(cidr, 1)`
    EOT
  type        = bool
  default     = false
}

variable "router_routes" {
  description = "List of route entry objects for Neutron router resource."
  type = list(object({
    destination_cidr = string
    next_hop         = string
  }))
  default = null
}