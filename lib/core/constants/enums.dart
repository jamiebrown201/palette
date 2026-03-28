/// All app-wide enumerations for the Palette application.
library;

import 'package:flutter/material.dart';

enum SubscriptionTier { free, plus, pro, projectPass }

extension SubscriptionTierX on SubscriptionTier {
  String get displayName => switch (this) {
    SubscriptionTier.free => 'Free',
    SubscriptionTier.plus => 'Palette Plus',
    SubscriptionTier.pro => 'Palette Pro',
    SubscriptionTier.projectPass => 'Project Pass',
  };

  bool operator >=(SubscriptionTier other) => index >= other.index;
}

enum PremiumFeature {
  paletteEditing,
  lightRecommendations,
  seventyTwentyTenPlanner,
  redThread,
  unlimitedMoodboards,
  colourCaptureToPalette,
  exportPdf,
  partnerMode,
}

extension PremiumFeatureX on PremiumFeature {
  SubscriptionTier get requiredTier => switch (this) {
    PremiumFeature.paletteEditing => SubscriptionTier.plus,
    PremiumFeature.lightRecommendations => SubscriptionTier.plus,
    PremiumFeature.seventyTwentyTenPlanner => SubscriptionTier.plus,
    PremiumFeature.redThread => SubscriptionTier.plus,
    PremiumFeature.unlimitedMoodboards => SubscriptionTier.plus,
    PremiumFeature.colourCaptureToPalette => SubscriptionTier.plus,
    PremiumFeature.exportPdf => SubscriptionTier.plus,
    PremiumFeature.partnerMode => SubscriptionTier.pro,
  };
}

enum PaletteFamily {
  pastels,
  brights,
  jewelTones,
  earthTones,
  darks,
  warmNeutrals,
  coolNeutrals,
}

extension PaletteFamilyX on PaletteFamily {
  String get displayName => switch (this) {
    PaletteFamily.pastels => 'Pastels',
    PaletteFamily.brights => 'Brights',
    PaletteFamily.jewelTones => 'Jewel Tones',
    PaletteFamily.earthTones => 'Earth Tones',
    PaletteFamily.darks => 'Darks',
    PaletteFamily.warmNeutrals => 'Warm Neutrals',
    PaletteFamily.coolNeutrals => 'Cool Neutrals',
  };

  String get description => switch (this) {
    PaletteFamily.pastels =>
      'Soft, light colours that bring calm and airiness to a space',
    PaletteFamily.brights =>
      'Vivid, saturated colours that energise and uplift',
    PaletteFamily.jewelTones =>
      'Rich, deep colours inspired by precious gemstones',
    PaletteFamily.earthTones => 'Warm, grounded colours drawn from nature',
    PaletteFamily.darks =>
      'Bold, dramatic colours that create intimacy and depth',
    PaletteFamily.warmNeutrals =>
      'Understated warm tones that create a cosy foundation',
    PaletteFamily.coolNeutrals =>
      'Understated cool tones that create a serene foundation',
  };
}

enum DnaConfidence { low, medium, high }

extension DnaConfidenceX on DnaConfidence {
  String get displayName => switch (this) {
    DnaConfidence.low => 'Eclectic',
    DnaConfidence.medium => 'Balanced',
    DnaConfidence.high => 'Clear',
  };
}

enum ColourArchetype {
  theCocooner,
  theGoldenHour,
  theCurator,
  theMonochromeModernist,
  theRomantic,
  theColourOptimist,
  theNatureLover,
  theStoryteller,
  theVelvetWhisper,
  theMaximalist,
  theBrightener,
  theDramatist,
  theMidnightArchitect,
  theMinimalist,
}

extension ColourArchetypeX on ColourArchetype {
  String get displayName => switch (this) {
    ColourArchetype.theCocooner => 'The Cocooner',
    ColourArchetype.theGoldenHour => 'The Golden Hour',
    ColourArchetype.theCurator => 'The Curator',
    ColourArchetype.theMonochromeModernist => 'The Monochrome Modernist',
    ColourArchetype.theRomantic => 'The Romantic',
    ColourArchetype.theColourOptimist => 'The Colour Optimist',
    ColourArchetype.theNatureLover => 'The Nature Lover',
    ColourArchetype.theStoryteller => 'The Storyteller',
    ColourArchetype.theVelvetWhisper => 'The Velvet Whisper',
    ColourArchetype.theMaximalist => 'The Maximalist',
    ColourArchetype.theBrightener => 'The Brightener',
    ColourArchetype.theDramatist => 'The Dramatist',
    ColourArchetype.theMidnightArchitect => 'The Midnight Architect',
    ColourArchetype.theMinimalist => 'The Minimalist',
  };
}

enum Undertone { warm, cool, neutral }

extension UndertoneX on Undertone {
  String get displayName => switch (this) {
    Undertone.warm => 'Warm',
    Undertone.cool => 'Cool',
    Undertone.neutral => 'Neutral',
  };

  String get badge => switch (this) {
    Undertone.warm => 'W',
    Undertone.cool => 'C',
    Undertone.neutral => 'N',
  };
}

enum ChromaBand { muted, mid, bold }

extension ChromaBandX on ChromaBand {
  String get displayName => switch (this) {
    ChromaBand.muted => 'Muted',
    ChromaBand.mid => 'Mid',
    ChromaBand.bold => 'Bold',
  };
}

enum CompassDirection { north, south, east, west }

extension CompassDirectionX on CompassDirection {
  String get displayName => switch (this) {
    CompassDirection.north => 'North',
    CompassDirection.south => 'South',
    CompassDirection.east => 'East',
    CompassDirection.west => 'West',
  };

  String get abbreviation => switch (this) {
    CompassDirection.north => 'N',
    CompassDirection.south => 'S',
    CompassDirection.east => 'E',
    CompassDirection.west => 'W',
  };
}

enum UsageTime { morning, afternoon, evening, allDay }

extension UsageTimeX on UsageTime {
  String get displayName => switch (this) {
    UsageTime.morning => 'Morning',
    UsageTime.afternoon => 'Afternoon',
    UsageTime.evening => 'Evening',
    UsageTime.allDay => 'All day',
  };
}

enum RoomMood {
  calm,
  energising,
  cocooning,
  elegant,
  fresh,
  grounded,
  dramatic,
  playful,
}

extension RoomMoodX on RoomMood {
  String get displayName => switch (this) {
    RoomMood.calm => 'Calm',
    RoomMood.energising => 'Energising',
    RoomMood.cocooning => 'Cocooning',
    RoomMood.elegant => 'Elegant',
    RoomMood.fresh => 'Fresh',
    RoomMood.grounded => 'Grounded',
    RoomMood.dramatic => 'Dramatic',
    RoomMood.playful => 'Playful',
  };
}

enum BudgetBracket { affordable, midRange, investment }

extension BudgetBracketX on BudgetBracket {
  String get displayName => switch (this) {
    BudgetBracket.affordable => 'Affordable',
    BudgetBracket.midRange => 'Mid-range',
    BudgetBracket.investment => 'Investment',
  };
}

enum RoomSize { small, medium, large }

extension RoomSizeX on RoomSize {
  String get displayName => switch (this) {
    RoomSize.small => 'Small',
    RoomSize.medium => 'Medium',
    RoomSize.large => 'Large',
  };

  String get description => switch (this) {
    RoomSize.small => 'Up to 10 m² (e.g. box room, small bathroom)',
    RoomSize.medium => 'About 10–20 m² (e.g. typical bedroom, kitchen)',
    RoomSize.large => '20 m²+ (e.g. open-plan living, large lounge)',
  };

  /// Recommended rug sizes for this room bracket.
  List<RugSize> get recommendedRugSizes => switch (this) {
    RoomSize.small => [RugSize.small120x170],
    RoomSize.medium => [RugSize.medium160x230, RugSize.large200x290],
    RoomSize.large => [RugSize.large200x290, RugSize.extraLarge240x340],
  };
}

enum PropertyType { flat, terraced, semiDetached, detached, other }

extension PropertyTypeX on PropertyType {
  String get displayName => switch (this) {
    PropertyType.flat => 'Flat',
    PropertyType.terraced => 'Terraced',
    PropertyType.semiDetached => 'Semi-detached',
    PropertyType.detached => 'Detached',
    PropertyType.other => 'Other',
  };
}

enum PropertyEra {
  victorian,
  edwardian,
  thirtiesToFifties,
  postWar,
  modern,
  newBuild,
  notSure,
}

extension PropertyEraX on PropertyEra {
  String get displayName => switch (this) {
    PropertyEra.victorian => 'Victorian',
    PropertyEra.edwardian => 'Edwardian',
    PropertyEra.thirtiesToFifties => '1930s-50s',
    PropertyEra.postWar => 'Post-war',
    PropertyEra.modern => 'Modern',
    PropertyEra.newBuild => 'New build',
    PropertyEra.notSure => 'Not sure',
  };
}

enum ProjectStage {
  justBought,
  planning,
  midProject,
  finishingTouches,
  justCurious,
}

extension ProjectStageX on ProjectStage {
  String get displayName => switch (this) {
    ProjectStage.justBought => 'Just bought',
    ProjectStage.planning => 'Planning',
    ProjectStage.midProject => 'Mid-project',
    ProjectStage.finishingTouches => 'Finishing touches',
    ProjectStage.justCurious => 'Just curious',
  };
}

enum Tenure { owner, renter }

extension TenureX on Tenure {
  String get displayName => switch (this) {
    Tenure.owner => 'Owner',
    Tenure.renter => 'Renter',
  };
}

enum FurnitureRole { hero, beta, surprise }

extension FurnitureRoleX on FurnitureRole {
  String get displayName => switch (this) {
    FurnitureRole.hero => 'Hero (70%)',
    FurnitureRole.beta => 'Beta (20%)',
    FurnitureRole.surprise => 'Surprise (10%)',
  };
}

enum FurnitureCategory {
  sofa,
  bed,
  table,
  rug,
  chair,
  shelving,
  lighting,
  storage,
  other,
}

extension FurnitureCategoryX on FurnitureCategory {
  String get displayName => switch (this) {
    FurnitureCategory.sofa => 'Sofa',
    FurnitureCategory.bed => 'Bed',
    FurnitureCategory.table => 'Table',
    FurnitureCategory.rug => 'Rug',
    FurnitureCategory.chair => 'Chair',
    FurnitureCategory.shelving => 'Shelving',
    FurnitureCategory.lighting => 'Lighting',
    FurnitureCategory.storage => 'Storage',
    FurnitureCategory.other => 'Other',
  };

  IconData get icon => switch (this) {
    FurnitureCategory.sofa => Icons.weekend,
    FurnitureCategory.bed => Icons.bed,
    FurnitureCategory.table => Icons.table_restaurant,
    FurnitureCategory.rug => Icons.texture,
    FurnitureCategory.chair => Icons.chair,
    FurnitureCategory.shelving => Icons.shelves,
    FurnitureCategory.lighting => Icons.light,
    FurnitureCategory.storage => Icons.inventory_2,
    FurnitureCategory.other => Icons.category,
  };
}

enum FurnitureStatus { keeping, mightReplace, replacing, dontHaveYet }

extension FurnitureStatusX on FurnitureStatus {
  String get displayName => switch (this) {
    FurnitureStatus.keeping => 'Keeping',
    FurnitureStatus.mightReplace => 'Might replace',
    FurnitureStatus.replacing => 'Replacing',
    FurnitureStatus.dontHaveYet => "I don't have this yet",
  };
}

enum FurnitureMaterial {
  wood,
  metal,
  fabric,
  leather,
  glass,
  stone,
  wickerRattan,
  plastic,
}

extension FurnitureMaterialX on FurnitureMaterial {
  String get displayName => switch (this) {
    FurnitureMaterial.wood => 'Wood',
    FurnitureMaterial.metal => 'Metal',
    FurnitureMaterial.fabric => 'Fabric',
    FurnitureMaterial.leather => 'Leather',
    FurnitureMaterial.glass => 'Glass',
    FurnitureMaterial.stone => 'Stone',
    FurnitureMaterial.wickerRattan => 'Wicker / Rattan',
    FurnitureMaterial.plastic => 'Plastic',
  };
}

enum WoodTone {
  lightOak,
  honeyOak,
  walnut,
  darkStain,
  whitePainted,
  reclaimed,
  teak,
  ash,
}

extension WoodToneX on WoodTone {
  String get displayName => switch (this) {
    WoodTone.lightOak => 'Light oak',
    WoodTone.honeyOak => 'Honey oak',
    WoodTone.walnut => 'Walnut',
    WoodTone.darkStain => 'Dark stain',
    WoodTone.whitePainted => 'White painted',
    WoodTone.reclaimed => 'Reclaimed',
    WoodTone.teak => 'Teak',
    WoodTone.ash => 'Ash',
  };

  Undertone get undertone => switch (this) {
    WoodTone.lightOak => Undertone.neutral,
    WoodTone.honeyOak => Undertone.warm,
    WoodTone.walnut => Undertone.warm,
    WoodTone.darkStain => Undertone.warm,
    WoodTone.whitePainted => Undertone.cool,
    WoodTone.reclaimed => Undertone.warm,
    WoodTone.teak => Undertone.warm,
    WoodTone.ash => Undertone.cool,
  };
}

enum MetalFinish {
  antiqueBrass,
  brushedGold,
  polishedBrass,
  roseGold,
  chrome,
  brushedNickel,
  matteBlack,
  copper,
  darkBronze,
}

extension MetalFinishX on MetalFinish {
  String get displayName => switch (this) {
    MetalFinish.antiqueBrass => 'Antique brass',
    MetalFinish.brushedGold => 'Brushed gold',
    MetalFinish.polishedBrass => 'Polished brass',
    MetalFinish.roseGold => 'Rose gold',
    MetalFinish.chrome => 'Chrome',
    MetalFinish.brushedNickel => 'Brushed nickel',
    MetalFinish.matteBlack => 'Matte black',
    MetalFinish.copper => 'Copper',
    MetalFinish.darkBronze => 'Dark bronze',
  };

  Undertone get undertone => switch (this) {
    MetalFinish.antiqueBrass => Undertone.warm,
    MetalFinish.brushedGold => Undertone.warm,
    MetalFinish.polishedBrass => Undertone.warm,
    MetalFinish.roseGold => Undertone.warm,
    MetalFinish.chrome => Undertone.cool,
    MetalFinish.brushedNickel => Undertone.cool,
    MetalFinish.matteBlack => Undertone.neutral,
    MetalFinish.copper => Undertone.warm,
    MetalFinish.darkBronze => Undertone.warm,
  };
}

enum FurnitureStyle { modern, traditional, eclectic }

extension FurnitureStyleX on FurnitureStyle {
  String get displayName => switch (this) {
    FurnitureStyle.modern => 'Modern',
    FurnitureStyle.traditional => 'Traditional',
    FurnitureStyle.eclectic => 'Eclectic',
  };
}

enum TextureFeel { smooth, lowTexture, highTexture, chunky }

extension TextureFeelX on TextureFeel {
  String get displayName => switch (this) {
    TextureFeel.smooth => 'Smooth',
    TextureFeel.lowTexture => 'Low texture',
    TextureFeel.highTexture => 'High texture',
    TextureFeel.chunky => 'Chunky',
  };
}

enum VisualWeight { light, medium, heavy }

extension VisualWeightX on VisualWeight {
  String get displayName => switch (this) {
    VisualWeight.light => 'Light',
    VisualWeight.medium => 'Medium',
    VisualWeight.heavy => 'Heavy',
  };
}

enum FinishSheen { matte, lowSheen, polished }

extension FinishSheenX on FinishSheen {
  String get displayName => switch (this) {
    FinishSheen.matte => 'Matte',
    FinishSheen.lowSheen => 'Low sheen',
    FinishSheen.polished => 'Polished',
  };
}

enum ColourRelationship {
  complementary,
  analogous,
  triadic,
  splitComplementary,
}

extension ColourRelationshipX on ColourRelationship {
  String get displayName => switch (this) {
    ColourRelationship.complementary => 'Complementary',
    ColourRelationship.analogous => 'Analogous',
    ColourRelationship.triadic => 'Triadic',
    ColourRelationship.splitComplementary => 'Split-complementary',
  };

  String get description => switch (this) {
    ColourRelationship.complementary =>
      'Colours that sit opposite each other, creating vibrant contrast',
    ColourRelationship.analogous =>
      'Neighbouring colours that create a harmonious, cohesive feel',
    ColourRelationship.triadic =>
      'Three evenly spaced colours for a balanced, vibrant palette',
    ColourRelationship.splitComplementary =>
      'A colour paired with the two colours next to its complement',
  };
}

enum WhiteUndertone { blue, pink, yellow, grey }

extension WhiteUndertoneX on WhiteUndertone {
  String get displayName => switch (this) {
    WhiteUndertone.blue => 'Blue undertone',
    WhiteUndertone.pink => 'Pink undertone',
    WhiteUndertone.yellow => 'Yellow undertone',
    WhiteUndertone.grey => 'Grey undertone',
  };
}

// ---------------------------------------------------------------------------
// Product catalogue enums (Phase 2A.3)
// ---------------------------------------------------------------------------

enum ProductCategory {
  rug,
  pendantLight,
  floorLamp,
  tableLamp,
  cushion,
  throwBlanket,
  curtain,
  artwork,
  mirror,
  plugInPendant,
  wallDecor,
}

extension ProductCategoryX on ProductCategory {
  String get displayName => switch (this) {
    ProductCategory.rug => 'Rug',
    ProductCategory.pendantLight => 'Pendant light',
    ProductCategory.floorLamp => 'Floor lamp',
    ProductCategory.tableLamp => 'Table lamp',
    ProductCategory.cushion => 'Cushion',
    ProductCategory.throwBlanket => 'Throw',
    ProductCategory.curtain => 'Curtain',
    ProductCategory.artwork => 'Artwork',
    ProductCategory.mirror => 'Mirror',
    ProductCategory.plugInPendant => 'Plug-in pendant',
    ProductCategory.wallDecor => 'Wall decor',
  };

  IconData get icon => switch (this) {
    ProductCategory.rug => Icons.texture,
    ProductCategory.pendantLight => Icons.light,
    ProductCategory.floorLamp => Icons.lightbulb_outline,
    ProductCategory.tableLamp => Icons.desk_outlined,
    ProductCategory.cushion => Icons.weekend,
    ProductCategory.throwBlanket => Icons.dry_cleaning,
    ProductCategory.curtain => Icons.curtains,
    ProductCategory.artwork => Icons.image_outlined,
    ProductCategory.mirror => Icons.flip,
    ProductCategory.plugInPendant => Icons.power,
    ProductCategory.wallDecor => Icons.wallpaper,
  };

  /// Maps to the lighting sub-category if applicable.
  LightingSubcategory? get lightingSubcategory => switch (this) {
    ProductCategory.pendantLight => LightingSubcategory.ambient,
    ProductCategory.floorLamp => LightingSubcategory.task,
    ProductCategory.tableLamp => LightingSubcategory.accent,
    _ => null,
  };
}

enum LightingSubcategory { ambient, task, accent }

extension LightingSubcategoryX on LightingSubcategory {
  String get displayName => switch (this) {
    LightingSubcategory.ambient => 'Ambient',
    LightingSubcategory.task => 'Task',
    LightingSubcategory.accent => 'Accent',
  };
}

enum ProductStyle {
  modern,
  traditional,
  scandi,
  midCentury,
  industrial,
  bohemian,
  minimalist,
}

extension ProductStyleX on ProductStyle {
  String get displayName => switch (this) {
    ProductStyle.modern => 'Modern',
    ProductStyle.traditional => 'Traditional',
    ProductStyle.scandi => 'Scandi',
    ProductStyle.midCentury => 'Mid-century',
    ProductStyle.industrial => 'Industrial',
    ProductStyle.bohemian => 'Bohemian',
    ProductStyle.minimalist => 'Minimalist',
  };
}

enum ProductMaterial {
  woodOak,
  woodWalnut,
  woodAsh,
  woodTeak,
  woodBirch,
  woodPine,
  woodReclaimed,
  metalBrass,
  metalAntiqueBrass,
  metalBrushedGold,
  metalChrome,
  metalBrushedNickel,
  metalMatteBlack,
  metalCopper,
  metalBronze,
  fabricLinen,
  fabricVelvet,
  fabricBoucle,
  fabricCotton,
  fabricSilk,
  fabricWool,
  fabricJute,
  leather,
  glass,
  ceramic,
  rattan,
  stone,
}

extension ProductMaterialX on ProductMaterial {
  String get displayName => switch (this) {
    ProductMaterial.woodOak => 'Oak',
    ProductMaterial.woodWalnut => 'Walnut',
    ProductMaterial.woodAsh => 'Ash',
    ProductMaterial.woodTeak => 'Teak',
    ProductMaterial.woodBirch => 'Birch',
    ProductMaterial.woodPine => 'Pine',
    ProductMaterial.woodReclaimed => 'Reclaimed wood',
    ProductMaterial.metalBrass => 'Brass',
    ProductMaterial.metalAntiqueBrass => 'Antique brass',
    ProductMaterial.metalBrushedGold => 'Brushed gold',
    ProductMaterial.metalChrome => 'Chrome',
    ProductMaterial.metalBrushedNickel => 'Brushed nickel',
    ProductMaterial.metalMatteBlack => 'Matte black',
    ProductMaterial.metalCopper => 'Copper',
    ProductMaterial.metalBronze => 'Bronze',
    ProductMaterial.fabricLinen => 'Linen',
    ProductMaterial.fabricVelvet => 'Velvet',
    ProductMaterial.fabricBoucle => 'Bouclé',
    ProductMaterial.fabricCotton => 'Cotton',
    ProductMaterial.fabricSilk => 'Silk',
    ProductMaterial.fabricWool => 'Wool',
    ProductMaterial.fabricJute => 'Jute',
    ProductMaterial.leather => 'Leather',
    ProductMaterial.glass => 'Glass',
    ProductMaterial.ceramic => 'Ceramic',
    ProductMaterial.rattan => 'Rattan',
    ProductMaterial.stone => 'Stone',
  };

  bool get isWood => name.startsWith('wood');
  bool get isMetal => name.startsWith('metal');

  WoodTone? get asWoodTone => switch (this) {
    ProductMaterial.woodOak => WoodTone.lightOak,
    ProductMaterial.woodWalnut => WoodTone.walnut,
    ProductMaterial.woodAsh => WoodTone.ash,
    ProductMaterial.woodTeak => WoodTone.teak,
    ProductMaterial.woodBirch => WoodTone.lightOak,
    ProductMaterial.woodPine => WoodTone.lightOak,
    ProductMaterial.woodReclaimed => WoodTone.reclaimed,
    _ => null,
  };

  MetalFinish? get asMetalFinish => switch (this) {
    ProductMaterial.metalBrass => MetalFinish.polishedBrass,
    ProductMaterial.metalAntiqueBrass => MetalFinish.antiqueBrass,
    ProductMaterial.metalBrushedGold => MetalFinish.brushedGold,
    ProductMaterial.metalChrome => MetalFinish.chrome,
    ProductMaterial.metalBrushedNickel => MetalFinish.brushedNickel,
    ProductMaterial.metalMatteBlack => MetalFinish.matteBlack,
    ProductMaterial.metalCopper => MetalFinish.copper,
    ProductMaterial.metalBronze => MetalFinish.darkBronze,
    _ => null,
  };

  Undertone get undertone {
    if (isWood) return asWoodTone?.undertone ?? Undertone.neutral;
    if (isMetal) return asMetalFinish?.undertone ?? Undertone.neutral;
    return switch (this) {
      ProductMaterial.fabricLinen => Undertone.warm,
      ProductMaterial.fabricVelvet => Undertone.warm,
      ProductMaterial.fabricBoucle => Undertone.warm,
      ProductMaterial.fabricCotton => Undertone.neutral,
      ProductMaterial.fabricSilk => Undertone.cool,
      ProductMaterial.fabricWool => Undertone.warm,
      ProductMaterial.fabricJute => Undertone.warm,
      ProductMaterial.leather => Undertone.warm,
      ProductMaterial.glass => Undertone.cool,
      ProductMaterial.ceramic => Undertone.neutral,
      ProductMaterial.rattan => Undertone.warm,
      ProductMaterial.stone => Undertone.cool,
      _ => Undertone.neutral,
    };
  }
}

enum RugSize { small120x170, medium160x230, large200x290, extraLarge240x340 }

extension RugSizeX on RugSize {
  String get displayName => switch (this) {
    RugSize.small120x170 => '120 × 170 cm',
    RugSize.medium160x230 => '160 × 230 cm',
    RugSize.large200x290 => '200 × 290 cm',
    RugSize.extraLarge240x340 => '240 × 340 cm',
  };
}

enum PriceTier { affordable, midRange, investment }

extension PriceTierX on PriceTier {
  String get displayName => switch (this) {
    PriceTier.affordable => '£',
    PriceTier.midRange => '££',
    PriceTier.investment => '£££',
  };

  BudgetBracket get asBudgetBracket => switch (this) {
    PriceTier.affordable => BudgetBracket.affordable,
    PriceTier.midRange => BudgetBracket.midRange,
    PriceTier.investment => BudgetBracket.investment,
  };
}
