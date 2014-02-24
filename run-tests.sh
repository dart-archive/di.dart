
#!/bin/sh
set -e

echo "run type factories generator for tests"
./test_tf_gen.sh

echo "run tests in dart"
dart --checked test/main.dart
dart --checked test/generator_test.dart
dart --checked test/injector_generator_spec.dart

echo "run dart2js on tests"
mkdir -p out
dart2js --minify -c test/main.dart -o out/main.dart.js

echo "run tests in node"
node out/main.dart.js

echo "run transformer tests"
pushd test/transformer
pub install
pub build --mode=debug

echo "running transformer test (uncompiled, Dynamic DI)"
dart --checked web/main.dart

echo "running transformer test (Static DI, Dart VM)"
dart --checked build/web/main.dart

echo "running transformer test (Static DI, dart2js)"
node build/web/main.dart.js

popd
