import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:legestic/l10n/api_messages.dart';
import 'package:legestic/services/api_client.dart';
import 'package:legestic/services/api_response.dart';
import 'package:legestic/services/cargo_service.dart';
import 'package:legestic/services/settings_service.dart';

import 'support/fake_token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService().init();
  });

  tearDown(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService().init();
  });

  CargoService _service(MockClient client) {
    return CargoService.withClient(
      ApiClient(client: client, tokenStorage: FakeTokenStorage()),
    );
  }

  Future<void> _create(CargoService service) {
    return service.createCargo(
      title: 'حمل سیمان',
      description: 'توضیحات بار',
      origin: 'تهران',
      destination: 'اصفهان',
      cargoType: 'کفی',
      goodsType: 'سیمان',
      weightTons: 12.5,
      estimatedPrice: 5000000,
      productId: 1,
      machineId: 2,
      ostanMabdaId: 8,
      ostanMaghsadId: 4,
    );
  }

  test(
    'createCargo maps integer-weight validation errors to Persian',
    () async {
      final service = _service(
        MockClient((request) async {
          return http.Response(
            '{"weight":["A valid integer is required."]}',
            400,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      await expectLater(_create(service), throwsA(isA<ApiException>()));
      expect(service.lastError, 'وزن: مقدار باید عدد صحیح باشد.');
    },
  );

  test('createCargo maps the same API error to English', () async {
    await SettingsService().setLocale(const Locale('en', 'US'));
    final service = _service(
      MockClient((request) async {
        return http.Response(
          '{"weight":["A valid integer is required."]}',
          400,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    await expectLater(_create(service), throwsA(isA<ApiException>()));
    expect(service.lastError, 'Weight: A valid integer is required.');
  });

  test('field names and length errors follow the active language', () {
    expect(
      ApiResponse.extractErrorMessage({
        'title': ['Ensure this field has no more than 100 characters.'],
      }, isEnglish: false),
      'عنوان: حداکثر 100 نویسه مجاز است.',
    );
    expect(
      ApiResponse.extractErrorMessage({
        'title': ['Ensure this field has no more than 100 characters.'],
      }, isEnglish: true),
      'Title: This field may have at most 100 characters.',
    );
    expect(
      ApiMessages.localizeFieldName('ostan_mabda', isEnglish: false),
      'استان مبدأ',
    );
    expect(
      ApiMessages.localizeFieldName('ostan_mabda', isEnglish: true),
      'Origin province',
    );
  });
}
