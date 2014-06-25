/**
 * This script generates a large number of classes and their corresponding factories
 * to benchmark/generated_files, to be imported by benchmarks that require many classes
 * and factories. Called from run-benchmarks.sh
 */
import 'dart:io';
import 'dart:async';

main() {
  int numClasses = 1000;

  File file = new File('benchmark/generated_files/classes.dart');
  var sink = file.openWrite(mode: WRITE);
  sink.write('int c=0;\n');
  for (var i = 0; i < numClasses; i++) {
    sink.write('class Test$i{Test$i(){c++;}}\n');
  }
  sink.close();

  file = new File('benchmark/generated_files/factories.dart');;
  sink = file.openWrite(mode: WRITE);
  sink.write('import "package:di/key.dart";\n');
  sink.write('import "package:di/di.dart";\n');
  sink.write('import "classes.dart";\n');
  sink.write('export "classes.dart";\n');
  for (var i = 0; i< numClasses; i++) {
    sink.write('final Key key$i = new Key(Test$i);\n');
  }
  sink.write('List<Key> allKeys = <Key>[\n');
  for (var i = 0; i < numClasses; i++) {
    sink.write('key$i, ');
  }
  sink.write('];\n');
  sink.write('Map<Type, Function> typeFactories = {\n');
  for (var i = 0; i < numClasses; i++) {
    sink.write('Test$i: () => new Test$i(),\n');
  }
  sink.write('};\n');
  sink.write('Map<Type, List<Key>> parameterKeys = {\n');
  for (var i = 0; i < numClasses; i++) {
    sink.write('Test$i: const[], ');
  }
  sink.write('\n};\n');
  sink.close();
}
