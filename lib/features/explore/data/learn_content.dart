import 'package:flutter/material.dart';
import 'package:palette/core/theme/palette_colours.dart';

/// Static educational content for the Explore > Learn section.
class LearnArticle {
  const LearnArticle({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String body;
}

const learnArticles = <LearnArticle>[
  LearnArticle(
    icon: Icons.palette_outlined,
    iconColor: PaletteColours.sageGreenDark,
    iconBg: PaletteColours.sageGreenLight,
    title: 'Why undertones matter',
    subtitle: 'The hidden colour beneath the surface',
    body:
        'Every paint colour has an undertone — a subtle base of warm, cool, '
        'or neutral that you might not notice on a swatch card but becomes '
        'obvious on a full wall. A "grey" can lean blue, green, or purple '
        'depending on its undertone.\n\n'
        'This is why two colours that look perfect together in the shop can '
        'clash at home. If your warm-toned sofa sits against a cool-toned '
        "grey wall, something will feel off even if you can't pinpoint why.\n\n"
        'The simplest test: hold a pure white sheet of paper next to your '
        'paint swatch. The undertone will reveal itself by contrast.',
  ),
  LearnArticle(
    icon: Icons.wb_sunny_outlined,
    iconColor: PaletteColours.softGoldDark,
    iconBg: PaletteColours.softGoldLight,
    title: 'How light changes colour',
    subtitle: 'Direction and time of day transform your room',
    body:
        'A north-facing room gets cool, indirect light that pushes colours '
        'towards blue. The same paint in a south-facing room will look '
        'warmer and more saturated because of the direct sunlight.\n\n'
        'East-facing rooms get warm morning light but cool afternoon shadow, '
        'while west-facing rooms do the opposite — cool mornings, golden '
        'evenings. This means your room changes character throughout the day.\n\n'
        'Always test paint samples on the wall for at least 24 hours, '
        'checking at different times. The colour you see at 10am under '
        "a north-facing window is very different from what you'll see at 6pm.",
  ),
  LearnArticle(
    icon: Icons.pie_chart_outline,
    iconColor: PaletteColours.accessibleBlueDark,
    iconBg: PaletteColours.accessibleBlueLight,
    title: 'The 70/20/10 rule',
    subtitle: 'A simple formula for balanced rooms',
    body:
        '70% of your room is the dominant colour — usually walls and large '
        'surfaces. This sets the mood and should be a colour you can live '
        'with every day.\n\n'
        '20% is your secondary colour — think curtains, rugs, upholstery, '
        'or an accent wall. This adds depth without overwhelming.\n\n'
        '10% is your surprise — cushions, artwork, vases, or a statement '
        "chair. This is where you can be bold and playful, and it's the "
        'easiest to change when you fancy a refresh.',
  ),
  LearnArticle(
    icon: Icons.linear_scale,
    iconColor: Color(0xFF8B3A3A),
    iconBg: Color(0xFFF0E0E0),
    title: 'What is a Red Thread?',
    subtitle: 'The colour that ties your whole home together',
    body:
        'In Scandinavian design, the "red thread" is a unifying element '
        'that runs through a whole space. In colour planning, it means '
        'choosing one or two colours that appear — even subtly — in every '
        'room.\n\n'
        "This doesn't mean every room looks the same. A warm terracotta "
        'thread might be the hero wall in your living room, a cushion in '
        'the bedroom, and a vase in the hallway. The repetition creates '
        'flow as you move through your home.\n\n'
        "Start by identifying the colour you're most drawn to across "
        'rooms, then look for ways to echo it in each space.',
  ),
  LearnArticle(
    icon: Icons.format_paint_outlined,
    iconColor: PaletteColours.textSecondary,
    iconBg: PaletteColours.warmGrey,
    title: 'Choosing the right white',
    subtitle: 'Not all whites are equal',
    body:
        "White paint is the most-bought and most-returned colour. That's "
        'because "white" is really dozens of colours — some lean pink, '
        'some lean yellow, some lean blue.\n\n'
        "Sowerby's Paper Test: hold a sheet of plain white printer paper "
        'against the wall next to your white paint sample. The paper acts '
        "as a true-white reference, making the paint's undertone jump out. "
        "You'll immediately see whether it's warm, cool, or neutral.\n\n"
        'As a rule of thumb, warm whites suit south-facing rooms and '
        'traditional homes, cool whites work in north-facing rooms and '
        'modern spaces, and neutral whites are the safest all-rounders.',
  ),
];
