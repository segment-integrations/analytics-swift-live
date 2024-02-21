#!/bin/bash

curl "https://raw.githubusercontent.com/segmentio/SignalsJS-Runtime/main/Runtime/Signals.js?token=GHSAT0AAAAAACMWAG5HU62ZI7BMT5ZHJZ3QZOWKENA" > Signals.js

./embedJS.sh SignalsRuntime Signals.js Sources/AnalyticsLive/SignalsRuntime.swift

rm Signals.js
