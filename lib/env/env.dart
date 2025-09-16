import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
final class Env {
  @EnviedField(varName: 'REVENUE_CAT_IOS_API_KEY', obfuscate: true)
  static final String revenueCatIosApiKey = _Env.revenueCatIosApiKey;

  @EnviedField(varName: 'REVENUE_CAT_ANDROID_API_KEY', obfuscate: true)
  static final String revenueCatAndroidApiKey = _Env.revenueCatAndroidApiKey;

  @EnviedField(varName: 'REVENUE_CAT_PROJECT_ID', obfuscate: true)
  static final String revenueCatProjectId = _Env.revenueCatProjectId;
}
