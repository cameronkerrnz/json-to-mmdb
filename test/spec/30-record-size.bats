#!./test/libs/bats/bin/bats

load '../libs/bats-support/load'
load '../libs/bats-assert/load'

@test "[record-size] File must convert" {
    rm -f output/record-size.mmdb
    run app/json-to-mmdb --input=input/record-size.json --output=output/record-size.mmdb
    [ "$status" -eq 0 ]
}

@test "[record-size] Converted file must be show evidence of record size" {
    run mmdb-dump-metadata --file=output/record-size.mmdb
    [ $status -eq 0 ]
    assert_output --partial "record size:           28 bits"
}

@test "[record-size] Test a basic lookup" {
    run mmdblookup --file=output/record-size.mmdb --ip=172.16.0.1 subnet
    assert_output --partial "172.16.0.0/12"
}
