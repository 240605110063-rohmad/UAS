class Weather {
  final String cityName;
  final double temperature;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;

  /// Koordinat lokasi dari blok `coord` (bisa null untuk data uji).
  final double? latitude;
  final double? longitude;

  const Weather({
    required this.cityName,
    required this.temperature,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    this.latitude,
    this.longitude,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    final weather = json['weather'][0];
    final main = json['main'];
    final wind = json['wind'];
    final coord = json['coord'];
    return Weather(
      cityName: json['name'] as String,
      temperature: (main['temp'] as num).toDouble(),
      description: weather['description'] as String,
      icon: weather['icon'] as String,
      humidity: (main['humidity'] as num).toInt(),
      windSpeed: (wind['speed'] as num).toDouble(),
      latitude: coord is Map ? (coord['lat'] as num?)?.toDouble() : null,
      longitude: coord is Map ? (coord['lon'] as num?)?.toDouble() : null,
    );
  }
}
