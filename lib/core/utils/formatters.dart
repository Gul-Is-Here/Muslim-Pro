import 'package:get/get.dart';
import 'package:intl/intl.dart';

abstract final class Formatters {
  static String time(DateTime t) => DateFormat.jm(Get.locale?.languageCode).format(t);

  /// 12-hour clock with AM/PM, e.g. 4:48 PM (chips and pills).
  static String clock(DateTime t) => DateFormat('h:mm a', Get.locale?.languageCode).format(t);

  static String countdown(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }
}
