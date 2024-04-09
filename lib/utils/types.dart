class OwnPosition {
  final double latitude;
  final double longitude;
  final double speed;
  final double heading;

  OwnPosition({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.heading,
  });
}

enum Tail { withoutTail, tail30min, tailToday }
