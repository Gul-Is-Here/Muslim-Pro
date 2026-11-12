import 'package:get/get.dart';
import 'package:intl/intl.dart';

abstract final class Formatters {
  static String time(DateTime t) => DateFormat.jm(Get.locale?.languageCode).format(t);

  /// 24-hour clock, e.g. 16:48 (compact chips and pills).
  static String clock(DateTime t) => DateFormat.Hm(Get.locale?.languageCode).format(t);

  static String countdown(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }
}
