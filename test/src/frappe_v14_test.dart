// ignore_for_file: prefer_const_constructors
import 'package:frappe_dart/frappe_dart.dart';
import 'package:test/test.dart';

void main() {
  group('FrappeV14', () {
    test('can be instantiated', () {
      expect(
        FrappeV14(
          baseUrl: 'https://example.com',
        ),
        isNotNull,
      );
    });
  });
}