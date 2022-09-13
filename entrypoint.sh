#!/bin/bash
set -eu

NUMPROCS=12

usage () {
    cat <<EOF
Usage: docker run -v <localpath>:/data easymapit <tracetype> <tracelist>
               <date> <days> [<user> <pass>]

<localpath>    A path in the local file system where input traces are
               located.  This will be mounted as a shared volume on /data
               inside the container.  Provide an absolute path to avoid Docker
               another base path on the local filesystem.  Data needed to run
               bdrmapit will be downloaded inside /data/bdrmapit if it is not
               downloaded yet.

<tracetype>    Either "A" or "W" to indicate the type of file included in
               <tracelist>.  "A" stands for RIPE Atlas format, with one result
               per line, in JSON format; "W" stands for scamper's warts.

<tracelist>    Absolute path to a text file inside the container's shared
               volume, so its path should start with /data.  The file should
               contain the absolute path per line, each pointing to a
               traceroute file.  Traceroute files should be located in the
               shared traceroute volume, so their paths must also start with
               /data.

<date>         A date in ISO format, e.g., 2021-10-20, usually the date
               corresponding to when the measurements in <tracelist> were
               collected.

<days>         Number of additional days starting from <date> to be
               downloaded from Ark and Atlas to use as training data
               for bdrmapit; pass 0 to use only one day of traces.

<user/pass>    Login to download recent traceroutes from CAIDA's topology
               measurements.  If no login is provided, public data will be
               used.  However, public traceroutes only include traces
               more than one year old.

Example:
$ docker run -v \$(pwd)/data:/data easymapit W /data/traces.txt 2021-10-20 0

Notes:

* To avoid duplicate downloads, we perform simple checks for the following
directories within the shared volume.  If they exist, the corresponding
data-fetching job will not be run.  As a result, you may need to delete
these directories if errors occur to trigger a new download.

    /data/bdrmapit/{asorg, bgp, itdk, peeringdb, prefix2as, prefix, rels,
                    ripe-recent, rir, team}

EOF
exit 1
}

if [[ $# -ne 4 && $# -ne 6 ]] ; then usage ; fi

tracetype=$1
if [[ $tracetype != A && $tracetype != W ]] ; then usage ; fi
tracelist=$2
date=$3

user=invalid
pass=invalid
caidapfx=public-
traceopts=()
if [[ $4 -gt 0 ]] ; then
    enddate=$(date --date "$date +$4 day" +%Y-%m-%d)
    traceopts=(-e "$enddate")
fi
if [[ $# -eq 6 ]] ; then
    user=$5
    pass=$6
    caidapfx=caida-
    traceopts+=(-u "$user" -p "$pass")
fi

for data in asorg bgp peeringdb prefix2as rels rir ; do
    if [[ -d /data/bdrmapit/$data ]] ; then
        echo "/data/bdrmapit/$data present, skipping"
        continue
    fi
    echo "retrieving /data/bdrmapit/$data"
    retrieve_external -b "$date" -d /data/bdrmapit/$data $data
done

shortdate=${date//-/}
underdate=${date//-/_}
monthdate=${shortdate:0:6}
asorgdate=$(grep -Ee "^$shortdate" /data/bdrmapit/asorg/datemap.txt \
        | cut -d " " -f 2)

if [[ ! -s "/data/bdrmapit/rir/$shortdate.rir.prefixes" ]] ; then
    echo "Generating RIR prefix-to-AS file"
    find /data/bdrmapit/rir -type f > /data/bdrmapit/rir/rir.files
    rir2as -f /data/bdrmapit/rir/rir.files \
            -r "/data/bdrmapit/rels/$shortdate.as-rel.txt.bz2" \
            -c "/data/bdrmapit/rels/$shortdate.cc.txt.bz2" \
            -o "/data/bdrmapit/rir/$shortdate.rir.prefixes"
fi

if [[ ! -s "/data/bdrmapit/ip2as/$shortdate.prefixes" ]] ; then
    echo "Generating global ip2as file"
    mkdir -p /data/bdrmapit/ip2as
    ip2as -p /data/bdrmapit/prefix2as/routeviews-rv2-"$shortdate"-????.pfx2as.gz \
            -P "/data/bdrmapit/peeringdb/peeringdb_2_dump_$underdate.json" \
            -r "/data/bdrmapit/rir/$shortdate.rir.prefixes" \
            -R "/data/bdrmapit/rels/${monthdate}01.as-rel.txt.bz2" \
            -c "/data/bdrmapit/rels/${monthdate}01.ppdc-ases.txt.bz2" \
            -a "/data/bdrmapit/asorg/$asorgdate.as-org2info.jsonl.gz" \
            -o "/data/bdrmapit/ip2as/$shortdate.prefixes"
fi

for data in itdk prefix ripe-recent team ; do
    if [[ -d /data/bdrmapit/$data ]] ; then
        echo "/data/bdrmapit/$data present, skipping"
        continue
    fi
    target=$caidapfx$data
    if [[ $data == ripe-recent ]] ; then target=ripe-recent ; fi
    echo "retrieving /data/bdrmapit/$data"
    retrieve_external -b "$date" -d /data/bdrmapit/$data \
            "${traceopts[@]}" $target
done

itdkdate=$(grep -Ee "^$shortdate" /data/bdrmapit/itdk/datemap.txt \
        | cut -d " " -f 2)
itdkdate=${itdkdate:0:6}

truncate --size 0 /data/bdrmapit/ripe-index.txt
truncate --size 0 /data/bdrmapit/warts-index.txt

if [[ -d /data/bdrmapit/ripe-recent ]] ; then
    find /data/bdrmapit/ripe-recent -name "traceroute-$date*bz2" -type f \
            >> /data/bdrmapit/ripe-index.txt
fi

if [[ -d /data/bdrmapit/prefix ]] ; then
    find /data/bdrmapit/prefix -name "*.$shortdate.warts.gz" -type f \
            >> /data/bdrmapit/warts-index.txt
fi
if [[ -d /data/bdrmapit/team ]] ; then
    find /data/bdrmapit/team -name "*.$shortdate.warts.gz" -type f \
            >> /data/bdrmapit/warts-index.txt
fi

case $tracetype in
A)
    cat "$tracelist" >> /data/bdrmapit/ripe-index.txt
    ;;
W)
    cat "$tracelist" >> /data/bdrmapit/warts-index.txt
    ;;
esac

mkdir -p /data/bdrmapit/output
echo "launching bdrmapit"
bdrmapit all \
        -w /data/bdrmapit/warts-index.txt \
        -a /data/bdrmapit/ripe-index.txt \
        -i "/data/bdrmapit/ip2as/$shortdate.prefixes" \
        -b "/data/bdrmapit/asorg/$asorgdate.as-org2info.jsonl.gz" \
        -r "/data/bdrmapit/rels/${monthdate}01.as-rel.txt.bz2" \
        -c "/data/bdrmapit/rels/${monthdate}01.ppdc-ases.txt.bz2" \
        -P "/data/bdrmapit/peeringdb/peeringdb_2_dump_$underdate.json" \
        -R "/data/bdrmapit/itdk/$itdkdate-midar-iff.nodes.as.bz2" \
        -s "/data/bdrmapit/output/annotations.sqlite3" \
        -p $NUMPROCS
