// just to get rid of the warning
library mirrors;

export 'dart:mirrors';

import 'dart:mirrors';


// terrible hack because we can't get a qualified name from a Type
// dartbug.com/8041
// dartbug.com/9395
ClassMirror getClassMirrorByTypeName (String typeName) {
  for (var lib in currentMirrorSystem().libraries.values) {
    if (lib.classes.containsKey(typeName)) {
      return lib.classes[typeName];
    }
  }
}