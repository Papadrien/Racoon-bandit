import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_profile.dart';

/// Service centralisé de gestion des profils joueurs.
/// Initialiser avec [load()] au démarrage avant [runApp].
class PlayerProfilesService {
  PlayerProfilesService._();

  static const _keyProfiles = 'player_profiles_v1';
  static const _keyInitialized = 'player_profiles_initialized';

  static List<PlayerProfile> _profiles = [];

  /// Profils non-modifiables.
  static List<PlayerProfile> get profiles => List.unmodifiable(_profiles);

  /// Profils triés par date de création.
  static List<PlayerProfile> get sortedProfiles {
    final list = List<PlayerProfile>.from(_profiles);
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  // ── Init ────────────────────────────────────────────────────────────────

  /// À appeler dans main(), avant runApp.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final initialized = prefs.getBool(_keyInitialized) ?? false;
      if (!initialized) {
        await _createDefaults(prefs);
        return;
      }
      final raw = prefs.getStringList(_keyProfiles) ?? [];
      _profiles = raw.map(PlayerProfile.fromJsonString).toList();
    } catch (_) {
      _profiles = [];
    }
  }

  static Future<void> _createDefaults(SharedPreferences prefs) async {
    final now = DateTime.now();
    _profiles = [
      PlayerProfile(
        id: _genId(now, 0),
        name: 'Dad',
        emoji: '🦝',
        colorValue: const Color(0xFF7C4DFF).toARGB32(),
        createdAt: now,
      ),
      PlayerProfile(
        id: _genId(now, 1),
        name: 'Mom',
        emoji: '🐼',
        colorValue: const Color(0xFF00BCD4).toARGB32(),
        createdAt: now.add(const Duration(milliseconds: 1)),
      ),
      PlayerProfile(
        id: _genId(now, 2),
        name: 'Brother',
        emoji: '🦊',
        colorValue: const Color(0xFFFF6D00).toARGB32(),
        createdAt: now.add(const Duration(milliseconds: 2)),
      ),
      PlayerProfile(
        id: _genId(now, 3),
        name: 'Sister',
        emoji: '🐸',
        colorValue: const Color(0xFF4CAF50).toARGB32(),
        createdAt: now.add(const Duration(milliseconds: 3)),
      ),
    ];
    await _persist(prefs);
    await prefs.setBool(_keyInitialized, true);
  }

  // ── CRUD ────────────────────────────────────────────────────────────────

  static Future<void> createProfile(PlayerProfile profile) async {
    _profiles.add(profile);
    await _save();
  }

  static Future<void> updateProfile(PlayerProfile profile) async {
    final idx = _profiles.indexWhere((p) => p.id == profile.id);
    if (idx >= 0) {
      _profiles[idx] = profile;
      await _save();
    }
  }

  static Future<void> deleteProfile(String id) async {
    _profiles.removeWhere((p) => p.id == id);
    await _save();
  }

  /// Retourne un [PlayerProfile] vide prêt à être édité.
  static PlayerProfile newProfile() => PlayerProfile(
        id: _genId(DateTime.now(), 0),
        name: '',
        emoji: '🦝',
        colorValue: const Color(0xFF7C4DFF).toARGB32(),
        createdAt: DateTime.now(),
      );

  // ── Helpers ─────────────────────────────────────────────────────────────

  static String _genId(DateTime base, int offset) =>
      (base.microsecondsSinceEpoch + offset).toString();

  static Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _persist(prefs);
    } catch (_) {}
  }

  static Future<void> _persist(SharedPreferences prefs) async {
    await prefs.setStringList(
      _keyProfiles,
      _profiles.map((p) => p.toJsonString()).toList(),
    );
  }
}
