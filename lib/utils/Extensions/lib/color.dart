import 'dart:ui';

extension ColorExt on Color {
  Color brighten(int value) {
    Color color0 = this;

    int red = color0.red + value;
    int green = color0.green + value;
    int blue = color0.blue + value;

    return Color.fromARGB(color0.alpha, red.clamp(0, 255), green.clamp(0, 255),
        blue.clamp(0, 255));
  }

  Color darken(int value) {
    Color color0 = this;

    int red = color0.red - value;
    int green = color0.green - value;
    int blue = color0.blue - value;

    return Color.fromARGB(color0.alpha, red.clamp(0, 255), green.clamp(0, 255),
        blue.clamp(0, 255));
  }
}
