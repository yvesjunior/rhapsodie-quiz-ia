# Implementation Tasks - Rhapsodie Quiz IA

**Status Legend:**
- ⬜ Not Started
- 🔄 In Progress
- ✅ Completed
- ⏸️ Blocked

---

## Phase 0: Preparation & Backup

### 0.1 Database Backup
- ✅ **TASK-0.1.1**: Create full backup of current MySQL database `elite_quiz_237`
  ```
  COMPLETED: 2025-12-27
  Backup created: database-backups/backup_elite_quiz_237_20251227_141605.sql.gz
  Script: scripts/export-database.sh
  ```

- ✅ **TASK-0.1.2**: Document current database schema
  ```
  COMPLETED: 2025-12-27
  Documentation: docs/CURRENT_DB_SCHEMA.md
  56 tables documented with columns, types, and relationships
  ```

### 0.2 Project Structure
- ⏸️ **TASK-0.2.1**: Create new backend project structure
  ```
  CANCELLED: Decision to keep existing CodeIgniter backend and modify as needed
  Reason: Less risk, faster implementation, existing mobile app compatibility
  ```

- ⏸️ **TASK-0.2.2**: Setup Docker environment for new API
  ```
  CANCELLED: Using existing Docker infrastructure
  Existing setup: docker-compose.yml with MySQL, Redis, PHP already configured
  ```

---

## Phase 1: Database Schema & Migrations

> **Note**: Using SQL migrations on existing CodeIgniter backend instead of Laravel migrations.
> Migration files: `/database-migrations/`

### 1.1 Core Tables

- ⏸️ **TASK-1.1.1**: Create Users table migration
  ```
  SKIPPED: Using existing tbl_users table (already has all required fields)
  ```

- ✅ **TASK-1.1.2**: Create Topics table migration
  ```
  COMPLETED: 2025-12-27
  Migration: database-migrations/001_create_tbl_topic.sql
  Created tbl_topic with 'rhapsody' and 'foundation_school' seeded
  ```

- ✅ **TASK-1.1.3**: Alter Categories table for topic support
  ```
  COMPLETED: 2025-12-27
  Migration: database-migrations/002_alter_tbl_category.sql
  Added: topic_id, parent_id, category_type, age_group, year, month, day,
         daily_text, content_text, content_video_url, content_audio_url, content_pdf_url
  ```

- ⏸️ **TASK-1.1.4**: Create Questions table migration
  ```
  SKIPPED: Using existing tbl_question table (already functional)
  Questions linked to categories via category_id
  ```

### 1.2 User Progress Tables

- ✅ **TASK-1.2.1**: Create User Progress table
  ```
  COMPLETED: 2025-12-27
  Migration: database-migrations/003_create_tbl_user_progress.sql
  Unified progress tracking for all topics with quiz_date support
  
  Unique constraint on (user_id, category_id).
  Create UserProgress model with relationships.
  ```

- ⬜ **TASK-1.2.2**: Create User Points table migration
  ```
  PROMPT: Create Laravel migration for tbl_user_points table with fields:
  - id (primary key)
  - user_id (foreign key to tbl_user)
  - date (date)
  - reading_points (integer, default 0)
  - quiz_points (integer, default 0)
  - contest_points (integer, default 0)
  - battle_points (integer, default 0)
  - total_points (integer, default 0)
  - created_at, updated_at
  
  Unique constraint on (user_id, date).
  Create UserPoints model.
  ```

### 1.3 Group Tables

- ✅ **TASK-1.3.1**: Create Groups table migration
  ```
  COMPLETED: 2025-12-27
  Migration: database-migrations/004_create_group_tables.sql
  Created tbl_group with invite_code, owner_id, max_members, member_count
  ```

- ✅ **TASK-1.3.2**: Create Group Members table migration
  ```
  COMPLETED: 2025-12-27
  Migration: database-migrations/004_create_group_tables.sql
  Created tbl_group_member with role and status tracking
  ```

### 1.4 Battle Tables

- ✅ **TASK-1.4.1**: Create 1v1 Battle table migration
  ```
  COMPLETED: 2025-12-27
  Migration: database-migrations/005_create_battle_1v1_table.sql
  Created tbl_battle_1v1 with match_code, topic/category support, player answers (JSON)
  ```

- ✅ **TASK-1.4.2**: Create Group Battle tables migration
  ```
  COMPLETED: 2025-12-27
  Migration: database-migrations/004_create_group_tables.sql
  Created tbl_group_battle and tbl_group_battle_entry
  ```

### 1.5 Contest Tables

- ⬜ **TASK-1.5.1**: Create Contest tables migration
  ```
  PROMPT: Create Laravel migrations for contest tables:
  
  1. tbl_contest:
  - id (primary key)
  - date (date, unique)
  - category_id (foreign key to tbl_category) -- Rhapsody day
  - title (string, nullable)
  - is_active (boolean, default true)
  - created_at, updated_at
  
  2. tbl_contest_entry:
  - id (primary key)
  - contest_id (foreign key to tbl_contest)
  - user_id (foreign key to tbl_user)
  - score (integer)
  - correct_answers (integer)
  - total_questions (integer)
  - rank (integer, nullable)
  - completed_at (timestamp)
  
  Unique constraint on (contest_id, user_id).
  Create Contest and ContestEntry models.
  ```

### 1.6 Run Migrations

- ⬜ **TASK-1.6.1**: Run all migrations
  ```
  PROMPT: Run all Laravel migrations in order:
  1. php artisan migrate
  2. Verify all tables are created correctly
  3. Run seeders for topics (rhapsody, foundation_school)
  4. Document any errors and fix them
  ```

---

## Phase 2: Backend API - Authentication

### 2.1 Auth Controllers

- ⬜ **TASK-2.1.1**: Create Auth Controller with Firebase authentication
  ```
  PROMPT: Create app/Http/Controllers/Api/V1/AuthController.php with methods:
  
  1. register(Request $request)
     - Validate: firebase_id, name, email (optional), phone (optional)
     - Create new user in database
     - Generate Sanctum token
     - Return user data + token
  
  2. login(Request $request)
     - Validate: firebase_id
     - Find user by firebase_id
     - If not found, create new user
     - Generate Sanctum token
     - Return user data + token
  
  3. logout(Request $request)
     - Revoke current token
     - Return success message
  
  4. me(Request $request)
     - Return authenticated user data with relationships
  
  Create corresponding FormRequest classes for validation.
  Add routes to routes/api.php under 'v1' prefix.
  ```

- ⬜ **TASK-2.1.2**: Create User Profile endpoints
  ```
  PROMPT: Create app/Http/Controllers/Api/V1/ProfileController.php with methods:
  
  1. show(Request $request)
     - Return current user profile with stats
  
  2. update(Request $request)
     - Validate: name, email, phone, profile_image
     - Update user profile
     - Return updated user
  
  3. updateFcmToken(Request $request)
     - Validate: fcm_token
     - Update user's FCM token
     - Return success
  
  4. stats(Request $request)
     - Return user statistics:
       - Total points
       - Rank
       - Quizzes completed
       - Battles won/lost
       - Groups joined
  
  Add routes: GET /profile, PUT /profile, POST /profile/fcm-token, GET /profile/stats
  ```

---

## Phase 3: Backend API - Topics & Categories

### 3.1 Topics API

- ⬜ **TASK-3.1.1**: Create Topics Controller
  ```
  PROMPT: Create app/Http/Controllers/Api/V1/TopicController.php with methods:
  
  1. index()
     - Return all active topics
     - Include category count for each topic
     - Response format:
       {
         "success": true,
         "data": [
           {
             "id": 1,
             "slug": "rhapsody",
             "name": "Rhapsody of Realities",
             "topic_type": "daily",
             "image": "...",
             "categories_count": 365
           },
           ...
         ]
       }
  
  2. show($id)
     - Return single topic with top-level categories
     - For Rhapsody: return years
     - For Foundation School: return modules
  
  Add routes: GET /topics, GET /topics/{id}
  ```

### 3.2 Categories API

- ⬜ **TASK-3.2.1**: Create Categories Controller
  ```
  PROMPT: Create app/Http/Controllers/Api/V1/CategoryController.php with methods:
  
  1. index(Request $request)
     - Query params: topic_id, parent_id (optional)
     - Return categories filtered by topic and parent
     - For Rhapsody root: return years
     - For Rhapsody with parent: return months or days
     - For Foundation School: return modules
  
  2. show($id)
     - Return single category with:
       - Parent info (if any)
       - Children (if any)
       - Content (for FS modules or Rhapsody days)
       - Question count
  
  3. content($id)
     - Return category content for reading/viewing:
       - For FS: content_text, video_url, audio_url
       - For Rhapsody day: daily_text
  
  4. questions($id)
     - Return questions for the category
     - Shuffle questions order
     - Don't include correct_answer in response (for quiz)
  
  Add routes:
  - GET /categories?topic_id=X&parent_id=Y
  - GET /categories/{id}
  - GET /categories/{id}/content
  - GET /categories/{id}/questions
  ```

---

## Phase 4: Backend API - Quiz & Progress

### 4.1 Quiz API

- ⬜ **TASK-4.1.1**: Create Quiz Controller
  ```
  PROMPT: Create app/Http/Controllers/Api/V1/QuizController.php with methods:
  
  1. start(Request $request, $categoryId)
     - Validate user can take quiz for this category
     - For FS: check if previous modules are completed
     - For Rhapsody: check if text was read (optional)
     - Return questions (shuffled, without correct answers)
  
  2. submit(Request $request, $categoryId)
     - Validate: answers array [{question_id, answer}]
     - Calculate score
     - Save to user_progress
     - Update user points (if Rhapsody)
     - Return results:
       {
         "score": 8,
         "total": 10,
         "percentage": 80,
         "correct_answers": [...],
         "points_earned": 8,
         "passed": true
       }
  
  3. review($categoryId)
     - Return user's last attempt with correct answers
     - Include explanations
  
  Add routes:
  - POST /quiz/{categoryId}/start
  - POST /quiz/{categoryId}/submit
  - GET /quiz/{categoryId}/review
  ```

### 4.2 Progress API

- ⬜ **TASK-4.2.1**: Create Progress Controller
  ```
  PROMPT: Create app/Http/Controllers/Api/V1/ProgressController.php with methods:
  
  1. index(Request $request)
     - Query params: topic_id (optional)
     - Return user's progress across all categories
     - Include completion percentage per topic
  
  2. topicProgress($topicId)
     - Return detailed progress for a topic
     - For FS: list of modules with status (locked/available/completed)
     - For Rhapsody: summary by month
  
  3. markContentViewed(Request $request, $categoryId)
     - Mark category content as viewed
     - Update progress record
     - Award reading points (for Rhapsody)
  
  Add routes:
  - GET /progress
  - GET /progress/topic/{topicId}
  - POST /progress/{categoryId}/content-viewed
  ```

---

## Phase 5: Backend API - Groups

### 5.1 Groups API

- ⬜ **TASK-5.1.1**: Create Groups Controller
  ```
  PROMPT: Create app/Http/Controllers/Api/V1/GroupController.php with methods:
  
  1. index(Request $request)
     - Return groups where user is a member
     - Include member count, recent activity
  
  2. store(Request $request)
     - Validate: name, description (optional)
     - Create group with current user as owner
     - Generate unique invitation code (6 chars)
     - Add user as member with role 'owner'
     - Return created group
  
  3. show($id)
     - Return group details
     - Include members list, recent battles
     - Check if user is member
  
  4. update(Request $request, $id)
     - Only owner/admin can update
     - Validate: name, description, image
     - Return updated group
  
  5. destroy($id)
     - Only owner can delete
     - Soft delete or deactivate group
  
  6. join(Request $request)
     - Validate: code (invitation code)
     - Find group by code
     - Add user as member with status 'active'
     - Return group details
  
  7. leave($id)
     - Remove user from group
     - Owner cannot leave (must transfer ownership first)
  
  8. members($id)
     - Return group members with roles
  
  9. inviteByCode($id)
     - Return group invitation code
     - Generate new code if requested
  
  Add routes:
  - GET /groups
  - POST /groups
  - GET /groups/{id}
  - PUT /groups/{id}
  - DELETE /groups/{id}
  - POST /groups/join
  - POST /groups/{id}/leave
  - GET /groups/{id}/members
  - GET /groups/{id}/invite-code
  ```

---

## Phase 6: Backend API - Battles

### 6.1 1v1 Battle API

- ⬜ **TASK-6.1.1**: Create Battle 1v1 Controller
  ```
  PROMPT: Create app/Http/Controllers/Api/V1/Battle1v1Controller.php with methods:
  
  1. index(Request $request)
     - Return user's battles (as challenger or opponent)
     - Filter by status: pending, completed
     - Include opponent info
  
  2. create(Request $request)
     - Validate: opponent_id, topic_id, category_id
     - Create battle with status 'pending'
     - Set expires_at to 24 hours from now
     - Send notification to opponent
     - Return battle details
  
  3. show($id)
     - Return battle details
     - Include questions if status is 'in_progress' or 'completed'
  
  4. accept($id)
     - Only opponent can accept
     - Update status to 'accepted' then 'in_progress'
     - Set accepted_at timestamp
     - Return battle with questions
  
  5. decline($id)
     - Only opponent can decline
     - Update status to 'declined'
     - Notify challenger
  
  6. submit(Request $request, $id)
     - Validate: answers array
     - Calculate score for current user
     - Update challenger_score or opponent_score
     - If both submitted: determine winner, update status to 'completed'
     - Award points to winner
     - Return results
  
  7. cancel($id)
     - Only challenger can cancel (if still pending)
     - Update status to 'cancelled'
  
  Add routes:
  - GET /battles/1v1
  - POST /battles/1v1
  - GET /battles/1v1/{id}
  - POST /battles/1v1/{id}/accept
  - POST /battles/1v1/{id}/decline
  - POST /battles/1v1/{id}/submit
  - POST /battles/1v1/{id}/cancel
  ```

### 6.2 Group Battle API

- ⬜ **TASK-6.2.1**: Create Group Battle Controller
  ```
  PROMPT: Create app/Http/Controllers/Api/V1/GroupBattleController.php with methods:
  
  1. index(Request $request, $groupId)
     - Return battles for a group
     - Filter by status
  
  2. create(Request $request, $groupId)
     - Only owner/admin can create
     - Validate: topic_id, category_id
     - Create battle with status 'scheduled'
     - Notify all group members
     - Return battle details
  
  3. show($groupId, $battleId)
     - Return battle details with entries
  
  4. start($groupId, $battleId)
     - Only owner/admin can start
     - Update status to 'in_progress'
     - Set start_time
     - Return battle with questions
  
  5. submit(Request $request, $groupId, $battleId)
     - Validate: answers array
     - Calculate score
     - Create/update battle entry
     - Return results
  
  6. complete($groupId, $battleId)
     - Mark battle as completed
     - Calculate ranks for all entries
     - Set end_time
     - Return final leaderboard
  
  7. leaderboard($groupId, $battleId)
     - Return ranked entries for battle
  
  Add routes:
  - GET /groups/{groupId}/battles
  - POST /groups/{groupId}/battles
  - GET /groups/{groupId}/battles/{battleId}
  - POST /groups/{groupId}/battles/{battleId}/start
  - POST /groups/{groupId}/battles/{battleId}/submit
  - POST /groups/{groupId}/battles/{battleId}/complete
  - GET /groups/{groupId}/battles/{battleId}/leaderboard
  ```

---

## Phase 7: Backend API - Contest

### 7.1 Contest API

- ⬜ **TASK-7.1.1**: Create Contest Controller
  ```
  PROMPT: Create app/Http/Controllers/Api/V1/ContestController.php with methods:
  
  1. today()
     - Return today's contest
     - If not exists, create from today's Rhapsody day
     - Include daily text and question count
     - Check if user already participated
  
  2. show($id)
     - Return contest details
     - Include user's entry if exists
  
  3. questions($id)
     - Return contest questions
     - Only if user hasn't submitted yet
  
  4. submit(Request $request, $id)
     - Validate: answers array
     - Calculate score
     - Create contest entry
     - Update rank (recalculate all ranks)
     - Return results with rank
  
  5. leaderboard(Request $request, $id)
     - Query params: limit (default 50), offset
     - Return ranked entries
     - Include current user's position
  
  6. history(Request $request)
     - Return user's contest history
     - Include scores and ranks
  
  Add routes:
  - GET /contest/today
  - GET /contest/{id}
  - GET /contest/{id}/questions
  - POST /contest/{id}/submit
  - GET /contest/{id}/leaderboard
  - GET /contest/history
  ```

### 7.2 Contest Scheduler

- ⬜ **TASK-7.2.1**: Create Contest Scheduler Command
  ```
  PROMPT: Create app/Console/Commands/CreateDailyContest.php:
  
  - Artisan command: contest:create-daily
  - Finds today's Rhapsody category (by date)
  - Creates contest record if not exists
  - Logs creation
  
  Environment Configuration (.env):
  ┌─────────────────────────────────────────────────────────────┐
  │ DAILY_CONTEST_AUTO_CREATE=true|false                        │
  │                                                             │
  │ - true (PRODUCTION):  Scheduled at 00:00 AM via cron job   │
  │ - false (DEV/TEST):   Manual trigger only via script/API   │
  └─────────────────────────────────────────────────────────────┘
  
  In Kernel.php (scheduler):
  if (env('DAILY_CONTEST_AUTO_CREATE', false)) {
      $schedule->command('contest:create-daily')->dailyAt('00:00');
  }
  
  Manual trigger script (dev):
  - php artisan contest:create-daily
  - POST /api/admin/contest/create-daily (admin API)
  
  Also create command to recalculate contest ranks:
  - Artisan command: contest:recalculate-ranks {contestId?}
  - Recalculates ranks for a contest or all today's contest
  ```

- ⬜ **TASK-7.2.2**: Create Daily Contest Notification Scheduler
  ```
  PROMPT: Create notification scheduler for Daily Contest reminders:
  
  Schedule (3 times daily until user completes):
  - 08:00 AM: "🌅 Bonjour! Le Rhapsody du jour est disponible. Gagnez vos 10 points!"
  - 13:00 PM: "☀️ N'oubliez pas votre Rhapsody quotidien! Il vous reste quelques heures."
  - 22:00 PM: "🌙 Dernière chance! Complétez votre Rhapsody avant minuit."
  
  Logic:
  1. Query users who have NOT completed today's contest
  2. Send push notification via Firebase Cloud Messaging
  3. Skip users who have already completed
  4. Log notifications sent
  
  Commands:
  - Artisan command: contest:send-reminders
  - Schedule in Kernel.php at 08:00, 13:00, 22:00
  ```

---

## Phase 8: Backend API - Leaderboards

### 8.1 Leaderboard API

- ⬜ **TASK-8.1.1**: Create Leaderboard Controller
  ```
  PROMPT: Create app/Http/Controllers/Api/V1/LeaderboardController.php with methods:
  
  1. daily(Request $request)
     - Query params: date (default today)
     - Return top users by daily points
     - Include current user's position
  
  2. weekly(Request $request)
     - Query params: week (default current week)
     - Aggregate points for the week
     - Return ranked users
  
  3. monthly(Request $request)
     - Query params: month, year (default current)
     - Aggregate points for the month
     - Return ranked users
  
  4. allTime(Request $request)
     - Return users ranked by all_time_score
     - Paginated (limit, offset)
  
  5. myRank(Request $request)
     - Return current user's ranks:
       - daily_rank
       - weekly_rank
       - monthly_rank
       - all_time_rank
  
  Add routes:
  - GET /leaderboard/daily
  - GET /leaderboard/weekly
  - GET /leaderboard/monthly
  - GET /leaderboard/all-time
  - GET /leaderboard/my-rank
  ```

---

## Phase 9: Mobile App - Setup

> **Note**: Using existing Flutter app structure and modifying/extending as needed.
> New features added: topics, groups, battles

### 9.1 Project Setup

- ✅ **TASK-9.1.1**: Flutter project structure (using existing)
  ```
  COMPLETED: 2025-12-27
  Using existing app structure at /src/mobile/
  New features added:
  - lib/features/topics/ (topics_remote_data_source.dart, topics_cubit.dart, models)
  - lib/features/groups/ (groups_remote_data_source.dart, groups_cubit.dart, models)
  - lib/features/battles/ (battles_remote_data_source.dart, battle_1v1_cubit.dart, models)
  - lib/ui/screens/groups/groups_screen.dart
  - lib/ui/screens/battles/battle_1v1_screen.dart, battle_mode_screen.dart
  ```
  ```
  PROMPT: Restructure the Flutter app in /src/mobile/ with Clean Architecture:
  
  lib/
  ├── main.dart
  ├── app/
  │   ├── app.dart
  │   └── routes.dart
  ├── core/
  │   ├── config/
  │   │   └── config.dart (API URL, etc.)
  │   ├── constants/
  │   ├── errors/
  │   ├── network/
  │   │   ├── api_client.dart
  │   │   └── api_endpoints.dart
  │   ├── theme/
  │   └── utils/
  ├── features/
  │   ├── auth/
  │   ├── topics/
  │   ├── quiz/
  │   ├── groups/
  │   ├── battles/
  │   ├── contest/
  │   ├── leaderboard/
  │   └── profile/
  └── shared/
      ├── widgets/
      └── models/
  
  Each feature folder has:
  - data/ (repositories, data sources)
  - domain/ (entities, use cases)
  - presentation/ (screens, widgets, cubits)
  ```

- ✅ **TASK-9.1.2**: Routes and Provider Setup
  ```
  COMPLETED: 2025-12-27
  Updated:
  - lib/core/routes/routes.dart - Added routes: topics, groups, battleMode, battle1v1
  - lib/app/app.dart - Added BlocProviders for:
    - TopicsCubit
    - GroupsCubit, GroupDetailCubit
    - Battle1v1Cubit, Battle1v1HistoryCubit
  ```

- ⬜ **TASK-9.1.3**: Setup API Client
  ```
  PROMPT: Create lib/core/network/api_client.dart using Dio:
  
  - Base URL from config
  - Interceptors for:
    - Auth token injection
    - Error handling
    - Logging
  - Methods: get, post, put, delete
  - Response parsing to ApiResponse model
  - Error handling with custom exceptions
  
  Create lib/core/network/api_endpoints.dart with all endpoint constants.
  ```

- ⬜ **TASK-9.1.3**: Setup BLoC/Cubit state management
  ```
  PROMPT: Setup flutter_bloc in the project:
  
  - Add dependencies: flutter_bloc, equatable
  - Create base cubit class with common states
  - Create BlocObserver for logging
  - Setup MultiBlocProvider in app.dart
  
  Create core state classes:
  - LoadingState
  - SuccessState<T>
  - ErrorState
  ```

---

## Phase 10: Mobile App - Authentication

### 10.1 Auth Feature

- ⬜ **TASK-10.1.1**: Create Auth Data Layer
  ```
  PROMPT: Create lib/features/auth/data/:
  
  1. models/user_model.dart
     - UserModel with fromJson, toJson
     - Fields matching API response
  
  2. datasources/auth_remote_datasource.dart
     - login(firebaseId, name, email)
     - register(firebaseId, name, email)
     - logout()
     - getProfile()
     - updateProfile(name, email, phone)
  
  3. repositories/auth_repository_impl.dart
     - Implements AuthRepository interface
     - Handles API calls and local storage
     - Saves token to secure storage
  ```

- ⬜ **TASK-10.1.2**: Create Auth Domain Layer
  ```
  PROMPT: Create lib/features/auth/domain/:
  
  1. entities/user.dart
     - User entity class
  
  2. repositories/auth_repository.dart
     - Abstract repository interface
  
  3. usecases/
     - login_usecase.dart
     - register_usecase.dart
     - logout_usecase.dart
     - get_profile_usecase.dart
  ```

- ⬜ **TASK-10.1.3**: Create Auth Presentation Layer
  ```
  PROMPT: Create lib/features/auth/presentation/:
  
  1. cubits/auth_cubit.dart
     - States: Initial, Loading, Authenticated, Unauthenticated, Error
     - Methods: login, register, logout, checkAuth
  
  2. screens/
     - login_screen.dart (Firebase Google/Apple sign-in buttons)
     - splash_screen.dart (check auth state)
  
  3. widgets/
     - social_login_button.dart
  ```

---

## Phase 11: Mobile App - Topics & Categories

### 11.1 Topics Feature

- ⬜ **TASK-11.1.1**: Create Topics Data Layer
  ```
  PROMPT: Create lib/features/topics/data/:
  
  1. models/topic_model.dart
  2. models/category_model.dart
  3. datasources/topics_remote_datasource.dart
     - getTopics()
     - getTopic(id)
     - getCategories(topicId, parentId)
     - getCategory(id)
     - getCategoryContent(id)
  4. repositories/topics_repository_impl.dart
  ```

- ⬜ **TASK-11.1.2**: Create Topics Presentation Layer
  ```
  PROMPT: Create lib/features/topics/presentation/:
  
  1. cubits/
     - topics_cubit.dart (load all topics)
     - categories_cubit.dart (load categories for topic)
  
  2. screens/
     - topics_screen.dart (list of topics: FS, Rhapsody)
     - categories_screen.dart (list of categories/modules)
     - category_detail_screen.dart (content viewer)
  
  3. widgets/
     - topic_card.dart
     - category_tile.dart
     - content_viewer.dart (text, video, audio)
  ```

---

## Phase 12: Mobile App - Quiz

### 12.1 Quiz Feature

- ⬜ **TASK-12.1.1**: Create Quiz Data Layer
  ```
  PROMPT: Create lib/features/quiz/data/:
  
  1. models/question_model.dart
  2. models/quiz_result_model.dart
  3. datasources/quiz_remote_datasource.dart
     - startQuiz(categoryId)
     - submitQuiz(categoryId, answers)
     - getReview(categoryId)
  4. repositories/quiz_repository_impl.dart
  ```

- ⬜ **TASK-12.1.2**: Create Quiz Presentation Layer
  ```
  PROMPT: Create lib/features/quiz/presentation/:
  
  1. cubits/quiz_cubit.dart
     - States: Initial, Loading, InProgress, Submitting, Completed, Error
     - Methods: startQuiz, selectAnswer, nextQuestion, previousQuestion, submitQuiz
     - Track: currentQuestionIndex, answers, timeRemaining
  
  2. screens/
     - quiz_screen.dart (question display, options, navigation)
     - quiz_result_screen.dart (score, correct answers, explanations)
  
  3. widgets/
     - question_card.dart
     - option_button.dart
     - quiz_progress_indicator.dart
     - timer_widget.dart
  ```

---

## Phase 13: Mobile App - Modes (Solo, 1v1, Multiplayer)

### 13.1 Mode Selection

- ⬜ **TASK-13.1.1**: Create Home Screen with Mode Selection
  ```
  PROMPT: Create lib/features/home/presentation/screens/home_screen.dart:
  
  - Display mode selection cards:
    1. Solo Mode - Play alone
    2. 1v1 Mode - Challenge a friend
    3. Multiplayer - Group battle
    4. Contest - Daily challenge
  
  - Each card navigates to respective flow
  - Show user stats summary
  - Show today's contest status
  
  Create corresponding widgets:
  - mode_card.dart
  - user_stats_bar.dart
  - daily_contest_banner.dart
  ```

### 13.2 Solo Mode Flow

- ✅ **TASK-13.2.1**: Topics & Categories Feature
  ```
  COMPLETED: 2025-12-27
  Created:
  - lib/features/topics/topics_remote_data_source.dart
  - lib/features/topics/cubits/topics_cubit.dart
  - lib/features/topics/models/topic_model.dart
  API endpoints integrated for topic/category browsing
  ```

- ⬜ **TASK-13.2.2**: Create Solo Mode Flow
  ```
  PROMPT: Create solo mode flow:
  
  1. User taps "Solo Mode"
  2. TopicsScreen: Select topic (FS or Rhapsody)
  3. CategoriesScreen: 
     - For FS: Select module
     - For Rhapsody: Select Year → Month → Day
  4. CategoryDetailScreen: View content (optional for FS)
  5. QuizScreen: Answer questions
  6. ResultScreen: View results
  
  Create navigation helper for this flow.
  ```

### 13.3 1v1 Mode Flow

- ✅ **TASK-13.3.1**: Create 1v1 Battle Data Layer
  ```
  COMPLETED: 2025-12-27
  Created:
  - lib/features/battles/models/battle_model.dart (Battle1v1, GroupBattle, BattleQuestion, etc.)
  - lib/features/battles/battles_remote_data_source.dart
    - create1v1Battle, join1v1Battle, get1v1Battle, submit1v1Answers, get1v1History
    - createGroupBattle, joinGroupBattle, startGroupBattle, submitGroupBattleAnswers
  - lib/features/battles/battles.dart (barrel file)
  ```

- ✅ **TASK-13.3.2**: Create 1v1 Battle Presentation Layer
  ```
  COMPLETED: 2025-12-27
  Created:
  - lib/features/battles/cubits/battle_1v1_cubit.dart
    - States: Initial, Loading, Created, WaitingOpponent, Ready, Playing, Completed, Error
    - Methods: createBattle, joinBattle, startGame, answerQuestion
    - Timer and polling for opponent
  - lib/ui/screens/battles/battle_1v1_screen.dart
    - Waiting state (share match code)
    - Ready state (VS display, start button)
    - Playing state (questions with timer)
    - Completed state (results, rematch option)
  - lib/ui/screens/battles/battle_mode_screen.dart
    - Mode selection (1v1, Group)
    - Quick actions (Join battle, History)
    - Topic/category selection sheet
  - lib/features/battles/cubits/battle_1v1_cubit.dart (Battle1v1HistoryCubit)
  ```

- ⬜ **TASK-13.3.3**: Create 1v1 Battle Real-time Updates
  ```
  PROMPT: Implement WebSocket or Firebase Realtime Database for:
  - Real-time opponent status updates
  - Live score tracking during battle
  - Instant results when both players finish
  ```

### 13.4 Multiplayer (Group) Mode Flow

- ✅ **TASK-13.4.1**: Create Groups Data Layer
  ```
  COMPLETED: 2025-12-27
  Created:
  - lib/features/groups/models/group_model.dart (Group, GroupMember)
  - lib/features/groups/groups_remote_data_source.dart
    - createGroup, getMyGroups, getGroup, joinGroup, leaveGroup, searchGroups
  - lib/features/groups/groups.dart (barrel file)
  ```

- ✅ **TASK-13.4.2**: Create Groups Presentation Layer
  ```
  COMPLETED: 2025-12-27
  Created:
  - lib/features/groups/cubits/groups_cubit.dart (GroupsCubit, GroupDetailCubit)
  - lib/ui/screens/groups/groups_screen.dart
    - GroupsScreen (list with empty state, FABs for create/join)
    - GroupDetailScreen (info, members, battles)
    - CreateGroupBattleScreen (topic/category selection with TopicsCubit integration)
    - _GroupCard, _MemberTile, _InfoChip widgets
    - Search dialog, join dialog, create dialog
  ```

- ✅ **TASK-13.4.3**: Create Group Battle Feature
  ```
  COMPLETED: 2025-12-27
  Created:
  - lib/features/battles/cubits/group_battle_cubit.dart
    - States: Initial, Loading, Created, Waiting, Ready, Playing, Submitted, Completed, Error
    - Full game flow with timer, polling, answer submission
  - lib/ui/screens/battles/group_battle_screen.dart
    - Waiting state (player list, start button for owner)
    - Ready state (battle info, start button)
    - Playing state (questions with timer, options)
    - Submitted state (waiting for others)
    - Completed state (leaderboard with ranks)
  ```

---

## Phase 14: Mobile App - Contest

### 14.1 Contest Feature

- ⬜ **TASK-14.1.1**: Create Contest Data Layer
  ```
  PROMPT: Create lib/features/contest/data/:
  
  1. models/contest_model.dart
  2. models/contest_entry_model.dart
  3. datasources/contest_remote_datasource.dart
     - getTodayContest()
     - getContest(id)
     - getQuestions(id)
     - submitContest(id, answers)
     - getLeaderboard(id)
     - getHistory()
  4. repositories/contest_repository_impl.dart
  ```

- ⬜ **TASK-14.1.2**: Create Contest Presentation Layer
  ```
  PROMPT: Create lib/features/contest/presentation/:
  
  1. cubits/
     - contest_cubit.dart
     - contest_leaderboard_cubit.dart
  
  2. screens/
     - contest_home_screen.dart (today's contest)
     - contest_quiz_screen.dart
     - contest_result_screen.dart
     - contest_leaderboard_screen.dart
     - contest_history_screen.dart
  
  3. widgets/
     - contest_banner.dart
     - leaderboard_tile.dart
     - rank_badge.dart
  ```

---

## Phase 15: Mobile App - Leaderboard & Profile

### 15.1 Leaderboard Feature

- ⬜ **TASK-15.1.1**: Create Leaderboard Feature
  ```
  PROMPT: Create lib/features/leaderboard/:
  
  Data:
  - leaderboard_remote_datasource.dart
  - leaderboard_repository_impl.dart
  
  Presentation:
  - cubits/leaderboard_cubit.dart
  - screens/leaderboard_screen.dart (tabs: daily, weekly, monthly, all-time)
  - widgets/leaderboard_tile.dart, rank_indicator.dart
  ```

### 15.2 Profile Feature

- ⬜ **TASK-15.2.1**: Create Profile Feature
  ```
  PROMPT: Create lib/features/profile/:
  
  Presentation:
  - cubits/profile_cubit.dart
  - screens/
    - profile_screen.dart (user info, stats, settings)
    - edit_profile_screen.dart
    - settings_screen.dart
  - widgets/
    - stat_card.dart
    - achievement_badge.dart
  ```

---

## Phase 16: Mobile App - Navigation & Polish

### 16.1 App Navigation

- ⬜ **TASK-16.1.1**: Setup App Navigation
  ```
  PROMPT: Create lib/app/routes.dart with GoRouter:
  
  Routes:
  - / → SplashScreen
  - /login → LoginScreen
  - /home → HomeScreen (with bottom nav)
  - /topics → TopicsScreen
  - /topics/:id/categories → CategoriesScreen
  - /categories/:id → CategoryDetailScreen
  - /quiz/:categoryId → QuizScreen
  - /battles → BattlesListScreen
  - /battles/create → CreateBattleScreen
  - /battles/:id → BattleDetailScreen
  - /groups → GroupsListScreen
  - /groups/create → CreateGroupScreen
  - /groups/:id → GroupDetailScreen
  - /contest → ContestHomeScreen
  - /leaderboard → LeaderboardScreen
  - /profile → ProfileScreen
  
  Implement guards for authenticated routes.
  ```

### 16.2 Bottom Navigation

- ⬜ **TASK-16.2.1**: Create Main Shell with Bottom Navigation
  ```
  PROMPT: Create lib/app/main_shell.dart:
  
  Bottom navigation with 5 tabs:
  1. Home (modes)
  2. Topics (FS & Rhapsody)
  3. Contest (daily)
  4. Leaderboard
  5. Profile
  
  Use IndexedStack to preserve state.
  Handle deep linking.
  ```

---

## Phase 17: Testing & Deployment

### 17.1 Backend Testing

- ⬜ **TASK-17.1.1**: Write API Tests
  ```
  PROMPT: Create PHPUnit tests for all API endpoints:
  
  - tests/Feature/AuthTest.php
  - tests/Feature/TopicsTest.php
  - tests/Feature/CategoriesTest.php
  - tests/Feature/QuizTest.php
  - tests/Feature/GroupsTest.php
  - tests/Feature/BattlesTest.php
  - tests/Feature/ContestTest.php
  - tests/Feature/LeaderboardTest.php
  
  Test success cases, error cases, authentication, authorization.
  ```

### 17.2 Mobile Testing

- ⬜ **TASK-17.2.1**: Write Widget Tests
  ```
  PROMPT: Create widget tests for critical screens:
  
  - test/features/auth/login_screen_test.dart
  - test/features/quiz/quiz_screen_test.dart
  - test/features/contest/contest_screen_test.dart
  
  Test UI interactions, state changes, navigation.
  ```

### 17.3 Deployment

- ⬜ **TASK-17.3.1**: Deploy Backend
  ```
  PROMPT: Create deployment configuration:
  
  1. docker-compose.prod.yml for production
  2. Nginx configuration with SSL
  3. Environment variables setup
  4. Database migration scripts
  5. Backup cron jobs
  
  Document deployment steps in DEPLOYMENT.md
  ```

- ⬜ **TASK-17.3.2**: Build Mobile Apps
  ```
  PROMPT: Create build scripts:
  
  1. Android release build with signing
  2. iOS release build
  3. Update app icons and splash screens
  4. Configure app store metadata
  
  Document in MOBILE_BUILD.md
  ```

---

## Summary

| Phase | Tasks | Status |
|-------|-------|--------|
| Phase 0: Preparation | 2 | ✅ Done (2 cancelled) |
| Phase 1: Database | 7 | ✅ Done (5 completed, 2 skipped) |
| Phase 2: Auth API | 2 | ⬜ Not Started |
| Phase 3: Topics API | 2 | ⬜ Not Started |
| Phase 4: Quiz API | 2 | ⬜ Not Started |
| Phase 5: Groups API | 1 | ⬜ Not Started |
| Phase 6: Battles API | 2 | ⬜ Not Started |
| Phase 7: Contest API | 2 | ⬜ Not Started |
| Phase 8: Leaderboard API | 1 | ⬜ Not Started |
| Phase 9: Mobile Setup | 3 | ✅ Mostly Done (2 completed) |
| Phase 10: Mobile Auth | 3 | ⬜ Not Started |
| Phase 11: Mobile Topics | 2 | ⬜ Not Started |
| Phase 12: Mobile Quiz | 2 | ⬜ Not Started |
| Phase 13: Mobile Modes | 5 | ✅ Done (Topics, 1v1, Groups, Group Battle) |
| Phase 14: Mobile Contest | 2 | ⬜ Not Started |
| Phase 15: Mobile Leaderboard/Profile | 2 | ⬜ Not Started |
| Phase 16: Mobile Navigation | 2 | ⬜ Not Started |
| Phase 17: Testing & Deployment | 4 | ⬜ Not Started |
| **TOTAL** | **46 Tasks** | 🔄 ~40% Complete |

---

## Additional Completed Features (Not in Original Tasks)

| Feature | Status |
|---------|--------|
| Rhapsody section on Home Screen | ✅ Completed |
| Rhapsody View All (year tabs, month grid) | ✅ Completed |
| Rhapsody Month Screen (days grid) | ✅ Completed |
| Rhapsody Day Screen (content + quiz) | ✅ Completed |
| Rhapsody DB seed (2025 data, 12 months) | ✅ Completed |
| Foundation School section on Home Screen | ✅ Completed |
| Foundation School Screen (7 classes) | ✅ Completed |
| Foundation School Class Detail Screen | ✅ Completed |
| Foundation School DB seed (7 classes) | ✅ Completed |
| Test Your Knowledge quiz section | ✅ Completed |
| Fixed header in Rhapsody daily screen | ✅ Completed |
| Glass Morphism day cards design | ✅ Completed |
| Solid month cards on Home Screen | ✅ Completed |
| Login fix for orphaned Firebase users | ✅ Completed |
| Type casting fixes in Flutter models | ✅ Completed |
| Coin reward for 100% quiz (replays allowed) | ✅ Completed |
| Points vs Coins distinction documented | ✅ Completed |

---

## Phase 18: Groups & Multiplayer Mode (Group Battles)

### Overview

**Concept:** Groups are persistent communities. Group Battles are temporary competitions within those communities.

```
GROUP (Persistent Entity)          →    GROUP BATTLES (Temporary Activities)
├── My Church (25 members)         →    ├── Battle #1 (Rhapsody Jan 15)
├── Youth Group (12 members)       →    ├── Battle #2 (Foundation M1)  
└── Bible Study (8 members)        →    └── Battle #3 (Rhapsody Jan 16)
```

### 18.1 Backend: Group Management

- ⬜ **TASK-18.1.1**: Create/verify Group tables exist
  ```sql
  -- Tables needed:
  -- tbl_group (id, name, description, owner_id, invite_code, is_public, max_members, status)
  -- tbl_group_member (id, group_id, user_id, role, status, joined_at)
  ```

- ⬜ **TASK-18.1.2**: Group API endpoints (CodeIgniter)
  ```
  POST   /api/groups                    - Create group
  GET    /api/groups                    - List user's groups
  GET    /api/groups/{id}               - Get group details
  PUT    /api/groups/{id}               - Update group
  DELETE /api/groups/{id}               - Delete group
  POST   /api/groups/join               - Join by invite code
  POST   /api/groups/{id}/leave         - Leave group
  GET    /api/groups/{id}/members       - List members
  POST   /api/groups/{id}/members/{uid}/remove - Remove member
  POST   /api/groups/{id}/members/{uid}/promote - Promote to admin
  ```

- ⬜ **TASK-18.1.3**: Group invite code generation
  ```
  - Generate unique 8-char alphanumeric code
  - Allow regenerating code (invalidates old)
  - Code lookup for joining
  ```

### 18.2 Backend: Group Battle Management

- ⬜ **TASK-18.2.1**: Create/verify Group Battle tables exist
  ```sql
  -- Tables needed:
  -- tbl_group_battle (id, group_id, topic_id, category_id, title, status, 
  --                   question_count, time_per_question, min_players, max_players,
  --                   entry_coins, prize_coins, started_at, ended_at)
  -- tbl_group_battle_entry (id, battle_id, user_id, score, correct_answers, 
  --                         total_questions, time_taken_ms, rank, completed_at)
  ```

- ⬜ **TASK-18.2.2**: Group Battle API endpoints
  ```
  POST   /api/group-battles                     - Create battle
  GET    /api/group-battles/{id}                - Get battle details + questions
  POST   /api/group-battles/{id}/join           - Join battle
  POST   /api/group-battles/{id}/start          - Start battle (owner only)
  POST   /api/group-battles/{id}/submit         - Submit answers
  GET    /api/group-battles/{id}/results        - Get results/leaderboard
  GET    /api/groups/{id}/battles               - List group's battles
  GET    /api/groups/{id}/battles/active        - Get active battle
  ```

- ⬜ **TASK-18.2.3**: Battle status management
  ```
  States: pending → waiting → active → completed
  - pending: Created, waiting for players
  - waiting: Min players joined, can start
  - active: Battle in progress
  - completed: All finished or time expired
  ```

### 18.3 Mobile: Group Management UI

- ⬜ **TASK-18.3.1**: Groups List Screen
  ```dart
  // lib/ui/screens/groups/groups_screen.dart
  - List user's groups (owner + member)
  - FAB to create new group
  - Join group button (enter code)
  - Group card: name, member count, role badge
  ```

- ⬜ **TASK-18.3.2**: Create Group Screen
  ```dart
  // lib/ui/screens/groups/create_group_screen.dart
  - Group name (required)
  - Description (optional)
  - Image upload (optional)
  - Public/Private toggle
  - Max members slider
  ```

- ⬜ **TASK-18.3.3**: Group Detail Screen
  ```dart
  // lib/ui/screens/groups/group_detail_screen.dart
  - Group info header (name, image, member count)
  - Invite code display + share button
  - Members list with roles
  - Recent battles list
  - "Start Battle" button (owner/admin only)
  - Settings (owner only)
  ```

- ⬜ **TASK-18.3.4**: Join Group Flow
  ```dart
  // Enter code → validate → show group preview → confirm join
  - Bottom sheet or dialog to enter code
  - Show group name, description, member count
  - Confirm button to join
  ```

- ⬜ **TASK-18.3.5**: Group Settings/Edit Screen
  ```dart
  // Owner only
  - Edit name, description, image
  - Regenerate invite code
  - Manage members (remove, promote)
  - Delete group
  ```

### 18.4 Mobile: Group Battle UI

- ⬜ **TASK-18.4.1**: Create Battle Screen
  ```dart
  // lib/ui/screens/battles/create_group_battle_screen.dart
  - Select Topic (Rhapsody, Foundation School, etc.)
  - Select Category (Year/Month/Day or Module)
  - Battle settings:
    - Question count (5, 10, 15)
    - Time per question (10, 15, 30 seconds)
    - Entry coins (optional)
    - Prize coins (optional)
  ```

- ⬜ **TASK-18.4.2**: Battle Waiting Room
  ```dart
  // lib/ui/screens/battles/battle_waiting_screen.dart
  - Show battle info (topic, category, settings)
  - List joined players (live update via polling)
  - Player count: X / max
  - "Start Battle" button (when min players joined)
  - Countdown timer if auto-start configured
  ```

- ⬜ **TASK-18.4.3**: Battle Playing Screen (exists, verify/enhance)
  ```dart
  // lib/ui/screens/battles/group_battle_screen.dart
  - Question display with timer
  - Answer buttons (A, B, C, D)
  - Progress indicator (Q1/10)
  - Score display
  - Submit and move to next
  ```

- ⬜ **TASK-18.4.4**: Battle Results Screen
  ```dart
  // lib/ui/screens/battles/battle_results_screen.dart
  - Podium display (1st, 2nd, 3rd)
  - Full leaderboard list
  - User's position highlighted
  - Stats: correct answers, time, rank
  - "Play Again" / "Back to Group" buttons
  ```

### 18.5 Mobile: State Management

- ⬜ **TASK-18.5.1**: Verify/Complete GroupsCubit
  ```dart
  // lib/features/groups/cubits/groups_cubit.dart
  States: Initial, Loading, Loaded, Error
  Methods: loadGroups, createGroup, joinGroup, leaveGroup
  ```

- ⬜ **TASK-18.5.2**: Verify/Complete GroupBattleCubit
  ```dart
  // lib/features/battles/cubits/group_battle_cubit.dart
  States: Initial, Loading, Created, Waiting, Ready, Playing, Completed, Error
  Methods: createBattle, joinBattle, startBattle, answerQuestion, submitAnswers
  ```

- ⬜ **TASK-18.5.3**: Polling for live updates
  ```dart
  // Poll every 3-5 seconds for:
  - Waiting room: player count
  - Battle status: started/completed
  - Results: final rankings
  ```

### 18.6 Integration & Navigation

- ⬜ **TASK-18.6.1**: Add Groups to Home Screen
  ```dart
  // Home Screen → Add "My Groups" section or tab
  - Show user's groups (max 3-5)
  - "View All" to groups list
  ```

- ⬜ **TASK-18.6.2**: Link Multiplayer Mode to Groups
  ```dart
  // When user taps "Multiplayer" on home:
  // 1. If no groups → prompt to create/join
  // 2. If groups exist → show groups list → select → create battle
  ```

- ⬜ **TASK-18.6.3**: Push Notifications (optional)
  ```
  - Battle invitation
  - Battle started
  - Battle completed
  - Member joined group
  ```

### 18.7 Testing & Polish

- ⬜ **TASK-18.7.1**: Test full flow
  ```
  1. Create group
  2. Share invite code
  3. Other user joins
  4. Owner creates battle
  5. All members join battle
  6. Battle plays out
  7. Results displayed
  ```

- ⬜ **TASK-18.7.2**: Edge cases
  ```
  - Single player battle (allowed?)
  - Player disconnects mid-battle
  - Owner leaves group
  - Battle timeout handling
  ```

### Task Summary

| Section | Tasks | Status |
|---------|-------|--------|
| 18.1 Backend: Group Management | 3 | ⬜ Not Started |
| 18.2 Backend: Group Battle | 3 | ⬜ Not Started |
| 18.3 Mobile: Group UI | 5 | ⬜ Not Started |
| 18.4 Mobile: Battle UI | 4 | ⬜ Not Started |
| 18.5 Mobile: State Management | 3 | ⬜ Not Started |
| 18.6 Integration & Navigation | 3 | ⬜ Not Started |
| 18.7 Testing & Polish | 2 | ⬜ Not Started |
| **TOTAL** | **23 Tasks** | ⬜ 0% Complete |

### Implementation Order (Recommended)

1. **Backend First:** 18.1 → 18.2 (API must exist before mobile)
2. **Mobile Groups:** 18.3 (Group CRUD before battles)
3. **Mobile Battles:** 18.4 → 18.5 (Battle UI + state)
4. **Integration:** 18.6 (Connect everything)
5. **Testing:** 18.7 (End-to-end validation)

---

## Phase 19: Solo Mode (Practice Mode)

### Overview

**Concept:** Practice mode where user selects only a Topic and quiz settings. Questions are randomly selected from ALL categories within that topic.

```
SOLO MODE FLOW:
User → Select Topic → Configure (questions, time) → Random Quiz → Results

QUESTION SOURCES:
├── Rhapsody: Random from ALL years/months/days
└── Foundation: Random from ALL modules (skip content, quiz only)

COIN REWARD:
├── 100% correct AND questions > 5 → +1 coin
└── Otherwise → 0 coins
```

### 19.1 Backend: Random Questions API

- ✅ **TASK-19.1.1**: Create random questions endpoint
  ```
  GET /api/solo/random-questions
  Parameters:
    - topic_id: required (rhapsody or foundation_school)
    - count: required (5, 10, 15, or 20)
  
  Response:
    - questions: array of random questions from all categories in topic
    - topic_name: string
    - total_available: total questions in topic (for info)
  ```

- ✅ **TASK-19.1.2**: Implement random selection logic
  ```php
  // Get all categories for topic
  // Join with questions table
  // ORDER BY RAND() LIMIT $count
  // Return questions with options
  ```

- ✅ **TASK-19.1.3**: Create solo quiz submission endpoint
  ```
  POST /api/solo/submit
  Body:
    - topic_id: string
    - question_count: int
    - answers: array of {question_id, answer}
    - time_taken: int (ms)
  
  Response:
    - score: int
    - correct_answers: int
    - total_questions: int
    - percentage: int
    - earned_coin: int (1 if 100% and count > 5, else 0)
    - correct_answers_detail: array
  ```

### 19.2 Mobile: Solo Mode UI

- ✅ **TASK-19.2.1**: Create Solo Mode Screen
  ```dart
  // lib/ui/screens/solo/solo_mode_screen.dart
  
  // Step 1: Topic Selection
  - Grid/List of available topics
  - Topic card: icon, name, question count available
  - Tap to select
  
  // Step 2: Quiz Configuration
  - Question count selector: [5] [10] [15] [20]
  - Time per question: [10s] [15s] [30s] [60s]
  - "Start Quiz" button
  ```

- ✅ **TASK-19.2.2**: Update existing quiz screen for Solo Mode
  ```dart
  // Modify quiz_screen.dart or create solo_quiz_screen.dart
  - Accept questions array (not category-based)
  - Timer per question
  - Progress indicator
  - Submit all at end
  ```

- ✅ **TASK-19.2.3**: Create Solo Results Screen
  ```dart
  // lib/ui/screens/solo/solo_results_screen.dart
  - Score display: X/Y (percentage)
  - Coin reward display (if earned)
  - Correct/incorrect answers review
  - "Play Again" button (same settings)
  - "Change Topic" button (back to topic selection)
  ```

### 19.3 Mobile: State Management

- ✅ **TASK-19.3.1**: Create SoloModeCubit
  ```dart
  // lib/features/solo/cubits/solo_mode_cubit.dart
  
  States:
    - SoloModeInitial
    - SoloModeTopicsLoaded(topics)
    - SoloModeQuestionsLoading
    - SoloModeReady(questions, settings)
    - SoloModePlaying(currentQuestion, answers)
    - SoloModeSubmitting
    - SoloModeCompleted(results)
    - SoloModeError(message)
  
  Methods:
    - loadTopics()
    - selectTopic(topicId)
    - configureQuiz(questionCount, timePerQuestion)
    - fetchRandomQuestions()
    - answerQuestion(questionId, answer)
    - submitQuiz()
  ```

- ✅ **TASK-19.3.2**: Create Solo Remote Data Source
  ```dart
  // lib/features/solo/solo_remote_data_source.dart
  
  Methods:
    - getAvailableTopics() → List<Topic>
    - getRandomQuestions(topicId, count) → List<Question>
    - submitSoloQuiz(topicId, answers) → SoloResult
  ```

### 19.4 Integration

- ✅ **TASK-19.4.1**: Update Home Screen Solo button
  ```dart
  // When user taps "Solo" on home screen:
  // Navigate to SoloModeScreen (new flow)
  // Instead of current self-challenge flow
  ```

- ✅ **TASK-19.4.2**: Update coin reward logic in backend
  ```php
  // In solo/submit endpoint:
  // if ($percentage == 100 && $question_count > 5) {
  //     $this->set_coins($user_id, 1);
  //     $earned_coin = 1;
  // }
  ```

- ✅ **TASK-19.4.3**: Add Solo Mode provider to main.dart
  ```
  Note: SoloModeCubit is created locally in SoloModeScreen using BlocProvider,
  so no global provider needed in main.dart
  ```
  ```dart
  // Add SoloModeCubit to MultiBlocProvider
  ```

### 19.5 Testing

- ⬜ **TASK-19.5.1**: Test full Solo Mode flow
  ```
  1. Tap Solo on home
  2. Select Rhapsody topic
  3. Configure: 10 questions, 15s
  4. Start quiz
  5. Answer all questions
  6. View results
  7. Verify coin reward (if applicable)
  ```

- ⬜ **TASK-19.5.2**: Test edge cases
  ```
  - Topic with < requested questions
  - 5 questions with 100% (no coin)
  - 10 questions with 100% (+1 coin)
  - Time expiry on question
  ```

### Task Summary

| Section | Tasks | Status |
|---------|-------|--------|
| 19.1 Backend: Random Questions API | 3 | ✅ Completed |
| 19.2 Mobile: Solo Mode UI | 3 | ✅ Completed |
| 19.3 Mobile: State Management | 2 | ✅ Completed |
| 19.4 Integration | 3 | ✅ Completed |
| 19.5 Testing | 2 | ⬜ Pending (manual testing) |
| **TOTAL** | **13 Tasks** | ✅ ~85% Complete |

### Implementation Order

1. **Backend API:** 19.1 (random questions + submit)
2. **State Management:** 19.3 (cubit + data source)
3. **UI:** 19.2 (screens)
4. **Integration:** 19.4 (wire up)
5. **Testing:** 19.5 (validation)

---

**Last Updated:** December 28, 2024  
**Current Focus:** Groups & Multiplayer Mode + Solo Mode  
**Next Priority:** Phase 18 (Groups) or Phase 19 (Solo Mode)

