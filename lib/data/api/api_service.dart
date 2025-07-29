import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';
import 'package:yoen_front/data/model/api_response.dart';
import '../model/login_request.dart';
import '../model/login_response.dart';
import '../model/register_request.dart';

part 'api_service.g.dart';

@RestApi()
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  @POST("/user/register")
  Future<ApiResponse<String>> register(@Body() RegisterRequest user);

  @POST("/user/login")
  Future<ApiResponse<LoginResponse>> login(@Body() LoginRequest user);

  @GET("/user/exists")
  Future<ApiResponse<LoginResponse>> checkValidEmail(
    @Query("email") String email,
  );
}
