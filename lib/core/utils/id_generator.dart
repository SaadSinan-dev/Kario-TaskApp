import 'package:uuid/uuid.dart';

/// Identifier generation.
///
/// Ids are created on the client so optimistic updates can render immediately
/// with their final identity — no swapping a temporary id for a server one
/// after the fact.
abstract final class Ids {
  static const Uuid _uuid = Uuid();

  /// A prefixed, sortable-ish id: `tsk_9f2c…`. The prefix makes logs and the
  /// exported JSON readable at a glance.
  static String create(String prefix) =>
      '${prefix}_${_uuid.v4().replaceAll('-', '').substring(0, 20)}';

  static String task() => create('tsk');
  static String subtask() => create('sub');
  static String project() => create('prj');
  static String workspace() => create('wsp');
  static String comment() => create('cmt');
  static String label() => create('lbl');
  static String notification() => create('ntf');
  static String activity() => create('act');
  static String milestone() => create('mls');
  static String user() => create('usr');
  static String session() => create('fcs');
}
