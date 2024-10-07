#!/bin/bash

ANALYTICSLIVECORE_VERSION="2.0.6"


rm -rf AnalyticsLiveCore-swift
git clone -c advice.detachedHead=false --depth=1 --branch ${ANALYTICSLIVECORE_VERSION} git@github.com:segment-integrations/AnalyticsLiveCore-swift.git

echo "Unzipping the AnalyticsLiveCore frameworks to ./xcframeworks ..."

mkdir -p ./xcframeworks
for file in ./AnalyticsLiveCore-swift/output/*.zip; do unzip -o "$file" -d ./xcframeworks; done

rm -rf AnalyticsLiveCore-swift

echo "Done extracting frameworks."
