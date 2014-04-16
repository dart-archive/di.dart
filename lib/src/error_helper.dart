library di.error_helper;

import 'package:di/key.dart';

String error(List resolving, message, [appendDependency]) {
  if (appendDependency != null) {
    resolving = [resolving[0] + 1, appendDependency, resolving];
  }

  String graph = resolvedTypes(resolving).reversed.join(' -> ');

  return '$message (resolving $graph)';
}

List<Key> resolvedTypes(resolving) {
  List resolved = [];
  while (resolving[0] != 0) {
    resolved.add(resolving[1]);
    resolving = resolving[2];
  }
  return resolved;
}
