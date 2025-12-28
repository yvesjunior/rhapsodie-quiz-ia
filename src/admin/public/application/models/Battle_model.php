<?php

defined('BASEPATH') or exit('No direct script access allowed');

/**
 * Battle Model
 * Handles 1v1 and group battle operations
 */
class Battle_model extends CI_Model
{
    // ============================================
    // 1v1 BATTLES
    // ============================================

    /**
     * Create a 1v1 battle
     */
    public function create_1v1_battle($challenger_id, $topic_id, $category_id, $config = [])
    {
        $match_code = $this->generate_match_code();
        
        $data = [
            'match_code' => $match_code,
            'topic_id' => $topic_id,
            'category_id' => $category_id,
            'challenger_id' => $challenger_id,
            'question_count' => $config['question_count'] ?? 10,
            'time_per_question' => $config['time_per_question'] ?? 15,
            'entry_coins' => $config['entry_coins'] ?? 0,
            'prize_coins' => $config['prize_coins'] ?? 0,
            'status' => 'waiting',
            'expires_at' => date('Y-m-d H:i:s', strtotime('+10 minutes'))
        ];
        
        // Get random questions
        $questions = $this->get_random_questions($category_id, $data['question_count']);
        $data['questions'] = json_encode($questions);
        
        $this->db->insert('tbl_battle_1v1', $data);
        
        return [
            'battle_id' => $this->db->insert_id(),
            'match_code' => $match_code,
            'questions' => $questions
        ];
    }

    /**
     * Generate unique match code
     */
    private function generate_match_code()
    {
        do {
            $code = strtoupper(substr(md5(uniqid(mt_rand(), true)), 0, 6));
            $exists = $this->db->where('match_code', $code)->count_all_results('tbl_battle_1v1');
        } while ($exists > 0);
        
        return $code;
    }

    /**
     * Get random questions for battle
     */
    private function get_random_questions($category_id, $count)
    {
        $questions = $this->db
            ->select('id, question, optiona, optionb, optionc, optiond, answer, note')
            ->where('category', $category_id)
            ->order_by('RAND()')
            ->limit($count)
            ->get('tbl_question')
            ->result_array();
        
        return $questions;
    }

    /**
     * Join a 1v1 battle
     */
    public function join_1v1_battle($match_code, $opponent_id)
    {
        $battle = $this->db
            ->where('match_code', $match_code)
            ->where('status', 'waiting')
            ->where('expires_at >', date('Y-m-d H:i:s'))
            ->get('tbl_battle_1v1')
            ->row_array();
        
        if (!$battle) {
            return ['error' => true, 'message' => 'Battle not found or expired'];
        }
        
        if ($battle['challenger_id'] == $opponent_id) {
            return ['error' => true, 'message' => 'Cannot join your own battle'];
        }
        
        $this->db
            ->where('id', $battle['id'])
            ->update('tbl_battle_1v1', [
                'opponent_id' => $opponent_id,
                'status' => 'ready'
            ]);
        
        $battle['opponent_id'] = $opponent_id;
        $battle['status'] = 'ready';
        $battle['questions'] = json_decode($battle['questions'], true);
        
        return ['error' => false, 'battle' => $battle];
    }

    /**
     * Start 1v1 battle
     */
    public function start_1v1_battle($battle_id)
    {
        return $this->db
            ->where('id', $battle_id)
            ->update('tbl_battle_1v1', [
                'status' => 'playing',
                'started_at' => date('Y-m-d H:i:s')
            ]);
    }

    /**
     * Submit 1v1 battle answers
     */
    public function submit_1v1_answers($battle_id, $user_id, $answers, $score, $correct, $time_ms)
    {
        $battle = $this->get_1v1_battle($battle_id);
        if (!$battle) {
            return ['error' => true, 'message' => 'Battle not found'];
        }
        
        $is_challenger = $battle['challenger_id'] == $user_id;
        $is_opponent = $battle['opponent_id'] == $user_id;
        
        if (!$is_challenger && !$is_opponent) {
            return ['error' => true, 'message' => 'Not a participant'];
        }
        
        $update = [];
        if ($is_challenger) {
            $update['challenger_answers'] = json_encode($answers);
            $update['challenger_score'] = $score;
            $update['challenger_correct'] = $correct;
            $update['challenger_time_ms'] = $time_ms;
            $update['challenger_ready'] = 1;
        } else {
            $update['opponent_answers'] = json_encode($answers);
            $update['opponent_score'] = $score;
            $update['opponent_correct'] = $correct;
            $update['opponent_time_ms'] = $time_ms;
            $update['opponent_ready'] = 1;
        }
        
        $this->db->where('id', $battle_id)->update('tbl_battle_1v1', $update);
        
        // Check if both players finished
        $battle = $this->get_1v1_battle($battle_id);
        if ($battle['challenger_ready'] && $battle['opponent_ready']) {
            $this->complete_1v1_battle($battle_id);
        }
        
        return ['error' => false, 'message' => 'Answers submitted'];
    }

    /**
     * Complete 1v1 battle and determine winner
     */
    private function complete_1v1_battle($battle_id)
    {
        $battle = $this->get_1v1_battle($battle_id);
        
        $winner_id = null;
        $is_draw = 0;
        
        if ($battle['challenger_score'] > $battle['opponent_score']) {
            $winner_id = $battle['challenger_id'];
        } else if ($battle['opponent_score'] > $battle['challenger_score']) {
            $winner_id = $battle['opponent_id'];
        } else {
            // Same score - check time
            if ($battle['challenger_time_ms'] < $battle['opponent_time_ms']) {
                $winner_id = $battle['challenger_id'];
            } else if ($battle['opponent_time_ms'] < $battle['challenger_time_ms']) {
                $winner_id = $battle['opponent_id'];
            } else {
                $is_draw = 1;
            }
        }
        
        $this->db
            ->where('id', $battle_id)
            ->update('tbl_battle_1v1', [
                'winner_id' => $winner_id,
                'is_draw' => $is_draw,
                'status' => 'completed',
                'ended_at' => date('Y-m-d H:i:s')
            ]);
        
        // Award coins to winner
        if ($winner_id && $battle['prize_coins'] > 0) {
            $this->db->query("UPDATE tbl_users SET coins = coins + {$battle['prize_coins']} WHERE id = $winner_id");
        }
        
        return $winner_id;
    }

    /**
     * Get 1v1 battle by ID
     */
    public function get_1v1_battle($battle_id)
    {
        return $this->db
            ->where('id', $battle_id)
            ->get('tbl_battle_1v1')
            ->row_array();
    }

    /**
     * Get 1v1 battle by match code
     */
    public function get_1v1_by_code($match_code)
    {
        return $this->db
            ->where('match_code', $match_code)
            ->get('tbl_battle_1v1')
            ->row_array();
    }

    /**
     * Get user's 1v1 battle history
     */
    public function get_user_1v1_history($user_id, $limit = 20)
    {
        return $this->db
            ->where('challenger_id', $user_id)
            ->or_where('opponent_id', $user_id)
            ->where('status', 'completed')
            ->order_by('ended_at', 'DESC')
            ->limit($limit)
            ->get('tbl_battle_1v1')
            ->result_array();
    }

    // ============================================
    // GROUP BATTLES
    // ============================================

    /**
     * Create a group battle
     */
    public function create_group_battle($group_id, $created_by, $topic_id, $category_id, $config = [])
    {
        $data = [
            'group_id' => $group_id,
            'topic_id' => $topic_id,
            'category_id' => $category_id,
            'created_by' => $created_by,
            'title' => $config['title'] ?? null,
            'question_count' => $config['question_count'] ?? 10,
            'time_per_question' => $config['time_per_question'] ?? 15,
            'entry_coins' => $config['entry_coins'] ?? 0,
            'prize_coins' => $config['prize_coins'] ?? 0,
            'min_players' => $config['min_players'] ?? 2,
            'max_players' => $config['max_players'] ?? 10,
            'status' => 'pending',
            'scheduled_start' => $config['scheduled_start'] ?? null
        ];
        
        // Get random questions
        $questions = $this->get_random_questions($category_id, $data['question_count']);
        $data['questions'] = json_encode($questions);
        
        $this->db->insert('tbl_group_battle', $data);
        $battle_id = $this->db->insert_id();
        
        // Auto-join creator
        $this->join_group_battle($battle_id, $created_by);
        
        return $battle_id;
    }

    /**
     * Join a group battle
     */
    public function join_group_battle($battle_id, $user_id)
    {
        // Check if already joined
        $existing = $this->db
            ->where('battle_id', $battle_id)
            ->where('user_id', $user_id)
            ->get('tbl_group_battle_entry')
            ->row_array();
        
        if ($existing) {
            return false;
        }
        
        $this->db->insert('tbl_group_battle_entry', [
            'battle_id' => $battle_id,
            'user_id' => $user_id,
            'status' => 'joined'
        ]);
        
        // Update player count
        $count = $this->db
            ->where('battle_id', $battle_id)
            ->count_all_results('tbl_group_battle_entry');
        
        $this->db
            ->where('id', $battle_id)
            ->update('tbl_group_battle', ['player_count' => $count]);
        
        return true;
    }

    /**
     * Start a group battle
     */
    public function start_group_battle($battle_id)
    {
        $battle = $this->get_group_battle($battle_id);
        
        if ($battle['player_count'] < $battle['min_players']) {
            return ['error' => true, 'message' => 'Not enough players'];
        }
        
        // Update all entries to playing
        $this->db
            ->where('battle_id', $battle_id)
            ->update('tbl_group_battle_entry', ['status' => 'playing']);
        
        $this->db
            ->where('id', $battle_id)
            ->update('tbl_group_battle', [
                'status' => 'active',
                'started_at' => date('Y-m-d H:i:s')
            ]);
        
        return ['error' => false, 'message' => 'Battle started'];
    }

    /**
     * Submit group battle answers
     */
    public function submit_group_battle_answers($battle_id, $user_id, $answers, $score, $correct, $wrong, $time_ms)
    {
        $this->db
            ->where('battle_id', $battle_id)
            ->where('user_id', $user_id)
            ->update('tbl_group_battle_entry', [
                'answers' => json_encode($answers),
                'score' => $score,
                'correct_answers' => $correct,
                'wrong_answers' => $wrong,
                'total_time_ms' => $time_ms,
                'status' => 'completed',
                'completed_at' => date('Y-m-d H:i:s')
            ]);
        
        // Check if all players finished
        $pending = $this->db
            ->where('battle_id', $battle_id)
            ->where('status !=', 'completed')
            ->count_all_results('tbl_group_battle_entry');
        
        if ($pending == 0) {
            $this->complete_group_battle($battle_id);
        }
        
        return true;
    }

    /**
     * Complete group battle and calculate rankings
     */
    private function complete_group_battle($battle_id)
    {
        // Get all entries sorted by score (desc) and time (asc)
        $entries = $this->db
            ->where('battle_id', $battle_id)
            ->order_by('score', 'DESC')
            ->order_by('total_time_ms', 'ASC')
            ->get('tbl_group_battle_entry')
            ->result_array();
        
        $battle = $this->get_group_battle($battle_id);
        
        // Assign ranks and coins
        $rank = 1;
        foreach ($entries as $entry) {
            $coins = 0;
            if ($rank == 1 && $battle['prize_coins'] > 0) {
                $coins = $battle['prize_coins'];
                $this->db->query("UPDATE tbl_users SET coins = coins + $coins WHERE id = {$entry['user_id']}");
            }
            
            $this->db
                ->where('id', $entry['id'])
                ->update('tbl_group_battle_entry', [
                    'rank' => $rank,
                    'coins_earned' => $coins
                ]);
            
            $rank++;
        }
        
        // Mark battle as completed
        $this->db
            ->where('id', $battle_id)
            ->update('tbl_group_battle', [
                'status' => 'completed',
                'ended_at' => date('Y-m-d H:i:s')
            ]);
    }

    /**
     * Get group battle by ID
     */
    public function get_group_battle($battle_id)
    {
        return $this->db
            ->where('id', $battle_id)
            ->get('tbl_group_battle')
            ->row_array();
    }

    /**
     * Get group battle entries
     */
    public function get_group_battle_entries($battle_id)
    {
        return $this->db
            ->select('e.*, u.name, u.profile')
            ->from('tbl_group_battle_entry e')
            ->join('tbl_users u', 'u.id = e.user_id')
            ->where('e.battle_id', $battle_id)
            ->order_by('e.rank', 'ASC')
            ->get()
            ->result_array();
    }

    /**
     * Get group's battle history
     */
    public function get_group_battles($group_id, $status = null, $limit = 20)
    {
        $this->db->where('group_id', $group_id);
        
        if ($status) {
            $this->db->where('status', $status);
        }
        
        return $this->db
            ->order_by('created_at', 'DESC')
            ->limit($limit)
            ->get('tbl_group_battle')
            ->result_array();
    }

    /**
     * Get pending battles for a group
     */
    public function get_pending_battles($group_id)
    {
        return $this->db
            ->where('group_id', $group_id)
            ->where('status', 'pending')
            ->order_by('scheduled_start', 'ASC')
            ->get('tbl_group_battle')
            ->result_array();
    }
}

