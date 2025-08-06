import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:yoen_front/data/model/api_response.dart';
import 'package:yoen_front/data/model/destination_response.dart';
import 'package:yoen_front/data/model/join_code_response.dart';
import 'package:yoen_front/data/model/payment_create_response.dart';
import 'package:yoen_front/data/model/record_create_request.dart';
import 'package:yoen_front/data/model/record_create_response.dart';
import 'package:yoen_front/data/model/travel_create_request.dart';
import 'package:yoen_front/data/model/travel_create_response.dart';
import 'package:yoen_front/data/model/travel_nickname_update.dart';
import 'package:yoen_front/data/model/travel_response.dart';
import 'package:yoen_front/data/model/travel_user_join_response.dart';
import 'package:yoen_front/data/model/user_travel_join_response.dart';
import 'package:yoen_front/data/model/record_response.dart';
import 'package:yoen_front/data/model/category_response.dart';
import 'package:yoen_front/data/model/payment_create_request.dart';

import 'package:yoen_front/data/model/travel_user_detail_response.dart';
import '../model/accept_join_request.dart';
import '../model/login_request.dart';
import '../model/login_response.dart';
import '../model/payment_detail_response.dart';
import '../model/payment_response.dart';
import '../model/register_request.dart';
import 'package:yoen_front/data/model/travel_detail_response.dart';
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

  @GET("/common/destination/all")
  Future<ApiResponse<List<DestinationResponse>>> getDestinations(
    @Query("nation") String nation,
  );

  @GET("/travel/userdetail")
  Future<ApiResponse<List<TravelUserDetailResponse>>> getTravelUsers(
    @Query("travelId") int travelId,
  );

  @POST("/travel/traveluser/nickname")
  Future<ApiResponse<String>> updateTravelNickname(
    @Body() TravelNicknameUpdate request,
  );

  @POST("/travel/create")
  Future<ApiResponse<TravelCreateResponse>> createTravel(
    @Body() TravelCreateRequest request,
  );

  @GET("/travel")
  Future<ApiResponse<List<TravelResponse>>> getTravels();

  @GET("/travel/detail")
  Future<ApiResponse<TravelDetailResponse>> getTravelDetail(
    @Query("travelId") int travelId,
  );

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

  @MultiPart()
  @POST("/record/create")
  Future<ApiResponse<RecordCreateResponse>> createRecord(
    @Part(name: 'dto', contentType: 'application/json') RecordCreateRequest dto,
    @Part(name: 'images') List<File> images,
  );

  @GET("/record")
  Future<ApiResponse<List<RecordResponse>>> getRecords(
    @Query("travelId") int travelId,
    @Query("date") String date,
  );

  @DELETE('/record/delete')
  Future<ApiResponse> deleteRecord(@Query("id") int recordId);

  @GET('/common/category')
  Future<ApiResponse<List<Category>>> getCategories(@Query('type') String type);

  @MultiPart()
  @POST("/payment/create")
  Future<ApiResponse<PaymentCreateResponse>> createPayment(
    @Part(name: 'dto', contentType: 'application/json')
    PaymentCreateRequest request,
    @Part(name: 'images') List<File> images,
  );

  @DELETE("/payment/delete")
  Future<ApiResponse<String>> deletePayment(@Query("paymentId") int paymentId);

  @GET("/payment")
  Future<ApiResponse<List<PaymentResponse>>> getPayments(
    @Query("travelId") int travelId,
    @Query("date") String date,
  );

  @GET("/payment/detail")
  Future<ApiResponse<PaymentDetailResponse>> getPaymentDetails(
    @Query("paymentId") int paymentId,
  );
}
