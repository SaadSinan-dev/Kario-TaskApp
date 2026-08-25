import 'package:flutter/foundation.dart';

/// A scored fuzzy match with the character positions that matched, so the UI
/// can highlight exactly what the query hit.
@immutable
class FuzzyMatch {
  const FuzzyMatch({required this.score, required this.positions});

  final int score;
  final List<int> positions;

  static const FuzzyMatch none = FuzzyMatch(score: 0, positions: <int>[]);

  bool get isMatch => score > 0;
}

/// Subsequence matcher in the spirit of a command palette: every query
/// character must appear in order, and matches are rewarded for landing on
/// word boundaries, consecutive runs, and the start of the string.
///
/// Deliberately hand-written and dependency-free — it is ~40 lines, runs over
/// in-memory collections, and keeping it here means the scoring can be tuned
/// for Kairo's own data rather than a generic library's idea of relevance.
abstract final class Fuzzy {
  static const int _bonusStart = 24;
  static const int _bonusBoundary = 14;
  static const int _bonusConsecutive = 10;
  static const int _bonusExactCase = 2;
  static const int _penaltyGap = 2;

  static FuzzyMatch match(String haystack, String needle) {
    if (needle.isEmpty) return const FuzzyMatch(score: 1, positions: <int>[]);
    if (haystack.isEmpty) return FuzzyMatch.none;

    final String lowerHay = haystack.toLowerCase();
    final String lowerNeedle = needle.toLowerCase();

    // A contiguous substring hit always outranks a scattered one.
    final int direct = lowerHay.indexOf(lowerNeedle);
    if (direct >= 0) {
      final bool atStart = direct == 0;
      final bool atBoundary = atStart || _isBoundary(haystack, direct);
      return FuzzyMatch(
        score:
            120 +
            (atStart ? _bonusStart : 0) +
            (atBoundary ? _bonusBoundary : 0) +
            (needle.length * 4) -
            (direct > 24 ? 8 : 0),
        positions: <int>[for (int i = 0; i < needle.length; i++) direct + i],
      );
    }

    int score = 0;
    int haystackIndex = 0;
    int lastMatch = -2;
    final List<int> positions = <int>[];

    for (int n = 0; n < lowerNeedle.length; n++) {
      final int target = lowerNeedle.codeUnitAt(n);
      int found = -1;
      for (int h = haystackIndex; h < lowerHay.length; h++) {
        if (lowerHay.codeUnitAt(h) == target) {
          found = h;
          break;
        }
      }
      if (found < 0) return FuzzyMatch.none;

      score += 8;
      if (found == 0) score += _bonusStart;
      if (_isBoundary(haystack, found)) score += _bonusBoundary;
      if (found == lastMatch + 1) score += _bonusConsecutive;
      if (haystack.codeUnitAt(found) == needle.codeUnitAt(n)) {
        score += _bonusExactCase;
      }
      final int gap = found - lastMatch - 1;
      if (gap > 0) score -= (gap * _penaltyGap).clamp(0, 12);

      positions.add(found);
      lastMatch = found;
      haystackIndex = found + 1;
    }

    // Shorter haystacks are more likely to be what the user meant.
    score += (40 - haystack.length).clamp(-10, 10);
    return score > 0
        ? FuzzyMatch(score: score, positions: positions)
        : FuzzyMatch.none;
  }

  /// Scores a record across several fields, keeping the best field's hit.
  static FuzzyMatch matchAny(Iterable<String> fields, String needle) {
    FuzzyMatch best = FuzzyMatch.none;
    for (final String field in fields) {
      final FuzzyMatch candidate = match(field, needle);
      if (candidate.score > best.score) best = candidate;
    }
    return best;
  }

  static bool _isBoundary(String value, int index) {
    if (index == 0) return true;
    final int previous = value.codeUnitAt(index - 1);
    const int space = 32, dash = 45, underscore = 95, slash = 47, dot = 46;
    if (previous == space ||
        previous == dash ||
        previous == underscore ||
        previous == slash ||
        previous == dot) {
      return true;
    }
    // camelCase boundary.
    final int current = value.codeUnitAt(index);
    return _isLower(previous) && _isUpper(current);
  }

  static bool _isUpper(int code) => code >= 65 && code <= 90;
  static bool _isLower(int code) => code >= 97 && code <= 122;
}
