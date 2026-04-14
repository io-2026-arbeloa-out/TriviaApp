import 'package:flutter/material.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/widgets/bottom_nav_bar.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final UIOptions options = UIOptions();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              options.mainColor,
              options.secondaryColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Nagłówek
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      color: options.textColor,
                    ),
                    Text(
                      'Profil',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: options.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 48), // żeby wyrównać z przyciskiem wstecz
                  ],
                ),
                const SizedBox(height: 24),

                // Avatar + nazwa
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor:
                        options.secondaryButtonColor.withOpacity(0.2),
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: options.textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nazwa użytkownika',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          color: options.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ranga: Newbie',
                        style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: options.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Statystyki
                Text(
                  'Statystyki',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: options.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatCard(context, 'Odpowiedziane pytania', '0'),
                const SizedBox(height: 8),
                _buildStatCard(context, 'Poprawne odpowiedzi', '0'),
                const SizedBox(height: 8),
                _buildStatCard(context, 'Skuteczność', '0%'),
                const SizedBox(height: 8),
                _buildStatCard(context, 'Gry rankingowe', '0'),
                const SizedBox(height: 8),
                _buildStatCard(context, 'Wygrane gry rankingowe', '0'),
                const SizedBox(height: 24),

                // Osiągnięcia
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: options.mainButtonColor,
                    foregroundColor: options.textColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // TODO: przejście do AchievementScreen
                  },
                  child: const Text(
                    'Zobacz osiągnięcia',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 2),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: options.secondaryColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: options.textColor,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: options.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}