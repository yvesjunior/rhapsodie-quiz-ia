#!/usr/bin/env php
<?php
/**
 * Script to manually create daily contest for testing
 * 
 * Usage: 
 *   docker compose exec rhapsody-web php /var/www/html/create_daily_contest.php
 *   docker compose exec rhapsody-web php /var/www/html/create_daily_contest.php --force   # Delete and recreate
 *   docker compose exec rhapsody-web php /var/www/html/create_daily_contest.php --reset   # Reset user completion status
 * 
 * This script directly connects to the database and creates today's daily contest
 * from the current day's Rhapsody content.
 */

// Parse command line arguments
$force = in_array('--force', $argv) || in_array('-f', $argv);
$reset = in_array('--reset', $argv) || in_array('-r', $argv);

if (in_array('--help', $argv) || in_array('-h', $argv)) {
    echo "Usage: php create_daily_contest.php [OPTIONS]\n\n";
    echo "Options:\n";
    echo "  --force, -f    Delete existing contest and recreate it\n";
    echo "  --reset, -r    Reset user completion status for today's contest\n";
    echo "  --help, -h     Show this help message\n\n";
    exit(0);
}

// Load database configuration - use environment variables in Docker
$host = getenv('DB_HOST') ?: 'rhapsody-db';
$user = getenv('DB_USER') ?: 'root';
$pass = getenv('DB_PASSWORD') ?: 'NcFgxKO4Fez7h6C2EYrbZk0NiwVPTrlO';
$dbname = getenv('DB_NAME') ?: 'elite_quiz_237';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "Connected to database successfully.\n\n";
    
    $today = date('Y-m-d');
    $now = new DateTime();
    $day = (int)$now->format('j');
    $month = (int)$now->format('n');
    $year = (int)$now->format('Y');
    $month_name = $now->format('F');
    
    echo "Creating daily contest for: $month_name $day, $year\n";
    
    // Check if daily contest already exists for today
    $stmt = $pdo->prepare("SELECT id FROM tbl_contest WHERE DATE(start_date) = ? AND contest_type = 'daily'");
    $stmt->execute([$today]);
    $existing = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($existing) {
        if ($force) {
            echo "⚠ Deleting existing contest (ID: {$existing['id']}) and its questions...\n";
            
            // Delete contest questions first
            $stmt = $pdo->prepare("DELETE FROM tbl_contest_question WHERE contest_id = ?");
            $stmt->execute([$existing['id']]);
            
            // Delete user contest sessions for today (table uses date, not contest_id)
            $stmt = $pdo->prepare("DELETE FROM tbl_user_contest_session WHERE date = ?");
            $stmt->execute([$today]);
            
            // Delete contest leaderboard entries
            $stmt = $pdo->prepare("DELETE FROM tbl_contest_leaderboard WHERE contest_id = ?");
            $stmt->execute([$existing['id']]);
            
            // Delete contest
            $stmt = $pdo->prepare("DELETE FROM tbl_contest WHERE id = ?");
            $stmt->execute([$existing['id']]);
            
            echo "✓ Deleted existing contest\n\n";
        } elseif ($reset) {
            echo "⚠ Resetting user completion status for contest (ID: {$existing['id']})...\n";
            
            // Delete user contest sessions for today (table uses date, not contest_id)
            $stmt = $pdo->prepare("DELETE FROM tbl_user_contest_session WHERE date = ?");
            $stmt->execute([$today]);
            
            // Delete contest leaderboard entries
            $stmt = $pdo->prepare("DELETE FROM tbl_contest_leaderboard WHERE contest_id = ?");
            $stmt->execute([$existing['id']]);
            
            echo "✓ Reset complete. You can now test the contest again.\n";
            echo "  Contest ID: {$existing['id']}\n";
            exit(0);
        } else {
            echo "✓ Daily contest already exists for today (ID: {$existing['id']})\n";
            echo "\nOptions:\n";
            echo "  --force   Delete and recreate the contest\n";
            echo "  --reset   Keep contest but reset your completion status\n";
            exit(0);
        }
    }
    
    // Find the Rhapsody topic (slug = 'rhapsody', topic_type = 'daily')
    $stmt = $pdo->query("SELECT id FROM tbl_topic WHERE slug = 'rhapsody' AND is_active = 1 LIMIT 1");
    $rhapsody_topic = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$rhapsody_topic) {
        die("Error: Rhapsody topic not found\n");
    }
    
    echo "Found Rhapsody topic ID: {$rhapsody_topic['id']}\n";
    
    // Find the day category for today's date
    // Uses: topic_id, category_type='day', year, month, day columns
    $stmt = $pdo->prepare("
        SELECT c.* 
        FROM tbl_category c 
        WHERE c.topic_id = ? 
        AND c.category_type = 'day'
        AND c.day = ? 
        AND c.month = ? 
        AND c.year = ?
    ");
    $stmt->execute([$rhapsody_topic['id'], $day, $month, $year]);
    $day_category = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$day_category) {
        die("Error: No Rhapsody content found for $month_name $day, $year\n");
    }
    
    echo "Found Rhapsody category ID: {$day_category['id']} ({$day_category['category_name']})\n";
    
    // Get questions from this category (random 5) with full data
    $stmt = $pdo->prepare("
        SELECT id, language_id, image, question, question_type, 
               optiona, optionb, optionc, optiond, optione, answer, note 
        FROM tbl_question 
        WHERE category = ? 
        ORDER BY RAND() 
        LIMIT 5
    ");
    $stmt->execute([$day_category['id']]);
    $questions = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($questions) < 5) {
        die("Error: Not enough questions for daily contest (need 5, found " . count($questions) . ")\n");
    }
    
    echo "Found " . count($questions) . " questions for the contest\n";
    
    // Create the daily contest
    $stmt = $pdo->prepare("
        INSERT INTO tbl_contest 
        (language_id, name, description, start_date, end_date, image, entry, prize_status, date_created, status, contest_type, rhapsody_category_id)
        VALUES (?, ?, ?, ?, ?, '', 0, 0, NOW(), 1, 'daily', ?)
    ");
    
    $language_id = $day_category['language_id'] ?? 14;
    $name = "Daily Rhapsody - $month_name $day, $year";
    $description = "Complete today's Rhapsody quiz to earn ranking points!";
    $start_date = "$today 00:00:00";
    $end_date = "$today 23:59:59";
    
    $stmt->execute([
        $language_id,
        $name,
        $description,
        $start_date,
        $end_date,
        $day_category['id']
    ]);
    
    $contest_id = $pdo->lastInsertId();
    
    // Add questions to contest (copy full question data into tbl_contest_question)
    $question_ids = [];
    foreach ($questions as $q) {
        $stmt = $pdo->prepare("
            INSERT INTO tbl_contest_question 
            (langauge_id, contest_id, image, question, question_type, optiona, optionb, optionc, optiond, optione, answer, note)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ");
        $stmt->execute([
            $q['language_id'] ?? $language_id,
            $contest_id,
            $q['image'] ?? '',
            $q['question'],
            $q['question_type'],
            $q['optiona'],
            $q['optionb'],
            $q['optionc'],
            $q['optiond'],
            $q['optione'] ?? '',
            $q['answer'],
            $q['note'] ?? ''
        ]);
        $question_ids[] = $q['id'];
    }
    
    echo "\n✓ Daily contest created successfully!\n";
    echo "  Contest ID: $contest_id\n";
    echo "  Name: $name\n";
    echo "  Source Question IDs: " . implode(', ', $question_ids) . "\n";
    echo "  Valid until: $end_date\n";
    
} catch (PDOException $e) {
    die("Database error: " . $e->getMessage() . "\n");
}
