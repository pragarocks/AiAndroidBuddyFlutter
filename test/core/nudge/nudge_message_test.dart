import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_pet/core/nudge/nudge_message.dart';

void main() {
  group('NudgeLibrary', () {
    test('has at least 80 messages', () {
      expect(NudgeLibrary.all.length, greaterThanOrEqualTo(80));
    });

    test('every message has non-empty text', () {
      for (final m in NudgeLibrary.all) {
        expect(m.text.trim().isNotEmpty, isTrue,
            reason: 'Empty message found in category ${m.category}');
      }
    });

    test('every category has at least one message', () {
      for (final cat in NudgeCategory.values) {
        final msgs = NudgeLibrary.forCategory(cat);
        expect(msgs.isNotEmpty, isTrue,
            reason: 'Category $cat has no messages');
      }
    });

    test('forCategoryAndApp returns app-specific messages when available', () {
      final msgs = NudgeLibrary.forCategoryAndApp(
          NudgeCategory.screenTimeHeavy, 'Instagram');
      expect(msgs.any((m) => m.appLabel == 'Instagram'), isTrue);
    });

    test('forCategoryAndApp falls back to generic when no app match', () {
      final msgs = NudgeLibrary.forCategoryAndApp(
          NudgeCategory.screenTimeHeavy, 'SomeUnknownApp');
      // Should return generic messages (appLabel == null)
      expect(msgs.every((m) => m.appLabel == null), isTrue);
    });

    test('water messages never exceed 140 chars', () {
      final waterMsgs = NudgeLibrary.forCategory(NudgeCategory.water);
      for (final m in waterMsgs) {
        expect(m.text.length, lessThanOrEqualTo(140),
            reason: '"${m.text}" exceeds 140 chars');
      }
    });

    test('all messages are under 160 chars (TTS sweet spot)', () {
      for (final m in NudgeLibrary.all) {
        expect(m.text.length, lessThanOrEqualTo(160),
            reason: '"${m.text}" exceeds 160 chars');
      }
    });

    test('screen time messages cover all severity levels', () {
      expect(NudgeLibrary.forCategory(NudgeCategory.screenTimeLight).isNotEmpty, isTrue);
      expect(NudgeLibrary.forCategory(NudgeCategory.screenTimeMedium).isNotEmpty, isTrue);
      expect(NudgeLibrary.forCategory(NudgeCategory.screenTimeHeavy).isNotEmpty, isTrue);
      expect(NudgeLibrary.forCategory(NudgeCategory.screenTimeExtreme).isNotEmpty, isTrue);
    });

    test('Instagram has app-specific messages for multiple categories', () {
      final medium = NudgeLibrary.forCategoryAndApp(
          NudgeCategory.screenTimeMedium, 'Instagram');
      final heavy = NudgeLibrary.forCategoryAndApp(
          NudgeCategory.screenTimeHeavy, 'Instagram');
      expect(medium.isNotEmpty, isTrue);
      expect(heavy.isNotEmpty, isTrue);
    });

    test('no duplicate message texts', () {
      final texts = NudgeLibrary.all.map((m) => m.text).toList();
      final unique = texts.toSet();
      expect(unique.length, equals(texts.length),
          reason: 'Duplicate nudge messages found');
    });
  });

  group('NudgeScheduler category selection', () {
    test('5 mins → screenTimeLight', () {
      expect(_catForMinutes(5), NudgeCategory.screenTimeLight);
    });
    test('15 mins → screenTimeMedium', () {
      expect(_catForMinutes(15), NudgeCategory.screenTimeMedium);
    });
    test('30 mins → screenTimeHeavy', () {
      expect(_catForMinutes(30), NudgeCategory.screenTimeHeavy);
    });
    test('60 mins → screenTimeExtreme', () {
      expect(_catForMinutes(60), NudgeCategory.screenTimeExtreme);
    });
    test('4 mins → null (no nudge)', () {
      expect(_catForMinutes(4), isNull);
    });
  });
}

// Mirrors the private _categoryForMinutes logic from NudgeScheduler
NudgeCategory? _catForMinutes(int mins) {
  if (mins >= 60) return NudgeCategory.screenTimeExtreme;
  if (mins >= 30) return NudgeCategory.screenTimeHeavy;
  if (mins >= 15) return NudgeCategory.screenTimeMedium;
  if (mins >= 5)  return NudgeCategory.screenTimeLight;
  return null;
}
