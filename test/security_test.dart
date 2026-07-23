import 'package:flutter_test/flutter_test.dart';
import 'package:vdoninja_sdk/src/vdoninja_sdk/vdoninja_sdk_web.dart';
import 'package:vdoninja_sdk/src/whep_client/whep_client_web.dart';
import 'package:vdoninja_sdk/src/whip_client/whip_client_web.dart';

void main() {
  group('Security URI Validation', () {
    test('SDK Web initialize rejects malicious URI schemes', () {
      expect(
          () => VDONinjaSDKWeb.initialize(cdnUrl: 'javascript:alert(1)'),
          throwsArgumentError);
      expect(
          () => VDONinjaSDKWeb.initialize(cdnUrl: 'data:text/javascript,alert(1)'),
          throwsArgumentError);
      expect(
          () => VDONinjaSDKWeb.initialize(cdnUrl: 'http://example.com/script.js'),
          throwsArgumentError);
    });

    test('WHEP Client initialize rejects malicious URI schemes', () {
      expect(
          () => initializeWHEP(cdnUrl: 'javascript:alert(1)'),
          throwsArgumentError);
      expect(
          () => initializeWHEP(cdnUrl: 'data:text/javascript,alert(1)'),
          throwsArgumentError);
      expect(
          () => initializeWHEP(cdnUrl: 'http://example.com/script.js'),
          throwsArgumentError);
    });

    test('WHIP Client initialize rejects malicious URI schemes', () {
      expect(
          () => initializeWHIP(cdnUrl: 'javascript:alert(1)'),
          throwsArgumentError);
      expect(
          () => initializeWHIP(cdnUrl: 'data:text/javascript,alert(1)'),
          throwsArgumentError);
      expect(
          () => initializeWHIP(cdnUrl: 'http://example.com/script.js'),
          throwsArgumentError);
    });
  });
}
