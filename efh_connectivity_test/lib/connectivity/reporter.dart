import 'result.dart';

/// Receives progress and match notifications during a run so that frontends
/// can render them however they like.
abstract class Reporter {
  /// Called with the number of rows flushed in input order and the total row
  /// count (total may be zero when unknown).
  void progress(int done, int total);

  /// Called for each Fortinet-blocked host that belongs to the configured log
  /// domain set.
  void alert(CheckResult result);

  /// Called for human-readable informational output.
  void message(String text);
}

/// Discards every notification.
class NopReporter implements Reporter {
  const NopReporter();

  @override
  void progress(int done, int total) {}

  @override
  void alert(CheckResult result) {}

  @override
  void message(String text) {}
}
