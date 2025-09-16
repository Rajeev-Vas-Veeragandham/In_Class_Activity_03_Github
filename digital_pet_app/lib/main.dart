import 'package:flutter/material.dart';

void main() => runApp(const DigitalPetApp());

class DigitalPetApp extends StatefulWidget {
  const DigitalPetApp({super.key});

  @override
  State<DigitalPetApp> createState() => _DigitalPetAppState();
}

class _DigitalPetAppState extends State<DigitalPetApp> {
  int happiness = 50;
  int energy = 50;

  void feedPet() {
    setState(() {
      energy = (energy + 15).clamp(0, 100);
      happiness = (happiness + 5).clamp(0, 100);
    });
  }

  void playWithPet() {
    setState(() {
      happiness = (happiness + 15).clamp(0, 100);
      energy = (energy - 10).clamp(0, 100);
    });
  }

  void restPet() {
    setState(() {
      energy = (energy + 20).clamp(0, 100);
      happiness = (happiness - 5).clamp(0, 100);
    });
  }

  /// Mood text
  String getPetMood() {
    final states = [
      {'ok': happiness > 70 && energy > 50, 'msg': "Happy & Energetic 😊"},
      {'ok': happiness < 40, 'msg': "Feeling Sad 😟"},
      {'ok': energy < 30, 'msg': "Tired 😴"},
    ];

    return states.firstWhere(
      (s) => s['ok'] as bool,
      orElse: () => {'msg': "Doing Okay 🙂"},
    )['msg'] as String;
  }

  /// Avatar changes by mood
  String getPetAvatar() {
    if (happiness > 70 && energy > 50) return "images/pet_happy.jpg";
    if (happiness < 40) return "images/pet_sad.jpg";
    if (energy < 30) return "images/pet_tired.jpg";
    return "images/pet_ok.jpg";
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Digital Pet",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.pink.shade50,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ),
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("My Digital Pet 🐾"),
            backgroundColor: Colors.teal,
            bottom: const TabBar(
              tabs: [
                Tab(child: Text("Feed 🦴", style: TextStyle(fontSize: 18))),
                Tab(child: Text("Play ⚽", style: TextStyle(fontSize: 18))),
                Tab(child: Text("Rest 😴", style: TextStyle(fontSize: 18))),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              actionTab("Give food to recover energy 🦴", "Feed Now", feedPet),
              actionTab("Playtime makes your pet happy ⚽", "Play Ball", playWithPet),
              actionTab("Rest to restore strength 😴", "Sleep", restPet),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pet avatar (mood image)
                SizedBox(
                  height: 160,
                  child: Image.asset(getPetAvatar(), fit: BoxFit.contain),
                ),
                const SizedBox(height: 10),
                Text(
                  getPetMood(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                buildStatusBar("Happiness", happiness),
                const SizedBox(height: 10),
                buildStatusBar("Energy", energy),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Action tab with description and button
  Widget actionTab(String text, String btnLabel, VoidCallback onTap) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
            ),
            onPressed: onTap,
            child: Text(btnLabel, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  /// Emoji selector
  String getEmoji(String type, int score) {
    final emojiLookup = {
      "Happiness": score >= 50 ? "😊" : "😟",
      "Energy": score >= 50 ? "⚡" : "😴",
    };
    return emojiLookup[type] ?? "🐾";
  }

  /// Gradient selector
  List<Color> getGradient(String type) {
    final colorSets = {
      "Happiness": [Colors.pinkAccent, Colors.orangeAccent],
      "Energy": [Colors.lightBlueAccent, Colors.greenAccent],
    };
    return colorSets[type] ?? [Colors.grey, Colors.blueGrey];
  }

  /// Animated progress bar with gradient + emoji
  Widget buildStatusBar(String title, int score) {
    final emoji = getEmoji(title, score);
    final colors = getGradient(title);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 22,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 500),
                tween: Tween(begin: 0, end: score.toDouble()),
                builder: (context, value, _) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: value / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(colors: colors),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: score < 50 ? 0 : null,
              right: score >= 50 ? 0 : null,
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          "$title: $score%",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colors.first,
          ),
        ),
      ],
    );
  }
}
