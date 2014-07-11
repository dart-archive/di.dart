library di.transformer.export_transformer;

import 'dart:async';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:barback/barback.dart';
import 'package:code_transformers/resolver.dart';
import 'package:path/path.dart' as path;

/**
 * Pub transformer that changes reflector in Module to null instead of importing
 * the dynamic reflector which imports mirrors. InjectorGenerator in transformer.dart
 * will change DEFAULT_REFLECTOR back to static (it is run by the app, whereas this is run by DI).
 */
class ModuleTransformerGroup implements TransformerGroup {
  final Iterable<Iterable> phases;

  ModuleTransformerGroup.asPlugin(BarbackSettings settings)
  : phases = [[new ModuleTransformer()]];
}

class ModuleTransformer extends Transformer {

  ModuleTransformer();

  isPrimary(AssetId id) {
    return new Future.value(id == new AssetId.parse("di|lib/src/module.dart"));
  }

  Future apply(Transform transform) {
    var id = transform.primaryInput.id;
    return transform.primaryInput.readAsString().then((code) {
      // Note: this rewrite is coupled with how module.dart is
      // written. Make sure both are updated in sync.
      transform.addOutput(new Asset.fromString(id, code
          .replaceAll(new RegExp('import "reflector_dynamic.dart";'),
              'import "reflector_null.dart";')));
    });
  }
}
