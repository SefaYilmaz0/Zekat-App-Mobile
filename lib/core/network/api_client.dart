import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;

  ApiClient() : dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.ornek.com', // TODO: Zekat-App API URL'si veya kur API'si buraya eklenecek
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  // Kurları getiren örnek bir metot
  Future<Response> getExchangeRates() async {
    return await dio.get('/exchange-rates');
  }
}

