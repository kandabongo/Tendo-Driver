import 'dart:math';

extension StringParsing on String {
  //

  String telFormat() {
    return this.replaceAll(new RegExp(r'^0+(?=.)'), '');
  }

  bool get isNotDefaultImage {
    return !this.toString().contains("default");
  }
}

const _randomAlphaNumericChars =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

String randomAlphaNumeric(int length) {
  final random = Random.secure();
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => _randomAlphaNumericChars.codeUnitAt(
        random.nextInt(_randomAlphaNumericChars.length),
      ),
    ),
  );
}
