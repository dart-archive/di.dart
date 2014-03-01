library di.transformers.refactor;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:barback/barback.dart';
import 'package:code_transformers/resolver.dart';
import 'package:source_maps/refactor.dart';


/// Transforms all simple identifiers of [identifier] to be [replacement] in the
/// entry point of the application.
///
/// This will resolve the full name of [identifier] and warn if it cannot be
/// resolved.
///
/// If the identifier is found and modifications are made then an import will be
/// added to the file indicated by [generatedFilename].
void transformIdentifiers(Transform transform, Resolver resolver,
    {String identifier, String replacement, String generatedFilename,
    String importPrefix}) {

  var identifierElement = resolver.getLibraryVariable(identifier);
  if (identifierElement != null) {
    identifierElement = identifierElement.getter;
  } else {
    identifierElement = resolver.getLibraryFunction(identifier);
  }

  if (identifierElement == null) {
    transform.logger.info('Unable to resolve $identifier, not '
        'transforming entry point.');
    transform.addOutput(transform.primaryInput);
    return;
  }

  var lib = resolver.entryLibrary;
  var transaction = resolver.createTextEditTransaction(lib);
  var unit = lib.definingCompilationUnit.node;

  unit.accept(new _IdentifierTransformer(transaction, identifierElement,
      '$importPrefix.$replacement'));

  if (transaction.hasEdits) {
    _addImport(transaction, unit, generatedFilename, importPrefix);
  }
  _commitTransaction(transaction, transform);
}

/// Commits the transaction if there have been edits, otherwise just adds
/// the input as an output.
void _commitTransaction(TextEditTransaction transaction, Transform transform) {
  var id = transform.primaryInput.id;

  if (transaction.hasEdits) {
    var printer = transaction.commit();
    var url = id.path.startsWith('lib/')
        ? 'package:${id.package}/${id.path.substring(4)}' : id.path;
    printer.build(url);
    transform.addOutput(new Asset.fromString(id, printer.text));
  } else {
    // No modifications, so just pass the source through.
    transform.addOutput(transform.primaryInput);
  }
}

/// Injects an import into the list of imports in the file.
void _addImport(TextEditTransaction transaction, CompilationUnit unit,
    String uri, String alias) {
  var libDirective;
  for (var directive in unit.directives) {
    if (directive is ImportDirective) {
      transaction.edit(directive.keyword.offset, directive.keyword.offset,
          'import \'$uri\' as $alias;\n');
      return;
    } else if (directive is LibraryDirective) {
      libDirective = directive;
    }
  }

  // No imports, add after the library directive if there was one.
  if (libDirective != null) {
    transaction.edit(libDirective.endToken.offset + 2,
        libDirective.endToken.offset + 2,
        'import \'$uri\' as $alias;\n');
  }
}

/// Vistior which changes every reference to a resolved element to a specific
/// string value.
class _IdentifierTransformer extends GeneralizingASTVisitor {
  final TextEditTransaction transaction;
  /// The element which all references to should be replaced.
  final Element original;
  /// The text which should replace [original].
  final String replacement;

  _IdentifierTransformer(this.transaction, this.original, this.replacement);

  visitIdentifier(Identifier node) {
    if (node.bestElement == original) {
      transaction.edit(node.beginToken.offset, node.endToken.end, replacement);
      return;
    }

    super.visitIdentifier(node);
  }

  // Bug 17043- should be eliminated once prefixed top-level methods are
  // treated as prefixed identifiers.
  visitMethodInvocation(MethodInvocation m) {
    if (m.methodName.bestElement == original) {
      if (m.target is SimpleIdentifier) {
        // Include the prefix in the rename.
        transaction.edit(m.target.beginToken.offset, m.methodName.endToken.end,
            replacement);
      } else {
        transaction.edit(m.methodName.beginToken.offset,
            m.methodName.endToken.end, replacement);
      }
      return;
    }
    super.visitMethodInvocation(m);
  }

  // Skip the contents of imports/exports/parts
  visitUriBasedDirective(ImportDirective d) {}
}
