main() {
  var s = new StringBuffer();

  int max_arg_count = 15;

  for (var i = 0; i <= max_arg_count; i++) {
    s.write("typedef _$i(");
    s.write(new List.generate(i, (c) => "a${c+1}").join(", "));
    s.write(");\n");
  }

  s.write("switch (len) {\n");
  for (var i = 0; i <= max_arg_count; i++) {
    s.write("case $i: argCountMatch = toFactory is _$i; break;\n");
  }
  s.write('}');

  print(s);
}
