<?php if (! defined('BASEPATH')) exit('No direct script access allowed');

class Elite_Cron_Job extends CI_Controller
{
    /**
     * This is default constructor of the class
     */
    public function __construct()
    {
        parent::__construct();
        // Use Montreal timezone for daily contest creation
        $tz = getenv('TZ') ?: 'America/Montreal';
        date_default_timezone_set($tz);
    }

    /**
     * This function is used to update date
     * This function is called by cron job once in a day at midnight 00:00
     */
    public function index()
    {
        $res = $this->db->where('date!=', date('Y-m-d'))->get('tbl_exam_module')->result_array();
        if (!empty($res)) {
            // print_r($res);
            $data = [
                'date' => date('Y-m-d'),
                'status' => 1
            ];
            $this->db->update('tbl_exam_module', $data);

            echo 'Exam Module Cronjob Time -' . date('Y-m-d H:i:s');
        }
        $res1 = $this->db->where('date_published!=', date('Y-m-d'))->get('tbl_daily_quiz')->result_array();
        if (!empty($res1)) {

            // echo $this->db->last_query();
            // echo 'done';
            $data1 = [
                'date_published' => date('Y-m-d'),

            ];
            $this->db->update('tbl_daily_quiz', $data1);
            echo 'Daily quiz Cronjob Time -' . date('Y-m-d H:i:s');
        }
        
        // Also create daily contest
        $this->create_daily_contest();
    }
    
    /**
     * Create daily contest from today's Rhapsody content
     * Called at 00:00 AM daily
     */
    public function create_daily_contest()
    {
        $force = $this->input->get('force') == '1';
        
        $today = date('Y-m-d');
        $day = (int)date('j');
        $month = (int)date('n');
        $year = (int)date('Y');
        $month_name = date('F');
        
        log_message('info', "Daily Contest Cron: Starting for $month_name $day, $year" . ($force ? " (FORCE MODE)" : ""));
        
        // Check if daily contest already exists for today
        $existing = $this->db->where('DATE(start_date)', $today)
            ->where('contest_type', 'daily')
            ->get('tbl_contest')
            ->row_array();
            
        if (!empty($existing)) {
            if ($force) {
                // Delete existing contest and related data
                $contest_id = $existing['id'];
                log_message('info', "Daily Contest Cron: Force mode - deleting contest ID: $contest_id");
                $this->db->where('contest_id', $contest_id)->delete('tbl_contest_question');
                $this->db->where('contest_id', $contest_id)->delete('tbl_contest_leaderboard');
                $this->db->where('id', $contest_id)->delete('tbl_contest');
                echo "Deleted existing contest (ID: $contest_id)\n";
            } else {
                log_message('info', "Daily Contest Cron: Contest already exists for today (ID: {$existing['id']})");
                echo "Daily contest already exists for today\n";
                return;
            }
        }
        
        // Find the Rhapsody topic
        $rhapsody_topic = $this->db->where('slug', 'rhapsody')
            ->where('is_active', 1)
            ->get('tbl_topic')
            ->row_array();
            
        if (empty($rhapsody_topic)) {
            log_message('error', "Daily Contest Cron: Rhapsody topic not found");
            echo "Error: Rhapsody topic not found\n";
            return;
        }
        
        // Find today's Rhapsody category
        $day_category = $this->db->where('topic_id', $rhapsody_topic['id'])
            ->where('category_type', 'day')
            ->where('day', $day)
            ->where('month', $month)
            ->where('year', $year)
            ->get('tbl_category')
            ->row_array();
            
        if (empty($day_category)) {
            log_message('error', "Daily Contest Cron: No Rhapsody content for $month_name $day, $year");
            echo "Error: No Rhapsody content for today\n";
            return;
        }
        
        // Get 5 random questions from this category
        $questions = $this->db->where('category', $day_category['id'])
            ->order_by('RAND()')
            ->limit(5)
            ->get('tbl_question')
            ->result_array();
            
        if (count($questions) < 5) {
            log_message('error', "Daily Contest Cron: Not enough questions (need 5, found " . count($questions) . ")");
            echo "Error: Not enough questions for daily contest\n";
            return;
        }
        
        // Create the daily contest
        $language_id = $day_category['language_id'] ?? 14;
        $contest_data = [
            'language_id' => $language_id,
            'name' => "Daily Rhapsody - $month_name $day, $year",
            'description' => "Complete today's Rhapsody quiz to earn ranking points!",
            'start_date' => "$today 00:00:00",
            'end_date' => "$today 23:59:59",
            'image' => '',
            'entry' => 0,
            'prize_status' => 0,
            'date_created' => date('Y-m-d H:i:s'),
            'status' => 1,
            'contest_type' => 'daily',
            'rhapsody_category_id' => $day_category['id']
        ];
        
        $this->db->insert('tbl_contest', $contest_data);
        $contest_id = $this->db->insert_id();
        
        // Add questions to contest
        foreach ($questions as $q) {
            $question_data = [
                'langauge_id' => $q['language_id'] ?? $language_id,
                'contest_id' => $contest_id,
                'image' => $q['image'] ?? '',
                'question' => $q['question'],
                'question_type' => $q['question_type'],
                'optiona' => $q['optiona'],
                'optionb' => $q['optionb'],
                'optionc' => $q['optionc'],
                'optiond' => $q['optiond'],
                'optione' => $q['optione'] ?? '',
                'answer' => $q['answer'],
                'note' => $q['note'] ?? ''
            ];
            $this->db->insert('tbl_contest_question', $question_data);
        }
        
        log_message('info', "Daily Contest Cron: Created contest ID $contest_id for $month_name $day, $year");
        echo "Daily contest created successfully (ID: $contest_id)\n";
        
        // Send automatic notification when contest is created
        $this->send_new_contest_notification($contest_id, $month_name, $day, $year);
    }
    
    /**
     * Send notification when a new daily contest is created
     * This is called automatically after create_daily_contest
     */
    private function send_new_contest_notification($contest_id, $month_name, $day, $year)
    {
        $title = "🎯 New Daily Quiz Available!";
        $body = "Today's Rhapsody quiz ($month_name $day) is ready. Complete it now to earn ranking points!";
        
        log_message('info', "Daily Contest Cron: Sending new contest notification for ID $contest_id");
        echo "Sending new contest notification...\n";
        
        // Save notification to database for in-app display
        $this->save_notification_to_db($title, $body, 'daily_contest', $contest_id);
        
        // Send FCM push notification
        $result = $this->send_fcm_topic_notification('daily_quiz', $title, $body, [
            'type' => 'new_daily_contest',
            'contest_id' => (string)$contest_id,
            'action' => 'open_contest'
        ]);
        
        if ($result) {
            echo "✓ New contest notification sent successfully\n";
            log_message('info', "Daily Contest Cron: Notification sent for contest ID $contest_id");
        } else {
            echo "✗ Failed to send new contest notification\n";
            log_message('error', "Daily Contest Cron: Failed to send notification for contest ID $contest_id");
        }
    }
    
    /**
     * Save notification to database for in-app notifications list
     */
    private function save_notification_to_db($title, $message, $type = 'default', $type_id = '')
    {
        $notification_data = [
            'title' => $title,
            'message' => $message,
            'users' => 'all',
            'user_id' => '',
            'type' => $type,
            'type_id' => (string)$type_id,
            'image' => '',
            'date_sent' => date('Y-m-d H:i:s')
        ];
        
        $this->db->insert('tbl_notifications', $notification_data);
        $notification_id = $this->db->insert_id();
        
        log_message('info', "Notification saved to DB (ID: $notification_id): $title");
        echo "  Notification saved to database (ID: $notification_id)\n";
        
        return $notification_id;
    }
    
    /**
     * Send daily contest notification reminders
     * Called at 8AM, 1PM, 10PM
     */
    public function send_daily_contest_notifications()
    {
        $today = date('Y-m-d');
        $hour = (int)date('G');
        
        log_message('info', "Daily Contest Notification: Checking at $hour:00");
        
        // Get today's daily contest
        $contest = $this->db->where('DATE(start_date)', $today)
            ->where('contest_type', 'daily')
            ->where('status', 1)
            ->get('tbl_contest')
            ->row_array();
            
        if (empty($contest)) {
            log_message('info', "Daily Contest Notification: No active contest for today");
            return;
        }
        
        // Get users who haven't completed the contest yet
        $completed_users = $this->db->select('user_id')
            ->where('contest_id', $contest['id'])
            ->get('tbl_contest_leaderboard')
            ->result_array();
            
        $completed_user_ids = array_column($completed_users, 'user_id');
        
        // Get all users with FCM tokens
        $query = $this->db->select('id, fcm_id, name')
            ->where('fcm_id !=', '')
            ->where('fcm_id IS NOT NULL', null, false)
            ->where('status', 1);
            
        if (!empty($completed_user_ids)) {
            $query->where_not_in('id', $completed_user_ids);
        }
        
        $users = $query->get('tbl_users')->result_array();
        
        if (empty($users)) {
            log_message('info', "Daily Contest Notification: No users to notify");
            return;
        }
        
        log_message('info', "Daily Contest Notification: " . count($users) . " users haven't completed the quiz");
        
        // Send FCM notification to topic (more reliable than individual tokens)
        $title = "⏰ Daily Rhapsody Quiz Reminder";
        $body = "Don't forget to complete today's Rhapsody quiz and earn points!";
        
        echo "Sending notification to topic 'daily_quiz'...\n";
        
        // Save reminder notification to database (avoid duplicates - max 1 reminder per day)
        $existing_reminder = $this->db->where('DATE(date_sent)', date('Y-m-d'))
            ->where('type', 'daily_contest_reminder')
            ->where('type_id', (string)$contest['id'])
            ->get('tbl_notifications')
            ->row_array();
            
        if (empty($existing_reminder)) {
            $this->save_notification_to_db($title, $body, 'daily_contest_reminder', $contest['id']);
        }
        
        $result = $this->send_fcm_topic_notification('daily_quiz', $title, $body, [
            'type' => 'daily_contest_reminder',
            'contest_id' => (string)$contest['id']
        ]);
        
        if ($result) {
            echo "✓ Topic notification sent successfully\n";
            echo "Users who haven't completed: " . count($users) . "\n";
        } else {
            echo "✗ Failed to send topic notification\n";
        }
    }
    
    /**
     * Send FCM notification to a topic using FCM v1 API
     */
    private function send_fcm_topic_notification($topic, $title, $body, $data = [])
    {
        $credentials_path = getenv('GOOGLE_APPLICATION_CREDENTIALS') ?: '/var/www/credentials/firebase-service-account.json';
        $project_id = getenv('FCM_PROJECT_ID') ?: 'rhapsodie-quizz';
        
        if (!file_exists($credentials_path)) {
            echo "  ERROR: Credentials file not found at $credentials_path\n";
            return false;
        }
        
        $access_token = $this->get_fcm_access_token($credentials_path);
        if (empty($access_token)) {
            echo "  ERROR: Failed to get access token\n";
            return false;
        }
        
        $url = "https://fcm.googleapis.com/v1/projects/{$project_id}/messages:send";
        
        $message = [
            'message' => [
                'topic' => $topic,
                'notification' => [
                    'title' => $title,
                    'body' => $body
                ],
                'android' => [
                    'priority' => 'high',
                    'notification' => [
                        'sound' => 'default',
                        'click_action' => 'FLUTTER_NOTIFICATION_CLICK'
                    ]
                ],
                'apns' => [
                    'payload' => [
                        'aps' => [
                            'sound' => 'default'
                        ]
                    ]
                ],
                'data' => array_map('strval', $data)
            ]
        ];
        
        $ch = curl_init($url);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Authorization: Bearer ' . $access_token,
            'Content-Type: application/json'
        ]);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($message));
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        
        $result = curl_exec($ch);
        $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        if ($http_code !== 200) {
            echo "  FCM Error (HTTP $http_code): $result\n";
            log_message('error', "FCM Topic: HTTP $http_code - $result");
            return false;
        }
        
        log_message('info', "FCM Topic: Notification sent to '$topic' - $result");
        return $result;
    }
    
    /**
     * Send FCM notification using FCM v1 API with service account
     * Requires: GOOGLE_APPLICATION_CREDENTIALS env var pointing to service account JSON
     *           FCM_PROJECT_ID env var with Firebase project ID
     */
    private function send_fcm_notification($fcm_token, $title, $body, $data = [])
    {
        // Default credentials path or from environment
        $credentials_path = getenv('GOOGLE_APPLICATION_CREDENTIALS') ?: '/var/www/credentials/firebase-service-account.json';
        $project_id = getenv('FCM_PROJECT_ID') ?: 'rhapsodie-quizz';
        
        if (empty($credentials_path) || !file_exists($credentials_path)) {
            log_message('error', 'FCM v1: Credentials file not found at ' . $credentials_path);
            return false;
        }
        
        if (empty($project_id)) {
            log_message('error', 'FCM v1: FCM_PROJECT_ID not configured');
            return false;
        }
        
        // Get OAuth2 access token
        $access_token = $this->get_fcm_access_token($credentials_path);
        if (empty($access_token)) {
            log_message('error', 'FCM v1: Failed to get access token');
            return false;
        }
        
        // FCM v1 API endpoint
        $url = "https://fcm.googleapis.com/v1/projects/{$project_id}/messages:send";
        echo "  FCM URL: $url\n";
        
        // Build message payload for FCM v1 API
        $message = [
            'message' => [
                'token' => $fcm_token,
                'notification' => [
                    'title' => $title,
                    'body' => $body
                ],
                'android' => [
                    'priority' => 'high',
                    'notification' => [
                        'sound' => 'default',
                        'click_action' => 'FLUTTER_NOTIFICATION_CLICK'
                    ]
                ],
                'apns' => [
                    'payload' => [
                        'aps' => [
                            'sound' => 'default'
                        ]
                    ]
                ],
                'data' => array_map('strval', $data) // FCM v1 requires string values
            ]
        ];
        
        $headers = [
            'Authorization: Bearer ' . $access_token,
            'Content-Type: application/json'
        ];
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($message));
        
        $result = curl_exec($ch);
        $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curl_error = curl_error($ch);
        curl_close($ch);
        
        if ($http_code !== 200) {
            echo "  FCM Error (HTTP $http_code): $result\n";
            if ($curl_error) {
                echo "  cURL Error: $curl_error\n";
            }
            log_message('error', "FCM v1: HTTP $http_code - $result");
            return false;
        }
        
        log_message('info', "FCM v1: Notification sent successfully - $result");
        return $result;
    }
    
    /**
     * Get OAuth2 access token from service account credentials
     * Uses JWT to authenticate with Google OAuth2
     */
    private function get_fcm_access_token($credentials_path)
    {
        echo "  Reading credentials from: $credentials_path\n";
        
        if (!file_exists($credentials_path)) {
            echo "  ERROR: Credentials file not found!\n";
            return null;
        }
        
        // Read service account JSON
        $credentials = json_decode(file_get_contents($credentials_path), true);
        
        if (empty($credentials['private_key']) || empty($credentials['client_email'])) {
            echo "  ERROR: Invalid service account JSON (missing private_key or client_email)\n";
            log_message('error', 'FCM v1: Invalid service account JSON');
            return null;
        }
        
        echo "  Service account: {$credentials['client_email']}\n";
        
        // Create JWT
        $now = time();
        $jwt_header = [
            'alg' => 'RS256',
            'typ' => 'JWT'
        ];
        
        $jwt_claim = [
            'iss' => $credentials['client_email'],
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud' => 'https://oauth2.googleapis.com/token',
            'iat' => $now,
            'exp' => $now + 3600
        ];
        
        $jwt_header_encoded = $this->base64url_encode(json_encode($jwt_header));
        $jwt_claim_encoded = $this->base64url_encode(json_encode($jwt_claim));
        
        $signature_input = $jwt_header_encoded . '.' . $jwt_claim_encoded;
        
        // Sign with private key
        $private_key = openssl_pkey_get_private($credentials['private_key']);
        if (!$private_key) {
            log_message('error', 'FCM v1: Failed to read private key');
            return null;
        }
        
        openssl_sign($signature_input, $signature, $private_key, 'SHA256');
        $jwt = $signature_input . '.' . $this->base64url_encode($signature);
        
        // Exchange JWT for access token
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, 'https://oauth2.googleapis.com/token');
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $jwt
        ]));
        
        $response = curl_exec($ch);
        $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        $token_data = json_decode($response, true);
        
        if (empty($token_data['access_token'])) {
            echo "  Token exchange failed (HTTP $http_code): $response\n";
            log_message('error', 'FCM v1: Failed to get access token - ' . $response);
            return null;
        }
        
        $token = $token_data['access_token'];
        echo "  Access token obtained (length: " . strlen($token) . ")\n";
        echo "  Token starts with: " . substr($token, 0, 20) . "...\n";
        return $token;
    }
    
    /**
     * Base64 URL-safe encoding
     */
    private function base64url_encode($data)
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
}
