import 'package:flutter_test/flutter_test.dart';
import 'package:modern_finance/screens/education/models/education_models.dart'; // Adjust import path if necessary

void main() {
  group('Lesson Model Tests', () {
    test('Lesson isBookmarked defaults to false and can be updated', () {
      final lesson = Lesson(
        id: 'test1',
        title: 'Test Lesson',
        description: 'Desc',
        type: LessonType.theory,
        estimatedTime: '10 min',
        order: 1,
        // isBookmarked is not provided, should default to false
      );
      expect(lesson.isBookmarked, isFalse, reason: 'Default isBookmarked should be false');

      // Test updating isBookmarked
      lesson.isBookmarked = true;
      expect(lesson.isBookmarked, isTrue, reason: 'isBookmarked should be updatable to true');

      lesson.isBookmarked = false;
      expect(lesson.isBookmarked, isFalse, reason: 'isBookmarked should be updatable to false');
    });

    test('Lesson.fromJson handles isBookmarked correctly', () {
      // Case 1: JSON with isBookmarked = true
      final jsonDataWithBookmarkTrue = {
        'id': 'test2',
        'title': 'Test Lesson 2',
        'description': 'Description for Test 2',
        'type': 'theory',
        'estimatedTime': '5 min',
        'order': 2,
        'isBookmarked': true,
        'content': [],
        'prerequisites': [],
        // Add other required fields if any, like 'quiz': null
      };
      final lessonWithBookmarkTrue = Lesson.fromJson(jsonDataWithBookmarkTrue);
      expect(lessonWithBookmarkTrue.isBookmarked, isTrue, reason: 'fromJson should parse isBookmarked: true');

      // Case 2: JSON with isBookmarked = false
      final jsonDataWithBookmarkFalse = {
        'id': 'test3',
        'title': 'Test Lesson 3',
        'description': 'Description for Test 3',
        'type': 'practice',
        'estimatedTime': '15 min',
        'order': 3,
        'isBookmarked': false,
        'content': [],
        'prerequisites': [],
      };
      final lessonWithBookmarkFalse = Lesson.fromJson(jsonDataWithBookmarkFalse);
      expect(lessonWithBookmarkFalse.isBookmarked, isFalse, reason: 'fromJson should parse isBookmarked: false');

      // Case 3: JSON without isBookmarked field (should default to false)
      final jsonDataWithoutBookmark = {
        'id': 'test4',
        'title': 'Test Lesson 4',
        'description': 'Description for Test 4',
        'type': 'interactive',
        'estimatedTime': '20 min',
        'order': 4,
        'content': [],
        'prerequisites': [],
      };
      final lessonWithoutBookmark = Lesson.fromJson(jsonDataWithoutBookmark);
      expect(lessonWithoutBookmark.isBookmarked, isFalse, reason: 'fromJson should default isBookmarked to false if not present');
    });

    test('Lesson.copyWith copies isBookmarked correctly', () {
      final originalLesson = Lesson(
        id: 'test_copy',
        title: 'Original Copy Lesson',
        description: 'Original Description',
        type: LessonType.quiz,
        estimatedTime: '30 min',
        order: 5,
        isBookmarked: true,
      );

      // Copy with no change to isBookmarked
      Lesson copiedLesson = originalLesson.copyWith();
      expect(copiedLesson.isBookmarked, isTrue, reason: 'copyWith should retain isBookmarked if not specified');
      expect(copiedLesson.id, originalLesson.id); // Sanity check

      // Copy and change isBookmarked to false
      copiedLesson = originalLesson.copyWith(isBookmarked: false);
      expect(copiedLesson.isBookmarked, isFalse, reason: 'copyWith should update isBookmarked to false');
      expect(copiedLesson.id, originalLesson.id);

      // Copy and change isBookmarked to true (from an initial false)
      final originalLessonFalseBookmark = Lesson(
        id: 'test_copy_false',
        title: 'Original False Bookmark',
        description: 'Desc',
        type: LessonType.theory,
        estimatedTime: '10m',
        order: 6,
        isBookmarked: false,
      );
      copiedLesson = originalLessonFalseBookmark.copyWith(isBookmarked: true);
      expect(copiedLesson.isBookmarked, isTrue, reason: 'copyWith should update isBookmarked to true');
      expect(copiedLesson.id, originalLessonFalseBookmark.id);
    });
  });
}
