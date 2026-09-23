class MobileInput {
  static bool up = false;
  static bool down = false;
  static bool left = false;
  static bool right = false;

  static bool _xPressed = false;
  static bool _zPressed = false;
  static bool _ePressed = false;

  static bool consumeX() {
    if (!_xPressed) {
      return false;
    }

    _xPressed = false;
    return true;
  }

  static bool consumeZ() {
    if (!_zPressed) {
      return false;
    }

    _zPressed = false;
    return true;
  }

  static bool consumeE() {
    if (!_ePressed) {
      return false;
    }

    _ePressed = false;
    return true;
  }

  static void pressX() {
    _xPressed = true;
  }

  static void pressZ() {
    _zPressed = true;
  }

  static void pressE() {
    _ePressed = true;
  }

  static void reset() {
    up = false;
    down = false;
    left = false;
    right = false;

    _xPressed = false;
    _zPressed = false;
    _ePressed = false;
  }
}