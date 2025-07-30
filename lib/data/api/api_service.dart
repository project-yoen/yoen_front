import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';
import 'package:yoen_front/data/model/api_response.dart';
import 'package:yoen_front/data/model/destination_response.dart';
import 'package:yoen_front/data/model/travel_create_request.dart';
import 'package:yoen_front/data/model/travel_create_response.dart';
import 'package:yoen_front/data/model/user_travel_join_response.dart';
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
  Future<ApiResponse<bool>> checkValidEmail(@Query("email") String email);

  @GET("/common/destination/all")
  Future<ApiResponse<List<DestinationResponse>>> getDestinations(
    @Query("nation") String nation,
  );

  @POST("/travel/create")
  Future<ApiResponse<TravelCreateResponse>> createTravel(
    @Body() TravelCreateRequest request,
  );

  @GET("/join/userlist")
  Future<ApiResponse<List<UserTravelJoinResponse>>> getUserJoinList();

  @POST("/join/{joinCode}")
  Future<ApiResponse<String>> joinTravelByCode(
    @Path("joinCode") String joinCode,
  );

  @DELETE("/join/delete/{id}")
  Future<ApiResponse<String>> deleteUserJoinTravel(
    @Path("id") int travelJoinId,
  );
}
