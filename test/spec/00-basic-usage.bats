#!./test/libs/bats/bin/bats

load '../libs/bats-support/load'
load '../libs/bats-assert/load'

@test "Help must be given" {
    run app/json-to-mmdb --help
    [ "$status" -eq 255 ]
    assert_output --partial "Usage:"
}

@test "Must not only provide input" {
    run app/json-to-mmdb --input=input/demo.json
    [ "$status" -eq 255 ]
}

@test "Must not only provide output" {
    run app/json-to-mmdb --output=output/demo.json
    [ "$status" -eq 255 ]
}

@test "Basic conversion (demo.json to demo.mmdb) must work" {
    run app/json-to-mmdb --input=input/demo.json --output=output/demo.mmdb
    [ "$status" -eq 0 ]
}

@test "Converted file must be show evidence of default record size" {
    run mmdb-dump-metadata --file=output/demo.mmdb
    [ $status -eq 0 ]
    assert_output --partial "record size:           24 bits"
}

@test "Basic conversion for IPv6 must work" {
    run app/json-to-mmdb --input=input/ipv6-demo.json --output=output/ipv6-demo.mmdb
    [ "$status" -eq 0 ]
}

@test "Converted file must be show evidence of IPv6" {
    run mmdb-dump-metadata --file=output/ipv6-demo.mmdb
    [ $status -eq 0 ]
    assert_output --partial "IP version:            6"
}
