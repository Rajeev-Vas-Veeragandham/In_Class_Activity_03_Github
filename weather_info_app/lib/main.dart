import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(WeatherWithOpenMeteoApp());

class WeatherWithOpenMeteoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Open-Meteo Weather",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  @override
  _WeatherHomePageState createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController cityController = TextEditingController();

  bool isLoading = false;
  bool hasData = false;
  bool showFahrenheit = false; // toggle flag

  String? cityName;
  double? currentTemp;
  String currentCondition = "";

  List<DailyForecast> dailyForecast = [];

  // Map Open-Meteo weather codes to human-friendly strings + emoji
  String weatherCodeToCondition(int code) {
    if (code == 0) return "☀ Clear";
    if (code == 1 || code == 2) return "⛅ Partly Cloudy";
    if (code == 3) return "☁ Overcast";
    if (code >= 45 && code <= 48) return "🌫 Fog";
    if (code == 51 || code == 53 || code == 55) return "🌦 Drizzle";
    if (code >= 56 && code <= 57) return "🧊 Freezing Drizzle";
    if (code >= 61 && code <= 67) return "🌧 Rain";
    if (code >= 71 && code <= 77) return "❄ Snow";
    if (code >= 80 && code <= 82) return "🌧 Showers";
    if (code >= 85 && code <= 86) return "❄ Snow Showers";
    if (code >= 95) return "⛈ Thunderstorm";
    return "❓ Unknown";
  }

  // Celsius to Fahrenheit
  double cToF(double c) => (c * 9 / 5) + 32;

  Future<Map<String, double>?> geocodeCity(String city) async {
    try {
      final url = Uri.parse(
        "https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(city)}&count=1",
      );
      final resp = await http.get(url);
      if (resp.statusCode != 200) return null;
      final data = json.decode(resp.body);
      if (data == null || data['results'] == null) return null;
      final results = data['results'] as List<dynamic>;
      if (results.isEmpty) return null;
      final first = results[0];
      return {
        "lat": (first['latitude'] as num).toDouble(),
        "lon": (first['longitude'] as num).toDouble(),
      };
    } catch (_) {
      return null;
    }
  }

  Future<bool> fetchWeather(double lat, double lon) async {
    try {
      final url = Uri.parse(
        "https://api.open-meteo.com/v1/forecast"
        "?latitude=$lat&longitude=$lon"
        "&current_weather=true"
        "&daily=weathercode,temperature_2m_max,temperature_2m_min"
        "&timezone=auto",
      );
      final resp = await http.get(url);
      if (resp.statusCode != 200) return false;

      final data = json.decode(resp.body);
      if (data == null) return false;

      final cw = data['current_weather'];
      if (cw != null) {
        currentTemp = (cw['temperature'] as num).toDouble();
        final int code = (cw['weathercode'] as num).toInt();
        currentCondition = weatherCodeToCondition(code);
      }

      dailyForecast.clear();
      final daily = data['daily'];
      if (daily != null) {
        final times = List<String>.from(daily['time'] ?? []);
        final tMax = List<num>.from(daily['temperature_2m_max'] ?? []);
        final tMin = List<num>.from(daily['temperature_2m_min'] ?? []);
        final codes = List<num>.from(daily['weathercode'] ?? []);

        for (int i = 0; i < times.length; i++) {
          dailyForecast.add(
            DailyForecast(
              date: times[i],
              tempMax: (i < tMax.length) ? tMax[i].toDouble() : double.nan,
              tempMin: (i < tMin.length) ? tMin[i].toDouble() : double.nan,
              condition: (i < codes.length)
                  ? weatherCodeToCondition(codes[i].toInt())
                  : "Unknown",
            ),
          );
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  void handleGetForecast() async {
    final city = cityController.text.trim();
    if (city.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please enter a city name.")));
      return;
    }

    setState(() {
      isLoading = true;
      hasData = false;
    });

    final loc = await geocodeCity(city);
    if (loc == null) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("City not found. Try a different name.")),
      );
      return;
    }

    final success = await fetchWeather(loc['lat']!, loc['lon']!);
    setState(() {
      isLoading = false;
      hasData = success;
      if (success) cityName = city;
    });

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch weather. Try again.")),
      );
    }
  }

  Widget buildTodayTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade100, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: cityController,
            decoration: InputDecoration(
              labelText: "Enter City Name",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.location_city),
            ),
            onSubmitted: (_) => handleGetForecast(),
          ),
          SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: isLoading ? null : handleGetForecast,
            icon: Icon(Icons.cloud),
            label: Text("Get Forecast"),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Center(
              child: isLoading
                  ? CircularProgressIndicator()
                  : !hasData
                  ? Text("No data yet. Enter a city and press Get Forecast.")
                  : AnimatedSwitcher(
                      duration: Duration(milliseconds: 600),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Column(
                        key: ValueKey(cityName),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            cityName ?? "",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade800,
                            ),
                          ),
                          SizedBox(height: 10),
                          AnimatedDefaultTextStyle(
                            duration: Duration(milliseconds: 500),
                            style: TextStyle(
                              fontSize: 50, // bigger emoji + text
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            child: Text(currentCondition),
                          ),
                          SizedBox(height: 20),
                          if (currentTemp != null)
                            Column(
                              children: [
                                AnimatedSwitcher(
                                  duration: Duration(milliseconds: 500),
                                  transitionBuilder: (child, anim) =>
                                      FadeTransition(
                                        opacity: anim,
                                        child: child,
                                      ),
                                  child: Text(
                                    showFahrenheit
                                        ? "${cToF(currentTemp!).toStringAsFixed(1)} °F"
                                        : "${currentTemp!.toStringAsFixed(1)} °C",
                                    key: ValueKey(showFahrenheit),
                                    style: TextStyle(
                                      fontSize: 55,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade900,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("°C"),
                                    Switch(
                                      value: showFahrenheit,
                                      onChanged: (val) =>
                                          setState(() => showFahrenheit = val),
                                    ),
                                    Text("°F"),
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildWeeklyTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.indigo.shade50],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: EdgeInsets.all(16),
      child: isLoading
          ? Center(child: CircularProgressIndicator())
          : (!hasData || dailyForecast.isEmpty)
          ? Center(child: Text("No forecast yet. Use Today tab to fetch data."))
          : ListView.builder(
              itemCount: dailyForecast.length,
              itemBuilder: (context, index) {
                final d = dailyForecast[index];
                final max = showFahrenheit ? cToF(d.tempMax) : d.tempMax;
                final min = showFahrenheit ? cToF(d.tempMin) : d.tempMin;

                return AnimatedContainer(
                  duration: Duration(milliseconds: 400),
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    child: ListTile(
                      leading: Text(
                        d.condition.split(" ")[0], // emoji
                        style: TextStyle(fontSize: 36), // bigger symbol
                      ),
                      title: Text(
                        d.date,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        d.condition.split(" ").skip(1).join(" "),
                        style: TextStyle(fontSize: 16),
                      ),
                      trailing: Text(
                        "${max.isNaN ? '-' : max.toStringAsFixed(1)}° / ${min.isNaN ? '-' : min.toStringAsFixed(1)}°"
                        "${showFahrenheit ? 'F' : 'C'}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("🌤 Weather"),
          bottom: TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.today), text: "Today"),
              Tab(icon: Icon(Icons.calendar_view_week), text: "7-Day"),
            ],
          ),
        ),
        body: TabBarView(children: [buildTodayTab(), buildWeeklyTab()]),
      ),
    );
  }
}

class DailyForecast {
  final String date;
  final double tempMax;
  final double tempMin;
  final String condition;

  DailyForecast({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.condition,
  });
}
