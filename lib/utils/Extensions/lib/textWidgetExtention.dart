// An extention for use with text widget to avoid re-write boilarplate code

// ignore_for_file: file_names

import 'package:flutter/material.dart';

extension StyledText<T extends Text> on T {
  Text copyWith({
    String? data,
    InlineSpan? textSpan,
    TextStyle? style,
    StrutStyle? strutStyle,
    TextAlign? textAlign,
    TextDirection? textDirection,
    bool? softWrap,
    TextOverflow? overflow,
    double? textScaleFactor,
    Locale? locale,
    int? maxLines,
    String? semanticsLabel,
    TextWidthBasis? textWidthBasis,
    TextHeightBehavior? textHeightBehavior,
  }) {
    return Text(
      data ?? this.data ?? "",
      style: style ?? this.style,
      locale: locale ?? this.locale,
      maxLines: maxLines ?? this.maxLines,
      overflow: overflow ?? this.overflow,
      semanticsLabel: semanticsLabel ?? this.semanticsLabel,
      softWrap: softWrap ?? this.softWrap,
      strutStyle: strutStyle ?? this.strutStyle,
      textAlign: textAlign ?? this.textAlign,
      textDirection: textDirection ?? this.textDirection,
      textHeightBehavior: textHeightBehavior ?? this.textHeightBehavior,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      textWidthBasis: textWidthBasis ?? this.textWidthBasis,
    );
  }

  T bold({FontWeight? weight}) => copyWith(
        style: (style ?? const TextStyle()).copyWith(
          fontWeight: weight ?? FontWeight.bold,
        ),
      ) as T;

  ///Text overflow is inclueded
  T setMaxLines({required int lines}) {
    return copyWith(
        maxLines: lines, overflow: TextOverflow.ellipsis, softWrap: true) as T;
  }

  T italic() {
    return copyWith(
      style: (style ?? const TextStyle()).copyWith(fontStyle: FontStyle.italic),
    ) as T;
  }

  T size(double size) {
    return copyWith(
        style: (style ?? const TextStyle()).copyWith(fontSize: size)) as T;
  }

  T color(Color color) {
    return copyWith(style: (style ?? const TextStyle()).copyWith(color: color))
        as T;
  }

  T underline() => copyWith(
        style: (style ?? const TextStyle())
            .copyWith(decoration: TextDecoration.underline),
      ) as T;

  T centerAlign() => copyWith(textAlign: TextAlign.center) as T;

  T firstUpperCaseWidget() {
    String upperCase = "";
    var suffix = "";
    if (data?.isNotEmpty ?? true) {
      upperCase = data?[0].toUpperCase() ?? "";
      suffix = data!.substring(1, data?.length);
    }
    return copyWith(data: upperCase + suffix) as T;
  }

  // randomize() {
  //   String? text = data;
  //   Set<int> indexSet = {};
  //   List.generate(text?.length ?? 0, (index) {
  //     int? value = _randomGen(text, indexSet);
  //     if (value != null) {
  //       indexSet.add(value);
  //     }
  //   });

  //   print(indexSet.toList().toString());
  // }

  // int? _randomGen(String? text, Set<int> indexSet) {
  //   int random = Random().nextInt(text?.length ?? 0);
  //   if (indexSet.contains(random)) {
  //     _randomGen(text, indexSet);
  //   } else {
  //     return random;
  //   }
  //   return null;
  // }
}
