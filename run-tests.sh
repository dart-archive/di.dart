#!/bin/sh
set -e

echo "Running generator..."
./test_tf_gen.sh

echo "Running tests in Dart..."
dart --checked test/main.dart
dart --checked test/transformer_test.dart

# Example app test
echo "Building example..."
rm -rf example/build/
cd example
pub_out=$(pub build | tee /dev/tty | grep -F "mirror" || : )
cd ..
echo "--------"

if [[ -n $pub_out ]]
then
    echo "FAIL: Example transformer should not import dart:mirror"
    failed=1
else
    echo "PASS: Example transformer should not import dart:mirror"
fi

output=$(node example/build/web/main.dart.js || : )
if [ $output == "Success" ]
then
    echo "PASS: Example transformer should inject dependencies"
else
    echo "FAIL: Example transformer should inject dependencies"
    failed=1
fi

if [[ -n $failed ]]
then
    echo "Tests failed. Build /example with \`pub build example/ --mode debug\` to debug."
    exit 1
fi
echo ""

echo "Compiling tests to JavaScript with dart2js..."
mkdir -p out
dart2js --minify -c test/main.dart -o out/main.dart.js

# attach a preamble file to dart2js output to emulate browser
# so node doesn't complain about lack of browser objects
cp test_assets/d8.js out/main.js
cat out/main.dart.js >> out/main.js

echo "Running compiled tests in node..."
node out/main.js

echo "Testing complete."
