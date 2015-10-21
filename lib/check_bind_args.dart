library di.check_bind_args;

import 'package:smoke/smoke.dart' as smoke;

import "src/module.dart";
export "src/module.dart" show DEFAULT_VALUE, IDENTITY, isSet, isNotSet;

checkBindArgs(dynamic toValue, Function toFactory,
              Type toImplementation, List inject, toInstanceOf) {
  int count = 0;
  if (isSet(toValue)) count++;
  if (isSet(toFactory)) {
    count++;
    if (!smoke.canAcceptNArgs(toFactory, inject.length)) {
      throw "toFactory's argument count does not match amount provided by inject";
    }
  }

  if (toImplementation != null) count++;
  if (toInstanceOf != null) count++;
  if (count > 1) {
    throw 'Only one of following parameters can be specified: '
    'toValue, toFactory, toImplementation, toInstanceOf';
  }

  if (inject.isNotEmpty && isNotSet(toFactory)) {
    throw "Received inject list but toFactory is not set.";
  }

  return true;
}

// Generation script in scripts/check_bind_args_script.dart
