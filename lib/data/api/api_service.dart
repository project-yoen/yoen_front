import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:yoen_front/data/model/api_response.dart';
import 'package:yoen_front/data/model/destination_response.dart';
import 'package:yoen_front/data/model/join_code_response.dart';
import 'package:yoen_front/data/model/record_create_response.dart';
import 'package:yoen_front/data/model/travel_create_request.dart';
import 'package:yoen_front/data/model/travel_create_response.dart';
import 'package:yoen_front/data/model/travel_response.dart';
import 'package:yoen_front/data/model/travel_user_join_response.dart';
import 'package:yoen_front/data/model/user_travel_join_response.dart';
import 'package:yoen_front/data/model/record_response.dart';

import 'package:yoen_front/data/model/travel_user_detail_response.dart';
import '../model/accept_join_request.dart';
import '../model/login_request.dart';
import '../model/login_response.dart';
import '../model/register_request.dart';
import '../model/user_response.dart';

part 'api_service.g.dart';

@RestApi()
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  @POST("/user/register")
  Future<ApiResponse<String>> register(@Body() RegisterRequest user);

  @GET("/user/profile")
  Future<ApiResponse<UserResponse>> getUserProfile();

  @POST("/user/update")
  Future<ApiResponse<UserResponse>> updateUserProfile(
    @Body() UserResponse updatedUser,
  );

  @POST("/user/login")
  Future<ApiResponse<LoginResponse>> login(@Body() LoginRequest user);

  @GET("/user/exists")
  Future<ApiResponse<bool>> checkValidEmail(@Query("email") String email);

  @MultiPart()
  @POST("/user/profileImage")
  Future<ApiResponse<String>> setProfileImage(
    @Part(name: "profileImage") File image,
  );

  @GET("/travel/userdetail")
  Future<ApiResponse<List<TravelUserDetailResponse>>> getTravelUsers(
    @Query("travelId") int travelId,
  );

  @GET("/common/destination/all")
  Future<ApiResponse<List<DestinationResponse>>> getDestinations(
    @Query("nation") String nation,
  );

  @POST("/travel/create")
  Future<ApiResponse<TravelCreateResponse>> createTravel(
    @Body() TravelCreateRequest request,
  );

  @GET("/travel")
  Future<ApiResponse<List<TravelResponse>>> getTravels();

  @POST("/travel/leave/{travelId}")
  Future<ApiResponse<String>> leaveTravel(@Path("travelId") int travelId);

  @GET("/join/userlist")
  Future<ApiResponse<List<UserTravelJoinResponse>>> getUserJoinList();

  @GET("/join/code")
  Future<ApiResponse<JoinCodeResponse>> getJoinCode(
    @Query("travelId") int travelId,
  );

  @POST("/join/{joinCode}")
  Future<ApiResponse<String>> joinTravelByCode(
    @Path("joinCode") String joinCode,
  );

  @DELETE("/join/delete/{id}")
  Future<ApiResponse<String>> deleteUserJoinTravel(
    @Path("id") int travelJoinId,
  );

  @GET("/join/travellist")
  Future<ApiResponse<List<TravelUserJoinResponse>>> getTravelJoinList(
    @Query("travelId") int travelId,
  );

  @POST("/join/accept")
  Future<ApiResponse<void>> acceptTravelJoinRequest(
    @Body() AcceptJoinRequest request,
  );

  @POST("/join/reject/{id}")
  Future<ApiResponse<void>> rejectTravelJoinRequest(
    @Path("id") int travelJoinRequestId,
  );

  @POST("/record/create")
  Future<ApiResponse<RecordCreateResponse>> createRecord(
    @Body() FormData formData,
  );

  @GET("/record")
  Future<ApiResponse<List<RecordResponse>>> getRecords(
    @Query("travelId") int travelId,
    @Query("date") String date,
  );
}
