import 'dart:math';

String generateRandomCode(int length) {
  const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  Random random = Random();
  String code = '';

  for (int i = 0; i < length; i++) {
    int index = random.nextInt(chars.length);
    code += chars[index];
  }

  return code;
}