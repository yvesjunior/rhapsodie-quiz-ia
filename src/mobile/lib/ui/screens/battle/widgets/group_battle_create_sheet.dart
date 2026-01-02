import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutterquiz/core/core.dart';
import 'package:flutterquiz/features/battle_room/cubits/multi_user_battle_room_cubit.dart';
import 'package:flutterquiz/features/profile_management/cubits/user_details_cubit.dart';
import 'package:flutterquiz/features/system_config/cubits/system_config_cubit.dart';
import 'package:flutterquiz/features/system_config/model/room_code_char_type.dart';
import 'package:flutterquiz/ui/screens/battle/widgets/battle_invite_card.dart';
import 'package:flutterquiz/ui/widgets/shared/shared.dart';
import 'package:flutterquiz/utils/extensions.dart';
import 'package:flutterquiz/utils/ui_utils.dart';
import 'package:google_fonts/google_fonts.dart';

/// Simplified Group Battle creation sheet
/// Step 1: Select Topic (Rhapsody / Foundation School)
/// Step 2: Entry Fee + Create Room
/// Questions are randomly selected from the chosen topic
class GroupBattleCreateSheet extends StatefulWidget {
  final Function({
    required String categoryId,
    required String categoryName,
    required String categoryImage,
    required int entryFee,
    required RoomCodeCharType charType,
  }) onCreateRoom;

  const GroupBattleCreateSheet({
    required this.onCreateRoom,
    super.key,
  });

  @override
  State<GroupBattleCreateSheet> createState() => _GroupBattleCreateSheetState();
}

class _GroupBattleCreateSheetState extends State<GroupBattleCreateSheet> {
  // Step tracking: 0 = Topic, 1 = Entry Fee
  int _currentStep = 0;
  
  // Selected topic
  String? _selectedTopic; // 'rhapsody' or 'foundation'
  String? _selectedTopicName;
  
  // Entry fee
  late List<int> _entryFees;
  late int _selectedEntryFee;
  
  // Loading state
  bool _isCreating = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    final minEntry = context.read<SystemConfigCubit>().groupBattleMinimumEntryFee;
    _entryFees = [minEntry, minEntry * 2, minEntry * 3, minEntry * 4];
    _selectedEntryFee = _entryFees.first;
  }
  
  RoomCodeCharType get _roomCodeCharType =>
      context.read<SystemConfigCubit>().groupBattleRoomCodeCharType;

  void _selectTopic(String topic, String topicName) {
    setState(() {
      _selectedTopic = topic;
      _selectedTopicName = topicName;
      _currentStep = 1; // Go directly to Entry Fee
    });
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        if (_currentStep == 0) {
          _selectedTopic = null;
          _selectedTopicName = null;
        }
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _createRoom() {
    if (_selectedTopic == null) return;
    if (_isCreating) return;
    
    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });
    
    // Use topic as category - questions will be randomly selected
    widget.onCreateRoom(
      categoryId: _selectedTopic!, // 'rhapsody' or 'foundation'
      categoryName: _selectedTopicName ?? _selectedTopic!,
      categoryImage: '',
      entryFee: _selectedEntryFee,
      charType: _roomCodeCharType,
    );
    
    // Don't pop here - the BlocListener in build will handle navigation
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return BlocConsumer<MultiUserBattleRoomCubit, MultiUserBattleRoomState>(
      listener: (context, state) {
        if (state is MultiUserBattleRoomSuccess) {
          // Check if game is ready to play
          if (state.battleRoom.readyToPlay == true) {
            // If user has joined (not the creator), navigate to quiz
            if (state.battleRoom.user1?.uid != 
                context.read<UserDetailsCubit>().userId()) {
              Navigator.of(context).pushReplacementNamed(Routes.multiUserBattleRoomQuiz);
            }
          }
          
          // Room destroyed by owner
          if (!state.isRoomExist) {
            if (context.read<UserDetailsCubit>().userId() !=
                state.battleRoom.user1?.uid) {
              _showRoomDestroyedDialog(context);
            }
          }
        } else if (state is MultiUserBattleRoomFailure) {
          setState(() {
            _isCreating = false;
            _errorMessage = context.tr(convertErrorCodeToLanguageKey(state.errorMessageCode)) 
                ?? 'Failed to create room';
          });
        }
      },
      builder: (context, state) {
        // Show waiting room if room created successfully
        if (state is MultiUserBattleRoomSuccess) {
          return _buildWaitingRoom(context, colorScheme, state);
        }
        
        // Show creation flow
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: UiUtils.bottomSheetTopRadius,
          ),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              // Header
              _buildHeader(colorScheme),
              const Divider(height: 1),
              
              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: colorScheme.error, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Step indicator (simplified to 2 steps)
              _buildStepIndicator(colorScheme),
              
              // Content based on step
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _currentStep == 0
                      ? _buildTopicSelection(colorScheme)
                      : _buildEntryFeeSelection(colorScheme),
                ),
              ),
              
              // Footer
              const SharedBottomNav(),
            ],
          ),
        );
      },
    );
  }
  
  void _showRoomDestroyedDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Room Closed',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'The host has closed this room.',
          style: GoogleFonts.nunito(),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
                Navigator.of(context).pop(); // Close sheet
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                'OK',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWaitingRoom(BuildContext context, ColorScheme colorScheme, MultiUserBattleRoomSuccess state) {
    final cubit = context.read<MultiUserBattleRoomCubit>();
    final isCreator = state.battleRoom.user1?.uid == context.read<UserDetailsCubit>().userId();
    
    // Count joined players
    int joinedPlayers = 0;
    if (state.battleRoom.user1?.name.isNotEmpty == true) joinedPlayers++;
    if (state.battleRoom.user2?.name.isNotEmpty == true) joinedPlayers++;
    if (state.battleRoom.user3?.name.isNotEmpty == true) joinedPlayers++;
    if (state.battleRoom.user4?.name.isNotEmpty == true) joinedPlayers++;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: UiUtils.bottomSheetTopRadius,
      ),
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => _showExitDialog(context, isCreator),
                  child: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
                ),
                Text(
                  isCreator 
                      ? 'Waiting for Players'
                      : 'Room Joined',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 24),
              ],
            ),
          ),
          const SizedBox(height: 15),
          const Divider(),
          const SizedBox(height: 15),
          
          // Invite Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: BattleInviteCard(
              categoryImage: cubit.categoryImage,
              categoryName: cubit.categoryName,
              entryFee: cubit.getEntryFee(),
              roomCode: cubit.getRoomCode(),
              shareText: context.tr('shareRoomCodeLbl') ?? 'Share this code with friends!',
              categoryEnabled: context.read<SystemConfigCubit>().isCategoryEnabledForGroupBattle,
            ),
          ),
          const SizedBox(height: 20),
          
          // Players Grid
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildPlayerCard(
                  name: state.battleRoom.user1?.name ?? '',
                  profileUrl: state.battleRoom.user1?.profileUrl ?? '',
                  isCreator: true,
                  colorScheme: colorScheme,
                  placeholder: context.tr('you') ?? 'You',
                ),
                _buildPlayerCard(
                  name: state.battleRoom.user2?.name ?? '',
                  profileUrl: state.battleRoom.user2?.profileUrl ?? '',
                  isCreator: false,
                  colorScheme: colorScheme,
                  placeholder: context.tr('player2') ?? 'Player 2',
                ),
                _buildPlayerCard(
                  name: state.battleRoom.user3?.name ?? '',
                  profileUrl: state.battleRoom.user3?.profileUrl ?? '',
                  isCreator: false,
                  colorScheme: colorScheme,
                  placeholder: context.tr('player3') ?? 'Player 3',
                ),
                _buildPlayerCard(
                  name: state.battleRoom.user4?.name ?? '',
                  profileUrl: state.battleRoom.user4?.profileUrl ?? '',
                  isCreator: false,
                  colorScheme: colorScheme,
                  placeholder: context.tr('player4') ?? 'Player 4',
                ),
              ],
            ),
          ),
          
          // Start Button (only for creator with 2+ players)
          if (isCreator)
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: joinedPlayers >= 2
                    ? () {
                        cubit.startGame();
                        Navigator.of(context).pushReplacementNamed(Routes.multiUserBattleRoomQuiz);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  joinedPlayers >= 2
                      ? 'Start Game'
                      : 'Waiting for Players...',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          
          // Footer
          const SharedBottomNav(),
        ],
      ),
    );
  }
  
  void _showExitDialog(BuildContext context, bool isCreator) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isCreator ? 'Delete Room?' : 'Leave Room?',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isCreator
              ? 'This will remove all players and delete the room.'
              : 'Are you sure you want to leave this room?',
          style: GoogleFonts.nunito(),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(color: colorScheme.outline),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext); // Close dialog
                    if (isCreator) {
                      context.read<MultiUserBattleRoomCubit>().deleteMultiUserBattleRoom();
                    } else {
                      final userId = context.read<UserDetailsCubit>().userId();
                      context.read<MultiUserBattleRoomCubit>().deleteUserFromRoom(userId);
                    }
                    Navigator.pop(context); // Close sheet
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isCreator ? 'Delete' : 'Leave',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlayerCard({
    required String name,
    required String profileUrl,
    required bool isCreator,
    required ColorScheme colorScheme,
    required String placeholder,
  }) {
    final hasPlayer = name.isNotEmpty;
    final hasValidImage = hasPlayer && profileUrl.isNotEmpty;
    final isSvg = profileUrl.toLowerCase().endsWith('.svg');
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: isCreator && hasPlayer
            ? Border.all(color: colorScheme.primary, width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(alpha: 0.2),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasValidImage
                ? (isSvg
                    ? SvgPicture.network(
                        profileUrl,
                        fit: BoxFit.cover,
                        placeholderBuilder: (_) => Icon(
                          Icons.person_outline,
                          size: 32,
                          color: colorScheme.primary.withValues(alpha: 0.5),
                        ),
                      )
                    : Image.network(
                        profileUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.person_outline,
                          size: 32,
                          color: colorScheme.primary.withValues(alpha: 0.5),
                        ),
                      ))
                : Icon(
                    Icons.person_outline,
                    size: 32,
                    color: colorScheme.primary.withValues(alpha: 0.5),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            hasPlayer ? name : placeholder,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: hasPlayer ? FontWeight.bold : FontWeight.w500,
              color: hasPlayer 
                  ? colorScheme.onSurface 
                  : colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (isCreator && hasPlayer)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                context.tr('host') ?? 'Host',
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentStep > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _goBack,
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Text(
              'Create Group Battle',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(ColorScheme colorScheme) {
    final steps = ['Topic', 'Entry Fee'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index <= _currentStep;
          final isComplete = index < _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isComplete
                        ? Colors.green
                        : isActive
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isComplete
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    steps[index],
                    style: TextStyle(
                      color: isActive ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 30,
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: isComplete ? Colors.green : colorScheme.surfaceContainerHighest,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTopicSelection(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select a Topic',
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Questions will be randomly selected from your chosen topic',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          
          // Topic cards - reduced height
          Row(
            children: [
              // Rhapsody card
              Expanded(
                child: _TopicCard(
                  title: 'Rhapsody of\nRealities',
                  subtitle: 'Daily devotional',
                  icon: Icons.menu_book,
                  color: Colors.deepPurple,
                  onTap: () => _selectTopic('rhapsody', 'Rhapsody of Realities'),
                ),
              ),
              const SizedBox(width: 12),
              // Foundation School card
              Expanded(
                child: _TopicCard(
                  title: 'Foundation\nSchool',
                  subtitle: 'Module learning',
                  icon: Icons.school,
                  color: Colors.teal,
                  onTap: () => _selectTopic('foundation', 'Foundation School'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEntryFeeSelection(ColorScheme colorScheme) {
    final userCoinsStr = context.read<UserDetailsCubit>().getCoins() ?? '0';
    final userCoins = int.tryParse(userCoinsStr) ?? 0;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected topic display
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedTopic == 'rhapsody' ? Icons.menu_book : Icons.school,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedTopicName ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Random questions from this topic',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          Text(
            'Entry Coins for Battle',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your coins: $userCoins',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          
          const SizedBox(height: 14),
          
          // Entry fee buttons
          Row(
            children: _entryFees.map((fee) {
              final isSelected = _selectedEntryFee == fee;
              final canAfford = userCoins >= fee;
              
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: canAfford ? () => setState(() => _selectedEntryFee = fee) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : canAfford
                                ? colorScheme.surfaceContainerHighest
                                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: colorScheme.primary, width: 2)
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$fee',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : canAfford
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Icon(
                            Icons.monetization_on,
                            size: 18,
                            color: isSelected
                                ? Colors.white
                                : Colors.amber,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const Spacer(),
          
          // Create Room button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isCreating || userCoins < _selectedEntryFee 
                  ? null 
                  : _createRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isCreating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'Create Room',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// Topic card widget - compact height
class _TopicCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TopicCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 140, // Fixed compact height
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
