import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'PINATA_API_KEY', obfuscate: true)
  static final String pinataApiKey = _Env.pinataApiKey;

  @EnviedField(varName: 'PINATA_SECRET_KEY', obfuscate: true)
  static final String pinataSecretKey = _Env.pinataSecretKey;
}