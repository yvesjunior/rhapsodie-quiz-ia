# Quiz Zone "Unable to Find Data" - Fix Guide

## Problem
The mobile app shows "Unable to find data" error when accessing Quiz Zone.

## Root Cause
The database is empty:
- **0 questions** in `tbl_question` table
- **0 quiz zone categories** in `tbl_category` table (type='1')

When the app tries to fetch questions, the API returns error code `102` (data not found).

## Solution
Add quiz zone data through the admin panel.

## Steps to Fix

### 1. Access Admin Panel
- Open: http://localhost:8080
- Login with your admin credentials

### 2. Enable Quiz Zone Mode
1. Go to **System Configurations**
2. Find **Quiz Zone Mode** setting
3. Enable it (set to `1` or ON)
4. Save changes

### 3. Add Quiz Zone Categories
1. Go to **Categories** → **Main Category**
2. Click **Add Category**
3. Set **Type** to `1` (Quiz Zone)
4. Fill in:
   - Category Name
   - Image (optional)
   - Description (optional)
   - Language
5. Save

### 4. Add Questions to Categories
1. Go to **Questions** → **Add Question**
2. Select the **Category** you created
3. For Quiz Zone questions, set:
   - **Type**: Quiz Zone (type='1')
   - **Level**: Set a level number (1, 2, 3, etc.)
   - **Category**: Select your quiz zone category
   - **Subcategory**: Optional (leave empty if no subcategories)
   - **Question**: Enter your question
   - **Options**: Add 4 answer options
   - **Correct Answer**: Select the correct option
4. Save the question

### 5. Verify Data
After adding data, verify:
- Categories exist with type='1'
- Questions exist with proper category and level assignments
- Questions have valid answers

### 6. Test in Mobile App
1. Restart the mobile app
2. Navigate to Quiz Zone tab
3. You should now see categories and be able to play quizzes

## Quick Database Check

To verify data was added, run:
```bash
cd "Elite Quiz - Admin Panel - v2.3.7"
docker exec elite-quiz-admin-db mysql -uroot -prootpassword elite_quiz_237 -e "SELECT COUNT(*) as total_questions FROM tbl_question;"
docker exec elite-quiz-admin-db mysql -uroot -prootpassword elite_quiz_237 -e "SELECT COUNT(*) as total_categories FROM tbl_category WHERE type='1';"
```

## Notes
- Quiz Zone questions require a **level** field (1, 2, 3, etc.)
- Categories without levels use level='0' when fetching questions
- Make sure **Quiz Zone Mode** is enabled in system configurations
- Questions must be assigned to the correct category type (type='1')

## API Endpoints Used
- `get_categories` - Fetches quiz zone categories
- `get_questions_by_level` - Fetches questions for a specific level
- `get_questions` - Fetches questions when level=0

## Error Codes
- `102` = Data not found (no questions/categories in database)
- `103` = Fill all data (missing required parameters)

