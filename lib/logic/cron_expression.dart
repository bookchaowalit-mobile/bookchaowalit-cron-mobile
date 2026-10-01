/// Pure-Dart parser and evaluator for standard five-field cron expressions.
///
/// Fields: minute (0-59), hour (0-23), day of month (1-31), month (1-12 or
/// JAN-DEC) and day of week (0-7 or SUN-SAT, where 0 and 7 are Sunday).
/// Each field accepts `*`, single values, ranges (`1-5`), lists (`1,3,5`) and
/// steps (`*/15`, `0-30/10`, `5/10`). The macros `@yearly`, `@annually`,
/// `@monthly`, `@weekly`, `@daily`, `@midnight` and `@hourly` are supported.
library;

class CronFormatException implements Exception {
  const CronFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _FieldSpec {
  const _FieldSpec(this.name, this.min, this.max, [this.names = const {}]);

  final String name;
  final int min;
  final int max;
  final Map<String, int> names;
}

const _monthNames = {
  'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MAY': 5, 'JUN': 6, //
  'JUL': 7, 'AUG': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12,
};

const _dayNames = {
  'SUN': 0, 'MON': 1, 'TUE': 2, 'WED': 3, 'THU': 4, 'FRI': 5, 'SAT': 6, //
};

const _specs = [
  _FieldSpec('minute', 0, 59),
  _FieldSpec('hour', 0, 23),
  _FieldSpec('day of month', 1, 31),
  _FieldSpec('month', 1, 12, _monthNames),
  _FieldSpec('day of week', 0, 7, _dayNames),
];

const _macros = {
  '@yearly': '0 0 1 1 *',
  '@annually': '0 0 1 1 *',
  '@monthly': '0 0 1 * *',
  '@weekly': '0 0 * * 0',
  '@daily': '0 0 * * *',
  '@midnight': '0 0 * * *',
  '@hourly': '0 * * * *',
};

const monthLabels = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

class CronExpression {
  CronExpression._(this.source, this._raw, this._values);

  /// Parses [input]; throws [CronFormatException] when it is invalid.
  factory CronExpression.parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw const CronFormatException('Enter a cron expression.');
    }
    final expanded = _macros[trimmed.toLowerCase()] ?? trimmed;
    final parts = expanded.split(RegExp(r'\s+'));
    if (parts.length != 5) {
      throw CronFormatException(
        'Expected 5 fields (minute hour day month weekday), got ${parts.length}.',
      );
    }
    final values = <Set<int>>[];
    for (var i = 0; i < 5; i++) {
      values.add(_parseField(parts[i].toUpperCase(), _specs[i]));
    }
    // Day of week 7 is an alias for Sunday.
    if (values[4].remove(7)) values[4].add(0);
    return CronExpression._(trimmed, parts, values);
  }

  final String source;
  final List<String> _raw;
  final List<Set<int>> _values;

  Set<int> get minutes => Set.unmodifiable(_values[0]);
  Set<int> get hours => Set.unmodifiable(_values[1]);
  Set<int> get daysOfMonth => Set.unmodifiable(_values[2]);
  Set<int> get months => Set.unmodifiable(_values[3]);
  Set<int> get daysOfWeek => Set.unmodifiable(_values[4]);

  // crontab(5): a day field is "restricted" unless it starts with `*`, so
  // `*/2` in day-of-month is still AND-ed with day-of-week (Vixie cron).
  bool get _domRestricted => !_raw[2].startsWith('*');
  bool get _dowRestricted => !_raw[4].startsWith('*');

  static Set<int> _parseField(String field, _FieldSpec spec) {
    if (field.isEmpty) {
      throw CronFormatException('The ${spec.name} field is empty.');
    }
    final result = <int>{};
    for (final part in field.split(',')) {
      if (part.isEmpty) {
        throw CronFormatException('Empty list item in ${spec.name}.');
      }
      var rangePart = part;
      var step = 1;
      final slash = part.indexOf('/');
      if (slash != -1) {
        rangePart = part.substring(0, slash);
        final parsedStep = _parseDecimal(part.substring(slash + 1));
        if (parsedStep == null || parsedStep < 1) {
          throw CronFormatException('Invalid step "$part" in ${spec.name}.');
        }
        step = parsedStep;
      }
      int start;
      int end;
      if (rangePart == '*') {
        start = spec.min;
        end = spec.name == 'day of week' ? 6 : spec.max;
      } else if (rangePart.contains('-')) {
        final bounds = rangePart.split('-');
        if (bounds.length != 2) {
          throw CronFormatException('Invalid range "$part" in ${spec.name}.');
        }
        start = _parseValue(bounds[0], spec);
        end = _parseValue(bounds[1], spec);
        if (start > end) {
          throw CronFormatException(
            'Range "$rangePart" in ${spec.name} runs backwards.',
          );
        }
      } else {
        start = _parseValue(rangePart, spec);
        end = slash == -1 ? start : spec.max;
      }
      for (var v = start; v <= end; v += step) {
        result.add(v);
      }
    }
    return result;
  }

  static int _parseValue(String token, _FieldSpec spec) {
    final named = spec.names[token];
    final value = named ?? _parseDecimal(token);
    if (value == null) {
      throw CronFormatException('"$token" is not valid in ${spec.name}.');
    }
    if (value < spec.min || value > spec.max) {
      throw CronFormatException(
        '${spec.name[0].toUpperCase()}${spec.name.substring(1)} must be '
        'between ${spec.min} and ${spec.max}, got $value.',
      );
    }
    return value;
  }

  /// Plain decimal digits only: `int.tryParse` would also accept `+5`,
  /// `0x1F` and other forms that cron itself rejects.
  static int? _parseDecimal(String token) =>
      RegExp(r'^[0-9]{1,4}$').hasMatch(token) ? int.parse(token) : null;

  bool _dayMatches(DateTime t) {
    final dom = _values[2].contains(t.day);
    final dow = _values[4].contains(t.weekday % 7);
    if (_domRestricted && _dowRestricted) return dom || dow;
    return dom && dow;
  }

  /// Whether the schedule fires at the minute containing [t].
  bool matches(DateTime t) =>
      _values[0].contains(t.minute) &&
      _values[1].contains(t.hour) &&
      _values[3].contains(t.month) &&
      _dayMatches(t);

  /// The next [count] run times strictly after [from] (minute precision).
  ///
  /// Returns fewer items when the schedule cannot fire within ten years
  /// (for example `0 0 30 2 *`).
  List<DateTime> nextRuns(DateTime from, {int count = 5}) {
    final runs = <DateTime>[];
    var t = DateTime(from.year, from.month, from.day, from.hour, from.minute)
        .add(const Duration(minutes: 1));
    final limitYear = from.year + 10;
    while (runs.length < count && t.year <= limitYear) {
      if (!_values[3].contains(t.month)) {
        t = DateTime(t.year, t.month + 1);
      } else if (!_dayMatches(t)) {
        t = DateTime(t.year, t.month, t.day + 1);
      } else if (!_values[1].contains(t.hour)) {
        t = DateTime(t.year, t.month, t.day, t.hour + 1);
      } else if (!_values[0].contains(t.minute)) {
        t = DateTime(t.year, t.month, t.day, t.hour, t.minute + 1);
      } else {
        runs.add(t);
        t = DateTime(t.year, t.month, t.day, t.hour, t.minute + 1);
      }
    }
    return runs;
  }

  /// A plain-English description of the schedule.
  String describe() {
    final minuteRaw = _raw[0];
    final hourRaw = _raw[1];
    final buffer = StringBuffer();
    final mins = _sorted(_values[0]);
    final hrs = _sorted(_values[1]);
    if (mins.length == 1 && hrs.length == 1) {
      buffer.write('At ${_two(hrs.single)}:${_two(mins.single)}');
    } else {
      if (minuteRaw == '*') {
        buffer.write('Every minute');
      } else if (minuteRaw.startsWith('*/')) {
        buffer.write(_every(minuteRaw.substring(2), 'minute'));
      } else {
        buffer.write('At minute ${compressRanges(mins)}');
      }
      if (hourRaw.startsWith('*/')) {
        buffer.write(', ${_every(hourRaw.substring(2), 'hour').toLowerCase()}');
      } else if (hourRaw != '*') {
        buffer.write(', during hour ${compressRanges(hrs)}');
      }
    }
    final dayParts = <String>[];
    if (_raw[2] != '*') {
      dayParts
          .add('on day ${compressRanges(_sorted(_values[2]))} of the month');
    }
    if (_raw[4] != '*') {
      dayParts.add(
        'on ${compressRanges(_sorted(_values[4]), (d) => dayLabels[d])}',
      );
    }
    if (dayParts.isNotEmpty) {
      final joiner = _domRestricted && _dowRestricted ? ' or ' : ' and ';
      buffer.write(', ${dayParts.join(joiner)}');
    }
    if (_raw[3] != '*') {
      buffer.write(
        ', in ${compressRanges(_sorted(_values[3]), (m) => monthLabels[m - 1])}',
      );
    }
    return buffer.toString();
  }

  static String _every(String step, String unit) =>
      step == '1' ? 'Every $unit' : 'Every $step ${unit}s';

  static List<int> _sorted(Set<int> values) => values.toList()..sort();

  static String _two(int v) => v.toString().padLeft(2, '0');
}

/// Formats sorted integers compactly, e.g. `[1,2,3,5]` -> `1-3, 5`.
String compressRanges(List<int> sorted, [String Function(int)? label]) {
  final fmt = label ?? (int v) => '$v';
  final parts = <String>[];
  var i = 0;
  while (i < sorted.length) {
    var j = i;
    while (j + 1 < sorted.length && sorted[j + 1] == sorted[j] + 1) {
      j++;
    }
    if (j - i >= 2) {
      parts.add('${fmt(sorted[i])}-${fmt(sorted[j])}');
    } else {
      for (var k = i; k <= j; k++) {
        parts.add(fmt(sorted[k]));
      }
    }
    i = j + 1;
  }
  return parts.join(', ');
}
