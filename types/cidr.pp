# @summary A type representing IPv4 & IPv6 CIDR notation
#
# The CIDR used for an anycast service can be either IPv4 or IPv6.
# This type creates a shorthand way of referencing stdlib's validation of either.
#
type Anycast_services::CIDR = Variant[Stdlib::IP::Address::V4::CIDR, Stdlib::IP::Address::V6::CIDR]
