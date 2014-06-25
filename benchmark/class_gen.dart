import 'dart:io';
import 'dart:async';

main() {
  int numClasses = 1000;

  File file = new File('benchmark/generated_classes.dart');
  var sink = file.openWrite(mode: WRITE);
  sink.write('import "package:di/key.dart";\n');
  sink.write('import "package:di/di.dart";\n');
  sink.write('int c=0;\n');
  for (var i = 0; i < numClasses; i++){
    sink.write('class Test$i{Test$i(){c++;}}\n');
    sink.write('final Key key$i = new Key(Test$i);\n');
  }
  sink.write('List<Key> allKeys = <Key>[\n');
  for (var i = 0; i < numClasses; i++){
    sink.write('key$i,\n');
  }
  sink.write('];\n');
  sink.write('Map<Key, Function> typeFactories = {\n');
  for (var i = 0; i < numClasses; i++){
    sink.write('Test$i: (f) => new Test$i(),\n');
  }
  sink.write('};\n');
  sink.close();
}
