# JSON to MMDB (MaxMind DataBase)

![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/cameronkerrnz/json-to-mmdb) ![Docker Cloud Automated build](https://img.shields.io/docker/cloud/automated/cameronkerrnz/json-to-mmdb) ![GitHub issues](https://img.shields.io/github/issues/cameronkerrnz/json-to-mmdb)

The MaxMind DataBase (MMDB) format is very useful for storing
information about IP ranges and quickly answering questions
about the part of the network that IP belongs to.
Classically, this is designed with a use-case of Global GeoIP
services, which is the business MaxMind are involved in.
But imagine other similar use-cases, where you want to get
information about your own network, and want to know, given
and IP, attributes such as VLAN ID or name, subnet, physical location, or special attributes such as:

- type of traffic expected on this subnet (eg. user, server, devices, etc.)
- contact / support information for that subnet
- whether this is an IP known to be a NAT gateway
- whether this is a VPN, DMZ, Datacenter, Distribution, Access Layer, etc.
- the mind wanders with possibilities.

This effort builds on top of the wonderful blog post that MaxMind made about creating your own (or supplementing theirs) MMDB files for GeoIP2.

https://blog.maxmind.com/2015/09/29/building-your-own-mmdb-database-for-fun-and-profit/

There are many ways you might care to represent your IP address
management data; it could be as simple (and useful) as a complex Excel spreadsheet, or a specialised IPAM tool.

As such, you will need to provide the code that gets that data and produces a JSON document that represents the data that you want to have in the MMDB. You might prefer to do that using tools such as Python with the Pandas library, or by querying some API. You might even need to query multiple sources of data, and some of that might even be static.

The creation of the MMDB format is necessarily tied to Perl; so this tool will take in your JSON and produce the MMDB. You could easily imagine this as a service or command-line tool. I'm doing this as a Docker image so all the dependencies and tooling are nicely encapsulated.

# Using the image

## First, Create a JSON Document

This would likely involve you doing some scripting to extract and manipulate data from wherever you have your IP addressing source(s) of truth/intent/belief. You're free to use whatever tooling you want for this, but here's some pointers for Python libraries based on where your data is located and an indication of how satisfying you might find the process. 

The creation of the JSON is straight-forward; any pain tends to be in getting to the data, particularly if you have to deal with some SOAP API and you're not familiar with SOAP and the various oddities that SOAP implementations throw at you.

- Excel spreadsheet: 'pandas' 😎 or 'openpyxl' 😎
- CSV: pandas 😎
- JSON: json 😎
- Any of the above, but the document is in a document management system such as
  Atlassian Confluence: 'webdav' may be applicable, or you might get it via API.
- IPAM application accessed via SOAP: 'zeep', but such apps can still be 😬
- IPAM application accessed via REST: 'requests' 😀
- Database: depends on which database; might also be useful fallback if your
  IPAM doesn't have an API, or if its API is too painful or limiting to use.
- Some of the data may come from your live network; you could use Ansible,
  'netmiko' or even 'snmp' or 'expect'

Note that you may want to include multiple data sources in your process; which
might include static allocations, depending on your needs. I would suggest you
separate the cross-cutting concerns in different stages; it will make it easier
to iterate through development and testing. If you're wanting to collate the
data into some temporary database, I can recommend 'sqlite' as being easy and
fun to use.

Be prepared to have to do some data cleanup and linking of multiple data-sets; it all depends on your source data. For example, you might need to use some heuristic to determine which city/campus a subnet is in, or to do so you might have to harvest data from your live network.

Whatever mechanism you use, you'll want a JSON document that looks like this:

```
{
    "schema": {
        "database_type": "demo-network",
        "description": { "en": "Demo network allocations" },
        "ip_version": 4,
        "types": {
            "vlan_id": "uint32",
            "name": "utf8_string",
            "campus": "utf8_string"
        }
    },
    "allocations": [
        {
            "subnet": "10.10.0.0/16",   <--- REQUIRED FIELD
            "name": "Datacenter range",
            "campus": "Head Office"
        },
        {
            "subnet": "10.10.0.0/20",
            "vlan_id": 1,
            "name": "Management interfaces",
            "campus": "Head Office"
        },
        ...
```

Remember that **the fields you provide in the `allocations` are completely up to you** but you must specify `subnet`. Note that order of the allocations should not matter. 

You can have a look at input/demo.json for a fuller example, but for the purposes of illustration, there are two sections to the JSON document:

With regard to the `types` within the `schema` element, please see [mapping of types](https://metacpan.org/pod/MaxMind::DB::Writer::Tree#DATA-TYPES) that will be used.

## Creating the MMDB

So now you have a JSON document that describes what will going into the MMDB file, let's compile it:

    docker run -v ${PWD}:/work/ --rm json-to-mmdb:latest \
        --input=/work/my-network.json \
        --output=/work/my-network.mmdb

Worth noting that this command will also run happily with Docker Desktop for Windows from a Powershell command-line.

## Smoke-test the generated database

Inside the container you will find the MMDB utilities available.

(Note that the PS> is a Powershell prompt, but the command is exactly the same as for Bash etc.)

```
PS> docker run -v ${PWD}/uo-network-allocations-json/:/work/ --rm -it --entrypoint=/bin/bash json-to-mmdb:latest
[user@526b47ded9f1 app]$ mmdblookup --file /work/uoo-addressing.mmdb --ip 10.112.0.1

  {
    "block":
      "STUDENT-1" <utf8_string>
    "block_class":
      "STUDENT-n" <utf8_string>
    "block_type":
      "Students" <utf8_string>
    "campus":
      "DUN" <utf8_string>
    "subnet":
      "10.112.0.0/21" <utf8_string>
  }
[root@c56bbd282057 json-to-mmdb]# /usr/local/bin/mmdb-dump-metadata --file=output/demo.mmdb 
  Demo network allocations
  type:                  demo-network
  languages:             

  binary format version: 2.0
  build epoch:           1,600,394,804 (2020-09-18 02:06::44 UTC)
  IP version:            4
  node count:            55
  record size:           24 bits
```

Doing a lookup

```
[root@c56bbd282057 json-to-mmdb]# mmdblookup --file output/demo.mmdb --ip 10.10.0.32

  {
    "campus": 
      "Head Office" <utf8_string>
    "name": 
      "Management interfaces" <utf8_string>
    "subnet": 
      "10.10.0.0/20" <utf8_string>
    "vlan_id": 
      1 <uint32>
  }
```

## Using with Logstash

You will need the logstash-filter-mmdb, which is not yet a
standard Logstash plugin. You might wonder why we don't
just use logstash-filter-geoip, and the only reason is
really because logstash-filter-geoip requires the MMDB
to be either the GeoCity2 City or ASN database schema.

    filter {
      mmdb {
        database => "/output/my-network.mmdb"
        source => "someip"
        target => "someip_info"
      }
    }

logstash-filter-mmdb uses the https://github.com/maxmind/MaxMind-DB-Reader-java library.

# (Not-a-Feature yet) Extending GeoCity2-City etc.

MaxMind, as a response to Californian privacy laws, require
users of GeoCity2-City etc. to download the databases using
an account; as a result anonymous downloads are not permitted.

You will need to provide the CSV format of the databases, and
keep these up to date; perhaps we should just have the user
give this container some credentials so we ensure we create something fresh...

**In the meantime, I'm not currently inclined to support
extending the GeoCity2 databases**; users of Logstash (which
is my primary deployment use-case) can first try a regular
geoip lookup, and then perhaps try using a mmdb lookup.

# For Developers (of this tool)

## Dependencies and Skills

  - Perl 5:
    - required for generating the MMDB version 2 files, as it is the only platform that has the supported writing library.

  - Docker:
    - for the build environment

## Build the image

This will create an local image called json-to-mmdb:latest

    docker build -t json-to-mmdb:latest .

Normally this should get built using a Docker Hub automated build, but
doing yourself is perfectly fine too.

Most people should be able to just use cameronkerrnz/json-to-mmdb:latest,
which should always be passing tests before getting tagged on Docker Hub.

