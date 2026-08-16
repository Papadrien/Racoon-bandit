import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'life_system_service.dart';

/// Service centralisé des achats intégrés — pack Premium (achat unique,
/// non consommable).
///
/// Le pack Premium débloque :
///  - la suppression des publicités récompensées obligatoires,
///  - des parties illimitées (plus de restriction ni d'attente entre
///    deux parties, voir [LifeSystemService.setUnlimitedLives]),
///  - tous les dos de cartes (voir ProgressionService.unlockedCardBackIds).
///
/// L'état "Premium" est mis en cache localement (SharedPreferences) pour
/// rester disponible hors-ligne, et est confirmé/synchronisé par le flux
/// d'achats de la plateforme (Play Store) à chaque démarrage.
class PurchaseService {
  PurchaseService._();

  static final PurchaseService instance = PurchaseService._();

  /// Identifiant produit configuré dans Play Console (achat unique).
  static const String premiumProductId = 'raccoon_bandit_premium';

  static const _prefsKey = 'is_premium_v1';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  ProductDetails? _premiumProduct;
  ProductDetails? get premiumProduct => _premiumProduct;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  /// Notifier écouté par l'UI (bouton Premium, encart vies, etc.) pour se
  /// reconstruire immédiatement dès qu'un achat est confirmé ou restauré.
  final ValueNotifier<bool> premiumNotifier = ValueNotifier<bool>(false);

  bool _isBuying = false;
  bool get isBuying => _isBuying;

  bool _isRestoring = false;
  bool get isRestoring => _isRestoring;

  /// À appeler une fois au démarrage (depuis le splash screen), après le
  /// chargement des autres services de progression.
  Future<void> initialize() async {
    await _loadCachedStatus();

    try {
      _isAvailable = await _iap.isAvailable();
    } catch (e) {
      _isAvailable = false;
      if (kDebugMode) debugPrint('[Purchase] isAvailable a échoué: $e');
    }

    if (!_isAvailable) return;

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (Object e) {
        if (kDebugMode) debugPrint('[Purchase] Erreur flux achats: $e');
      },
    );

    await _loadProducts();
  }

  Future<void> _loadCachedStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool(_prefsKey) ?? false;
    } catch (e) {
      if (kDebugMode) debugPrint('[Purchase] Erreur lecture cache: $e');
    }
    premiumNotifier.value = _isPremium;
    if (_isPremium) {
      unawaited(LifeSystemService.instance.setUnlimitedLives(true));
    }
  }

  Future<void> _loadProducts() async {
    try {
      final response = await _iap.queryProductDetails({premiumProductId});
      if (response.error != null && kDebugMode) {
        debugPrint('[Purchase] Erreur requête produits: ${response.error}');
      }
      if (response.notFoundIDs.isNotEmpty && kDebugMode) {
        debugPrint('[Purchase] IDs introuvables: ${response.notFoundIDs}');
      }
      if (response.productDetails.isNotEmpty) {
        _premiumProduct = response.productDetails.first;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Purchase] Erreur chargement produits: $e');
    }
  }

  /// Lance le flux d'achat Premium. Le résultat (succès/échec) arrive de
  /// façon asynchrone via [purchaseStream] et met à jour [isPremium].
  /// Retourne `false` immédiatement si l'achat n'a pas pu être initié.
  Future<bool> buyPremium() async {
    if (_isPremium || _isBuying) return false;

    if (!_isAvailable) {
      try {
        _isAvailable = await _iap.isAvailable();
      } catch (_) {
        _isAvailable = false;
      }
    }
    if (!_isAvailable) return false;

    var product = _premiumProduct;
    if (product == null) {
      await _loadProducts();
      product = _premiumProduct;
    }
    if (product == null) return false;

    _isBuying = true;
    try {
      final param = PurchaseParam(productDetails: product);
      return await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      if (kDebugMode) debugPrint('[Purchase] Erreur achat: $e');
      return false;
    } finally {
      _isBuying = false;
    }
  }

  /// Relance la restauration des achats précédents (obligatoire sur iOS,
  /// utile sur Android en cas de réinstallation / changement d'appareil).
  Future<void> restorePurchases() async {
    if (_isRestoring) return;
    if (!_isAvailable) {
      try {
        _isAvailable = await _iap.isAvailable();
      } catch (_) {
        _isAvailable = false;
      }
    }
    if (!_isAvailable) return;

    _isRestoring = true;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      if (kDebugMode) debugPrint('[Purchase] Erreur restauration: $e');
    } finally {
      _isRestoring = false;
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.productID == premiumProductId) {
        switch (purchase.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            unawaited(_grantPremium());
            break;
          case PurchaseStatus.error:
            if (kDebugMode) {
              debugPrint('[Purchase] Erreur achat: ${purchase.error}');
            }
            break;
          case PurchaseStatus.pending:
          case PurchaseStatus.canceled:
            break;
        }
      }

      if (purchase.pendingCompletePurchase) {
        unawaited(_iap.completePurchase(purchase));
      }
    }
  }

  Future<void> _grantPremium() async {
    _isPremium = true;
    premiumNotifier.value = true;
    await LifeSystemService.instance.setUnlimitedLives(true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, true);
    } catch (e) {
      if (kDebugMode) debugPrint('[Purchase] Erreur sauvegarde cache: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
