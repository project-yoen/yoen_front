import 'package:flutter/material.dart';

class RegisterAgeGenderScreen extends StatefulWidget {
  const RegisterAgeGenderScreen({super.key});

  @override
  State<RegisterAgeGenderScreen> createState() =>
      _RegisterAgeGenderScreenState();
}

class _RegisterAgeGenderScreenState extends State<RegisterAgeGenderScreen> {
  String? _selectedYear;
  String? _selectedMonth;
  String? _selectedDay;
  String? _selectedGender;

  final List<String> _years = List.generate(
    80,
    (index) => (1950 + index).toString(),
  );
  final List<String> _months = List.generate(
    12,
    (index) => (index + 1).toString().padLeft(2, '0'),
  );
  final List<String> _days = List.generate(
    31,
    (index) => (index + 1).toString().padLeft(2, '0'),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Text(
              '생일 / 성별',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return DropdownMenu<String>(
                        width: constraints.maxWidth,
                        initialSelection: _selectedYear,
                        label: const Text('년'),
                        requestFocusOnTap: false,
                        menuHeight: 300,
                        expandedInsets: EdgeInsets.zero,
                        inputDecorationTheme: const InputDecorationTheme(
                          border: OutlineInputBorder(),
                        ),
                        dropdownMenuEntries: _years
                            .map<DropdownMenuEntry<String>>((String value) {
                              return DropdownMenuEntry<String>(
                                value: value,
                                label: value,
                              );
                            })
                            .toList(),
                        onSelected: (String? value) {
                          setState(() {
                            _selectedYear = value;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return DropdownMenu<String>(
                        width: constraints.maxWidth,
                        initialSelection: _selectedMonth,
                        label: const Text('월'),
                        requestFocusOnTap: false,
                        menuHeight: 300,
                        expandedInsets: EdgeInsets.zero,
                        inputDecorationTheme: const InputDecorationTheme(
                          border: OutlineInputBorder(),
                        ),
                        dropdownMenuEntries: _months
                            .map<DropdownMenuEntry<String>>((String value) {
                              return DropdownMenuEntry<String>(
                                value: value,
                                label: value,
                              );
                            })
                            .toList(),
                        onSelected: (String? value) {
                          setState(() {
                            _selectedMonth = value;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return DropdownMenu<String>(
                        width: constraints.maxWidth,
                        initialSelection: _selectedDay,
                        label: const Text('일'),
                        requestFocusOnTap: false,
                        menuHeight: 300,
                        expandedInsets: EdgeInsets.zero,
                        inputDecorationTheme: const InputDecorationTheme(
                          border: OutlineInputBorder(),
                        ),
                        dropdownMenuEntries: _days
                            .map<DropdownMenuEntry<String>>((String value) {
                              return DropdownMenuEntry<String>(
                                value: value,
                                label: value,
                              );
                            })
                            .toList(),
                        onSelected: (String? value) {
                          setState(() {
                            _selectedDay = value;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
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
              child: FloatingActionButton(
                onPressed: () {
                  // TODO: 다음 화면으로 이동 또는 완료
                },
                child: const Icon(Icons.arrow_forward),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
