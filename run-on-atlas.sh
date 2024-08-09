#!/bin/bash
set -eu
set -x

source secrets.txt
START=2021-12-08
DURATION=0

# Atlas file locations on achtung17
# DIR=/home/kevin/rankingservice/algorithms/evaluation/resources/bdrmapit
# mkdir -p data/traces
# cp $DIR/traceroute_atlas_bgp_survey_full*json data/traces/
DATADIR=data/revtr-atlas/traces/

function run_bdrmapit {
    local duration=$(( $1 ))
    local runname=$2
    docker run -v "$(pwd)/data:/data" --user "$(id -u):$(id -g)" \
            easymapit A /data/traces.txt $START \
            $duration "$CAIDA_USER" "$CAIDA_PASS" \
            | tee "data/revtr-atlas/$runname.log"
    mv data/bdrmapit/output "data/revtr-atlas/output-$runname"
}

for duration in $DURATION ; do
    duration=$(( duration ))
    # Run for each file at a time
    # for file in "$DATADIR"/traceroute_atlas_bgp_survey_full*.json ; do
    #     echo "/$file" > data/traces.txt
    #     tstamp=${file%%.json}
    #     tstamp=${tstamp##*_}
    #     run_bdrmapit $duration "$tstamp-${duration}days"
    # done

    # Run for all files at the same time
    # find "$DATADIR" -name 'traceroute_atlas_bgp_survey*json.gz' \
    #         -exec echo /{} \; > data/traces.txt
    # run_bdrmapit $duration full-${duration}days

    # Run without RIPE traceroutes
    # truncate --size 0 data/traces.txt
    # run_bdrmapit $duration caida-${duration}days

    # Backing up datasets
    if [[ ! -d data/revtr-atlas/bdrmapit-${duration}days ]] ; then
        cp -a data/bdrmapit data/revtr-atlas/bdrmapit-${duration}days
    fi

    # Run without Ark traceroutes
    find "$DATADIR" -name 'traceroute_atlas_bgp_survey*json.gz' \
            -exec echo /{} \; > data/traces.txt
    rm -rf data/bdrmapit/{prefix,team}
    mkdir -p data/bdrmapit/{prefix,team}
    run_bdrmapit $duration ripe-${duration}days

    # Removing duration-dependent datasets
    rm -rf data/bdrmapit/{itdk,prefix,ripe-recent,team}
done
