import 'package:googleapis/texttospeech/v1.dart';
import 'package:googleapis/vision/v1.dart';
import 'package:googleapis_auth/auth_io.dart';

class CredentialsProvider {
  CredentialsProvider();

  Future<ServiceAccountCredentials> get _credentials async {
    // Paste the JSON string of the service account below
    return ServiceAccountCredentials.fromJson(r'''
      {
        "type": "",
        "project_id": "",
        "private_key_id": "",
        "private_key": "",
        "client_email": "",
        "client_id": "",
        "auth_uri": "",
        "token_uri": "",
        "auth_provider_x509_cert_url": "",
        "client_x509_cert_url": ""
      }
  ''');
  }

  Future<AutoRefreshingAuthClient> get client async {
    AutoRefreshingAuthClient _client = await clientViaServiceAccount(
        await _credentials, [VisionApi.CloudVisionScope, TexttospeechApi.CloudPlatformScope]).then((c) => c);
    return _client;
  }
}
