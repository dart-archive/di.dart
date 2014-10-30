#!/bin/bash
set -e

# Prepend text to a file in-place.
function di::prepend_text {
  local file=$1
  local text=$2

  # NOTE: sed -i doesn't work on osx/bsd
  tmpfile=$(mktemp -t di_benchmark.XXXXXX)
  echo "$text" > $tmpfile
  cat "$file" >> $tmpfile
  cp -f "$tmpfile" "$file"
  rm -f "$tmpfile"
}

BENCHMARKS="module_benchmark.dart
dynamic_injector_benchmark.dart
static_injector_benchmark.dart
instance_benchmark.dart
large_benchmark.dart"

mkdir -p benchmark/generated_files
dart scripts/class_gen.dart

# run tests in dart
echo "Dart VM Benchmarks:"
echo "-------------------"
for b in $BENCHMARKS; do
  echo "Running: $b"
  dart benchmark/$b
done

# run dart2js on tests
echo
echo "Compiling with dart2js:"
echo "-----------------------"
mkdir -p out
for b in $BENCHMARKS; do
  echo "$b"
  dart2js --minify benchmark/$b -o out/$b.js > /dev/null
  # HACK node.js doesn't understand self
  di::prepend_text "out/$b.js" "var self=this"
done

# run tests in node
echo
echo "JS Benchmarks:"
echo "--------------"
for b in $BENCHMARKS; do
  echo "Running: $b"
  node out/$b.js
done
