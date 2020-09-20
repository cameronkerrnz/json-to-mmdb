#!./test/libs/bats/bin/bats

load '../libs/bats-support/load'
load '../libs/bats-assert/load'

@test "Non-MMDB should fail to be recognised as a MMDB file" {
    run mmdb-dump-metadata --file=input/demo.json
    [ $status -ne 0 ]
}

@test "Output must be recognised as a MMDB file" {
    run mmdb-dump-metadata --file=output/demo.mmdb
    [ $status -eq 0 ]
}

@test "Correct subnet should be found for 172.16.0.1" {
    run mmdblookup --file=output/demo.mmdb --ip=172.16.0.1 subnet
    assert_output --partial "172.16.0.0/12"
}

@test "Strings are stored in NFC Unicode Normal Form" {
    run mmdblookup --file=output/demo.mmdb --ip=10.64.0.1 name
    # If it was NFKC, then the ligature would present as the three characters 'ffi'
    assert_output --partial '"Unicode NFKC Test (ﬃ)" <utf8_string>'
}

@test "Input is not an IP: 172.16.0.0/12" {
    run mmdblookup --file=output/demo.mmdb --ip=172.16.0.0/12 subnet
    [ $status -ne 0 ]
}

@test "Input is an IPv6 address in a IPv4 database" {
    run mmdblookup --file=output/demo.mmdb --ip=::172.16.0.0
    assert_output --partial 'You attempted to look up an IPv6 address in an IPv4-only database'
}

@test "VLAN is an integer" {
    run mmdblookup --file=output/demo.mmdb --ip=172.16.0.0 vlan_id
    assert_output --partial '234 <uint32>'
}

@test "No entry for 0.0.0.0" {
    run mmdblookup --file=output/demo.mmdb --ip=0.0.0.0 vlan_id
    assert_output --partial 'Could not find an entry for this IP address'
}
