import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pet_trail/config/app_config.dart';
import 'package:pet_trail/data/services/profile_api_service.dart';
import 'package:pet_trail/data/services/tour_api_service.dart';
import 'package:pet_trail/data/services/walker_api_service.dart';
import 'package:pet_trail/domain/models/nearby_walker.dart';
import 'package:pet_trail/domain/models/pet.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pet_trail/utils/geo_utils.dart';
import 'package:pet_trail/utils/mapbox_walk_path_snap.dart';
import 'package:pet_trail/presentation/controllers/chat_controller.dart';
import 'package:pet_trail/screens/chat_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.identifier,
    required this.name,
    required this.email,
    required this.role,
    required this.accessToken,
  });

  final String identifier;
  final String name;
  final String email;
  final String role;
  final String accessToken;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  final _profileService = ProfileApiService();
  final _walkerApiService = WalkerApiService();
  final _walkersRef = FirebaseDatabase.instance.ref('walker_locations');

  bool? _available;
  bool _loadingAvailability = false;
  Timer? _locationTimer;
  LatLng? _walkerCurrentPosition;
  StreamSubscription<DatabaseEvent>? _pendingTourSubscription;
  bool _pendingTourDialogShowing = false;
  Position? _tutorPosition;
  List<NearbyWalker> _nearbyWalkers = [];
  StreamSubscription<DatabaseEvent>? _walkersSubscription;
  StreamSubscription<DatabaseEvent>? _ownLocationSubscription;
  StreamSubscription<DatabaseEvent>? _tourResponseSubscription;
  bool _tourResponseDialogShowing = false;
  bool _waitingTourResponse = false;
  bool _activeTour = false;
  String? _activeTourPartnerName;
  String? _activeTourPetName;
  Uint8List? _activeTourPetPhotoBytes;
  String? _activeTourConfirmationCode;
  String? _activeTourId;
  ChatController? _chatController;
  bool _walkerTourStarted = false;
  LatLng? _partnerPosition;
  Uint8List? _walkerIconBytes;
  Uint8List? _tutorIconBytes;
  StreamSubscription<DatabaseEvent>? _activeTourSubscription;
  StreamSubscription<DatabaseEvent>? _partnerLocationSubscription;
  StreamSubscription<DatabaseEvent>? _walkPathSubscription;
  StreamSubscription<DatabaseEvent>? _finishRequestSubscription;
  bool _finishTourDialogShowing = false;
  final ValueNotifier<bool> _dismissTerminationDialog = ValueNotifier(false);
  Timer? _activeTourTimer;
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;
  double _walkDistanceMeters = 0;
  Set<Polyline> _routePolylines = {};
  List<LatLng> _walkPathPoints = [];
  String? _distanceText;
  String? _etaText;
  bool _retryingNearbyWalkers = false;
  int _lastPushedWalkPathIndex = -1;
  DateTime? _lastRouteEtaUpdateAt;
  LatLng? _lastRouteEtaPartnerPos;
  Timer? _walkTrailSnapTimer;
  int _walkTrailSnapScheduleId = 0;

  static const double _nearbyRadiusKm = 5.0;
  static const String _mapsApiKey = 'AIzaSyDgVA4WH04-RrXfqDcI7Gkbj7i2_ImjXLQ';

  bool get _isWalker => widget.role == 'walker';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestLocationPermissionThenInit();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshActiveTourState());
    }
  }

  Future<void> _requestLocationPermissionThenInit() async {
    final iconResults = await Future.wait([
      rootBundle.load('assets/images/locIconP.png'),
      rootBundle.load('assets/images/locIconT.png'),
    ]);
    if (mounted) {
      setState(() {
        _walkerIconBytes = iconResults[0].buffer.asUint8List();
        _tutorIconBytes = iconResults[1].buffer.asUint8List();
      });
    }
    await _ensureLocationPermission();
    if (_isWalker) {
      _fetchAvailability();
    } else {
      _initTutorMap();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatController?.removeListener(_onChatControllerUpdate);
    _chatController?.dispose();
    _chatController = null;
    _locationTimer?.cancel();
    _walkersSubscription?.cancel();
    _ownLocationSubscription?.cancel();
    _pendingTourSubscription?.cancel();
    _tourResponseSubscription?.cancel();
    _activeTourSubscription?.cancel();
    _partnerLocationSubscription?.cancel();
    _walkPathSubscription?.cancel();
    _finishRequestSubscription?.cancel();
    _dismissTerminationDialog.dispose();
    _activeTourTimer?.cancel();
    _elapsedTimer?.cancel();
    _walkTrailSnapTimer?.cancel();
    super.dispose();
  }

  void _invalidateWalkTrailSnap() {
    _walkTrailSnapTimer?.cancel();
    _walkTrailSnapTimer = null;
    _walkTrailSnapScheduleId++;
  }

  void _scheduleWalkTrailSnap() {
    if (!AppConfig.hasMapboxAccessToken) return;
    if (_walkPathPoints.length < 2) return;
    _walkTrailSnapTimer?.cancel();
    final id = ++_walkTrailSnapScheduleId;
    _walkTrailSnapTimer = Timer(const Duration(milliseconds: 900), () async {
      final pts = List<LatLng>.from(_walkPathPoints);
      if (pts.length < 2) return;
      final snapped = await fetchMapboxWalkingMatchedPath(
        rawPoints: pts,
        mapboxAccessToken: AppConfig.mapboxAccessToken,
      );
      if (!mounted || id != _walkTrailSnapScheduleId) return;
      setState(() {
        _routePolylines = _buildTrailPolyline(
          snapped != null && snapped.length >= 2 ? snapped : pts,
        );
      });
    });
  }

  Future<void> _sendReview({
    required String tourId,
    required int rating,
  }) async {
    try {
      await TourApiService().sendReview(
        accessToken: widget.accessToken,
        tourIdentifier: tourId,
        rating: rating,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avaliação enviada com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao enviar avaliação: $e')));
    }
  }

  Future<void> _showReviewDialog(String tourId) async {
    int rating = 0;

    final result = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: const Text('Avaliar passeio'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Como foi sua experiência com o passeador?',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        onPressed: () {
                          setStateDialog(() => rating = starValue);
                        },
                        icon: Icon(
                          Icons.star_rounded,
                          size: 34,
                          color: starValue <= rating
                              ? Colors.amber
                              : Colors.grey.shade400,
                        ),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: rating == 0 ? null : () => Navigator.of(ctx).pop(rating),
                  child: const Text('Enviar avaliação'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    await _sendReview(tourId: tourId, rating: result);
  }

  Future<void> _fetchAvailability() async {
    try {
      final profile = await _profileService.fetchWalkerProfile(
        identifier: widget.identifier,
        accessToken: widget.accessToken,
      );
      if (!mounted) return;
      final available = profile.available ?? false;
      setState(() {
        _available = available;
      });
      if (available) _startLocationUpdates();
    } catch (_) {
      if (!mounted) return;
      setState(() => _available = false);
    }
    _startPendingTourListener();
    await _tryRestoreActiveTour();
    if (!_activeTour && _isWalker) {
      await _tryRestoreWalkerActiveTourFromApi();
    }
  }

  Future<void> _tryRestoreWalkerActiveTourFromApi() async {
    try {
      final tours = await TourApiService().fetchMyTours(
        accessToken: widget.accessToken,
      );
      if (!mounted || _activeTour) return;

      final active = tours.where((tour) {
        final status = tour.status.toUpperCase();
        return status == 'IN_PROGRESS' || status == 'WALKER_ON_THE_WAY';
      }).toList();
      if (active.isEmpty) return;

      final selected = active.first;
      await _syncActiveTourToFirebase(selected.identifier);
      await _startWalkerActiveTour(
        selected.identifier,
        selected.tutorName?.isNotEmpty == true ? selected.tutorName! : 'Tutor',
        apiStatus: selected.status,
        startedAt: selected.startedAt,
      );
    } catch (_) {}
  }

  Future<void> _tryRestoreTutorActiveTourFromApi() async {
    try {
      final tours = await TourApiService().fetchMyTours(
        accessToken: widget.accessToken,
      );
      if (!mounted || _activeTour) return;

      final active = tours.where((tour) {
        final status = tour.status.toUpperCase();
        return status == 'IN_PROGRESS' || status == 'WALKER_ON_THE_WAY';
      }).toList();
      if (active.isEmpty) return;

      final selected = active.first;
      await _syncActiveTourToFirebase(selected.identifier);
      if (!mounted || _activeTour) return;
      _startTutorActiveTour(
        selected.identifier,
        selected.walkerName?.isNotEmpty == true
            ? selected.walkerName!
            : 'Passeador',
        apiStatus: selected.status,
        startedAt: selected.startedAt,
      );
    } catch (_) {}
  }

  Future<void> _refreshActiveTourState() async {
    if (!mounted) return;

    if (_activeTour && _activeTourId != null) {
      await _syncActiveTourToFirebase(_activeTourId!);
      return;
    }

    await _tryRestoreActiveTour();
    if (!mounted || _activeTour) return;

    if (_isWalker) {
      await _tryRestoreWalkerActiveTourFromApi();
    } else {
      await _tryRestoreTutorActiveTourFromApi();
    }
  }

  Future<void> _syncActiveTourToFirebase(String tourId) async {
    try {
      await TourApiService().syncActiveTour(
        accessToken: widget.accessToken,
        tourIdentifier: tourId,
      );
    } catch (_) {}
  }

  Future<void> _handleActiveTourFirebaseAbsent(String tourId) async {
    if (!mounted || _activeTourId != tourId) return;

    try {
      final tour = await TourApiService().fetchTourById(
        accessToken: widget.accessToken,
        identifier: tourId,
      );
      if (!mounted || _activeTourId != tourId) return;

      final status = tour.status.toUpperCase();
      if (status == 'FINISHED' || status == 'REFUSED') {
        if (_activeTour) {
          _endTour(
            summary: {
              'started_at': tour.startedAt?.toIso8601String(),
              'finished_at': tour.finishedAt?.toIso8601String(),
              'total_time_seconds': tour.totalTimeSeconds,
              'distance_meters': tour.distanceMeters,
            },
          );
        }
        return;
      }

      if (status == 'WALKER_ON_THE_WAY' || status == 'IN_PROGRESS') {
        await _syncActiveTourToFirebase(tourId);
        if (!mounted || _activeTourId != tourId) return;

        if (status == 'IN_PROGRESS' && !_walkerTourStarted) {
          _applyInProgressTourState(startedAt: tour.startedAt);
          if (_isWalker) {
            _startLocationUpdates(intervalSeconds: 10);
          }
          _listenWalkPath(tourId);
        }
        return;
      }
    } catch (_) {}

    if (_walkerTourStarted) {
      _fetchTourSummaryAndEnd();
    }
  }

  void _applyInProgressTourState({DateTime? startedAt}) {
    setState(() {
      _walkerTourStarted = true;
      _activeTourConfirmationCode = null;
      _routePolylines = {};
      _distanceText = null;
      _etaText = null;
      _walkPathPoints = _walkerCurrentPosition != null
          ? [_walkerCurrentPosition!]
          : [];
      _walkDistanceMeters = 0;
    });
    _invalidateWalkTrailSnap();
    _lastPushedWalkPathIndex = -1;
    _activeTourTimer?.cancel();
    _activeTourTimer = null;
    _startElapsedTimer(startedAt: startedAt);
  }

  Future<void> _ensureWalkerPositionForActiveTour() async {
    if (_walkerCurrentPosition != null) return;
    try {
      final ok = await _ensureLocationPermission();
      if (!ok) return;
      final gpsPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      setState(
        () => _walkerCurrentPosition = LatLng(gpsPos.latitude, gpsPos.longitude),
      );
    } catch (_) {}
  }

  void _onChatControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _startTutorActiveTour(
    String tourId,
    String walkerName, {
    String? apiStatus,
    DateTime? startedAt,
  }) {
    final inProgress = apiStatus?.toUpperCase() == 'IN_PROGRESS';
    setState(() {
      _activeTour = true;
      _activeTourPartnerName = walkerName;
      _activeTourPetName = null;
      _activeTourPetPhotoBytes = null;
      _activeTourId = tourId;
      _walkerTourStarted = inProgress;
      _nearbyWalkers = [];
    });
    _chatController?.dispose();
    _chatController = ChatController(
      chatBaseUrl: AppConfig.chatBaseUrl,
      token: widget.accessToken,
      tourId: tourId,
      currentUserId: widget.identifier,
    );
    _chatController!.addListener(_onChatControllerUpdate);

    if (inProgress) {
      _applyInProgressTourState(startedAt: startedAt);
    }

    _startFinishRequestListener();
    _fetchAndLoadPetInfo(tourId);

    _sendTutorLocation();
    _activeTourTimer?.cancel();
    _activeTourTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendTutorLocation();
      if (_partnerPosition != null && _tutorPosition != null) {
        _updateDistanceEta(
          LatLng(_tutorPosition!.latitude, _tutorPosition!.longitude),
          _partnerPosition!,
        );
      }
    });

    _activeTourSubscription?.cancel();
    _activeTourSubscription = FirebaseDatabase.instance
        .ref('active_tours/$tourId')
        .onValue
        .listen((event) {
          if (!mounted) return;
          final data = event.snapshot.value;
          if (data == null) {
            unawaited(_handleActiveTourFirebaseAbsent(tourId));
            return;
          }
          final map = Map<String, dynamic>.from(data as Map);
          final walkerId = map['walker_id']?.toString();
          if (walkerId == null) return;

          final status = map['status']?.toString();
          if (status == 'IN_PROGRESS' && !_walkerTourStarted) {
            final startedAtStr = map['started_at']?.toString();
            final startedAt = startedAtStr != null
                ? DateTime.tryParse(startedAtStr)
                : null;
            _applyInProgressTourState(startedAt: startedAt);
            _listenWalkPath(tourId);
          }

          _listenPartnerLocation('walker_locations/$walkerId');
        });
  }

  Future<void> _sendTutorLocation() async {
    if (_tutorPosition == null) return;
    try {
      await FirebaseDatabase.instance
          .ref('tutor_locations/${widget.identifier}')
          .update({
            'latitude': _tutorPosition!.latitude,
            'longitude': _tutorPosition!.longitude,
          });
    } catch (_) {}
  }

  Future<void> _startWalkerActiveTour(
    String tourId,
    String tutorName, {
    String? apiStatus,
    DateTime? startedAt,
  }) async {
    final inProgress = apiStatus?.toUpperCase() == 'IN_PROGRESS';
    setState(() {
      _activeTour = true;
      _activeTourPartnerName = tutorName;
      _activeTourPetName = null;
      _activeTourPetPhotoBytes = null;
      _activeTourId = tourId;
      _walkerTourStarted = inProgress;
    });
    _chatController?.dispose();
    _chatController = ChatController(
      chatBaseUrl: AppConfig.chatBaseUrl,
      token: widget.accessToken,
      tourId: tourId,
      currentUserId: widget.identifier,
    );
    _chatController!.addListener(_onChatControllerUpdate);
    _lastPushedWalkPathIndex = -1;

    _fetchAndLoadPetInfo(tourId);
    await _ensureWalkerPositionForActiveTour();

    if (inProgress) {
      _applyInProgressTourState(startedAt: startedAt);
      _startLocationUpdates(intervalSeconds: 10);
      _listenWalkPath(tourId);
    } else {
      _startLocationUpdates();
    }

    try {
      final walkerPos = _walkerCurrentPosition;
      if (walkerPos == null) return;

      final tourSnap = await FirebaseDatabase.instance
          .ref('active_tours/$tourId')
          .get();
      if (tourSnap.exists && mounted) {
        final tourData = Map<String, dynamic>.from(tourSnap.value as Map);
        final status = tourData['status']?.toString();
        if (status == 'IN_PROGRESS' && !_walkerTourStarted) {
          final startedAtStr = tourData['started_at']?.toString();
          final firebaseStartedAt = startedAtStr != null
              ? DateTime.tryParse(startedAtStr)
              : null;
          _applyInProgressTourState(startedAt: firebaseStartedAt ?? startedAt);
          _startLocationUpdates(intervalSeconds: 10);
          _listenWalkPath(tourId);
        }

        final tutorId = tourData['tutor_id']?.toString();
        if (tutorId != null) {
          final locSnap = await FirebaseDatabase.instance
              .ref('tutor_locations/$tutorId')
              .get();
          if (locSnap.exists && mounted) {
            final loc = Map<String, dynamic>.from(locSnap.value as Map);
            final lat = (loc['latitude'] as num?)?.toDouble();
            final lng = (loc['longitude'] as num?)?.toDouble();
            if (lat != null && lng != null) {
              await _updateDistanceEta(walkerPos, LatLng(lat, lng));
            }
          }
          if (!_walkerTourStarted) {
            _listenPartnerLocation('tutor_locations/$tutorId');
          }
        }
      }
    } catch (_) {}

    // Listen to active_tours/{tourId} → get tutor_id for ongoing updates
    _activeTourSubscription?.cancel();
    _activeTourSubscription = FirebaseDatabase.instance
        .ref('active_tours/$tourId')
        .onValue
        .listen((event) {
          if (!mounted) return;
          final data = event.snapshot.value;
          if (data == null) {
            unawaited(_handleActiveTourFirebaseAbsent(tourId));
            return;
          }
          final map = Map<String, dynamic>.from(data as Map);
          final tutorId = map['tutor_id']?.toString();
          if (tutorId == null) return;

          final status = map['status']?.toString();
          if (status == 'IN_PROGRESS' && !_walkerTourStarted) {
            final startedAtStr = map['started_at']?.toString();
            final firebaseStartedAt = startedAtStr != null
                ? DateTime.tryParse(startedAtStr)
                : null;
            _applyInProgressTourState(startedAt: firebaseStartedAt ?? startedAt);
            _startLocationUpdates(intervalSeconds: 10);
            _listenWalkPath(tourId);
          }

          _listenPartnerLocation('tutor_locations/$tutorId');
        });

    // Distance Matrix timer using walker's current position
    _activeTourTimer?.cancel();
    _activeTourTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_walkerCurrentPosition != null && _partnerPosition != null) {
        _updateDistanceEta(_walkerCurrentPosition!, _partnerPosition!);
      }
    });
  }

  void _listenPartnerLocation(String firebasePath) {
    _partnerLocationSubscription?.cancel();
    _partnerLocationSubscription = FirebaseDatabase.instance
        .ref(firebasePath)
        .onValue
        .listen((event) async {
          if (!mounted) return;
          final data = event.snapshot.value;
          if (data == null) return;
          final map = Map<String, dynamic>.from(data as Map);
          final lat = (map['latitude'] as num?)?.toDouble();
          final lng = (map['longitude'] as num?)?.toDouble();
          if (lat == null || lng == null) return;
          final partnerPos = LatLng(lat, lng);
          final currentPartner = _partnerPosition;
          final shouldUpdateMarker =
              currentPartner == null ||
              Geolocator.distanceBetween(
                    currentPartner.latitude,
                    currentPartner.longitude,
                    partnerPos.latitude,
                    partnerPos.longitude,
                  ) >
                  2;
          if (shouldUpdateMarker) {
            setState(() => _partnerPosition = partnerPos);
          }

          // Passeio iniciado: só atualiza o marcador, sem rota nem ETA
          if (_walkerTourStarted) return;

          final myPos = _isWalker
              ? _walkerCurrentPosition
              : (_tutorPosition != null
                    ? LatLng(
                        _tutorPosition!.latitude,
                        _tutorPosition!.longitude,
                      )
                    : null);
          if (myPos != null && _shouldRefreshRouteEta(partnerPos)) {
            await _updateRoute(myPos, partnerPos);
            await _updateDistanceEta(myPos, partnerPos);
          }
        });
  }

  bool _shouldRefreshRouteEta(LatLng partnerPos) {
    final now = DateTime.now();
    if (_lastRouteEtaUpdateAt == null || _lastRouteEtaPartnerPos == null) {
      _lastRouteEtaUpdateAt = now;
      _lastRouteEtaPartnerPos = partnerPos;
      return true;
    }

    final elapsed = now.difference(_lastRouteEtaUpdateAt!).inSeconds >= 12;
    final movedMeters = Geolocator.distanceBetween(
      _lastRouteEtaPartnerPos!.latitude,
      _lastRouteEtaPartnerPos!.longitude,
      partnerPos.latitude,
      partnerPos.longitude,
    );
    if (!elapsed && movedMeters < 25) return false;

    _lastRouteEtaUpdateAt = now;
    _lastRouteEtaPartnerPos = partnerPos;
    return true;
  }

  void _listenWalkPath(String tourId) {
    _walkPathSubscription?.cancel();
    _walkPathSubscription = FirebaseDatabase.instance
        .ref('walk_paths/$tourId')
        .onValue
        .listen((event) {
          if (!mounted) return;
          final data = event.snapshot.value;
          if (data == null) return;
          final points = <LatLng>[];

          // Firebase can return a List when keys are consecutive integers ('0','1','2'…)
          if (data is List) {
            for (final item in data) {
              if (item is! Map) continue;
              final lat = (item['lat'] as num?)?.toDouble();
              final lng = (item['lng'] as num?)?.toDouble();
              if (lat != null && lng != null) points.add(LatLng(lat, lng));
            }
          } else {
            final raw = data as Map;
            final keys = raw.keys.toList()
              ..sort((a, b) {
                final ia = int.tryParse(a.toString()) ?? 0;
                final ib = int.tryParse(b.toString()) ?? 0;
                return ia.compareTo(ib);
              });
            for (final k in keys) {
              final p = raw[k];
              if (p is! Map) continue;
              final lat = (p['lat'] as num?)?.toDouble();
              final lng = (p['lng'] as num?)?.toDouble();
              if (lat != null && lng != null) points.add(LatLng(lat, lng));
            }
          }

          double total = 0;
          for (int i = 1; i < points.length; i++) {
            total += Geolocator.distanceBetween(
              points[i - 1].latitude,
              points[i - 1].longitude,
              points[i].latitude,
              points[i].longitude,
            );
          }
          setState(() {
            _walkPathPoints = points;
            _walkDistanceMeters = total;
            _routePolylines = _buildTrailPolyline(points);
          });
          _scheduleWalkTrailSnap();
        });
  }

  Set<Polyline> _buildTrailPolyline(List<LatLng> points) {
    if (points.length < 2) return {};
    return {
      Polyline(
        polylineId: const PolylineId('walk_trail'),
        points: points,
        color: const Color(0xFF4CAF50),
        width: 4,
      ),
    };
  }

  Future<void> _updateRoute(LatLng origin, LatLng dest) async {
    _invalidateWalkTrailSnap();
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${dest.latitude},${dest.longitude}'
        '&mode=walking'
        '&key=$_mapsApiKey',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = body['routes'] as List?;
      if (routes == null || routes.isEmpty) return;
      final points =
          (routes[0] as Map)['overview_polyline']?['points'] as String?;
      if (points == null) return;
      final polylinePoints = _decodePolyline(points);
      if (!mounted) return;
      setState(() {
        _routePolylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: polylinePoints,
            color: const Color(0xFF4285F4),
            width: 4,
          ),
        };
      });
    } catch (_) {}
  }

  Future<void> _updateDistanceEta(LatLng origin, LatLng dest) async {
    final (distance, duration) = await _fetchDistanceEta(origin, dest);
    if (!mounted) return;
    setState(() {
      _distanceText = distance;
      _etaText = duration;
    });
  }

  Future<(String?, String?)> _fetchDistanceEta(
    LatLng origin,
    LatLng dest,
  ) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json'
        '?origins=${origin.latitude},${origin.longitude}'
        '&destinations=${dest.latitude},${dest.longitude}'
        '&mode=walking'
        '&key=$_mapsApiKey',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return (null, null);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final rows = body['rows'] as List?;
      if (rows == null || rows.isEmpty) return (null, null);
      final elements = (rows[0] as Map)['elements'] as List?;
      if (elements == null || elements.isEmpty) return (null, null);
      final element = elements[0] as Map;
      if (element['status'] != 'OK') return (null, null);
      final distance = (element['distance'] as Map?)?['text'] as String?;
      final duration = (element['duration'] as Map?)?['text'] as String?;
      return (distance, duration);
    } catch (_) {
      return (null, null);
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final result = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;
    while (index < encoded.length) {
      int shift = 0, b = 0, result_ = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result_ |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result_ & 1) != 0 ? ~(result_ >> 1) : (result_ >> 1);
      lat += dlat;

      shift = 0;
      result_ = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result_ |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result_ & 1) != 0 ? ~(result_ >> 1) : (result_ >> 1);
      lng += dlng;

      result.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return result;
  }

  // ── Walker: disponibilidade ──────────────────────────────────────────────

  void _startPendingTourListener() {
    final ref = FirebaseDatabase.instance.ref(
      'notifications/walkers/${widget.identifier}/pending_tour',
    );
    _pendingTourSubscription = ref.onValue.listen((event) {
      if (!mounted) return;
      final data = event.snapshot.value;
      if (data != null && !_pendingTourDialogShowing) {
        final tour = Map<String, dynamic>.from(data as Map);
        _showPendingTourDialog(tour);
      } else if (data == null && _pendingTourDialogShowing) {
        _pendingTourDialogShowing = false;
        Navigator.of(context, rootNavigator: true).maybePop();
      }
    });
  }

  Future<void> _showPendingTourDialog(Map<String, dynamic> tour) async {
    _pendingTourDialogShowing = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PendingTourDialog(
        tour: tour,
        accessToken: widget.accessToken,
        tourService: TourApiService(),
        onActivate: (tourId, tutorName) =>
            _startWalkerActiveTour(tourId, tutorName),
      ),
    );
    _pendingTourDialogShowing = false;
  }

  void _openActiveTourChat(BuildContext context) {
    if (_chatController == null || _activeTourId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          controller: _chatController!,
          currentUserId: widget.identifier,
          counterpartName: _activeTourPartnerName ?? '',
        ),
      ),
    );
  }

  Future<void> _showStartTourCodeDialog() async {
    final tourId = _activeTourId;
    if (tourId == null) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _StartTourCodeDialog(
        accessToken: widget.accessToken,
        tourIdentifier: tourId,
        tourService: TourApiService(),
        onSuccess: () {
          if (!mounted) return;
          setState(() {
            _walkerTourStarted = true;
            _routePolylines = {};
            _distanceText = null;
            _etaText = null;
            _walkPathPoints = _walkerCurrentPosition != null
                ? [_walkerCurrentPosition!]
                : [];
            _walkDistanceMeters = 0;
          });
          _invalidateWalkTrailSnap();
          _lastPushedWalkPathIndex = -1;
          _activeTourTimer?.cancel();
          _activeTourTimer = null;
          _startLocationUpdates(intervalSeconds: 10);
          _startElapsedTimer();
          if (_activeTourId != null) _listenWalkPath(_activeTourId!);
        },
      ),
    );
  }

  Future<void> _toggleAvailability(bool value) async {
    setState(() => _loadingAvailability = true);
    try {
      await _profileService.updateWalkerAvailability(
        identifier: widget.identifier,
        accessToken: widget.accessToken,
        available: value,
      );
      if (!mounted) return;
      setState(() {
        _available = value;
        if (!value) _walkerCurrentPosition = null;
      });
      if (value) {
        _startLocationUpdates();
      } else {
        _stopLocationUpdates();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loadingAvailability = false);
    }
  }

  void _startElapsedTimer({DateTime? startedAt}) {
    _elapsedTimer?.cancel();
    final base = startedAt ?? DateTime.now();
    _elapsedSeconds = DateTime.now().difference(base).inSeconds.clamp(0, 86400);
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });
  }

  String _formatElapsed() {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatWalkDistance() {
    if (_walkDistanceMeters < 1000) {
      return '${_walkDistanceMeters.toStringAsFixed(0)} m';
    }
    return '${(_walkDistanceMeters / 1000).toStringAsFixed(2)} km';
  }

  void _startLocationUpdates({int intervalSeconds = 30}) {
    _locationTimer?.cancel();
    _sendLocation();
    _locationTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => _sendLocation(),
    );
    _listenOwnLocation();
  }

  void _stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _ownLocationSubscription?.cancel();
    _ownLocationSubscription = null;
  }

  Future<void> _sendLocation() async {
    try {
      final ok = await _ensureLocationPermission();
      if (!ok) return;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      await _profileService.updateWalkerLocation(
        identifier: widget.identifier,
        accessToken: widget.accessToken,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {}
  }

  // Exibe a posição atual do próprio walker no mapa lendo do Firebase
  void _listenOwnLocation() {
    _ownLocationSubscription?.cancel();
    _ownLocationSubscription = _walkersRef
        .child(widget.identifier)
        .onValue
        .listen((event) {
          final data = event.snapshot.value;
          if (data == null || !mounted) return;
          final map = Map<String, dynamic>.from(data as Map);
          final lat = (map['latitude'] as num?)?.toDouble();
          final lng = (map['longitude'] as num?)?.toDouble();
          if (lat == null || lng == null) return;
          final newPos = LatLng(lat, lng);
          if (_walkerTourStarted) {
            final added = _walkPathPoints.isNotEmpty
                ? Geolocator.distanceBetween(
                    _walkPathPoints.last.latitude,
                    _walkPathPoints.last.longitude,
                    newPos.latitude,
                    newPos.longitude,
                  )
                : 0.0;
            _walkPathPoints.add(newPos);
            _pushWalkPath();
            setState(() {
              _walkerCurrentPosition = newPos;
              _walkDistanceMeters += added;
              _routePolylines = _buildTrailPolyline(_walkPathPoints);
            });
            _scheduleWalkTrailSnap();
          } else {
            setState(() => _walkerCurrentPosition = newPos);
          }
        });
  }

  Future<void> _pushWalkPath() async {
    final tourId = _activeTourId;
    if (tourId == null) return;
    final data = <String, dynamic>{};
    for (var i = _lastPushedWalkPathIndex + 1; i < _walkPathPoints.length; i++) {
      data['$i'] = {
        'lat': _walkPathPoints[i].latitude,
        'lng': _walkPathPoints[i].longitude,
      };
    }
    if (data.isEmpty) return;
    final previousIndex = _lastPushedWalkPathIndex;
    _lastPushedWalkPathIndex = _walkPathPoints.length - 1;
    try {
      await FirebaseDatabase.instance.ref('walk_paths/$tourId').update(data);
    } catch (_) {
      _lastPushedWalkPathIndex = previousIndex;
    }
  }

  void _endTour({Map<String, dynamic>? summary}) {
    _chatController?.removeListener(_onChatControllerUpdate);
    _chatController?.dispose();
    _chatController = null;
    final finishedTourId = _activeTourId;
    final shouldAskReview = !_isWalker && finishedTourId != null;

    _activeTourTimer?.cancel();
    _activeTourTimer = null;
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    _activeTourSubscription?.cancel();
    _activeTourSubscription = null;
    _partnerLocationSubscription?.cancel();
    _partnerLocationSubscription = null;
    _walkPathSubscription?.cancel();
    _walkPathSubscription = null;
    _finishRequestSubscription?.cancel();
    _finishRequestSubscription = null;
    _invalidateWalkTrailSnap();

    if (_isWalker) {
      _stopLocationUpdates();

      if (_activeTourId != null) {
        FirebaseDatabase.instance
            .ref('walk_paths/$_activeTourId')
            .remove()
            .catchError((_) {});
      }

      _startLocationUpdates();
    }

    if (!mounted) return;

    _dismissTerminationDialog.value = true;

    setState(() {
      _activeTour = false;
      _walkerTourStarted = false;
      _activeTourId = null;
      _activeTourPartnerName = null;
      _activeTourPetName = null;
      _activeTourPetPhotoBytes = null;
      _activeTourConfirmationCode = null;
      _partnerPosition = null;
      _walkPathPoints = [];
      _walkDistanceMeters = 0;
      _elapsedSeconds = 0;
      _routePolylines = {};
      _distanceText = null;
      _etaText = null;
    });
    _lastPushedWalkPathIndex = -1;
    _lastRouteEtaUpdateAt = null;
    _lastRouteEtaPartnerPos = null;

    if (summary != null) {
      showModalBottomSheet<void>(
        context: context,
        isDismissible: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _TourSummarySheet(summary: summary),
      ).whenComplete(() {
        if (!mounted) return;

        if (shouldAskReview) {
          _showReviewDialog(finishedTourId);
        }
      });
    } else {
      if (shouldAskReview) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          _showReviewDialog(finishedTourId);
        });
      }
    }
  }

  Future<void> _fetchAndLoadPetInfo(String tourId) async {
    try {
      final tour = await TourApiService().fetchTourById(
        accessToken: widget.accessToken,
        identifier: tourId,
      );
      if (!mounted) return;
      setState(() {
        _activeTourPetName = tour.petName ?? '';
        _activeTourConfirmationCode = tour.confirmationCode;
      });

      final bytes = await TourApiService().fetchPetPhoto(
        accessToken: widget.accessToken,
        tutorIdentifier: tour.tutorIdentifier,
        petIdentifier: tour.petIdentifier,
      );
      if (!mounted || bytes == null) return;
      setState(() => _activeTourPetPhotoBytes = bytes);
    } catch (_) {}
  }

  Future<void> _fetchTourSummaryAndEnd() async {
    final tourId = _activeTourId;
    Map<String, dynamic>? summary;
    if (tourId != null) {
      try {
        final tour = await TourApiService().fetchTourById(
          accessToken: widget.accessToken,
          identifier: tourId,
        );
        summary = {
          'started_at': tour.startedAt?.toIso8601String(),
          'finished_at': tour.finishedAt?.toIso8601String(),
          'total_time_seconds': tour.totalTimeSeconds,
          'distance_meters': tour.distanceMeters,
        };
      } catch (_) {}
    }
    _endTour(summary: summary);
  }

  void _startFinishRequestListener() {
    final ref = FirebaseDatabase.instance.ref(
      'notifications/tutors/${widget.identifier}/finish_request',
    );
    _finishRequestSubscription?.cancel();
    _finishRequestSubscription = ref.onValue.listen((event) {
      if (!mounted) return;
      final data = event.snapshot.value;
      if (data != null && !_finishTourDialogShowing) {
        final payload = Map<String, dynamic>.from(data as Map);
        _showFinishRequestNotificationDialog(payload);
      }
    });
  }

  Future<void> _showFinishRequestNotificationDialog(
    Map<String, dynamic> payload,
  ) async {
    _finishTourDialogShowing = true;

    final tourId =
        payload['tour_identifier']?.toString() ?? _activeTourId ?? '';
    final walkerName =
        payload['walker_name']?.toString() ??
        _activeTourPartnerName ??
        'passeador';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _FinishRequestNotificationDialog(
        walkerName: walkerName,
        onConfirm: () {},
      ),
    );

    _finishTourDialogShowing = false;

    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;

    await _showFinishTourQrDialog(tourId);
  }

  Future<void> _showFinishTourQrDialog(String tourId) async {
    final summary = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _FinishTourQrDialog(
        accessToken: widget.accessToken,
        tourIdentifier: tourId,
        tourService: TourApiService(),
      ),
    );

    if (!mounted) return;

    if (summary != null) {
      _endTour(summary: summary);
    }
  }

  Future<void> _showWalkerTerminationCodeDialog() async {
    final tourId = _activeTourId;
    if (tourId == null) return;

    final path = <String, dynamic>{};
    for (var i = 0; i < _walkPathPoints.length; i++) {
      path['$i'] = {
        'lat': _walkPathPoints[i].latitude,
        'lng': _walkPathPoints[i].longitude,
      };
    }

    String? qrToken;
    String? expiresAt;
    String? error;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => _WalkerTerminationCodeLoadingDialog(
        accessToken: widget.accessToken,
        tourIdentifier: tourId,
        distanceMeters: _walkDistanceMeters,
        totalTimeSeconds: _elapsedSeconds,
        path: path,
        tourService: TourApiService(),
        onCodeReceived: (token, expiresIso) {
          qrToken = token;
          expiresAt = expiresIso;
        },
        onError: (e) => error = e,
      ),
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error!)));
      return;
    }

    if (qrToken != null && qrToken!.isNotEmpty) {
      _dismissTerminationDialog.value = false;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (ctx) => _WalkerTerminationQrDisplayDialog(
          qrToken: qrToken!,
          expiresAtIso: expiresAt,
          dismissNotifier: _dismissTerminationDialog,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR não recebido. Tente encerrar o passeio novamente.'),
      ),
    );
  }

  // ── Restaura passeio ativo após re-login ─────────────────────────────────

  Future<void> _tryRestoreActiveTour() async {
    try {
      final roleField = _isWalker ? 'walker_id' : 'tutor_id';
      final snapshot = await FirebaseDatabase.instance
          .ref('active_tours')
          .orderByChild(roleField)
          .equalTo(widget.identifier)
          .limitToFirst(1)
          .get();

      if (!snapshot.exists || !mounted) return;

      final raw = snapshot.value;
      if (raw is! Map) return;

      final entry = raw.entries.first;
      final tourId = entry.key.toString();
      final tourRaw = entry.value;
      if (tourRaw is! Map) return;

      final status = tourRaw['status']?.toString().toUpperCase();
      // null = walker accepted (a caminho); IN_PROGRESS = passeio em andamento
      if (status != null &&
          status != 'IN_PROGRESS' &&
          status != 'WALKER_ON_THE_WAY') {
        return;
      }

      final walkerName = tourRaw['walker_name']?.toString() ?? 'Passeador';
      final tutorName = tourRaw['tutor_name']?.toString() ?? 'Tutor';
      final firebaseStatus = tourRaw['status']?.toString();
      final startedAtStr = tourRaw['started_at']?.toString();
      final startedAt = startedAtStr != null
          ? DateTime.tryParse(startedAtStr)
          : null;

      if (!mounted) return;
      await _syncActiveTourToFirebase(tourId);
      if (!mounted) return;
      if (_isWalker) {
        await _startWalkerActiveTour(
          tourId,
          tutorName,
          apiStatus: firebaseStatus ?? 'WALKER_ON_THE_WAY',
          startedAt: startedAt,
        );
      } else {
        _startTutorActiveTour(
          tourId,
          walkerName,
          apiStatus: firebaseStatus ?? 'WALKER_ON_THE_WAY',
          startedAt: startedAt,
        );
      }
    } catch (_) {}
  }

  // ── Tutor: mapa de passeadores próximos ─────────────────────────────────

  Future<void> _initTutorMap() async {
    final ok = await _ensureLocationPermission();
    if (!ok || !mounted) return;

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
    if (!mounted) return;
    setState(() => _tutorPosition = position);

    _startTourResponseListener();
    _startFinishRequestListener();

    await _tryRestoreActiveTour();
    if (!_activeTour) {
      await _tryRestoreTutorActiveTourFromApi();
    }

    _walkersSubscription = _walkersRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (!mounted) return;

      if (data == null) {
        setState(() => _nearbyWalkers = []);
        return;
      }

      final map = Map<String, dynamic>.from(data as Map);
      final walkers = <NearbyWalker>[];

      for (final entry in map.entries) {
        final walkerData = Map<String, dynamic>.from(entry.value as Map);
        final available = walkerData['available'] as bool? ?? false;
        final status = walkerData['status'] as String? ?? 'idle';
        if (!available || status != 'idle') continue;

        final lat = (walkerData['latitude'] as num?)?.toDouble();
        final lng = (walkerData['longitude'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;

        final distance = haversineDistance(
          position.latitude,
          position.longitude,
          lat,
          lng,
        );
        if (distance > _nearbyRadiusKm) continue;

        walkers.add(
          NearbyWalker(
            identifier: entry.key,
            name: walkerData['name'] as String? ?? '',
            latitude: lat,
            longitude: lng,
          ),
        );
      }

      setState(() => _nearbyWalkers = walkers);
    });
  }

  Future<void> _retryNearbyWalkers() async {
    if (_retryingNearbyWalkers) return;
    if (_isWalker) return;
    if (!mounted) return;

    setState(() => _retryingNearbyWalkers = true);
    await _walkersSubscription?.cancel();
    _walkersSubscription = null;

    try {
      await _initTutorMap();
    } finally {
      if (mounted) {
        setState(() => _retryingNearbyWalkers = false);
      }
    }
  }

  void _startTourResponseListener() {
    final ref = FirebaseDatabase.instance.ref(
      'notifications/tutors/${widget.identifier}/tour_response',
    );
    _tourResponseSubscription?.cancel();
    _tourResponseSubscription = ref.onValue.listen((event) {
      if (!mounted) return;
      final data = event.snapshot.value;
      if (data != null && !_tourResponseDialogShowing) {
        final response = Map<String, dynamic>.from(data as Map);
        _showTourResponseDialog(response);
      } else if (data == null && _tourResponseDialogShowing) {
        _tourResponseDialogShowing = false;
      }
    });
  }

  Future<void> _showTourResponseDialog(Map<String, dynamic> response) async {
    _tourResponseDialogShowing = true;
    setState(() => _waitingTourResponse = false);

    String? distanceText;
    String? etaText;

    final accepted = response['accepted'] as bool? ?? false;
    final tourId = response['tour_identifier']?.toString();
    if (accepted && tourId != null && _tutorPosition != null) {
      try {
        final tourSnap = await FirebaseDatabase.instance
            .ref('active_tours/$tourId')
            .get();
        if (tourSnap.exists) {
          final tourData = Map<String, dynamic>.from(tourSnap.value as Map);
          final walkerId = tourData['walker_id']?.toString();
          if (walkerId != null) {
            final locSnap = await FirebaseDatabase.instance
                .ref('walker_locations/$walkerId')
                .get();
            if (locSnap.exists) {
              final loc = Map<String, dynamic>.from(locSnap.value as Map);
              final lat = (loc['latitude'] as num?)?.toDouble();
              final lng = (loc['longitude'] as num?)?.toDouble();
              if (lat != null && lng != null) {
                final tutorLatLng = LatLng(
                  _tutorPosition!.latitude,
                  _tutorPosition!.longitude,
                );
                (distanceText, etaText) = await _fetchDistanceEta(
                  tutorLatLng,
                  LatLng(lat, lng),
                );
              }
            }
          }
        }
      } catch (_) {}
    }

    if (!mounted) {
      _tourResponseDialogShowing = false;
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _TourResponseDialog(
        response: response,
        accessToken: widget.accessToken,
        tutorIdentifier: widget.identifier,
        tourService: TourApiService(),
        distanceText: distanceText,
        etaText: etaText,
        onActivate: (tourId, walkerName) =>
            _startTutorActiveTour(tourId, walkerName),
      ),
    );
    _tourResponseDialogShowing = false;
  }

  // ── Shared ───────────────────────────────────────────────────────────────

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ative o GPS do seu dispositivo para continuar.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Permissão de localização negada. Habilite nas configurações do app.',
            ),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Configurações',
              onPressed: Geolocator.openAppSettings,
            ),
          ),
        );
      }
      return false;
    }

    if (permission == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissão de localização negada.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return false;
    }

    return true;
  }

  Future<void> _onWalkerPinTapped(NearbyWalker walker) async {
    if (!mounted || _activeTour) return;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _WalkerPinSheet(
        walker: walker,
        accessToken: widget.accessToken,
        tutorIdentifier: widget.identifier,
        walkerApiService: _walkerApiService,
        tutorPosition: _tutorPosition,
        onRequestSent: () => setState(() => _waitingTourResponse = true),
      ),
    );
  }

  Set<Marker> get _tutorMapMarkers {
    final markers = <Marker>{};

    if (_tutorPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('tutor'),
          position: LatLng(_tutorPosition!.latitude, _tutorPosition!.longitude),
        ),
      );
    }

    if (_activeTour) {
      if (_partnerPosition != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('active_walker'),
            position: _partnerPosition!,
            infoWindow: InfoWindow(
              title: _activeTourPartnerName ?? 'Passeador',
              snippet: 'Localização do passeador do passeio',
            ),
          ),
        );
      }
    } else {
      for (final walker in _nearbyWalkers) {
        final name = walker.name.trim().isEmpty
            ? 'Passeador'
            : walker.name.trim();
        markers.add(
          Marker(
            markerId: MarkerId(walker.identifier),
            position: LatLng(walker.latitude, walker.longitude),
            infoWindow: InfoWindow(
              title: name,
              snippet: 'Pessoa disponível',
            ),
            onTap: () => _onWalkerPinTapped(walker),
          ),
        );
      }
    }

    return markers;
  }

  Set<Marker> get _walkerMapMarkers {
    final markers = <Marker>{};
    if (_walkerCurrentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('walker_self'),
          position: _walkerCurrentPosition!,
          infoWindow: InfoWindow(
            title: widget.name,
            snippet: 'Sua localização atual',
          ),
        ),
      );
    }
    if (_activeTour && _partnerPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('active_tutor'),
          position: _partnerPosition!,
          infoWindow: InfoWindow(title: _activeTourPartnerName ?? 'Tutor'),
        ),
      );
    }
    return markers;
  }

  Widget _buildMapboxMap({
    required LatLng initialPosition,
    required Set<Marker> markers,
    required Set<Polyline> polylines,
    double initialZoom = 15,
  }) {
    if (!AppConfig.hasMapboxAccessToken) {
      return const Center(
        child: Text('Configure MAPBOX_ACCESS_TOKEN para exibir o mapa.'),
      );
    }

    return _MapboxDashboardMap(
      styleUri: AppConfig.mapboxStyleUriForBrightness(
        Theme.of(context).brightness == Brightness.dark,
      ),
      accessToken: AppConfig.mapboxAccessToken,
      initialPosition: initialPosition,
      initialZoom: initialZoom,
      markers: markers,
      polylines: polylines,
      walkerIconBytes: _walkerIconBytes,
      tutorIconBytes: _tutorIconBytes,
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayName = widget.name.isNotEmpty ? widget.name : 'Usuário';

    final body = _isWalker
        ? _buildWalkerBody(context, cs, displayName)
        : _buildTutorBody(context, cs, displayName);

    return SizedBox.expand(child: body);
  }

  Widget _buildWalkerBody(
    BuildContext context,
    ColorScheme cs,
    String displayName,
  ) {
    final initialPosition = _walkerCurrentPosition;
    final isOn = _available ?? false;

    return Stack(
      children: [
        // Fundo: mapa quando disponível ou em tour ativo, tela de indisponível caso contrário
        if (isOn || _activeTour)
          initialPosition == null
              ? Center(child: CircularProgressIndicator(color: cs.secondary))
              : _buildMapboxMap(
                  initialPosition: initialPosition,
                  markers: _walkerMapMarkers,
                  polylines: _routePolylines,
                )
        else
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.pets,
                  size: 56,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'Você está indisponível para passeios',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  'Toque no botão abaixo para ficar disponível',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

        // Card de passeio ativo (walker)
        if (_activeTour)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _WalkerActiveTourCard(
              petName: _activeTourPetName ?? '',
              petPhotoBytes: _activeTourPetPhotoBytes,
              tutorName: _activeTourPartnerName ?? 'Tutor',
              tourStarted: _walkerTourStarted,
              distance: _walkerTourStarted ? _formatWalkDistance() : _distanceText,
              elapsed: _walkerTourStarted ? _formatElapsed() : _etaText,
              onStart: !_walkerTourStarted ? _showStartTourCodeDialog : null,
              onFinish: _walkerTourStarted ? _showWalkerTerminationCodeDialog : null,
              onChat: () => _openActiveTourChat(context),
              unreadCount: _chatController?.unreadCount ?? 0,
            ),
          ),

        // Botão flutuante de disponibilidade (oculto durante tour ativo)
        if (!_activeTour)
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AvailabilityFab(
                    available: _available,
                    loading: _loadingAvailability,
                    onTap: (_available == null || _loadingAvailability)
                        ? null
                        : () => _toggleAvailability(!isOn),
                  ),
                  const SizedBox(height: 8),
                  if (_available != null && !_loadingAvailability)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isOn ? 'Disponível' : 'Indisponível',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isOn ? cs.secondary : cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTutorBody(
    BuildContext context,
    ColorScheme cs,
    String displayName,
  ) {
    if (_tutorPosition == null) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.secondary,
        ),
      );
    }

    final initialPosition = LatLng(
      _tutorPosition!.latitude,
      _tutorPosition!.longitude,
    );

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_activeTour) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _walkerTourStarted
                                ? 'Passeio em andamento com ${_activeTourPartnerName ?? 'passeador'}'
                                : 'Passeador a caminho',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        if (_chatController != null)
                          Badge(
                            isLabelVisible: (_chatController?.unreadCount ?? 0) > 0,
                            label: Text(
                              (_chatController?.unreadCount ?? 0) > 99
                                  ? '99+'
                                  : '${_chatController!.unreadCount}',
                              style: const TextStyle(fontSize: 10),
                            ),
                            child: IconButton(
                              onPressed: () => _openActiveTourChat(context),
                              icon: const Icon(Icons.chat_rounded),
                              color: cs.secondary,
                              tooltip: 'Abrir chat',
                            ),
                          ),
                        if (!_walkerTourStarted && _activeTourConfirmationCode != null) ...[
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Código',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                _activeTourConfirmationCode!,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                  color: cs.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: cs.secondaryContainer,
                          backgroundImage: _activeTourPetPhotoBytes != null
                              ? MemoryImage(_activeTourPetPhotoBytes!)
                              : null,
                          child: _activeTourPetPhotoBytes == null
                              ? Icon(Icons.pets_rounded, size: 18, color: cs.onSecondaryContainer)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Pet: ${_activeTourPetName?.isNotEmpty == true ? _activeTourPetName! : '—'}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (_walkerTourStarted)
                      Text(
                        '${_formatWalkDistance()} — ${_formatElapsed()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      )
                    else if (_distanceText != null)
                      Text(
                        _etaText != null
                            ? '$_distanceText — $_etaText'
                            : _distanceText!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ] else ...[
                    Text(
                      'Bem-vindo, $displayName!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_waitingTourResponse)
                      Text(
                        'Aguardando aceite do passeio...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nearbyWalkers.isEmpty
                                ? 'Nenhum passeador disponível por perto'
                                : '${_nearbyWalkers.length} passeador${_nearbyWalkers.length > 1 ? 'es' : ''} disponível${_nearbyWalkers.length > 1 ? 'is' : ''} por perto',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          if (_nearbyWalkers.isEmpty) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _retryingNearbyWalkers
                                  ? null
                                  : () {
                                      unawaited(_retryNearbyWalkers());
                                    },
                              icon: _retryingNearbyWalkers
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: cs.primary,
                                      ),
                                    )
                                  : const Icon(Icons.refresh_rounded, size: 20),
                              label: Text(
                                _retryingNearbyWalkers
                                    ? 'Buscando...'
                                    : 'Tentar novamente',
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildMapboxMap(
                    initialPosition: initialPosition,
                    initialZoom: 14,
                    markers: _tutorMapMarkers,
                    polylines: _routePolylines,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MapboxDashboardMap extends StatefulWidget {
  const _MapboxDashboardMap({
    required this.styleUri,
    required this.accessToken,
    required this.initialPosition,
    required this.initialZoom,
    required this.markers,
    required this.polylines,
    this.walkerIconBytes,
    this.tutorIconBytes,
  });

  final String styleUri;
  final String accessToken;
  final LatLng initialPosition;
  final double initialZoom;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Uint8List? walkerIconBytes;
  final Uint8List? tutorIconBytes;

  @override
  State<_MapboxDashboardMap> createState() => _MapboxDashboardMapState();
}

class _MapboxDashboardMapState extends State<_MapboxDashboardMap> {
  mb.MapboxMap? _mapboxMap;
  mb.PointAnnotationManager? _pointManager;
  mb.PolylineAnnotationManager? _polylineManager;
  final Map<String, VoidCallback?> _tapByAnnotationId = {};
  final Map<String, mb.PointAnnotation> _pointByMarkerId = {};
  final Map<String, String> _annotationIdToMarkerId = {};
  final Map<String, mb.PolylineAnnotation> _polylineById = {};
  bool _refreshInFlight = false;
  bool _refreshQueued = false;

  void _onMapCreated(mb.MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    await mapboxMap.style.setStyleURI(widget.styleUri);
    await mapboxMap.setCamera(
      mb.CameraOptions(
        center: mb.Point(
          coordinates: mb.Position(
            widget.initialPosition.longitude,
            widget.initialPosition.latitude,
          ),
        ),
        zoom: widget.initialZoom,
      ),
    );
    _pointManager = await mapboxMap.annotations.createPointAnnotationManager();
    _polylineManager =
        await mapboxMap.annotations.createPolylineAnnotationManager();
    _pointManager?.tapEvents(onTap: (annotation) {
      _tapByAnnotationId[annotation.id]?.call();
    });
    await _refreshAnnotations();
  }

  @override
  void dispose() {
    _tapByAnnotationId.clear();
    _pointByMarkerId.clear();
    _annotationIdToMarkerId.clear();
    _polylineById.clear();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _MapboxDashboardMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.styleUri != widget.styleUri) {
      _mapboxMap = null;
      _pointManager = null;
      _polylineManager = null;
      _tapByAnnotationId.clear();
      _pointByMarkerId.clear();
      _annotationIdToMarkerId.clear();
      _polylineById.clear();
    }
    _refreshAnnotations();
  }

  Future<void> _refreshAnnotations() async {
    if (_refreshInFlight) {
      _refreshQueued = true;
      return;
    }
    _refreshInFlight = true;
    try {
      await _doRefreshAnnotations();
    } finally {
      _refreshInFlight = false;
      if (_refreshQueued) {
        _refreshQueued = false;
        _refreshAnnotations();
      }
    }
  }

  Future<void> _doRefreshAnnotations() async {
    final pointManager = _pointManager;
    final polylineManager = _polylineManager;
    final mapboxMap = _mapboxMap;
    if (pointManager == null || polylineManager == null || mapboxMap == null) {
      return;
    }

    final nextMarkerIds = widget.markers.map((m) => m.markerId.value).toSet();
    final markerIdsToDelete = _pointByMarkerId.keys
        .where((id) => !nextMarkerIds.contains(id))
        .toList();
    for (final markerId in markerIdsToDelete) {
      final annotation = _pointByMarkerId.remove(markerId);
      if (annotation != null) {
        await pointManager.delete(annotation);
        _tapByAnnotationId.remove(annotation.id);
        _annotationIdToMarkerId.remove(annotation.id);
      }
    }

    for (final marker in widget.markers) {
      final markerId = marker.markerId.value;
      final imageBytes = markerId.contains('tutor')
          ? widget.tutorIconBytes
          : widget.walkerIconBytes;
      final existing = _pointByMarkerId[markerId];
      if (existing == null) {
        final created = await pointManager.create(
          mb.PointAnnotationOptions(
            geometry: mb.Point(
              coordinates: mb.Position(
                marker.position.longitude,
                marker.position.latitude,
              ),
            ),
            image: imageBytes,
            iconAnchor: mb.IconAnchor.BOTTOM,
            iconOffset: [0.0, -2.0],
            iconSize: markerId.contains('active_') ? 0.92 : 0.84,
          ),
        );
        _pointByMarkerId[markerId] = created;
        _annotationIdToMarkerId[created.id] = markerId;
        _tapByAnnotationId[created.id] = marker.onTap;
      } else {
        existing.geometry = mb.Point(
          coordinates: mb.Position(
            marker.position.longitude,
            marker.position.latitude,
          ),
        );
        existing.iconSize = markerId.contains('active_') ? 0.92 : 0.84;
        await pointManager.update(existing);
        _tapByAnnotationId[existing.id] = marker.onTap;
      }
    }

    final nextPolylineIds = widget.polylines.map((p) => p.polylineId.value).toSet();
    final polylineIdsToDelete = _polylineById.keys
        .where((id) => !nextPolylineIds.contains(id))
        .toList();
    for (final polylineId in polylineIdsToDelete) {
      final annotation = _polylineById.remove(polylineId);
      if (annotation != null) {
        await polylineManager.delete(annotation);
      }
    }

    for (final polyline in widget.polylines) {
      final polylineId = polyline.polylineId.value;
      final points = polyline.points
          .map((p) => mb.Position(p.longitude, p.latitude))
          .toList();
      final existing = _polylineById[polylineId];
      if (existing == null) {
        final created = await polylineManager.create(
          mb.PolylineAnnotationOptions(
            geometry: mb.LineString(coordinates: points),
            lineColor: polyline.color.toARGB32(),
            lineWidth: polyline.width.toDouble(),
          ),
        );
        _polylineById[polylineId] = created;
      } else {
        existing.geometry = mb.LineString(coordinates: points);
        existing.lineColor = polyline.color.toARGB32();
        existing.lineWidth = polyline.width.toDouble();
        await polylineManager.update(existing);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return mb.MapWidget(
      key: ValueKey(widget.styleUri),
      onMapCreated: _onMapCreated,
      textureView: true,
    );
  }
}


class _WalkerPinSheet extends StatefulWidget {
  const _WalkerPinSheet({
    required this.walker,
    required this.accessToken,
    required this.tutorIdentifier,
    required this.walkerApiService,
    required this.tutorPosition,
    this.onRequestSent,
  });

  final NearbyWalker walker;
  final String accessToken;
  final String tutorIdentifier;
  final WalkerApiService walkerApiService;
  final Position? tutorPosition;
  final VoidCallback? onRequestSent;

  @override
  State<_WalkerPinSheet> createState() => _WalkerPinSheetState();
}

class _WalkerPinSheetState extends State<_WalkerPinSheet> {
  bool _loading = true;
  String? _error;
  double? _walkPrice;
  double? _averageRideTime;
  double? _averageRating;
  List<Pet> _pets = [];
  bool _requestingTour = false;

  final _tourService = TourApiService();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final info = await widget.walkerApiService.findOneForPin(
        accessToken: widget.accessToken,
        identifier: widget.walker.identifier,
      );
      final pets = await _tourService.fetchPets(
        accessToken: widget.accessToken,
        tutorIdentifier: widget.tutorIdentifier,
      );
      if (!mounted) return;
      setState(() {
        _walkPrice = info.walkPrice;
        _averageRideTime = info.averageRideTime;
        _averageRating = info.averageRating;
        _pets = pets;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar os dados do passeador';
        _loading = false;
      });
    }
  }

  Future<void> _onSolicitarPasseio() async {
    if (_pets.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Nenhum pet cadastrado'),
          content: const Text(
            'Você precisa cadastrar um pet antes de solicitar um passeio.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => _RequestTourDialog(
        pets: _pets,
        accessToken: widget.accessToken,
        tutorIdentifier: widget.tutorIdentifier,
        tourService: _tourService,
        onConfirm: (petIdentifier) async {
          Navigator.of(ctx).pop();
          if (!mounted) return;
          setState(() => _requestingTour = true);
          try {
            await _tourService.createTourRequest(
              accessToken: widget.accessToken,
              walkerIdentifier: widget.walker.identifier,
              tutorIdentifier: widget.tutorIdentifier,
              petIdentifier: petIdentifier,
              tutorLatitude: widget.tutorPosition?.latitude ?? 0.0,
              tutorLongitude: widget.tutorPosition?.longitude ?? 0.0,
            );
            if (!mounted) return;
            widget.onRequestSent?.call();
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Passeio solicitado com sucesso!'),
                duration: Duration(seconds: 3),
              ),
            );
          } catch (_) {
            if (!mounted) return;
            setState(() => _requestingTour = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erro ao solicitar passeio. Tente novamente.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.walker.name,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Passeador disponível',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text(_error!, style: TextStyle(color: cs.error))
          else ...[
            _InfoRow(
              icon: Icons.attach_money_rounded,
              label: 'Preço por passeio',
              value: _walkPrice != null
                  ? 'R\$ ${_walkPrice!.toStringAsFixed(2).replaceAll('.', ',')}'
                  : '—',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.timer_outlined,
              label: 'Tempo médio',
              value: _averageRideTime != null
                  ? '${_averageRideTime!.toStringAsFixed(0)} min'
                  : '—',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.star_outline_rounded,
              label: 'Nota média',
              value: _averageRating != null
                  ? _averageRating!.toStringAsFixed(1)
                  : '—',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _requestingTour ? null : _onSolicitarPasseio,
                child: _requestingTour
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Solicitar passeio'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RequestTourDialog extends StatefulWidget {
  const _RequestTourDialog({
    required this.pets,
    required this.accessToken,
    required this.tutorIdentifier,
    required this.tourService,
    required this.onConfirm,
  });

  final List<Pet> pets;
  final String accessToken;
  final String tutorIdentifier;
  final TourApiService tourService;
  final Future<void> Function(String petIdentifier) onConfirm;

  @override
  State<_RequestTourDialog> createState() => _RequestTourDialogState();
}

class _RequestTourDialogState extends State<_RequestTourDialog> {
  late Pet _selectedPet;
  final Map<String, Uint8List?> _photoCache = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedPet = widget.pets.first;
    _loadPhotos();
  }

  void _loadPhotos() {
    for (final pet in widget.pets) {
      widget.tourService
          .fetchPetPhoto(
            accessToken: widget.accessToken,
            tutorIdentifier: widget.tutorIdentifier,
            petIdentifier: pet.identifier,
          )
          .then((bytes) {
            if (mounted) setState(() => _photoCache[pet.identifier] = bytes);
          });
    }
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    await widget.onConfirm(_selectedPet.identifier);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Solicitar passeio'),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Selecione o pet',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.pets.length,
                separatorBuilder: (context, index) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final pet = widget.pets[index];
                  final selected = pet.identifier == _selectedPet.identifier;
                  final photoBytes = _photoCache[pet.identifier];

                  return InkWell(
                    onTap: _loading
                        ? null
                        : () => setState(() => _selectedPet = pet),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? cs.primaryContainer
                            : cs.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? cs.primary : cs.outlineVariant,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: cs.surfaceContainerHighest,
                            backgroundImage: photoBytes != null
                                ? MemoryImage(photoBytes)
                                : null,
                            child: photoBytes == null
                                ? Icon(
                                    Icons.pets,
                                    size: 22,
                                    color: cs.onSurfaceVariant,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pet.name,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: selected
                                            ? cs.onPrimaryContainer
                                            : null,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (selected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: cs.primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _loading ? null : _confirm,
          child: _loading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Solicitar'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.secondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _TourResponseDialog extends StatefulWidget {
  const _TourResponseDialog({
    required this.response,
    required this.accessToken,
    required this.tutorIdentifier,
    required this.tourService,
    this.distanceText,
    this.etaText,
    this.onActivate,
  });

  final Map<String, dynamic> response;
  final String accessToken;
  final String tutorIdentifier;
  final TourApiService tourService;
  final String? distanceText;
  final String? etaText;
  final void Function(String tourId, String walkerName)? onActivate;

  @override
  State<_TourResponseDialog> createState() => _TourResponseDialogState();
}

class _TourResponseDialogState extends State<_TourResponseDialog> {
  bool _loading = false;

  Future<void> _clearNotification() async {
    final accepted = widget.response['accepted'] as bool? ?? false;
    final tourId = widget.response['tour_identifier']?.toString();
    final walkerName = widget.response['walker_name']?.toString() ?? '';

    setState(() => _loading = true);
    try {
      await widget.tourService.clearTutorTourNotification(
        accessToken: widget.accessToken,
        identifier: widget.tutorIdentifier,
      );
      if (!mounted) return;
      if (accepted && tourId != null) {
        widget.onActivate?.call(tourId, walkerName);
      }
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Erro ao limpar a notificação do passeio. Tente novamente.',
          ),
        ),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accepted = widget.response['accepted'] as bool? ?? false;
    final walkerName = widget.response['walker_name']?.toString() ?? '—';
    final confirmationCode =
        widget.response['confirmation_code']?.toString() ?? '—';

    return AlertDialog(
      icon: Align(
        alignment: Alignment.centerLeft,
        child: Image.asset('assets/images/logo.png', height: 36),
      ),
      title: Text(accepted ? 'Passeador a caminho!' : 'Passeio recusado'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            accepted ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 56,
            color: accepted ? Colors.green : cs.error,
          ),
          const SizedBox(height: 16),
          Text(
            accepted
                ? '$walkerName aceitou o passeio e está a caminho!'
                : '$walkerName recusou o seu passeio.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (accepted) ...[
            const SizedBox(height: 14),
            Text(
              'Esse é o código de confirmação do passeio, informe ao passeador:',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              confirmationCode,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            if (widget.distanceText != null) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.directions_walk, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    widget.etaText != null
                        ? '${widget.distanceText} — ${widget.etaText}'
                        : widget.distanceText!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: _loading ? null : _clearNotification,
          child: _loading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('OK'),
        ),
      ],
    );
  }
}

class _PendingTourDialog extends StatefulWidget {
  const _PendingTourDialog({
    required this.tour,
    required this.accessToken,
    required this.tourService,
    this.onActivate,
  });

  final Map<String, dynamic> tour;
  final String accessToken;
  final TourApiService tourService;
  final void Function(String tourId, String tutorName)? onActivate;

  @override
  State<_PendingTourDialog> createState() => _PendingTourDialogState();
}

class _PendingTourDialogState extends State<_PendingTourDialog> {
  bool _loading = false;

  String _formatDate(String isoDate) {
    final dt = DateTime.parse(isoDate).toLocal();
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/${dt.year} às $hour:$minute';
  }

  Future<void> _respond(bool accepted) async {
    final tourIdentifier = widget.tour['tour_identifier']?.toString();
    if (tourIdentifier == null) return;
    final tutorName = widget.tour['tutor_name']?.toString() ?? '';
    // Captura o callback antes do await — o dialog pode ser desmontado
    // pelo listener do Firebase antes da resposta HTTP chegar, tornando
    // mounted=false e impedindo a chamada do onActivate.
    final onActivate = accepted ? widget.onActivate : null;
    setState(() => _loading = true);
    try {
      await widget.tourService.confirmTour(
        accessToken: widget.accessToken,
        tourIdentifier: tourIdentifier,
        accepted: accepted,
      );
      onActivate?.call(tourIdentifier, tutorName);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao responder o pedido. Tente novamente.'),
        ),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tutorName = widget.tour['tutor_name']?.toString() ?? '—';
    final petName = widget.tour['pet_name']?.toString() ?? '—';
    final createdAtRaw = widget.tour['created_at']?.toString();
    final createdAt = createdAtRaw != null ? _formatDate(createdAtRaw) : '—';

    return AlertDialog(
      icon: Align(
        alignment: Alignment.centerLeft,
        child: Image.asset('assets/images/logo.png', height: 36),
      ),
      title: const Text('Novo pedido de passeio', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TourInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Tutor',
            value: tutorName,
          ),
          const SizedBox(height: 12),
          _TourInfoRow(icon: Icons.pets_rounded, label: 'Pet', value: petName),
          const SizedBox(height: 12),
          _TourInfoRow(
            icon: Icons.access_time_rounded,
            label: 'Solicitado em',
            value: createdAt,
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        OutlinedButton(
          onPressed: _loading ? null : () => _respond(false),
          style: OutlinedButton.styleFrom(foregroundColor: cs.error),
          child: const Text('Recusar'),
        ),
        FilledButton(
          onPressed: _loading ? null : () => _respond(true),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Aceitar'),
        ),
      ],
    );
  }
}

class _StartTourCodeDialog extends StatefulWidget {
  const _StartTourCodeDialog({
    required this.accessToken,
    required this.tourIdentifier,
    required this.tourService,
    required this.onSuccess,
  });

  final String accessToken;
  final String tourIdentifier;
  final TourApiService tourService;
  final void Function() onSuccess;

  @override
  State<_StartTourCodeDialog> createState() => _StartTourCodeDialogState();
}

class _StartTourCodeDialogState extends State<_StartTourCodeDialog> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _startTour() async {
    final code = _codeController.text.trim();
    if (code.length != 4) {
      setState(() => _error = 'Digite exatamente 4 dígitos.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.tourService.startTour(
        accessToken: widget.accessToken,
        tourIdentifier: widget.tourIdentifier,
        confirmationCode: code,
      );

      if (!mounted) return;
      widget.onSuccess();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Align(
        alignment: Alignment.centerLeft,
        child: Image.asset('assets/images/logo.png', height: 36),
      ),
      title: const Text('Iniciar passeio', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Quando estiver no local do tutor, digite o código informado por ele:',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _codeController,
            enabled: !_loading,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: '0000',
              counterText: '',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _startTour(),
          ),
          if (_error != null && _error!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.error),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _loading ? null : _startTour,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Iniciar'),
        ),
      ],
    );
  }
}

class _TourInfoRow extends StatelessWidget {
  const _TourInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.secondary),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _WalkerActiveTourCard extends StatefulWidget {
  const _WalkerActiveTourCard({
    required this.petName,
    required this.tutorName,
    required this.tourStarted,
    this.petPhotoBytes,
    this.distance,
    this.elapsed,
    this.onStart,
    this.onFinish,
    this.onChat,
    this.unreadCount = 0,
  });

  final String petName;
  final Uint8List? petPhotoBytes;
  final String tutorName;
  final bool tourStarted;
  final String? distance;
  final String? elapsed;
  final VoidCallback? onStart;
  final VoidCallback? onFinish;
  final VoidCallback? onChat;
  final int unreadCount;

  @override
  State<_WalkerActiveTourCard> createState() => _WalkerActiveTourCardState();
}

class _WalkerActiveTourCardState extends State<_WalkerActiveTourCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;
  late final AnimationController _animController;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = widget.tourStarted ? 'Passeio em andamento' : 'Indo até o tutor';

    return Material(
      elevation: 4,
      child: SafeArea(
        bottom: false,
        child: Container(
          color: cs.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barra de título sempre visível + chevron
              InkWell(
                onTap: _toggle,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Badge(
                        isLabelVisible: widget.unreadCount > 0,
                        label: Text(
                          widget.unreadCount > 99 ? '99+' : '${widget.unreadCount}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        child: IconButton(
                          onPressed: widget.onChat,
                          icon: const Icon(Icons.chat_rounded),
                          color: cs.secondary,
                          tooltip: 'Abrir chat',
                        ),
                      ),
                      AnimatedRotation(
                        turns: _expanded ? 0 : 0.5,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_less_rounded,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Conteúdo expansível
              SizeTransition(
                sizeFactor: _expandAnimation,
                axisAlignment: -1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: cs.secondaryContainer,
                                  backgroundImage: widget.petPhotoBytes != null
                                      ? MemoryImage(widget.petPhotoBytes!)
                                      : null,
                                  child: widget.petPhotoBytes == null
                                      ? Icon(Icons.pets_rounded, size: 18, color: cs.onSecondaryContainer)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pet: ${widget.petName.isNotEmpty ? widget.petName : '—'}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Tutor: ${widget.tutorName}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (widget.distance != null || widget.elapsed != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                [widget.distance, widget.elapsed].where((e) => e != null).join(' — '),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (widget.onFinish != null)
                        FilledButton.icon(
                          onPressed: widget.onFinish,
                          style: FilledButton.styleFrom(
                            backgroundColor: cs.error,
                            foregroundColor: cs.onError,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          icon: const Icon(Icons.stop_circle_outlined, size: 18),
                          label: const Text('Finalizar'),
                        )
                      else if (widget.onStart != null)
                        FilledButton(
                          onPressed: widget.onStart,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          child: const Text('Iniciar'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvailabilityFab extends StatelessWidget {
  const _AvailabilityFab({
    required this.available,
    required this.loading,
    required this.onTap,
  });

  final bool? available;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOn = available ?? false;

    final bgColor = isOn ? cs.secondary : cs.surface;
    final fgColor = isOn ? cs.onSecondary : cs.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: loading || available == null
            ? Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: cs.secondary,
                  ),
                ),
              )
            : Icon(Icons.pets, color: fgColor, size: 32),
      ),
    );
  }
}

// ── Bottom sheet: resumo do passeio finalizado ───────────────────────────────

class _TourSummarySheet extends StatelessWidget {
  const _TourSummarySheet({required this.summary});

  final Map<String, dynamic> summary;

  String _formatTime(String? isoString) {
    if (isoString == null) return '—';
    final dt = DateTime.tryParse(isoString)?.toLocal();
    if (dt == null) return '—';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(dynamic seconds) {
    final s = seconds is int ? seconds : int.tryParse(seconds.toString()) ?? 0;
    final m = s ~/ 60;
    return '$m min';
  }

  String _formatDistance(dynamic meters) {
    final m = meters is double
        ? meters
        : double.tryParse(meters.toString()) ?? 0.0;
    if (m < 1000) return '${m.toStringAsFixed(0)} m';
    return '${(m / 1000).toStringAsFixed(2)} km';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: cs.secondary, size: 24),
              const SizedBox(width: 10),
              Text(
                'Passeio finalizado!',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SummaryRow(
            icon: Icons.play_arrow_rounded,
            label: 'Início',
            value: _formatTime(summary['started_at']?.toString()),
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            icon: Icons.stop_rounded,
            label: 'Fim',
            value: _formatTime(summary['finished_at']?.toString()),
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            icon: Icons.timer_outlined,
            label: 'Duração',
            value: _formatDuration(summary['total_time_seconds']),
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            icon: Icons.straighten_rounded,
            label: 'Distância',
            value: _formatDistance(summary['distance_meters']),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.secondary),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ── Dialog: notificação de encerramento para o tutor ─────────────────────────

class _FinishRequestNotificationDialog extends StatelessWidget {
  const _FinishRequestNotificationDialog({
    required this.walkerName,
    required this.onConfirm,
  });

  final String walkerName;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Align(
        alignment: Alignment.centerLeft,
        child: Image.asset('assets/images/logo.png', height: 36),
      ),
      title: const Text('Passeio finalizado', textAlign: TextAlign.center),
      content: Text(
        '$walkerName quer encerrar o passeio. Clique em OK para escanear o QR de encerramento.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}

// ── Dialog: scanner de QR de encerramento para o tutor ───────────────────────

class _FinishTourQrDialog extends StatefulWidget {
  const _FinishTourQrDialog({
    required this.accessToken,
    required this.tourIdentifier,
    required this.tourService,
  });

  final String accessToken;
  final String tourIdentifier;
  final TourApiService tourService;

  @override
  State<_FinishTourQrDialog> createState() => _FinishTourQrDialogState();
}

class _FinishTourQrDialogState extends State<_FinishTourQrDialog> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _loading = false;
  String? _error;
  bool _hasScanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _finish(String qrToken) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final tour = await widget.tourService.finishTour(
        accessToken: widget.accessToken,
        tourIdentifier: widget.tourIdentifier,
        qrToken: qrToken,
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      Navigator.of(context).pop(tour);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      icon: Align(
        alignment: Alignment.centerLeft,
        child: Image.asset('assets/images/logo.png', height: 36),
      ),
      title: const Text('Escanear QR de encerramento', textAlign: TextAlign.center),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Aponte a câmera para o QR exibido pelo passeador:',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 220,
              width: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
                    if (_hasScanned || _loading) return;
                    final value = capture.barcodes.first.rawValue;
                    if (value == null || value.isEmpty) return;
                    _hasScanned = true;
                    _finish(value);
                  },
                ),
              ),
            ),
            if (_loading) ...[
              const SizedBox(height: 10),
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
            if (_error != null && _error!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.error),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

// ── Dialog: walker chama API e recebe token do QR ────────────────────────────

class _WalkerTerminationCodeLoadingDialog extends StatefulWidget {
  const _WalkerTerminationCodeLoadingDialog({
    required this.accessToken,
    required this.tourIdentifier,
    required this.distanceMeters,
    required this.totalTimeSeconds,
    required this.path,
    required this.tourService,
    required this.onCodeReceived,
    required this.onError,
  });

  final String accessToken;
  final String tourIdentifier;
  final double distanceMeters;
  final int totalTimeSeconds;
  final Map<String, dynamic> path;
  final TourApiService tourService;
  final void Function(String qrToken, String? expiresAtIso) onCodeReceived;
  final void Function(String error) onError;

  @override
  State<_WalkerTerminationCodeLoadingDialog> createState() =>
      _WalkerTerminationCodeLoadingDialogState();
}

class _WalkerTerminationCodeLoadingDialogState
    extends State<_WalkerTerminationCodeLoadingDialog> {
  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    try {
      final result = await widget.tourService.generateTerminationCode(
        accessToken: widget.accessToken,
        tourIdentifier: widget.tourIdentifier,
        distanceMeters: widget.distanceMeters,
        totalTimeSeconds: widget.totalTimeSeconds,
        path: widget.path,
      );
      widget.onCodeReceived(result['qr_token']!, result['expires_at']);
    } catch (e) {
      widget.onError(e.toString().replaceFirst('Exception: ', ''));
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return const AlertDialog(
      content: Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Gerando QR de encerramento...'),
          ],
        ),
      ),
    );
  }
}

// ── Dialog: exibe QR de encerramento para o walker ───────────────────────────

class _WalkerTerminationQrDisplayDialog extends StatefulWidget {
  const _WalkerTerminationQrDisplayDialog({
    required this.qrToken,
    required this.expiresAtIso,
    required this.dismissNotifier,
  });

  final String qrToken;
  final String? expiresAtIso;
  final ValueNotifier<bool> dismissNotifier;

  @override
  State<_WalkerTerminationQrDisplayDialog> createState() =>
      _WalkerTerminationQrDisplayDialogState();
}

class _WalkerTerminationQrDisplayDialogState
    extends State<_WalkerTerminationQrDisplayDialog> {
  String _formatExpires(String? iso) {
    if (iso == null || iso.isEmpty) return '--:--';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '--:--';
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  void initState() {
    super.initState();
    widget.dismissNotifier.addListener(_onDismiss);
  }

  @override
  void dispose() {
    widget.dismissNotifier.removeListener(_onDismiss);
    super.dispose();
  }

  void _onDismiss() {
    if (widget.dismissNotifier.value && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      icon: Align(
        alignment: Alignment.centerLeft,
        child: Image.asset('assets/images/logo.png', height: 36),
      ),
      title: const Text('QR de encerramento', textAlign: TextAlign.center),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Peça para o tutor escanear este QR para concluir o passeio:',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            QrImageView(
              data: widget.qrToken,
              size: 220,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              'Se o tutor nao conseguir ler, toque em Fechar e gere novamente.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            if (widget.expiresAtIso != null)
              Text(
                'Válido até ${_formatExpires(widget.expiresAtIso)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            const SizedBox(height: 4),
            Text(
              'Aguardando confirmação do tutor...',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
