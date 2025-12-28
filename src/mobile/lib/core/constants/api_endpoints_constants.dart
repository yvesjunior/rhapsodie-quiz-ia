import 'package:flutterquiz/core/config/config.dart';

const _api = '$panelUrl/Api';

// User Management & Authentication
const addUserUrl = '$_api/user_signup';
const checkUserExistUrl = '$_api/check_user_exists';
const deleteUserAccountUrl = '$_api/delete_user_account';
const updateProfileUrl = '$_api/update_profile';
const uploadProfileUrl = '$_api/upload_profile_image';
const getUserDetailsByIdUrl = '$_api/get_user_by_id';
const updateFcmIdUrl = '$_api/update_fcm_id';

// Battle & Multiplayer Game
const createMultiUserBattleRoomUrl = '$_api/create_room';
const getQuestionForMultiUserBattle = '$_api/get_question_by_room_id';
const getQuestionForOneToOneBattle = '$_api/get_random_questions';
const getBattleStatisticsUrl = '$_api/get_battle_statistics';

// Quiz Categories & Questions
const getCategoryUrl = '$_api/get_categories';
const getSubCategoryUrl = '$_api/get_subcategory_by_maincategory';
const getQuestionsByCategoryOrSubcategory = '$_api/get_questions';
const getQuestionByTypeUrl = '$_api/get_questions_by_type';
const getQuestionsByLevelUrl = '$_api/get_questions_by_level';
const reportQuestionUrl = '$_api/report_question';
const setQuizCoinScoreUrl = '$_api/set_quiz_coin_score';

// Contest & Leaderboard
const getContestUrl = '$_api/get_contest';
const getQuestionContestUrl = '$_api/get_questions_by_contest';
const getContestLeaderboardUrl = '$_api/get_contest_leaderboard';
const getAllTimeLeaderboardUrl = '$_api/get_globle_leaderboard';
const getDailyLeaderboardUrl = '$_api/get_daily_leaderboard';
const getMonthlyLeaderboardUrl = '$_api/get_monthly_leaderboard';

// Learning & Exam Modules
const getExamModuleUrl = '$_api/get_exam_module';
const getExamModuleQuestionsUrl = '$_api/get_exam_module_questions';
const setExamModuleResultUrl = '$_api/set_exam_module_result';
const getFunAndLearnUrl = '$_api/get_fun_n_learn';
const getFunAndLearnQuestionsUrl = '$_api/get_fun_n_learn_questions';
const getGuessTheWordQuestionUrl = '$_api/get_guess_the_word';
const getLatexQuestionUrl = '$_api/get_maths_questions';
const getAudioQuestionUrl = '$_api/get_audio_questions';
const getQuestionForSelfChallengeUrl = '$_api/get_questions_for_self_challenge';

// Progress & Statistics
const getLevelUrl = '$_api/get_level_data';
const getStatisticUrl = '$_api/get_users_statistics';

// Daily Features & Ads
const getQuestionForDailyQuizUrl = '$_api/get_daily_quiz';
const watchedDailyAdUrl = '$_api/update_daily_ads_counter';

// Bookmarks & Badges
const getBookmarkUrl = '$_api/get_bookmark';
const updateBookmarkUrl = '$_api/set_bookmark';
const getUserBadgesUrl = '$_api/get_user_badges';

// Payment & Coins
const getCoinStoreData = '$_api/get_coin_store_data';
const getCoinHistoryUrl = '$_api/get_tracker_data';
const updateUserCoinsAndScoreUrl = '$_api/set_user_coin_score';
const makePaymentRequestUrl = '$_api/set_payment_request';
const cancelPaymentRequestUrl = '$_api/delete_pending_payment_request';
const getTransactionsUrl = '$_api/get_payment_request';
const purchaseIAP = '$_api/set_user_in_app';
const unlockPremiumCategoryUrl = '$_api/unlock_premium_category';

// System & Configuration
const getAppSettingsUrl = '$_api/get_settings';
const getSystemConfigUrl = '$_api/get_system_configurations';
const getSupportedLanguageListUrl = '$_api/get_system_language_list';
const getSupportedQuestionLanguageUrl = '$_api/get_languages';
const getSystemLanguageJson = '$_api/get_system_language_json';
const getNotificationUrl = '$_api/get_notifications';

// Multi Match Game
const getMultiMatchLevelDataUrl = '$_api/get_multi_match_level_data';
const getMultiMatchQuestionsUrl = '$_api/get_multi_match_questions';
const getMultiMatchQuestionsByLevelUrl =
    '$_api/get_multi_match_questions_by_level';
const multiMatchReportQuestionUrl = '$_api/multi_match_report_question';

// ============================================
// NEW: Topics & Categories (Rhapsody, Foundation School)
// ============================================
const getTopicsUrl = '$_api/get_topics';
const getTopicUrl = '$_api/get_topic';
const getTopicCategoriesUrl = '$_api/get_topic_categories';
const getRhapsodyDailyUrl = '$_api/get_rhapsody_daily';
const getRhapsodyYearsUrl = '$_api/get_rhapsody_years';
const getRhapsodyMonthsUrl = '$_api/get_rhapsody_months';
const getRhapsodyDaysUrl = '$_api/get_rhapsody_days';
const getRhapsodyDayDetailUrl = '$_api/get_rhapsody_day_detail';
const getFoundationSchoolModulesUrl = '$_api/get_foundation_school_modules';
const getFoundationClassesUrl = '$_api/get_foundation_classes';
const getFoundationClassDetailUrl = '$_api/get_foundation_class_detail';
const getLatestRhapsodyMonthsUrl = '$_api/get_latest_rhapsody_months';
const getUserProgressUrl = '$_api/get_user_progress';
const updateUserProgressUrl = '$_api/update_user_progress';

// ============================================
// NEW: Groups
// ============================================
const createGroupUrl = '$_api/create_group';
const getMyGroupsUrl = '$_api/get_my_groups';
const getGroupUrl = '$_api/get_group';
const joinGroupUrl = '$_api/join_group';
const leaveGroupUrl = '$_api/leave_group';
const deleteGroupUrl = '$_api/delete_group';
const searchGroupsUrl = '$_api/search_groups';
const getPublicGroupsUrl = '$_api/get_public_groups';
const joinPublicGroupUrl = '$_api/join_public_group';

// ============================================
// NEW: 1v1 Battles
// ============================================
const create1v1BattleUrl = '$_api/create_1v1_battle';
const join1v1BattleUrl = '$_api/join_1v1_battle';
const get1v1BattleUrl = '$_api/get_1v1_battle';
const submit1v1AnswersUrl = '$_api/submit_1v1_answers';
const get1v1HistoryUrl = '$_api/get_1v1_history';

// ============================================
// NEW: Group Battles
// ============================================
const createGroupBattleUrl = '$_api/create_group_battle';
const joinGroupBattleUrl = '$_api/join_group_battle';
const startGroupBattleUrl = '$_api/start_group_battle';
const submitGroupBattleAnswersUrl = '$_api/submit_group_battle_answers';
const getGroupBattleUrl = '$_api/get_group_battle';
const getGroupBattlesUrl = '$_api/get_group_battles';
