#!/bin/bash

rate=1000
size=512
pods=100
duration=10
sink="kafka"
source="k8s-vector"

sed -e "s/SIZE/$size/g
s/RATE/$rate/g
s/DURATION/$duration/g
s/PODS/$pods/g" logging_vector_benchmark_template.yaml > current_test.yaml

target=$(oc get --no-headers route -n dittybopper | awk {'print $2'})

starttime=$(date +%s%N | cut -b1-13)
oc create -f current_test.yaml

sleep 10
word=$(oc get pods -n test --no-headers | grep -v Completed | wc -l)
while [ "$word" != 0  ]
do
	echo "Logging test still running..."
        sleep 10
	word=$(oc get pods -n test --no-headers | grep -v Completed | wc -l)
done
endtime=$(date +%s%N | cut -b1-13)

for i in {1..5}
do
	echo updating dittybooper
	curl -H "Content-Type: application/json" -X POST -d "{\"dashboardId\":$i,\"time\":$starttime,\"isRegion\":\"true\",\"timeEnd\":$endtime,\"tags\":[\"$rate\", \"$size\", \"$pods\",\"$duration\",\"$sink\", \"$source\"],\"text\":\"logging test: rate, size, pods, duration, sink, source\"}" http://admin:admin@$target/api/annotations
done

echo $(date)
