<?php

defined('BASEPATH') or exit('No direct script access allowed');

require APPPATH . '/libraries/REST_Controller.php';
require FCPATH . 'vendor/autoload.php';

use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use ReceiptValidator\iTunes\Validator as iTunesValidator;

class Api extends REST_Controller
{
    public function __construct()
    {
        parent::__construct();
        $this->load->database();
        // Default image
        $this->NO_IMAGE = base_url() . LOGO_IMG_PATH . is_settings('half_logo');

        date_default_timezone_set(get_system_timezone());

        $this->toDate = date('Y-m-d');
        $this->twoDayOldDate = date('Y-m-d', strtotime('-2 days'));
        $this->toDateTime = date('Y-m-d H:i:s');
        $this->twoDayOldDateTime = date('Y-m-d H:i:s', strtotime('-2 days'));
        $this->toContestDateTime = date('Y-m-d H:i:00');
        $this->load->library('JWT');
        $jwtKey = $this->db->where('type', 'jwt_key')->get('tbl_settings')->row_array();
        $jwtKey = $jwtKey['message'];
        $this->JWT_SECRET_KEY = "$jwtKey";

        $this->systemTimezoneGMT = is_settings('system_timezone_gmt') ? is_settings('system_timezone_gmt') : 'Asia/Kolkata';
        $this->systemTimezone = is_settings('system_timezone') ? is_settings('system_timezone') : '+05:30';

        $questionShuffleMode = $this->db->where('type', 'question_shuffle_mode')->get('tbl_settings')->row_array();
        $questionShuffleMode = $questionShuffleMode['message'];
        if ($questionShuffleMode) {
            $this->Order_By = 'rand()';
        } else {
            $this->Order_By = 'id';
        }

        $optionShuffleMode = $this->db->where('type', 'option_shuffle_mode')->get('tbl_settings')->row_array();
        $optionShuffleMode = $optionShuffleMode['message'];
        $this->OPTION_SHUFFLE_MODE = "$optionShuffleMode";

        $this->DASHING_DEBUT = 'dashing_debut';
        $this->COMBAT_WINNER = 'combat_winner';
        $this->CLASH_WINNER = 'clash_winner';
        $this->ULTIMATE_PLAYER = 'ultimate_player';
        $this->QUIZ_WARRIOR = 'quiz_warrior';
        $this->SUPER_SONIC = 'super_sonic';
        $this->FLASHBACK = 'flashback';
        $this->BRAINIAC = 'brainiac';
        $this->BIG_THING = 'big_thing';
        $this->ELITE = 'elite';
        $this->THIRSTY = 'thirsty';
        $this->POWER_ELITE = 'power_elite';
        $this->SHARING_CARING = 'sharing_caring';
        $this->STREAK = 'streak';
        $this->refer_coin_msg = 'usedReferCode';
        $this->earn_coin_msg = 'referCodeToFriend';
        $this->opening_msg = 'welcomeBonus';
        $this->watched_ads = 'watchedAds';
        $this->minimumQuestionsForBadge = 5;
    }

    public function user_signup_post()
    {

        if ($this->post('firebase_id') && $this->post('type') && ($this->post('firebase_id') != 'null') && ($this->post('firebase_id') != 'NULL')) {
            $firebase_id = $this->post('firebase_id');

            // ------- Should be Enabled for server  ----------
            $is_verify = $this->verify_user($firebase_id);
            // ---------------------------------------------------
            // ------- Should be Disable for server  ----------
            // $is_verify=true;
            // ---------------------------------------------------
            if ($is_verify) {
                $type = $this->post('type');
                $email = ($this->post('email')) ? $this->post('email') : '';
                $name = ($this->post('name')) ? $this->post('name') : '';
                $mobile = ($this->post('mobile')) ? $this->post('mobile') : '';
                $profile = ($this->post('profile')) ? $this->post('profile') : '';
                $fcm_id = ($this->post('fcm_id')) ? $this->post('fcm_id') : '';
                $web_fcm_id = ($this->post('web_fcm_id')) ? $this->post('web_fcm_id') : '';
                $friends_code = ($this->post('friends_code')) ? $this->post('friends_code') : '';
                $status = ($this->post('status')) ? $this->post('status') : '1';
                $refer_coin = is_settings('refer_coin');
                $earn_coin = is_settings('earn_coin');

                if (!empty($friends_code)) {
                    $code = valid_friends_refer_code($friends_code);
                    if (!$code['is_valid']) {
                        $friends_code = '';
                    }
                }
                $res = $this->db->where('firebase_id', $firebase_id)->get('tbl_users')->row_array();
                if (!empty($res)) {
                    // login
                    if ($res['status'] == 1) {
                        $user_id = $res['id'];
                        $refer_code = $this->random_string(4) . $res['refer_code'];

                        $friends_code_is_used = check_friends_code_is_used_by_user($user_id);
                        if (!$friends_code_is_used['is_used'] && $friends_code != '') {
                            $data = array('friends_code' => $friends_code);
                            $this->db->where('id', $user_id)->update('tbl_users', $data);
                            //update coins
                            $this->set_coins($user_id, $refer_coin);
                            // set tracker data
                            $this->set_tracker_data($user_id, $refer_coin, $this->refer_coin_msg, 0);

                            $credited = credit_coins_to_friends_code($friends_code);
                            if ($credited['credited']) {
                                $this->set_coins($credited['user_id'], $credited['coins'], false);
                                // set tracker data
                                $this->set_tracker_data($credited['user_id'], $earn_coin, $this->earn_coin_msg, 0);
                                // for sharing is caring badge
                                $friends = $this->db->where('friends_code', $friends_code)->get('tbl_users')->result_array();
                                $friends_counter = count($friends);
                                $this->set_coins($credited['user_id'], $friends_counter, false, $type = 'sharing_caring');
                            }
                        }
                        if (!empty($fcm_id)) {
                            $data = array('fcm_id' => $fcm_id);
                            $this->db->where('id', $user_id)->update('tbl_users', $data);
                        }
                        if (!empty($web_fcm_id)) {
                            $data = array('web_fcm_id' => $web_fcm_id);
                            $this->db->where('id', $user_id)->update('tbl_users', $data);
                        }
                        if (!is_refer_code_set($user_id) && !empty($refer_code)) {
                            $data = array('refer_code' => $refer_code);
                            $this->db->where('id', $user_id)->update('tbl_users', $data);
                        }
                        if (!empty($name)) {
                            $data = array('name' => $name);
                            $this->db->where('id', $user_id)->update('tbl_users', $data);
                        }

                        //generate token
                        $api_token = $this->generate_token($user_id, $firebase_id);
                        $this->db->where('id', $user_id)->update('tbl_users', ['api_token' => $api_token]);

                        $res1 = $this->db->where('firebase_id', $firebase_id)->get('tbl_users')->row_array();

                        if (filter_var($res['profile'], FILTER_VALIDATE_URL) === false) {
                            $res1['profile'] = ($res1['profile']) ? base_url() . USER_IMG_PATH . $res1['profile'] : '';
                        }
                        $response['error'] = false;
                        $response['message'] = "105";
                        $response['data'] = $res1;
                    } else {
                        $response['error'] = true;
                        $response['message'] = "126";
                    }
                } else {
                    // register
                    if ($this->post('app_language') && !empty($this->post('app_language'))) {
                        $default_app_language = $this->post('app_language');
                    } else {
                        $get_app_default_language = $this->db->select('id,name,app_default')->where('app_default', 1)->get('tbl_upload_languages')->row_array();
                        $default_app_language = $get_app_default_language['name'];
                    }

                    if ($this->post('web_language') && !empty($this->post('web_language'))) {
                        $default_web_language = $this->post('web_language');
                    } else {
                        $get_web_default_language = $this->db->select('id,name,web_default')->where('web_default', 1)->get('tbl_upload_languages')->row_array();
                        $default_web_language = $get_web_default_language['name'];
                    }

                    $data = array(
                        'firebase_id' => $firebase_id,
                        'name' => $name,
                        'email' => $email,
                        'mobile' => $mobile,
                        'type' => $type,
                        'profile' => $profile,
                        'fcm_id' => $fcm_id,
                        'web_fcm_id' => $web_fcm_id,
                        'friends_code' => $friends_code,
                        'coins' => '0',
                        'status' => $status,
                        'date_registered' => $this->toDateTime,
                        'app_language' => $default_app_language ?? 'english',
                        'web_language' => $default_web_language ?? 'english'
                    );
                    $this->db->insert('tbl_users', $data);
                    $insert_id = $this->db->insert_id();

                    // get the welcome bonus result from settings 
                    $welcome_bonus_query = $this->db->select('message')->where('type', 'welcome_bonus_coin')->get('tbl_settings')->row_array();

                    // get the welcome bonus data if not found then default will be 5
                    $welcome_bonus_coins = (int)$welcome_bonus_query['message'] ?? 5;

                    //set the welcome bonus entry in table :- tracker
                    $this->set_tracker_data($insert_id, $welcome_bonus_coins, $this->opening_msg, 0);

                    //add coins to users
                    $this->db->where('id', $insert_id)->update('tbl_users', ['coins' => $welcome_bonus_coins]);

                    //generate token
                    $api_token = $this->generate_token($insert_id, $firebase_id);
                    $this->db->where('id', $insert_id)->update('tbl_users', ['api_token' => $api_token]);

                    $counter = 0;
                    $badges = [
                        'user_id' => $insert_id,
                        'dashing_debut' => $counter,
                        'dashing_debut_counter' => $counter,
                        'combat_winner' => $counter,
                        'combat_winner_counter' => $counter,
                        'clash_winner' => $counter,
                        'clash_winner_counter' => $counter,
                        'most_wanted_winner' => $counter,
                        'most_wanted_winner_counter' => $counter,
                        'ultimate_player' => $counter,
                        'quiz_warrior' => $counter,
                        'quiz_warrior_counter' => $counter,
                        'super_sonic' => $counter,
                        'flashback' => $counter,
                        'brainiac' => $counter,
                        'big_thing' => $counter,
                        'elite' => $counter,
                        'thirsty' => $counter,
                        'thirsty_date' => '0000-00-00',
                        'thirsty_counter' => $counter,
                        'power_elite' => $counter,
                        'power_elite_counter' => $counter,
                        'sharing_caring' => $counter,
                        'streak' => $counter,
                        'streak_date' => '0000-00-00',
                        'streak_counter' => $counter,
                    ];
                    $this->db->insert('tbl_users_badges', $badges);

                    $refer_code = $this->random_string(4) . $insert_id;
                    $dataR = array('refer_code' => $refer_code);
                    $this->db->where('id', $insert_id)->update('tbl_users', $dataR);

                    if ($friends_code != '') {
                        $data = array('coins' => $refer_coin);
                        $this->db->where('id', $insert_id)->update('tbl_users', $data);
                        $this->set_tracker_data($insert_id, $refer_coin, $this->refer_coin_msg, 0);
                        $credited = credit_coins_to_friends_code($friends_code);
                        if ($credited['credited']) {
                            $this->set_coins($credited['user_id'], $credited['coins'], false);
                            $this->set_tracker_data($credited['user_id'], $earn_coin, $this->earn_coin_msg, 0);
                            // for sharing is caring badge
                            $friends = $this->db->where('friends_code', $friends_code)->get('tbl_users')->result_array();
                            $friends_counter = count($friends);
                            $this->set_coins($credited['user_id'], $friends_counter, false, $type = 'sharing_caring');
                        }
                    }

                    $res1 = $this->db->where('id', $insert_id)->get('tbl_users')->row_array();

                    if (filter_var($res1['profile'], FILTER_VALIDATE_URL) === false) {
                        $res1['profile'] = ($res1['profile']) ? base_url() . USER_IMG_PATH . $res1['profile'] : '';
                    }
                    $response['error'] = false;
                    $response['message'] = "104";
                    $response['data'] = $res1;
                }
            } else {
                $response['error'] = true;
                $response['message'] = "129";
            }
        } else {
            $response['error'] = true;
            $response['message'] = "103";
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_random_questions_post()
    {
        $is_user = $this->verify_token();
        if (!$is_user['error']) {
            $user_id = $is_user['user_id'];
            $firebase_id = $is_user['firebase_id'];
        } else {
            $this->response($is_user, REST_Controller::HTTP_OK);
            return false;
        }

        if ($this->post('match_id')) {
            $match_id = $this->post('match_id');
            if ($this->post('destroy_match') && $this->post('destroy_match') == 1) {
                $this->db->where('match_id', $match_id)->delete('tbl_battle_questions');
                $response['error'] = false;
                $response['message'] = "108";
            } else {
                $this->db->where('date_created <', $this->toDate)->delete('tbl_battle_questions');

                $language_id = ($this->post('language_id')) ? $this->post('language_id') : 0;
                if ($this->post('category')) {
                    $category = $this->post('category');
                } else {
                    $category = '0';
                }

                if (!$this->checkBattleExists($match_id)) {
                    $is_random = $this->post('random') ?? 0;
                    $fix_question = is_settings('battle_mode_one_fix_question');
                    $limit = is_settings('battle_mode_one_total_question');
                    if ($is_random != 0) {
                        $fix_question = is_settings('battle_mode_random_fix_question');
                        $limit = is_settings('battle_mode_random_total_question');
                    }
                    
                    // Handle special topic types: rhapsody and foundation
                    if ($category === 'rhapsody') {
                        $res = $this->_get_rhapsody_questions_for_battle($limit ?: 10, $language_id);
                    } else if ($category === 'foundation') {
                        $res = $this->_get_foundation_questions_for_battle($limit ?: 10, $language_id);
                    } else {
                        /* if match does not exist read and store the questions */
                        $this->db->select('tbl_question.*,c.id as cat_id, sc.id as subcat_id'); // Select all columns from tbl_question

                        if (!empty($language_id)) {
                            $this->db->where('tbl_question.language_id', $language_id);
                        }
                        if (!empty($category)) {
                            $this->db->where('tbl_question.category', $category);
                        }
                        $this->db->join('tbl_category c', 'tbl_question.category = c.id')->where('c.is_premium = 0');
                        $this->db->join('tbl_subcategory sc', 'tbl_question.subcategory = sc.id', 'left');
                        $this->db->order_by('rand()');
                        if ($fix_question == 1) {
                            $this->db->limit($limit, 0);
                        }
                        $res = $this->db->get('tbl_question')->result_array();
                    }

                    if (empty($res)) {
                        $response['error'] = true;
                        $response['message'] = "102";
                    } else {
                        $questions = json_encode($res);

                        $entry_coin = $this->post('entry_coin') ? $this->post('entry_coin') : 0;
                        $frm_data = array(
                            'match_id' => $match_id,
                            'entry_coin' => $entry_coin,
                            'questions' => $questions,
                            'set_user1' => 0,
                            'set_user2' => 0,
                            'date_created' => $this->toDateTime,
                        );
                        $this->db->insert('tbl_battle_questions', $frm_data);
                        foreach ($res as $row) {
                            $row['image'] = (!empty($row['image'])) ? base_url() . QUESTION_IMG_PATH . $row['image'] : '';
                            $row['answer'] = $this->encrypt_data($firebase_id, trim($row['answer']));

                            unset($row['session_answer']);
                            $temp[] = $row;
                        }
                        $res = $temp;

                        $response['error'] = false;
                        $response['data'] = $res;
                    }
                } else {
                    /* read the questions and send it. */
                    $res = $this->db->where('match_id', $match_id)->get('tbl_battle_questions')->row_array();

                    $res = json_decode($res['questions'], 1);
                    foreach ($res as $rowData) {
                        $rowData['image'] = (!empty($rowData['image'])) ? base_url() . QUESTION_IMG_PATH . $rowData['image'] : '';
                        $rowData['answer'] = $this->encrypt_data($firebase_id, trim($rowData['answer']));
                        unset($rowData['session_answer']);
                        $temp[] = $rowData;
                    }
                    $res['questions'] = json_encode($temp);
                    $response['error'] = false;
                    $response['data'] = json_decode($res['questions']);
                }
            }
        } else {
            $response['error'] = true;
            $response['message'] = "103";
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_question_by_room_id_post()
    {
        $is_user = $this->verify_token();
        if (!$is_user['error']) {
            $user_id = $is_user['user_id'];
            $firebase_id = $is_user['firebase_id'];
        } else {
            $this->response($is_user, REST_Controller::HTTP_OK);
            return false;
        }

        if ($this->post('room_id')) {
            $room_id = $this->post('room_id');

            $res = $this->db->where('room_id', $room_id)->get('tbl_rooms')->row_array();
            if (empty($res)) {
                $response['error'] = true;
                $response['message'] = "102";
            } else {
                $res = json_decode($res['questions'], true);
                $fix_question = is_settings('battle_mode_group_fix_question');
                $limit = is_settings('battle_mode_group_total_question'); // Get the limit
                if ($fix_question == 1) {
                    $res = array_slice($res, 0, $limit); // Limit the number of questions
                }
                foreach ($res as $row) {
                    $row['image'] = (!empty($row['image'])) ? base_url() . QUESTION_IMG_PATH . $row['image'] : '';
                    $row['answer'] = $this->encrypt_data($firebase_id, trim($row['answer']));
                    $temp[] = $row;
                }
                $res[0]['questions'] = json_encode($temp);
                $response['error'] = false;
                $response['data'] = json_decode($res[0]['questions']);
            }
        } else {
            $response['error'] = true;
            $response['message'] = "103";
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function create_room_post()
    {
        $is_user = $this->verify_token();
        if (!$is_user['error']) {
            $user_id = $is_user['user_id'];
            $firebase_id = $is_user['firebase_id'];
        } else {
            $this->response($is_user, REST_Controller::HTTP_OK);
            return false;
        }

        if ($user_id && $this->post('room_id') && $this->post('room_type')) {
            $room_id = $this->post('room_id');
            $room_type = $this->post('room_type');
            $no_of_que = is_settings('battle_mode_group_fix_question') ? (is_settings('battle_mode_group_total_question') ?? 10) : 10;

            $language_id = ($this->post('language_id')) ? $this->post('language_id') : 0;
            $entry_coin = ($this->post('entry_coin')) ? $this->post('entry_coin') : 0;

            $category = $this->post('category') ? $this->post('category') : '';

            $res1 = $this->db->where('room_id', $room_id)->get('tbl_rooms')->row_array();
            if (empty($res1)) {
                // Handle special topic types: rhapsody and foundation
                log_message('debug', "create_room: category=$category, language_id=$language_id, no_of_que=$no_of_que");
                if ($category === 'rhapsody') {
                    // Get random questions from Rhapsody content
                    log_message('debug', "create_room: Fetching rhapsody questions");
                    $res = $this->_get_rhapsody_questions_for_battle($no_of_que, $language_id);
                    log_message('debug', "create_room: Got " . count($res) . " rhapsody questions");
                } else if ($category === 'foundation') {
                    // Get random questions from Foundation content
                    log_message('debug', "create_room: Fetching foundation questions");
                    $res = $this->_get_foundation_questions_for_battle($no_of_que, $language_id);
                    log_message('debug', "create_room: Got " . count($res) . " foundation questions");
                } else {
                    // Standard category-based questions
                    if (!empty($language_id)) {
                        $this->db->where('language_id', $language_id);
                    }
                    if (!empty($category)) {
                        $this->db->where('category', $category);
                    }
                    $this->db->order_by($this->Order_By)->limit($no_of_que);
                    $res = $this->db->get('tbl_question')->result_array();
                }

                if (empty($res)) {
                    $response['error'] = true;
                    $response['message'] = "102";
                } else {
                    $total_questions = count($res);
                    $questions = json_encode($res);

                    // Convert topic name to topic ID for storage
                    $category_id = 0;
                    if ($category === 'rhapsody' || $category === 'foundation') {
                        $topic_row = $this->db->where('slug', $category === 'rhapsody' ? 'rhapsody' : 'foundation_school')
                            ->get('tbl_topic')->row_array();
                        if (!empty($topic_row)) {
                            $category_id = $topic_row['id'];
                        }
                    } else if (is_numeric($category)) {
                        $category_id = (int)$category;
                    }
                    
                    $frm_data = array(
                        'room_id' => $room_id,
                        'entry_coin' => $entry_coin,
                        'user_id' => $user_id,
                        'room_type' => $room_type,
                        'category_id' => $category_id,
                        'no_of_que' => $total_questions ?? $no_of_que,
                        'questions' => $questions,
                        'set_user1' => 0,
                        'set_user2' => 0,
                        'set_user3' => 0,
                        'set_user4' => 0,
                        'date_created' => $this->toDateTime,
                    );
                    $this->db->insert('tbl_rooms', $frm_data);

                    $response['error'] = false;
                    $response['message'] = "120";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "119";
            }
        } else {
            $response['error'] = true;
            $response['message'] = "103";
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_bookmark_post()
    {
        $is_user = $this->verify_token();
        if (!$is_user['error']) {
            $user_id = $is_user['user_id'];
            $firebase_id = $is_user['firebase_id'];
        } else {
            $this->response($is_user, REST_Controller::HTTP_OK);
            return false;
        }

        if ($user_id && $this->post('type')) {
            $type = $this->post('type');

            if ($type == 3 || $type == '3') {
                $this->db->select('b.*, q.language_id, q.category, q.subcategory, q.image, q.question, q.answer');
                $this->db->join('tbl_guess_the_word q', 'q.id=b.question_id');
            } else if ($type == 4 || $type == '4') {
                $this->db->select('b.*, q.category, q.subcategory, q.language_id, q.audio_type, q.audio, q.question, q.question_type, q.optiona, q.optionb, q.optionc, q.optiond, q.optione, q.answer, q.note');
                $this->db->join('tbl_audio_question q', 'q.id=b.question_id');
            } else if ($type == 5 || $type == '5') {
                $this->db->select('b.*, q.category, q.subcategory, q.language_id, q.image, q.question, q.question_type, q.optiona, q.optionb, q.optionc, q.optiond, q.optione, q.answer, q.note');
                $this->db->join('tbl_maths_question q', 'q.id=b.question_id');
            } else if ($type == 6 || $type == '6') {
                $this->db->select('b.*, q.category, q.subcategory, q.language_id, q.image, q.question, q.question_type,q.answer_type, q.optiona, q.optionb, q.optionc, q.optiond, q.optione, q.answer, q.note');
                $this->db->join('tbl_multi_match q', 'q.id=b.question_id');
            } else {
                $this->db->select('b.*, q.category, q.subcategory, q.language_id, q.image, q.question, q.question_type, q.optiona, q.optionb, q.optionc, q.optiond, q.optione, q.answer, q.level, q.note');
                $this->db->join('tbl_question q', 'q.id=b.question_id');
            }
            $this->db->where('b.type', $type);
            $this->db->where('b.user_id', $user_id)->order_by('b.id', 'DESC');
            $data = $this->db->get('tbl_bookmark b')->result_array();
            if (!empty($data)) {
                for ($i = 0; $i < count($data); $i++) {
                    if ($type == 3 || $type == '3') {
                        $data[$i]['image'] = ($data[$i]['image']) ? base_url() . GUESS_WORD_IMG_PATH . $data[$i]['image'] : '';
                    } else if ($type == 4 || $type == '4') {
                        $data[$i]['audio'] = ($data[$i]['audio']) ? (($data[$i]['audio_type'] != '1') ? base_url() . QUESTION_AUDIO_PATH : '') . $data[$i]['audio'] : '';
                        $data[$i] = $this->suffleOptions($data[$i], $firebase_id);
                        unset($data[$i]['session_answer']);
                    } else if ($type == 5 || $type == '5') {
                        $data[$i]['image'] = ($data[$i]['image']) ? base_url() . MATHS_QUESTION_IMG_PATH . $data[$i]['image'] : '';
                        $data[$i] = $this->suffleOptions($data[$i], $firebase_id);
                        unset($data[$i]['session_answer']);
                    } else if ($type == 6 || $type == '6') {
                        $data[$i]['image'] = ($data[$i]['image']) ? base_url() . MULTIMATCH_QUESTION_IMG_PATH . $data[$i]['image'] : '';
                        $answers = explode(',', trim($data[$i]['answer']));
                        $data[$i]['answer'] = array_map(function ($answer) use ($firebase_id) {
                            return $this->encrypt_data($firebase_id, $answer);
                        }, $answers);
                    } else {
                        $data[$i]['image'] = ($data[$i]['image']) ? base_url() . QUESTION_IMG_PATH . $data[$i]['image'] : '';
                        $data[$i] = $this->suffleOptions($data[$i], $firebase_id);
                        unset($data[$i]['session_answer']);
                    }
                }
                $response['error'] = false;
                $response['data'] = $data;
            } else {
                $response['error'] = false;
                $response['data'] = $data;
            }
        } else {
            $response['error'] = true;
            $response['message'] = "103";
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function set_bookmark_post()
    {
        $is_user = $this->verify_token();
        if (!$is_user['error']) {
            $user_id = $is_user['user_id'];
            $firebase_id = $is_user['firebase_id'];
        } else {
            $this->response($is_user, REST_Controller::HTTP_OK);
            return false;
        }

        if ($user_id && $this->post('question_id') && $this->post('status') != '' && $this->post('type')) {
            $question_id = $this->post('question_id');
            $status = $this->post('status');
            $type = $this->post('type');

            if ($status == '1' || $status == 1) {
                $frm_data = array(
                    'user_id' => $user_id,
                    'question_id' => $question_id,
                    'status' => $status,
                    'type' => $type,
                );
                $this->db->insert('tbl_bookmark', $frm_data);
            } else {
                $this->db->where('user_id', $user_id)->where('question_id', $question_id)->delete('tbl_bookmark');
            }
            $response['error'] = false;
            $response['message'] = "111";
        } else {
            $response['error'] = true;
            $response['message'] = "103";
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_notifications_post()
    {
        $is_user = $this->verify_token();
        if (!$is_user['error']) {
            $user_id = $is_user['user_id'];
            $firebase_id = $is_user['firebase_id'];
        } else {
            $this->response($is_user, REST_Controller::HTTP_OK);
            return false;
        }

        $get_user_data = $this->db->select('date_registered')->where('id', $user_id)->get('tbl_users')->row_array();
        $register_date = date('Y-m-d', strtotime($get_user_data['date_registered']));

        $limit = ($this->post('limit') && is_numeric($this->post('limit'))) ? $this->post('limit') : 10;
        $offset = ($this->post('offset') && is_numeric($this->post('offset'))) ? $this->post('offset') : 0;

        $sort = ($this->post('sort')) ? $this->post('sort') : 'id';
        $order = ($this->post('order')) ? $this->post('order') : 'DESC';

        $this->db->select('id,title,message,users,type,type_id,image,date_sent')
            ->from('tbl_notifications n')
            ->where('DATE(n.date_sent) >=', $register_date)
            ->group_start()
            ->where('n.users', 'all')
            ->or_where('FIND_IN_SET(' . $user_id . ', n.user_id) >', 0)
            ->group_end()
            ->order_by($sort, $order)
            ->limit($limit, $offset);
        $result = $this->db->get()->result_array();

        $this->db->select('COUNT(*) as total')
            ->from('tbl_notifications n')
            ->where('DATE(n.date_sent) >=', $register_date)
            ->group_start()
            ->where('n.users', 'all')
            ->or_where('FIND_IN_SET(' . $user_id . ', n.user_id) >', 0)
            ->group_end();
        $total = $this->db->get()->row()->total;

        if (!empty($result)) {
            for ($i = 0; $i < count($result); $i++) {
                if (filter_var($result[$i]['image'], FILTER_VALIDATE_URL) === false) {
                    /* Not a valid URL. Its a image only or empty */
                    $result[$i]['image'] = (!empty($result[$i]['image'])) ? base_url() . NOTIFICATION_IMG_PATH . $result[$i]['image'] : '';
                }
            }
        }
        
        // Always return success with data (empty array if no notifications)
        $response['error'] = false;
        $response['total'] = "$total";
        $response['data'] = $result ?: [];

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_user_by_id_post()
    {
        try {
            // ------- Should be Enabled for server  ----------
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
                $user_status = $is_user['status'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }
            // ---------------------------------------------------

            // ------- Should be Disable for server  ----------
            // $user_id = $this->post('user_id');
            // $firebase_id = $this->post('firebase_id');
            // ------------------------------------------------


            if ($user_status == 1) {
                if ($firebase_id) {
                    // /* Check User Daily Ads Counter */
                    $dailyAdsCoinQuery = $this->db->select('message')->where('type', 'daily_ads_coins')->get('tbl_settings')->row_array();
                    $dailyAdsCoin = $dailyAdsCoinQuery['message'];

                    // Get Daily Ads Counter from Settings
                    $dailyAdsCounterQuery = $this->db->select('message')->where('type', 'daily_ads_counter')->get('tbl_settings')->row_array();
                    $dailyAdsCounter = $dailyAdsCounterQuery['message'];

                    // Get User Daily Ads Counter And Date            
                    $res = $this->db->where('id', $user_id)->get('tbl_users')->row_array();
                    $userCounter = $res['daily_ads_counter'];
                    $userDailyAdsDate = $res['daily_ads_date'];

                    // Convert Date to string time 
                    $dailyAdsDate = strtotime($userDailyAdsDate);
                    $currentDate = strtotime(date('Y-m-d'));

                    if ($currentDate != $dailyAdsDate) {
                        // If Date Doen't match with today's date
                        // Then Update Counter to 0 and date to today's
                        $data = array(
                            'daily_ads_counter' => 0,
                            'daily_ads_date' => date('Y-m-d'),
                        );

                        // Update data and allow the user to watch ads
                        $this->db->where('id', $user_id)->where('firebase_id', $firebase_id)->update('tbl_users', $data);
                        $dailyAdsAvailable = 1;
                    } else {
                        if ($dailyAdsCounter == $userCounter) {
                            // If Daily Ads Counter is less than or equal to user's counter then not allow to watch ads
                            $dailyAdsAvailable = 0;
                        } else {
                            // If Daily Ads Counter is greater than or equal to user's counter then allow to watch ads
                            $dailyAdsAvailable = 1;
                        }
                    }
                    $res = $this->db->select('id, firebase_id, name, email, mobile, type, profile, fcm_id,web_fcm_id, coins, refer_code, friends_code, status, date_registered,remove_ads,app_language,web_language')->where('firebase_id', $firebase_id)->get('tbl_users')->row_array();
                    if ($res) {
                        $res1 = $this->db->where('user_id', $user_id)->get('tbl_users_badges')->row_array();
                        if (empty($res1)) {
                            $counter = 0;
                            $badges = [
                                'user_id' => $user_id,
                                'dashing_debut' => $counter,
                                'dashing_debut_counter' => $counter,
                                'combat_winner' => $counter,
                                'combat_winner_counter' => $counter,
                                'clash_winner' => $counter,
                                'clash_winner_counter' => $counter,
                                'most_wanted_winner' => $counter,
                                'most_wanted_winner_counter' => $counter,
                                'ultimate_player' => $counter,
                                'quiz_warrior' => $counter,
                                'quiz_warrior_counter' => $counter,
                                'super_sonic' => $counter,
                                'flashback' => $counter,
                                'brainiac' => $counter,
                                'big_thing' => $counter,
                                'elite' => $counter,
                                'thirsty' => $counter,
                                'thirsty_date' => '0000-00-00',
                                'thirsty_counter' => $counter,
                                'power_elite' => $counter,
                                'power_elite_counter' => $counter,
                                'sharing_caring' => $counter,
                                'streak' => $counter,
                                'streak_date' => '0000-00-00',
                                'streak_counter' => $counter,
                            ];
                            $this->db->insert('tbl_users_badges', $badges);
                        }

                        if (filter_var($res['profile'], FILTER_VALIDATE_URL) === false) {
                            // Not a valid URL. Its a image only or empty
                            $res['profile'] = ($res['profile']) ? base_url() . USER_IMG_PATH . $res['profile'] : '';
                        }
                        // Calculate all-time score and rank from tbl_contest_leaderboard (consistent with leaderboard screen)
                        // Using dense ranking: tied users share the same rank, next distinct score gets next rank
                        $my_rank_sql = "
                            SELECT 
                                COALESCE(m.total_score, 0) AS score,
                                COALESCE((
                                    SELECT COUNT(DISTINCT sub.total_score) + 1 
                                    FROM (
                                        SELECT user_id, SUM(score) AS total_score 
                                        FROM tbl_contest_leaderboard 
                                        GROUP BY user_id
                                    ) AS sub 
                                    WHERE sub.total_score > COALESCE(m.total_score, 0)
                                ), 1) AS user_rank 
                            FROM (
                                SELECT user_id, SUM(score) AS total_score 
                                FROM tbl_contest_leaderboard 
                                GROUP BY user_id
                            ) AS m 
                            WHERE m.user_id = ?
                        ";
                        $my_rank = $this->db->query($my_rank_sql, [$res['id']])->row_array();
                        $res['all_time_score'] = ($my_rank) ? $my_rank['score'] : '0';
                        $res['all_time_rank'] = ($my_rank) ? $my_rank['user_rank'] : '0';
                        $res['daily_ads_available'] = $dailyAdsAvailable ?? 0;

                        $getStreakData = $this->db->select('id,streak,streak_date')->where('user_id', $user_id)->get('tbl_users_badges')->row_array();
                        if ($getStreakData['streak'] == 0 && $getStreakData['streak_date'] != $this->toDate) {
                            $this->set_badge_counter($user_id, $this->STREAK, 0);
                        }

                        $response['error'] = false;
                        $response['data'] = $res;
                    } else {
                        $response['error'] = true;
                        $response['message'] = "131";
                    }
                } else {
                    $response['error'] = true;
                    $response['message'] = "103";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "126";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
            $response['error'] = $e;
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function check_user_exists_post()
    {
        try {
            if ($this->post('firebase_id')) {
                $firebase_id = $this->post('firebase_id');
                $res = $this->db->where('firebase_id', $firebase_id)->get('tbl_users')->row_array();
                if ($res) {
                    $response['error'] = false;
                    $response['message'] = "130";
                } else {
                    $response['error'] = false;
                    $response['message'] = "131";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
            $response['error'] = $e;
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function upload_profile_image_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            if ($user_id && $_FILES['image']['name'] != '') {
                // create folder
                if (!is_dir(USER_IMG_PATH)) {
                    mkdir(USER_IMG_PATH, 0777, true);
                }
                $config['upload_path'] = USER_IMG_PATH;
                $config['allowed_types'] = IMG_ALLOWED_WITH_SVG_TYPES;
                $config['file_name'] = time();
                $this->load->library('upload', $config);
                $this->upload->initialize($config);

                if (!$this->upload->do_upload('image')) {
                    $response['error'] = true;
                    $response['message'] = "107";
                } else {
                    $sql1 = $this->db->select('profile')->where('id', $user_id)->get('tbl_users')->row_array();
                    if ($sql1['profile'] != "") {
                        $full_url = USER_IMG_PATH . $sql1['profile'];
                        if (file_exists($full_url)) {
                            unlink($full_url);
                        }
                    }

                    $data = $this->upload->data();
                    $img = $data['file_name'];

                    if ($_FILES['image']['type'] != 'application/octet-stream' && $_FILES['image']['type'] != 'image/svg+xml') {

                        //image compress
                        $this->load->library('Compress'); // load the codeginiter library

                        $compress = new Compress();
                        $compress->file_url = base_url() . USER_IMG_PATH . $img;
                        $compress->new_name_image = $img;
                        $compress->quality = 80;
                        $compress->destination = base_url() . USER_IMG_PATH;
                        $compress->compress_image();
                    }

                    $insert_data = array(
                        'profile' => $img,
                    );
                    $this->db->where('id', $user_id)->update('tbl_users', $insert_data);

                    $res = $this->db->select('profile')->where('id', $user_id)->get('tbl_users')->row_array();
                    if (filter_var($res['profile'], FILTER_VALIDATE_URL) === false) {
                        // Not a valid URL. Its a image only or empty
                        $res['profile'] = ($res['profile']) ? base_url() . USER_IMG_PATH . $res['profile'] : '';
                    }
                    $response['error'] = false;
                    $response['message'] = '106';
                    $response['data'] = $res;
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
            $response['error'] = $e;
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function set_user_coin_score_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            if ($user_id) {
                if ($this->post('coins') && $this->post('title')) {
                    $coins = $this->post('coins');
                    $title = $this->post('title');
                    $status = $this->post('type') ? 0 : 1;
                    if ($this->post('type')) {
                        $type = $this->post('type');
                        if ($type != 'watchedRewardAd') {
                            $this->set_badges_reward($user_id, $type);
                        }
                    }
                    $this->set_coins($user_id, $coins);
                    $this->set_tracker_data($user_id, $coins, $title, $status);
                } else if ($this->post('score')) {
                    $score = $this->post('score');
                    $this->set_monthly_leaderboard($user_id, $score);
                }

                $result = $this->db->select('coins')->where('id', $user_id)->get('tbl_users')->row_array();

                if (!empty($result)) {
                    $my_rank = $this->myGlobalRank($user_id);

                    $result['score'] = ($my_rank) ? $my_rank['score'] : '0';

                    $response['error'] = false;
                    $response['message'] = "111";
                    $response['data'] = $result;
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
            $response['error'] = $e;
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function update_profile_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            if ($user_id) {
                $data = array();
                if ($this->post('name')) {
                    $data['name'] = $this->post('name');
                }

                if ($this->post('email')) {
                    $data['email'] = $this->post('email');
                }
                if ($this->post('mobile')) {
                    $data['mobile'] = $this->post('mobile');
                }
                if ($this->post('app_language')) {
                    $data['app_language'] = $this->post('app_language');
                }
                if ($this->post('web_language')) {
                    $data['web_language'] = $this->post('web_language');
                }
                if ($this->post('remove_ads')) {
                    if ($this->post('remove_ads') <= 1 && $this->post('remove_ads') > -1) {
                        $data['remove_ads'] = $this->post('remove_ads');
                    } else {
                        $response['error'] = false;
                        $response['message'] = "122";
                        $this->response($response, REST_Controller::HTTP_OK);
                        return false;
                    }
                }
                $this->db->where('id', $user_id)->update('tbl_users', $data);

                $response['error'] = false;
                $response['message'] = "106";
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
            $response['error'] = $e;
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_categories_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $user_id = 0;
            }
            if ($this->post('type')) {
                $type = $this->post('type');
                $subType = $this->post('sub_type') ?? 0;
                $no_of_que_Condition = '';
                $no_of_Condition = '';
                $join = '';
                if ($type == 1 || $type == '1') {
                    $tbl = 'tbl_question';
                    if ($subType) {
                        if ($subType == 1) {
                            $join .= 'LEFT JOIN tbl_user_category uc ON q.category = uc.category_id';
                            $no_of_que_Condition .= 'AND (c.is_premium = 0 OR (c.is_premium = 1 AND uc.user_id = ' . $user_id . '))';
                        } else {
                            $no_of_que_Condition .= 'AND c.is_premium = 0';
                        }
                        $no_of_Condition .= 'AND c.is_premium = 0';
                    }
                } else if ($type == 2 || $type == '2') {
                    $tbl = 'tbl_fun_n_learn';
                } else if ($type == 3 || $type == '3') {
                    $tbl = 'tbl_guess_the_word';
                } else if ($type == 4 || $type == '4') {
                    $tbl = 'tbl_audio_question';
                } else if ($type == 5 || $type == '5') {
                    $tbl = 'tbl_maths_question';
                } else if ($type == 6 || $type == '6') {
                    $tbl = 'tbl_multi_match';
                }

                $no_of =  '(SELECT COUNT(s.id) FROM tbl_subcategory s WHERE s.maincat_id = c.id ' . $no_of_Condition . ' AND s.status = 1 AND s.id IN (SELECT DISTINCT subcategory FROM ' . $tbl . ' WHERE subcategory != 0)) as no_of';
                $no_of_que = ',(select count(q.id) from ' . $tbl . ' q ' . $join . ' where q.category=c.id ' . $no_of_que_Condition . ') as no_of_que';

                $maxlevel = '';
                if ($type == 1 || $type == 6) {
                    $maxlevel = ',(CASE WHEN (SELECT COUNT(s.id) FROM tbl_subcategory s WHERE s.maincat_id = c.id AND s.status = 1 AND s.id IN (SELECT DISTINCT subcategory FROM ' . $tbl . ' WHERE subcategory != 0 )) = 0 THEN (SELECT MAX(CAST(level AS UNSIGNED)) FROM ' . $tbl . ' q WHERE q.category = c.id) ELSE 0 END) AS maxlevel';
                }

                $has_unlocked = '';
                if ($user_id) {
                    $has_unlocked = ',(SELECT COUNT(*) FROM tbl_user_category uc WHERE uc.category_id = c.id AND uc.user_id = ' . $user_id . ') AS has_unlocked';
                }
                $selectField = 'c.*,' . $no_of . $no_of_que . $maxlevel . $has_unlocked;
                $this->db->select($selectField);
                $this->db->from('tbl_category c');
                $this->db->where('type', $type);
                if ($this->post('id')) {
                    $id = $this->post('id');
                    $this->db->where('id', $id);
                }
                if ($this->post('language_id')) {
                    $language_id = $this->post('language_id');
                    $this->db->where('language_id', $language_id);
                }
                $this->db->having('no_of_que >', 0); // check that no of questions should be more than 0
                $this->db->order_by('row_order', 'ASC');
                $data = $this->db->get()->result_array();
                if (!empty($data)) {
                    for ($i = 0; $i < count($data); $i++) {
                        $data[$i]['image'] = $data[$i]['image'] ? base_url() . CATEGORY_IMG_PATH . $data[$i]['image'] : '';
                        $data[$i]['maxlevel'] = (array_key_exists('maxlevel', $data[$i]) && !empty($data[$i]['maxlevel'])) ? $data[$i]['maxlevel'] : '0';
                        if ($user_id) {
                            //check if category played or not
                            $res = $this->db->where('category', $data[$i]['id'])->where('type', $type)->where('user_id', $user_id)->get('tbl_quiz_categories')->row_array();
                            $data[$i]['is_play'] = !empty($res) ? '1' : '0';
                            $data[$i]['has_unlocked'] = $data[$i]['has_unlocked'] ? '1' : '0';
                        }
                    }
                    $response['error'] = false;
                    $response['subType'] = $subType;
                    $response['data'] = $data;
                } else {
                    $response['error'] = true;
                    $response['message'] = '102';
                }
            } else {
                $response['error'] = true;
                $response['message'] = '103';
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_subcategory_by_maincategory_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            if ($user_id && ($this->post('category') || $this->post('category_slug'))) {
                $category = $this->post('category') ?? 0;
                $categorySlug = !empty($this->post('category_slug')) ? $this->post('category_slug') : null;
                $res = $this->getCategoryData($category, $categorySlug);

                if ($res) {
                    $type = (!empty($res)) ? $res['type'] : 1;

                    if ($type == 1 || $type == '1') {
                        $no_of_que = ' (select count(id) from tbl_question q where q.subcategory=s.id ) as no_of_que,';
                    } else if ($type == 2 || $type == '2') {
                        $no_of_que = ' (select count(id) from tbl_fun_n_learn q where q.subcategory=s.id AND q.status=1) as no_of_que,';
                    } else if ($type == 3 || $type == '3') {
                        $no_of_que = ' (select count(id) from tbl_guess_the_word q where q.subcategory=s.id ) as no_of_que,';
                    } else if ($type == 4 || $type == '4') {
                        $no_of_que = ' (select count(id) from tbl_audio_question q where q.subcategory=s.id ) as no_of_que,';
                    } else if ($type == 5 || $type == '5') {
                        $no_of_que = ' (select count(id) from tbl_maths_question q where q.subcategory=s.id ) as no_of_que,';
                    } else if ($type == 6 || $type == '6') {
                        $no_of_que = ' (select count(id) from tbl_multi_match q where q.subcategory=s.id ) as no_of_que,';
                    }

                    if ($type == 6) {
                        $this->db->select('s.*,`c.category_name as category_name, ' . $no_of_que . ' (select max(`level` + 0) from tbl_multi_match q where q.subcategory=s.id ) as maxlevel');
                    } else {
                        $this->db->select('s.*,`c.category_name as category_name, ' . $no_of_que . ' (select max(`level` + 0) from tbl_question q where q.subcategory=s.id ) as maxlevel');
                    }
                    $this->db->join('tbl_category c', 'c.id = s.maincat_id');
                    $this->db->where('maincat_id', $res['id']);
                    $this->db->where('status', 1);
                    $this->db->having('no_of_que >', 0); // check that no of questions should be more than 0
                    $this->db->order_by('row_order', 'ASC');
                    $data = $this->db->get('tbl_subcategory s')->result_array();
                    if (!empty($data)) {
                        for ($i = 0; $i < count($data); $i++) {
                            $data[$i]['image'] = ($data[$i]['image']) ? base_url() . SUBCATEGORY_IMG_PATH . $data[$i]['image'] : '';
                            $data[$i]['maxlevel'] = ($data[$i]['maxlevel'] == '' || $data[$i]['maxlevel'] == null) ? '0' : $data[$i]['maxlevel'];

                            //check if category played or not
                            $res = $this->db->where('subcategory', $data[$i]['id'])->where('category', $data[$i]['maincat_id'])->where('user_id', $user_id)->get('tbl_quiz_categories')->row_array();
                            $data[$i]['is_play'] = (!empty($res)) ? '1' : '0';
                        }
                        $response['error'] = false;
                        $response['data'] = $data;
                    } else {
                        $response['error'] = true;
                        $response['message'] = "102";
                    }
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_questions_by_level_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {

                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {

                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }
            if ($this->post('level') && ($this->post('category') || $this->post('subcategory'))) {
                $level = $this->post('level');
                $language_id = ($this->post('language_id')) ? $this->post('language_id') : 0;
                $category_id = $this->post('category');
                $subcategory_id = $this->post('subcategory');
                $fix_question = is_settings('quiz_zone_fix_level_question');
                $limit = is_settings('quiz_zone_total_level_question');

                $this->db->select('tbl_question.*,cat.slug as category_slug,subcat.slug as subcategory_slug');
                $this->db->where('level', $level);
                $this->db->join('tbl_category cat', 'cat.id=tbl_question.category', 'left');
                $this->db->join('tbl_subcategory subcat', 'subcat.id=tbl_question.subcategory', 'left');
                if ($this->post('subcategory')) {
                    $this->db->where('tbl_question.subcategory', $subcategory_id);
                } else {
                    $this->db->where('tbl_question.category', $category_id);
                }
                if (!empty($language_id)) {
                    $this->db->where('tbl_question.language_id', $language_id);
                }
                $this->db->order_by($this->Order_By);
                if ($fix_question == 1) {
                    $this->db->limit($limit, 0);
                }
                $data = $this->db->get('tbl_question')->result_array();
                $questionData = [];
                if (!empty($data)) {
                    for ($i = 0; $i < count($data); $i++) {
                        $data[$i]['image'] = ($data[$i]['image']) ? base_url() . QUESTION_IMG_PATH . $data[$i]['image'] : '';
                        $optionData = $this->suffleOptions($data[$i], $firebase_id);
                        $data[$i] = $optionData;
                        $questionData[] = [
                            'id' => $data[$i]['id'],
                            'answer' => $data[$i]['session_answer'],
                            'level' => $data[$i]['level']
                        ];
                        unset($data[$i]['session_answer']);
                    }
                    if ($questionData) {
                        $this->set_user_session($user_id, $questionData, 'tbl_user_quiz_zone_session');
                    }
                    $response['error'] = false;
                    $response['data'] = $data;
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_daily_quiz_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            if ($user_id) {
                $timezone = $this->post('timezone') ? $this->post('timezone') : $this->systemTimezone;
                $today = new DateTime('now', new DateTimeZone($timezone));
                $today_date = $today->format('Y-m-d');
                $gmt_format = $this->post('gmt_format') ? $this->post('gmt_format') : $this->systemTimezoneGMT;

                $res1 = $this->db->where("DATE(CONVERT_TZ(date, '+00:00', '" . $gmt_format . "')) =", $today_date)->where('user_id', $user_id)->get('tbl_daily_quiz_user')->row_array();
                if (empty($res1)) {
                    $questions = $response = array();
                    $language_id = ($this->post('language_id') && is_numeric($this->post('language_id'))) ? $this->post('language_id') : '0';
                    $res = $this->db->where("DATE(CONVERT_TZ(date_published, '+00:00', '" . $gmt_format . "')) =", $today_date)->where('language_id', $language_id)->get('tbl_daily_quiz')->row_array();
                    if (!empty($res)) {
                        $res2 = $this->db->where('user_id', $user_id)->get('tbl_daily_quiz_user')->row_array();
                        if (!empty($res2)) {
                            $frm_data = array(
                                'date' => $today_date,
                            );
                            $this->db->where('user_id', $user_id)->update('tbl_daily_quiz_user', $frm_data);
                        } else {
                            $frm_data = array(
                                'user_id' => $user_id,
                                'date' => $today_date,
                            );
                            $this->db->insert('tbl_daily_quiz_user', $frm_data);
                        }

                        $questions = $res['questions_id'];
                        $questionData = [];
                        $result = $this->db->query("SELECT * FROM tbl_question WHERE id IN (" . $questions . ") ORDER BY FIELD(id," . $questions . ")")->result_array();
                        if (!empty($result)) {
                            for ($i = 0; $i < count($result); $i++) {
                                $result[$i]['image'] = ($result[$i]['image']) ? base_url() . QUESTION_IMG_PATH . $result[$i]['image'] : '';
                                $optionData = $this->suffleOptions($result[$i], $firebase_id);
                                $result[$i] = $optionData;
                                $questionData[] = [
                                    'id' => $result[$i]['id'],
                                    'answer' => $result[$i]['session_answer']
                                ];
                                unset($result[$i]['session_answer']);
                            }
                            if ($questionData) {
                                $this->set_user_session($user_id, $questionData, 'tbl_user_daily_quiz_session');
                            }
                            $response['error'] = false;
                            $response['data'] = $result;
                        } else {
                            $response['error'] = true;
                            $response['message'] = "102";
                        }
                    } else {
                        $response['error'] = true;
                        $response['message'] = "102";
                    }
                } else {
                    $response['error'] = true;
                    $response['message'] = "112";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_level_data_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            if ($user_id && ($this->post('category') || $this->post('category_slug'))) {
                $category = $this->post('category') ?? 0;
                $categorySlug = !empty($this->post('category_slug')) ? $this->post('category_slug') : null;
                $subcategory = ($this->post('subcategory')) ? $this->post('subcategory') : 0;
                $subcategorySlug = !empty($this->post('subcategory_slug')) ? $this->post('subcategory_slug') : null;

                if ($subcategory) {
                    $subcategoryData = $this->db->select("id,maincat_id,subcategory_name,slug")->where('id', $subcategory)->get('tbl_subcategory')->row_array();
                    if ($subcategoryData) {
                        $categoryData = $this->getCategoryData($category, $categorySlug);
                        $questionData = $this->getQuestionData($subcategoryData, $categoryData);
                    }
                } elseif ($subcategorySlug) {
                    $subcategoryData = $this->db->select("id,maincat_id,subcategory_name,slug")->where('slug', $subcategorySlug)->get('tbl_subcategory')->row_array();
                    if ($subcategoryData) {
                        $categoryData = $this->getCategoryData($category, $categorySlug);
                        $questionData = $this->getQuestionData($subcategoryData, $categoryData);
                    }
                } else {
                    $categoryData = $this->getCategoryData($category, $categorySlug);
                    $subcategoryData = ['id' => 0];
                    $questionData = $this->getQuestionData($subcategoryData, $categoryData);
                }

                if ((isset($categoryData) && !empty($categoryData)) && (isset($subcategoryData) && !empty($subcategoryData))) {
                    // Get Level Data with its Particular Question Count
                    $max_level = $questionData['max_level'];
                    $counter = range(1, $max_level);
                    $levelData = [];

                    foreach ($counter as $key => $level) {
                        $query = $this->db->query('select count(id) as no_of_que from tbl_question where level = ' . $level . ' and category = ' . $categoryData["id"] . ' and subcategory = ' . $subcategoryData["id"])->row_array();
                        $levelData[$key]['level'] = $level;
                        $levelData[$key]['no_of_ques'] = $query['no_of_que'];
                    }

                    // Get Data 
                    $res = $this->db->select('level')->where('user_id', $user_id)->where('category', $categoryData['id'])->where('subcategory', $subcategoryData['id'])->get('tbl_level')->row_array();
                    $data = array(
                        'level' => $res['level'] ?? "1",
                        'no_of_ques' => $questionData['no_of_que'],
                        'max_level' => $questionData['max_level'],
                        'category' => $categoryData ?? [],
                        'subcategory' => $subcategoryData ?? [],
                        'level_data' => $levelData ?? []
                    );
                    $response['error'] = false;
                    $response['data'] = $data;
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_questions_for_self_challenge_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            if ($this->post('limit') && ($this->post('category') || $this->post('subcategory') || $this->post('category_slug') || $this->post('subcategory_slug'))) {
                $language_id = ($this->post('language_id')) ? $this->post('language_id') : 0;
                $limit = $this->post('limit');

                // Get Category and subcategory data from params
                $category = $this->post('category') ?? 0;
                $categorySlug = !empty($this->post('category_slug')) ? $this->post('category_slug') : '';
                $subcategory = ($this->post('subcategory')) ? $this->post('subcategory') : 0;
                $subcategorySlug = !empty($this->post('subcategory_slug')) ? $this->post('subcategory_slug') : '';

                if ($subcategory || $subcategorySlug) {
                    // if Subcategory is there 
                    $subcategory = $this->getSubCategoryData($subcategory, $subcategorySlug);
                    $this->db->where('subcategory', $subcategory['id']);
                } else {
                    // Else show category data
                    $categoryData = $this->getCategoryData($category, $categorySlug);
                    $this->db->where('category', $categoryData['id']);
                }

                if (!empty($language_id)) {
                    $this->db->where('language_id', $language_id);
                }
                $this->db->order_by($this->Order_By)->limit($limit, 0);
                $data = $this->db->get('tbl_question')->result_array();
                if (!empty($data)) {
                    for ($i = 0; $i < count($data); $i++) {
                        $data[$i]['image'] = ($data[$i]['image']) ? base_url() . QUESTION_IMG_PATH . $data[$i]['image'] : '';
                        $data[$i] = $this->suffleOptions($data[$i], $firebase_id);
                        unset($data[$i]['session_answer']);
                    }
                    $response['error'] = false;
                    $response['data'] = $data;
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Monthly Leaderboard - Based on Contest Scores for THIS MONTH
     * Shows rankings from daily Rhapsody contests only
     */
    public function get_monthly_leaderboard_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            $offset = (int)($this->post('offset') ?: 0);
            $limit = (int)($this->post('limit') ?: 25);
            $month = date('m');
            $year = date('Y');

            // Initialize defaults
            $data = array();
            $topThreeUsersData = array();
            $user_rank = array(
                'user_id' => $user_id,
                'score' => '0',
                'user_rank' => '0',
                'email' => '',
                'name' => '',
                'profile' => '',
            );

            // Base query: Contest scores for this month + all active users
            $base_sql = "
                SELECT u.id as user_id, u.email, u.name, u.profile,
                       COALESCE(SUM(cl.score), 0) as score,
                       MAX(cl.last_updated) as last_updated
                FROM tbl_users u
                LEFT JOIN tbl_contest_leaderboard cl ON u.id = cl.user_id
                LEFT JOIN tbl_contest c ON cl.contest_id = c.id 
                    AND YEAR(c.start_date) = ? AND MONTH(c.start_date) = ?
                WHERE u.status = 1
                GROUP BY u.id, u.email, u.name, u.profile
                ORDER BY score DESC, u.name ASC
            ";

            // Dense ranking: tied users share same rank, next distinct score gets next consecutive rank
            $ranked_sql = "
                SELECT r.*,
                       @rank := IF(@prev_score = r.score, @rank, @rank + 1) as user_rank,
                       @prev_score := r.score
                FROM ($base_sql) r,
                     (SELECT @rank := 0, @prev_score := NULL) init
            ";

            // Get total active users
            $total = $this->db->where('status', 1)->count_all_results('tbl_users');

            if ($user_id && $total > 0) {
                // Get paginated results
                $sql = "SELECT * FROM ($ranked_sql) ranked ORDER BY user_rank ASC LIMIT ? OFFSET ?";
                $result = $this->db->query($sql, array($year, $month, $limit, $offset));
                $data = $result->result_array();

                // Process profile URLs
                foreach ($data as &$row) {
                    if (!filter_var($row['profile'], FILTER_VALIDATE_URL)) {
                        $row['profile'] = $row['profile'] ? base_url() . USER_IMG_PATH . $row['profile'] : '';
                    }
                }

                // Top 3 for podium
                $top3_sql = "SELECT * FROM ($ranked_sql) ranked ORDER BY user_rank ASC LIMIT 3";
                $top3_result = $this->db->query($top3_sql, array($year, $month));
                $topThreeUsersData = $top3_result->result_array();

                foreach ($topThreeUsersData as &$row) {
                    if (!filter_var($row['profile'], FILTER_VALIDATE_URL)) {
                        $row['profile'] = $row['profile'] ? base_url() . USER_IMG_PATH . $row['profile'] : '';
                    }
                }

                // Current user's rank
                $my_sql = "SELECT * FROM ($ranked_sql) ranked WHERE user_id = ? LIMIT 1";
                $my_result = $this->db->query($my_sql, array($year, $month, $user_id));
                $my_rank = $my_result->row_array();

                if (!empty($my_rank)) {
                    if (!filter_var($my_rank['profile'], FILTER_VALIDATE_URL)) {
                        $my_rank['profile'] = $my_rank['profile'] ? base_url() . USER_IMG_PATH . $my_rank['profile'] : '';
                    }
                    $user_rank = $my_rank;
                }
            }

            $response['error'] = false;
            $response['total'] = "$total";
            $response['data'] = array(
                'my_rank' => $user_rank,
                'other_users_rank' => $data,
                'top_three_ranks' => $topThreeUsersData
            );
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Daily Leaderboard - Based on Contest Scores for TODAY
     * Shows rankings from daily Rhapsody contests only
     */
    public function get_daily_leaderboard_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            $offset = (int)($this->post('offset') ?: 0);
            $limit = (int)($this->post('limit') ?: 25);
            $today = date('Y-m-d');

            // Initialize defaults
            $data = array();
            $topThreeUsersData = array();
            $user_rank = array(
                'user_id' => $user_id,
                'score' => '0',
                'user_rank' => '0',
                'email' => '',
                'name' => '',
                'profile' => '',
            );

            // Base query: Contest scores for today + all active users with 0 if no entry
            $base_sql = "
                SELECT u.id as user_id, u.email, u.name, u.profile,
                       COALESCE(SUM(cl.score), 0) as score,
                       MAX(cl.last_updated) as last_updated
                FROM tbl_users u
                LEFT JOIN tbl_contest_leaderboard cl ON u.id = cl.user_id
                LEFT JOIN tbl_contest c ON cl.contest_id = c.id AND DATE(c.start_date) = ?
                WHERE u.status = 1
                GROUP BY u.id, u.email, u.name, u.profile
                ORDER BY score DESC, u.name ASC
            ";

            // Dense ranking: tied users share same rank, next distinct score gets next consecutive rank
            $ranked_sql = "
                SELECT r.*,
                       @rank := IF(@prev_score = r.score, @rank, @rank + 1) as user_rank,
                       @prev_score := r.score
                FROM ($base_sql) r,
                     (SELECT @rank := 0, @prev_score := NULL) init
            ";

            // Get total active users
            $total = $this->db->where('status', 1)->count_all_results('tbl_users');

            if ($user_id && $total > 0) {
                // Get paginated results
                $sql = "SELECT * FROM ($ranked_sql) ranked ORDER BY user_rank ASC LIMIT ? OFFSET ?";
                $result = $this->db->query($sql, array($today, $limit, $offset));
                $data = $result->result_array();

                // Process profile URLs
                foreach ($data as &$row) {
                    if (!filter_var($row['profile'], FILTER_VALIDATE_URL)) {
                        $row['profile'] = $row['profile'] ? base_url() . USER_IMG_PATH . $row['profile'] : '';
                    }
                }

                // Top 3 for podium
                $top3_sql = "SELECT * FROM ($ranked_sql) ranked ORDER BY user_rank ASC LIMIT 3";
                $top3_result = $this->db->query($top3_sql, array($today));
                $topThreeUsersData = $top3_result->result_array();

                foreach ($topThreeUsersData as &$row) {
                    if (!filter_var($row['profile'], FILTER_VALIDATE_URL)) {
                        $row['profile'] = $row['profile'] ? base_url() . USER_IMG_PATH . $row['profile'] : '';
                    }
                }

                // Current user's rank
                $my_sql = "SELECT * FROM ($ranked_sql) ranked WHERE user_id = ? LIMIT 1";
                $my_result = $this->db->query($my_sql, array($today, $user_id));
                $my_rank = $my_result->row_array();

                if (!empty($my_rank)) {
                    if (!filter_var($my_rank['profile'], FILTER_VALIDATE_URL)) {
                        $my_rank['profile'] = $my_rank['profile'] ? base_url() . USER_IMG_PATH . $my_rank['profile'] : '';
                    }
                    $user_rank = $my_rank;
                }
            }

            $response['error'] = false;
            $response['total'] = "$total";
            $response['data'] = array(
                'my_rank' => $user_rank,
                'other_users_rank' => $data,
                'top_three_ranks' => $topThreeUsersData
            );
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Global Leaderboard - Based on ALL Contest Scores (All Time)
     * Shows rankings from all daily Rhapsody contests ever
     */
    public function get_globle_leaderboard_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            $offset = (int)($this->post('offset') ?: 0);
            $limit = (int)($this->post('limit') ?: 25);

            // Initialize defaults
            $data = array();
            $topThreeUsersData = array();
            $user_rank = array(
                'user_id' => $user_id,
                'score' => '0',
                'user_rank' => '0',
                'email' => '',
                'name' => '',
                'profile' => '',
            );

            // Base query: ALL contest scores + all active users
            $base_sql = "
                SELECT u.id as user_id, u.email, u.name, u.profile,
                       COALESCE(SUM(cl.score), 0) as score,
                       MAX(cl.last_updated) as last_updated
                FROM tbl_users u
                LEFT JOIN tbl_contest_leaderboard cl ON u.id = cl.user_id
                WHERE u.status = 1
                GROUP BY u.id, u.email, u.name, u.profile
                ORDER BY score DESC, u.name ASC
            ";

            // Dense ranking query: tied users share same rank, next distinct score gets next consecutive rank
            // Example: 1st, 1st, 2nd, 2nd, 3rd (not 1st, 1st, 3rd, 3rd, 5th)
            $ranked_sql = "
                SELECT r.*,
                       @rank := IF(@prev_score = r.score, @rank, @rank + 1) as user_rank,
                       @prev_score := r.score
                FROM ($base_sql) r,
                     (SELECT @rank := 0, @prev_score := NULL) init
            ";

            // Get total active users
            $total = $this->db->where('status', 1)->count_all_results('tbl_users');

            if ($user_id && $total > 0) {
                // Get paginated results
                $sql = "SELECT * FROM ($ranked_sql) ranked ORDER BY user_rank ASC LIMIT ? OFFSET ?";
                $result = $this->db->query($sql, array($limit, $offset));
                $data = $result->result_array();

                // Process profile URLs
                foreach ($data as &$row) {
                    if (!filter_var($row['profile'], FILTER_VALIDATE_URL)) {
                        $row['profile'] = $row['profile'] ? base_url() . USER_IMG_PATH . $row['profile'] : '';
                    }
                }

                // Top 3 for podium
                $top3_sql = "SELECT * FROM ($ranked_sql) ranked ORDER BY user_rank ASC LIMIT 3";
                $top3_result = $this->db->query($top3_sql);
                $topThreeUsersData = $top3_result->result_array();

                foreach ($topThreeUsersData as &$row) {
                    if (!filter_var($row['profile'], FILTER_VALIDATE_URL)) {
                        $row['profile'] = $row['profile'] ? base_url() . USER_IMG_PATH . $row['profile'] : '';
                    }
                }

                // Current user's rank
                $my_sql = "SELECT * FROM ($ranked_sql) ranked WHERE user_id = ? LIMIT 1";
                $my_result = $this->db->query($my_sql, array($user_id));
                $my_rank = $my_result->row_array();

                if (!empty($my_rank)) {
                    if (!filter_var($my_rank['profile'], FILTER_VALIDATE_URL)) {
                        $my_rank['profile'] = $my_rank['profile'] ? base_url() . USER_IMG_PATH . $my_rank['profile'] : '';
                    }
                    $user_rank = $my_rank;
                }
            }

            $response['error'] = false;
            $response['total'] = "$total";
            $response['data'] = array(
                'my_rank' => $user_rank,
                'other_users_rank' => $data,
                'top_three_ranks' => $topThreeUsersData
            );
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_questions_by_type_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            if ($this->post('type')) {
                $type = $this->post('type');
                $language_id = ($this->post('language_id')) ? $this->post('language_id') : "0";
                $fix_question = is_settings('true_false_quiz_fix_question');
                $limit = is_settings('true_false_quiz_total_question');

                $this->db->select('tbl_question.*,c.id as cat_id, sc.id as subcat_id'); // Select all columns from tbl_question

                $this->db->where('tbl_question.question_type', $type);
                if (!empty($language_id)) {
                    $this->db->where('tbl_question.language_id', $language_id);
                }
                $this->db->join('tbl_category c', 'tbl_question.category = c.id')->where('c.is_premium', '0');
                $this->db->join('tbl_subcategory sc', 'tbl_question.subcategory = sc.id', 'left');
                $this->db->order_by($this->Order_By);

                if ($fix_question == 1 && $limit) {
                    $this->db->limit($limit, 0);
                }

                $data = $this->db->get('tbl_question')->result_array();

                $questionData = [];
                if (!empty($data)) {
                    for ($i = 0; $i < count($data); $i++) {
                        $data[$i]['image'] = ($data[$i]['image']) ? base_url() . QUESTION_IMG_PATH . $data[$i]['image'] : '';
                        $optionData = $this->suffleOptions($data[$i], $firebase_id);
                        $data[$i] = $optionData;
                        $questionData[] = [
                            'id' => $data[$i]['id'],
                            'answer' => $data[$i]['session_answer'],
                            'level' => $data[$i]['level']
                        ];
                        unset($data[$i]['session_answer']);
                    }
                    if ($questionData) {
                        $this->set_user_session($user_id, $questionData, 'tbl_user_true_false_session');
                    }

                    $response['error'] = false;
                    $response['data'] = $data;
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_contest_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            if ($user_id) {
                $timezone = $this->post('timezone') ? $this->post('timezone') : $this->systemTimezone;
                $today = new DateTime('now', new DateTimeZone($timezone));
                $today_date = $today->format('Y-m-d H:i:00');
                $gmt_format = $this->post('gmt_format') ? $this->post('gmt_format') : $this->systemTimezoneGMT;

                $toDateTime = (new DateTime("now", new DateTimeZone($timezone)))->format("Y-m-d H:i:00");

                $language_id = ($this->post('language_id') && is_numeric($this->post('language_id'))) ? $this->post('language_id') : '0';

                /* selecting live quiz ids (excluding daily contests which are shown separately) */
                if ($language_id) {
                    $result = $this->db->query("SELECT id FROM tbl_contest WHERE status=1 AND language_id = $language_id AND contest_type != 'daily' AND (CONVERT_TZ('" . $toDateTime . "', '+00:00', '" . $gmt_format . "') BETWEEN CONVERT_TZ(start_date, '+00:00', '" . $gmt_format . "') AND CONVERT_TZ(end_date, '+00:00', '" . $gmt_format . "'))")->result_array();
                } else {
                    $result = $this->db->query("SELECT id FROM tbl_contest WHERE status=1 AND contest_type != 'daily' AND (CONVERT_TZ('" . $toDateTime . "', '+00:00', '" . $gmt_format . "') BETWEEN CONVERT_TZ(start_date, '+00:00', '" . $gmt_format . "') AND CONVERT_TZ(end_date, '+00:00', '" . $gmt_format . "'))")->result_array();
                }


                $live_type_ids = $past_type_ids = '';
                if (!empty($result)) {
                    foreach ($result as $type_id) {
                        $live_type_ids .= $type_id['id'] . ', ';
                    }
                    $live_type_ids = rtrim($live_type_ids, ', ');

                    /* getting past quiz ids & its data which user has played */
                    $result = $this->db->query("SELECT contest_id FROM tbl_contest_leaderboard WHERE contest_id in ($live_type_ids) and user_id = $user_id ORDER BY id DESC")->result_array();
                    if (!empty($result)) {
                        foreach ($result as $type_id) {
                            $past_type_ids .= $type_id['contest_id'] . ', ';
                        }
                        $past_type_ids = rtrim($past_type_ids, ', ');

                        $past_result = $this->db->query("SELECT *, (select SUM(points) FROM tbl_contest_prize tcp WHERE tcp.contest_id=c.id) as points, (select count(contest_id) FROM tbl_contest_prize tcp WHERE tcp.contest_id=c.id) as top_users,(SELECT COUNT(*) from tbl_contest_leaderboard tcl where tcl.contest_id = c.id ) as participants FROM tbl_contest c WHERE c.id in ($past_type_ids) ORDER BY c.id DESC")->result_array();
                        unset($result);
                        foreach ($past_result as $quiz) {
                            $quiz['image'] = (!empty($quiz['image'])) ? base_url() . CONTEST_IMG_PATH . $quiz['image'] : '';
                            $quiz['start_date'] = date("d-M", strtotime($quiz['start_date']));
                            $quiz['end_date'] = date("d-M", strtotime($quiz['end_date']));

                            $points = $this->db->query("SELECT top_winner, points FROM tbl_contest_prize WHERE contest_id=" . $quiz['id'])->result_array();
                            $quiz['points'] = $points;
                            $result[] = $quiz;
                        }
                        $past_result = $result;
                        $response['past_contest']['error'] = false;
                        $response['past_contest']['message'] = "117";
                        $response['past_contest']['data'] = (!empty($past_result)) ? $past_result : '';
                    } else {
                        if ($language_id) {
                            $past_result = $this->db->query("SELECT c.*, (select SUM(points) FROM tbl_contest_prize tcp WHERE tcp.contest_id=c.id) as points, (select count(contest_id) FROM tbl_contest_prize tcp WHERE tcp.contest_id=c.id) as top_users,(SELECT COUNT(*) from tbl_contest_leaderboard tcl where tcl.contest_id=c.id ) as participants FROM tbl_contest_leaderboard as l, tbl_contest as c WHERE l.user_id = '$user_id' and l.contest_id = c.id and c.language_id = $language_id AND c.contest_type != 'daily' ORDER BY c.id DESC")->result_array();
                        } else {
                            $past_result = $this->db->query("SELECT c.*, (select SUM(points) FROM tbl_contest_prize tcp WHERE tcp.contest_id=c.id) as points, (select count(contest_id) FROM tbl_contest_prize tcp WHERE tcp.contest_id=c.id) as top_users,(SELECT COUNT(*) from tbl_contest_leaderboard tcl where tcl.contest_id=c.id ) as participants FROM tbl_contest_leaderboard as l, tbl_contest as c WHERE l.user_id = '$user_id' and l.contest_id = c.id AND c.contest_type != 'daily' ORDER BY c.id DESC")->result_array();
                        }
                        if (!empty($past_result)) {
                            foreach ($past_result as $quiz) {
                                $quiz['image'] = (!empty($quiz['image'])) ? base_url() . CONTEST_IMG_PATH . $quiz['image'] : '';
                                $quiz['start_date'] = date("d-M", strtotime($quiz['start_date']));
                                $quiz['end_date'] = date("d-M", strtotime($quiz['end_date']));
                                $points = $this->db->query("SELECT top_winner, points FROM tbl_contest_prize WHERE contest_id=" . $quiz['id'])->result_array();
                                $quiz['points'] = $points;
                                $result[] = $quiz;
                            }
                            $past_result = $result;
                            $response['past_contest']['error'] = false;
                            $response['past_contest']['message'] = "117";
                            $response['past_contest']['data'] = (!empty($past_result)) ? $past_result : '';
                        } else {
                            $response['past_contest']['error'] = true;
                            $response['past_contest']['message'] = "116";
                        }
                    }

                    /* getting all quiz details by ids retrieved */
                    $sql = (empty($past_type_ids)) ?
                        "SELECT c.*, (select SUM(points) FROM tbl_contest_prize tcp WHERE tcp.contest_id=c.id) as points, (select count(contest_id) FROM tbl_contest_prize tcp WHERE tcp.contest_id=c.id) as top_users,(SELECT COUNT(*) from tbl_contest_leaderboard tcl WHERE tcl.contest_id=c.id ) as participants FROM tbl_contest c WHERE id IN ($live_type_ids) AND status='1' ORDER BY `id` DESC" :
                        "SELECT c.*, (select SUM(points) FROM tbl_contest_prize tcp WHERE tcp.contest_id=c.id) as points, (select count(contest_id) FROM tbl_contest_prize tcp WHERE tcp.contest_id=c.id) as top_users,(SELECT COUNT(*) from tbl_contest_leaderboard tcl WHERE tcl.contest_id=c.id ) as participants FROM tbl_contest c WHERE id IN ($live_type_ids) and id NOT IN ($past_type_ids) AND status='1' ORDER BY `id` DESC";
                    $live_result = $this->db->query($sql)->result_array();

                    $result = array();

                    if (!empty($live_result)) {
                        foreach ($live_result as $quiz) {
                            $quiz['image'] = (!empty($quiz['image'])) ? base_url() . CONTEST_IMG_PATH . $quiz['image'] : '';
                            $quiz['start_date'] = date("d-M", strtotime($quiz['start_date']));
                            $quiz['end_date'] = date("d-M", strtotime($quiz['end_date']));

                            $points = $this->db->query("SELECT top_winner, points FROM tbl_contest_prize WHERE contest_id=" . $quiz['id'])->result_array();
                            $quiz['points'] = $points;
                            $result[] = $quiz;
                        }
                        $live_result = $result;
                        $response['live_contest']['error'] = false;
                        $response['live_contest']['message'] = "118";
                        $response['live_contest']['data'] = (!empty($live_result)) ? $live_result : '';
                    } else {
                        $response['live_contest']['error'] = true;
                        $response['live_contest']['message'] = "115";
                    }
                } else {
                    if ($language_id) {
                        $past_result = $this->db->query("SELECT c.*, (select SUM(points) FROM tbl_contest_prize tcp WHERE tcp.contest_id=c.id) as points, (select count(contest_id) FROM tbl_contest_prize tcp WHERE tcp.contest_id=c.id) as top_users,(SELECT COUNT(*) from tbl_contest_leaderboard tcl where tcl.contest_id=c.id ) as participants FROM tbl_contest_leaderboard as l, tbl_contest as c WHERE l.user_id='$user_id' and l.contest_id=c.id and c.language_id = $language_id AND c.contest_type != 'daily' ORDER BY c.id DESC")->result_array();
                    } else {
                        $past_result = $this->db->query("SELECT c.*, (select SUM(points) FROM tbl_contest_prize tcp WHERE tcp.contest_id=c.id) as points, (select count(contest_id) FROM tbl_contest_prize tcp WHERE tcp.contest_id=c.id) as top_users,(SELECT COUNT(*) from tbl_contest_leaderboard tcl where tcl.contest_id=c.id ) as participants FROM tbl_contest_leaderboard as l, tbl_contest as c WHERE l.user_id='$user_id' and l.contest_id=c.id AND c.contest_type != 'daily' ORDER BY c.id DESC")->result_array();
                    }
                    if (!empty($past_result)) {
                        foreach ($past_result as $quiz) {
                            $quiz['image'] = (!empty($quiz['image'])) ? base_url() . CONTEST_IMG_PATH . $quiz['image'] : '';
                            $quiz['start_date'] = date("d-M", strtotime($quiz['start_date']));
                            $quiz['end_date'] = date("d-M", strtotime($quiz['end_date']));

                            $points = $this->db->query("SELECT top_winner, points FROM tbl_contest_prize WHERE contest_id=" . $quiz['id'])->result_array();
                            $quiz['points'] = $points;
                            $result[] = $quiz;
                        }
                        $past_result = $result;
                        $response['past_contest']['error'] = false;
                        $response['past_contest']['message'] = "117";
                        $response['past_contest']['data'] = (!empty($past_result)) ? $past_result : '';
                    } else {
                        $response['past_contest']['error'] = true;
                        $response['past_contest']['message'] = "116";
                    }
                    $response['live_contest']['error'] = true;
                    $response['live_contest']['message'] = "115";
                }

                /* selecting upcoming quiz ids (excluding daily contests) */
                if ($language_id) {
                    $result = $this->db->query("SELECT id FROM tbl_contest where language_id = $language_id AND contest_type != 'daily' and ((start_date) > '$this->toContestDateTime')")->result_array();
                } else {
                    $result = $this->db->query("SELECT id FROM tbl_contest where contest_type != 'daily' and (CAST(start_date AS DATE) > '$this->toDate')")->result_array();
                }
                $upcoming_type_ids = '';
                if (!empty($result)) {

                    foreach ($result as $type_id) {
                        $upcoming_type_ids .= $type_id['id'] . ', ';
                    }
                    $upcoming_type_ids = rtrim($upcoming_type_ids, ', ');

                    /* getting all quiz details by ids retrieved */
                    $upcoming_result = $this->db->query("SELECT c.*, (select SUM(points) FROM tbl_contest_prize tcp WHERE tcp.contest_id=c.id) as points, (select count(contest_id) FROM tbl_contest_prize tcp WHERE tcp.contest_id=c.id) as top_users FROM tbl_contest c WHERE id IN ($upcoming_type_ids) ORDER BY id DESC")->result_array();
                    $result = array();
                    if (!empty($upcoming_result)) {
                        foreach ($upcoming_result as $quiz) {
                            $quiz['image'] = (!empty($quiz['image'])) ? base_url() . CONTEST_IMG_PATH . $quiz['image'] : '';
                            $quiz['start_date'] = date("d-M", strtotime($quiz['start_date']));
                            $quiz['end_date'] = date("d-M", strtotime($quiz['end_date']));

                            $points = $this->db->query("SELECT top_winner, points FROM tbl_contest_prize WHERE contest_id=" . $quiz['id'])->result_array();
                            $quiz['points'] = $points;
                            $quiz['participants'] = "";
                            $result[] = $quiz;
                        }
                        $upcoming_result = $result;
                    }
                    $response['upcoming_contest']['error'] = false;
                    $response['upcoming_contest']['message'] = "118";
                    $response['upcoming_contest']['data'] = (!empty($upcoming_result)) ? $upcoming_result : '';
                } else {
                    $response['upcoming_contest']['error'] = true;
                    $response['upcoming_contest']['message'] = "114";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_questions_by_contest_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            if ($this->post('contest_id')) {
                $contest_id = $this->post('contest_id');
                $data = $this->db->where('contest_id', $contest_id)->order_by($this->Order_By)->get('tbl_contest_question')->result_array();
                if (!empty($data)) {
                    $questionData = [];
                    for ($i = 0; $i < count($data); $i++) {
                        $data[$i]['image'] = ($data[$i]['image']) ? base_url() . CONTEST_QUESTION_IMG_PATH . $data[$i]['image'] : '';
                        $optionData = $this->suffleOptions($data[$i], $firebase_id);
                        $data[$i] = $optionData;
                        $questionData[] = [
                            'id' => $data[$i]['id'],
                            'answer' => $data[$i]['session_answer'],
                        ];
                        unset($data[$i]['session_answer']);
                    }
                    if ($questionData) {
                        $questionData[0]['contest_id'] = $contest_id;
                        $this->set_user_session($user_id, $questionData, 'tbl_user_contest_session');
                    }
                    $response['error'] = false;
                    $response['data'] = $data;
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }


        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_contest_leaderboard_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            if ($this->post('contest_id')) {
                $contest_id = $this->post('contest_id');
                $offset = ($this->post('offset') && is_numeric($this->post('offset'))) ? $this->post('offset') : 0;
                $limit = ($this->post('limit') && is_numeric($this->post('limit'))) ? $this->post('limit') : 25;

                $sort = 'r.user_rank';
                $order = 'ASC';

                $sub_query = "SELECT s.*, @user_rank := @user_rank + 1 user_rank FROM ( SELECT c.*,u.name,u.profile FROM tbl_contest_leaderboard c join tbl_users u on u.id = c.user_id where u.status=1 AND contest_id='" . $contest_id . "') s, (SELECT @user_rank := 0) init ORDER BY score DESC,last_updated ASC";

                $this->db->select('r.*');
                $this->db->from("($sub_query) r");
                $this->db->where('contest_id', $contest_id);

                $total = $this->db->count_all_results('', false);
                $this->db->order_by($sort, $order);
                if ($limit) {
                    $this->db->limit($limit, $offset);
                }
                $other_user_rank_sql = $this->db->get();
                $res = $other_user_rank_sql->result_array();

                $response['total'] = $total;
                for ($i = 0; $i < count($res); $i++) {
                    if (filter_var($res[$i]['profile'], FILTER_VALIDATE_URL) === false) {
                        // Not a valid URL. Its a image only or empty
                        $res[$i]['profile'] = (!empty($res[$i]['profile'])) ? base_url() . USER_IMG_PATH . $res[$i]['profile'] : '';
                    }
                }
                if ($user_id) {
                    $this->db->reset_query();
                    $this->db->from("($sub_query) r");
                    $this->db->where('contest_id', $contest_id);
                    $this->db->where('r.user_id', $user_id);
                    $this->db->select('r.*');
                    $this->db->limit(1);
                    $my_rank_sql = $this->db->get();
                    $my_rank = $my_rank_sql->row_array();

                    if (!empty($my_rank)) {
                        if (filter_var($my_rank['profile'], FILTER_VALIDATE_URL) === false) {
                            // Not a valid URL. Its a image only or empty
                            $my_rank['profile'] = (!empty($my_rank['profile'])) ? base_url() . USER_IMG_PATH . $my_rank['profile'] : '';
                        }
                        $response['my_rank'] = $my_rank;
                    }
                }
                if (empty($res)) {
                    $response['error'] = true;
                    $response['message'] = "102";
                } else {
                    $response['error'] = false;
                    $response['data'] = $res;

                    $this->db->reset_query();
                    $this->db->from("($sub_query) r");
                    $this->db->where('contest_id', $contest_id);
                    $this->db->select('r.*');
                    $this->db->order_by($sort, $order);
                    $this->db->limit(3);
                    $topThree_rank_sql = $this->db->get();
                    $topThreeUsersdata = $topThree_rank_sql->result_array();

                    for ($i = 0; $i < count($topThreeUsersdata); $i++) {
                        if (filter_var($topThreeUsersdata[$i]['profile'], FILTER_VALIDATE_URL) === false) {
                            // Not a valid URL. Its a image only or empty
                            $topThreeUsersdata[$i]['profile'] = (!empty($topThreeUsersdata[$i]['profile'])) ? base_url() . USER_IMG_PATH . $topThreeUsersdata[$i]['profile'] : '';
                        }
                    }
                    $response['top_three_ranks'] = $topThreeUsersdata;
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }


        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * ============================================
     * DAILY CONTEST API ENDPOINTS
     * ============================================
     * Daily Contest is based on today's Rhapsody content
     * Points: 5 (reading) + 5 (quiz - 5 questions) = 10 max
     */

    /**
     * Check if user has completed today's daily contest
     * Returns: { has_pending_contest: bool, contest_id: int|null, date: string }
     */
    public function get_daily_contest_status_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            // Use Montreal timezone for date comparisons
            $tz = getenv('TZ') ?: 'America/Montreal';
            date_default_timezone_set($tz);
            
            $now = date('Y-m-d H:i:s');
            $today = date('Y-m-d');
            
            // First, mark any expired daily contests as completed for users who didn't participate
            // Find expired daily contests (end_date < now) that user hasn't participated in
            $expired_contests = $this->db->select('c.id')
                ->from('tbl_contest c')
                ->where('c.contest_type', 'daily')
                ->where('c.status', 1)
                ->where('c.end_date <', $now)
                ->get()
                ->result_array();
            
            foreach ($expired_contests as $expired) {
                // Check if user participated
                $participated = $this->db->where('contest_id', $expired['id'])
                    ->where('user_id', $user_id)
                    ->get('tbl_contest_leaderboard')
                    ->row_array();
                
                // If not participated, mark as expired (0 points)
                if (empty($participated)) {
                    $this->db->insert('tbl_contest_leaderboard', [
                        'contest_id' => $expired['id'],
                        'user_id' => $user_id,
                        'score' => 0,
                        'last_updated' => date('Y-m-d H:i:s'),
                    ]);
                }
            }
            
            // Check if there's a daily contest for today that hasn't expired yet
            $daily_contest = $this->db->select('id, name, start_date, end_date, rhapsody_category_id')
                ->where('DATE(start_date)', $today)
                ->where('contest_type', 'daily')
                ->where('status', 1)
                ->where('end_date >=', $now)
                ->get('tbl_contest')
                ->row_array();

            if (empty($daily_contest)) {
                // No active daily contest exists for today
                $response['error'] = false;
                $response['has_pending_contest'] = false;
                $response['contest_id'] = null;
                $response['message'] = 'No daily contest available today';
            } else {
                // Check if user has already participated
                $user_participation = $this->db->where('contest_id', $daily_contest['id'])
                    ->where('user_id', $user_id)
                    ->get('tbl_contest_leaderboard')
                    ->row_array();

                $has_completed = !empty($user_participation);
                
                $response['error'] = false;
                $response['has_pending_contest'] = !$has_completed;
                $response['has_completed'] = $has_completed;
                $response['contest_id'] = $daily_contest['id'];
                $response['contest_name'] = $daily_contest['name'];
                $response['start_date'] = $daily_contest['start_date'];
                $response['end_date'] = $daily_contest['end_date'];
                $response['date'] = $today;
                
                if ($has_completed) {
                    $response['user_score'] = $user_participation['score'];
                    $response['message'] = 'Daily contest already completed';
                } else {
                    $response['message'] = 'Daily contest pending';
                }
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Get today's daily contest details
     * Includes Rhapsody text and questions (5 questions)
     */
    public function get_today_daily_contest_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            // Use Montreal timezone for date comparisons
            $tz = getenv('TZ') ?: 'America/Montreal';
            date_default_timezone_set($tz);
            
            $today = date('Y-m-d');
            $now = date('Y-m-d H:i:s');
            
            // Get today's daily contest that hasn't expired yet
            $daily_contest = $this->db->select('c.*, cat.category_name, cat.image as category_image')
                ->from('tbl_contest c')
                ->join('tbl_category cat', 'cat.id = c.rhapsody_category_id', 'left')
                ->where('DATE(c.start_date)', $today)
                ->where('c.contest_type', 'daily')
                ->where('c.status', 1)
                ->where('c.end_date >=', $now)
                ->get()
                ->row_array();

            if (empty($daily_contest)) {
                $response['error'] = true;
                $response['message'] = 'No daily contest available today or contest has expired';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            // Check if user already participated
            $user_participation = $this->db->where('contest_id', $daily_contest['id'])
                ->where('user_id', $user_id)
                ->get('tbl_contest_leaderboard')
                ->row_array();

            if (!empty($user_participation)) {
                $response['error'] = true;
                $response['already_completed'] = true;
                $response['user_score'] = $user_participation['score'];
                $response['message'] = 'You have already completed today\'s contest';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            // Get Rhapsody content from the linked category
            $rhapsody_content = '';
            $rhapsody_verse = '';
            $rhapsody_prayer = '';
            $scripture_ref = '';
            $further_study = '';
            if ($daily_contest['rhapsody_category_id']) {
                $category = $this->db->where('id', $daily_contest['rhapsody_category_id'])
                    ->get('tbl_category')
                    ->row_array();
                if ($category) {
                    $rhapsody_verse = $category['daily_text'] ?? '';
                    $rhapsody_content = $category['content_text'] ?? '';
                    $rhapsody_prayer = $category['prayer_text'] ?? '';
                    $scripture_ref = $category['scripture_ref'] ?? '';
                    $further_study = $category['further_study'] ?? '';
                }
            }

            // Get 5 questions for this contest
            $questions = $this->db->select('q.*')
                ->from('tbl_contest_question q')
                ->where('q.contest_id', $daily_contest['id'])
                ->order_by('RAND()')
                ->limit(5)
                ->get()
                ->result_array();

            // Format questions
            for ($i = 0; $i < count($questions); $i++) {
                if (!empty($questions[$i]['image']) && filter_var($questions[$i]['image'], FILTER_VALIDATE_URL) === false) {
                    $questions[$i]['image'] = base_url() . CONTEST_QUESTION_IMG_PATH . $questions[$i]['image'];
                }
            }

            $response['error'] = false;
            $response['data'] = [
                'contest_id' => $daily_contest['id'],
                'name' => $daily_contest['name'],
                'description' => $daily_contest['description'],
                'date' => $today,
                'scripture_ref' => $scripture_ref,
                'rhapsody_verse' => $rhapsody_verse,
                'rhapsody_text' => $rhapsody_content,
                'rhapsody_prayer' => $rhapsody_prayer,
                'further_study' => $further_study,
                'reading_points' => 5,
                'quiz_points_per_question' => 1,
                'total_questions' => count($questions),
                'questions' => $questions
            ];
            $response['message'] = 'Daily contest loaded successfully';

        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Submit daily contest answers
     * Awards: 5 points for reading + 1 point per correct answer (max 5)
     */
    public function submit_daily_contest_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            // Use Montreal timezone for date comparisons
            $tz = getenv('TZ') ?: 'America/Montreal';
            date_default_timezone_set($tz);

            $contest_id = $this->post('contest_id');
            $answers = $this->post('answers'); // Array of {question_id, answer}
            $read_text = $this->post('read_text'); // Boolean - did user read the text

            if (!$contest_id) {
                $response['error'] = true;
                $response['message'] = 'Contest ID is required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            // Check if contest exists and is daily type
            $contest = $this->db->where('id', $contest_id)
                ->where('contest_type', 'daily')
                ->where('status', 1)
                ->get('tbl_contest')
                ->row_array();

            if (empty($contest)) {
                $response['error'] = true;
                $response['message'] = 'Invalid contest';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }
            
            // Check if contest has expired
            $now = date('Y-m-d H:i:s');
            if ($contest['end_date'] < $now) {
                // Contest expired - mark as completed with 0 points
                $this->db->insert('tbl_contest_leaderboard', [
                    'contest_id' => $contest_id,
                    'user_id' => $user_id,
                    'score' => 0,
                    'last_updated' => date('Y-m-d H:i:s'),
                ]);
                
                $response['error'] = true;
                $response['expired'] = true;
                $response['message'] = 'This contest has expired';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            // Check if user already participated
            $existing = $this->db->where('contest_id', $contest_id)
                ->where('user_id', $user_id)
                ->get('tbl_contest_leaderboard')
                ->row_array();

            if (!empty($existing)) {
                $response['error'] = true;
                $response['message'] = 'You have already completed this contest';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            // Calculate score
            $reading_points = ($read_text == '1' || $read_text === true) ? 5 : 0;
            $quiz_points = 0;
            $correct_answers = 0;

            if (!empty($answers) && is_array($answers)) {
                foreach ($answers as $answer) {
                    $question_id = $answer['question_id'];
                    $user_answer = $answer['answer'];

                    // Get correct answer
                    $question = $this->db->select('answer')
                        ->where('id', $question_id)
                        ->get('tbl_contest_question')
                        ->row_array();

                    if ($question && strtolower(trim($question['answer'])) == strtolower(trim($user_answer))) {
                        $quiz_points += 1;
                        $correct_answers++;
                    }
                }
            }

            $total_score = $reading_points + $quiz_points;

            // Save to leaderboard
            $leaderboard_data = [
                'contest_id' => $contest_id,
                'user_id' => $user_id,
                'score' => $total_score,
                'last_updated' => date('Y-m-d H:i:s')
            ];
            $this->db->insert('tbl_contest_leaderboard', $leaderboard_data);

            // Update daily leaderboard for ranking
            $this->set_daily_leaderboard($user_id, $total_score);

            $response['error'] = false;
            $response['data'] = [
                'reading_points' => $reading_points,
                'quiz_points' => $quiz_points,
                'correct_answers' => $correct_answers,
                'total_questions' => count($answers),
                'total_score' => $total_score,
                'max_score' => 10
            ];
            $response['message'] = 'Contest submitted successfully';

        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Create daily contest from today's Rhapsody (for testing/manual trigger)
     * In production, this is called by cron at 00:00 AM
     * ENV: DAILY_CONTEST_AUTO_CREATE controls automatic creation
     */
    public function create_daily_contest_post()
    {
        try {
            // This endpoint can be restricted to admin in production
            $is_user = $this->verify_token();
            if ($is_user['error']) {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            $today = date('Y-m-d');
            $now = new DateTime();
            $day = $now->format('j');
            $month = $now->format('n');
            $year = $now->format('Y');
            $month_name = $now->format('F');

            // Check if daily contest already exists for today
            $existing = $this->db->where('DATE(start_date)', $today)
                ->where('contest_type', 'daily')
                ->get('tbl_contest')
                ->row_array();

            if (!empty($existing)) {
                $response['error'] = false;
                $response['message'] = 'Daily contest already exists for today';
                $response['contest_id'] = $existing['id'];
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            // Find today's Rhapsody category (Year -> Month -> Day structure)
            // First find the Rhapsody topic
            $rhapsody_topic = $this->db->where('topic_type', 'rhapsody')
                ->where('status', 1)
                ->get('tbl_topics')
                ->row_array();

            if (empty($rhapsody_topic)) {
                $response['error'] = true;
                $response['message'] = 'Rhapsody topic not found';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            // Find the day category for today's date
            // Category structure: Year (2025) -> Month (January) -> Day (1, 2, 3...)
            $day_category = $this->db->select('c.*')
                ->from('tbl_category c')
                ->where('c.topic_id', $rhapsody_topic['id'])
                ->where('c.rhapsody_day', $day)
                ->where('c.rhapsody_month', $month)
                ->where('c.rhapsody_year', $year)
                ->where('c.status', 1)
                ->get()
                ->row_array();

            if (empty($day_category)) {
                $response['error'] = true;
                $response['message'] = "No Rhapsody content found for $month_name $day, $year";
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            // Get questions from this category (random 5)
            $questions = $this->db->where('category', $day_category['id'])
                ->order_by('RAND()')
                ->limit(5)
                ->get('tbl_question')
                ->result_array();

            if (count($questions) < 5) {
                $response['error'] = true;
                $response['message'] = 'Not enough questions for daily contest (need 5, found ' . count($questions) . ')';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            // Create the daily contest
            $contest_data = [
                'language_id' => $day_category['language_id'] ?? 14,
                'name' => "Daily Rhapsody - $month_name $day, $year",
                'description' => 'Complete today\'s Rhapsody quiz to earn ranking points!',
                'start_date' => $today . ' 00:00:00',
                'end_date' => $today . ' 23:59:59',
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

            // Copy questions to contest_question table
            foreach ($questions as $q) {
                $contest_question = [
                    'contest_id' => $contest_id,
                    'langauge_id' => $q['language_id'] ?? 14,
                    'image' => $q['image'] ?? '',
                    'question' => $q['question'],
                    'question_type' => $q['question_type'] ?? 1,
                    'optiona' => $q['optiona'],
                    'optionb' => $q['optionb'],
                    'optionc' => $q['optionc'],
                    'optiond' => $q['optiond'],
                    'optione' => $q['optione'] ?? '',
                    'answer' => $q['answer'],
                    'note' => $q['note'] ?? '',
                    'date_created' => date('Y-m-d H:i:s')
                ];
                $this->db->insert('tbl_contest_question', $contest_question);
            }

            $response['error'] = false;
            $response['message'] = 'Daily contest created successfully';
            $response['data'] = [
                'contest_id' => $contest_id,
                'name' => $contest_data['name'],
                'questions_count' => count($questions),
                'rhapsody_category' => $day_category['category_name']
            ];

        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Get random questions from Rhapsody topic for battle mode
     * @param int $limit Number of questions to fetch
     * @param int $language_id Optional language filter
     * @return array Questions
     */
    private function _get_rhapsody_questions_for_battle($limit, $language_id = 0)
    {
        // Get Rhapsody topic ID
        $topic = $this->db->where('slug', 'rhapsody')->get('tbl_topic')->row_array();
        if (empty($topic)) {
            return [];
        }

        // Get all category IDs for this topic (type = day for actual content)
        $categories = $this->db->select('id')
            ->where('topic_id', $topic['id'])
            ->where('category_type', 'day')
            ->get('tbl_category')
            ->result_array();
        
        if (empty($categories)) {
            return [];
        }

        $category_ids = array_column($categories, 'id');

        // Get random questions from these categories
        $this->db->where_in('category', $category_ids);
        if (!empty($language_id)) {
            $this->db->where('language_id', $language_id);
        }
        $this->db->order_by('RAND()')->limit($limit);
        return $this->db->get('tbl_question')->result_array();
    }

    /**
     * Get random questions from Foundation School topic for battle mode
     * @param int $limit Number of questions to fetch
     * @param int $language_id Optional language filter
     * @return array Questions
     */
    private function _get_foundation_questions_for_battle($limit, $language_id = 0)
    {
        log_message('debug', "_get_foundation_questions_for_battle: limit=$limit, language_id=$language_id");
        
        // Get Foundation School topic ID
        $topic = $this->db->where('slug', 'foundation_school')->get('tbl_topic')->row_array();
        log_message('debug', "_get_foundation_questions_for_battle: topic=" . json_encode($topic));
        
        if (empty($topic)) {
            log_message('error', "_get_foundation_questions_for_battle: No foundation_school topic found");
            return [];
        }

        // Get all category IDs for this topic (modules)
        $categories = $this->db->select('id')
            ->where('topic_id', $topic['id'])
            ->get('tbl_category')
            ->result_array();
        
        log_message('debug', "_get_foundation_questions_for_battle: categories count=" . count($categories));
        
        if (empty($categories)) {
            log_message('error', "_get_foundation_questions_for_battle: No categories found for topic_id=" . $topic['id']);
            return [];
        }

        $category_ids = array_column($categories, 'id');
        log_message('debug', "_get_foundation_questions_for_battle: category_ids=" . json_encode($category_ids));

        // Get random questions from these categories
        // Foundation questions may have language_id = 0, so also include those
        $this->db->where_in('category', $category_ids);
        if (!empty($language_id)) {
            // Include questions with the specified language OR language_id = 0 (universal)
            $this->db->group_start();
            $this->db->where('language_id', $language_id);
            $this->db->or_where('language_id', 0);
            $this->db->group_end();
        }
        $this->db->order_by('RAND()')->limit($limit);
        $result = $this->db->get('tbl_question')->result_array();
        
        log_message('debug', "_get_foundation_questions_for_battle: found " . count($result) . " questions");
        
        return $result;
    }

    /**
     * @deprecated No longer used. Leaderboard now uses tbl_contest_leaderboard exclusively.
     * Kept for backward compatibility - does nothing.
     */
    private function set_daily_leaderboard($user_id, $score)
    {
        // DEPRECATED: Leaderboard now uses tbl_contest_leaderboard exclusively
        // This function is kept for backward compatibility but does nothing
        return;
    }

    /**
     * ============================================
     * END DAILY CONTEST API ENDPOINTS
     * ============================================
     */

    public function get_fun_n_learn_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }
            if ($this->post('type') && $this->post('type_id') && $user_id) {
                $type = $this->post('type');
                $type_id = $this->post('type_id');
                $this->db->select('c.*,cat.category_name as category_name,subcat.subcategory_name as subcategory_name, (select count(id) from tbl_fun_n_learn_question q where q.fun_n_learn_id=c.id ) as no_of_que');
                if ($this->post('id')) {
                    $id = $this->post('id');
                    $this->db->where('id', $id);
                }
                if ($this->post('language_id')) {
                    $language_id = $this->post('language_id');
                    $this->db->where('c.language_id', $language_id);
                }
                $this->db->join('tbl_category cat', 'cat.id=c.category', 'left');
                $this->db->join('tbl_subcategory subcat', 'subcat.id=c.subcategory', 'left');
                $this->db->where($type, $type_id);
                $this->db->where('c.status', 1);
                $this->db->order_by('id', 'DESC');
                $data = $this->db->get('tbl_fun_n_learn c')->result_array();
                if (!empty($data)) {
                    for ($i = 0; $i < count($data); $i++) {
                        //check if category played or not
                        if ($data[$i]['content_data'] != '' && $data[$i]['content_type'] == 2) {
                            $data[$i]['content_data'] = base_url(FUN_LEARN_IMG_PATH . $data[$i]['content_data']);
                        } else if ($data[$i]['content_type'] == 0) {
                            $data[$i]['content_data'] = '';
                        }
                        $res = $this->db->where('type_id', $data[$i]['id'])->where('subcategory', $data[$i]['subcategory'])->where('category', $data[$i]['category'])->where('user_id', $user_id)->get('tbl_quiz_categories')->row_array();
                        $data[$i]['is_play'] = (!empty($res)) ? '1' : '0';
                    }
                    $response['error'] = false;
                    $response['data'] = $data;
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_fun_n_learn_questions_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            if ($this->post('fun_n_learn_id')) {
                $optionEMode = is_option_e_mode_enabled();
                $fun_n_learn_id = $this->post('fun_n_learn_id');
                $fix_question = is_settings('fun_n_learn_quiz_fix_question');
                $limit = is_settings('fun_n_learn_quiz_total_question');

                $this->db->select('q.*, tf.category, tf.subcategory');
                $this->db->join('tbl_fun_n_learn tf', 'tf.id=q.fun_n_learn_id');
                if (!$optionEMode) {
                    $this->db->where('answer !=', 'e');
                }
                $this->db->where('fun_n_learn_id', $fun_n_learn_id);
                $this->db->order_by($this->Order_By);

                if ($fix_question == 1 && $limit) {
                    $this->db->limit($limit, 0);
                }

                $data = $this->db->get('tbl_fun_n_learn_question q')->result_array();
                $questionData = [];
                if (!empty($data)) {

                    for ($i = 0; $i < count($data); $i++) {
                        $data[$i]['image'] = ($data[$i]['image']) ? base_url() . FUN_LEARN_QUESTION_IMG_PATH . $data[$i]['image'] : '';
                        $optionData = $this->suffleOptions($data[$i], $firebase_id);
                        $data[$i] = $optionData;
                        $questionData[] = [
                            'id' => $data[$i]['id'],
                            'answer' => $data[$i]['session_answer'],
                        ];
                        unset($data[$i]['session_answer']);
                    }
                    if ($questionData) {
                        $questionData[0]['fun_n_learn_id'] = $fun_n_learn_id;
                        $this->set_user_session($user_id, $questionData, 'tbl_user_fun_n_learn_session');
                    }
                    $response['error'] = false;
                    $response['data'] = $data;
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_users_statistics_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            if ($user_id) {
                $result = $this->db->query("SELECT us.*,u.name,u.profile,(SELECT category_name FROM tbl_category c WHERE c.id=us.strong_category) as strong_category, (SELECT category_name FROM tbl_category c WHERE c.id=us.weak_category) as weak_category FROM tbl_users_statistics us LEFT JOIN tbl_users u on u.id = us.user_id WHERE user_id=$user_id")->result_array();

                if (!empty($result)) {
                    if ($result[0]['strong_category'] == null) {
                        $result[0]['strong_category'] = "0";
                    }
                    if ($result[0]['weak_category'] == null) {
                        $result[0]['weak_category'] = "0";
                    }
                    if ($result[0]['questions_answered'] == null) {
                        $result[0]['questions_answered'] = "0";
                    }
                    if ($result[0]['correct_answers'] == null) {
                        $result[0]['correct_answers'] = "0";
                    }
                    if ($result[0]['strong_category'] == null) {
                        $result[0]['strong_category'] = "0";
                    }
                    if ($result[0]['best_position'] == null) {
                        $result[0]['best_position'] = "0";
                    }
                    if (filter_var($result[0]['profile'], FILTER_VALIDATE_URL) === false) {
                        // Not a valid URL. Its a image only or empty
                        $result[0]['profile'] = (!empty($result[0]['profile'])) ? base_url() . USER_IMG_PATH . $result[0]['profile'] : '';
                    }
                    $response['error'] = false;
                    $response['data'] = $result[0];
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_system_configurations_post()
    {
        try {
            $setting = [
                'system_timezone',
                'system_timezone_gmt',
                'app_link',
                'ios_app_link',
                'refer_coin',
                'earn_coin',
                'reward_coin',
                'app_version',
                'app_version_ios',
                'shareapp_text',
                'language_mode',
                'force_update',
                'daily_quiz_mode',
                'in_app_purchase_mode',
                'in_app_ads_mode',
                'ads_type',
                'android_banner_id',
                'android_interstitial_id',
                'android_rewarded_id',
                'ios_banner_id',
                'ios_interstitial_id',
                'ios_rewarded_id',
                'android_game_id',
                'ios_game_id',
                'app_key_android_iron_source',
                'app_key_ios_iron_source',
                'rewarded_id_android_iron_source',
                'rewarded_id_ios_iron_source',
                'interstitial_id_android_iron_source',
                'interstitial_id_ios_iron_source',
                'banner_id_android_iron_source',
                'banner_id_ios_iron_source',
                'payment_mode',
                'per_coin',
                'coin_amount',
                'currency_symbol',
                'coin_limit',
                'app_maintenance',
                'bot_image',
                'daily_ads_visibility',
                'daily_ads_coins',
                'daily_ads_counter',
                // 'maximum_winning_coins',
                // 'minimum_coins_winning_percentage',
                'quiz_winning_percentage',
                'score',
                'answer_mode',
                'review_answers_deduct_coin',
                'quiz_zone_mode',
                'quiz_zone_duration',
                'quiz_zone_lifeline_deduct_coin',
                // 'quiz_zone_wrong_answer_deduct_score',
                // 'quiz_zone_correct_answer_credit_score',
                'guess_the_word_question',
                'guess_the_word_seconds',
                'guess_the_word_max_hints',
                // 'guess_the_word_max_winning_coin',
                // 'guess_the_word_wrong_answer_deduct_score',
                // 'guess_the_word_correct_answer_credit_score',
                'guess_the_word_hint_deduct_coin',
                'audio_mode_question',
                'audio_quiz_seconds',
                // 'audio_quiz_wrong_answer_deduct_score',
                // 'audio_quiz_correct_answer_credit_score',
                'maths_quiz_mode',
                'maths_quiz_seconds',
                // 'maths_quiz_wrong_answer_deduct_score',
                // 'maths_quiz_correct_answer_credit_score',
                'fun_n_learn_question',
                'fun_and_learn_time_in_seconds',
                // 'fun_n_learn_quiz_wrong_answer_deduct_score',
                // 'fun_n_learn_quiz_correct_answer_credit_score',
                'true_false_mode',
                'true_false_quiz_in_seconds',
                // 'true_false_quiz_wrong_answer_deduct_score',
                // 'true_false_quiz_correct_answer_credit_score',
                'battle_mode_one',
                'battle_mode_one_category',
                'battle_mode_one_in_seconds',
                // 'battle_mode_one_correct_answer_credit_score',
                // 'battle_mode_one_quickest_correct_answer_extra_score',
                // 'battle_mode_one_second_quickest_correct_answer_extra_score',
                'battle_mode_one_code_char',
                'battle_mode_one_entry_coin',
                'battle_mode_group',
                'battle_mode_group_category',
                'battle_mode_group_in_seconds',
                'battle_mode_group_wrong_answer_deduct_score',
                'battle_mode_group_correct_answer_credit_score',
                'battle_mode_group_quickest_correct_answer_extra_score',
                'battle_mode_group_second_quickest_correct_answer_extra_score',
                'battle_mode_group_code_char',
                'battle_mode_group_entry_coin',
                'battle_mode_random',
                'battle_mode_random_category',
                'battle_mode_random_in_seconds',
                // 'battle_mode_random_correct_answer_credit_score',
                // 'battle_mode_random_quickest_correct_answer_extra_score',
                // 'battle_mode_random_second_quickest_correct_answer_extra_score',
                'battle_mode_random_search_duration',
                'battle_mode_random_entry_coin',
                'self_challenge_mode',
                'self_challenge_max_minutes',
                'self_challenge_max_questions',
                'exam_module',
                'exam_module_resume_exam_timeout',
                'contest_mode',
                // 'contest_mode_wrong_deduct_score',
                // 'contest_mode_correct_credit_score',
                'multi_match_mode',
                'multi_match_fix_level_question',
                'multi_match_total_level_question',
                'multi_match_duration',
                // 'multi_match_wrong_answer_deduct_score',
                // 'multi_match_correct_answer_credit_score',
                'latex_mode',
                'exam_latex_mode',
                'gmail_login',
                'email_login',
                'phone_login',
                'apple_login'
            ];
            foreach ($setting as $row) {
                $data = $this->db->where('type', $row)->get('tbl_settings')->row_array();
                if ($row == 'bot_image') {
                    $res[$row] = ($data) ? base_url() . LOGO_IMG_PATH . $data['message'] : base_url() . LOGO_IMG_PATH . 'bot-stock.png';
                } else {
                    $res[$row] = ($data) ? $data['message'] : '';
                }
            }
            if (!empty($res)) {
                $response['error'] = false;
                $response['data'] = $res;
            } else {
                $response['error'] = true;
                $response['message'] = "102";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_coin_store_data_post()
    {
        try {
            $data = $this->db->where('status', 1)->order_by('id', 'asc')->get('tbl_coin_store')->result_array();
            for ($i = 0; $i < count($data); $i++) {
                $data[$i]['image'] = ($data[$i]['image']) ? base_url() . COIN_STORE_IMG_PATH . $data[$i]['image'] :  $this->NO_IMAGE;
            }
            if (!empty($data)) {
                $response['error'] = false;
                $response['data'] = $data;
            } else {
                $response['error'] = true;
                $response['message'] = "102";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_languages_post()
    {
        try {
            if ($this->post('id')) {
                $id = $this->post('id');
                $this->db->where('id', $id);
            }
            $data = $this->db->select('id, language, code, default_active')->where('status', 1)->where('type', 1)->order_by('id', 'ASC')->get('tbl_languages')->result_array();
            if (!empty($data)) {
                $response['error'] = false;
                $response['data'] = $data;
            } else {
                $response['error'] = true;
                $response['message'] = "102";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_guess_the_word_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }
            if ($this->post('type') && $this->post('type_id')) {
                $fix_question = is_settings('guess_the_word_fix_question');
                $limit = is_settings('guess_the_word_total_question');

                $type = $this->post('type');
                $type_id = $this->post('type_id');

                if ($this->post('language_id')) {
                    $language_id = $this->post('language_id');
                    $this->db->where('language_id', $language_id);
                }
                $this->db->where($type, $type_id);
                $this->db->order_by($this->Order_By);

                if ($fix_question == 1) {
                    $this->db->limit($limit, 0);
                }
                $data = $this->db->get('tbl_guess_the_word c')->result_array();
                $questionData = [];
                if (!empty($data)) {
                    for ($i = 0; $i < count($data); $i++) {
                        $data[$i]['image'] = ($data[$i]['image']) ? base_url() . GUESS_WORD_IMG_PATH . $data[$i]['image'] : '';
                        $questionData[] = [
                            'id' => $data[$i]['id'],
                            'answer' => trim($data[$i]['answer']),
                        ];
                        $data[$i]['answer'] = $this->encrypt_data($firebase_id, trim($data[$i]['answer']));
                    }
                    if ($questionData) {
                        $this->set_user_session($user_id, $questionData, 'tbl_user_guess_the_word_session');
                    }
                    $response['error'] = false;
                    $response['data'] = $data;
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_settings_post()
    {
        try {
            if ($this->post('type')) {
                $type = $this->post('type');
                $res = $this->db->where('type', $type)->get('tbl_settings')->row_array();
                if (!empty($res)) {
                    $response['error'] = false;
                    $response['data'] = $res['message'];
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $setting_data = [
                    'about_us',
                    'privacy_policy',
                    'terms_conditions',
                    'contact_us',
                    'instructions',
                    'app_name'
                ];
                $res = $this->db->where('type!=', 'shared_secrets')->where_in('type', $setting_data)->get('tbl_settings')->result_array();
                if (!empty($res)) {
                    $response['error'] = false;
                    $response['data'] = $res;
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function report_question_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            if ($this->post('question_id') && $user_id && $this->post('message')) {
                $frm_data = array(
                    'question_id' => $this->post('question_id'),
                    'user_id' => $user_id,
                    'message' => $this->post('message'),
                    'date' => $this->toDateTime,
                );
                $this->db->insert('tbl_question_reports', $frm_data);
                $response['error'] = false;
                $response['message'] = "109";
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_questions_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            if ($this->post('type') && $this->post('id')) {
                $type = $this->post('type');
                $id = $this->post('id');

                $this->db->where($type, $id);
                $this->db->order_by($this->Order_By);
                $data = $this->db->get('tbl_question')->result_array();
                if (!empty($data)) {
                    $questionData = [];
                    for ($i = 0; $i < count($data); $i++) {
                        $data[$i]['image'] = ($data[$i]['image']) ? base_url() . QUESTION_IMG_PATH . $data[$i]['image'] : '';
                        $data[$i] = $this->suffleOptions($data[$i], $firebase_id);
                        // Store answer for session validation
                        $questionData[] = [
                            'id' => $data[$i]['id'],
                            'answer' => $data[$i]['session_answer'],
                            'category' => $data[$i]['category'],
                            'subcategory' => $data[$i]['subcategory'],
                            'level' => $data[$i]['level'] ?? '0'
                        ];
                        unset($data[$i]['session_answer']);
                    }
                    // Create session for quiz result validation
                    if ($questionData && $user_id) {
                        $this->set_user_session($user_id, $questionData, 'tbl_user_quiz_zone_session');
                    }
                    $response['error'] = false;
                    $response['data'] = $data;
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function update_fcm_id_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            if ($firebase_id) {
                $data = [];
                $fcm_id = $this->post('fcm_id');
                if ($fcm_id) {
                    $data['fcm_id'] = $fcm_id;
                }
                $web_fcm_id = $this->post('web_fcm_id');
                if ($web_fcm_id) {
                    $data['web_fcm_id'] = $web_fcm_id;
                }
                if ($data) {
                    $this->db->where('firebase_id', $firebase_id)->update('tbl_users', $data);
                }
                $response['error'] = false;
                $response['message'] = "111";
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_audio_questions_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }
            if ($this->post('type') && $this->post('type_id')) {
                $type = $this->post('type');
                $id = $this->post('type_id');
                $fix_question = is_settings('audio_quiz_fix_question');
                $limit = is_settings('audio_quiz_total_question');

                $this->db->where($type, $id);
                $this->db->order_by($this->Order_By);

                if ($fix_question == 1) {
                    $this->db->limit($limit, 0);
                }

                $data = $this->db->get('tbl_audio_question')->result_array();
                if (!empty($data)) {
                    $questionData = [];
                    for ($i = 0; $i < count($data); $i++) {
                        if ($data[$i]['audio_type'] != '1') {
                            $path = base_url() . QUESTION_AUDIO_PATH;
                        } else {
                            $path = "";
                        }
                        $data[$i]['audio'] = ($data[$i]['audio']) ? $path . $data[$i]['audio'] : '';
                        $optionData = $this->suffleOptions($data[$i], $firebase_id);
                        $data[$i] = $optionData;
                        $questionData[] = [
                            'id' => $data[$i]['id'],
                            'answer' => $data[$i]['session_answer'],
                        ];
                        unset($data[$i]['session_answer']);
                    }
                    if ($questionData) {
                        $this->set_user_session($user_id, $questionData, 'tbl_user_audio_quiz_session');
                    }
                    $response['error'] = false;
                    $response['data'] = $data;
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_user_badges_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }
            if ($user_id) {
                $res1 = $this->db->select('id')->where('user_id', $user_id)->get('tbl_users_badges')->row_array();
                if ($res1) {
                    $badges = [
                        'dashing_debut',
                        'combat_winner',
                        'clash_winner',
                        'most_wanted_winner',
                        'ultimate_player',
                        'quiz_warrior',
                        'super_sonic',
                        'flashback',
                        'brainiac',
                        'big_thing',
                        'elite',
                        'thirsty',
                        'power_elite',
                        'sharing_caring',
                        'streak',
                    ];
                    // Get the language_id from the post data or default to 14
                    $language_id = $this->post('language_id') ? $this->post('language_id') : 14;
                    foreach ($badges as $key => $row) {
                        $res[$key] = $this->db->where('type', $row)->where('language_id', $language_id)->get('tbl_badges')->row_array();
                        if (empty($res[$key])) {
                            $res[$key] = $this->db->where('type', $row)->where('language_id', 14)->get('tbl_badges')->row_array();
                        }
                        $get_user_language = $this->db->select('id,app_language,web_language')->where('id', $user_id)->get('tbl_users')->row_array();
                        $user_app_language = $get_user_language['app_language'];
                        $user_web_language = $get_user_language['web_language'];

                        $get_app_default_language = $this->db->select('id,name,app_default')->where('app_default', 1)->get('tbl_upload_languages')->row_array();
                        $get_web_default_language = $this->db->select('id,name,web_default')->where('web_default', 1)->get('tbl_upload_languages')->row_array();
                        $default_app_language = $get_app_default_language['name'] ?? '';
                        $default_web_language = $get_web_default_language['name'] ?? '';

                        $app_data = $this->getBadgeNotificationData($user_app_language, $row, APP_LANGUAGE_FILE_PATH, 'app_sample_file.json', $default_app_language);
                        $web_data = $this->getBadgeNotificationData($user_web_language, $row, WEB_LANGUAGE_FILE_PATH, 'web_sample_file.json', $default_web_language);

                        $res[$key]['badge_label'] = $web_data['notification_title'] ?? 'Congratulations!';
                        $res[$key]['badge_note'] = $web_data['notification_body'] ?? 'You have unlocked new badge.';

                        $res[$key]['app_badge_label'] = $app_data['notification_title'] ?? 'Congratulations!';
                        $res[$key]['app_badge_note'] = $app_data['notification_body'] ?? 'You have unlocked new badge.';
                        $res[$key]['badge_icon'] = (isset($res[$key]['badge_icon']) && !empty($res[$key]['badge_icon'])) ? base_url() . BADGE_IMG_PATH . $res[$key]['badge_icon'] : "";
                        $res1 = $this->db->select($row)->where('user_id', $user_id)->get('tbl_users_badges')->row_array();
                        $res[$key]['status'] = $res1[$row];
                    }
                    $response['error'] = false;
                    $response['data'] = $res;
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_battle_statistics_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            if ($user_id) {
                $offset = ($this->post('offset') && is_numeric($this->post('offset'))) ? $this->post('offset') : 0;
                $limit = ($this->post('limit') && is_numeric($this->post('limit'))) ? $this->post('limit') : 5;

                $sort = ($this->post('sort')) ? $this->post('sort') : 'id';
                $order = ($this->post('order')) ? $this->post('order') : 'DESC';

                $result = $this->db->query("SELECT (SELECT COUNT(*) FROM (SELECT DISTINCT date_created from tbl_battle_statistics WHERE winner_id = $user_id)as w ) AS Victories, (SELECT COUNT(*) FROM (SELECT DISTINCT `date_created` from tbl_battle_statistics WHERE (user_id1= $user_id || user_id2= $user_id)AND is_drawn=1)as d) AS Drawn, (SELECT COUNT(*) FROM (SELECT DISTINCT `date_created` from tbl_battle_statistics WHERE (user_id1= $user_id || user_id2= $user_id) AND winner_id != $user_id and is_drawn = 0)as l )AS Loose")->result_array();
                $response['myreport'] = $result;

                $matches = $temp = array();

                $result = $this->db->query("SELECT *, (select name from tbl_users u WHERE u.id = m.user_id1 ) as user_1, (select name from tbl_users u WHERE u.id = m.user_id2 ) as user_2, (select profile from tbl_users u WHERE u.id = m.user_id1 ) as user_profile1, (select profile from tbl_users u WHERE u.id = m.user_id2 ) as user_profile2 FROM tbl_battle_statistics m where user_id1 = $user_id or user_id2 = $user_id GROUP BY DATE(date_created) ORDER BY $sort $order limit $offset,$limit")->result_array();
                if (!empty($result)) {
                    foreach ($result as $row) {
                        $temp['opponent_id'] = ($row['user_id1'] == $user_id) ? $row['user_id2'] : $row['user_id1'];
                        $temp['opponent_name'] = ($row['user_id1'] == $user_id) ? $row['user_2'] : $row['user_1'];
                        $temp['opponent_profile'] = ($row['user_id1'] == $user_id) ? $row['user_profile2'] : $row['user_profile1'];
                        if (!empty($temp['opponent_profile']) || $temp['opponent_profile'] != null) {
                            if (filter_var($temp['opponent_profile'], FILTER_VALIDATE_URL) === false) {
                                // Not a valid URL. Its a image only or empty
                                $temp['opponent_profile'] = (!empty($temp['opponent_profile'])) ? base_url() . USER_IMG_PATH . $temp['opponent_profile'] : '';
                            }
                        }

                        if ($row['is_drawn'] == 1) {
                            $temp['mystatus'] = "Draw";
                        } else {
                            $temp['mystatus'] = ($row['winner_id'] == $user_id) ? "Won" : "Lost";
                        }
                        $temp['date_created'] = $row['date_created'];
                        $matches[] = $temp;
                    }
                    $response['error'] = false;
                    $response['data'] = $matches;
                } else {
                    $response['error'] = false;
                    $response['message'] = "113";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_exam_module_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            if ($user_id && $this->post('type')) {
                $type = $this->post('type');
                $timezone = $this->post('timezone') ? $this->post('timezone') : $this->systemTimezone;
                $today = new DateTime('now', new DateTimeZone($timezone));
                $today_date = $today->format('Y-m-d');
                $gmt_format = $this->post('gmt_format') ? $this->post('gmt_format') : $this->systemTimezoneGMT;

                if ($type == 1 || $type == '1') {
                    $this->db->select('te.*,DATE_FORMAT(CONVERT_TZ(te.date, "+00:00", "' . $gmt_format . '"), "%Y-%m-%d") AS converted_date, (select count(id) from tbl_exam_module_question q where q.exam_module_id=te.id ) as no_of_que, (select SUM(marks) from tbl_exam_module_question q where q.exam_module_id=te.id ) as total_marks');
                    if ($this->post('id')) {
                        $id = $this->post('id');
                        $this->db->where('id', $id);
                    }
                    if ($this->post('language_id')) {
                        $language_id = $this->post('language_id');
                        $this->db->where('language_id', $language_id);
                    }
                    $this->db->where('status', 1);
                    $this->db->where("DATE(CONVERT_TZ(date, '+00:00', '" . $gmt_format . "')) =", $today_date);

                    $this->db->order_by('id', 'DESC');
                    $data = $this->db->get('tbl_exam_module te')->result_array();
                    if (!empty($data)) {
                        for ($i = 0; $i < count($data); $i++) {
                            $res = $this->db->where('user_id', $user_id)->where('exam_module_id', $data[$i]['id'])->get('tbl_exam_module_result')->result_array();
                            $data[$i]['exam_status'] = (empty($res)) ? '1' : $res[0]['status'];
                        }
                        $response['error'] = false;
                        $response['data'] = $data;
                    } else {
                        $response['error'] = true;
                        $response['message'] = "102";
                    }
                } else if ($type == 2 || $type == '2') {
                    $offset = ($this->post('offset') && is_numeric($this->post('offset'))) ? $this->post('offset') : 0;
                    $limit = ($this->post('limit') && is_numeric($this->post('limit'))) ? $this->post('limit') : 10;
                    $this->db->select('te.*, ter.obtained_marks, ter.total_duration, ter.statistics, (select SUM(marks) from tbl_exam_module_question q where q.exam_module_id=te.id ) as total_marks');
                    $this->db->join('tbl_exam_module_result ter', 'ter.exam_module_id=te.id');
                    if ($this->post('language_id')) {
                        $language_id = $this->post('language_id');
                        $this->db->where('language_id', $language_id);
                    }
                    $this->db->where('te.status', 1)->where('ter.user_id', $user_id);
                    $this->db->order_by('id', 'DESC');
                    $this->db->limit($limit, $offset);
                    $data = $this->db->get('tbl_exam_module te')->result_array();
                    if (!empty($data)) {
                        $this->db->select('te.*, ter.obtained_marks, ter.total_duration, ter.statistics, (select SUM(marks) from tbl_exam_module_question q where q.exam_module_id=te.id ) as total_marks');
                        $this->db->join('tbl_exam_module_result ter', 'ter.exam_module_id=te.id');
                        if ($this->post('language_id')) {
                            $language_id = $this->post('language_id');
                            $this->db->where('language_id', $language_id);
                        }
                        $this->db->where('te.status', 1)->where('ter.user_id', $user_id);
                        $data1 = $this->db->get('tbl_exam_module te')->result_array();
                        $total = count($data1);
                        for ($i = 0; $i < count($data); $i++) {
                            $data[$i]['statistics'] = json_decode($data[$i]['statistics'], true);
                        }
                        $response['error'] = false;
                        $response['total'] = "$total";
                        $response['data'] = $data;
                    } else {
                        $response['error'] = true;
                        $response['message'] = "102";
                    }
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_exam_module_questions_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }
            if ($this->post('exam_module_id')) {
                $exam_module_id = $this->post('exam_module_id');
                $this->db->where('exam_module_id', $exam_module_id);
                $this->db->order_by($this->Order_By);
                $data = $this->db->get('tbl_exam_module_question')->result_array();
                if (!empty($data)) {
                    for ($i = 0; $i < count($data); $i++) {
                        $data[$i]['image'] = ($data[$i]['image']) ? base_url() . EXAM_QUESTION_IMG_PATH . $data[$i]['image'] : '';
                        $data[$i] = $this->suffleOptions($data[$i], $firebase_id);
                        unset($data[$i]['session_answer']);
                    }
                    $response['error'] = false;
                    $response['data'] = $data;
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function set_exam_module_result_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }
            if ($this->post('exam_module_id') && $user_id) {
                $exam_module_id = $this->post('exam_module_id');

                $res = $this->db->where('exam_module_id', $exam_module_id)->where('user_id', $user_id)->get('tbl_exam_module_result')->result_array();
                if (empty($res)) {
                    $data = array(
                        'exam_module_id' => $this->post('exam_module_id'),
                        'user_id' => $user_id,
                        'rules_violated' => 0,
                        'status' => 2,
                    );
                    $this->db->insert('tbl_exam_module_result', $data);
                    $response['error'] = false;
                    $response['message'] = "110";
                } else {
                    if ($this->post('total_duration') != '' && $this->post('statistics') && $this->post('obtained_marks') != '') {
                        $data = array(
                            'obtained_marks' => $this->post('obtained_marks'),
                            'total_duration' => $this->post('total_duration'),
                            'statistics' => $this->post('statistics'),
                            'status' => 3,
                            'rules_violated' => ($this->post('rules_violated')) ? $this->post('rules_violated') : 0,
                            'captured_question_ids' => ($this->post('captured_question_ids')) ? $this->post('captured_question_ids') : '',
                        );
                        $this->db->where('exam_module_id', $exam_module_id)->where('user_id', $user_id)->update('tbl_exam_module_result', $data);
                        $response['error'] = false;
                        $response['message'] = "110";
                    } else {
                        $response['error'] = true;
                        $response['message'] = "103";
                    }
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function delete_user_account_post()
    {
        try {
            // ------- Should be Enabled for server  -----------------
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }
            // --------------------------------------------------------

            // ------- Should be Enabled for local  ------------------
            // $user_id = $this->post('user_id');
            // $firebase_id = $this->post('firebase_id');
            // --------------------------------------------------------

            if ($user_id) {
                $tables = [
                    'tbl_bookmark',
                    'tbl_contest_leaderboard',
                    'tbl_daily_quiz_user',
                    'tbl_exam_module_result',
                    'tbl_leaderboard_daily',
                    'tbl_leaderboard_monthly',
                    'tbl_level',
                    'tbl_multi_match_level',
                    'tbl_multi_match_question_reports',
                    'tbl_payment_request',
                    'tbl_question_reports',
                    'tbl_quiz_categories',
                    'tbl_rooms',
                    'tbl_tracker',
                    'tbl_users_badges',
                    'tbl_users_statistics',
                    'tbl_user_category',
                    'tbl_user_subcategory',
                    'tbl_user_quiz_zone_session',
                    'tbl_user_daily_quiz_session',
                    'tbl_user_true_false_session',
                    'tbl_user_fun_n_learn_session',
                    'tbl_user_guess_the_word_session',
                    'tbl_user_audio_quiz_session',
                    'tbl_user_maths_quiz_session',
                    'tbl_user_multi_match_session',
                    'tbl_user_contest_session'
                ];

                foreach ($tables as $type) {
                    if ($this->db->table_exists($type)) {
                        $this->db->where('user_id', $user_id)->delete($type);
                    }
                }

                $this->db->where('user_id1', $user_id)->delete('tbl_battle_statistics');
                $this->db->where('user_id2', $user_id)->delete('tbl_battle_statistics');
                $this->db->query("UPDATE tbl_notifications SET user_id = TRIM(BOTH ',' FROM REPLACE(CONCAT(',', user_id, ','), '," . $user_id . ",', ',')) WHERE type = 'selected' AND FIND_IN_SET('$user_id', user_id) > 0");

                // Delete groups owned by this user and their related data
                if ($this->db->table_exists('tbl_group')) {
                    // Get all groups owned by this user
                    $owned_groups = $this->db->where('owner_id', $user_id)->get('tbl_group')->result_array();
                    foreach ($owned_groups as $group) {
                        // Delete group battle entries for battles in this group
                        if ($this->db->table_exists('tbl_group_battle')) {
                            $battles = $this->db->where('group_id', $group['id'])->get('tbl_group_battle')->result_array();
                            foreach ($battles as $battle) {
                                if ($this->db->table_exists('tbl_group_battle_entry')) {
                                    $this->db->where('battle_id', $battle['id'])->delete('tbl_group_battle_entry');
                                }
                            }
                            $this->db->where('group_id', $group['id'])->delete('tbl_group_battle');
                        }
                        // Delete group members
                        if ($this->db->table_exists('tbl_group_member')) {
                            $this->db->where('group_id', $group['id'])->delete('tbl_group_member');
                        }
                    }
                    // Delete the groups
                    $this->db->where('owner_id', $user_id)->delete('tbl_group');
                }

                // Also remove user from any groups they are a member of (not owner)
                if ($this->db->table_exists('tbl_group_member')) {
                    $this->db->where('user_id', $user_id)->delete('tbl_group_member');
                }

                // Delete 1v1 battle entries
                if ($this->db->table_exists('tbl_battle_1v1')) {
                    $this->db->where('challenger_id', $user_id)->or_where('opponent_id', $user_id)->delete('tbl_battle_1v1');
                }

                // Delete user progress
                if ($this->db->table_exists('tbl_user_progress')) {
                    $this->db->where('user_id', $user_id)->delete('tbl_user_progress');
                }

                $this->db->where('id', $user_id)->delete('tbl_users');

                $response['error'] = false;
                $response['message'] = "111";
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function set_tracker_data_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }
            if ($user_id && $this->post('coins') && $this->post('title') && $this->post('status') != "") {
                $coins = $this->post('coins');
                $title = $this->post('title');
                $status = $this->post('status');

                $this->set_tracker_data($user_id, $coins, $title, $status);

                $response['error'] = false;
                $response['message'] = "111";
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_tracker_data_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }
            if ($user_id) {
                $offset = ($this->post('offset') && is_numeric($this->post('offset'))) ? $this->post('offset') : 0;
                $limit = ($this->post('limit') && is_numeric($this->post('limit'))) ? $this->post('limit') : 10;
                $type = ($this->post('type') && is_numeric($this->post('type'))) ? $this->post('type') : 0;
                if ($type == 1) {
                    $this->db->where('status', 0);
                } else if ($type == 2) {
                    $this->db->where('status', 1);
                }

                $this->db->where('user_id', $user_id);
                $this->db->order_by('id', 'DESC');
                $this->db->limit($limit, $offset);
                $data = $this->db->get('tbl_tracker')->result_array();
                if (!empty($data)) {
                    if ($type == 1) {
                        $data1 = $this->db->where('user_id', $user_id)->where('status', 0)->order_by('id', 'DESC')->get('tbl_tracker')->result_array();
                    } else if ($type == 2) {
                        $data1 = $this->db->where('user_id', $user_id)->where('status', 1)->order_by('id', 'DESC')->get('tbl_tracker')->result_array();
                    } else {
                        $data1 = $this->db->where('user_id', $user_id)->order_by('id', 'DESC')->get('tbl_tracker')->result_array();
                    }

                    $total = count($data1);

                    $response['error'] = false;
                    $response['total'] = "$total";
                    $response['data'] = $data;
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function set_payment_request_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }
            if ($user_id && $this->post('payment_type') && $this->post('payment_address') && $this->post('payment_amount') && $this->post('coin_used') && $this->post('details')) {
                $payment_type = $this->post('payment_type');
                $payment_address = $this->post('payment_address');
                $payment_amount = $this->post('payment_amount');
                $coin_used = $this->post('coin_used');
                $details = $this->post('details');
                $status = 0; // 0-pending & 1-completed

                $res = $this->db->where('type', 'payment_mode')->get('tbl_settings')->row_array();
                $res_msg = $this->db->where('type', 'payment_message')->get('tbl_settings')->row_array();
                if (!empty($res) && !empty($res_msg)) {
                    if ($res['message'] == 1 || $res['message'] == '1') {
                        $user_res = $this->db->where('id', $user_id)->get('tbl_users')->row_array();
                        if (!empty($user_res)) {

                            $firebase_id = $user_res['firebase_id'];
                            if ($user_res['status'] == 1 || $user_res['status'] == '1') {

                                /* check if user already made request before 24 hours */
                                $payment_res = $this->db->where('user_id', $user_id)->order_by('id', 'DESC')->get('tbl_payment_request')->row_array();

                                if (!empty($payment_res)) {
                                    $current_time = $this->toDateTime;
                                    $old_date = $payment_res['date'];
                                    $hourdiff = round((strtotime($current_time) - strtotime($old_date)) / 3600, 1);
                                    $hours_res = $this->db->where('type', 'difference_hours')->get('tbl_settings')->row_array();
                                    $hours_diff = (!empty($hours_res)) ? $hours_res['message'] : 48;
                                    if ($hourdiff < $hours_diff) {
                                        $response['error'] = true;
                                        $response['message'] = "127";
                                        $this->response($response, REST_Controller::HTTP_OK);
                                        return false;
                                    }
                                }

                                $frm_data = array(
                                    'user_id' => $user_id,
                                    'uid' => $firebase_id,
                                    'payment_type' => $payment_type,
                                    'payment_address' => $payment_address,
                                    'payment_amount' => $payment_amount,
                                    'coin_used' => $coin_used,
                                    'details' => $details,
                                    'status' => $status,
                                    'date' => $this->toDateTime,
                                    'status_date' => $this->toDateTime,
                                );
                                $this->db->insert('tbl_payment_request', $frm_data);

                                //set tracker data
                                $coins = -$coin_used;
                                $title = "redeemRequest";
                                $this->set_tracker_data($user_id, $coins, $title, 1);

                                //deduct cion from user table
                                $old_coin = $user_res['coins'];
                                $new_coin = $old_coin - $coin_used;
                                $data = array(
                                    'coins' => $new_coin,
                                );
                                $this->db->where('id', $user_id)->where('firebase_id', $firebase_id)->update('tbl_users', $data);
                                $response['error'] = false;
                                $response['message'] = "111";
                            } else {
                                $response['error'] = true;
                                $response['message'] = "126";
                            }
                        } else {
                            $response['error'] = true;
                            $response['message'] = "102";
                        }
                    } else {
                        $response['error'] = true;
                        $response['message'] = $res_msg['message'];
                    }
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_payment_request_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }
            if ($user_id) {
                $offset = ($this->post('offset') && is_numeric($this->post('offset'))) ? $this->post('offset') : 0;
                $limit = ($this->post('limit') && is_numeric($this->post('limit'))) ? $this->post('limit') : 10;
                $this->db->where('user_id', $user_id);
                $this->db->order_by('id', 'DESC');
                $this->db->limit($limit, $offset);
                $data = $this->db->get('tbl_payment_request')->result_array();
                if (!empty($data)) {
                    $data1 = $this->db->where('user_id', $user_id)->order_by('id', 'DESC')->get('tbl_payment_request')->result_array();
                    $total = count($data1);

                    $response['error'] = false;
                    $response['total'] = "$total";
                    $response['data'] = $data;
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_maths_questions_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }
            if ($this->post('type') && $this->post('type_id')) {
                $type = $this->post('type');
                $id = $this->post('type_id');
                $fix_question = is_settings('maths_quiz_fix_question');
                $limit = is_settings('maths_quiz_total_question');

                $this->db->where($type, $id);
                $this->db->order_by($this->Order_By);

                if ($fix_question == 1) {
                    $this->db->limit($limit, 0);
                }
                $data = $this->db->get('tbl_maths_question')->result_array();
                if (!empty($data)) {
                    $questionData = [];
                    for ($i = 0; $i < count($data); $i++) {
                        $data[$i]['image'] = ($data[$i]['image']) ? base_url() . MATHS_QUESTION_IMG_PATH . $data[$i]['image'] : '';
                        $optionData = $this->suffleOptions($data[$i], $firebase_id);
                        $data[$i] = $optionData;
                        $questionData[] = [
                            'id' => $data[$i]['id'],
                            'answer' => $data[$i]['session_answer'],
                        ];
                        unset($data[$i]['session_answer']);
                    }
                    if ($questionData) {
                        $this->set_user_session($user_id, $questionData, 'tbl_user_maths_quiz_session');
                    }
                    $response['error'] = false;
                    $response['data'] = $data;
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function delete_pending_payment_request_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }
            if ($user_id && $this->post('payment_id')) {
                $user_res = $this->db->where('id', $user_id)->get('tbl_users')->row_array();
                $paymentId = $this->post('payment_id');
                $paymentData = $this->db->where('id', $paymentId)->get('tbl_payment_request')->row_array();
                if ($paymentData) {
                    $newCoins = 0;
                    if ($paymentData['status'] == 0) {

                        // Add Tracker of Cancelled Payment Request
                        $title = "cancelPaymentRequest";
                        $this->set_tracker_data($user_id, $paymentData['coin_used'], $title, 0);

                        // Delete Payment Request
                        $this->db->where('id', $paymentId)->delete('tbl_payment_request');


                        // Calculate new coins
                        $newCoins = $user_res['coins'] + $paymentData['coin_used'];
                        $data = array(
                            'coins' => $newCoins,
                        );
                        // Update Coins in users table
                        $this->db->where('id', $user_id)->update('tbl_users', $data);

                        $response['error'] = false;
                        $response['message'] = "111";
                    } else {
                        $response['error'] = true;
                        $response['message'] = "135";
                    }
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function unlock_premium_category_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            if ($this->post('category')) {
                $category_id = $this->post('category');
                $data = $this->db->where(['user_id' => $user_id, 'category_id' => $category_id])->order_by('id', 'asc')->get('tbl_user_category')->result_array();
                if ($data) {
                    $response['error'] = true;
                    $response['message'] = "132";
                } else {
                    $frm_data = array(
                        'user_id' => $user_id,
                        'category_id' => $category_id,
                    );
                    $this->db->insert('tbl_user_category', $frm_data);
                    $response['error'] = false;
                    $response['message'] = "110";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }


        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function check_daily_ads_status_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            // Get Daily Ads Coin from Settings
            $dailyAdsCoinQuery = $this->db->select('message')->where('type', 'daily_ads_coins')->get('tbl_settings')->row_array();
            $dailyAdsCoin = $dailyAdsCoinQuery['message'];

            // Get Daily Ads Counter from Settings
            $dailyAdsCounterQuery = $this->db->select('message')->where('type', 'daily_ads_counter')->get('tbl_settings')->row_array();
            $dailyAdsCounter = $dailyAdsCounterQuery['message'];

            // Get User Daily Ads Counter And Date            
            $res = $this->db->where('id', $user_id)->get('tbl_users')->row_array();
            $userCounter = $res['daily_ads_counter'];
            $userDailyAdsDate = $res['daily_ads_date'];

            // Convert Date to string time 
            $dailyAdsDate = strtotime($userDailyAdsDate);
            $currentDate = strtotime(date('Y-m-d'));

            if ($currentDate != $dailyAdsDate) {
                // If Date Doen't match with today's date
                // Then Update Counter to 0 and date to today's
                $data = array(
                    'daily_ads_counter' => 0,
                    'daily_ads_date' => date('Y-m-d'),
                );

                // Update data and allow the user to watch ads
                $this->db->where('id', $user_id)->where('firebase_id', $firebase_id)->update('tbl_users', $data);
                $response['error'] = false;
                $response['message'] = "134";
            } else {
                if ($dailyAdsCounter == $userCounter) {
                    // If Daily Ads Counter is less than or equal to user's counter then not allow to watch ads
                    $response['error'] = true;
                    $response['message'] = "133";
                } else {
                    // If Daily Ads Counter is greater than or equal to user's counter then allow to watch ads
                    $response['error'] = false;
                    $response['message'] = "134";
                }
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function update_daily_ads_counter_post()
    {

        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            // Get Daily Ads Coin from Settings
            $dailyAdsCoinQuery = $this->db->select('message')->where('type', 'daily_ads_coins')->get('tbl_settings')->row_array();
            $dailyAdsCoin = $dailyAdsCoinQuery ? $dailyAdsCoinQuery['message'] : 5;

            // Get Daily Ads Counter from Settings
            $dailyAdsCounterQuery = $this->db->select('message')->where('type', 'daily_ads_counter')->get('tbl_settings')->row_array();
            $dailyAdsCounter = $dailyAdsCounterQuery ? $dailyAdsCounterQuery['message'] : 1;

            // Get User Daily Ads Counter, Date And Coins
            $res = $this->db->where('id', $user_id)->get('tbl_users')->row_array();
            $userCounter = $res['daily_ads_counter'];
            $userDailyAdsDate = $res['daily_ads_date'];
            $userCoins = $res['coins'];

            // Convert Date to string time 
            $dailyAdsDate = strtotime($userDailyAdsDate);
            $currentDate = strtotime(date('Y-m-d'));

            $data = array();

            if ($currentDate != $dailyAdsDate) {
                // If Date Doen't match with today's date
                // Then Update Counter to 0 and date to today's
                $data = array(
                    'daily_ads_counter' => 1,
                    'daily_ads_date' => date('Y-m-d'),
                );
                $response['error'] = false;
                $response['message'] = "111";
            } else {
                // If Date match with today's date
                if ($dailyAdsCounter <= $userCounter) {
                    // If Daily Ads Counter is less than or equal to user's counter then not allow to watch ads
                    $response['error'] = true;
                    $response['message'] = "133";
                } else {
                    // If Counter is not equal or exceding then update with increment
                    $data = array(
                        'daily_ads_counter' => ($userCounter + 1),
                        'coins' => ($userCoins + $dailyAdsCoin)
                    );
                    $response['error'] = false;
                    $response['message'] = "111";
                }
            }

            // Data Array Exists then update User Tracker and 
            if (isset($data) && !empty($data)) {
                $this->set_tracker_data($user_id, $dailyAdsCoin, $this->watched_ads, 0);
                $this->db->where('id', $user_id)->update('tbl_users', $data);
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    // Web's Home Settings settings data are retrived in this api
    public function get_web_home_settings_post()
    {
        try {
            $types = [
                'section_1_mode',
                'section1_heading',
                'section1_title1',
                'section1_title2',
                'section1_title3',
                'section1_image1',
                'section1_image2',
                'section1_image3',
                'section1_desc1',
                'section1_desc2',
                'section1_desc3',
                'section_2_mode',
                'section2_heading',
                'section2_title1',
                'section2_title2',
                'section2_title3',
                'section2_title4',
                'section2_desc1',
                'section2_desc2',
                'section2_desc3',
                'section2_desc4',
                'section2_image1',
                'section2_image2',
                'section2_image3',
                'section2_image4',
                'section_3_mode',
                'section3_heading',
                'section3_title1',
                'section3_title2',
                'section3_title3',
                'section3_title4',
                'section3_image1',
                'section3_image2',
                'section3_image3',
                'section3_image4',
                'section3_desc1',
                'section3_desc2',
                'section3_desc3',
                'section3_desc4'
            ];

            $language_id = $this->post('language_id') != "" ? $this->post('language_id') : 14;
            $data = $this->db->where('language_id', $language_id)->where_in('type', $types)->get('tbl_web_settings')->result_array();
            $web_settings_data = array();
            if (is_language_mode_enabled()) {
                $this->db->where('language_id', $language_id);
            }
            $sliderData = $this->db->order_by('id', 'DESC')->get('tbl_slider')->result_array();
            if (!empty($sliderData)) {
                for ($i = 0; $i < count($sliderData); $i++) {
                    $sliderData[$i]['image'] = ($sliderData[$i]['image']) ? base_url() . SLIDER_IMG_PATH . $sliderData[$i]['image'] : '';
                }
            }
            $web_settings_data['sliderData'] = $sliderData;

            if (!empty($data)) {
                for ($i = 0; $i < count($data); $i++) {
                    $type = $data[$i]['type'];
                    $message = $data[$i]['message'];

                    // Images of Home settings
                    $images = ['section1_image1', 'section1_image2', 'section1_image3', 'section2_image1', 'section2_image2', 'section2_image3', 'section2_image4', 'section3_image1', 'section3_image2', 'section3_image3', 'section3_image4'];
                    foreach ($images as $key => $value) {
                        if ($type == $value) {
                            $message = ($message) ? base_url() . WEB_HOME_SETTINGS_LOGO_PATH . $message : '';
                        }
                    }

                    $web_settings_data[$type] = $message;
                }
                $response['error'] = false;
                $response['data'] = $web_settings_data;
            } else {
                if (!empty($sliderData)) {
                    $response['error'] = false;
                    $response['data'] = $web_settings_data;
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    // Web's Settings data are retrived in this api
    public function get_web_settings_post()
    {
        try {
            $types = [
                'firebase_api_key',
                'firebase_auth_domain',
                'firebase_database_url',
                'firebase_project_id',
                'firebase_storage_bucket',
                'firebase_messager_sender_id',
                'firebase_app_id',
                'firebase_measurement_id',
                'company_name_footer',
                'email_footer',
                'phone_number_footer',
                'web_link_footer',
                'company_text',
                'address_text',
                'header_logo',
                'footer_logo',
                'sticky_header_logo',
                'quiz_zone_icon',
                'daily_quiz_icon',
                'true_false_icon',
                'fun_learn_icon',
                'self_challange_icon',
                'contest_play_icon',
                'one_one_battle_icon',
                'group_battle_icon',
                'audio_question_icon',
                'math_mania_icon',
                'exam_icon',
                'guess_the_word_icon',
                'primary_color',
                'footer_color',
                'social_media',
                'multi_match_icon'
            ];
            // Here Added language because settings and home settings of web are in same folder and web settings will be always stored with language 14
            $data = $this->db->where('language_id', 14)->where_in('type', $types)->get('tbl_web_settings')->result_array();
            $web_settings_data = array();
            if (!empty($data)) {
                for ($i = 0; $i < count($data); $i++) {
                    $type = $data[$i]['type'];

                    if ($type == 'social_media') {
                        $message = $data[$i]['message'] ? json_decode($data[$i]['message']) : '';
                        if (!empty($message)) {
                            foreach ($message as $key => $value) {
                                $value->icon = ($value->icon) ? base_url() . WEB_SETTINGS_LOGO_PATH . $value->icon : '';
                            }
                        }
                    } else {
                        $message = $data[$i]['message'];
                        // LOGOS of Web settings
                        $logos = ['favicon', 'header_logo', 'footer_logo', 'sticky_header_logo', 'quiz_zone_icon', 'daily_quiz_icon', 'true_false_icon', 'fun_learn_icon', 'self_challange_icon', 'contest_play_icon', 'one_one_battle_icon', 'group_battle_icon', 'audio_question_icon', 'math_mania_icon', 'exam_icon', 'guess_the_word_icon', 'multi_match_icon'];
                        foreach ($logos as $key => $value) {
                            if ($type == $value) {
                                $message = ($message) ? base_url() . WEB_SETTINGS_LOGO_PATH . $message : '';
                            }
                        }
                    }

                    $web_settings_data[$type] = $message;
                }
                $response['error'] = false;
                $response['data'] = $web_settings_data;
            } else {
                $response['error'] = true;
                $response['message'] = "102";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_user_coin_score_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            if ($user_id) {
                $result = $this->db->select('coins')->where('id', $user_id)->get('tbl_users')->row_array();
                if (!empty($result)) {
                    $my_rank = $this->myGlobalRank($user_id);

                    $result['score'] = ($my_rank) ? $my_rank['score'] : '0';

                    $response['error'] = false;
                    $response['data'] = $result;
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function set_user_in_app_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }
            if ($user_id && $this->post('product_id')) {
                $product_id = $this->post('product_id');
                if ($this->post('purchase_token') && $this->post('pay_from')) {
                    $purchaseToken = $this->post('purchase_token');
                    $pay_from = $this->post('pay_from');
                    $getCoinStoreData = $this->db->select('coins,type')->where('product_id', $product_id)->get('tbl_coin_store')->row_array();
                    $amount = $getCoinStoreData['coins'] ?? 0;
                    $packageType = $getCoinStoreData['type'] ?? '';
                    $status = 1;

                    $checkToken = $this->db->where('product_id', $product_id)->where('purchase_token', $purchaseToken)->get('tbl_users_in_app')->row_array();
                    if (empty($checkToken)) {
                        // 1=android,2=ios
                        if ($pay_from == 1) {
                            $packageName = is_settings('app_package_name') ?? '';
                            $pathToServiceAccountJsonFile = 'assets/firebase_config.json';
                            $get_file = file_get_contents($pathToServiceAccountJsonFile); //data read from json file
                            $fileData = ($get_file != '') ? json_decode($get_file) : '';
                            $applicationName = ($fileData != '') ? $fileData->project_id ?? '' : '';
                            if ($applicationName != '') {
                                $googleClient = new Google\Client();
                                $googleClient->setScopes([\Google\Service\AndroidPublisher::ANDROIDPUBLISHER]);
                                $googleClient->setApplicationName($applicationName);
                                $googleClient->setAuthConfig($pathToServiceAccountJsonFile);

                                $googleAndroidPublisher = new \Google\Service\AndroidPublisher($googleClient);
                                $validator = new \ReceiptValidator\GooglePlay\Validator($googleAndroidPublisher);

                                try {
                                    $ValidResponse = $validator->setPackageName($packageName)
                                        ->setProductId($product_id)
                                        ->setPurchaseToken($purchaseToken)
                                        ->validatePurchase();

                                    if ($ValidResponse) {

                                        $response1 = $googleAndroidPublisher->purchases_products->get($packageName, $product_id, $purchaseToken);
                                        $orderId = $response1->getOrderId() ?? '';
                                        $checkOrder = $this->db->where('product_id', $product_id)->where('purchase_token', $purchaseToken)->get('tbl_users_in_app')->row_array();

                                        $purchaseTimeMillis = $response1->purchaseTimeMillis ?? '';
                                        if ($purchaseTimeMillis != '') {

                                            // Convert milliseconds to seconds and create a DateTime object
                                            $purchaseTimeSeconds = $purchaseTimeMillis / 1000;
                                            $purchaseDate = new DateTime("@$purchaseTimeSeconds");
                                            $purchaseDate->setTimezone(new DateTimeZone(get_system_timezone())); // Set the desired timezone if needed

                                            $date = $purchaseDate->format('Y-m-d H:i:s');
                                        }

                                        $tracker_data = [
                                            'pay_from' => 1,
                                            'uid' => $firebase_id,
                                            'user_id' => $user_id,
                                            'product_id' => $product_id,
                                            'amount' => $amount ?? 0,
                                            'status' => $status ?? 0,
                                            'transaction_id' => $orderId ?? '',
                                            'date' => ($date != '') ? $date : $this->toDateTime,
                                            'purchase_token' => $purchaseToken,
                                            'responseData' => $response1 ? json_encode($response1) : '',
                                        ];
                                        $insertData = $this->db->insert('tbl_users_in_app', $tracker_data);

                                        if ($insertData) {
                                            if ($packageType != '' && $packageType == 0) {
                                                $coins = $amount ?? 0;
                                                $this->set_coins($user_id, $coins);
                                                //set tracker data
                                                $title = 'boughtCoins';
                                                $status = 0;
                                                $this->set_tracker_data($user_id, $coins, $title, $status);
                                            } else if ($packageType != '' && $packageType == 1) {
                                                $updateAds = [
                                                    'remove_ads' => 1
                                                ];
                                                $this->db->where('id', $user_id)->update('tbl_users', $updateAds);
                                            }
                                            $response['error'] = false;
                                            $response['message'] = "110";
                                        } else {
                                            $response['error'] = true;
                                            $response['message'] = "122";
                                        }
                                    } else {
                                        $response['error'] = true;
                                        $response['message'] = "122";
                                    }
                                } catch (Exception $e) {
                                    $response['error'] = true;
                                    $response['message'] = '122';
                                    $response['message_error'] = $e->getMessage();
                                }
                            } else {
                                $response['error'] = true;
                                $response['message'] = '122';
                            }
                        } else if ($pay_from == 2) {
                            $validator = new iTunesValidator(iTunesValidator::ENDPOINT_PRODUCTION);
                            $receiptBase64Data = $purchaseToken;
                            try {
                                $sharedSecret = is_settings('shared_secrets') ?? ''; // Generated in iTunes Connect's In-App Purchase menu
                                if ($sharedSecret) {
                                    $ValidateResponse = $validator->setSharedSecret($sharedSecret)->setReceiptData($receiptBase64Data)->validate(); // use setSharedSecret() if for recurring subscriptions
                                    if ($ValidateResponse->isValid()) {
                                        foreach ($ValidateResponse->getPurchases() as $purchase) {
                                            $responseData = $purchase;
                                            $getTransactionId = $purchase->getTransactionId();
                                            if ($purchase->getPurchaseDate() != null) {
                                                $getPurchaseDate = $purchase->getPurchaseDate();
                                            }
                                        }
                                        $tracker_data = [
                                            'pay_from' => 2,
                                            'uid' => $firebase_id,
                                            'user_id' => $user_id,
                                            'product_id' => $product_id,
                                            'amount' => $amount ?? 0,
                                            'status' => $status ?? 0,
                                            'transaction_id' => $getTransactionId ?? '',
                                            'date' => isset($getPurchaseDate) ? $getPurchaseDate : $this->toDateTime,
                                            'purchase_token' => $purchaseToken,
                                            'responseData' => json_encode($responseData) ?? ''
                                        ];
                                        $insertData = $this->db->insert('tbl_users_in_app', $tracker_data);
                                        if ($insertData) {
                                            if ($packageType != '' && $packageType == 0) {
                                                $coins = $amount ?? 0;
                                                $this->set_coins($user_id, $coins);
                                                //set tracker data
                                                $title = 'boughtCoins';
                                                $status = 0;
                                                $this->set_tracker_data($user_id, $coins, $title, $status);
                                            } else if ($packageType != '' && $packageType == 1) {
                                                $updateAds = [
                                                    'remove_ads' => 1
                                                ];
                                                $this->db->where('id', $user_id)->update('tbl_users', $updateAds);
                                            }
                                            $response['error'] = false;
                                            $response['message'] = "110";
                                        } else {
                                            $response['error'] = true;
                                            $response['message'] = "122";
                                        }
                                    } else {
                                        $response['error'] = true;
                                        $response['message'] = '122';
                                        $response['message_error'] = $ValidateResponse->getResultCode();
                                    }
                                } else {
                                    $response['error'] = true;
                                    $response['message'] = "103";
                                }
                            } catch (Exception $e) {
                                $response['error'] = true;
                                $response['message'] = '122';
                                $response['message_error'] = $e->getMessage();
                            }
                        } else {
                            $response['error'] = true;
                            $response['message'] = "122";
                        }
                    } else {
                        $response['error'] = true;
                        $response['message'] = "136";
                    }
                } else {
                    $response['error'] = true;
                    $response['message'] = "103";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_system_language_list_post()
    {
        try {
            if ($this->post('from')) {
                $from = $this->post('from');
                $this->db->select('name,title');
                switch ($from) {
                    case 1:
                        $this->db->select('app_version,app_rtl_support,app_status,app_default')->where('app_status', 1)->where('app_version!=', '0.0.0');
                        break;
                    case 2:
                        $this->db->select('web_version,web_rtl_support,web_status,web_default')->where('web_status', 1)->where('web_version!=', '0.0.0');
                        break;
                    default:
                        $response = [
                            'error' => true,
                            'message' => "122"
                        ];
                        $this->response($response, REST_Controller::HTTP_OK);
                        return;
                }
                $checkData = $this->db->get('tbl_upload_languages')->result_array();
                if ($checkData) {
                    $response = [
                        'error' => false,
                        'data' => $checkData
                    ];
                } else {
                    $response = [
                        'error' => true,
                        'message' => "102"
                    ];
                }
            } else {
                $response = [
                    'error' => true,
                    'message' => "103"
                ];
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_system_language_json_post()
    {
        try {
            if ($this->post('from')) {
                $from = $this->post('from');
                $language = $this->post('language') ?? 'english';
                $version = '';
                $rtl_support = '0';
                $status = '0';
                $default = '0';

                switch ($from) {
                    case 1:
                        $path = APP_LANGUAGE_FILE_PATH;
                        $sampleFile = 'app_sample_file.json';
                        break;
                    case 2:
                        $path = WEB_LANGUAGE_FILE_PATH;
                        $sampleFile = 'web_sample_file.json';
                        break;
                    default:
                        $response = [
                            'error' => true,
                            'message' => "122"
                        ];
                        $this->response($response, REST_Controller::HTTP_OK);
                        return;
                }

                $file = $path . $language . '.json';

                if (!file_exists($file)) {
                    $file = $path . $sampleFile;
                } else {
                    $checkData = $this->db->where('name', $language)->get('tbl_upload_languages')->row_array();
                    if ($checkData) {
                        $version = ($from == 1) ? $checkData['app_version'] : $checkData['web_version'];
                        $rtl_support = ($from == 1) ? $checkData['app_rtl_support'] : $checkData['web_rtl_support'];
                        $status = ($from == 1) ? $checkData['app_status'] : $checkData['web_status'];
                        $default = ($from == 1) ? $checkData['app_default'] : $checkData['web_default'];
                    }
                }

                $getFileContent = file_get_contents($file);
                $sampleArray = json_decode($getFileContent, true);

                $response = [
                    'error' => false,
                    'version' => $version,
                    'rtl_support' => $rtl_support,
                    'status' => $status,
                    'default' => $default,
                    'data' => $sampleArray
                ];
            } else {
                $response = [
                    'error' => true,
                    'message' => "103"
                ];
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_multi_match_questions_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            if ($this->post('type') && $this->post('id')) {
                $type = $this->post('type');
                $id = $this->post('id');

                $this->db->where($type, $id);
                $this->db->order_by($this->Order_By);
                $data = $this->db->get('tbl_multi_match')->result_array();
                if (!empty($data)) {
                    for ($i = 0; $i < count($data); $i++) {
                        $data[$i]['image'] = ($data[$i]['image']) ? base_url() . MULTIMATCH_QUESTION_IMG_PATH . $data[$i]['image'] : '';
                        $answers = explode(',', trim($data[$i]['answer']));
                        $data[$i]['answer'] = array_map(function ($answer) use ($firebase_id) {
                            return $this->encrypt_data($firebase_id, $answer);
                        }, $answers);
                    }
                    $response['error'] = false;
                    $response['data'] = $data;
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_multi_match_questions_by_type_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            if ($this->post('question_type')) {
                $type = $this->post('question_type');
                $language_id = ($this->post('language_id')) ? $this->post('language_id') : "0";
                $fix_question = is_settings('true_false_quiz_fix_question');
                $limit = is_settings('true_false_quiz_total_question');

                $this->db->select('ms.*,c.id as cat_id, sc.id as subcat_id');

                $this->db->where('ms.question_type', $type);
                if (!empty($language_id)) {
                    $this->db->where('ms.language_id', $language_id);
                }
                $this->db->join('tbl_category c', 'ms.category = c.id')->where('c.is_premium', '0');
                $this->db->join('tbl_subcategory sc', 'ms.subcategory = sc.id', 'left');
                $this->db->order_by($this->Order_By);

                if ($fix_question == 1 && $limit) {
                    $this->db->limit($limit, 0);
                }

                $data = $this->db->get('tbl_multi_match ms')->result_array();

                if (!empty($data)) {
                    for ($i = 0; $i < count($data); $i++) {
                        $data[$i]['image'] = ($data[$i]['image']) ? base_url() . MULTIMATCH_QUESTION_IMG_PATH . $data[$i]['image'] : '';
                        $answers = explode(',', trim($data[$i]['answer']));
                        $data[$i]['answer'] = array_map(function ($answer) use ($firebase_id) {
                            return $this->encrypt_data($firebase_id, $answer);
                        }, $answers);
                    }
                    $response['error'] = false;
                    $response['data'] = $data;
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_multi_match_questions_by_level_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {

                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {

                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }
            if ($this->post('level') && ($this->post('category') || $this->post('subcategory'))) {
                $level = $this->post('level');
                $language_id = ($this->post('language_id')) ? $this->post('language_id') : 0;
                $category_id = $this->post('category');
                $subcategory_id = $this->post('subcategory');
                $fix_question = is_settings('multi_match_fix_level_question');
                $limit = is_settings('multi_match_total_level_question');

                $this->db->select('mq.*,cat.slug as category_slug,subcat.slug as subcategory_slug');
                $this->db->where('level', $level);
                $this->db->join('tbl_category cat', 'cat.id=mq.category', 'left');
                $this->db->join('tbl_subcategory subcat', 'subcat.id=mq.subcategory', 'left');
                if ($this->post('subcategory')) {
                    $this->db->where('mq.subcategory', $subcategory_id);
                } else {
                    $this->db->where('mq.category', $category_id);
                }
                if (!empty($language_id)) {
                    $this->db->where('mq.language_id', $language_id);
                }
                $this->db->order_by($this->Order_By);
                if ($fix_question == 1) {
                    $this->db->limit($limit, 0);
                }
                $data = $this->db->get('tbl_multi_match mq')->result_array();
                $questionData = [];
                if (!empty($data)) {
                    for ($i = 0; $i < count($data); $i++) {
                        $data[$i]['image'] = ($data[$i]['image']) ? base_url() . MULTIMATCH_QUESTION_IMG_PATH . $data[$i]['image'] : '';
                        $questionData[] = [
                            'id' => $data[$i]['id'],
                            'answer' => $data[$i]['answer'],
                            'level' => $data[$i]['level']
                        ];
                        $answers = explode(',', trim($data[$i]['answer']));
                        $data[$i]['answer'] = array_map(function ($answer) use ($firebase_id) {
                            return $this->encrypt_data($firebase_id, $answer);
                        }, $answers);
                    }
                    if ($questionData) {
                        $this->set_user_session($user_id, $questionData, 'tbl_user_multi_match_session');
                    }
                    $response['error'] = false;
                    $response['data'] = $data;
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function multi_match_report_question_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            if ($this->post('question_id') && $user_id && $this->post('message')) {
                $frm_data = array(
                    'question_id' => $this->post('question_id'),
                    'user_id' => $user_id,
                    'message' => $this->post('message'),
                    'date' => $this->toDateTime,
                );
                $this->db->insert('tbl_multi_match_question_reports', $frm_data);
                $response['error'] = false;
                $response['message'] = "109";
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function get_multi_match_level_data_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            if ($user_id && ($this->post('category') || $this->post('category_slug'))) {
                $category = $this->post('category') ?? 0;
                $categorySlug = !empty($this->post('category_slug')) ? $this->post('category_slug') : null;
                $subcategory = ($this->post('subcategory')) ? $this->post('subcategory') : 0;
                $subcategorySlug = !empty($this->post('subcategory_slug')) ? $this->post('subcategory_slug') : null;

                if ($subcategory) {
                    $subcategoryData = $this->db->select("id,maincat_id,subcategory_name,slug")->where('id', $subcategory)->get('tbl_subcategory')->row_array();
                    if ($subcategoryData) {
                        $categoryData = $this->getCategoryData($category, $categorySlug);
                        $questionData = $this->getMultiMatchQuestionData($subcategoryData, $categoryData);
                    }
                } elseif ($subcategorySlug) {
                    $subcategoryData = $this->db->select("id,maincat_id,subcategory_name,slug")->where('slug', $subcategorySlug)->get('tbl_subcategory')->row_array();
                    if ($subcategoryData) {
                        $categoryData = $this->getCategoryData($category, $categorySlug);
                        $questionData = $this->getMultiMatchQuestionData($subcategoryData, $categoryData);
                    }
                } else {
                    $categoryData = $this->getCategoryData($category, $categorySlug);
                    $subcategoryData = ['id' => 0];
                    $questionData = $this->getMultiMatchQuestionData($subcategoryData, $categoryData);
                }

                if ((isset($categoryData) && !empty($categoryData)) && (isset($subcategoryData) && !empty($subcategoryData))) {
                    // Get Level Data with its Particular Question Count
                    $max_level = $questionData['max_level'];
                    $counter = range(1, $max_level);
                    $levelData = [];

                    foreach ($counter as $key => $level) {
                        $query = $this->db->query('select count(id) as no_of_que from tbl_multi_match where level = ' . $level . ' and category = ' . $categoryData["id"] . ' and subcategory = ' . $subcategoryData["id"])->row_array();
                        $levelData[$key]['level'] = $level;
                        $levelData[$key]['no_of_ques'] = $query['no_of_que'];
                    }

                    // Get Data 
                    $res = $this->db->select('level')->where('user_id', $user_id)->where('category', $categoryData['id'])->where('subcategory', $subcategoryData['id'])->get('tbl_multi_match_level')->row_array();
                    $data = array(
                        'level' => $res['level'] ?? "1",
                        'no_of_ques' => $questionData['no_of_que'],
                        'max_level' => $questionData['max_level'],
                        'category' => $categoryData ?? [],
                        'subcategory' => $subcategoryData ?? [],
                        'level_data' => $levelData ?? []
                    );
                    $response['error'] = false;
                    $response['data'] = $data;
                } else {
                    $response['error'] = true;
                    $response['message'] = "102";
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }


        $this->response($response, REST_Controller::HTTP_OK);
    }

    public function set_quiz_coin_score_post()
    {
        try {
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
                $firebase_id = $is_user['firebase_id'];
            } else {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return false;
            }

            if ($user_id && $this->post('quiz_type')) {
                $category = $this->post('category') ? $this->post('category') : 0;
                $subcategory = $this->post('subcategory') ? $this->post('subcategory') : 0;
                $match_id = $this->post('match_id') ? $this->post('match_id') : 0;
                $is_bot = $this->post('is_bot') ? $this->post('is_bot') : 0;
                $no_of_hint_used = $this->post('no_of_hint_used') ? $this->post('no_of_hint_used') : 0;
                $totalPlayTime = $this->post('total_play_time') ? $this->post('total_play_time') : 0;
                $joined_users_count = $this->post('joined_users_count') ? $this->post('joined_users_count') : 0;
                $quiz_type = $this->post('quiz_type');
                $playQuestions = $this->post('play_questions');
                $lifeline = $this->post('lifeline') ? explode(',', $this->post('lifeline')) : [];

                $quizMap = [
                    "1"   => [
                        'table' => 'tbl_user_quiz_zone_session',
                        'handler' => 'QuizZone',
                        'params' => [$user_id, 'tbl_user_quiz_zone_session', $category, $subcategory, $playQuestions, $lifeline],
                        'requires_session' => true
                    ],
                    "1.1" => [
                        'table' => 'tbl_user_daily_quiz_session',
                        'handler' => 'DailyQuiz',
                        'params' => [$user_id, 'tbl_user_daily_quiz_session', $playQuestions],
                        'requires_session' => true
                    ],
                    "1.2" => [
                        'table' => 'tbl_user_true_false_session',
                        'handler' => 'trueFalse',
                        'params' => [$user_id, 'tbl_user_true_false_session', $playQuestions],
                        'requires_session' => true
                    ],
                    "1.3" => [
                        'handler' => 'randomBattle',
                        'params' => [$user_id, $match_id, $is_bot, $playQuestions],
                        'requires_session' => false
                    ],
                    "1.4" => [
                        'handler' => 'oneVsOneBattle',
                        'params' => [$user_id, $match_id, $playQuestions],
                        'requires_session' => false
                    ],
                    "1.5" => [
                        'handler' => 'groupBattle',
                        'params' => [$user_id, $match_id, $playQuestions, $joined_users_count],
                        'requires_session' => false
                    ],
                    "2"   => [
                        'table' => 'tbl_user_fun_n_learn_session',
                        'handler' => 'funNLearn',
                        'params' => [$user_id, 'tbl_user_fun_n_learn_session', $category, $subcategory, $playQuestions, $totalPlayTime],
                        'requires_session' => true
                    ],
                    "3"   => [
                        'table' => 'tbl_user_guess_the_word_session',
                        'handler' => 'guessTheWord',
                        'params' => [$user_id, 'tbl_user_guess_the_word_session', $category, $subcategory, $playQuestions, $totalPlayTime, $no_of_hint_used],
                        'requires_session' => true
                    ],
                    "4"   => [
                        'table' => 'tbl_user_audio_quiz_session',
                        'handler' => 'audioQuiz',
                        'params' => [$user_id, 'tbl_user_audio_quiz_session', $category, $subcategory, $playQuestions],
                        'requires_session' => true
                    ],
                    "5"   => [
                        'table' => 'tbl_user_maths_quiz_session',
                        'handler' => 'mathsQuiz',
                        'params' => [$user_id, 'tbl_user_maths_quiz_session', $category, $subcategory, $playQuestions],
                        'requires_session' => true
                    ],
                    "6"   => [
                        'table' => 'tbl_user_multi_match_session',
                        'handler' => 'multiMatch',
                        'params' => [$user_id, 'tbl_user_multi_match_session', $category, $subcategory, $playQuestions],
                        'requires_session' => true
                    ],
                    "contest"   => [
                        'table' => 'tbl_user_contest_session',
                        'handler' => 'contest',
                        'params' => [$user_id, 'tbl_user_contest_session', $playQuestions],
                        'requires_session' => true
                    ],
                ];

                $key = (string) $quiz_type;
                if (isset($quizMap[$key])) {
                    $config = $quizMap[$key];
                    $table = '';
                    $handler = $config['handler'];
                    $params = $config['params'];
                    $requiresSession = $config['requires_session'] ?? false;

                    if ($requiresSession) {
                        $table = $config['table'];
                        $batchSize = 500;
                        do {
                            $rows = $this->db->select('id')
                                ->from($table)
                                ->where('date <', $this->twoDayOldDate)
                                ->limit($batchSize)
                                ->get()
                                ->result_array();

                            $idsToDelete = array_column($rows, 'id');

                            if (!empty($idsToDelete)) {
                                $this->db->where_in('id', $idsToDelete);
                                $this->db->delete($table);
                            }

                            $deletedRows = count($idsToDelete);
                        } while ($deletedRows === $batchSize);


                        // Only check session with light query
                        $checkData = $this->db->select('id')
                            ->where('user_id', $user_id)
                            ->limit(1)
                            ->get($table)
                            ->row_array();

                        if (!$checkData) {
                            $response = [
                                'error' => true,
                                'error_msg' => 'Not Valid',
                                'message' => "122"
                            ];
                            $this->response($response, REST_Controller::HTTP_OK);
                            return;
                        }
                    }

                    $res = call_user_func_array([$this, $handler], $params);
                    if ($res) {
                        $response = [
                            'error' => false,
                            'message' => "111",
                            'data' => $res
                        ];
                    } else {
                        $response = [
                            'error' => true,
                            'message' => "102"
                        ];
                    }
                } else {
                    $response = [
                        'error' => true,
                        'error_msg' => 'Quiz Type',
                        'message' => "122"
                    ];
                }
            } else {
                $response['error'] = true;
                $response['message'] = "103";
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "122";
            $response['error_msg'] = $e->getMessage();
        }

        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Other Functions used for internally 
     */

    function set_quiz_level_data($user_id, $quiz_type, $level, $category, $subcategory = 0)
    {
        $table = '';
        if ($quiz_type == 1) {
            $table = 'tbl_level';
        } else if ($quiz_type == 6) {
            $table = 'tbl_multi_match_level';
        }
        if ($table) {
            $this->db->where('user_id', $user_id)->where('category', $category)->where('subcategory', $subcategory);
            $res = $this->db->get($table)->result_array();
            if (!empty($res)) {
                $data = array(
                    'level' => $level,
                );
                $this->db->where('user_id', $user_id)->where('category', $category)->where('subcategory', $subcategory)->update($table, $data);
            } else {
                $frm_data = array(
                    'user_id' => $user_id,
                    'category' => $category,
                    'subcategory' => $subcategory,
                    'level' => $level,
                );
                $this->db->insert($table, $frm_data);
            }
        }
    }

    function set_users_statistics($user_id, $category_id, $questions_answered, $correct_answers,  $ratio)
    {
        $res = $this->db->where('user_id', $user_id)->get('tbl_users_statistics')->row_array();
        if (!empty($res)) {
            $type = 'big_thing';
            $res2 = $this->db->where('user_id', $user_id)->get('tbl_users_badges')->row_array();
            if (!empty($res2)) {
                if ($res2[$type] == 0 || $res2[$type] == '0') {
                    $res1 = $this->db->where('type', $type)->get('tbl_badges')->row_array();
                    if (!empty($res1)) {
                        $counter = $res1['badge_counter'];
                        if ($counter <= $res['correct_answers']) {
                            $this->set_badges($user_id, $this->BIG_THING, 1);
                        }
                    }
                }
            }

            $qa = $res['questions_answered'];
            $ca = $res['correct_answers'];
            $sc = $res['strong_category'];
            $r1 = $res['ratio1'];
            $wc = $res['weak_category'];
            $r2 = $res['ratio2'];
            $bp = $res['best_position'];

            $my_rank = $this->myGlobalRank($user_id);

            $rank1 = $my_rank['user_rank'];
            if ($rank1 < $bp || $bp == 0) {
                $bp = $rank1;
                $data = array('best_position' => $bp);
                $this->db->where('user_id', $user_id)->update('tbl_users_statistics', $data);
            }

            if ($ratio > 50) {
                /* update strong category */
                /* when ratio is > 50 he is strong in this particular category */
                $data['questions_answered'] = $qa + $questions_answered;
                $data['correct_answers'] = $ca + $correct_answers;
                if ($ratio > $r1 || $sc == 0) {
                    $data['strong_category'] = $category_id;
                    $data['ratio1'] = $ratio;
                }
            } else {
                /* update weak category */
                /* when ratio is < 50 he is weak in this particular category */
                $data['questions_answered'] = $qa + $questions_answered;
                $data['correct_answers'] = $ca + $correct_answers;
                if ($ratio < $r2 || $wc == 0) {
                    $data['weak_category'] = $category_id;
                    $data['ratio2'] = $ratio;
                }
            }
            $data['best_position'] = $bp;
            $this->db->where('user_id', $user_id)->update('tbl_users_statistics', $data);
        } else {
            if ($ratio > 50) {
                $frm_data = array(
                    'user_id' => $user_id,
                    'questions_answered' => $questions_answered,
                    'correct_answers' => $correct_answers,
                    'strong_category' => $category_id,
                    'ratio1' => $ratio,
                    'weak_category' => 0,
                    'ratio2' => 0,
                    'best_position' => 0,
                    'date_created' => $this->toDateTime,
                );
            } else {
                $frm_data = array(
                    'user_id' => $user_id,
                    'questions_answered' => $questions_answered,
                    'correct_answers' => $correct_answers,
                    'strong_category' => 0,
                    'ratio1' => 0,
                    'weak_category' => $category_id,
                    'ratio2' => $ratio,
                    'best_position' => 0,
                    'date_created' => $this->toDateTime,
                );
            }
            $this->db->insert('tbl_users_statistics', $frm_data);
        }
    }

    function set_users_battle_statistics($user_id1, $user_id2, $is_drawn, $winner_id)
    {
        $frm_data = array(
            'user_id1' => $user_id1,
            'user_id2' => $user_id2,
            'is_drawn' => $is_drawn,
            'winner_id' => $winner_id,
            'date_created' => $this->toDateTime,
        );
        $this->db->insert('tbl_battle_statistics', $frm_data);

        if ($is_drawn == 0 || $is_drawn == '0') {
            $this->set_badges($winner_id, $this->COMBAT_WINNER);

            $type = $this->QUIZ_WARRIOR;
            if ($user_id1 == $winner_id) {
                $res = $this->db->where('user_id', $user_id1)->get('tbl_users_badges')->row_array();
                if (!empty($res)) {
                    $counter_name = $type . '_counter';
                    if ($res[$type] == 0 || $res[$type] == '0') {
                        $res1 = $this->db->where('type', $type)->get('tbl_badges')->row_array();
                        if (!empty($res1)) {
                            $counter = $res1['badge_counter'];
                            $user_conter = $res[$counter_name];
                            $user_conter = $user_conter + 1;
                            if ($user_conter < $counter) {
                                $data = [$counter_name => $user_conter];
                                $this->db->where('user_id', $user_id1)->update('tbl_users_badges', $data);

                                $data1 = [$counter_name => 0];
                                $this->db->where('user_id', $user_id2)->update('tbl_users_badges', $data1);
                            } else if ($counter == $user_conter) {
                                $this->set_badges($user_id1, $type, $counter = 0);
                            }
                        }
                    }
                }
            } else if ($user_id2 == $winner_id) {
                $res = $this->db->where('user_id', $user_id2)->get('tbl_users_badges')->row_array();
                if (!empty($res)) {
                    $counter_name = $type . '_counter';
                    if ($res[$type] == 0 || $res[$type] == '0') {
                        $res1 = $this->db->where('type', $type)->get('tbl_badges')->row_array();
                        if (!empty($res1)) {
                            $counter = $res1['badge_counter'];
                            $user_conter = $res[$counter_name];
                            $user_conter = $user_conter + 1;
                            if ($user_conter < $counter) {
                                $data = [$counter_name => $user_conter];
                                $this->db->where('user_id', $user_id2)->update('tbl_users_badges', $data);

                                $data1 = [$counter_name => 0];
                                $this->db->where('user_id', $user_id1)->update('tbl_users_badges', $data1);
                            } else if ($counter == $user_conter) {
                                $this->set_badges($user_id2, $type, $counter = 0);
                            }
                        }
                    }
                }
            }
        }
    }

    function set_user_session($user_id, $questions, $table)
    {
        $checkData = $this->db->where('user_id', $user_id)->get($table)->row_array();
        if ($checkData) {
            $this->db->where('user_id', $user_id)->update($table, ['questions' => json_encode($questions)]);
        } else {
            $frm_data = array(
                'user_id' => $user_id,
                'questions' => json_encode($questions),
                'date' => $this->toDate,
            );
            $this->db->insert($table, $frm_data);
        }
    }

    //1
    function QuizZone($user_id, $table, $category, $subcategory, $playQuestions,  $lifelineData = [])
    {
        $checkData = $this->db->where('user_id', $user_id)->get($table)->row_array();
        if ($checkData) {
            $minimumQuestionsForBadge = $this->minimumQuestionsForBadge;
            $setQuestions = json_decode($checkData['questions'], true);
            $currentLevel = $setQuestions[0]['level'];
            $getMaxLevelData = $this->db->select_max('level')->where('category', $category)->where('subcategory', $subcategory)->get('tbl_question')->row_array();
            $totalLevel = $getMaxLevelData['level'];

            if ($currentLevel <= $totalLevel) {
                $setQuestionMap = [];
                $setQuestionMap = array_column($setQuestions, 'answer', 'id');
                $total_questions = count($setQuestions);
                $correctAnswer = 0;

                $play_questions = json_decode($playQuestions, true);
                foreach ($play_questions as $userAnswer) {
                    $id = $userAnswer['id'];
                    if (isset($setQuestionMap[$id]) && $setQuestionMap[$id] === $userAnswer['answer']) {
                        $correctAnswer++;
                    }
                }
                $questions_answered = count($play_questions);
                $quiz_winning_percentage = is_settings('quiz_winning_percentage');
                $winningPer = ($correctAnswer * 100) / $total_questions;

                if ($lifelineData) {
                    $quiz_zone_lifeline_deduct_coin = is_settings('quiz_zone_lifeline_deduct_coin');
                    $quiz_zone_lifeline_deduct_coin = $quiz_zone_lifeline_deduct_coin ? ('-' . $quiz_zone_lifeline_deduct_coin) : 0;
                    foreach ($lifelineData as $key => $lifeline) {
                        $this->set_coins($user_id, $quiz_zone_lifeline_deduct_coin);
                        $title = $lifeline;
                        $status = 1; //deduct
                        $this->set_tracker_data($user_id, $quiz_zone_lifeline_deduct_coin, $title, $status);
                    }
                }
                $earnCoin = $userScore = 0;
                    $wrongAnswer = $total_questions - $correctAnswer;

                // NEW COIN RULE: Award 1 coin only for 100% correct (perfect score)
                if ($correctAnswer == $total_questions && $total_questions > 0) {
                    $earnCoin = 1;
                }
                
                // Foundation School quizzes don't award coins
                $this->load->model('Topic_model');
                $isFoundationSchool = $this->Topic_model->is_foundation_school_category($category);
                if ($isFoundationSchool) {
                    $earnCoin = 0;
                }

                // Calculate user score for statistics (not for coins)
                    $quiz_zone_correct_answer_credit_score = is_settings('quiz_zone_correct_answer_credit_score');
                    $quiz_zone_wrong_answer_deduct_score = is_settings('quiz_zone_wrong_answer_deduct_score');
                    $userScore = ($correctAnswer * $quiz_zone_correct_answer_credit_score) - ($wrongAnswer * $quiz_zone_wrong_answer_deduct_score);

                $getLevelData = $this->db->select('level')->where('user_id', $user_id)->where('category', $category)->where('subcategory', $subcategory)->get('tbl_level')->row_array();
                    $nextUnlockLevel = $getLevelData['level'] ?? 0;

                if ($winningPer >= $quiz_winning_percentage) {
                    $ratio = $winningPer;

                    // NOTE: Leaderboard points are ONLY for Daily Rhapsody Contest (not regular training quizzes)
                    // set_monthly_leaderboard should be called from daily_contest endpoint when implemented
                    // if ($userScore) {
                    //     $this->set_monthly_leaderboard($user_id, $userScore);
                    // }
                    
                    $this->set_users_statistics($user_id, $category, $questions_answered, $correctAnswer, $ratio);

                    $updateLevel = $currentLevel + 1;
                    
                    // Update level if progressing
                    if ($updateLevel > $nextUnlockLevel && $updateLevel != $nextUnlockLevel) {
                        $this->set_quiz_level_data($user_id, 1, $updateLevel, $category, $subcategory);
                    }
                    
                    // Award 1 coin for 100% correct (no first-completion restriction, replay allowed)
                    if ($earnCoin) {
                        $this->set_coins($user_id, $earnCoin);
                        $title = 'perfectQuiz';
                        $status = 0; //add
                        $this->set_tracker_data($user_id, $earnCoin, $title, $status);
                    }
                }
                $this->set_badges($user_id, $this->DASHING_DEBUT);
                if (!$lifelineData) {
                    if ($minimumQuestionsForBadge >= $total_questions && $correctAnswer == $total_questions) {
                        $this->set_badges($user_id, $this->BRAINIAC, 1);
                    }
                }
                $this->db->where('id', $checkData['id'])->delete($table);
            }
            $resultData = [
                'user_id' => $user_id,
                'total_questions' => $total_questions ?? 0,
                'correctAnswer' => $correctAnswer ?? 0,
                'winningPer' => $winningPer ?? 0,
                'earnCoin' => (float)$earnCoin ?? 0,
                'userScore' => (float)$userScore ?? 0,
                'totalLevel' => (float)$totalLevel ?? 0,
                'currentLevel' => (float)$currentLevel ?? 0,
            ];
            return $resultData;
        } else {
            return false;
        }
    }

    //1.1
    function DailyQuiz($user_id, $table, $playQuestions)
    {
        $checkData = $this->db->where('user_id', $user_id)->get($table)->row_array();
        if ($checkData) {
            $setQuestions = json_decode($checkData['questions'], true);

            $setQuestionMap = [];
            $setQuestionMap = array_column($setQuestions, 'answer', 'id');
            $total_questions = count($setQuestions);
            $correctAnswer = 0;

            $play_questions = json_decode($playQuestions, true);
            foreach ($play_questions as $userAnswer) {
                $id = $userAnswer['id'];
                if (isset($setQuestionMap[$id]) && $setQuestionMap[$id] === $userAnswer['answer']) {
                    $correctAnswer++;
                }
            }
            $ratio = ($correctAnswer * 100) / $total_questions;

            $this->set_badge_counter($user_id, $this->THIRSTY, 0);

            $this->db->where('id', $checkData['id'])->delete($table);
            $resultData = [
                'user_id' => $user_id,
                'total_questions' => $total_questions,
                'correctAnswer' => $correctAnswer,
                'winningPer' => $ratio,
            ];
            return $resultData;
        } else {
            return false;
        }
    }

    // 1.2
    function trueFalse($user_id, $table, $playQuestions)
    {
        $checkData = $this->db->where('user_id', $user_id)->get($table)->row_array();
        if ($checkData) {
            $setQuestions = json_decode($checkData['questions'], true);

            $setQuestionMap = [];
            $setQuestionMap = array_column($setQuestions, 'answer', 'id');
            $total_questions = count($setQuestions);
            $correctAnswer = 0;

            $play_questions = json_decode($playQuestions, true);
            foreach ($play_questions as $userAnswer) {
                $id = $userAnswer['id'];
                if (isset($setQuestionMap[$id]) && $setQuestionMap[$id] === $userAnswer['answer']) {
                    $correctAnswer++;
                }
            }
            $ratio = ($correctAnswer * 100) / $total_questions;

            $this->db->where('id', $checkData['id'])->delete($table);
            $resultData = [
                'user_id' => $user_id,
                'total_questions' => $total_questions,
                'correctAnswer' => $correctAnswer,
                'winningPer' => $ratio,
            ];
            return $resultData;
        } else {
            return false;
        }
    }

    // 1.3
    function randomBattle($user_id, $match_id, $is_bot, $playQuestions)
    {
        $checkData = $this->db->where('match_id', $match_id)
            ->where('0 IN (set_user1, set_user2)', null, false)
            ->where("NOT FIND_IN_SET($user_id, CONCAT(set_user1, ',', set_user2))", null, false)
            ->get('tbl_battle_questions')->row_array();
        if ($checkData) {
            $userData = json_decode($playQuestions, true);
            $user1_id = $userData['user1_id'];
            $user2_id = $userData['user2_id'];
            $user1_data = $userData['user1_data'];
            $user2_data = $userData['user2_data'];

            $entry_coin = $checkData['entry_coin'];

            $earnCoin = 0;
            $user1CorrectAnswer = 0;
            $user1Points = 0;
            $user2CorrectAnswer = 0;
            $user2Points = 0;
            $winner_user_id = 0;
            $is_drawn = 0;
            $leftUser = 0;
            $score = 0;
            $user1_earnCoin = $user2_earnCoin = 0;

            $setQuestions = json_decode($checkData['questions'], true);

            $correct_answer_credit_score = is_settings('battle_mode_random_correct_answer_credit_score');
            $quickest_correct_answer_extra_score = is_settings('battle_mode_random_quickest_correct_answer_extra_score');
            $second_quickest_correct_answer_extra_score = is_settings('battle_mode_random_second_quickest_correct_answer_extra_score');

            $setQuestionMap = [];
            $setQuestionMap = array_column($setQuestions, 'answer', 'id');
            $total_questions = count($setQuestions);

            [$user1Points, $user1CorrectAnswer, $user1Quickest, $user1QuickestBonus, $user1SecondQuickestBonus] = $this->calculateBattleUserScore($user1_data, $setQuestionMap, $correct_answer_credit_score, $quickest_correct_answer_extra_score, $second_quickest_correct_answer_extra_score);
            [$user2Points, $user2CorrectAnswer, $user2Quickest, $user2QuickestBonus, $user2SecondQuickestBonus] = $this->calculateBattleUserScore($user2_data, $setQuestionMap, $correct_answer_credit_score, $quickest_correct_answer_extra_score, $second_quickest_correct_answer_extra_score);

            if ($user1Points > $user2Points) {
                $winner_user_id = $user1_id;
                $score = $user1Points;
            } else if ($user1Points < $user2Points) {
                $winner_user_id = $user2_id;
                $score = $user2Points;
            } else if (($user1Points == $user2Points) && ($user1_id && $user2_id)) {
                $is_drawn = 1;
                $score = ($user_id == $user1_id) ? $user1Points : (($user_id == $user2_id) ? $user2Points : 0);
            } else if ($user1_id == 0 || $user2_id == 0) {
                $leftUser = 1;
                if ($user1_id) {
                    $winner_user_id = $user1_id;
                    $score = $user1Points;
                } else if ($user2_id) {
                    $winner_user_id = $user2_id;
                    $score = $user2Points;
                }
            }

            if ($is_bot == 0 && $score) {
                $this->set_monthly_leaderboard($user_id, $score);
            }

            if ($is_drawn) {
                $user1_earnCoin = $user2_earnCoin = $entry_coin;
                if ($is_bot == 0) {
                    $this->set_coins($user_id, $entry_coin);
                    $this->set_tracker_data($user_id, $entry_coin, 'wonBattle', 0); //0: add
                    $this->set_users_battle_statistics($user1_id, $user2_id, $is_drawn, $winner_user_id);
                }
            } else if ($winner_user_id) {
                $earnCoinVal = $entry_coin * 2;
                $earnCoin = floor($earnCoinVal);
                if ($winner_user_id == $user1_id) {
                    $user1_earnCoin = $earnCoin;
                } else if ($winner_user_id == $user2_id) {
                    $user2_earnCoin = $earnCoin;
                }
                if ($is_bot == 0 && $user_id == $winner_user_id) {
                    $this->set_coins($user_id, $earnCoin);
                    $this->set_tracker_data($user_id, $earnCoin, 'wonBattle', 0); //0: add
                    $this->set_users_battle_statistics($user1_id, $user2_id, $is_drawn, $winner_user_id);
                }
            }

            if ($is_bot == 0) {
                if ($user1Quickest && $user_id == $user1_id) {
                    $this->set_badges($user_id, $this->ULTIMATE_PLAYER, 1);
                } else if ($user2Quickest && $user_id == $user2_id) {
                    $this->set_badges($user_id, $this->ULTIMATE_PLAYER, 1);
                }
            }

            if ($user_id == $user1_id) {
                $this->db->where('id', $checkData['id'])->update('tbl_battle_questions', ['set_user1' => $user_id]);
            } else if ($user_id == $user2_id) {
                $this->db->where('id', $checkData['id'])->update('tbl_battle_questions', ['set_user2' => $user_id]);
            }

            if ($user1_id == 0 && $user2_id != 0) {
                $this->db->where('id', $checkData['id'])->where('set_user1', 0)->where('set_user2!=', 0)->delete('tbl_battle_questions');
            } else if ($user2_id == 0 && $user1_id != 0) {
                $this->db->where('id', $checkData['id'])->where('set_user1!=', 0)->where('set_user2', 0)->delete('tbl_battle_questions');
            } else if ($user1_id == 0 && $user2_id == 0) {
                $this->db->where('id', $checkData['id'])->delete('tbl_battle_questions');
            } else {
                $this->db->where('id', $checkData['id'])->where('set_user1!=', 0)->where('set_user2!=', 0)->delete('tbl_battle_questions');
            }


            $user1Data = [
                'correctAnswer' => $user1CorrectAnswer ?? 0,
                'userPoints' => $user1Points ?? 0,
                'earnCoin' => (float)$user1_earnCoin ?? 0,
                'is_quickest' => $user1Quickest  ?? false,
                'quickest_bonus' => $user1QuickestBonus  ?? 0,
                'second_quickest_bonus' => $user1SecondQuickestBonus  ?? 0,
            ];

            $user2Data = [
                'correctAnswer' => $user2CorrectAnswer ?? 0,
                'userPoints' => $user2Points ?? 0,
                'earnCoin' => (float)$user2_earnCoin ?? 0,
                'is_quickest' => $user2Quickest ?? false,
                'quickest_bonus' => $user2QuickestBonus  ?? 0,
                'second_quickest_bonus' => $user2SecondQuickestBonus  ?? 0,
            ];

            $resultData = [
                'user_id' => $user_id,
                'entry_coin' => $entry_coin ?? 0,
                'total_questions' => $total_questions ?? 0,
                'user1_id' => $user1_id ?? 0,
                'user2_id' => $user2_id ?? 0,
                'winner_user_id' => $winner_user_id ?? 0,
                'winner_coin' => (float)$earnCoin ?? 0,
                'is_drawn' => $is_drawn ?? 0,
                'leftUser' => $leftUser ?? 0,
                'user1_data' => $user1Data ?? [],
                'user2_data' => $user2Data ?? [],
            ];
            return $resultData;
        } else {
            return false;
        }
    }

    // 1.4
    function oneVsOneBattle($user_id, $match_id, $playQuestions)
    {
        $checkData = $this->db->where('match_id', $match_id)
            ->where('0 IN (set_user1, set_user2)', null, false)
            ->where("NOT FIND_IN_SET($user_id, CONCAT(set_user1, ',', set_user2))", null, false)
            ->get('tbl_battle_questions')->row_array();
        if ($checkData) {
            $userData = json_decode($playQuestions, true);
            $user1_id = $userData['user1_id'];
            $user2_id = $userData['user2_id'];
            $user1_data = $userData['user1_data'];
            $user2_data = $userData['user2_data'];

            $entry_coin = $checkData['entry_coin'];

            $earnCoin = 0;
            $user1CorrectAnswer = 0;
            $user1Points = 0;
            $user2CorrectAnswer = 0;
            $user2Points = 0;
            $winner_user_id = 0;
            $is_drawn = 0;
            $leftUser = 0;
            $score = 0;
            $user1_earnCoin = $user2_earnCoin = 0;

            $setQuestions = json_decode($checkData['questions'], true);

            $correct_answer_credit_score = is_settings('battle_mode_one_correct_answer_credit_score');
            $quickest_correct_answer_extra_score = is_settings('battle_mode_one_quickest_correct_answer_extra_score');
            $second_quickest_correct_answer_extra_score = is_settings('battle_mode_one_second_quickest_correct_answer_extra_score');

            $setQuestionMap = [];
            $setQuestionMap = array_column($setQuestions, 'answer', 'id');
            $total_questions = count($setQuestions);

            [$user1Points, $user1CorrectAnswer, $user1Quickest, $user1QuickestBonus, $user1SecondQuickestBonus] = $this->calculateBattleUserScore($user1_data, $setQuestionMap, $correct_answer_credit_score, $quickest_correct_answer_extra_score, $second_quickest_correct_answer_extra_score);
            [$user2Points, $user2CorrectAnswer, $user2Quickest, $user2QuickestBonus, $user2SecondQuickestBonus] = $this->calculateBattleUserScore($user2_data, $setQuestionMap, $correct_answer_credit_score, $quickest_correct_answer_extra_score, $second_quickest_correct_answer_extra_score);

            if ($user1Points > $user2Points) {
                $winner_user_id = $user1_id;
                $score = $user1Points;
            } else if ($user1Points < $user2Points) {
                $winner_user_id = $user2_id;
                $score = $user2Points;
            } else if (($user1Points == $user2Points) && ($user1_id && $user2_id)) {
                $is_drawn = 1;
                $score = ($user_id == $user1_id) ? $user1Points : (($user_id == $user2_id) ? $user2Points : 0);
            } else if ($user1_id == 0 || $user2_id == 0) {
                $leftUser = 1;
                if ($user1_id) {
                    $winner_user_id = $user1_id;
                    $score = $user1Points;
                } else if ($user2_id) {
                    $winner_user_id = $user2_id;
                    $score = $user2Points;
                }
            }



            if ($score) {
                $this->set_monthly_leaderboard($user_id, $score);
            }

            if ($is_drawn) {
                $user1_earnCoin = $user2_earnCoin = $entry_coin;
                $this->set_coins($user_id, $entry_coin);
                $this->set_tracker_data($user_id, $entry_coin, 'wonBattle', 0); //0: add
                $this->set_users_battle_statistics($user1_id, $user2_id, $is_drawn, $winner_user_id);
            } else if ($winner_user_id) {
                $earnCoinVal = $entry_coin * 2;
                $earnCoin = floor($earnCoinVal);
                if ($winner_user_id == $user1_id) {
                    $user1_earnCoin = $earnCoin;
                } else if ($winner_user_id == $user2_id) {
                    $user2_earnCoin = $earnCoin;
                }
                if ($user_id == $winner_user_id) {
                    $this->set_coins($user_id, $earnCoin);
                    $this->set_tracker_data($user_id, $earnCoin, 'wonBattle', 0); //0: add
                    $this->set_users_battle_statistics($user1_id, $user2_id, $is_drawn, $winner_user_id);
                }
            }

            if ($user1Quickest && $user_id == $user1_id) {
                $this->set_badges($user_id, $this->ULTIMATE_PLAYER, 1);
            } else if ($user2Quickest && $user_id == $user2_id) {
                $this->set_badges($user_id, $this->ULTIMATE_PLAYER, 1);
            }

            if ($user_id == $user1_id) {
                $this->db->where('id', $checkData['id'])->update('tbl_battle_questions', ['set_user1' => $user_id]);
            } else if ($user_id == $user2_id) {
                $this->db->where('id', $checkData['id'])->update('tbl_battle_questions', ['set_user2' => $user_id]);
            }


            if ($user1_id == 0 && $user2_id != 0) {
                $this->db->where('id', $checkData['id'])->where('set_user1', 0)->where('set_user2!=', 0)->delete('tbl_battle_questions');
            } else if ($user2_id == 0 && $user1_id != 0) {
                $this->db->where('id', $checkData['id'])->where('set_user1!=', 0)->where('set_user2', 0)->delete('tbl_battle_questions');
            } else if ($user1_id == 0 && $user2_id == 0) {
                $this->db->where('id', $checkData['id'])->delete('tbl_battle_questions');
            } else {
                $this->db->where('id', $checkData['id'])->where('set_user1!=', 0)->where('set_user2!=', 0)->delete('tbl_battle_questions');
            }

            $user1Data = [
                'correctAnswer' => $user1CorrectAnswer ?? 0,
                'userPoints' => $user1Points ?? 0,
                'earnCoin' => (float)$user1_earnCoin ?? 0,
                'is_quickest' => $user1Quickest  ?? false,
                'quickest_bonus' => $user1QuickestBonus  ?? 0,
                'second_quickest_bonus' => $user1SecondQuickestBonus  ?? 0,
            ];

            $user2Data = [
                'correctAnswer' => $user2CorrectAnswer ?? 0,
                'userPoints' => $user2Points ?? 0,
                'earnCoin' => (float)$user2_earnCoin ?? 0,
                'is_quickest' => $user2Quickest ?? false,
                'quickest_bonus' => $user2QuickestBonus  ?? 0,
                'second_quickest_bonus' => $user2SecondQuickestBonus  ?? 0,
            ];

            $resultData = [
                'user_id' => $user_id,
                'entry_coin' => $entry_coin ?? 0,
                'total_questions' => $total_questions ?? 0,
                'user1_id' => $user1_id ?? 0,
                'user2_id' => $user2_id ?? 0,
                'is_drawn' => $is_drawn ?? 0,
                'leftUser' => $leftUser ?? 0,
                'winner_user_id' => $winner_user_id ?? 0,
                'winner_coin' => (float)$earnCoin ?? 0,
                'user1_data' => $user1Data ?? [],
                'user2_data' => $user2Data ?? [],
            ];
            return $resultData;
        } else {
            return false;
        }
    }

    // 1.5
    function groupBattle($user_id, $room_id, $playQuestions, $joined_users_count)
    {

        $batchSize = 500;

        do {
            $rows = $this->db->select('id')
                ->from('tbl_rooms')
                ->where('date_created <', $this->twoDayOldDateTime)
                ->limit($batchSize)
                ->get()
                ->result_array();

            $idsToDelete = array_column($rows, 'id');

            if (!empty($idsToDelete)) {
                $this->db->where_in('id', $idsToDelete);
                $this->db->delete('tbl_rooms');
            }

            $deletedRows = count($idsToDelete);
        } while ($deletedRows === $batchSize);

        $checkData = $this->db->where('room_id', $room_id)
            ->where('0 IN (set_user1, set_user2, set_user3, set_user4)', null, false)
            ->where("NOT FIND_IN_SET($user_id, CONCAT(set_user1, ',', set_user2, ',', set_user3, ',', set_user4))", null, false)
            ->get('tbl_rooms')->row_array();
        if ($checkData) {
            $userData = json_decode($playQuestions, true);
            $user1_id = $userData['user1_id'];
            $user2_id = $userData['user2_id'];
            $user3_id = $userData['user3_id'];
            $user4_id = $userData['user4_id'];
            $user1_data = $userData['user1_data'];
            $user2_data = $userData['user2_data'];
            $user3_data = $userData['user3_data'];
            $user4_data = $userData['user4_data'];

            $user1CorrectAnswer = $user2CorrectAnswer = $user3CorrectAnswer = $user4CorrectAnswer = 0;

            $setQuestions = json_decode($checkData['questions'], true);
            $setQuestionMap = [];
            $setQuestionMap = array_column($setQuestions, 'answer', 'id');
            $total_questions = count($setQuestions);

            [$user1CorrectAnswer] = $this->calculategroupBattleUserScore($user1_data, $setQuestionMap);
            [$user2CorrectAnswer] = $this->calculategroupBattleUserScore($user2_data, $setQuestionMap);
            [$user3CorrectAnswer] = $this->calculategroupBattleUserScore($user3_data, $setQuestionMap);
            [$user4CorrectAnswer] = $this->calculategroupBattleUserScore($user4_data, $setQuestionMap);

            $data = [
                $user1_id => $user1CorrectAnswer,
                $user2_id => $user2CorrectAnswer,
                $user3_id => $user3CorrectAnswer,
                $user4_id => $user4CorrectAnswer
            ];

            arsort($data);

            $ranks = [];
            $prevValue = null;
            $rank = 0;

            foreach ($data as $userId => $value) {
                if ($value !== $prevValue) {
                    $rank++;
                }
                if ($userId != 0) {
                    $ranks[$userId] = ['rank' => $rank, 'user_id' => $userId, 'correct_answer' => $value];
                }
                $prevValue = $value;
            }

            $total_user_count = count($ranks) ?? 0;
            $firstRankWinners = [];
            foreach ($ranks as $userId => $item) {
                if ($item['rank'] === 1 && $userId != 0) {
                    $firstRankWinners[] = $userId;
                }
            }

            $totalWinner = count($firstRankWinners);
            $entry_coin = $checkData['entry_coin'];
            $earnCoin =  ($totalWinner > 0) ? floor($entry_coin * ($joined_users_count / $totalWinner)) : 0;
            if ($earnCoin) {
                foreach ($firstRankWinners as $winnerUser) {
                    if ($winnerUser == $user_id) {
                        $this->set_coins($user_id, $earnCoin);
                        $this->set_tracker_data($user_id, $earnCoin, 'wonGroupBattle', 0);
                        $this->set_badges($user_id, $this->CLASH_WINNER, 0);
                        break;
                    }
                }
            }


            if ($user_id == $user1_id) {
                $this->db->where('room_id', $room_id)->update('tbl_rooms', ['set_user1' => $user_id]);
            } else if ($user_id == $user2_id) {
                $this->db->where('room_id', $room_id)->update('tbl_rooms', ['set_user2' => $user_id]);
            } else if ($user_id == $user3_id) {
                $this->db->where('room_id', $room_id)->update('tbl_rooms', ['set_user3' => $user_id]);
            } else if ($user_id == $user4_id) {
                $this->db->where('room_id', $room_id)->update('tbl_rooms', ['set_user4' => $user_id]);
            }

            $sql = "DELETE FROM tbl_rooms WHERE room_id = ? AND ((set_user1 != 0) + (set_user2 != 0) + (set_user3 != 0) + (set_user4 != 0)) >= ?";
            $this->db->query($sql, [$room_id, $total_user_count]);

            $resultData = [
                'user_id' => $user_id,
                'total_questions' => $total_questions ?? 0,
                'user1_id' => $user1_id ?? 0,
                'user2_id' => $user2_id ?? 0,
                'user3_id' => $user3_id ?? 0,
                'user4_id' => $user4_id ?? 0,
                'total_user_count' => $total_user_count ?? 0,
                'entry_coin' => $entry_coin ?? 0,
                'totalWinner' => $totalWinner ?? 0,
                'joined_users_count' => $joined_users_count ?? 0,
                'winner_score' => $earnCoin ?? 0,
                'winner' => $firstRankWinners ?? [],
                'user_rank' => $ranks ?? 0,
            ];
            return $resultData;
        } else {
            return false;
        }
    }

    function calculateBattleUserScore($userData, $setQuestionMap, $correct_answer_credit_score, $quickest_bonus, $second_quickest_bonus)
    {
        $points = 0;
        $correctAnswers = 0;
        $allQuickest = true;
        $quikest = 0;
        $second_quikest = 0;

        foreach ($userData as $answer) {
            $id = $answer['id'];
            $time = $answer['second'];

            if (isset($setQuestionMap[$id]) && $setQuestionMap[$id] === $answer['answer']) {
                $correctAnswers++;
                if ($time <= 2) {
                    $quikest += $quickest_bonus;
                    $points += $correct_answer_credit_score + $quickest_bonus;
                } elseif ($time <= 4) {
                    $second_quikest += $second_quickest_bonus;
                    $points += $correct_answer_credit_score + $second_quickest_bonus;
                } else {
                    $points += $correct_answer_credit_score;
                    $allQuickest = false;
                    $quikest = 0;
                    $second_quikest = 0;
                }
            }
        }
        if ($correctAnswers === 0 || (count($userData) != $correctAnswers)) {
            $allQuickest = false;
        }
        return [$points, $correctAnswers, $allQuickest, $quikest, $second_quikest];
    }

    function calculategroupBattleUserScore($userData, $setQuestionMap)
    {
        $correctAnswers = 0;

        if ($userData) {
            foreach ($userData as $answer) {
                $id = $answer['id'];

                if (isset($setQuestionMap[$id]) && $setQuestionMap[$id] === $answer['answer']) {
                    $correctAnswers++;
                }
            }
        }
        return [$correctAnswers];
    }

    // 2
    function funNLearn($user_id, $table, $category, $subcategory, $playQuestions, $totalPlayTime)
    {
        $checkData = $this->db->where('user_id', $user_id)->get($table)->row_array();
        if ($checkData) {
            $setQuestions = json_decode($checkData['questions'], true);
            $type_id = 0;
            $type_id = $setQuestions[0]['fun_n_learn_id'];

            $earnCoin = $userScore = 0;

            $setQuestionMap = [];
            $setQuestionMap = array_column($setQuestions, 'answer', 'id');
            $total_questions = count($setQuestions);
            $correctAnswer = 0;

            $play_questions = json_decode($playQuestions, true);
            foreach ($play_questions as $userAnswer) {
                $id = $userAnswer['id'];
                if (isset($setQuestionMap[$id]) && $setQuestionMap[$id] === $userAnswer['answer']) {
                    $correctAnswer++;
                }
            }
            $quiz_winning_percentage = is_settings('quiz_winning_percentage');
            $winningPer = ($correctAnswer * 100) / $total_questions;

            if ($winningPer >= $quiz_winning_percentage) {
                $ratio = $winningPer;

                $questions_answered = count($play_questions);
                $this->set_users_statistics($user_id, $category, $questions_answered, $correctAnswer,  $ratio);
                $type = 2;
                $res = $this->db->where('user_id', $user_id)->where('type', $type)->where('type_id', $type_id)->where('category', $category)->where('subcategory', $subcategory)->get('tbl_quiz_categories')->result_array();
                if (empty($res)) {
                    $wrongAnswer = $total_questions - $correctAnswer;
                    $minimum_coins_winning_percentage = is_settings('minimum_coins_winning_percentage');
                    $maximum_winning_coins = is_settings('maximum_winning_coins');
                    $fun_n_learn_quiz_correct_answer_credit_score = is_settings('fun_n_learn_quiz_correct_answer_credit_score');
                    $fun_n_learn_quiz_wrong_answer_deduct_score = is_settings('fun_n_learn_quiz_wrong_answer_deduct_score');
                    if ($winningPer >= $minimum_coins_winning_percentage) {
                        $earnCoin = $maximum_winning_coins;
                    } else {
                        $earnCoin = ($maximum_winning_coins - (($minimum_coins_winning_percentage - $winningPer) / 10));
                    }
                    $userScore = ($correctAnswer * $fun_n_learn_quiz_correct_answer_credit_score) - ($wrongAnswer * $fun_n_learn_quiz_wrong_answer_deduct_score);
                    $frm_data = array(
                        'user_id' => $user_id,
                        'type' => $type,
                        'category' => $category,
                        'subcategory' => $subcategory,
                        'type_id' => $type_id,
                    );
                    $this->db->insert('tbl_quiz_categories', $frm_data);
                    if ($userScore) {
                        $this->set_monthly_leaderboard($user_id, $userScore);
                    }
                    $earnCoin = floor($earnCoin);
                    if ($earnCoin) {
                        $this->set_coins($user_id, $earnCoin);
                        $title = 'wonFunNLearn';
                        $status = 0; //add
                        $this->set_tracker_data($user_id, $earnCoin, $title, $status);
                    } else {
                        $earnCoin = 0;
                    }

                    $badgeUnlock = $this->db->select('id,flashback')->where('user_id', $user_id)->get('tbl_users_badges')->row_array();
                    if ($badgeUnlock && ($badgeUnlock['flashback'] == 0)) {
                        $timerPerQuestion = is_settings('fun_and_learn_time_in_seconds') ?? 0;
                        $idealTimeInSeconds = ($total_questions * $timerPerQuestion);
                        if (($total_questions >= 5) && ($total_questions == $correctAnswer) && ($totalPlayTime <= $idealTimeInSeconds)) {
                            $this->set_badges($user_id, $this->FLASHBACK, 1);
                        }
                    }
                }
            }

            $this->db->where('id', $checkData['id'])->delete($table);

            $resultData = [
                'user_id' => $user_id,
                'total_questions' => $total_questions ?? 0,
                'correctAnswer' => $correctAnswer ?? 0,
                'winningPer' => $winningPer ?? 0,
                'earnCoin' => (float)$earnCoin ?? 0,
                'userScore' => (float)$userScore ?? 0
            ];
            return $resultData;
        } else {
            return false;
        }
    }

    // 3
    function guessTheWord($user_id, $table, $category, $subcategory, $playQuestions, $totalPlayTime, $hintUsed)
    {
        $checkData = $this->db->where('user_id', $user_id)->get($table)->row_array();
        if ($checkData) {
            $setQuestions = json_decode($checkData['questions'], true);

            $setQuestionMap = [];
            $setQuestionMap = array_column($setQuestions, 'answer', 'id');
            $total_questions = count($setQuestions);
            $correctAnswer = 0;

            $play_questions = json_decode($playQuestions, true);
            foreach ($play_questions as $userAnswer) {
                $id = $userAnswer['id'];
                if (isset($setQuestionMap[$id]) && strtolower($setQuestionMap[$id]) === strtolower($userAnswer['answer'])) {
                    $correctAnswer++;
                }
            }
            $questions_answered = count($play_questions);
            $quiz_winning_percentage = is_settings('quiz_winning_percentage');
            $winningPer = ($correctAnswer * 100) / $total_questions;

            if ($hintUsed) {
                $guess_the_word_hint_deduct_coin = is_settings('guess_the_word_hint_deduct_coin');
                $hint_deduct_coin = $guess_the_word_hint_deduct_coin ? ($hintUsed * $guess_the_word_hint_deduct_coin) : 0;
                $deduct_coin = $hint_deduct_coin ? ('-' . $hint_deduct_coin) : 0;
                $this->set_coins($user_id, $deduct_coin);
                $title = 'usedHintLifeline';
                $status = 1; //deduct
                $this->set_tracker_data($user_id, $deduct_coin, $title, $status);
            }
            $earnCoin = $userScore = 0;

            if ($winningPer >= $quiz_winning_percentage) {
                $ratio = $winningPer;
                $this->set_users_statistics($user_id, $category, $questions_answered, $correctAnswer,  $ratio);
                $type = 3;
                $type_id = 0;
                $res = $this->db->where('user_id', $user_id)->where('type', $type)->where('type_id', $type_id)->where('category', $category)->where('subcategory', $subcategory)->get('tbl_quiz_categories')->result_array();
                if (empty($res)) {
                    $wrongAnswer = $total_questions - $correctAnswer;
                    $minimum_coins_winning_percentage = is_settings('minimum_coins_winning_percentage');
                    $maximum_winning_coins = is_settings('guess_the_word_max_winning_coin');
                    $guess_the_word_correct_answer_credit_score = is_settings('guess_the_word_correct_answer_credit_score');
                    $guess_the_word_wrong_answer_deduct_score = is_settings('guess_the_word_wrong_answer_deduct_score');
                    if ($winningPer >= $minimum_coins_winning_percentage) {
                        $earnCoin = $maximum_winning_coins;
                    } else {
                        $earnCoin = ($maximum_winning_coins - (($minimum_coins_winning_percentage - $winningPer) / 10));
                    }
                    $userScore = ($correctAnswer * $guess_the_word_correct_answer_credit_score) - ($wrongAnswer * $guess_the_word_wrong_answer_deduct_score);
                    $frm_data = array(
                        'user_id' => $user_id,
                        'type' => $type,
                        'category' => $category,
                        'subcategory' => $subcategory,
                        'type_id' => $type_id,
                    );
                    $this->db->insert('tbl_quiz_categories', $frm_data);

                    if ($userScore) {
                        $this->set_monthly_leaderboard($user_id, $userScore);
                    }
                    $earnCoin = floor($earnCoin);
                    if ($earnCoin) {
                        $this->set_coins($user_id, $earnCoin);
                        $title = 'wonGuessTheWord';
                        $status = 0; //add
                        $this->set_tracker_data($user_id, $earnCoin, $title, $status);
                    } else {
                        $earnCoin = 0;
                    }

                    if (!$hintUsed) {
                        $badgeUnlock = $this->db->select('id,super_sonic')->where('user_id', $user_id)->get('tbl_users_badges')->row_array();
                        if ($badgeUnlock && ($badgeUnlock['super_sonic'] == 0)) {
                            $timerPerQuestion = is_settings('guess_the_word_seconds') ?? 0;
                            $idealTimeInSeconds = ($total_questions * $timerPerQuestion);
                            if (($total_questions >= 5) &&  ($totalPlayTime <= $idealTimeInSeconds)) {
                                $this->set_badges($user_id, $this->SUPER_SONIC, 1);
                            }
                        }
                    }
                }
            }

            $this->db->where('id', $checkData['id'])->delete($table);

            $resultData = [
                'user_id' => $user_id,
                'total_questions' => $total_questions ?? 0,
                'correctAnswer' => $correctAnswer ?? 0,
                'winningPer' => $winningPer ?? 0,
                'earnCoin' => (float)$earnCoin ?? 0,
                'userScore' => (float)$userScore ?? 0,
            ];
            return $resultData;
        } else {
            return false;
        }
    }

    // 4
    function audioQuiz($user_id, $table, $category, $subcategory, $playQuestions)
    {
        $checkData = $this->db->where('user_id', $user_id)->get($table)->row_array();
        if ($checkData) {
            $setQuestions = json_decode($checkData['questions'], true);

            $earnCoin = $userScore = 0;

            $setQuestionMap = [];
            $setQuestionMap = array_column($setQuestions, 'answer', 'id');
            $total_questions = count($setQuestions);
            $correctAnswer = 0;

            $play_questions = json_decode($playQuestions, true);
            foreach ($play_questions as $userAnswer) {
                $id = $userAnswer['id'];
                if (isset($setQuestionMap[$id]) && $setQuestionMap[$id] === $userAnswer['answer']) {
                    $correctAnswer++;
                }
            }
            $quiz_winning_percentage = is_settings('quiz_winning_percentage');
            $winningPer = ($correctAnswer * 100) / $total_questions;

            if ($winningPer >= $quiz_winning_percentage) {
                $ratio = $winningPer;
                $questions_answered = count($play_questions);
                $this->set_users_statistics($user_id, $category, $questions_answered, $correctAnswer,  $ratio);
                $type = 4;
                $type_id = 0;
                $res = $this->db->where('user_id', $user_id)->where('type', $type)->where('type_id', $type_id)->where('category', $category)->where('subcategory', $subcategory)->get('tbl_quiz_categories')->result_array();
                if (empty($res)) {
                    $wrongAnswer = $total_questions - $correctAnswer;
                    $minimum_coins_winning_percentage = is_settings('minimum_coins_winning_percentage');
                    $maximum_winning_coins = is_settings('maximum_winning_coins');
                    $audio_quiz_correct_answer_credit_score = is_settings('audio_quiz_correct_answer_credit_score');
                    $audio_quiz_wrong_answer_deduct_score = is_settings('audio_quiz_wrong_answer_deduct_score');
                    if ($winningPer >= $minimum_coins_winning_percentage) {
                        $earnCoin = $maximum_winning_coins;
                    } else {
                        $earnCoin = ($maximum_winning_coins - (($minimum_coins_winning_percentage - $winningPer) / 10));
                    }

                    $userScore = ($correctAnswer * $audio_quiz_correct_answer_credit_score) - ($wrongAnswer * $audio_quiz_wrong_answer_deduct_score);
                    $frm_data = array(
                        'user_id' => $user_id,
                        'type' => $type,
                        'category' => $category,
                        'subcategory' => $subcategory,
                        'type_id' => $type_id,
                    );
                    $this->db->insert('tbl_quiz_categories', $frm_data);
                    if ($userScore) {
                        $this->set_monthly_leaderboard($user_id, $userScore);
                    }
                    $earnCoin = floor($earnCoin);
                    if ($earnCoin) {
                        $this->set_coins($user_id, $earnCoin);
                        $title = 'wonAudioQuiz';
                        $status = 0; //add
                        $this->set_tracker_data($user_id, $earnCoin, $title, $status);
                    } else {
                        $earnCoin = 0;
                    }
                }
            }

            $this->db->where('id', $checkData['id'])->delete($table);

            $resultData = [
                'user_id' => $user_id,
                'total_questions' => $total_questions ?? 0,
                'correctAnswer' => $correctAnswer ?? 0,
                'winningPer' => $winningPer ?? 0,
                'earnCoin' => (float)$earnCoin ?? 0,
                'userScore' => (float)$userScore ?? 0
            ];
            return $resultData;
        } else {
            return false;
        }
    }

    // 5
    function mathsQuiz($user_id, $table, $category, $subcategory, $playQuestions)
    {
        $checkData = $this->db->where('user_id', $user_id)->get($table)->row_array();
        if ($checkData) {
            $setQuestions = json_decode($checkData['questions'], true);

            $earnCoin = $userScore = 0;

            $setQuestionMap = [];
            $setQuestionMap = array_column($setQuestions, 'answer', 'id');
            $total_questions = count($setQuestions);
            $correctAnswer = 0;

            $play_questions = json_decode($playQuestions, true);
            foreach ($play_questions as $userAnswer) {
                $id = $userAnswer['id'];
                if (isset($setQuestionMap[$id]) && $setQuestionMap[$id] === $userAnswer['answer']) {
                    $correctAnswer++;
                }
            }
            $quiz_winning_percentage = is_settings('quiz_winning_percentage');
            $winningPer = ($correctAnswer * 100) / $total_questions;

            if ($winningPer >= $quiz_winning_percentage) {
                $ratio = $winningPer;
                $questions_answered = count($play_questions);
                $this->set_users_statistics($user_id, $category, $questions_answered, $correctAnswer,  $ratio);
                $type = 5;
                $type_id = 0;
                $res = $this->db->where('user_id', $user_id)->where('type', $type)->where('type_id', $type_id)->where('category', $category)->where('subcategory', $subcategory)->get('tbl_quiz_categories')->result_array();
                if (empty($res)) {
                    $wrongAnswer = $total_questions - $correctAnswer;
                    $minimum_coins_winning_percentage = is_settings('minimum_coins_winning_percentage');
                    $maximum_winning_coins = is_settings('maximum_winning_coins');
                    $maths_quiz_correct_answer_credit_score = is_settings('maths_quiz_correct_answer_credit_score');
                    $maths_quiz_wrong_answer_deduct_score = is_settings('maths_quiz_wrong_answer_deduct_score');
                    if ($winningPer >= $minimum_coins_winning_percentage) {
                        $earnCoin = $maximum_winning_coins;
                    } else {
                        $earnCoin = ($maximum_winning_coins - (($minimum_coins_winning_percentage - $winningPer) / 10));
                    }
                    $userScore = ($correctAnswer * $maths_quiz_correct_answer_credit_score) - ($wrongAnswer * $maths_quiz_wrong_answer_deduct_score);

                    $frm_data = array(
                        'user_id' => $user_id,
                        'type' => $type,
                        'category' => $category,
                        'subcategory' => $subcategory,
                        'type_id' => $type_id,
                    );
                    $this->db->insert('tbl_quiz_categories', $frm_data);
                    if ($userScore) {
                        $this->set_monthly_leaderboard($user_id, $userScore);
                    }
                    $earnCoin = floor($earnCoin);
                    if ($earnCoin) {
                        $this->set_coins($user_id, $earnCoin);
                        $title = 'wonMathQuiz';
                        $status = 0; //add
                        $this->set_tracker_data($user_id, $earnCoin, $title, $status);
                    } else {
                        $earnCoin = 0;
                    }
                }
            }

            $this->db->where('id', $checkData['id'])->delete($table);

            $resultData = [
                'user_id' => $user_id,
                'total_questions' => $total_questions ?? 0,
                'correctAnswer' => $correctAnswer ?? 0,
                'winningPer' => $winningPer ?? 0,
                'earnCoin' => (float)$earnCoin ?? 0,
                'userScore' => (float)$userScore ?? 0
            ];
            return $resultData;
        } else {
            return false;
        }
    }

    // 6
    function multiMatch($user_id, $table, $category, $subcategory, $playQuestions)
    {
        $checkData = $this->db->where('user_id', $user_id)->get($table)->row_array();
        if ($checkData) {
            $setQuestions = json_decode($checkData['questions'], true);
            $currentLevel = $setQuestions[0]['level'];
            $getMaxLevelData = $this->db->select_max('level')->where('category', $category)->where('subcategory', $subcategory)->get('tbl_multi_match')->row_array();
            $totalLevel = $getMaxLevelData['level'];
            $earnCoin = $userScore = 0;

            if ($currentLevel <= $totalLevel) {
                $setQuestionMap = [];
                $setQuestionMap = array_column($setQuestions, 'answer', 'id');
                $total_questions = count($setQuestions);
                $correctAnswer = 0;

                $play_questions = json_decode($playQuestions, true);
                foreach ($play_questions as $userAnswer) {
                    $id = $userAnswer['id'];
                    if (isset($setQuestionMap[$id]) && $setQuestionMap[$id] === $userAnswer['answer']) {
                        $correctAnswer++;
                    }
                }
                $quiz_winning_percentage = is_settings('quiz_winning_percentage');
                $winningPer = ($correctAnswer * 100) / $total_questions;


                if ($winningPer >= $quiz_winning_percentage) {
                    $wrongAnswer = $total_questions - $correctAnswer;
                    $minimum_coins_winning_percentage = is_settings('minimum_coins_winning_percentage');
                    $maximum_winning_coins = is_settings('maximum_winning_coins');
                    $multi_match_correct_answer_credit_score = is_settings('multi_match_correct_answer_credit_score');
                    $multi_match_wrong_answer_deduct_score = is_settings('multi_match_wrong_answer_deduct_score');
                    if ($winningPer >= $minimum_coins_winning_percentage) {
                        $earnCoin = $maximum_winning_coins;
                    } else {
                        $earnCoin = ($maximum_winning_coins - (($minimum_coins_winning_percentage - $winningPer) / 10));
                    }
                    $userScore = ($correctAnswer * $multi_match_correct_answer_credit_score) - ($wrongAnswer * $multi_match_wrong_answer_deduct_score);
                    $getLevelData = $this->db->select('level')->where('user_id', $user_id)->where('category', $category)->where('subcategory', $subcategory)->get('tbl_level')->row_array();

                    $nextUnlockLevel = $getLevelData['level'] ?? 0;

                    if ($userScore) {
                        $this->set_monthly_leaderboard($user_id, $userScore);
                    }

                    $updateLevel = $currentLevel + 1;
                    $earnCoin = floor($earnCoin);
                    if ($earnCoin && ($updateLevel > $nextUnlockLevel && $updateLevel != $nextUnlockLevel)) {
                        $this->set_quiz_level_data($user_id, 6, $updateLevel, $category, $subcategory);
                        $this->set_coins($user_id, $earnCoin);
                        $title = 'wonMultiMatch';
                        $status = 0; //add
                        $this->set_tracker_data($user_id, $earnCoin, $title, $status);
                    } else {
                        $earnCoin = 0;
                    }
                }

                $this->db->where('id', $checkData['id'])->delete($table);
            }
            $resultData = [
                'user_id' => $user_id,
                'total_questions' => $total_questions ?? 0,
                'correctAnswer' => $correctAnswer ?? 0,
                'winningPer' => $winningPer ?? 0,
                'earnCoin' => (float)$earnCoin ?? 0,
                'userScore' => (float)$userScore ?? 0,
                'totalLevel' => (float)$totalLevel ?? 0,
                'currentLevel' => (float)$currentLevel ?? 0,
            ];
            return $resultData;
        } else {
            return false;
        }
    }

    //contest
    function contest($user_id, $table, $playQuestions)
    {
        $checkData = $this->db->where('user_id', $user_id)->get($table)->row_array();
        if ($checkData) {
            $setQuestions = json_decode($checkData['questions'], true);
            $contest_id = $setQuestions[0]['contest_id'];
            $earnCoin = $userScore = 0;
            $correctAnswer = 0;

            $getContest = $this->db->where('contest_id', $contest_id)->where('user_id', $user_id)->get('tbl_contest_leaderboard')->row_array();

            if (empty($getContest)) {
                $setQuestionMap = [];
                $setQuestionMap = array_column($setQuestions, 'answer', 'id');
                $total_questions = count($setQuestions);

                $play_questions = json_decode($playQuestions, true);
                foreach ($play_questions as $userAnswer) {
                    $id = $userAnswer['id'];
                    if (isset($setQuestionMap[$id]) && $setQuestionMap[$id] === $userAnswer['answer']) {
                        $correctAnswer++;
                    }
                }
                $questions_answered = count($play_questions);
                $winningPer = ($correctAnswer * 100) / $total_questions;

                $wrongAnswer = $total_questions - $correctAnswer;
                $contest_mode_correct_credit_score = is_settings('contest_mode_correct_credit_score');
                $contest_mode_wrong_deduct_score = is_settings('contest_mode_wrong_deduct_score');

                $userScore = ($correctAnswer * $contest_mode_correct_credit_score) - ($wrongAnswer * $contest_mode_wrong_deduct_score);

                if ($userScore) {
                    $this->set_monthly_leaderboard($user_id, $userScore);
                }

                $data = array(
                    'user_id' => $user_id,
                    'contest_id' => $contest_id,
                    'questions_attended' => $questions_answered,
                    'correct_answers' => $correctAnswer,
                    'score' => $userScore,
                    'last_updated' => $this->toDateTime,
                    'date_created' => $this->toDateTime,
                );
                $this->db->insert('tbl_contest_leaderboard', $data);
            }


            $this->db->where('id', $checkData['id'])->delete($table);

            $resultData = [
                'user_id' => $user_id,
                'total_questions' => $total_questions ?? 0,
                'correctAnswer' => $correctAnswer ?? 0,
                'winningPer' => $winningPer ?? 0,
                'earnCoin' => (float)$earnCoin ?? 0,
                'userScore' => (float)$userScore ?? 0,
            ];
            return $resultData;
        } else {
            return false;
        }
    }

    public function getBadgeNotificationData($language, $type, $path, $sampleFile, $defaultFile)
    {
        $file = $path . $language . '.json';

        if (!file_exists($file) && $defaultFile) {
            $file = $path . $defaultFile;
            if (!file_exists($file)) {
                $file = $path . $sampleFile;
            }
        } else {
            $file = $path . $sampleFile;
        }

        $content = file_get_contents($file);
        $dataArray = json_decode($content, true);

        $badge_label = $type . '_label';
        $badge_note = $type . '_note';

        return [
            'notification_title' => $dataArray[$badge_label] ?? 'Congratulations!!',
            'notification_body' => $dataArray[$badge_note] ?? 'You have unlocked new badge.'
        ];
    }

    public function set_badges($user_id, $type, $counter = 0)
    {
        $res = $this->db->where('user_id', $user_id)->get('tbl_users_badges')->row_array();
        $counter_name = $type . '_counter';
        if (!empty($res)) {
            if ($res[$type] == 0 || $res[$type] == '0') {
                $res1 = $this->db->where('type', $type)->get('tbl_badges')->row_array();
                if (!empty($res1)) {
                    if ($counter == 0) {
                        $counter = $res1['badge_counter'];
                        $user_counter = $res[$counter_name];
                        $user_counter = $user_counter + 1;
                        if ($user_counter < $counter) {
                            $data = [$counter_name => $user_counter];
                            $this->db->where('user_id', $user_id)->update('tbl_users_badges', $data);
                        } else if (($counter == $user_counter) || $counter == 1) {
                            $power_elite_counter = $res['power_elite_counter'] + 1;
                            $this->set_power_elite_badge($user_id, $power_elite_counter);
                            $data1 = [
                                $counter_name => $user_counter,
                                $type => 1,
                            ];
                            $this->db->where('user_id', $user_id)->update('tbl_users_badges', $data1);
                            //send notification
                            $this->send_badges_notification($user_id, $type);
                        }
                    } else {
                        $power_elite_counter = $res['power_elite_counter'] + 1;
                        $this->set_power_elite_badge($user_id, $power_elite_counter);
                        $data1 = [
                            $type => 1,
                        ];
                        $this->db->where('user_id', $user_id)->update('tbl_users_badges', $data1);
                        //send notification
                        $this->send_badges_notification($user_id, $type);
                    }
                }
            }
        }
    }

    public function set_power_elite_badge($user_id, $counter)
    {
        $type = $this->POWER_ELITE;
        $res = $this->db->where('user_id', $user_id)->get('tbl_users_badges')->row_array();
        $user_conter = $type . '_counter';
        if (!empty($res)) {
            if ($res[$type] == 0 || $res[$type] == '0') {
                $res1 = $this->db->where('type', $type)->get('tbl_badges')->row_array();
                if (!empty($res1)) {
                    $badge_counter = $res1['badge_counter'];

                    if ($counter < $badge_counter) {
                        $data = [$user_conter => $counter];
                        $this->db->where('user_id', $user_id)->update('tbl_users_badges', $data);
                    }

                    if ($counter == $badge_counter) {
                        $data1 = [
                            $type . '_counter' => $counter,
                            $type => 1,
                        ];
                        $this->db->where('user_id', $user_id)->update('tbl_users_badges', $data1);
                        //send notification
                        $this->send_badges_notification($user_id, $type);
                    }
                }
            }
        }
    }

    public function set_badge_counter($user_id, $type)
    {
        $per_date = date('Y-m-d', strtotime("-1 days"));
        $res2 = $this->db->where('user_id', $user_id)->get('tbl_users_badges')->row_array();

        if (!empty($res2)) {
            if ($res2[$type] == 0 || $res2[$type] == '0') {
                $old_date = $res2[$type . '_date'];
                $old_counter = $res2[$type . '_counter'];
                if ($old_date == $per_date) {
                    $res1 = $this->db->where('type', $type)->get('tbl_badges')->row_array();
                    if (!empty($res1)) {
                        $badge_counter = $res1['badge_counter'];
                        $final_counter = $old_counter + 1;
                        if ($final_counter < $badge_counter) {
                            $data1 = [
                                $type . '_date' => $this->toDate,
                                $type . '_counter' => $final_counter,
                            ];
                            $this->db->where('user_id', $user_id)->update('tbl_users_badges', $data1);
                        }
                        if ($final_counter == $badge_counter) {
                            $this->set_badges($user_id, $type, 1);
                        }
                    }
                } else if ($old_date != $this->toDate) {
                    $data1 = [
                        $type . '_date' => $this->toDate,
                        $type . '_counter' => 1,
                    ];
                    $this->db->where('user_id', $user_id)->update('tbl_users_badges', $data1);
                    $res1 = $this->db->where('type', $type)->get('tbl_badges')->row_array();
                    $badge_counter = $res1['badge_counter'];
                    if ($badge_counter == 1) {
                        $this->set_badges($user_id, $type, 1);
                    }
                }
            }
        }
    }

    public function set_coins($user_id, $coins, $is_update = true, $type = 'elite')
    {
        $res = $this->db->where('id', $user_id)->get('tbl_users')->row_array();
        if (!empty($res)) {
            if ($is_update) {
                $net_coins = $res['coins'] + $coins;
                $data = [
                    'coins' => $net_coins,
                ];
                $this->db->where('id', $user_id)->update('tbl_users', $data);
            } else {
                $net_coins = $coins;
            }

            if ($type == 'elite') {
                $res2 = $this->db->where('user_id', $user_id)->get('tbl_users_badges')->row_array();
                if (!empty($res2)) {
                    if ($res2[$type] == 0 || $res2[$type] == '0') {
                        $res1 = $this->db->where('type', $type)->get('tbl_badges')->row_array();
                        if (!empty($res1)) {
                            $counter = $res1['badge_counter'];
                            if ($counter <= $net_coins) {
                                $this->set_badges($user_id, $this->ELITE, 1);
                            }
                        }
                    }
                }
            } else if ($type == 'sharing_caring') {
                $res2 = $this->db->where('user_id', $user_id)->get('tbl_users_badges')->row_array();
                if (!empty($res2)) {
                    if ($res2[$type] == 0 || $res2[$type] == '0') {
                        $res1 = $this->db->where('type', $type)->get('tbl_badges')->row_array();
                        if (!empty($res1)) {
                            $counter = $res1['badge_counter'];
                            if ($counter <= $net_coins) {
                                $this->set_badges($user_id, $this->SHARING_CARING, 1);
                            }
                        }
                    }
                }
            }
        }
    }

    public function set_badges_reward($user_id, $type)
    {
        $res = $this->db->where('user_id', $user_id)->get('tbl_users_badges')->row_array();
        if (!empty($res)) {
            if ($res[$type] == 1 || $res[$type] == '1') {
                $data1 = [
                    $type => 2,
                ];
                $this->db->where('user_id', $user_id)->update('tbl_users_badges', $data1);
            }
        }
    }

    public function send_badges_notification($user_id, $type)
    {
        $res = $this->db->select('id,fcm_id,web_fcm_id,app_language,web_language')->where('id', $user_id)->get('tbl_users')->row_array();
        $fcm_id = $res['fcm_id'];
        $web_fcm_id = $res['web_fcm_id'];

        $user_app_language = $res['app_language'];

        $get_app_default_language = $this->db->select('id,name,app_default')->where('app_default', 1)->get('tbl_upload_languages')->row_array();
        $default_app_language = $get_app_default_language['name'] ?? '';

        $notificationData = $this->getBadgeNotificationData($user_app_language, $type, APP_LANGUAGE_FILE_PATH, 'app_sample_file.json', $default_app_language);

        $notification_title_message = $notificationData['notification_title'] ?? 'Congratulations!!';
        $notification_body_message = $notificationData['notification_body'] ?? 'You have unlocked new badge.';
        $fcmMsg = array(
            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            'type' => 'badges',
            'badge_type' => $type,
            'title' => $notification_title_message,
            'body' => $notification_body_message,
        );

        if ($fcm_id && $fcm_id != '' && $fcm_id != 'empty') {
            $registrationID = explode(',', $fcm_id);
            $factory = (new Factory)->withServiceAccount('assets/firebase_config.json');
            $messaging = $factory->createMessaging();
            $message = CloudMessage::new();
            $message = $message->withNotification($fcmMsg)->withData($fcmMsg);
            $messaging->sendMulticast($message, $registrationID);
        }

        $user_web_language = $res['web_language'];

        $get_web_default_language = $this->db->select('id,name,web_default')->where('web_default', 1)->get('tbl_upload_languages')->row_array();
        $default_web_language = $get_web_default_language['name'] ?? '';

        $web_notificationData = $this->getBadgeNotificationData($user_web_language, $type, WEB_LANGUAGE_FILE_PATH, 'web_sample_file.json', $default_web_language);

        $web_notification_title_message = $web_notificationData['notification_title'] ?? 'Congratulations!!';
        $web_notification_body_message = $web_notificationData['notification_body'] ?? 'You have unlocked new badge.';
        $web_fcmMsg = array(
            'click_action' => 'WEB_NOTIFICATION_CLICK',
            'type' => 'badges',
            'badge_type' => $type,
            'title' => $web_notification_title_message,
            'body' => $web_notification_body_message,
        );

        if ($web_fcm_id && $web_fcm_id != '' && $web_fcm_id != 'empty') {
            $registrationID = explode(',', $web_fcm_id);
            $factory = (new Factory)->withServiceAccount('assets/firebase_config.json');
            $messaging = $factory->createMessaging();
            $message = CloudMessage::new();
            $message = $message->withNotification($web_fcmMsg)->withData($web_fcmMsg);
            $messaging->sendMulticast($message, $registrationID);
        }
    }

    public function set_tracker_data($user_id, $points, $type, $status)
    {
        $res = $this->db->select('firebase_id, coins')->where('id', $user_id)->get('tbl_users')->row_array();
        if (!empty($res)) {
            $firebase_id = $res['firebase_id'];
            $tracker_res = $this->db->where('user_id', $user_id)->where('uid', $firebase_id)->get('tbl_tracker')->row_array();
            if (empty($tracker_res) && !empty($res['coins'])) {
                $coins = $res['coins'] - $points;
                if ($coins != 0 || $coins != "0") {
                    $tracker_data = [
                        'user_id' => $user_id,
                        'uid' => $firebase_id,
                        'points' => $coins,
                        'type' => $this->opening_msg,
                        'status' => 1,
                        'date' => $this->toDateTime,
                    ];
                    $this->db->insert('tbl_tracker', $tracker_data);
                }
            }

            $tracker_data = [
                'user_id' => $user_id,
                'uid' => $firebase_id,
                'points' => $points,
                'type' => $type,
                'status' => $status,
                'date' => $this->toDateTime,
            ];
            $this->db->insert('tbl_tracker', $tracker_data);
        }
    }

    /**
     * @deprecated No longer used. Leaderboard now uses tbl_contest_leaderboard exclusively.
     * Kept for backward compatibility - does nothing.
     */
    public function set_monthly_leaderboard($user_id, $score)
    {
        // DEPRECATED: Leaderboard now uses tbl_contest_leaderboard exclusively
        // This function is kept for backward compatibility but does nothing
        return;
    }

    public function random_string($length)
    {
        $characters = 'abC0DefGHij1KLMnop2qR3STu4vwxY5ZABc6dEFgh7IJ8klm9NOPQrstUVWXyz';
        $string = '';
        for ($i = 0; $i < $length; $i++) {
            $string .= $characters[mt_rand(0, strlen($characters) - 1)];
        }
        return $string;
    }

    public function checkBattleExists($match_id)
    {
        $res = $this->db->where('match_id', $match_id)->get('tbl_battle_questions')->result_array();
        if (empty($res)) {
            return false;
        } else {
            return true;
        }
    }

    public function verify_user($firebase_id)
    {
        $firebase_config = 'assets/firebase_config.json';
        if (file_exists($firebase_config)) {
            $factory = (new Factory)->withServiceAccount($firebase_config);
            $firebaseauth = $factory->createAuth();
            try {
                $user = (array) $firebaseauth->getUser($firebase_id);
                if ($user['uid'] == $firebase_id) {
                    return true;
                } else {
                    return false;
                }
            } catch (\Kreait\Firebase\Exception\Auth\UserNotFound $e) {
                return false;
            }
        } else {
            return false;
        }
    }

    public function generate_token($user_id, $firebase_id)
    {
        $payload = [
            'iat' => time(), /* issued at time */
            'iss' => 'Quiz',
            'exp' => time() + (30 * 60 * 60 * 24), /* expires after 1 minute */
            'user_id' => $user_id,
            'firebase_id' => $firebase_id,
            'sub' => 'Quiz Authentication',
        ];
        return $this->jwt->encode($payload, $this->JWT_SECRET_KEY);
    }

    public function verify_token()
    {
        try {
            $token = $this->jwt->getBearerToken();
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
            return $response;
        }
        if (!empty($token)) {
            try {
                $res = $this->db->where('api_token', $token)->get('tbl_users')->row_array();
                if (empty($res)) {
                    $response['error'] = true;
                    $response['message'] = '129';
                    return $response;
                } else {
                    $payload = $this->jwt->decode($token, $this->JWT_SECRET_KEY, ['HS256']);
                    if ($payload) {
                        if (isset($payload->user_id) && isset($payload->firebase_id)) {
                            $response['error'] = false;
                            $response['user_id'] = $payload->user_id;
                            $response['firebase_id'] = $payload->firebase_id;
                            $response['status'] = $res['status'];
                            return $response;
                        } else {
                            $response['error'] = true;
                            $response['message'] = '129';
                            return $response;
                        }
                    } else {
                        $response['error'] = true;
                        $response['message'] = '129';
                        return $response;
                    }
                }
            } catch (Exception $e) {
                $response['error'] = true;
                $response['message'] = $e->getMessage();
                return $response;
            }
        } else {
            $response['error'] = true;
            $response['message'] = "125";
            return $response;
        }
    }

    public function encrypt_data($key, $text)
    {
        $iv = openssl_random_pseudo_bytes(16);
        $key .= "0000";
        $encrypted_data = openssl_encrypt($text, 'aes-256-cbc', $key, 0, $iv);
        $data = array("ciphertext" => $encrypted_data, "iv" => bin2hex($iv));
        return $data;
    }

    public function decrypt_data($key, $text, $iv)
    {
        $decrypted_data = '';
        if ($iv) {
            $key .= "0000";
            $decrypted_data = openssl_decrypt($text, 'aes-256-cbc', $key, 0, hex2bin($iv));
        }
        return $decrypted_data;
    }

    function suffleOptions($data, $firebase_id)
    {
        // Create an associative array of options
        $options = array(
            'optiona' => trim($data['optiona']),
            'optionb' => trim($data['optionb']),
        );
        if ($data['question_type'] == 1) {
            $options['optionc'] = trim($data['optionc']);
            $options['optiond'] = trim($data['optiond']);
            if (is_option_e_mode_enabled() && $data['optione'] != null) {
                $options['optione'] = trim($data['optione']);
            }
        }

        // Find the correct answer before shuffling
        $correctAnswer = 'option' . $data['answer'];
        $correctAnswerValue = $options[$correctAnswer];

        // Shuffle the options
        $shuffled_options = $options;
        if ($this->OPTION_SHUFFLE_MODE == 1) {
            shuffle($shuffled_options);
            // Assign the shuffled values back to the original options
            $keys = array_keys($options);
            for ($j = 0; $j < count($keys); $j++) {
                $data[$keys[$j]] = $shuffled_options[$j];
                // Update the correct answer after shuffling
                if ($shuffled_options[$j] == $correctAnswerValue) {
                    $suffledAnswer = chr(ord('a') + $j);  // converts the index $j to a letter like 0 to 'a', 1 to 'b', etc.
                    $data['session_answer'] = $suffledAnswer;
                    $data['answer'] = $this->encrypt_data($firebase_id, $suffledAnswer);
                }
            }
        } else {
            $data['session_answer'] = trim($data['answer']);
            $data['answer'] = $this->encrypt_data($firebase_id, trim($data['answer']));
        }
        return $data;
    }

    function getCategoryData($category, $categorySlug)
    {
        if ($category) {
            return $this->db->where('id', $category)->get('tbl_category')->row_array();
        } else if ($categorySlug) {
            return $this->db->where('slug', $categorySlug)->get('tbl_category')->row_array();
        }
        return null;
    }

    function getSubCategoryData($subCategory, $subCategorySlug)
    {
        if ($subCategory) {
            return $this->db->where('id', $subCategory)->get('tbl_subcategory')->row_array();
        } else if ($subCategorySlug) {
            return $this->db->where('slug', $subCategorySlug)->get('tbl_subcategory')->row_array();
        }
        return null;
    }

    function getQuestionData($subcategoryData, $categoryData)
    {
        if ($subcategoryData["id"] != 0) {
            return $this->db->query('select count(id) as no_of_que, MAX(level) as max_level from tbl_question where subcategory  = ' . $subcategoryData["id"])->row_array();
        } else {
            return $this->db->query('select count(id) as no_of_que, MAX(level) as max_level from tbl_question where category = ' . $categoryData["id"] . ' AND subcategory = 0')->row_array();
        }
    }

    function getMultiMatchQuestionData($subcategoryData, $categoryData)
    {
        if ($subcategoryData["id"] != 0) {
            return $this->db->query('select count(id) as no_of_que, MAX(level) as max_level from tbl_multi_match where subcategory  = ' . $subcategoryData["id"])->row_array();
        } else {
            return $this->db->query('select count(id) as no_of_que, MAX(level) as max_level from tbl_multi_match where category = ' . $categoryData["id"] . ' AND subcategory = 0')->row_array();
        }
    }

    function myGlobalRank($user_id)
    {
        // Base query - include ALL active users with 0 points if no entry
        $base_sql = "
            SELECT u.id as user_id, u.email, u.name, u.status, u.profile, 
                   COALESCE(SUM(m.score), 0) AS score, 
                   COALESCE(MAX(m.last_updated), NOW()) as last_updated 
            FROM tbl_users u 
            LEFT JOIN tbl_leaderboard_monthly m ON u.id = m.user_id
            WHERE u.status = 1 
            GROUP BY u.id, u.email, u.name, u.status, u.profile
            ORDER BY score DESC, last_updated ASC
        ";
        
        // Tied ranking query (same score = same rank)
        $ranked_sql = "
            SELECT r.*, 
                   @rank := IF(@prev_score = r.score, @rank, @row_num) as user_rank,
                   @row_num := @row_num + 1,
                   @prev_score := r.score
            FROM ($base_sql) r, 
                 (SELECT @rank := 0, @row_num := 1, @prev_score := NULL) init
        ";
        
        $sql = "SELECT * FROM ($ranked_sql) ranked WHERE ranked.user_id = ? LIMIT 1";
        $result = $this->db->query($sql, array($user_id));
        return $result->row_array();
    }

    // ============================================
    // TOPICS API ENDPOINTS
    // Added: 2025-12-27
    // ============================================

    /**
     * Get all available topics (Rhapsody, Foundation School)
     * POST /Api/get_topics
     */
    public function get_topics_post()
    {
        try {
            $this->load->model('Topic_model');
            $topics = $this->Topic_model->get_all_topics();

            if (!empty($topics)) {
                // Add image URLs
                for ($i = 0; $i < count($topics); $i++) {
                    $topics[$i]['image'] = $topics[$i]['image'] 
                        ? base_url() . 'images/topics/' . $topics[$i]['image'] 
                        : '';
                }
                $response['error'] = false;
                $response['data'] = $topics;
            } else {
                $response['error'] = true;
                $response['message'] = 'No topics found';
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Get topic details by ID or slug
     * POST /Api/get_topic
     * @param id or slug
     */
    public function get_topic_post()
    {
        try {
            $this->load->model('Topic_model');
            $topic = null;

            if ($this->post('id')) {
                $topic = $this->Topic_model->get_topic_by_id($this->post('id'));
            } else if ($this->post('slug')) {
                $topic = $this->Topic_model->get_topic_by_slug($this->post('slug'));
            }

            if ($topic) {
                $topic['image'] = $topic['image'] 
                    ? base_url() . 'images/topics/' . $topic['image'] 
                    : '';
                $response['error'] = false;
                $response['data'] = $topic;
            } else {
                $response['error'] = true;
                $response['message'] = 'Topic not found';
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Get categories for a specific topic
     * POST /Api/get_topic_categories
     * @param topic_id or topic_slug
     * @param parent_id (optional) - for hierarchical navigation
     * @param age_group (optional) - kids, teens, adults, all
     */
    public function get_topic_categories_post()
    {
        try {
            $this->load->model('Topic_model');
            
            $topic_id = null;
            if ($this->post('topic_id')) {
                $topic_id = $this->post('topic_id');
            } else if ($this->post('topic_slug')) {
                $topic = $this->Topic_model->get_topic_by_slug($this->post('topic_slug'));
                $topic_id = $topic ? $topic['id'] : null;
            }

            if (!$topic_id) {
                $response['error'] = true;
                $response['message'] = 'Topic ID or slug required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $parent_id = $this->post('parent_id') ?: null;
            $age_group = $this->post('age_group') ?: 'all';

            $categories = $this->Topic_model->get_topic_categories($topic_id, $parent_id, $age_group);

            if (!empty($categories)) {
                for ($i = 0; $i < count($categories); $i++) {
                    $categories[$i]['image'] = $categories[$i]['image'] 
                        ? base_url() . CATEGORY_IMG_PATH . $categories[$i]['image'] 
                        : '';
                    
                    // Count questions in this category
                    $que_count = $this->db
                        ->where('category', $categories[$i]['id'])
                        ->count_all_results('tbl_question');
                    $categories[$i]['question_count'] = $que_count;

                    // Check if has children
                    $child_count = $this->db
                        ->where('parent_id', $categories[$i]['id'])
                        ->count_all_results('tbl_category');
                    $categories[$i]['has_children'] = $child_count > 0 ? '1' : '0';
                }
                $response['error'] = false;
                $response['data'] = $categories;
            } else {
                $response['error'] = true;
                $response['message'] = 'No categories found';
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Get Rhapsody content for a specific date
     * POST /Api/get_rhapsody_daily
     * @param year (required)
     * @param month (optional)
     * @param day (optional)
     * @param age_group (optional) - kids, teens, adults
     */
    public function get_rhapsody_daily_post()
    {
        try {
            $this->load->model('Topic_model');

            if (!$this->post('year')) {
                $response['error'] = true;
                $response['message'] = 'Year is required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $year = $this->post('year');
            $month = $this->post('month') ?: null;
            $day = $this->post('day') ?: null;

            $categories = $this->Topic_model->get_rhapsody_by_date($year, $month, $day);

            // Filter by age group if specified
            $age_group = $this->post('age_group');
            if ($age_group && $age_group !== 'all') {
                $categories = array_filter($categories, function($cat) use ($age_group) {
                    return $cat['age_group'] === $age_group || $cat['age_group'] === 'all';
                });
                $categories = array_values($categories);
            }

            if (!empty($categories)) {
                for ($i = 0; $i < count($categories); $i++) {
                    $categories[$i]['image'] = $categories[$i]['image'] 
                        ? base_url() . CATEGORY_IMG_PATH . $categories[$i]['image'] 
                        : '';
                    
                    // Count questions
                    $que_count = $this->db
                        ->where('category', $categories[$i]['id'])
                        ->count_all_results('tbl_question');
                    $categories[$i]['question_count'] = $que_count;
                }
                $response['error'] = false;
                $response['data'] = $categories;
            } else {
                $response['error'] = true;
                $response['message'] = 'No content found for this date';
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Get all Rhapsody years
     * POST /Api/get_rhapsody_years
     */
    public function get_rhapsody_years_post()
    {
        try {
            $this->load->model('Topic_model');
            $years = $this->Topic_model->get_rhapsody_years();

            $response['error'] = false;
            $response['data'] = $years;
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Get Rhapsody months for a year
     * POST /Api/get_rhapsody_months
     * @param year (required)
     */
    public function get_rhapsody_months_post()
    {
        try {
            if (!$this->post('year')) {
                $response['error'] = true;
                $response['message'] = 'Year is required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $this->load->model('Topic_model');
            $year = $this->post('year');
            $months = $this->Topic_model->get_rhapsody_months($year);

            $response['error'] = false;
            $response['data'] = $months;
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Get Rhapsody days for a month
     * POST /Api/get_rhapsody_days
     * @param year (required)
     * @param month (required)
     */
    public function get_rhapsody_days_post()
    {
        try {
            if (!$this->post('year') || !$this->post('month')) {
                $response['error'] = true;
                $response['message'] = 'Year and month are required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $this->load->model('Topic_model');
            $year = $this->post('year');
            $month = $this->post('month');
            $days = $this->Topic_model->get_rhapsody_days($year, $month);

            $response['error'] = false;
            $response['data'] = $days;
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Get Rhapsody day detail (full content)
     * POST /Api/get_rhapsody_day_detail
     * @param year (required)
     * @param month (required)
     * @param day (required)
     */
    public function get_rhapsody_day_detail_post()
    {
        try {
            if (!$this->post('year') || !$this->post('month') || !$this->post('day')) {
                $response['error'] = true;
                $response['message'] = 'Year, month, and day are required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $this->load->model('Topic_model');
            $year = $this->post('year');
            $month = $this->post('month');
            $day = $this->post('day');
            
            $detail = $this->Topic_model->get_rhapsody_day_detail($year, $month, $day);

            if ($detail) {
                $response['error'] = false;
                $response['data'] = $detail;
            } else {
                $response['error'] = true;
                $response['message'] = 'No content found for this date';
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Get Foundation School modules
     * POST /Api/get_foundation_school_modules
     */
    public function get_foundation_school_modules_post()
    {
        try {
            $is_user = $this->verify_token();
            $user_id = !$is_user['error'] ? $is_user['user_id'] : 0;

            $this->load->model('Topic_model');
            $modules = $this->Topic_model->get_foundation_school_modules();

            if (!empty($modules)) {
                for ($i = 0; $i < count($modules); $i++) {
                    $modules[$i]['image'] = $modules[$i]['image'] 
                        ? base_url() . CATEGORY_IMG_PATH . $modules[$i]['image'] 
                        : '';
                    
                    // Count questions
                    $que_count = $this->db
                        ->where('category', $modules[$i]['id'])
                        ->count_all_results('tbl_question');
                    $modules[$i]['question_count'] = $que_count;

                    // Get user progress if logged in
                    if ($user_id) {
                        $progress = $this->db
                            ->where('user_id', $user_id)
                            ->where('category_id', $modules[$i]['id'])
                            ->get('tbl_user_progress')
                            ->row_array();
                        
                        $modules[$i]['user_progress'] = $progress ? [
                            'status' => $progress['status'],
                            'progress_percent' => $progress['progress_percent'],
                            'score' => $progress['score'],
                            'completed_at' => $progress['completed_at']
                        ] : null;
                    }
                }
                $response['error'] = false;
                $response['data'] = $modules;
            } else {
                $response['error'] = true;
                $response['message'] = 'No modules found';
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Get Foundation School classes
     * POST /Api/get_foundation_classes
     */
    public function get_foundation_classes_post()
    {
        try {
            $is_user = $this->verify_token();
            $user_id = !$is_user['error'] ? $is_user['user_id'] : 0;

            $this->load->model('Topic_model');
            $classes = $this->Topic_model->get_foundation_classes();

            if (!empty($classes)) {
                for ($i = 0; $i < count($classes); $i++) {
                    // Get user progress if logged in
                    if ($user_id) {
                        $progress = $this->db
                            ->where('user_id', $user_id)
                            ->where('category_id', $classes[$i]['id'])
                            ->get('tbl_user_progress')
                            ->row_array();
                        
                        $classes[$i]['user_progress'] = $progress ? [
                            'status' => $progress['status'],
                            'progress_percent' => $progress['progress_percent'],
                            'score' => $progress['score'],
                            'completed_at' => $progress['completed_at']
                        ] : null;
                    }
                }
                $response['error'] = false;
                $response['data'] = $classes;
            } else {
                $response['error'] = true;
                $response['message'] = 'No classes found';
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Get Foundation School class detail
     * POST /Api/get_foundation_class_detail
     * @param class_id (required)
     */
    public function get_foundation_class_detail_post()
    {
        try {
            if (!$this->post('class_id')) {
                $response['error'] = true;
                $response['message'] = 'Class ID is required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $this->load->model('Topic_model');
            $class_id = $this->post('class_id');
            
            $detail = $this->Topic_model->get_foundation_class_detail($class_id);

            if ($detail) {
                // Get user progress if logged in
                $is_user = $this->verify_token();
                if (!$is_user['error']) {
                    $user_id = $is_user['user_id'];
                    $progress = $this->db
                        ->where('user_id', $user_id)
                        ->where('category_id', $class_id)
                        ->get('tbl_user_progress')
                        ->row_array();
                    
                    $detail['user_progress'] = $progress ? [
                        'status' => $progress['status'],
                        'progress_percent' => $progress['progress_percent'],
                        'score' => $progress['score'],
                        'completed_at' => $progress['completed_at']
                    ] : null;
                }

                $response['error'] = false;
                $response['data'] = $detail;
            } else {
                $response['error'] = true;
                $response['message'] = 'Class not found';
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Get latest Rhapsody months for home screen
     * POST /Api/get_latest_rhapsody_months
     */
    public function get_latest_rhapsody_months_post()
    {
        try {
            $this->load->model('Topic_model');
            $limit = $this->post('limit') ? intval($this->post('limit')) : 4;
            
            $months = $this->Topic_model->get_latest_rhapsody_months($limit);

            $response['error'] = false;
            $response['data'] = $months;
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Get user progress for a topic/category
     * POST /Api/get_user_progress
     * @param topic_id or category_id
     */
    public function get_user_progress_post()
    {
        try {
            $is_user = $this->verify_token();
            if ($is_user['error']) {
                $response['error'] = true;
                $response['message'] = 'Authentication required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }
            $user_id = $is_user['user_id'];

            $this->db->where('user_id', $user_id);

            if ($this->post('topic_id')) {
                $this->db->where('topic_id', $this->post('topic_id'));
            }
            if ($this->post('category_id')) {
                $this->db->where('category_id', $this->post('category_id'));
            }

            $progress = $this->db->get('tbl_user_progress')->result_array();

            $response['error'] = false;
            $response['data'] = $progress;
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Update user progress
     * POST /Api/update_user_progress
     */
    public function update_user_progress_post()
    {
        try {
            $is_user = $this->verify_token();
            if ($is_user['error']) {
                $response['error'] = true;
                $response['message'] = 'Authentication required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }
            $user_id = $is_user['user_id'];

            if (!$this->post('topic_id') || !$this->post('category_id')) {
                $response['error'] = true;
                $response['message'] = 'topic_id and category_id are required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $topic_id = $this->post('topic_id');
            $category_id = $this->post('category_id');
            $quiz_date = $this->post('quiz_date') ?: null;

            // Check if progress exists
            $this->db->where('user_id', $user_id);
            $this->db->where('category_id', $category_id);
            if ($quiz_date) {
                $this->db->where('quiz_date', $quiz_date);
            } else {
                $this->db->where('quiz_date IS NULL', null, false);
            }
            $existing = $this->db->get('tbl_user_progress')->row_array();

            $data = [
                'status' => $this->post('status') ?: 'in_progress',
                'progress_percent' => $this->post('progress_percent') ?: 0,
                'questions_total' => $this->post('questions_total') ?: 0,
                'questions_answered' => $this->post('questions_answered') ?: 0,
                'questions_correct' => $this->post('questions_correct') ?: 0,
                'score' => $this->post('score') ?: 0,
                'last_activity_at' => date('Y-m-d H:i:s')
            ];

            if ($this->post('status') === 'completed' && !isset($existing['completed_at'])) {
                $data['completed_at'] = date('Y-m-d H:i:s');
            }

            if ($existing) {
                // Update
                $this->db->where('id', $existing['id']);
                $this->db->update('tbl_user_progress', $data);
                $response['action'] = 'updated';
            } else {
                // Insert
                $data['user_id'] = $user_id;
                $data['topic_id'] = $topic_id;
                $data['category_id'] = $category_id;
                $data['quiz_date'] = $quiz_date;
                $data['started_at'] = date('Y-m-d H:i:s');
                $this->db->insert('tbl_user_progress', $data);
                $response['action'] = 'created';
            }

            $response['error'] = false;
            $response['message'] = 'Progress updated successfully';
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    // ============================================
    // GROUP API ENDPOINTS
    // Added: 2025-12-27
    // ============================================

    /**
     * Create a new group
     * POST /Api/create_group
     */
    public function create_group_post()
    {
        try {
            $is_user = $this->verify_token();
            if ($is_user['error']) {
                $response['error'] = true;
                $response['message'] = 'Authentication required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }
            $user_id = $is_user['user_id'];

            if (!$this->post('name')) {
                $response['error'] = true;
                $response['message'] = 'Group name is required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $this->load->model('Group_model');
            
            $group_id = $this->Group_model->create_group(
                $user_id,
                $this->post('name'),
                $this->post('description'),
                $this->post('image'),
                $this->post('is_public') ?: 0,
                $this->post('max_members') ?: 50
            );

            $group = $this->Group_model->get_group($group_id);
            
            $response['error'] = false;
            $response['message'] = 'Group created successfully';
            $response['data'] = $group;
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Get user's groups
     * POST /Api/get_my_groups
     */
    public function get_my_groups_post()
    {
        try {
            $is_user = $this->verify_token();
            if ($is_user['error']) {
                $response['error'] = true;
                $response['message'] = 'Authentication required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }
            $user_id = $is_user['user_id'];

            $this->load->model('Group_model');
            $groups = $this->Group_model->get_user_groups($user_id);

            $response['error'] = false;
            $response['data'] = $groups;
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Get group details
     * POST /Api/get_group
     */
    public function get_group_post()
    {
        try {
            $this->load->model('Group_model');
            $group = null;

            if ($this->post('group_id')) {
                $group = $this->Group_model->get_group($this->post('group_id'));
            } else if ($this->post('invite_code')) {
                $group = $this->Group_model->get_group_by_code($this->post('invite_code'));
            }

            if ($group) {
                $group['members'] = $this->Group_model->get_members($group['id']);
                
                // Add user's role if authenticated
                $is_user = $this->verify_token();
                if (!$is_user['error']) {
                    $group['role'] = $this->Group_model->get_user_role($group['id'], $is_user['user_id']);
                    $group['is_member'] = $group['role'] !== null;
                } else {
                    $group['role'] = null;
                    $group['is_member'] = false;
                }
                
                $response['error'] = false;
                $response['data'] = $group;
            } else {
                $response['error'] = true;
                $response['message'] = 'Group not found';
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Join a group by invite code
     * POST /Api/join_group
     */
    public function join_group_post()
    {
        try {
            $is_user = $this->verify_token();
            if ($is_user['error']) {
                $response['error'] = true;
                $response['message'] = 'Authentication required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }
            $user_id = $is_user['user_id'];

            if (!$this->post('invite_code')) {
                $response['error'] = true;
                $response['message'] = 'Invite code is required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $this->load->model('Group_model');
            $group = $this->Group_model->get_group_by_code($this->post('invite_code'));

            if (!$group) {
                $response['error'] = true;
                $response['message'] = 'Invalid invite code';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            if ($group['member_count'] >= $group['max_members']) {
                $response['error'] = true;
                $response['message'] = 'Group is full';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $joined = $this->Group_model->add_member($group['id'], $user_id);

            if ($joined) {
                $response['error'] = false;
                $response['message'] = 'Joined group successfully';
                $response['data'] = $this->Group_model->get_group($group['id']);
            } else {
                $response['error'] = true;
                $response['message'] = 'Already a member of this group';
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Leave a group
     * POST /Api/leave_group
     */
    public function leave_group_post()
    {
        try {
            $is_user = $this->verify_token();
            if ($is_user['error']) {
                $response['error'] = true;
                $response['message'] = 'Authentication required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }
            $user_id = $is_user['user_id'];

            if (!$this->post('group_id')) {
                $response['error'] = true;
                $response['message'] = 'Group ID is required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $this->load->model('Group_model');
            $left = $this->Group_model->leave_group($this->post('group_id'), $user_id);

            if ($left) {
                $response['error'] = false;
                $response['message'] = 'Left group successfully';
            } else {
                $response['error'] = true;
                $response['message'] = 'Owner cannot leave the group. Delete the group instead.';
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Delete a group (owner only)
     * POST /Api/delete_group
     */
    public function delete_group_post()
    {
        try {
            $is_user = $this->verify_token();
            if ($is_user['error']) {
                $response['error'] = true;
                $response['message'] = 'Authentication required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }
            $user_id = $is_user['user_id'];

            if (!$this->post('group_id')) {
                $response['error'] = true;
                $response['message'] = 'Group ID is required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $this->load->model('Group_model');
            $group = $this->Group_model->get_group($this->post('group_id'));

            if (!$group) {
                $response['error'] = true;
                $response['message'] = 'Group not found';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            // Only owner can delete the group
            if ($group['owner_id'] != $user_id) {
                $response['error'] = true;
                $response['message'] = 'Only the group owner can delete this group';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            // Delete the group and all related data
            $this->Group_model->delete_group_cascade($this->post('group_id'));

            $response['error'] = false;
            $response['message'] = 'Group deleted successfully';
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Search public groups
     * POST /Api/search_groups
     */
    public function search_groups_post()
    {
        try {
            if (!$this->post('query')) {
                $response['error'] = true;
                $response['message'] = 'Search query is required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $this->load->model('Group_model');
            $groups = $this->Group_model->search_groups($this->post('query'));

            $response['error'] = false;
            $response['data'] = $groups;
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Get public groups for discovery
     * Shows all public groups that user is not already a member of
     */
    public function get_public_groups_post()
    {
        try {
            $user_id = null;
            
            // Optional: exclude groups user is already in
            $is_user = $this->verify_token();
            if (!$is_user['error']) {
                $user_id = $is_user['user_id'];
            }

            $limit = $this->post('limit') ? intval($this->post('limit')) : 50;
            $offset = $this->post('offset') ? intval($this->post('offset')) : 0;

            $this->load->model('Group_model');
            $groups = $this->Group_model->get_public_groups($user_id, $limit, $offset);

            $response['error'] = false;
            $response['data'] = $groups;
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Join a public group directly (no invite code needed)
     */
    public function join_public_group_post()
    {
        try {
            $is_user = $this->verify_token();
            if ($is_user['error']) {
                $response['error'] = true;
                $response['message'] = 'Authentication required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }
            $user_id = $is_user['user_id'];

            if (!$this->post('group_id')) {
                $response['error'] = true;
                $response['message'] = 'Group ID is required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $this->load->model('Group_model');
            $result = $this->Group_model->join_public_group($this->post('group_id'), $user_id);

            if ($result['success']) {
                $group = $result['group'];
                $group['members'] = $this->Group_model->get_members($group['id']);
                $group['role'] = 'member';
                
                $response['error'] = false;
                $response['message'] = 'Successfully joined the group';
                $response['data'] = $group;
            } else {
                $response['error'] = true;
                $response['message'] = $result['message'];
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    // ============================================
    // 1v1 BATTLE API ENDPOINTS
    // ============================================

    /**
     * Create a 1v1 battle
     * POST /Api/create_1v1_battle
     */
    public function create_1v1_battle_post()
    {
        try {
            $is_user = $this->verify_token();
            if ($is_user['error']) {
                $response['error'] = true;
                $response['message'] = 'Authentication required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }
            $user_id = $is_user['user_id'];

            if (!$this->post('topic_id') || !$this->post('category_id')) {
                $response['error'] = true;
                $response['message'] = 'topic_id and category_id are required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $this->load->model('Battle_model');
            
            $config = [
                'question_count' => $this->post('question_count') ?: 10,
                'time_per_question' => $this->post('time_per_question') ?: 15,
                'entry_coins' => $this->post('entry_coins') ?: 0,
                'prize_coins' => $this->post('prize_coins') ?: 0
            ];

            $result = $this->Battle_model->create_1v1_battle(
                $user_id,
                $this->post('topic_id'),
                $this->post('category_id'),
                $config
            );

            $response['error'] = false;
            $response['message'] = 'Battle created. Share the match code!';
            $response['data'] = [
                'battle_id' => $result['battle_id'],
                'match_code' => $result['match_code']
            ];
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Join a 1v1 battle
     * POST /Api/join_1v1_battle
     */
    public function join_1v1_battle_post()
    {
        try {
            $is_user = $this->verify_token();
            if ($is_user['error']) {
                $response['error'] = true;
                $response['message'] = 'Authentication required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }
            $user_id = $is_user['user_id'];

            if (!$this->post('match_code')) {
                $response['error'] = true;
                $response['message'] = 'Match code is required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $this->load->model('Battle_model');
            $result = $this->Battle_model->join_1v1_battle($this->post('match_code'), $user_id);

            if ($result['error']) {
                $response['error'] = true;
                $response['message'] = $result['message'];
            } else {
                $response['error'] = false;
                $response['message'] = 'Joined battle successfully';
                $response['data'] = $result['battle'];
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Get 1v1 battle details
     * POST /Api/get_1v1_battle
     */
    public function get_1v1_battle_post()
    {
        try {
            $this->load->model('Battle_model');
            $battle = null;

            if ($this->post('battle_id')) {
                $battle = $this->Battle_model->get_1v1_battle($this->post('battle_id'));
            } else if ($this->post('match_code')) {
                $battle = $this->Battle_model->get_1v1_by_code($this->post('match_code'));
            }

            if ($battle) {
                $battle['questions'] = json_decode($battle['questions'], true);
                
                // Get player info
                $battle['challenger'] = $this->db
                    ->select('id, name, profile')
                    ->where('id', $battle['challenger_id'])
                    ->get('tbl_users')
                    ->row_array();
                
                if ($battle['opponent_id']) {
                    $battle['opponent'] = $this->db
                        ->select('id, name, profile')
                        ->where('id', $battle['opponent_id'])
                        ->get('tbl_users')
                        ->row_array();
                }
                
                $response['error'] = false;
                $response['data'] = $battle;
            } else {
                $response['error'] = true;
                $response['message'] = 'Battle not found';
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Submit 1v1 battle answers
     * POST /Api/submit_1v1_answers
     */
    public function submit_1v1_answers_post()
    {
        try {
            $is_user = $this->verify_token();
            if ($is_user['error']) {
                $response['error'] = true;
                $response['message'] = 'Authentication required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }
            $user_id = $is_user['user_id'];

            if (!$this->post('battle_id')) {
                $response['error'] = true;
                $response['message'] = 'battle_id is required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $this->load->model('Battle_model');
            
            $answers = $this->post('answers') ? json_decode($this->post('answers'), true) : [];
            
            $result = $this->Battle_model->submit_1v1_answers(
                $this->post('battle_id'),
                $user_id,
                $answers,
                $this->post('score') ?: 0,
                $this->post('correct') ?: 0,
                $this->post('time_ms') ?: 0
            );

            $response['error'] = $result['error'];
            $response['message'] = $result['message'];
            
            // Get updated battle
            $response['data'] = $this->Battle_model->get_1v1_battle($this->post('battle_id'));
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Get 1v1 battle history
     * POST /Api/get_1v1_history
     */
    public function get_1v1_history_post()
    {
        try {
            $is_user = $this->verify_token();
            if ($is_user['error']) {
                $response['error'] = true;
                $response['message'] = 'Authentication required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }
            $user_id = $is_user['user_id'];

            $this->load->model('Battle_model');
            $history = $this->Battle_model->get_user_1v1_history($user_id);

            $response['error'] = false;
            $response['data'] = $history;
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    // ============================================
    // GROUP BATTLE API ENDPOINTS
    // ============================================

    /**
     * Create a group battle
     * POST /Api/create_group_battle
     */
    public function create_group_battle_post()
    {
        try {
            $is_user = $this->verify_token();
            if ($is_user['error']) {
                $response['error'] = true;
                $response['message'] = 'Authentication required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }
            $user_id = $is_user['user_id'];

            if (!$this->post('group_id') || !$this->post('topic_id') || !$this->post('category_id')) {
                $response['error'] = true;
                $response['message'] = 'group_id, topic_id, and category_id are required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            // Check if user is admin of group
            $this->load->model('Group_model');
            if (!$this->Group_model->is_admin($this->post('group_id'), $user_id)) {
                $response['error'] = true;
                $response['message'] = 'Only group admins can create battles';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $this->load->model('Battle_model');
            
            $config = [
                'title' => $this->post('title'),
                'question_count' => $this->post('question_count') ?: 10,
                'time_per_question' => $this->post('time_per_question') ?: 15,
                'entry_coins' => $this->post('entry_coins') ?: 0,
                'prize_coins' => $this->post('prize_coins') ?: 0,
                'min_players' => $this->post('min_players') ?: 2,
                'max_players' => $this->post('max_players') ?: 10,
                'scheduled_start' => $this->post('scheduled_start')
            ];

            $battle_id = $this->Battle_model->create_group_battle(
                $this->post('group_id'),
                $user_id,
                $this->post('topic_id'),
                $this->post('category_id'),
                $config
            );

            $battle = $this->Battle_model->get_group_battle($battle_id);

            $response['error'] = false;
            $response['message'] = 'Group battle created';
            $response['data'] = $battle;
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Join a group battle
     * POST /Api/join_group_battle
     */
    public function join_group_battle_post()
    {
        try {
            $is_user = $this->verify_token();
            if ($is_user['error']) {
                $response['error'] = true;
                $response['message'] = 'Authentication required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }
            $user_id = $is_user['user_id'];

            if (!$this->post('battle_id')) {
                $response['error'] = true;
                $response['message'] = 'battle_id is required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $this->load->model('Battle_model');
            $battle = $this->Battle_model->get_group_battle($this->post('battle_id'));
            
            if (!$battle) {
                $response['error'] = true;
                $response['message'] = 'Battle not found';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            // Check if user is member of group
            $this->load->model('Group_model');
            if (!$this->Group_model->is_member($battle['group_id'], $user_id)) {
                $response['error'] = true;
                $response['message'] = 'You must be a group member to join';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $joined = $this->Battle_model->join_group_battle($this->post('battle_id'), $user_id);

            if ($joined) {
                $response['error'] = false;
                $response['message'] = 'Joined battle successfully';
                $response['data'] = $this->Battle_model->get_group_battle($this->post('battle_id'));
            } else {
                $response['error'] = true;
                $response['message'] = 'Already joined this battle';
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Start a group battle
     * POST /Api/start_group_battle
     */
    public function start_group_battle_post()
    {
        try {
            $is_user = $this->verify_token();
            if ($is_user['error']) {
                $response['error'] = true;
                $response['message'] = 'Authentication required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }
            $user_id = $is_user['user_id'];

            if (!$this->post('battle_id')) {
                $response['error'] = true;
                $response['message'] = 'battle_id is required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $this->load->model('Battle_model');
            $battle = $this->Battle_model->get_group_battle($this->post('battle_id'));
            
            if ($battle['created_by'] != $user_id) {
                $response['error'] = true;
                $response['message'] = 'Only the battle creator can start it';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $result = $this->Battle_model->start_group_battle($this->post('battle_id'));
            
            $response['error'] = $result['error'];
            $response['message'] = $result['message'];
            $response['data'] = $this->Battle_model->get_group_battle($this->post('battle_id'));
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Submit group battle answers
     * POST /Api/submit_group_battle_answers
     */
    public function submit_group_battle_answers_post()
    {
        try {
            $is_user = $this->verify_token();
            if ($is_user['error']) {
                $response['error'] = true;
                $response['message'] = 'Authentication required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }
            $user_id = $is_user['user_id'];

            if (!$this->post('battle_id')) {
                $response['error'] = true;
                $response['message'] = 'battle_id is required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $this->load->model('Battle_model');
            
            $answers = $this->post('answers') ? json_decode($this->post('answers'), true) : [];
            
            $this->Battle_model->submit_group_battle_answers(
                $this->post('battle_id'),
                $user_id,
                $answers,
                $this->post('score') ?: 0,
                $this->post('correct') ?: 0,
                $this->post('wrong') ?: 0,
                $this->post('time_ms') ?: 0
            );

            $response['error'] = false;
            $response['message'] = 'Answers submitted';
            $response['data'] = $this->Battle_model->get_group_battle($this->post('battle_id'));
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Get group battle details and leaderboard
     * POST /Api/get_group_battle
     */
    public function get_group_battle_post()
    {
        try {
            if (!$this->post('battle_id')) {
                $response['error'] = true;
                $response['message'] = 'battle_id is required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $this->load->model('Battle_model');
            $battle = $this->Battle_model->get_group_battle($this->post('battle_id'));

            if ($battle) {
                $battle['questions'] = json_decode($battle['questions'], true);
                $battle['entries'] = $this->Battle_model->get_group_battle_entries($battle['id']);
                
                $response['error'] = false;
                $response['data'] = $battle;
            } else {
                $response['error'] = true;
                $response['message'] = 'Battle not found';
            }
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Get group's battle list
     * POST /Api/get_group_battles
     */
    public function get_group_battles_post()
    {
        try {
            if (!$this->post('group_id')) {
                $response['error'] = true;
                $response['message'] = 'group_id is required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $this->load->model('Battle_model');
            $status = $this->post('status'); // null = all, 'pending', 'active', 'completed'
            $battles = $this->Battle_model->get_group_battles($this->post('group_id'), $status);

            $response['error'] = false;
            $response['data'] = $battles;
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    // =========================================================================
    // SOLO MODE (Practice Mode) - Random Questions by Topic
    // =========================================================================

    /**
     * Get available topics for Solo Mode
     * POST /Api/get_solo_topics
     * 
     * Returns topics with question counts for Solo Mode selection
     */
    public function get_solo_topics_post()
    {
        try {
            $is_user = $this->verify_token();
            if ($is_user['error']) {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return;
            }

            $this->load->model('Topic_model');
            $topics = $this->Topic_model->get_solo_mode_topics();

            $response['error'] = false;
            $response['data'] = array_values($topics); // Ensure indexed array for JSON
            $response['message'] = 'Topics for Solo Mode';
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Get random questions for Solo Mode
     * POST /Api/get_solo_questions
     * 
     * @param topic (required) - Topic slug: 'rhapsody' or 'foundation_school'
     * @param count (required) - Number of questions: 5, 10, 15, or 20
     * @param language_id (optional) - Language filter
     * 
     * Returns random questions from ALL categories within the topic
     */
    public function get_solo_questions_post()
    {
        try {
            $is_user = $this->verify_token();
            if ($is_user['error']) {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return;
            }
            $user_id = $is_user['user_id'];
            $firebase_id = $is_user['firebase_id'];

            // Validate required parameters
            if (!$this->post('topic')) {
                $response['error'] = true;
                $response['message'] = 'topic is required (rhapsody or foundation_school)';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            if (!$this->post('count')) {
                $response['error'] = true;
                $response['message'] = 'count is required (5, 10, 15, or 20)';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $topic_slug = $this->post('topic');
            $count = intval($this->post('count'));
            $language_id = $this->post('language_id') ?: 0;

            // Validate count (allowed: 5, 10, 15, 20)
            $allowed_counts = [5, 10, 15, 20];
            if (!in_array($count, $allowed_counts)) {
                $response['error'] = true;
                $response['message'] = 'count must be 5, 10, 15, or 20';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $this->load->model('Topic_model');
            
            // Verify topic exists
            $topic = $this->Topic_model->get_topic_by_slug($topic_slug);
            if (!$topic) {
                $response['error'] = true;
                $response['message'] = 'Topic not found: ' . $topic_slug;
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            // Get random questions
            $questions = $this->Topic_model->get_random_questions_by_topic($topic_slug, $count, $language_id);

            if (empty($questions)) {
                $response['error'] = true;
                $response['message'] = 'No questions available for this topic';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            // Check if we have enough questions
            if (count($questions) < $count) {
                $response['error'] = true;
                $response['message'] = 'Not enough questions available. Requested: ' . $count . ', Available: ' . count($questions);
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            // Process questions (shuffle options, add image URLs, etc.)
            for ($i = 0; $i < count($questions); $i++) {
                $questions[$i]['image'] = ($questions[$i]['image']) 
                    ? base_url() . QUESTION_IMG_PATH . $questions[$i]['image'] 
                    : '';
                $questions[$i] = $this->suffleOptions($questions[$i], $firebase_id);
                unset($questions[$i]['session_answer']);
            }

            // Get total available for info
            $total_available = $this->Topic_model->get_topic_questions_count($topic_slug);

            $response['error'] = false;
            $response['data'] = array_values($questions); // Ensure indexed array for JSON
            $response['topic'] = [
                'id' => $topic['id'],
                'slug' => $topic['slug'],
                'name' => $topic['name']
            ];
            $response['requested_count'] = $count;
            $response['total_available'] = $total_available;
            $response['message'] = 'Random questions for Solo Mode';

        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }

    /**
     * Submit Solo Mode quiz answers
     * POST /Api/submit_solo_quiz
     * 
     * @param topic (required) - Topic slug
     * @param question_count (required) - Number of questions answered
     * @param answers (required) - Array of {question_id, selected_answer}
     * @param time_taken (optional) - Total time in milliseconds
     * 
     * Reward: +1 coin if 100% correct AND question_count > 5
     */
    public function submit_solo_quiz_post()
    {
        try {
            $is_user = $this->verify_token();
            if ($is_user['error']) {
                $this->response($is_user, REST_Controller::HTTP_OK);
                return;
            }
            $user_id = $is_user['user_id'];

            // Validate required parameters
            if (!$this->post('topic') || !$this->post('question_count') || !$this->post('answers')) {
                $response['error'] = true;
                $response['message'] = 'topic, question_count, and answers are required';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $topic_slug = $this->post('topic');
            $question_count = intval($this->post('question_count'));
            $answers = $this->post('answers'); // Array of {question_id, selected_answer}
            $time_taken = $this->post('time_taken') ?: 0;

            if (!is_array($answers)) {
                $answers = json_decode($answers, true);
            }

            if (empty($answers)) {
                $response['error'] = true;
                $response['message'] = 'answers array is empty';
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            $this->load->model('Topic_model');
            
            // Verify topic exists
            $topic = $this->Topic_model->get_topic_by_slug($topic_slug);
            if (!$topic) {
                $response['error'] = true;
                $response['message'] = 'Topic not found: ' . $topic_slug;
                $this->response($response, REST_Controller::HTTP_OK);
                return;
            }

            // Calculate score
            $correct_answers = 0;
            $total_questions = count($answers);
            $detailed_results = [];
            
            log_message('debug', "Solo Quiz: Processing $total_questions answers for topic: $topic_slug");

            foreach ($answers as $answer) {
                $question_id = $answer['question_id'];
                $selected_letter = strtolower(trim($answer['selected_answer'] ?? ''));
                $selected_option_text = trim($answer['selected_option_text'] ?? '');

                // Get question from database
                $question = $this->db->where('id', $question_id)->get('tbl_question')->row_array();
                
                if ($question) {
                    // The original correct answer letter (before any shuffle)
                    $correct_letter = strtolower(trim($question['answer']));
                    
                    // Get the correct answer option text
                    $correct_option_key = 'option' . $correct_letter;
                    $correct_option_text = trim($question[$correct_option_key] ?? '');
                    
                    // Compare by option TEXT (handles shuffled options)
                    // The client sends the actual text of the selected option
                    $is_correct = !empty($selected_option_text) && 
                                  ($selected_option_text === $correct_option_text);
                    
                    log_message('debug', "Q$question_id: selected='$selected_option_text' correct='$correct_option_text' is_correct=" . ($is_correct ? 'true' : 'false'));
                    
                    if ($is_correct) {
                        $correct_answers++;
                    }

                    $detailed_results[] = [
                        'question_id' => $question_id,
                        'selected_answer' => $selected_letter,
                        'correct_answer' => $correct_letter,
                        'is_correct' => $is_correct,
                        'question' => $question['question'],
                        'note' => $question['note'] ?? '' // Explanation
                    ];
                }
            }

            // Calculate percentage
            $percentage = ($total_questions > 0) ? round(($correct_answers / $total_questions) * 100) : 0;

            // Determine coin reward
            // Rule: +1 coin if 100% correct AND question_count >= 5
            $earned_coin = 0;
            if ($percentage == 100 && $question_count >= 5) {
                $earned_coin = 1;
                $this->set_coins($user_id, $earned_coin);
                
                // Track the coin reward
                $title = 'soloModePerfect';
                $status = 0; // add
                $this->set_tracker_data($user_id, $earned_coin, $title, $status);
            }

            // Save solo quiz attempt (optional - for tracking)
            // We could add a tbl_solo_quiz_attempt table later if needed

            $response['error'] = false;
            $response['score'] = $correct_answers;
            $response['total_questions'] = $total_questions;
            $response['correct_answers'] = $correct_answers;
            $response['wrong_answers'] = $total_questions - $correct_answers;
            $response['percentage'] = $percentage;
            $response['earned_coin'] = $earned_coin;
            $response['coin_eligible'] = ($question_count >= 5); // Tells if coin was possible
            $response['time_taken'] = $time_taken;
            $response['topic'] = [
                'id' => $topic['id'],
                'slug' => $topic['slug'],
                'name' => $topic['name']
            ];
            $response['detailed_results'] = $detailed_results;
            $response['message'] = ($earned_coin > 0) 
                ? 'Perfect score! +1 coin earned' 
                : ($percentage == 100 && $question_count < 5 
                    ? 'Perfect score! (No coin for less than 5 questions)' 
                    : 'Quiz completed');

        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = $e->getMessage();
        }
        $this->response($response, REST_Controller::HTTP_OK);
    }
}
