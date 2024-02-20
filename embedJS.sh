#!/bin/bash

# no args, so give usage.
if [ $# -ne 3 ]
then
	echo "Embed JS into Swift"
	echo ""
	echo "Usage: $ ./embedJS.sh <runtimeName> <sourceFile> <outputFile>"
	echo "   ex: $ ./embedJS.sh \"SignalRuntime\" ./signalsRuntime.js ./sources/signals/signalsRuntime.swift"
	exit 0
fi

if ! test -f $2; then
  echo "Error: $2 does not exist."
fi

touch $3 || { echo "There was an error accessing $3"; exit 1; }
rm $3 || { echo "There was an error accessing $3"; exit 1; }

echo "/**" >> $3
echo "THIS FILE IS GENERATED!! DO NOT MODIFY!" >> $3
echo "THIS FILE IS GENERATED!! DO NOT MODIFY!" >> $3
echo "THIS FILE IS GENERATED!! DO NOT MODIFY!" >> $3
echo "" >> $3
echo "Use embedJS.sh to re-generate if needed." >> $3
echo "*/" >> $3
echo "" >> $3
echo "class $1 {" >> $3
echo "    static let embeddedJS = \"\"\"" >> $3

while IFS= read -r line
do
  echo "    $line" >> $3
done < $2

echo "" >> $3
echo "    \"\"\"" >> $3
echo "}" >> $3
echo "" >> $3

