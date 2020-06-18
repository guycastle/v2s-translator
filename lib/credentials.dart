import 'package:googleapis/texttospeech/v1.dart';
import 'package:googleapis/vision/v1.dart';
import 'package:googleapis_auth/auth_io.dart';

class CredentialsProvider {
  CredentialsProvider();

  Future<ServiceAccountCredentials> get _credentials async {
    // Paste the JSON string of the service account below
    return ServiceAccountCredentials.fromJson(r'''
      {
        "type": "service_account",
        "project_id": "postgraduate-vtstrans",
        "private_key_id": "7da8ee181d0803f215a065cb359b75af59e082d3",
        "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC64emgxddgBX0l\n/Hxut5VpYMzerQ6WiOzRq/w2wzZcYybGPHnov0XjDXLkSMH5mAlj4h039qvZAaZG\nz18X2HievtZ9SPyuZRTCgFeEy/PUD5Vx3U7G7sJCvCnrHRq4B/rqODDiRebIvB+i\na//9YgBs+TFOnJh7EzAbGiCqaS+B4Af775w9KCxOF09WgdMQFneslWgaoFr+lGn+\nEN4nrhXxHQ8pOotyiohDhaOUyb4PYjW3uk5XgHbexmPDYQq00Kg/YM6s/dwPFrCD\n1j5NENPez5dTKqxlyiIcmVcrfW17UOt9ehXrXF+eArwgt4BcAqNkuTcpCLC3PMtk\njwhKgILjAgMBAAECggEAB4W8b7pG9xiBdxv4rkQ5gWpiFLyGj8ynK7Fuj43ADGv5\nTZV1msbIO2F5NHMxS6ixCBI79tq5BB0q4kLKox0Vjd5Ep/peIW70LPgZjcDf6bNO\n4qxz1VIbA7CrR0l+n9XCZdcpMJJ7vazE4TbTsRFWzwwgzfdDtACLuSuOEQ322ZVn\nVJ/HCDEfLCroCP/2ayq6SSxbnkgy2a0mlsTPnd8o3UrFVCWyLpY40BqTB5tN7rSr\nt5Jq5GtnBcYly5vBFX05cie42aq+0ZhkGxfugXwSuBwXH/XEiJcVfGOf0zgleZtL\njM5/+Lt//j0HfgTyZ7sumWtNIhYS9BQjf7hvJ/hRoQKBgQDrkHR5ic1911jWbjrW\n0LoBLUcWqJ6vSvD27mg0L+LPE0g2h5N4NUG7zNi+OlxyjLoab8q09s4FRx/amlpT\nLtpQc9+7QG4g8CF18jhNHldTDLvIkdCkI/cwukdFnJXaYW7XEcU/tXLBzS/5DwP1\nNYaUSRKh0u6AvW8G5DL6OgjaOQKBgQDLGE3yYEUzGAWuranU7rQ+OMpDNwWi+t47\nXb1kzpKIOtWP9DvoUZ/OwtEUf6i66j2DF/vIEkHtf9vB22901Ls/+4Y3+Lsovyfq\nEq5IxartTBRFJKMnqhXlNS9Oa2O4+NBOP6TYnTfDTL7MFuYorsX5T96e5/Ap8b2B\nXHXIisr1+wKBgQDmCiu0hN4oBiS7Quoy3aLHg2/osMJGbOjkO+2HCTx0/F+I4N0i\nht+qhmEjY9rkAom7R3CtSFfoz4xL7nBGy3pnFsFmG4VwpRAIHoLczMR6VfUL6VnW\n8Uh0TXVMhZ3RpVSYssHtdUSb/cTbc85pp9vE85c+cL54+oVyNWeS9RmwAQKBgF57\nwx+ETA02GsamAkGOf4oG74oPme61mRezR34TYDZCcMJU1F4DQz50gcJwlXXHrbBE\nQx1T6RnthrYMOTD4GtjsUgfODnwpWg9ae3xdgWR+JVv5bHHyfdcxQ/3Olgkir/4H\nO9COa7fPB2B5MsAwdufCkYYJz0AkN45sDluqvjtrAoGASQVG5h/wFEiP6uYic4xC\n0RN7UMH030Lw6U+ZCbyyEMNYg3vLKmcISzYGnDy+xbIpdJEyKhwmE9UuARugmJW5\nFhzT29WOrRSwww40wU2U5eYUXkdHY0/8RlpSiOrvngS+dgtVwelvsE8m4Oo2AG+d\n616neIhlIK2kfyKbjrb0Onc=\n-----END PRIVATE KEY-----\n",
        "client_email": "vtstrans-service-account@postgraduate-vtstrans.iam.gserviceaccount.com",
        "client_id": "111056591447255242267",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/vtstrans-service-account%40postgraduate-vtstrans.iam.gserviceaccount.com"
      }
  ''');
  }

  Future<AutoRefreshingAuthClient> get client async {
    AutoRefreshingAuthClient _client = await clientViaServiceAccount(
        await _credentials, [VisionApi.CloudVisionScope, TexttospeechApi.CloudPlatformScope]).then((c) => c);
    return _client;
  }
}
