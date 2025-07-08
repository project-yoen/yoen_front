import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Cupertino import 추가

class RegisterAgeGenderScreen extends StatefulWidget {
  const RegisterAgeGenderScreen({super.key});

  @override
  State<RegisterAgeGenderScreen> createState() =>
      _RegisterAgeGenderScreenState();
}

class _RegisterAgeGenderScreenState extends State<RegisterAgeGenderScreen> {
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedGenderValue;

  @override
  void initState() {
    super.initState();
    // 초기값 설정 (선택 사항, 여기서는 2000년 1월 1일로 설정)
    _selectedDate = DateTime(2000, 1, 1);
    _yearController.text = _selectedDate!.year.toString();
    _monthController.text = _selectedDate!.month.toString().padLeft(2, '0');
    _dayController.text = _selectedDate!.day.toString().padLeft(2, '0');
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  void _showDatePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: MediaQuery.of(context).copyWith().size.height / 3,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                color: Colors.grey[200],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('취소'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    CupertinoButton(
                      child: const Text('선택'),
                      onPressed: () {
                        if (_selectedDate != null) {
                          _yearController.text = _selectedDate!.year.toString();
                          _monthController.text = _selectedDate!.month
                              .toString()
                              .padLeft(2, '0');
                          _dayController.text = _selectedDate!.day
                              .toString()
                              .padLeft(2, '0');
                        }
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDate ?? DateTime(2000, 1, 1),
                  minimumDate: DateTime(1950, 1, 1),
                  maximumDate: DateTime(2030, 12, 31),
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      _selectedDate = newDate;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGenderPicker(BuildContext context) {
    final List<String> genders = ['남성', '여성', '기타'];
    int initialIndex = _selectedGenderValue != null
        ? genders.indexOf(_selectedGenderValue!)
        : 0;
    if (initialIndex == -1) initialIndex = 0; // Fallback if not found

    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: MediaQuery.of(context).copyWith().size.height / 3,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                color: Colors.grey[200],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('취소'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    CupertinoButton(
                      child: const Text('선택'),
                      onPressed: () {
                        _genderController.text =
                            _selectedGenderValue ?? genders[0];
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: initialIndex,
                  ),
                  itemExtent: 32.0, // Height of each item
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      _selectedGenderValue = genders[index];
                    });
                  },
                  children: List<Widget>.generate(genders.length, (int index) {
                    return Center(child: Text(genders[index]));
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            GestureDetector(
              onTap: () => _showDatePicker(context),
              child: AbsorbPointer(
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _yearController,
                        decoration: const InputDecoration(
                          labelText: '년',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _monthController,
                        decoration: const InputDecoration(
                          labelText: '월',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _dayController,
                        decoration: const InputDecoration(
                          labelText: '일',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _showGenderPicker(context),
              child: AbsorbPointer(
                child: TextFormField(
                  controller: _genderController,
                  decoration: const InputDecoration(
                    labelText: '성별',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                ),
              ),
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
