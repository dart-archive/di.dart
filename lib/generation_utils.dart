library di.generation_utils;

import 'package:analyzer/src/generated/ast.dart';

class _Annotation {
  final String key;
  final String constructor;

  _Annotation(this.key, this.constructor);
}

_Annotation parseAnnotation(FormalParameter formalParameter, Function resolveClassIdentifier) {
  if (formalParameter.element.metadata.isEmpty) return null;

  final metadata = (formalParameter as NormalFormalParameter).metadata;
  assert(metadata.length == 1);

  Annotation annotation = metadata.first;
  var element = annotation.element;

  final clazz = resolveClassIdentifier(element.returnType);
  final source = annotation.toSource();
  final args = _annotationArgsToStr(annotation.arguments.arguments, resolveClassIdentifier);

  return new _Annotation(toValidDartId(source), "const $clazz($args)");
}

String _annotationArgsToStr(NodeList<Expression> args, Function resolveClassIdentifier) {
  toStr(arg) => (arg is SimpleIdentifier) ? resolveClassIdentifier(arg.staticElement.type) : arg;
  return args.map(toStr).join(", ");
}

String toValidDartId(String str) =>
    str.replaceAll(new RegExp(r"\W+"), "_");