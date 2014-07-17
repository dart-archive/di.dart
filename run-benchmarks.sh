#!/bin/sh 
set -e

BENCHMARKS="module_benchmark.dart
dynamic_injector_benchmark.dart
static_injector_benchmark.dart
instance_benchmark.dart
large_benchmark.dart"

mkdir -p benchmark/generated_files
dart scripts/class_gen.dart

# run tests in dart
for b in $BENCHMARKS
do
    dart benchmark/$b
done

# run dart2js on tests
mkdir -p out
echo "running dart2js"
for b in $BENCHMARKS
do
    dart2js --minify benchmark/$b   -o out/$b.js > /dev/null
done

# run tests in node
for b in $BENCHMARKS
do
    node out/$b.js
done
