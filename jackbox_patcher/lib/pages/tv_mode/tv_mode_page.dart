import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:jackbox_patcher/model/jackbox/game_info/family_friendly.dart';
import 'package:jackbox_patcher/model/user_model/user_jackbox_game.dart';
import 'package:jackbox_patcher/model/user_model/user_jackbox_pack.dart';
import 'package:jackbox_patcher/services/api_utility/api_service.dart';
import 'package:jackbox_patcher/services/launcher/launcher.dart';
import 'package:jackbox_patcher/services/user/user_data.dart';
import 'package:window_manager/window_manager.dart';

typedef TvGame = ({UserJackboxPack pack, UserJackboxGame game});

/// A deliberately small, keyboard-first screen for TV launchers.
/// Steam Input can map a controller to these keys without any device-specific
/// Linux controller code: D-pad = arrows, A = Enter, B = Escape.
class TvModePage extends StatefulWidget {
  const TvModePage({super.key});

  @override
  State<TvModePage> createState() => _TvModePageState();
}

class _TvModePageState extends State<TvModePage> {
  static const _columns = 5;
  final FocusNode _keyboardFocus = FocusNode();
  int _selectedGame = 0;
  int _selectedFilter = 0;
  int _players = 0;
  bool _familyFriendly = false;
  bool _audience = false;
  bool _favourites = false;
  bool _filtersFocused = false;
  bool _launching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _keyboardFocus.requestFocus());
  }

  @override
  void dispose() {
    _keyboardFocus.dispose();
    super.dispose();
  }

  List<TvGame> get _games {
    final games = <TvGame>[];
    for (final pack in UserData().packs) {
      if (!pack.owned) continue;
      for (final game in pack.games) {
        if (game.hidden || !_matches(game)) continue;
        games.add((pack: pack, game: game));
      }
    }
    games.sort((a, b) => a.game.game.name.compareTo(b.game.game.name));
    return games;
  }

  bool _matches(UserJackboxGame game) {
    final info = game.game.info;
    return (_players == 0 || (info.players.min <= _players && info.players.max >= _players)) &&
        (!_familyFriendly || info.familyFriendly != GameInfoFamilyFriendly.NOT_FAMILY_FRIENDLY) &&
        (!_audience || info.audience) &&
        (!_favourites || game.stars > 0);
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      _keyboardFocus.requestFocus();
      return;
    }
    if (key == LogicalKeyboardKey.arrowUp && !_filtersFocused) {
      final games = _games;
      if (_selectedGame >= _columns) {
        setState(() => _selectedGame = (_selectedGame - _columns).clamp(0, games.length - 1).toInt());
      } else {
        setState(() => _filtersFocused = true);
      }
      return;
    }
    if (key == LogicalKeyboardKey.arrowDown && _filtersFocused) {
      setState(() => _filtersFocused = false);
      return;
    }
    if (_filtersFocused) {
      if (key == LogicalKeyboardKey.arrowLeft) {
        setState(() => _selectedFilter = (_selectedFilter + 3) % 4);
      } else if (key == LogicalKeyboardKey.arrowRight) {
        setState(() => _selectedFilter = (_selectedFilter + 1) % 4);
      } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.select) {
        _activateFilter();
      }
      return;
    }

    final games = _games;
    if (games.isEmpty) return;
    if (key == LogicalKeyboardKey.arrowLeft) {
      setState(() => _selectedGame = (_selectedGame - 1).clamp(0, games.length - 1).toInt());
    } else if (key == LogicalKeyboardKey.arrowRight) {
      setState(() => _selectedGame = (_selectedGame + 1).clamp(0, games.length - 1).toInt());
    } else if (key == LogicalKeyboardKey.arrowDown) {
      setState(() => _selectedGame = (_selectedGame + _columns).clamp(0, games.length - 1).toInt());
    } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.select) {
      _launch(games[_selectedGame]);
    }
  }

  void _activateFilter() {
    setState(() {
      switch (_selectedFilter) {
        case 0:
          _players = _players >= 10 ? 0 : _players + 1;
          break;
        case 1:
          _familyFriendly = !_familyFriendly;
          break;
        case 2:
          _audience = !_audience;
          break;
        case 3:
          _favourites = !_favourites;
          break;
      }
      _selectedGame = 0;
    });
  }

  Future<void> _launch(TvGame game) async {
    if (_launching) return;
    setState(() => _launching = true);
    try {
      await Launcher.launchGame(game.pack, game.game);
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final games = _games;
    if (_selectedGame >= games.length && games.isNotEmpty) _selectedGame = games.length - 1;
    final typography = FluentTheme.of(context).typography;
    return KeyboardListener(
      focusNode: _keyboardFocus,
      onKeyEvent: _handleKey,
      child: ScaffoldPage.scrollable(
        header: PageHeader(
          title: Text('Jackbox TV', style: typography.titleLarge),
          commandBar: CommandBar(primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.full_screen),
              label: const Text('Exit fullscreen'),
              onPressed: () => windowManager.setFullScreen(false),
            )
          ]),
        ),
        children: [
          Text('Choose a game', style: typography.subtitle),
          const SizedBox(height: 12),
          _filterBar(),
          const SizedBox(height: 18),
          Text('${games.length} games ready to play', style: typography.bodyStrong),
          const SizedBox(height: 12),
          if (games.isEmpty)
            const InfoBar(title: Text('No installed games match these filters.'), severity: InfoBarSeverity.warning)
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _columns,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.15,
              ),
              itemCount: games.length,
              itemBuilder: (context, index) => _gameCard(games[index], index == _selectedGame),
            ),
          const SizedBox(height: 22),
          Text('D-pad: move  •  A: select / launch  •  D-pad up: filters  •  B: back', style: typography.caption),
        ],
      ),
    );
  }

  Widget _filterBar() {
    return Row(children: [
      _filterChip(0, _players == 0 ? 'Any players' : '$_players players'),
      _filterChip(1, 'Family friendly', active: _familyFriendly),
      _filterChip(2, 'Audience', active: _audience),
      _filterChip(3, 'Favourites', active: _favourites),
    ]);
  }

  Widget _filterChip(int index, String label, {bool active = false}) {
    final selected = _filtersFocused && _selectedFilter == index;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Button(
        style: ButtonStyle(
          backgroundColor: ButtonState.resolveWith((_) => selected ? Colors.white : active ? Colors.blue : Colors.grey[160]),
          foregroundColor: ButtonState.resolveWith((_) => selected ? Colors.black : Colors.white),
        ),
        onPressed: () {
          setState(() {
            _filtersFocused = true;
            _selectedFilter = index;
          });
          _activateFilter();
        },
        child: Text(label),
      ),
    );
  }

  Widget _gameCard(TvGame entry, bool selected) {
    final game = entry.game.game;
    final color = selected ? Colors.white : Colors.transparent;
    return GestureDetector(
      onTap: () => _launch(entry),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: color, width: selected ? 4 : 1),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[180],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: SizedBox.expand(
              child: CachedNetworkImage(
                imageUrl: APIService().assetLink(game.background),
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Center(child: Icon(FluentIcons.game)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(game.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: FluentTheme.of(context).typography.bodyStrong),
              Text('${entry.pack.pack.name}  •  ${game.info.players.min}–${game.info.players.max} players',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: FluentTheme.of(context).typography.caption),
            ]),
          )
        ]),
      ),
    );
  }
}
