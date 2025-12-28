import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/commons/commons.dart';
import 'package:flutterquiz/core/core.dart';
import 'package:flutterquiz/features/ads/blocs/banner_ad_cubit.dart';
import 'package:flutterquiz/features/ads/blocs/interstitial_ad_cubit.dart';
import 'package:flutterquiz/features/ads/widgets/banner_ad_container.dart';
import 'package:flutterquiz/features/profile_management/cubits/user_details_cubit.dart';
import 'package:flutterquiz/features/quiz/cubits/quiz_category_cubit.dart';
import 'package:flutterquiz/features/quiz/models/category.dart';
import 'package:flutterquiz/features/quiz/models/quiz_type.dart';
import 'package:flutterquiz/ui/screens/quiz/guess_the_word_quiz_screen.dart';
import 'package:flutterquiz/ui/screens/quiz/levels_screen.dart';
import 'package:flutterquiz/ui/screens/quiz/multi_match/screens/multi_match_quiz_screen.dart';
import 'package:flutterquiz/ui/screens/quiz/subcategory_and_level_screen.dart';
import 'package:flutterquiz/ui/screens/quiz/subcategory_screen.dart';
import 'package:flutterquiz/ui/widgets/already_logged_in_dialog.dart';
import 'package:flutterquiz/ui/widgets/circular_progress_container.dart';
import 'package:flutterquiz/ui/widgets/error_container.dart';
import 'package:flutterquiz/ui/widgets/premium_category_access_badge.dart';
import 'package:flutterquiz/ui/widgets/unlock_premium_category_dialog.dart';
import 'package:flutterquiz/utils/extensions.dart';
import 'package:flutterquiz/utils/ui_utils.dart';

/// Purple header color - consistent across all screens
const _headerColor = Color(0xFF7B68EE);

/// Category card colors
const _categoryColors = [
  Color(0xFF6BD5A0), // Green
  Color(0xFFF5C26B), // Orange/Yellow
  Color(0xFF6BD5A0), // Green
  Color(0xFFF8B5D4), // Pink
  Color(0xFF87CEEB), // Light Blue
  Color(0xFFF8B5D4), // Pink
  Color(0xFFF5C26B), // Orange/Yellow
  Color(0xFFB8A5F0), // Purple/Lavender
  Color(0xFF6BD5A0), // Green
];

final class CategoryScreenArgs extends RouteArgs {
  const CategoryScreenArgs({required this.quizType});

  final QuizTypes quizType;
}

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({required this.args, super.key});

  final CategoryScreenArgs args;

  @override
  State<CategoryScreen> createState() => _CategoryScreen();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final args = routeSettings.args<CategoryScreenArgs>();

    return CupertinoPageRoute(builder: (_) => CategoryScreen(args: args));
  }
}

class _CategoryScreen extends State<CategoryScreen> {
  final ScrollController scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // preload ads
    Future.delayed(Duration.zero, () {
      context.read<InterstitialAdCubit>().showAd(context);
    });

    context.read<QuizCategoryCubit>().getQuizCategoryWithUserId(
      languageId: UiUtils.getCurrentQuizLanguageId(context),
      type: UiUtils.getCategoryTypeNumberFromQuizType(widget.args.quizType),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String getCategoryTitle(QuizTypes quizType) => context.tr(switch (quizType) {
    QuizTypes.mathMania => 'mathMania',
    QuizTypes.audioQuestions => 'audioQuestions',
    QuizTypes.guessTheWord => 'guessTheWord',
    QuizTypes.funAndLearn => 'funAndLearn',
    QuizTypes.multiMatch => 'multiMatch',
    _ => 'exploreCategoriesLbl',
  })!;

  @override
  Widget build(BuildContext context) {
    final bannerAdLoaded =
        context.watch<BannerAdCubit>().bannerAdLoaded &&
        !context.read<UserDetailsCubit>().removeAds();
    
    return Scaffold(
      backgroundColor: _headerColor,
      body: Stack(
        children: [
          // Purple background
          Container(
            height: context.height * 0.2,
            color: _headerColor,
          ),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                
                // Main content area with white background
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: bannerAdLoaded ? 60 : 0),
                          child: showCategory(),
                        ),
                        const Align(
                          alignment: Alignment.bottomCenter,
                          child: BannerAdContainer(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          // Back button placeholder for symmetry
          const SizedBox(width: 44),
          
          // Title
          Expanded(
            child: Text(
              getCategoryTitle(widget.args.quizType),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeights.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          // Search button
          GestureDetector(
            onTap: () {
              // Toggle search focus
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleOnTapCategory(BuildContext context, Category category) {
    /// Unlock the Premium Category
    if (category.isPremium &&
        !category.hasUnlocked &&
        !category.hasSubcategories &&
        !category.hasLevels) {
      showUnlockPremiumCategoryDialog(
        context,
        categoryId: category.id!,
        categoryName: category.categoryName!,
        requiredCoins: category.requiredCoins,
        categoryCubit: context.read<QuizCategoryCubit>(),
      );
      return;
    }

    /// noOf is number of subcategories
    if (!category.hasSubcategories) {
      if (widget.args.quizType == QuizTypes.multiMatch) {
        if (category.maxLevel == '0') {
          context.pushNamed(
            Routes.multiMatchQuiz,
            arguments: MultiMatchQuizArgs(
              categoryId: category.id!,
              isPremiumCategory: category.isPremium,
            ),
          );
        } else {
          context.pushNamed(
            Routes.levels,
            arguments: LevelsScreenArgs(
              quizType: QuizTypes.multiMatch,
              category: category,
              categoryCubit: context.read<QuizCategoryCubit>(),
            ),
          );
        }
      } else if (widget.args.quizType == QuizTypes.quizZone) {
        /// if category doesn't have any subCategory, check for levels.
        if (category.maxLevel == '0') {
          //direct move to quiz screen pass level as 0
          Navigator.of(context).pushNamed(
            Routes.quiz,
            arguments: {
              'quizType': QuizTypes.quizZone,
              'categoryId': category.id,
              'subcategoryId': '',
              'level': '0',
              'subcategoryMaxLevel': '0',
              'unlockedLevel': 0,
              'contestId': '',
              'comprehensionId': '',
              'showRetryButton': category.hasQuestions,
              'isPremiumCategory': category.isPremium,
            },
          );
        } else {
          //navigate to level screen
          context.pushNamed(
            Routes.levels,
            arguments: LevelsScreenArgs(
              quizType: QuizTypes.quizZone,
              category: category,
              categoryCubit: context.read<QuizCategoryCubit>(),
            ),
          );
        }
      } else if (widget.args.quizType == QuizTypes.audioQuestions) {
        Navigator.of(context).pushNamed(
          Routes.quiz,
          arguments: {
            'quizType': QuizTypes.audioQuestions,
            'categoryId': category.id,
            'isPlayed': category.isPlayed,
            'isPremiumCategory': category.isPremium,
          },
        );
      } else if (widget.args.quizType == QuizTypes.guessTheWord) {
        context.pushNamed(
          Routes.guessTheWord,
          arguments: GuessTheWordQuizScreenArgs(
            categoryId: category.id!,
            isPlayed: category.isPlayed,
            isPremiumCategory: category.isPremium,
          ),
        );
      } else if (widget.args.quizType == QuizTypes.funAndLearn) {
        Navigator.of(context).pushNamed(
          Routes.funAndLearnTitle,
          arguments: {
            'categoryId': category.id,
            'title': category.categoryName,
            'isPremiumCategory': category.isPremium,
          },
        );
      } else if (widget.args.quizType == QuizTypes.mathMania) {
        Navigator.of(context).pushNamed(
          Routes.quiz,
          arguments: {
            'quizType': QuizTypes.mathMania,
            'categoryId': category.id,
            'isPlayed': category.isPlayed,
            'isPremiumCategory': category.isPremium,
          },
        );
      }
    } else {
      if (widget.args.quizType
          case QuizTypes.multiMatch || QuizTypes.quizZone) {
        context.pushNamed(
          Routes.subcategoryAndLevel,
          arguments: SubCategoryAndLevelScreenArgs(
            quizType: widget.args.quizType,
            category: category,
            categoryCubit: context.read<QuizCategoryCubit>(),
          ),
        );
      } else {
        Navigator.of(context).pushNamed(
          Routes.subCategory,
          arguments: SubCategoryScreenArgs(
            quizType: widget.args.quizType,
            category: category,
            categoryCubit: context.read<QuizCategoryCubit>(),
          ),
        );
      }
    }
  }

  void _startRandomQuiz(List<Category> categories) {
    if (categories.isEmpty) return;
    
    // Pick a random category
    final random = categories[(DateTime.now().millisecondsSinceEpoch % categories.length)];
    _handleOnTapCategory(context, random);
  }

  Widget showCategory() {
    return BlocConsumer<QuizCategoryCubit, QuizCategoryState>(
      bloc: context.read<QuizCategoryCubit>(),
      listener: (context, state) {
        if (state is QuizCategoryFailure) {
          if (state.errorMessage == errorCodeUnauthorizedAccess) {
            showAlreadyLoggedInDialog(context);
          }
        }
      },
      builder: (context, state) {
        if (state is QuizCategoryProgress || state is QuizCategoryInitial) {
          return const Center(child: CircularProgressContainer());
        }
        if (state is QuizCategoryFailure) {
          return ErrorContainer(
            showBackButton: false,
            errorMessageColor: Theme.of(context).primaryColor,
            showErrorImage: true,
            errorMessage: convertErrorCodeToLanguageKey(state.errorMessage),
            onTapRetry: () {
              context.read<QuizCategoryCubit>().getQuizCategoryWithUserId(
                languageId: UiUtils.getCurrentQuizLanguageId(context),
                type: UiUtils.getCategoryTypeNumberFromQuizType(
                  widget.args.quizType,
                ),
              );
            },
          );
        }
        
        final categoryList = (state as QuizCategorySuccess).categories;
        
        // Filter categories based on search
        final filteredList = _searchQuery.isEmpty
            ? categoryList
            : categoryList.where((c) => 
                c.categoryName!.toLowerCase().contains(_searchQuery.toLowerCase())
              ).toList();
        
        return _buildCategoryGrid(filteredList, categoryList);
      },
    );
  }

  Widget _buildCategoryGrid(List<Category> filteredList, List<Category> allCategories) {
    // Calculate grid layout
    // First 3 rows: 3 items each
    // Then: Random Quiz card spanning 2 columns
    // Continue with more categories
    
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Insert Random Quiz card at position 7 (after 2 rows of 3)
                if (index == 6) {
                  return null; // Skip, handled separately
                }
                
                final actualIndex = index > 6 ? index - 1 : index;
                
                if (actualIndex >= filteredList.length) return null;
                
                return _buildCategoryCard(filteredList[actualIndex], actualIndex);
              },
              childCount: filteredList.length + 1, // +1 for random quiz placeholder
            ),
          ),
        ),
        
        // Random Quiz Card (wider)
        if (filteredList.length >= 6)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _buildRandomQuizCard(allCategories),
            ),
          ),
        
        // More categories after Random Quiz
        if (filteredList.length > 6)
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final actualIndex = index + 6;
                  if (actualIndex >= filteredList.length) return null;
                  return _buildCategoryCard(filteredList[actualIndex], actualIndex);
                },
                childCount: filteredList.length - 6,
              ),
            ),
          ),
        
        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(Category category, int index) {
    final color = _categoryColors[index % _categoryColors.length];
    final imageUrl = category.image!.isEmpty ? Assets.placeholder : category.image!;
    
    return GestureDetector(
      onTap: () => _handleOnTapCategory(context, category),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // Category content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category name
                  Text(
                    category.categoryName!.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeights.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const Spacer(),
                  
                  // Category image
                  Align(
                    alignment: Alignment.bottomRight,
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: QImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Premium badge
            if (category.isPremium && !category.hasUnlocked)
              Positioned(
                top: 8,
                right: 8,
                child: PremiumCategoryAccessBadge(
                  hasUnlocked: category.hasUnlocked,
                  isPremium: category.isPremium,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRandomQuizCard(List<Category> categories) {
    return GestureDetector(
      onTap: () => _startRandomQuiz(categories),
      child: Container(
        height: 140,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFB8A5F0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.trWithFallback('startLbl', 'START').toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeights.semiBold,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    context.trWithFallback('randomQuizLbl', 'RANDOM QUIZ').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeights.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow button
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                ),
              ),
            ),
            
            // Character/mascot placeholder
            Positioned(
              bottom: 0,
              right: 60,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.quiz_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
