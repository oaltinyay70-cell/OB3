import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/milstd_theme.dart';

/// Avatar definition — 80s ZX Spectrum era game characters.
class _AvatarDef {
  const _AvatarDef(this.assetPath, this.label);
  final String assetPath;
  final String label;
}

const _avatars = [
  _AvatarDef('assets/images/avatars/jet_set_willy.png', 'Jet Set'),
  _AvatarDef('assets/images/avatars/tir_na_nog.png', 'Tír Góg'),
  _AvatarDef('assets/images/avatars/lords_midnight.png', 'Darkdoom'),
  _AvatarDef('assets/images/avatars/manic_miner.png', 'Miner'),
  _AvatarDef('assets/images/avatars/sabre_wulf.png', 'Sabreguy'),
  _AvatarDef('assets/images/avatars/knight_lore.png', 'Doomdaniel'),
  _AvatarDef('assets/images/avatars/commando.png', 'Mercenary'),
  _AvatarDef('assets/images/avatars/atic_atac.png', 'Dorotar'),
];

const _nationalities = [
  'NATO',
  'United States',
  'United Kingdom',
  'Turkey',
  'Israel',
  'China',
  'Russia',
  'Iran',
  'France',
  'India',
  'Australia',
];

/// Call Sign Selection Screen (S01) — matches callsign.png mockup
///
/// Layout:
///   Title: "CREATE YOUR CALL SIGN"
///   Subtitle: "Your identity in the battlefield"
///   Avatar selection: 4×2 grid of 80s ZX Spectrum era characters
///   Call sign text input (0/12 counter)
///   Nationality dropdown
///   Warning: "Your call sign is PERMANENT and cannot be changed later."
///   Register button
class CallSignScreen extends StatefulWidget {
  const CallSignScreen({super.key, required this.onCallSignConfirmed});

  /// Called with the chosen call sign and avatar asset path when confirmed.
  final void Function(String callSign, {String? avatarAsset}) onCallSignConfirmed;

  @override
  State<CallSignScreen> createState() => _CallSignScreenState();
}

class _CallSignScreenState extends State<CallSignScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  int _selectedAvatar = -1; // no avatar selected initially
  String? _selectedNationality;

  bool get _isValid {
    final text = _controller.text;
    return text.length >= 3 &&
        text.length <= 12 &&
        RegExp(r'^[A-Z0-9\-]+$').hasMatch(text) &&
        _selectedAvatar >= 0;
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _confirmCallSign() {
    if (!_isValid) return;
    final avatarPath = _selectedAvatar >= 0 ? _avatars[_selectedAvatar].assetPath : null;
    widget.onCallSignConfirmed(_controller.text, avatarAsset: avatarPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MilstdTheme.backgroundPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // ═══ Title ═══
              const Text(
                'CREATE YOUR CALL SIGN',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: MilstdTheme.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your identity in the battlefield',
                style: TextStyle(
                  fontFamily: 'IBMPlexSans',
                  fontSize: 14,
                  color: MilstdTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // ═══ Avatar Selection ═══
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'AVATAR SELECTION',
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: MilstdTheme.accentPrimary,
                    letterSpacing: 1.0,
                    shadows: [
                      Shadow(
                        color: MilstdTheme.accentPrimary.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 4×2 avatar grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 6,
                  childAspectRatio: 0.78,
                ),
                itemCount: _avatars.length,
                itemBuilder: (context, i) {
                  final avatar = _avatars[i];
                  final isSelected = _selectedAvatar == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAvatar = i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? MilstdTheme.accentPrimary
                                  : MilstdTheme.borderSubtle,
                              width: isSelected ? 2.5 : 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: MilstdTheme.accentPrimary
                                          .withValues(alpha: 0.5),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              avatar.assetPath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: MilstdTheme.surface,
                                child: const Icon(
                                  Icons.person,
                                  color: MilstdTheme.textMuted,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          avatar.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'IBMPlexSans',
                            fontSize: 10,
                            color: isSelected
                                ? MilstdTheme.textPrimary
                                : MilstdTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // ═══ Call Sign Input ═══
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: MilstdTheme.backgroundTertiary,
                  border: Border.all(
                    color: _controller.text.isNotEmpty && _isValid
                        ? MilstdTheme.borderActive
                        : MilstdTheme.borderDefault,
                    width: 1,
                  ),
                  borderRadius: const BorderRadius.all(MilstdTheme.radiusSm),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9\-]')),
                          LengthLimitingTextInputFormatter(12),
                          _UpperCaseTextFormatter(),
                        ],
                        style: const TextStyle(
                          fontFamily: 'ShareTechMono',
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: MilstdTheme.textPrimary,
                        ),
                        cursorColor: MilstdTheme.accentPrimary,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'ENTER CALL SIGN',
                          hintStyle: TextStyle(
                            fontFamily: 'IBMPlexSans',
                            fontSize: 16,
                            color: MilstdTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '${_controller.text.length}/12',
                      style: const TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 12,
                        color: MilstdTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ═══ Nationality Dropdown ═══
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: MilstdTheme.backgroundTertiary,
                  border: Border.all(
                    color: MilstdTheme.borderDefault,
                    width: 1,
                  ),
                  borderRadius: const BorderRadius.all(MilstdTheme.radiusSm),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedNationality,
                    isExpanded: true,
                    dropdownColor: MilstdTheme.backgroundSecondary,
                    hint: const Text(
                      'SELECT NATIONALITY',
                      style: TextStyle(
                        fontFamily: 'IBMPlexSans',
                        fontSize: 16,
                        color: MilstdTheme.textMuted,
                      ),
                    ),
                    icon: const Icon(Icons.arrow_drop_down,
                        color: MilstdTheme.textMuted),
                    style: const TextStyle(
                      fontFamily: 'IBMPlexSans',
                      fontSize: 16,
                      color: MilstdTheme.textPrimary,
                    ),
                    items: _nationalities
                        .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedNationality = v),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ═══ Warning Banner ═══
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: MilstdTheme.accentWarm.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.all(MilstdTheme.radiusSm),
                  border: Border.all(
                    color: MilstdTheme.accentWarm.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: MilstdTheme.accentWarm,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Your call sign is PERMANENT\nand cannot be changed later.',
                        style: TextStyle(
                          fontFamily: 'IBMPlexSans',
                          fontSize: 12,
                          color: MilstdTheme.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ═══ Register Button ═══
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isValid ? _confirmCallSign : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MilstdTheme.accentPrimary,
                    disabledBackgroundColor:
                        MilstdTheme.accentPrimary.withValues(alpha: 0.3),
                    foregroundColor: MilstdTheme.textInverse,
                    disabledForegroundColor:
                        MilstdTheme.textInverse.withValues(alpha: 0.4),
                    textStyle: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(MilstdTheme.radiusSm),
                    ),
                  ),
                  child: const Text('REGISTER CALL SIGN'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Auto-uppercases all text input.
class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
