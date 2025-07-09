import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegisterAgeGenderScreen extends StatefulWidget {
  const RegisterAgeGenderScreen({super.key});

  @override
  State<RegisterAgeGenderScreen> createState() =>
      _RegisterAgeGenderScreenState();
}

class _RegisterAgeGenderScreenState extends State<RegisterAgeGenderScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  String? _selectedGender;

  // FocusNodes for each text field
  late FocusNode _yearFocusNode;
  late FocusNode _monthFocusNode;
  late FocusNode _dayFocusNode;

  @override
  void initState() {
    super.initState();
    _yearFocusNode = FocusNode();
    _monthFocusNode = FocusNode();
    _dayFocusNode = FocusNode();

    // Add listeners to trigger validation when each field loses focus
    _yearFocusNode.addListener(() {
      if (!_yearFocusNode.hasFocus) {
        _formKey.currentState?.validate();
      }
    });
    _monthFocusNode.addListener(() {
      if (!_monthFocusNode.hasFocus) {
        _formKey.currentState?.validate();
      }
    });
    _dayFocusNode.addListener(() {
      if (!_dayFocusNode.hasFocus) {
        _formKey.currentState?.validate();
      }
    });
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();

    _yearFocusNode.dispose();
    _monthFocusNode.dispose();
    _dayFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          scrolledUnderElevation: 0.0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                '생일 / 성별',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                autovalidateMode:
                    AutovalidateMode.disabled, // Change to disabled
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _yearController,
                        focusNode: _yearFocusNode, // Assign FocusNode
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: const InputDecoration(
                          labelText: '년',
                          border: OutlineInputBorder(),
                          helperText: ' ', // 공간 확보
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return null; // 비어있을 때는 유효성 검사하지 않음
                          }
                          if (value.length != 4) {
                            return 'YYYY-MM-DD 형식을 지켜주세요.';
                          }
                          if (int.tryParse(value) == null) {
                            return '숫자만 입력 가능합니다.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _monthController,
                        focusNode: _monthFocusNode, // Assign FocusNode
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        decoration: const InputDecoration(
                          labelText: '월',
                          border: OutlineInputBorder(),
                          helperText: ' ', // 공간 확보
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return null; // 비어있을 때는 유효성 검사하지 않음
                          }
                          if (value.length != 2) {
                            return 'YYYY-MM-DD 형식을 지켜주세요.';
                          }
                          final month = int.tryParse(value);
                          if (month == null || month < 1 || month > 12) {
                            return 'YYYY-MM-DD 형식을 지켜주세요.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _dayController,
                        focusNode: _dayFocusNode, // Assign FocusNode
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        decoration: const InputDecoration(
                          labelText: '일',
                          border: OutlineInputBorder(),
                          helperText: ' ', // 공간 확보
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return null; // 비어있을 때는 유효성 검사하지 않음
                          }
                          if (value.length != 2) {
                            return 'YYYY-MM-DD 형식을 지켜주세요.';
                          }
                          final day = int.tryParse(value);
                          if (day == null || day < 1 || day > 31) {
                            return 'YYYY-MM-DD 형식을 지켜주세요.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  return DropdownMenu<String>(
                    width: constraints.maxWidth,
                    initialSelection: _selectedGender,
                    label: const Text('성별'),
                    requestFocusOnTap: false,
                    expandedInsets: EdgeInsets.zero,
                    inputDecorationTheme: const InputDecorationTheme(
                      border: OutlineInputBorder(),
                    ),
                    dropdownMenuEntries: ['남성', '여성', '기타']
                        .map<DropdownMenuEntry<String>>((String value) {
                          return DropdownMenuEntry<String>(
                            value: value,
                            label: value,
                          );
                        })
                        .toList(),
                    onSelected: (String? value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  );
                },
              ),
              const Spacer(),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () {
                    // 유효성 검사 등 처리
                    if (_formKey.currentState!.validate()) {
                      // 다음 로직
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(), // 원형 버튼
                    padding: const EdgeInsets.all(20), // 버튼 크기 조절
                    backgroundColor: Colors.deepPurple, // 배경색
                    foregroundColor: Colors.white, // 아이콘 색
                    elevation: 4, // 그림자 깊이
                  ),
                  child: const Icon(Icons.arrow_forward, size: 30),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
