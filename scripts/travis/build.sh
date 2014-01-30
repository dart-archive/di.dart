#!/bin/bash
set -e
. ./scripts/env.sh

echo "build.sh - DART_SDK: $DART_SDK"
./run-tests.sh