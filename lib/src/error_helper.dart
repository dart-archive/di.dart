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
  List resolvingKeys = resolving.ancestorKeys.reversed.toList(growable: false);
  // De-duplicate keys when there is a circular dependency
  // This is required because we don't check for circular dependencies before the
  // a depth threshold which would lead to msg like "A -> B -> A -> B -> ... -> A"
  for (var i = 1; i < resolvingKeys.length - 1; i++) {
    if (resolvingKeys[i] == resolvingKeys.first) {
      resolvingKeys = resolvingKeys.sublist(0, i + 1);
    }
  }

  return '$message (resolving ${resolvingKeys.join(" -> ")})';
}
