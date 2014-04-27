library di.error_helper;

import 'package:di/di.dart';
import 'package:di/src/base_injector.dart';

/**
 * Returns an error message for the given dependency chain.
 * If [addDependency] is given, its [String] representation gets appended
 * to the error message.
 *
 * Example:
 * If [resolving]'s ancestors have keys k1, k2, k3 and [message] is 'foo',
 * then this looks like 'foo (resolving k3 -> k2 -> k1)'.
 */
String error(ResolutionContext resolving, String message, [Key appendDependency]) {
  if (appendDependency != null) {
    resolving = new ResolutionContext(resolving.depth + 1, appendDependency, resolving);
  }
  String path = resolving.ancestorKeys().reversed.join(' -> ');
  return '$message (resolving $path)';
}
