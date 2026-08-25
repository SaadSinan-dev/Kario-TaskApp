/// Serialization helpers shared by every entity.
///
/// Kairo's models are hand-written immutable value types rather than generated
/// ones. The trade-off is documented in the README: with ~15 entities the
/// generated code would outweigh what it saves, and hand-written `fromJson`
/// lets each model apply its own migration-tolerant defaults — which is what
/// keeps a locally persisted workspace readable after a schema change.
library;

typedef JsonMap = Map<String, dynamic>;

/// Reads an ISO-8601 string, tolerating nulls and malformed values.
DateTime? readDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

/// Same as [readDate] but guarantees a value; used for `createdAt` style
/// fields that must never be null.
DateTime readDateOr(Object? value, DateTime fallback) =>
    readDate(value) ?? fallback;

String? writeDate(DateTime? value) => value?.toIso8601String();

List<String> readStringList(Object? value) {
  if (value is! List) return const <String>[];
  return value.whereType<String>().toList(growable: false);
}

List<JsonMap> readObjectList(Object? value) {
  if (value is! List) return const <JsonMap>[];
  return value.whereType<Map<dynamic, dynamic>>().map(asJsonMap).toList();
}

/// Hive returns `Map<dynamic, dynamic>` for nested objects; normalise once here
/// so no model has to care where the map came from.
JsonMap asJsonMap(Map<dynamic, dynamic> raw) => raw.map(
  (Object? key, Object? value) => MapEntry<String, dynamic>('$key', value),
);

String readString(Object? value, [String fallback = '']) =>
    value is String ? value : fallback;

int readInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? readIntOrNull(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}

double readDouble(Object? value, [double fallback = 0]) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

bool readBool(Object? value, [bool fallback = false]) =>
    value is bool ? value : fallback;

/// Colours are persisted as ARGB integers, which survives a JSON round-trip
/// and stays readable in an export.
int readColorValue(Object? value, int fallback) => readInt(value, fallback);
