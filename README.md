# A prototype of Dependency Injection framework for Dart

Influenced by Pico Container, AngularJS DI, Node DI, Guice, Dagger and what not.


Couple of facts:

- only constructor injection (no setter, no interface or any other bullshit)
- everything is a singleton within given injector
  - create child injector (for shorter scopes)
  - inject a factory
- injector is immutable

For example usage see [the tests](https://github.com/vojtajina/dart-di/blob/master/test/main.dart).