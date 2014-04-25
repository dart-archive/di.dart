library di.error_helper;

import 'package:di/key.dart';

/**
 * Returns an error message for the given dependency chain.
 * See [resolvedTypes] for assumptions on [resolving].
 * If [addDependency] is not null, its [String] representation gets appended
 * to the end of the error message.
 *
 * Example:
 * If [resolving] is (2, k1), (10, k2), (0, k3), and [message] is 'foo',
 * then this looks like
 * 'foo (resolving k3 -> k2 -> k1)'
 */
String error(List resolving, String message, [Key appendDependency]) {
  if (appendDependency != null) {
    resolving = [resolving[0] + 1, appendDependency, resolving];
  }
  String graph = resolvedTypes(resolving).reversed.join(' -> ');
  return '$message (resolving $graph)';
}

/**
 * Returns the [Key]s from the given singly-linked list.
 * Assumes [resolving] is a [List] of size 3 - [i, key, next] -
 * where i is an int, key is a Key, and next is null or another such [List].
 * Also assumes that the tail of the list has i == 0.
 * So effectively, [resolving] is a non-empty, singly-linked list of pairs
 * (i, key) where the list is considered terminated when i == 0.
 */
List<Key> resolvedTypes(List resolving) {
  List<Key> resolved = [];
  while (resolving[0] != 0) {
    resolved.add(resolving[1]);
    resolving = resolving[2];
  }
  return resolved;
}
