library di.check_bind_args;

import "src/module.dart";

checkBindArgs(dynamic toValue, Function toFactory, Factory toFactoryPos,
              Type toImplementation, List inject) {
  int count = 0;
  bool argCountMatch = false;
  if (isSet(toValue)) count++;
  if (isSet(toFactory)) {
    count++;
    var len = inject.length;
    if (len == 0) argCountMatch = toFactory is _0;
    if (len == 1) argCountMatch = toFactory is _1;
    if (len == 2) argCountMatch = toFactory is _2;
    if (len == 3) argCountMatch = toFactory is _3;
    if (len == 4) argCountMatch = toFactory is _4;
    if (len == 5) argCountMatch = toFactory is _5;
    if (len == 6) argCountMatch = toFactory is _6;
    if (len == 7) argCountMatch = toFactory is _7;
    if (len == 8) argCountMatch = toFactory is _8;
    if (len == 9) argCountMatch = toFactory is _9;
    if (len == 10) argCountMatch = toFactory is _10;
    if (len == 11) argCountMatch = toFactory is _11;
    if (len == 12) argCountMatch = toFactory is _12;
    if (len == 13) argCountMatch = toFactory is _13;
    if (len == 14) argCountMatch = toFactory is _14;
    if (len == 15) argCountMatch = toFactory is _15;
    if (len == 16) argCountMatch = toFactory is _16;
    if (len == 17) argCountMatch = toFactory is _17;
    if (len == 18) argCountMatch = toFactory is _18;
    if (len == 19) argCountMatch = toFactory is _19;
    if (len == 20) argCountMatch = toFactory is _20;
    if (len == 21) argCountMatch = toFactory is _21;
    if (len == 22) argCountMatch = toFactory is _22;
    if (len == 23) argCountMatch = toFactory is _23;
    if (len == 24) argCountMatch = toFactory is _24;
    if (len == 25) argCountMatch = toFactory is _25;
    if (len == 26) argCountMatch = toFactory is _26;
    if (len == 27) argCountMatch = toFactory is _27;
    if (len == 28) argCountMatch = toFactory is _28;
    if (len == 29) argCountMatch = toFactory is _29;
    if (len == 30) argCountMatch = toFactory is _30;
    if (len == 31) argCountMatch = toFactory is _31;
    if (len == 32) argCountMatch = toFactory is _32;
    if (len == 33) argCountMatch = toFactory is _33;
    if (len == 34) argCountMatch = toFactory is _34;
    if (len == 35) argCountMatch = toFactory is _35;
    if (len == 36) argCountMatch = toFactory is _36;
    if (len == 37) argCountMatch = toFactory is _37;
    if (len == 38) argCountMatch = toFactory is _38;
    if (len == 39) argCountMatch = toFactory is _39;
    if (len == 40) argCountMatch = toFactory is _40;
    if (len == 41) argCountMatch = toFactory is _41;
    if (len == 42) argCountMatch = toFactory is _42;
    if (len > 42) throw "toFactory `$toFactory` argument count exceeded limit";
    if (!argCountMatch) throw "toFactory's argument count does not match amount provided by inject";
  }
  if (isSet(toFactoryPos)) {
    count++;
    if (toFactoryPos is! _1) throw "toFactoryPos must take exactly one argument.";
  }
  if (toImplementation != null) count++;
  if (count > 1) {
    throw 'Only one of following parameters can be specified: '
    'toValue, toFactory, toFactoryPos, toImplementation';
  }

  if (inject.length > 0 && isNotSet(toFactory) &&
      !(inject.length == 1 && identical(toFactoryPos, IDENTITY))) {
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
typedef _16(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16);
typedef _17(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17);
typedef _18(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18);
typedef _19(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19);
typedef _20(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20);
typedef _21(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21);
typedef _22(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22);
typedef _23(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23);
typedef _24(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24);
typedef _25(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25);
typedef _26(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26);
typedef _27(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27);
typedef _28(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28);
typedef _29(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29);
typedef _30(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30);
typedef _31(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31);
typedef _32(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31, a32);
typedef _33(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31, a32, a33);
typedef _34(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31, a32, a33, a34);
typedef _35(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31, a32, a33, a34, a35);
typedef _36(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31, a32, a33, a34, a35, a36);
typedef _37(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31, a32, a33, a34, a35, a36, a37);
typedef _38(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31, a32, a33, a34, a35, a36, a37, a38);
typedef _39(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31, a32, a33, a34, a35, a36, a37, a38, a39);
typedef _40(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31, a32, a33, a34, a35, a36, a37, a38, a39, a40);
typedef _41(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31, a32, a33, a34, a35, a36, a37, a38, a39, a40, a41);
typedef _42(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31, a32, a33, a34, a35, a36, a37, a38, a39, a40, a41, a42);

// Generation script

//main() {
//  var s = new StringBuffer();
//
//  int max_arg_count = 42;
//
//  for (var i = 0; i <= max_arg_count; i++) {
//    s.write("typedef _$i(");
//    s.write(new List.generate(i, (c) => "a${c+1}").join(", "));
//    s.write(");\n");
//  }
//
//  for (var i = 0; i <= max_arg_count; i++) {
//    s.write("if (len == $i) argCountMatch = toFactory is _$i;\n");
//  }
//
//  print(s);
//}
