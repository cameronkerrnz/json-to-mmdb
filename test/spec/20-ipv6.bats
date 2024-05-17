#!./test/libs/bats/bin/bats

load '../libs/bats-support/load'
load '../libs/bats-assert/load'

@test "[IPv6] Output must be recognised as a MMDB file" {
    run mmdb-dump-metadata --file=output/ipv6-demo.mmdb
    [ $status -eq 0 ]
}

@test "[IPv6] Query IPv6 compatible IPv6 address" {
    run mmdblookup --file=output/ipv6-demo.mmdb --ip=::172.16.0.1 subnet
    assert_output --partial "172.16.0.0/12"
}

@test "[IPv6] Query IPv4 address" {
    run mmdblookup --file=output/ipv6-demo.mmdb --ip=172.16.0.1 subnet
    assert_output --partial "172.16.0.0/12"
}

@test "[IPv6] Input is not an IP address (but instead a subnet): ::172.16.0.0/12" {
    run mmdblookup --file=output/ipv6-demo.mmdb --ip=::172.16.0.0/12 subnet
    [ $status -ne 0 ]
}

@test "[IPv6] VLAN is an integer" {
    run mmdblookup --file=output/ipv6-demo.mmdb --ip=::172.16.0.0 vlan_id
    assert_output --partial '234 <uint32>'
}

@test "[IPv6] No entry for 0.0.0.0" {
    run mmdblookup --file=output/ipv6-demo.mmdb --ip=0.0.0.0 vlan_id
    assert_output --partial 'Could not find an entry for this IP address'
}

@test "[IPv6] No entry for ::" {
    run mmdblookup --file=output/ipv6-demo.mmdb --ip=:: vlan_id
    assert_output --partial 'Could not find an entry for this IP address'
}

@test "[IPv6] Querying for a basic global" {
    run mmdblookup --file=output/ipv6-demo.mmdb --ip=2001:7f8:18::55 name
    assert_output --partial 'Root Name Servers'
}

@test "[IPv6] Test that very long prefixes are still separated (Pitter)" {
    run mmdblookup --file=output/ipv6-demo.mmdb --ip=2001:4860:4860::8888 name
    assert_output --partial 'Pitter'
}

@test "[IPv6] Test that very long prefixes are still separated (Patter)" {
    run mmdblookup --file=output/ipv6-demo.mmdb --ip=2001:4860:4860::8844 name
    assert_output --partial 'Patter'
}
