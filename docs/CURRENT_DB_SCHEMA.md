# Current Database Schema - Rhapsody Quiz 237

**Generated:** 2025-12-27  
**Database:** elite_quiz_237  
**Size:** ~1.63 MB  
**Total Tables:** 56

---

## Table of Contents
1. [User & Authentication Tables](#1-user--authentication-tables)
2. [Category & Content Tables](#2-category--content-tables)
3. [Question Tables](#3-question-tables)
4. [Game Mode Tables](#4-game-mode-tables)
5. [Contest Tables](#5-contest-tables)
6. [User Progress & Session Tables](#6-user-progress--session-tables)
7. [Leaderboard & Statistics Tables](#7-leaderboard--statistics-tables)
8. [Configuration & System Tables](#8-configuration--system-tables)
9. [E-Commerce Tables](#9-e-commerce-tables)
10. [Relationships Diagram](#10-relationships-diagram)

---

## 1. User & Authentication Tables

### `tbl_users`
Main user table storing all registered users.

| Column | Type | Nullable | Key | Default | Notes |
|--------|------|----------|-----|---------|-------|
| id | int unsigned | NO | PRI | AUTO | Primary key |
| firebase_id | longtext | NO | MUL | - | Firebase auth ID |
| name | varchar(128) | NO | - | '' | User display name |
| email | varchar(128) | NO | MUL | - | User email |
| mobile | varchar(32) | NO | - | - | Phone number |
| type | varchar(16) | NO | - | - | Login type (google, phone, etc.) |
| profile | varchar(128) | NO | - | - | Profile image path |
| fcm_id | varchar(1024) | YES | MUL | - | Firebase Cloud Messaging token (mobile) |
| web_fcm_id | varchar(1024) | YES | MUL | - | FCM token (web) |
| coins | int | NO | - | 0 | User coin balance |
| refer_code | varchar(128) | YES | - | - | User's referral code |
| friends_code | varchar(128) | YES | - | - | Referral code used |
| remove_ads | tinyint | NO | - | 0 | Ad-free status |
| daily_ads_counter | int | NO | - | 0 | Daily ad view count |
| daily_ads_date | date | NO | - | '2023-10-19' | Last ad view date |
| status | int unsigned | YES | - | 0 | Account status |
| date_registered | datetime | NO | - | - | Registration timestamp |
| api_token | longtext | NO | - | - | JWT auth token |
| app_language | varchar(512) | YES | - | - | Preferred app language |
| web_language | varchar(512) | YES | - | - | Preferred web language |

### `tbl_authenticate`
Admin panel authentication.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| auth_id | int | NO | PRI | AUTO |
| auth_username | varchar(12) | NO | UNI | - |
| auth_pass | text | NO | - | - |
| role | varchar(32) | NO | - | - |
| permissions | mediumtext | NO | - | - |
| status | int | NO | - | 0 |
| language | varchar(255) | NO | - | 'english' |
| created | datetime | NO | - | - |

### `tbl_users_badges`
User badge progress and achievements.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| user_id | int | NO | - | - |
| dashing_debut | int | NO | - | - |
| dashing_debut_counter | int | NO | - | - |
| combat_winner | int | NO | - | - |
| combat_winner_counter | int | NO | - | - |
| clash_winner | int | NO | - | - |
| clash_winner_counter | int | NO | - | - |
| most_wanted_winner | int | NO | - | - |
| most_wanted_winner_counter | int | NO | - | - |
| ultimate_player | int | NO | - | - |
| quiz_warrior | int | NO | - | - |
| quiz_warrior_counter | int | NO | - | - |
| super_sonic | int | NO | - | - |
| flashback | int | NO | - | - |
| brainiac | int | NO | - | - |
| big_thing | int | NO | - | - |
| elite | int | NO | - | - |
| thirsty | int | NO | - | - |
| thirsty_date | date | YES | - | - |
| thirsty_counter | int | NO | - | - |
| power_elite | int | NO | - | - |
| power_elite_counter | int | NO | - | - |
| sharing_caring | int | NO | - | - |
| streak | int | NO | - | - |
| streak_date | date | YES | - | - |
| streak_counter | int | NO | - | - |

### `tbl_users_statistics`
User performance statistics.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| user_id | int | NO | MUL | - |
| questions_answered | int | NO | - | - |
| correct_answers | int | NO | - | - |
| strong_category | int | NO | - | - |
| ratio1 | double | NO | - | - |
| weak_category | int | NO | - | - |
| ratio2 | double | NO | - | - |
| best_position | int | NO | - | - |
| date_created | datetime | NO | - | - |

---

## 2. Category & Content Tables

### `tbl_category`
Main quiz categories.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| language_id | int | NO | MUL | 0 |
| category_name | varchar(250) | NO | - | - |
| slug | varchar(250) | YES | - | - |
| type | int | NO | - | - |
| is_premium | tinyint | NO | - | 0 |
| coins | int | NO | - | 0 |
| image | text | YES | - | - |
| row_order | int | NO | - | - |

### `tbl_subcategory`
Subcategories linked to main categories.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| language_id | int | NO | MUL | 0 |
| maincat_id | int | NO | MUL | - |
| subcategory_name | varchar(250) | NO | - | - |
| slug | varchar(250) | YES | - | - |
| image | text | YES | - | - |
| status | tinyint | NO | - | 1 |
| is_premium | tinyint | NO | - | 0 |
| coins | int | NO | - | 0 |
| row_order | int | NO | - | - |

### `tbl_quiz_categories`
User quiz category selections/unlocks.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| user_id | int | NO | MUL | - |
| type | int | NO | MUL | - |
| type_id | int | NO | - | - |
| category | int | NO | - | - |
| subcategory | int | NO | - | - |

### `tbl_user_category`
User category associations.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| user_id | int | NO | MUL | - |
| category_id | int | NO | - | - |

### `tbl_fun_n_learn`
Fun & Learn content (learning material with quizzes).

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| language_id | int | NO | - | 0 |
| category | int | NO | MUL | - |
| subcategory | int | NO | MUL | - |
| title | text | NO | - | - |
| detail | longtext | NO | - | - |
| status | int | NO | - | 0 |
| content_type | tinyint | NO | - | 0 |
| content_data | varchar(255) | NO | - | - |

---

## 3. Question Tables

### `tbl_question`
Main quiz questions.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| category | int | NO | MUL | - |
| subcategory | int | NO | MUL | - |
| language_id | int | NO | MUL | 0 |
| image | varchar(512) | NO | - | - |
| question | text | NO | - | - |
| question_type | tinyint | NO | - | - |
| optiona | text | NO | - | - |
| optionb | text | NO | - | - |
| optionc | text | NO | - | - |
| optiond | text | NO | - | - |
| optione | text | YES | - | - |
| answer | text | NO | - | - |
| level | int | NO | - | - |
| note | text | NO | - | - |

### `tbl_ai_questions`
AI-generated questions.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | bigint | NO | PRI | AUTO |
| language_id | int | NO | - | 0 |
| quiz_type | int | NO | - | 0 |
| contest_id | int | NO | - | 0 |
| exam_id | int | NO | - | 0 |
| category | int | NO | - | - |
| subcategory | int | NO | - | 0 |
| level | int | NO | - | 0 |
| question_type | int | NO | - | 0 |
| answer_type | int | NO | - | 0 |
| question | text | NO | - | - |
| options | longtext | NO | - | - |
| correct_answer | varchar(50) | NO | - | - |
| marks | int | NO | - | 0 |
| status | int | NO | - | 0 |
| note | varchar(255) | YES | - | - |
| date_time | datetime | NO | - | - |

### `tbl_audio_question`
Audio-based quiz questions.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| category | int | NO | MUL | - |
| subcategory | int | NO | MUL | - |
| language_id | int | NO | MUL | 0 |
| audio_type | int | NO | - | - |
| audio | varchar(255) | NO | - | - |
| question | text | NO | - | - |
| question_type | tinyint | NO | - | - |
| optiona - optione | text | - | - | - |
| answer | text | NO | - | - |
| note | text | NO | - | - |

### `tbl_maths_question`
Math quiz questions.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| category | int | NO | MUL | - |
| subcategory | int | NO | MUL | - |
| language_id | int | NO | MUL | 0 |
| image | varchar(512) | NO | - | - |
| question | text | NO | - | - |
| question_type | tinyint | NO | - | - |
| optiona - optione | text | - | - | - |
| answer | text | NO | - | - |
| note | text | NO | - | - |

### `tbl_guess_the_word`
Guess the word game questions.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| language_id | int | NO | - | - |
| category | int | NO | MUL | - |
| subcategory | int | NO | MUL | - |
| image | text | NO | - | - |
| question | text | NO | - | - |
| answer | text | NO | - | - |

### `tbl_multi_match`
Multi-match quiz questions.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| category | int | NO | MUL | - |
| subcategory | int | NO | MUL | - |
| language_id | int | NO | MUL | 0 |
| image | varchar(250) | NO | - | - |
| question | text | NO | - | - |
| question_type | tinyint | NO | - | - |
| optiona - optione | text | - | - | - |
| answer_type | tinyint | NO | - | - |
| answer | text | NO | - | - |
| level | int | NO | - | - |
| note | text | NO | - | - |

### `tbl_fun_n_learn_question`
Questions for Fun & Learn mode.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| fun_n_learn_id | int | NO | MUL | - |
| question | text | NO | - | - |
| question_type | int | NO | - | - |
| optiona - optione | text | - | - | - |
| answer | varchar(12) | NO | - | - |
| image | varchar(250) | NO | - | - |

### `tbl_question_reports` / `tbl_multi_match_question_reports`
User-reported questions.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| question_id | int | NO | MUL | - |
| user_id | int | NO | MUL | - |
| message | varchar(512) | NO | - | - |
| date | datetime | NO | - | - |

---

## 4. Game Mode Tables

### `tbl_battle_questions`
1v1 Battle questions storage.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| match_id | varchar(128) | NO | UNI | - |
| entry_coin | int | NO | - | 0 |
| questions | longtext | NO | - | - |
| date_created | datetime | NO | - | - |
| set_user1 | int | NO | - | 0 |
| set_user2 | int | NO | - | 0 |

### `tbl_battle_statistics`
Battle match results.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| user_id1 | int | NO | MUL | - |
| user_id2 | int | NO | MUL | - |
| is_drawn | tinyint | NO | - | - |
| winner_id | int | NO | - | - |
| date_created | datetime | NO | - | - |

### `tbl_rooms`
Multiplayer room management.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| room_id | text | NO | - | - |
| entry_coin | int | NO | - | 0 |
| user_id | int | NO | MUL | - |
| room_type | varchar(11) | NO | - | - |
| category_id | int | NO | MUL | - |
| no_of_que | int | NO | - | - |
| questions | longtext | NO | - | - |
| date_created | datetime | NO | - | - |
| set_user1 | int | NO | - | 0 |
| set_user2 | int | NO | - | 0 |
| set_user3 | int | NO | - | 0 |
| set_user4 | int | NO | - | 0 |

### `tbl_daily_quiz`
Daily quiz assignments.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| language_id | int | NO | MUL | - |
| questions_id | text | NO | - | - |
| date_published | date | NO | - | - |

### `tbl_daily_quiz_user`
Daily quiz participation tracking.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| user_id | int | NO | - | - |
| date | date | NO | - | - |

### `tbl_exam_module`
Exam modules.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| language_id | int | NO | MUL | 0 |
| title | text | NO | - | - |
| date | date | NO | - | - |
| exam_key | varchar(100) | NO | - | - |
| duration | int | NO | - | - |
| status | int | NO | - | 0 |
| answer_again | int | NO | - | - |

### `tbl_exam_module_question`
Exam questions.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| exam_module_id | int | NO | MUL | - |
| image | varchar(512) | NO | - | - |
| marks | int | NO | - | - |
| question | text | NO | - | - |
| question_type | tinyint | NO | - | - |
| optiona - optione | text | - | - | - |
| answer | text | NO | - | - |

### `tbl_exam_module_result`
Exam results.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| exam_module_id | int | NO | MUL | - |
| user_id | int | NO | MUL | - |
| obtained_marks | varchar(200) | NO | - | - |
| total_duration | varchar(20) | NO | - | - |
| statistics | longtext | NO | - | - |
| status | int | NO | - | - |
| rules_violated | tinyint | NO | - | - |
| captured_question_ids | text | NO | - | - |

---

## 5. Contest Tables

### `tbl_contest`
Contest definitions.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| language_id | int | NO | MUL | 0 |
| name | text | NO | - | - |
| start_date | datetime | NO | - | - |
| end_date | datetime | NO | - | - |
| description | text | NO | - | - |
| image | varchar(512) | NO | - | - |
| entry | int | NO | - | - |
| prize_status | int | NO | - | - |
| date_created | datetime | NO | - | - |
| status | int | NO | - | - |

### `tbl_contest_question`
Contest-specific questions.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| langauge_id | int | NO | - | 0 |
| contest_id | int | NO | MUL | - |
| image | varchar(256) | NO | - | - |
| question | text | NO | - | - |
| question_type | int | NO | - | - |
| optiona - optione | text | - | - | - |
| answer | varchar(12) | NO | - | - |
| note | text | NO | - | - |

### `tbl_contest_leaderboard`
Contest rankings.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| user_id | int | NO | MUL | - |
| contest_id | int | NO | MUL | - |
| questions_attended | int | NO | - | - |
| correct_answers | int | NO | - | - |
| score | double | NO | MUL | - |
| last_updated | datetime | NO | - | - |
| date_created | datetime | NO | - | - |

### `tbl_contest_prize`
Contest prize configuration.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| contest_id | int | NO | MUL | - |
| top_winner | int | NO | - | - |
| points | int | NO | - | - |

---

## 6. User Progress & Session Tables

### User Session Tables (Common Structure)
These tables track user quiz sessions for different game modes:
- `tbl_user_quiz_zone_session`
- `tbl_user_audio_quiz_session`
- `tbl_user_maths_quiz_session`
- `tbl_user_fun_n_learn_session`
- `tbl_user_guess_the_word_session`
- `tbl_user_multi_match_session`
- `tbl_user_contest_session`
- `tbl_user_daily_quiz_session`
- `tbl_user_true_false_session`

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | bigint | NO | PRI | AUTO |
| user_id | int | NO | MUL | - |
| questions | longtext | NO | MUL | - |
| date | date | YES | - | - |

### `tbl_level`
User level progress.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| user_id | int | NO | MUL | - |
| category | int | NO | MUL | - |
| subcategory | int | NO | MUL | - |
| level | int | NO | - | - |

### `tbl_multi_match_level`
Multi-match level progress.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| user_id | int | NO | MUL | - |
| category | int | NO | MUL | - |
| subcategory | int | NO | MUL | - |
| level | int | NO | - | - |

### `tbl_bookmark`
User question bookmarks.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| user_id | int | NO | MUL | - |
| question_id | int | NO | MUL | - |
| status | int | NO | - | - |
| type | int | NO | - | - |

### `tbl_tracker`
User activity/points tracker.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| user_id | int | NO | MUL | - |
| uid | text | NO | - | - |
| points | varchar(255) | NO | - | - |
| type | text | NO | - | - |
| status | tinyint | NO | - | - |
| date | date | NO | - | - |

---

## 7. Leaderboard & Statistics Tables

### `tbl_leaderboard_daily`
Daily leaderboard scores.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| user_id | int | NO | MUL | - |
| score | int | NO | - | - |
| date_created | datetime | NO | - | - |

### `tbl_leaderboard_monthly`
Monthly leaderboard scores.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| user_id | int | NO | MUL | - |
| score | int | NO | - | - |
| last_updated | datetime | NO | - | - |
| date_created | datetime | NO | - | - |

---

## 8. Configuration & System Tables

### `tbl_settings`
System-wide settings.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| type | varchar(512) | NO | - | - |
| message | text | NO | - | - |

### `tbl_web_settings`
Web-specific settings (per language).

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| language_id | int | YES | - | 14 |
| type | varchar(32) | NO | - | - |
| message | text | YES | - | - |

### `tbl_languages`
Supported quiz languages.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| language | varchar(64) | NO | - | - |
| code | varchar(11) | NO | - | - |
| status | tinyint | NO | - | 0 |
| type | tinyint | NO | - | 0 |
| default_active | tinyint | NO | - | 0 |

### `tbl_upload_languages`
Uploaded language packs.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| name | varchar(512) | NO | - | - |
| title | varchar(512) | NO | - | - |
| app_version | varchar(100) | NO | - | '0' |
| web_version | varchar(100) | NO | - | '0' |
| app_rtl_support | tinyint | NO | - | 0 |
| web_rtl_support | tinyint | NO | - | 0 |
| app_status | tinyint | NO | - | 0 |
| web_status | tinyint | NO | - | 0 |
| app_default | tinyint | NO | - | 0 |
| web_default | tinyint | NO | - | 0 |

### `tbl_badges`
Badge definitions.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| language_id | int | YES | - | 14 |
| type | varchar(100) | NO | - | - |
| badge_label | varchar(200) | NO | - | - |
| badge_note | text | NO | - | - |
| badge_reward | int | NO | - | - |
| badge_icon | varchar(100) | NO | - | - |
| badge_counter | int | NO | - | - |

### `tbl_slider`
Home screen slider images.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| language_id | int | NO | MUL | - |
| image | varchar(255) | NO | - | - |
| title | text | NO | - | - |
| description | text | NO | - | - |

### `tbl_notifications`
Push notification history.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| title | varchar(128) | NO | - | - |
| message | text | NO | - | - |
| users | varchar(8) | NO | - | 'all' |
| user_id | longtext | YES | - | - |
| type | varchar(250) | NO | - | - |
| type_id | int | NO | - | - |
| image | varchar(128) | NO | - | - |
| date_sent | datetime | NO | - | - |

### `tbl_month_week`
Month/Week reference data.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| name | varchar(100) | NO | - | - |
| type | int | NO | - | - |

---

## 9. E-Commerce Tables

### `tbl_coin_store`
In-app coin packages.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| title | varchar(50) | NO | - | - |
| coins | int | NO | - | - |
| type | int | NO | - | 0 |
| product_id | varchar(150) | NO | UNI | - |
| image | text | YES | - | - |
| description | text | NO | - | - |
| status | tinyint | NO | - | 1 |

### `tbl_users_in_app`
In-app purchase records.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| pay_from | tinyint | NO | - | - |
| uid | longtext | NO | MUL | - |
| user_id | int | NO | MUL | - |
| product_id | text | NO | MUL | - |
| amount | int | NO | - | - |
| status | varchar(50) | NO | - | - |
| transaction_id | text | NO | - | - |
| date | datetime | NO | - | - |
| purchase_token | longtext | NO | - | - |
| responseData | longtext | NO | - | - |

### `tbl_payment_request`
User withdrawal/payment requests.

| Column | Type | Nullable | Key | Default |
|--------|------|----------|-----|---------|
| id | int | NO | PRI | AUTO |
| user_id | int | NO | MUL | - |
| uid | text | NO | - | - |
| payment_type | varchar(100) | NO | - | - |
| payment_address | varchar(225) | NO | - | - |
| payment_amount | varchar(20) | NO | - | - |
| coin_used | varchar(20) | NO | - | - |
| details | text | NO | - | - |
| status | tinyint | NO | - | - |
| date | datetime | NO | - | - |
| status_date | datetime | YES | - | - |

---

## 10. Relationships Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              USER ECOSYSTEM                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│   tbl_users ────────────────────────────────────────────────────────────────│
│       │                                                                       │
│       ├──► tbl_users_badges (1:1)                                            │
│       ├──► tbl_users_statistics (1:1)                                        │
│       ├──► tbl_level (1:N)                                                   │
│       ├──► tbl_bookmark (1:N)                                                │
│       ├──► tbl_tracker (1:N)                                                 │
│       ├──► tbl_user_*_session (1:N) [9 session tables]                       │
│       ├──► tbl_leaderboard_daily (1:N)                                       │
│       ├──► tbl_leaderboard_monthly (1:N)                                     │
│       ├──► tbl_battle_statistics (1:N)                                       │
│       ├──► tbl_rooms (1:N)                                                   │
│       ├──► tbl_contest_leaderboard (1:N)                                     │
│       └──► tbl_exam_module_result (1:N)                                      │
│                                                                               │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                            CONTENT HIERARCHY                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│   tbl_languages ─────────────────────────────────────────────────────────────│
│       │                                                                       │
│       ├──► tbl_category                                                      │
│       │       │                                                               │
│       │       └──► tbl_subcategory                                           │
│       │               │                                                       │
│       │               ├──► tbl_question                                       │
│       │               ├──► tbl_audio_question                                 │
│       │               ├──► tbl_maths_question                                 │
│       │               ├──► tbl_guess_the_word                                 │
│       │               ├──► tbl_multi_match                                    │
│       │               └──► tbl_fun_n_learn ──► tbl_fun_n_learn_question      │
│       │                                                                       │
│       ├──► tbl_contest ──► tbl_contest_question                              │
│       │                └──► tbl_contest_prize                                 │
│       │                                                                       │
│       ├──► tbl_exam_module ──► tbl_exam_module_question                      │
│       │                                                                       │
│       └──► tbl_daily_quiz                                                    │
│                                                                               │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                              GAME MODES                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│   Battle Mode (1v1)                                                          │
│   ├── tbl_battle_questions (question storage per match)                      │
│   └── tbl_battle_statistics (match results)                                  │
│                                                                               │
│   Multiplayer Mode (Group)                                                   │
│   └── tbl_rooms (room management, up to 4 players)                          │
│                                                                               │
│   Contest Mode                                                               │
│   ├── tbl_contest                                                            │
│   ├── tbl_contest_question                                                   │
│   ├── tbl_contest_leaderboard                                                │
│   └── tbl_contest_prize                                                      │
│                                                                               │
│   Exam Mode                                                                  │
│   ├── tbl_exam_module                                                        │
│   ├── tbl_exam_module_question                                               │
│   └── tbl_exam_module_result                                                 │
│                                                                               │
│   Daily Quiz                                                                 │
│   ├── tbl_daily_quiz                                                         │
│   └── tbl_daily_quiz_user                                                    │
│                                                                               │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Notes for Migration

### Tables to Keep/Modify
- `tbl_users` - Keep, add new fields for topics
- `tbl_category` - Modify to support new topic hierarchy
- `tbl_question` - Keep, link to new category structure

### Tables to Create
- `tbl_topic` - New: Rhapsody, Foundation School
- `tbl_user_progress` - New: Unified progress tracking
- `tbl_group` - New: Group management
- `tbl_group_member` - New: Group memberships
- `tbl_group_battle` - New: Group battles
- `tbl_battle_1v1` - New: Refactored 1v1 battles

### Tables to Deprecate
- `tbl_exam_module*` - Merge into Foundation School
- `tbl_fun_n_learn*` - Merge into Foundation School
- `tbl_guess_the_word` - Remove (not in MVP)
- `tbl_audio_question` - Remove (not in MVP)
- `tbl_maths_question` - Remove (not in MVP)
- `tbl_multi_match*` - Remove (not in MVP)

---

*This document serves as a reference for the database migration from the current Rhapsody Quiz schema to the new Rhapsody platform.*

