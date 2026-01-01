#!/usr/bin/env php
<?php
/**
 * Script to manually create daily contest for testing
 * Usage: php scripts/create_daily_contest.php
 * 
 * This script directly connects to the database and creates today's daily contest
 * from the current day's Rhapsody content.
 */

// Load database configuration
$config_path = __DIR__ . '/../src/admin/public/application/config/database.php';
if (!file_exists($config_path)) {
    die("Error: Database config not found at $config_path\n");
}

require_once $config_path;

// Get database credentials from CodeIgniter config
$db_config = $db['default'];
$host = $db_config['hostname'];
$user = $db_config['username'];
$pass = $db_config['password'];
$dbname = $db_config['database'];

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
        echo "✓ Daily contest already exists for today (ID: {$existing['id']})\n";
        exit(0);
    }
    
    // Find the Rhapsody topic
    $stmt = $pdo->query("SELECT id FROM tbl_topics WHERE topic_type = 'rhapsody' AND status = 1 LIMIT 1");
    $rhapsody_topic = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$rhapsody_topic) {
        die("Error: Rhapsody topic not found\n");
    }
    
    echo "Found Rhapsody topic ID: {$rhapsody_topic['id']}\n";
    
    // Find the day category for today's date
    $stmt = $pdo->prepare("
        SELECT c.* 
        FROM tbl_category c 
        WHERE c.topic_id = ? 
        AND c.rhapsody_day = ? 
        AND c.rhapsody_month = ? 
        AND c.rhapsody_year = ? 
        AND c.status = 1
    ");
    $stmt->execute([$rhapsody_topic['id'], $day, $month, $year]);
    $day_category = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$day_category) {
        die("Error: No Rhapsody content found for $month_name $day, $year\n");
    }
    
    echo "Found Rhapsody category ID: {$day_category['id']} ({$day_category['category_name']})\n";
    
    // Get questions from this category (random 5)
    $stmt = $pdo->prepare("SELECT id FROM tbl_question WHERE category = ? ORDER BY RAND() LIMIT 5");
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
    
    // Add questions to contest
    $question_ids = array_column($questions, 'id');
    foreach ($question_ids as $q_id) {
        $stmt = $pdo->prepare("INSERT INTO tbl_contest_question (contest_id, question_id) VALUES (?, ?)");
        $stmt->execute([$contest_id, $q_id]);
    }
    
    echo "\n✓ Daily contest created successfully!\n";
    echo "  Contest ID: $contest_id\n";
    echo "  Name: $name\n";
    echo "  Questions: " . implode(', ', $question_ids) . "\n";
    echo "  Valid until: $end_date\n";
    
} catch (PDOException $e) {
    die("Database error: " . $e->getMessage() . "\n");
}

