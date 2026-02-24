import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ExploreCard(
            icon: Icons.color_lens_outlined,
            title: 'Colour Wheel',
            subtitle: 'Explore colour relationships',
            onTap: () => context.go('/explore/wheel'),
          ),
          const SizedBox(height: 12),
          _ExploreCard(
            icon: Icons.format_paint_outlined,
            title: 'White Finder',
            subtitle: 'Find the right white for your room',
            onTap: () => context.go('/explore/white-finder'),
          ),
          const SizedBox(height: 12),
          _ExploreCard(
            icon: Icons.library_books_outlined,
            title: 'Paint Library',
            subtitle: 'Browse colours from UK paint brands',
            onTap: () => context.go('/explore/paint-library'),
          ),
        ],
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
    );
  }
}
