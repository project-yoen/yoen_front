import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/notifier/register_notifier.dart';
import 'package:yoen_front/view/register_result.dart';

const Map<String?, String> mapToEng = {
  '남성': 'MALE',
  '여성': 'FEMALE',
  '기타': 'OTHERS',
};

class RegisterAgeGenderScreen extends ConsumerStatefulWidget {
  const RegisterAgeGenderScreen({super.key});

  @override
  ConsumerState<RegisterAgeGenderScreen> createState() =>
      _RegisterAgeGenderScreenState();
}

class _RegisterAgeGenderScreenState
    extends ConsumerState<RegisterAgeGenderScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  String? _selectedGender;

  // FocusNodes for each text field
  late FocusNode _yearFocusNode;
  late FocusNode _monthFocusNode;
  late FocusNode _dayFocusNode;
  int _prevYearLength = 0;
  int _prevMonthLength = 0;

  @override
  void initState() {
    super.initState();

    _yearFocusNode = FocusNode();
    _monthFocusNode = FocusNode();
    _dayFocusNode = FocusNode();

    _yearController.addListener(() {
      setState(() {});
      final current = _yearController.text.length;

      if (_prevYearLength < current && current == 4) {
        FocusScope.of(context).requestFocus(_monthFocusNode);
      }

      _prevYearLength = current;
    });

    _monthController.addListener(() {
      setState(() {});
      final current = _monthController.text.length;

      if (_prevMonthLength < current && current == 2) {
        FocusScope.of(context).requestFocus(_dayFocusNode);
      }

      _prevMonthLength = current;
    });

    _dayController.addListener(() {
      setState(() {});
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

  bool isEmptyField() {
    return _yearController.text.isEmpty ||
        _dayController.text.isEmpty ||
        _monthController.text.isEmpty ||
        _selectedGender == null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _formKey.currentState?.validate();
      },
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
                            return '연도를 입력해주세요.';
                          }
                          if (value.length != 4) {
                            return '형식을 확인해주세요.';
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
                            return '날짜(월)를 입력해주세요.';
                          }
                          if (value.length != 2) {
                            return '형식을 확인해주세요.';
                          }
                          final month = int.tryParse(value);
                          if (month == null || month < 1 || month > 12) {
                            return '형식을 확인해주세요.';
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
                            return '날짜(일)를 입력해주세요.';
                          }
                          if (value.length != 2) {
                            return '형식을 확인해주세요.';
                          }
                          final day = int.tryParse(value);
                          if (day == null || day < 1 || day > 31) {
                            return '형식을 확인해주세요.';
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
                  onPressed: (!isEmptyField())
                      ? () {
                          // 유효성 검사 등 처리
                          if (_formKey.currentState!.validate()) {
                            final provider = ref.read(
                              registerNotifierProvider.notifier,
                            );
                            // 다음 로직
                            final birthday =
                                '${_yearController.text}-${_monthController.text}-${_dayController.text}';
                            provider.setBirthday(birthday);

                            provider.setGender(mapToEng[_selectedGender]!);
                            provider.submit();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RegisterResultScreen(),
                              ),
                            );
                          }
                        }
                      : null,
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
