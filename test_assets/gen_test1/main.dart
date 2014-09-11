import 'dart:async';

import 'annotations.dart';
import 'common1.dart';

import 'a.dart' deferred as a;
import 'b.dart' deferred as b;
import 'c.dart' deferred as c;

void main() {
  a.loadLibrary().then(onALoaded);
  b.loadLibrary().then(onBLoaded);
  c.loadLibrary().then(onCLoaded);
}

void onALoaded(_) {
  var serviceA = new a.ServiceA();
  serviceA.sayHi();
}

void onBLoaded(_) {
  var serviceB = new b.ServiceB();
  serviceB.sayHi();
}

void onCLoaded(_) {
  c.cStuff();
}

@InjectableTest()
class ServiceMain {
  sayHi() {
    print('Hi ServiceMain!');
  }
}
