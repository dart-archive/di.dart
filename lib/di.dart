import 'mirrors.dart';
import 'dart:async';

class Injector {
  // should be <Type,Type>
  Map<String, String> providers = new Map<String, String>();
  // should be <Type, dynamic>
  Map<String, dynamic> instances = new Map<String, dynamic>();
  
  Injector([Map types]) {
    if (types != null) {
      // create <String,String> map, because Dart is stupid and makes us deal with strings rather than types
      types.forEach((key, value) {
        providers[key.toString()] = value.toString();
      });  
    }
  }
  
  ClassMirror _getClassMirrorByTypeName (String typeName) {
    // overriden provider
    if (providers.containsKey(typeName)) {
      typeName = providers[typeName];
    }

    for (var lib in currentMirrorSystem().libraries.values) {
      if (lib.classes.containsKey(typeName)) {
        return lib.classes[typeName];
      }
    }
  }
  
  ClassMirror _getClassMirrorFromType(Type type) {
    // terrible hack because we can't get a qualified name from a Type
    // dartbug.com/8041
    // dartbug.com/9395
    return _getClassMirrorByTypeName(type.toString());
  }
  
  
  dynamic _getInstanceByTypeName(String typeName) {
    if (instances.containsKey(typeName)) {
      return instances[typeName];
    }
    
    ClassMirror cm = _getClassMirrorByTypeName(typeName);
    MethodMirror ctor = cm.constructors.values.first;
    
    resolveArgument(p) {
      return _getInstanceByTypeName(p.type.simpleName);
    }
    
    var positionalArgs = ctor.parameters.map(resolveArgument).toList();
    var namedArgs = null;
    var instance = deprecatedFutureValue(cm.newInstance(ctor.constructorName, positionalArgs, namedArgs));
    
    instances[typeName] = instance;

    return instance;
  }

 
  // PUBLIC API
  dynamic get(Type type) {
    return _getInstanceByTypeName(type.toString()).reflectee;
  }
}
