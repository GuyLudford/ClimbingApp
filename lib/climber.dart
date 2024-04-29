class Climber {
  final String climberId;
  final Map<String, dynamic> routes;

  Climber({required this.climberId, required this.routes});

  factory Climber.fromJson(Map<String, dynamic> json) {
    return Climber(
      climberId: json.keys.first,
      routes: json[json.keys.first]['routes'],
    );
  }
}
