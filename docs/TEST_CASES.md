# Rhapsody Quiz - Test Cases

## Table of Contents
1. [Daily Contest](#1-daily-contest)
2. [Solo Mode](#2-solo-mode)
3. [Leaderboard](#3-leaderboard)
4. [Regular Quiz (Rhapsody/Foundation)](#4-regular-quiz)
5. [Multiplayer Battles](#5-multiplayer-battles)
6. [Offline Functionality](#6-offline-functionality)
7. [Notifications](#7-notifications)
8. [User Profile](#8-user-profile)

---

## 1. Daily Contest

### TC-DC-001: Complete Daily Contest Successfully
**Preconditions:** User is logged in, daily contest exists, user hasn't completed today's contest

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Navigate to Contest screen | Daily Rhapsody card shows "Play Now" |
| 2 | Tap on Daily Rhapsody card | Reading screen appears with today's Rhapsody text |
| 3 | Read the text and tap "Start Quiz" | Quiz screen appears with first question |
| 4 | Answer all 5 questions correctly (select "b" for test data) | Feedback shows correct for each answer |
| 5 | After last question | Result screen appears |
| 6 | Check score | Score shows 10/10 (5 reading + 5 quiz) |
| 7 | Tap "Done" | Returns to Contest screen |
| 8 | Check Daily Rhapsody card | Shows "Completed" with score |
| 9 | Navigate to Leaderboard | User's score is updated |

### TC-DC-002: Contest Already Completed
**Preconditions:** User has already completed today's contest

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Navigate to Contest screen | Daily Rhapsody card shows "Completed" with score |
| 2 | Tap on card | Shows completion message, cannot replay |

### TC-DC-003: Contest While Offline
**Preconditions:** Device is offline

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Navigate to Contest screen | Shows "Connect to the internet" message |
| 2 | Tap refresh button | Still shows offline message |
| 3 | Enable internet connection | Contest loads normally |

### TC-DC-004: Exit Contest Early
**Preconditions:** User is in the middle of a contest

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Start daily contest | Quiz screen appears |
| 2 | Answer 2 questions | 2 questions answered |
| 3 | Tap back button | Exit confirmation dialog appears |
| 4 | Tap "Leave & Collect" | Partial score submitted, returns to Contest screen |
| 5 | Try to start contest again | Shows "Already completed" |

---

## 2. Solo Mode

### TC-SM-001: Complete Solo Mode Quiz (Rhapsody)
**Preconditions:** User is logged in, has sufficient coins if required

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Navigate to Solo Mode | Topic selection screen appears |
| 2 | Select "Rhapsody" topic | Question count selector appears |
| 3 | Select 5 questions | Confirm and start |
| 4 | Answer all questions correctly | Feedback shows for each |
| 5 | Complete quiz | Result screen with score, source labels shown |
| 6 | Tap "Review Answers" | Shows all questions with sources (e.g., "Rhapsody - Dec 25, 2025") |
| 7 | Check coin reward | If 5+ questions and 100% correct, coins awarded |

### TC-SM-002: Solo Mode Foundation Quiz
**Preconditions:** Foundation content exists

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Navigate to Solo Mode | Topic selection screen appears |
| 2 | Select "Foundation" topic | Question count selector appears |
| 3 | Answer questions | Explanation/note is NOT shown (hidden for Foundation) |
| 4 | Complete quiz | Result screen shows sources (e.g., "Foundation - Module 1: Title") |

### TC-SM-003: Solo Mode Lifelines
**Preconditions:** User is in Solo Mode quiz

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Start a question | All lifelines available |
| 2 | Tap 50/50 | Two wrong options are hidden |
| 3 | Next question, tap Audience Poll | Poll percentages shown on options |
| 4 | Next question, tap Reset Time | Timer resets to full time |
| 5 | Each lifeline | Can only be used once per quiz |

### TC-SM-004: Solo Mode Coin Reward
**Preconditions:** User completes quiz with 5+ questions

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Complete 5-question quiz with 100% correct | "You earned X coins!" message |
| 2 | Return to home screen | Coin balance updated |
| 3 | Complete 4-question quiz with 100% correct | No coin reward (< 5 questions) |

---

## 3. Leaderboard

### TC-LB-001: View Leaderboards
**Preconditions:** User is logged in

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Navigate to Leaderboard tab | This Week tab is shown by default |
| 2 | Check podium | Top 3 users shown with avatars |
| 3 | Scroll down | Other users listed with ranks |
| 4 | Tap "This Month" tab | Monthly leaderboard loads |
| 5 | Tap "All Time" tab | All-time leaderboard loads |

### TC-LB-002: Dense Ranking (Ex Aequo)
**Preconditions:** Multiple users have same score

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | View leaderboard with tied users | Tied users show same rank number |
| 2 | Check "ex æquo" label | Shows for tied users in list |
| 3 | If current user is tied for podium | Current user shown on podium (priority) |

### TC-LB-003: Leaderboard Refresh After Contest
**Preconditions:** User just completed a contest

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Complete daily contest | Score submitted |
| 2 | Tap "Done" to return | Home screen refreshes |
| 3 | Navigate to Leaderboard | New score reflected in ranking |
| 4 | Pull to refresh | Leaderboard updates |

---

## 4. Regular Quiz

### TC-RQ-001: Rhapsody Quiz
**Preconditions:** Rhapsody content exists

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Navigate to Rhapsody section | Years list appears |
| 2 | Select year, month, day | Day detail with text and quiz button |
| 3 | Tap "Start Quiz" | Quiz loads |
| 4 | Answer questions | Feedback shown |
| 5 | Complete quiz | Result screen with score |
| 6 | Check source in review | Shows "Rhapsody - [Date]" |

### TC-RQ-002: Foundation Quiz
**Preconditions:** Foundation classes exist

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Navigate to Foundation section | Classes list appears |
| 2 | Select a class | Class detail with modules |
| 3 | Start module quiz | Quiz loads |
| 4 | Complete quiz | Result screen |
| 5 | Check source in review | Shows "Foundation - [Module Title]" |

---

## 5. Multiplayer Battles

### TC-MB-001: 1v1 Random Battle
**Preconditions:** Two users online

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Navigate to Battle Mode | 1v1 and Group options shown |
| 2 | Select 1v1 Random | Topic selection appears |
| 3 | Select topic (Rhapsody/Foundation) | Entry fee shown |
| 4 | Tap "Let's Play" | Searching for opponent... |
| 5 | Opponent found | Battle begins |
| 6 | Answer questions | Real-time scores shown |
| 7 | Complete battle | Winner announced, coins awarded |

### TC-MB-002: Group Battle Room Creation
**Preconditions:** User is logged in

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Navigate to Battle Mode | Options shown |
| 2 | Select Group Battle | Create/Join options |
| 3 | Tap "Create Room" | Topic selection appears |
| 4 | Select topic and entry fee | Room created with code |
| 5 | Share room code | Other users can join |
| 6 | Users join | Player cards update in waiting room |
| 7 | Start game | Battle begins for all players |

### TC-MB-003: Battle Result Accuracy
**Preconditions:** User completes a battle

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Complete battle with known answers | All correct = 100% |
| 2 | Check result summary | Correct count matches answers given |
| 3 | Winner takes entry fees | Coins = entry × 2 |

---

## 6. Offline Functionality

### TC-OF-001: Offline Rhapsody Reading
**Preconditions:** User previously viewed Rhapsody content while online

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Go offline | Network disabled |
| 2 | Navigate to Rhapsody | Cached content loads |
| 3 | Read day's content | Text displays correctly |

### TC-OF-002: Offline Foundation Reading
**Preconditions:** User previously viewed Foundation content while online

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Go offline | Network disabled |
| 2 | Navigate to Foundation | Cached classes load |
| 3 | View class details | Content displays from cache |

### TC-OF-003: Offline Contest Blocked
**Preconditions:** Device is offline

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Go offline | Network disabled |
| 2 | Navigate to Contest | "Connect to internet" message |
| 3 | Cannot start contest | Contest requires online |

### TC-OF-004: Offline Solo Mode (Cached Questions)
**Preconditions:** Questions were cached during online session

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Go offline | Network disabled |
| 2 | Start Solo Mode | Topics available |
| 3 | Select topic with cached questions | Quiz starts from cache |
| 4 | Complete quiz | Score calculated locally |

---

## 7. Notifications

### TC-NT-001: New Contest Notification
**Preconditions:** FCM configured, user subscribed to topic

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Admin creates new daily contest | Notification sent |
| 2 | User receives push notification | Shows "New Daily Quiz Available!" |
| 3 | Tap notification | Opens app to Contest screen |

### TC-NT-002: Clear Notifications
**Preconditions:** User has notifications

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Navigate to Notifications | List of notifications shown |
| 2 | Tap trash icon | Confirmation dialog appears |
| 3 | Confirm clear | All notifications removed |
| 4 | Check empty state | Shows "No notifications" |

### TC-NT-003: Notification Bell Animation
**Preconditions:** User has pending contest

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | View home screen with pending contest | Bell icon jiggles |
| 2 | Observe animation | Quick jiggle + vertical bounce every 5s |
| 3 | Badge pulses | Red badge has glow effect |

---

## 8. User Profile

### TC-UP-001: View Profile
**Preconditions:** User is logged in

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Navigate to Profile tab | User info displayed |
| 2 | Check coins | Balance matches earned coins |
| 3 | Check rank | Matches leaderboard position |
| 4 | Check badges | Earned badges shown |

### TC-UP-002: Coin Balance Updates
**Preconditions:** User completes rewarded activity

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Note current coin balance | X coins |
| 2 | Complete Solo Mode (5+ questions, 100%) | Reward earned |
| 3 | Return to home | Balance = X + reward |
| 4 | Win a battle | Balance increases by entry × 2 |

---

## Test Data Setup

### Create Test Contest
```bash
./scripts/create_daily_contest.sh --force
```

### Reset User Scores
```sql
DELETE FROM tbl_contest_leaderboard WHERE user_id = [USER_ID];
```

### Check Current Scores
```sql
SELECT cl.user_id, u.name, cl.contest_id, cl.score 
FROM tbl_contest_leaderboard cl
JOIN tbl_users u ON u.id = cl.user_id
ORDER BY cl.id DESC LIMIT 10;
```

### Add Test Coins
```sql
UPDATE tbl_users SET coins = coins + 100 WHERE id = [USER_ID];
```

---

## Known Test Answers

For test contests, all correct answers are typically **"b"**.

Check current contest answers:
```sql
SELECT id, question, answer 
FROM tbl_contest_question 
WHERE contest_id = (SELECT MAX(id) FROM tbl_contest WHERE contest_type = 'daily');
```

