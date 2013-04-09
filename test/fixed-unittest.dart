library unittest;

import 'package:unittest/unittest.dart';
import '../lib/mirrors.dart';

export 'package:unittest/unittest.dart';

// fix the testing framework ;-)
void it(String spec, TestFunction body) => test(spec, body);
void xit(String spec, TestFunction body) {}
void iit(String spec, TestFunction body) => solo_test(spec, body);

Matcher toEqual(expected) => equals(expected);
Matcher toBe(expected) => same(expected);
Matcher instanceOf(Type t) => new IsInstanceOfTypeMatcher(t);


// Welcome to Dart ;-)
class IsInstanceOfTypeMatcher extends BaseMatcher {
  Type t;
  
  IsInstanceOfTypeMatcher(Type t) {
    this.t = t;
  }
  
  bool matches(obj, MatchState matchState) {
    // we should at least compare qualifiedName, but there's no way to get it from Type
    return reflect(obj).type.simpleName == t.toString();
  }
  
  Description describe(Description description) =>
      description.add('an instance of ${t.toString()}');
}
