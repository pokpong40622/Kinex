import 'package:flutter/material.dart';

/// The 5 gentle topics the whole deck is organized into.
enum TopicId { selfCare, home, movement, medicine, companionship }

/// Which mascot / pictogram to paint. Backed by hand-drawn [CustomPainter]s,
/// not image assets, so the whole art style stays crisp at any size.
enum MascotType { teacup, house, sun, glassesPill, heartHands, buddy }

enum PictogramType {
  bed,
  shoes,
  waterGlass,
  foodPlate,
  bathroomMat,
  stairsHandrail,
  rugCord,
  nightLight,
  taichi,
  stretching,
  balanceChair,
  calendarRoutine,
  pillDoctor,
  glasses,
  glassesClean,
  pillSchedule,
  cane,
  familyTalk,
  phoneEmergency,
  friendsCommunity,
}

enum GameMode { multipleChoice, trueFalse, matching }

class Topic {
  final TopicId id;
  final String title;
  final String subtitle;
  final Color color;
  final MascotType mascot;

  const Topic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.mascot,
  });
}

class McQuestion {
  final TopicId topic;
  final PictogramType illustration;
  final String question;
  final List<String> options; // exactly 4, A..D order
  final int correctIndex;

  const McQuestion({
    required this.topic,
    required this.illustration,
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

class TfQuestion {
  final TopicId topic;
  final PictogramType illustration;
  final String statement;
  final bool correctAnswer;

  const TfQuestion({
    required this.topic,
    required this.illustration,
    required this.statement,
    required this.correctAnswer,
  });
}

class MatchPair {
  final TopicId topic;
  final PictogramType situationIllustration;
  final String situation;
  final PictogramType tipIllustration;
  final String tip;

  const MatchPair({
    required this.topic,
    required this.situationIllustration,
    required this.situation,
    required this.tipIllustration,
    required this.tip,
  });
}
