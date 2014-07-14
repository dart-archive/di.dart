main() {
  var args;
  for (var i = 0; i <= 25; i++) {
    print("case $i:");
    args = new List.generate(i, (j) => "a${j+1}").join(', ');
    print("return ($args) {");
    var buffer = new StringBuffer();
    for (var j = 0; j < i; j++){
      buffer.write("l[$j]=a${j+1};");
    }
    print(buffer);
    print("return create(name, l).reflectee;");
    print("};");
  }
}
