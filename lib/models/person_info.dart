/// Person being assessed. Age + gender drive test parameters (e.g. arm-curl
/// weight) and appear on the record form; BP/pulse are optional intake fields
/// from the manual's record sheet (page 24).
enum Gender {
  male,
  female;

  String get thaiLabel => this == Gender.male ? 'ชาย' : 'หญิง';
  String get token => name;
  static Gender fromToken(String t) =>
      Gender.values.firstWhere((g) => g.name == t);
}

class PersonInfo {
  final String? name;
  final int age;
  final Gender gender;
  final int? systolic; // ความดันตัวบน
  final int? diastolic; // ความดันตัวล่าง
  final int? pulse; // ชีพจร (ครั้ง/นาที)

  const PersonInfo({
    this.name,
    required this.age,
    required this.gender,
    this.systolic,
    this.diastolic,
    this.pulse,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'gender': gender.token,
        'systolic': systolic,
        'diastolic': diastolic,
        'pulse': pulse,
      };

  factory PersonInfo.fromJson(Map<String, dynamic> j) => PersonInfo(
        name: j['name'] as String?,
        age: j['age'] as int,
        gender: Gender.fromToken(j['gender'] as String),
        systolic: j['systolic'] as int?,
        diastolic: j['diastolic'] as int?,
        pulse: j['pulse'] as int?,
      );
}
