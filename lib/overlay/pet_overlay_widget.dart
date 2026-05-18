import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/pet/pet_loader.dart';
import '../core/pet/pet_state.dart';
import '../core/pet/pet_state_machine.dart';
import '../core/personality/pet_profile_repository.dart';
import '../core/tts/tts_engine.dart';
import 'pet_painter.dart';
import 'speech_bubble_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Behaviour constants (mirroring Android Studio PetOverlayService)
// ─────────────────────────────────────────────────────────────────────────────
const _kIdleTimeoutSec    = 20;    // seconds of inactivity before roaming starts
const _kSleepHoldMs       = 6000;  // hold 6s to enter sleep
const _kWakeHoldMs        = 3000;  // hold 3s to wake from sleep
const _kRapidTapThresh    = 5;     // 5 taps → beat/run
const _kTapWindowMs       = 1500;  // window for counting taps (ms)
const _kSadThreshold      = 3;     // consecutive beats before sad
const _kWalkStepDp        = 8.0;   // idle walk step size in dp
const _kRunStepDp         = 18.0;  // beat-run step size in dp
const _kWalkDelayMs       = 190;   // ms per idle walk frame
const _kRunDelayMs        = 70;    // ms per beat-run frame
const _kRecordWindowMs    = 3000;  // Talking Tom listen duration
const _kEchoWindowMs      = 3000;  // echo playback window

// ─────────────────────────────────────────────────────────────────────────────
// Tap reactions (mirrors Android Studio string lists)
// ─────────────────────────────────────────────────────────────────────────────
const _tapReactions = [
  'Hey! 👋', 'Hiii~', 'What? 🤔', '*boop*', 'Heyyy!', '...hi?',
];
const _beatReactions = [
  'Ow! Stop! 😤', 'Hey! That hurts!', 'Not cool! 😠', 'Ouch! 😣',
];
const _sadReactions = [
  '...you\'re mean 😢', 'Please stop... 🥺', 'I don\'t deserve this! 😭',
];

// ─────────────────────────────────────────────────────────────────────────────
// Main overlay widget
// ─────────────────────────────────────────────────────────────────────────────
class PetOverlayWidget extends ConsumerStatefulWidget {
  const PetOverlayWidget({super.key});

  @override
  ConsumerState<PetOverlayWidget> createState() => _PetOverlayWidgetState();
}

class _PetOverlayWidgetState extends ConsumerState<PetOverlayWidget>
    with TickerProviderStateMixin {

  // ── Position & display ────────────────────────────────────────────────────
  double _x = 60;
  double _y = 300;
  double _scale = 1.0;
  bool _flipX = false;   // mirror sprite for leftward movement
  String? _bubbleText;

  Size _screen = const Size(400, 800);
  double get _petSize => 96.0;

  // ── Tap tracking ──────────────────────────────────────────────────────────
  int _tapCount = 0;
  int _beatCount = 0;
  Timer? _tapResetTimer;
  Timer? _beatResetTimer;
  Timer? _tripleTapTimer;

  // ── Long-press timers ─────────────────────────────────────────────────────
  Timer? _sleepTimer;
  bool _sleepMode = false;

  // ── Behaviour loop ────────────────────────────────────────────────────────
  Timer? _idleTimer;
  Timer? _behaviorTimer;
  bool _roaming = false;

  // ── Talking Tom ───────────────────────────────────────────────────────────
  bool _talkingTomMode = false;
  Timer? _tomTimer;

  // ── Beat/run ──────────────────────────────────────────────────────────────
  Timer? _runTimer;

  // ── Pet animation state ──────────────────────────────────────────────────────
  PetState _currentPetState = PetState.idle;
  String? _activePetId;

  final _rng = Random();

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen(_onOverlayMessage);
    _loadInitialPet();
    _scheduleIdleRoam();
  }

  Future<void> _loadInitialPet() async {
    try {
      final repo = ref.read(petProfileRepositoryProvider);
      final profile = await repo.load();
      if (mounted) {
        setState(() => _activePetId = profile.petId);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tapResetTimer?.cancel();
    _beatResetTimer?.cancel();
    _tripleTapTimer?.cancel();
    _sleepTimer?.cancel();
    _idleTimer?.cancel();
    _behaviorTimer?.cancel();
    _tomTimer?.cancel();
    _runTimer?.cancel();
    super.dispose();
  }

  // ── Overlay messages from main isolate ───────────────────────────────────
  void _onOverlayMessage(dynamic message) {
    if (message is Map) {
      final action = message['action'] as String?;
      if (action == 'showBubble') {
        final text = message['text'] as String?;
        if (text != null && mounted) setState(() => _bubbleText = text);
      } else if (action == 'changePet') {
        final petId = message['petId'] as String?;
        if (petId != null && mounted) {
          setState(() => _activePetId = petId);
        }
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BEHAVIOUR LOOP — random weighted state machine
  // ─────────────────────────────────────────────────────────────────────────

  void _scheduleIdleRoam() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: _kIdleTimeoutSec), _startRoaming);
  }

  void _stopRoaming() {
    _roaming = false;
    _behaviorTimer?.cancel();
  }

  void _startRoaming() {
    if (_sleepMode || _talkingTomMode) return;
    _roaming = true;
    _runNextBehavior();
  }

  void _runNextBehavior() {
    if (!_roaming || !mounted) return;
    _behaviorTimer?.cancel();

    final roll = _rng.nextInt(100);
    final delay = _rng.nextInt(450) + 150; // 150–600ms gap between behaviors

    if (roll < 40) {
      // WALK — 6-22 steps in one direction
      _doWalk();
    } else if (roll < 60) {
      // IDLE REST — stand 1.2-3.5s
      _setAnim(PetState.idle);
      final rest = _rng.nextInt(2300) + 1200;
      _behaviorTimer = Timer(Duration(milliseconds: rest + delay), _runNextBehavior);
    } else if (roll < 72) {
      // THINKING — look left/right
      _doThinking();
    } else if (roll < 82) {
      // EXCITED BURST — 3× jump+excited
      _doExcitedBurst();
    } else if (roll < 90) {
      // TELEPORT HOP
      _doTeleport();
    } else if (roll < 96) {
      // STRETCH / WAIT
      _setAnim(PetState.waiting);
      final rest = _rng.nextInt(1000) + 1000;
      _behaviorTimer = Timer(Duration(milliseconds: rest + delay), () {
        _setAnim(PetState.idle);
        _behaviorTimer = Timer(Duration(milliseconds: 600 + delay), _runNextBehavior);
      });
    } else {
      // SPIN — quick direction flick
      _doSpin();
    }
  }

  void _doWalk() {
    final goRight = _rng.nextBool();
    final steps = _rng.nextInt(16) + 6;
    var step = 0;

    _behaviorTimer = Timer.periodic(Duration(milliseconds: _kWalkDelayMs), (t) {
      if (!_roaming || !mounted) { t.cancel(); return; }
      _setAnim(goRight ? PetState.runRight : PetState.runLeft);
      final dp = _kWalkStepDp * (goRight ? 1 : -1);
      setState(() {
        _x = (_x + dp).clamp(0.0, max(0.0, _screen.width - _petSize));
        _flipX = !goRight;
      });

      final hitWall = (goRight && _x >= _screen.width - _petSize) ||
          (!goRight && _x <= 0);
      step++;
      if (hitWall || step >= steps) {
        t.cancel();
        _setAnim(PetState.excited);
        _behaviorTimer = Timer(const Duration(milliseconds: 280), _runNextBehavior);
      }
    });
  }

  void _doThinking() {
    _setAnim(PetState.thinking);
    final thinkMs = _rng.nextInt(1300) + 1500;
    _behaviorTimer = Timer(Duration(milliseconds: thinkMs), () {
      _setAnim(PetState.runLeft);
      Future.delayed(const Duration(milliseconds: 120), () {
        _setAnim(PetState.runRight);
        Future.delayed(const Duration(milliseconds: 120), () {
          _setAnim(PetState.idle);
          _behaviorTimer = Timer(const Duration(milliseconds: 400), _runNextBehavior);
        });
      });
    });
  }

  void _doExcitedBurst() {
    var count = 0;
    _behaviorTimer = Timer.periodic(const Duration(milliseconds: 250), (t) {
      if (!mounted) { t.cancel(); return; }
      _setAnim(count.isEven ? PetState.excited : PetState.jump);
      count++;
      if (count >= 6) {
        t.cancel();
        _setAnim(PetState.idle);
        _behaviorTimer = Timer(const Duration(milliseconds: 300), _runNextBehavior);
      }
    });
  }

  void _doTeleport() {
    _setAnim(PetState.jump);
    _behaviorTimer = Timer(const Duration(milliseconds: 240), () {
      setState(() {
        _x = _rng.nextDouble() * (_screen.width - _petSize * 1.5) + _petSize * 0.25;
        _y = _rng.nextDouble() * (_screen.height * 0.72) + _screen.height * 0.08;
      });
      _behaviorTimer = Timer(const Duration(milliseconds: 180), () {
        _setAnim(PetState.idle);
        _behaviorTimer = Timer(const Duration(milliseconds: 500), _runNextBehavior);
      });
    });
  }

  void _doSpin() {
    var count = 0;
    _behaviorTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) { t.cancel(); return; }
      _setAnim(count.isEven ? PetState.runRight : PetState.runLeft);
      count++;
      if (count >= 8) {
        t.cancel();
        _setAnim(PetState.idle);
        _behaviorTimer = Timer(const Duration(milliseconds: 300), _runNextBehavior);
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BEAT → RUN AWAY
  // ─────────────────────────────────────────────────────────────────────────

  void _animateRunAway() {
    _stopRoaming();
    _runTimer?.cancel();
    _setAnim(PetState.beating);

    final goRight = _x < _screen.width / 2;
    final runState = goRight ? PetState.runRight : PetState.runLeft;
    setState(() => _flipX = !goRight);

    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      _runTimer = Timer.periodic(Duration(milliseconds: _kRunDelayMs), (t) {
        if (!mounted) { t.cancel(); return; }
        _setAnim(runState);
        final dp = _kRunStepDp * (goRight ? 1 : -1);
        setState(() => _x = (_x + dp).clamp(0.0, max(0.0, _screen.width - _petSize)));
        final hitBorder = (goRight && _x >= _screen.width - _petSize) ||
            (!goRight && _x <= 0);
        if (hitBorder) {
          t.cancel();
          _setAnim(PetState.jump);
          Future.delayed(const Duration(milliseconds: 350), () {
            if (!mounted) return;
            // Teleport to opposite side
            final margin = _petSize * 2;
            setState(() {
              _x = goRight
                  ? _rng.nextDouble() * margin
                  : _screen.width - margin - _rng.nextDouble() * margin;
              _y = _screen.height * 0.15 +
                  _rng.nextDouble() * (_screen.height * 0.6);
            });
            _setAnim(PetState.idle);
            _scheduleIdleRoam();
          });
        }
      });
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SLEEP MODE
  // ─────────────────────────────────────────────────────────────────────────

  void _enterSleepMode() {
    if (_sleepMode) return;
    _sleepMode = true;
    _stopRoaming();
    _talkingTomMode = false;
    _tomTimer?.cancel();
    _showBubble('Zzz... hold 3s to wake me 😴');
    _setAnim(PetState.runRight);

    // Fly to top-right corner
    final targetX = _screen.width - _petSize - 8;
    const targetY = 8.0;
    var step = 0;
    const steps = 20;
    final dx = (targetX - _x) / steps;
    final dy = (targetY - _y) / steps;

    _behaviorTimer = Timer.periodic(const Duration(milliseconds: 30), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _x = (_x + dx).clamp(0.0, max(0.0, _screen.width - _petSize));
        _y = (_y + dy).clamp(0.0, max(0.0, _screen.height - _petSize));
      });
      step++;
      if (step >= steps) {
        t.cancel();
        setState(() {
          _x = targetX;
          _y = targetY;
          _scale = 0.4;   // shrink to 40%
        });
        _setAnim(PetState.sleeping);
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) setState(() => _bubbleText = null);
        });
      }
    });
  }

  void _exitSleepMode() {
    if (!_sleepMode) return;
    _sleepMode = false;
    setState(() => _scale = 1.0);
    _setAnim(PetState.excited);
    _showBubble("I'm awake! Let's play! 🎉");
    _speak("I'm awake! Let's play!");

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _setAnim(PetState.runLeft);
      final targetX = _screen.width / 2 - _petSize / 2;
      final targetY = _screen.height * 0.4;
      var step = 0;
      const steps = 25;
      final dx = (targetX - _x) / steps;
      final dy = (targetY - _y) / steps;

      _behaviorTimer = Timer.periodic(const Duration(milliseconds: 28), (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() {
          _x = (_x + dx).clamp(0.0, max(0.0, _screen.width - _petSize));
          _y = (_y + dy).clamp(0.0, max(0.0, _screen.height - _petSize));
        });
        step++;
        if (step >= steps) {
          t.cancel();
          _setAnim(PetState.idle);
          _scheduleIdleRoam();
        }
      });
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TALKING TOM MODE
  // ─────────────────────────────────────────────────────────────────────────

  void _toggleTalkingTom() {
    _talkingTomMode = !_talkingTomMode;
    if (_talkingTomMode) {
      _stopRoaming();
      _showBubble('Listening... 🎤');
      _setAnim(PetState.waiting);
      _runTomLoop();
    } else {
      _tomTimer?.cancel();
      _setAnim(PetState.idle);
      _hideBubble();
      _scheduleIdleRoam();
    }
  }

  void _runTomLoop() {
    if (!_talkingTomMode || !mounted) return;
    _setAnim(PetState.waiting);
    _showBubble('Listening... 🎤');

    // Listen phase (3s)
    _tomTimer = Timer(Duration(milliseconds: _kRecordWindowMs), () {
      if (!_talkingTomMode || !mounted) return;
      // Echo phase — bounce while "speaking"
      _showBubble('Hehe! 😄');
      var toggle = true;
      var echoMs = 0;
      _tomTimer = Timer.periodic(const Duration(milliseconds: 400), (t) {
        if (!_talkingTomMode || !mounted) { t.cancel(); return; }
        _setAnim(toggle ? PetState.jump : PetState.excited);
        toggle = !toggle;
        echoMs += 400;
        if (echoMs >= _kEchoWindowMs) {
          t.cancel();
          // Request echo from TTS engine (platform channel)
          ref.read(ttsEngineProvider).speak('Hehe, you said something funny!');
          _setAnim(PetState.idle);
          Future.delayed(const Duration(milliseconds: 400), _runTomLoop);
        }
      });
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAP HANDLING
  // ─────────────────────────────────────────────────────────────────────────

  void _onTap() {
    _resetIdleTimer();
    _tapResetTimer?.cancel();
    _tripleTapTimer?.cancel();
    _tapCount++;

    if (_tapCount >= _kRapidTapThresh) {
      _tapCount = 0;
      _beatCount++;
      _beatResetTimer?.cancel();
      if (_beatCount >= _kSadThreshold) {
        _beatCount = 0;
        final msg = _sadReactions[_rng.nextInt(_sadReactions.length)];
        _showBubble(msg); _speak(msg);
        _setAnim(PetState.sad);
      } else {
        _beatResetTimer = Timer(const Duration(seconds: 25), () => _beatCount = 0);
        final msg = _beatReactions[_rng.nextInt(_beatReactions.length)];
        _showBubble(msg); _speak(msg);
        _animateRunAway();
      }
    } else if (_tapCount == 3) {
      // Schedule triple-tap → wait 350ms to confirm no 4th tap
      _tripleTapTimer = Timer(const Duration(milliseconds: 350), () {
        if (_tapCount == 3) { _tapCount = 0; _toggleTalkingTom(); }
      });
      _tapResetTimer = Timer(Duration(milliseconds: _kTapWindowMs), () => _tapCount = 0);
    } else if (_tapCount == 1) {
      final msg = _tapReactions[_rng.nextInt(_tapReactions.length)];
      _showBubble(msg); _speak(msg);
      ref.read(petStateMachineProvider.notifier).send(const UserTapped());
      _tapResetTimer = Timer(Duration(milliseconds: _kTapWindowMs), () => _tapCount = 0);
    } else {
      _tapResetTimer = Timer(Duration(milliseconds: _kTapWindowMs), () => _tapCount = 0);
    }
  }

  void _resetIdleTimer() {
    _stopRoaming();
    _scheduleIdleRoam();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LONG PRESS (sleep / wake)
  // ─────────────────────────────────────────────────────────────────────────

  void _onLongPressStart(LongPressStartDetails _) {
    final holdMs = _sleepMode ? _kWakeHoldMs : _kSleepHoldMs;
    _sleepTimer = Timer(Duration(milliseconds: holdMs), () {
      if (_sleepMode) _exitSleepMode(); else _enterSleepMode();
    });
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    _sleepTimer?.cancel();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  // Central animation setter — all behavior methods call this
  void _setAnim(PetState state) {
    if (!mounted) return;
    setState(() => _currentPetState = state);
  }

  void _showBubble(String text) {
    if (mounted) setState(() => _bubbleText = text);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _bubbleText = null);
    });
  }

  void _hideBubble() {
    if (mounted) setState(() => _bubbleText = null);
  }

  Future<void> _speak(String text) async {
    await ref.read(ttsEngineProvider).speak(text);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _screen = MediaQuery.of(context).size;
    final profileAsync = ref.watch(petProfileProvider);

    // Update touchable region after rendering so that touches pass through properly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_bubbleText != null) {
        FlutterOverlayWindow.updateTouchableRegion(
            0, 0, _screen.width.toInt(), _screen.height.toInt());
      } else {
        FlutterOverlayWindow.updateTouchableRegion(
            _x.toInt(), _y.toInt(), (_x + _petSize).toInt(), (_y + _petSize).toInt());
      }
    });

    final petId = _activePetId ?? 'axobotl';

    return Stack(
      children: [
        Builder(
          builder: (context) {
            final petAsync = ref.watch(loadedPetProvider(petId));
            return petAsync.when(
              loading: () => _buildPlaceholder(),
              error: (e, st) {
                print("PET LOAD ERROR: $e");
                return _buildPlaceholder();
              },
              data: (loaded) => Positioned(
                left: _x,
                top: _y,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Speech bubble — always above pet
                    if (_bubbleText != null)
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: _screen.width - 32),
                        child: SpeechBubbleWidget(
                          text: _bubbleText!,
                          onDismiss: _hideBubble,
                        ),
                      ),
                    // Pet sprite
                    GestureDetector(
                      onTap: _sleepMode ? null : _onTap,
                      onLongPressStart: _onLongPressStart,
                      onLongPressEnd: _onLongPressEnd,
                      onPanUpdate: (d) {
                        _sleepTimer?.cancel();
                        _resetIdleTimer();
                        setState(() {
                          _x = (_x + d.delta.dx).clamp(0.0, max(0.0, _screen.width - _petSize));
                          _y = (_y + d.delta.dy).clamp(0.0, max(0.0, _screen.height - _petSize));
                        });
                      },
                      child: Builder(
                        builder: (context) {
                          final runLeft = loaded.config.animations[PetState.runLeft];
                          final runRight = loaded.config.animations[PetState.runRight];
                          final hasSeparateWalk = runLeft != null && runRight != null && runLeft.row != runRight.row;
                          final shouldFlip = _flipX && !hasSeparateWalk;

                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..scale(shouldFlip ? -_scale : _scale, _scale),
                            child: AnimatedPetWidget(
                              spritesheet: loaded.spritesheet,
                              config: loaded.config,
                              currentState: _currentPetState,
                              size: _petSize,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        )
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Positioned(
      left: _x,
      top: _y,
      child: GestureDetector(
        onTap: _onTap,
        child: Container(
          width: _petSize,
          height: _petSize,
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.pets, color: Colors.white, size: 48),
        ),
      ),
    );
  }
}
