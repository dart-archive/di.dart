library di.transformer.export_transformer;

import 'dart:async';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:barback/barback.dart';
import 'package:code_transformers/resolver.dart';
import 'package:path/path.dart' as path;
import 'options.dart';

/**
 * Pub transformer that removes Module (and hence mirror) export in Dart.
 *   -> Run by DI only.
 * This removes the Module class, but the InjectorGenerator transformer
 * in the application will add a static Module back in.
 */
class ExportTransformer extends Transformer with ResolverTransformer {
  final TransformOptions options;

  ExportTransformer(this.options, Resolvers resolvers) {
    this.resolvers = resolvers;
  }

  isPrimary(_) => true;

  Future<bool> shouldApplyResolver(Asset asset) {
    return new Future.value(asset.id == new AssetId.parse("di|lib/di.dart"));
  }

  applyResolver(Transform transform, Resolver resolver) {
    AssetId id = transform.primaryInput.id;
    var lib = resolver.getLibrary(id);
    var unit = lib.definingCompilationUnit.node;
    var transaction = resolver.createTextEditTransaction(lib);
    var imports = unit.directives.where((d) => d is ExportDirective);
    var dir = imports.where((ExportDirective d) =>
        d.uriContent == 'module_dynamic.dart');
    transaction.edit(dir.first.offset, dir.first.end, "");
    var printer = transaction.commit();
    var url = id.path.startsWith('lib/') ?
        'package:${id.package}/${id.path.substring(4)}' : id.path;
    printer.build(url);
    transform.addOutput(new Asset.fromString(id, printer.text));
  }
}
