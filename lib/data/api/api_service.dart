import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';
import 'package:yoen_front/data/model/api_response.dart';
import '../model/register_request.dart';

part 'api_service.g.dart';

@RestApi(baseUrl: "http://localhost:8080")
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  @GET("/user/{id}")
  Future<RegisterRequest> getUser(@Path("id") String id);

  @GET("/user/getAllUser")
  Future<List<RegisterRequest>> getAllUser(@Path("id") String id);

  @POST("/user/register")
  Future<ApiResponse<String>> createUser(@Body() RegisterRequest user);
}
