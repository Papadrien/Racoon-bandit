import 'dart:convert';

class AchievementProgress {
  final String id;
  final int progress;
  const AchievementProgress({required this.id, this.progress = 0});

  Map<String,dynamic> toJson()=>{'id':id,'progress':progress};
}

class GlobalStats {
  int gamesPlayed;
  int gamesWon;
  int totalFoodGained;
  int totalFoodStolen;
  int totalCardsPlayed;
  int totalBanditCardsPlayed;
  int totalRaccoonCardsPlayed;
  List<AchievementProgress> achievements;

  GlobalStats({
    this.gamesPlayed=0,
    this.gamesWon=0,
    this.totalFoodGained=0,
    this.totalFoodStolen=0,
    this.totalCardsPlayed=0,
    this.totalBanditCardsPlayed=0,
    this.totalRaccoonCardsPlayed=0,
    this.achievements=const [],
  });

  Map<String,dynamic> toJson()=>{
    'gamesPlayed':gamesPlayed,
    'gamesWon':gamesWon,
    'totalFoodGained':totalFoodGained,
    'totalFoodStolen':totalFoodStolen,
    'totalCardsPlayed':totalCardsPlayed,
    'totalBanditCardsPlayed':totalBanditCardsPlayed,
    'totalRaccoonCardsPlayed':totalRaccoonCardsPlayed,
    'achievements':achievements.map((e)=>e.toJson()).toList(),
  };

  
  factory GlobalStats.fromJson(Map<String, dynamic> json) => GlobalStats(
        gamesPlayed: (json['gamesPlayed'] as num?)?.toInt() ?? 0,
        gamesWon: (json['gamesWon'] as num?)?.toInt() ?? 0,
        totalFoodGained: (json['totalFoodGained'] as num?)?.toInt() ?? 0,
        totalFoodStolen: (json['totalFoodStolen'] as num?)?.toInt() ?? 0,
        totalCardsPlayed: (json['totalCardsPlayed'] as num?)?.toInt() ?? 0,
        totalBanditCardsPlayed: (json['totalBanditCardsPlayed'] as num?)?.toInt() ?? 0,
        totalRaccoonCardsPlayed: (json['totalRaccoonCardsPlayed'] as num?)?.toInt() ?? 0,
        achievements: (json['achievements'] as List<dynamic>?)
                ?.map((e) => AchievementProgress(
                      id: (e as Map<String, dynamic>)['id'] as String,
                      progress: ((e)['progress'] as num?)?.toInt() ?? 0,
                    ))
                .toList() ??
            [],
      );


  String toJsonString()=>jsonEncode(toJson());
  factory GlobalStats.fromJsonString(String raw)=>GlobalStats.fromJson(jsonDecode(raw));
}
