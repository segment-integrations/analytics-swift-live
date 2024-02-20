#!/bin/bash

curl "https://raw.githubusercontent.com/segmentio/SignalsJS-Runtime/main/Runtime/Signals.js?token=GHSAT0AAAAAACMWAG5HQ4ISLKFZQU5AEVUAZOP24AQ" > Signals.js

./embedJS.sh SignalsRuntime Signals.js Sources/AnalyticsLive/SignalsRuntime.swift

rm Signals.js
