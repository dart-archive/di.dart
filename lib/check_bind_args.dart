library di.check_bind_args;

import "src/module.dart";
export "src/module.dart" show DEFAULT_VALUE, IDENTITY, isSet, isNotSet;

checkBindArgs(dynamic toValue, Function toFactory,
              Type toImplementation, List inject, toInstanceOf) {
  int count = 0;
  bool argCountMatch = true;
  if (isSet(toValue)) count++;
  if (isSet(toFactory)) {
    count++;
    var len = inject.length;
    switch (len) {
      case 0: argCountMatch = toFactory is _0; break;
      case 1: argCountMatch = toFactory is _1; break;
      case 2: argCountMatch = toFactory is _2; break;
      case 3: argCountMatch = toFactory is _3; break;
      case 4: argCountMatch = toFactory is _4; break;
      case 5: argCountMatch = toFactory is _5; break;
      case 6: argCountMatch = toFactory is _6; break;
      case 7: argCountMatch = toFactory is _7; break;
      case 8: argCountMatch = toFactory is _8; break;
      case 9: argCountMatch = toFactory is _9; break;
      case 10: argCountMatch = toFactory is _10; break;
      case 11: argCountMatch = toFactory is _11; break;
      case 12: argCountMatch = toFactory is _12; break;
      case 13: argCountMatch = toFactory is _13; break;
      case 14: argCountMatch = toFactory is _14; break;
      case 15: argCountMatch = toFactory is _15; break;
    }
    if (!argCountMatch) throw "toFactory's argument count does not match amount provided by inject";
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

typedef _0();
typedef _1(a1);
typedef _2(a1, a2);
typedef _3(a1, a2, a3);
typedef _4(a1, a2, a3, a4);
typedef _5(a1, a2, a3, a4, a5);
typedef _6(a1, a2, a3, a4, a5, a6);
typedef _7(a1, a2, a3, a4, a5, a6, a7);
typedef _8(a1, a2, a3, a4, a5, a6, a7, a8);
typedef _9(a1, a2, a3, a4, a5, a6, a7, a8, a9);
typedef _10(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10);
typedef _11(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11);
typedef _12(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12);
typedef _13(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13);
typedef _14(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14);
typedef _15(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15);

// Generation script in scripts/check_bind_args_script.dart
