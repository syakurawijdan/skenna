import 'package:flutter_test/flutter_test.dart';
import 'package:skenna/data/api_client.dart';

void main() {
  test('ApiClient baseUrl has http scheme', () {
    final client = ApiClient();
    expect(client.baseUrl, startsWith('http'));
  });
}
