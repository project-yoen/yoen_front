import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/model/user_response.dart';
import '../data/widget/user_travel_check_tile.dart';

class UserTravelJoinScreen extends ConsumerStatefulWidget {
  const UserTravelJoinScreen({super.key});

  @override
  ConsumerState<UserTravelJoinScreen> createState() =>
      _UserTravelJoinScreenState();
}

class _UserTravelJoinScreenState extends ConsumerState<UserTravelJoinScreen> {
  @override
  Widget build(BuildContext context) {
    // 예시용 더미 데이터
    final dummyUsers = [
      UserResponse(
        name: "홍길동",
        nickname: "길동이",
        imageUrl: "https://i.pravatar.cc/150?img=3",
        email: '',
      ),
      UserResponse(
        name: "김영희",
        nickname: "영희",
        imageUrl: "https://i.pravatar.cc/150?img=5",
        email: '',
      ),
      UserResponse(
        name: "박철수",
        nickname: "철수",
        imageUrl: "https://i.pravatar.cc/150?img=7",
        email: '',
      ),
    ];

    final travelList = [
      {"id": 1, "name": "제주도 여행", "nation": "대한민국", "users": dummyUsers},
      {
        "id": 2,
        "name": "오사카 여행",
        "nation": "일본",
        "users": dummyUsers.sublist(0, 2),
      },
      {"id": 3, "name": "파리 여행", "nation": "프랑스", "users": <UserResponse>[]},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("신청 여행 목록")),
      body: ListView.builder(
        itemCount: travelList.length,
        itemBuilder: (context, index) {
          final travel = travelList[index];
          return UserTravelCheckTile(
            travelId: travel["id"] as int,
            travelName: travel["name"] as String,
            nation: travel["nation"] as String,
            users: travel["users"] as List<UserResponse>,
            onCancel: () {
              print(travel["id"]);
            },
          );
        },
      ),
    );
  }
}
