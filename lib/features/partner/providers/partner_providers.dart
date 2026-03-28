import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/features/palette/providers/palette_providers.dart';
import 'package:palette/features/partner/logic/partner_comparison.dart';
import 'package:palette/providers/database_providers.dart';

/// Watch the current partner profile.
final partnerProfileProvider = StreamProvider<PartnerProfile?>((ref) {
  final repo = ref.watch(partnerRepositoryProvider);
  return repo.watchPartner();
});

/// Compute partner comparison when both DNAs are available.
final partnerComparisonProvider = Provider<PartnerComparison?>((ref) {
  final partnerAsync = ref.watch(partnerProfileProvider);
  final dnaAsync = ref.watch(latestColourDnaProvider);

  final partner = partnerAsync.valueOrNull;
  final dna = dnaAsync.valueOrNull;

  if (partner == null || !partner.hasCompletedQuiz || dna == null) {
    return null;
  }

  return comparePartnerDna(userDna: dna, partner: partner);
});
