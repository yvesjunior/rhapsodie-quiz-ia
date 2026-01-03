<?php

defined('BASEPATH') or exit('No direct script access allowed');

/**
 * Topic Model
 * Handles operations for tbl_topic (Rhapsody, Foundation School)
 */
class Topic_model extends CI_Model
{
    private $table = 'tbl_topic';

    /**
     * Get all active topics
     */
    public function get_all_topics()
    {
        return $this->db
            ->where('is_active', 1)
            ->order_by('row_order', 'ASC')
            ->get($this->table)
            ->result_array();
    }

    /**
     * Get topic by ID
     */
    public function get_topic_by_id($id)
    {
        return $this->db
            ->where('id', $id)
            ->where('is_active', 1)
            ->get($this->table)
            ->row_array();
    }

    /**
     * Get topic by slug
     */
    public function get_topic_by_slug($slug)
    {
        return $this->db
            ->where('slug', $slug)
            ->where('is_active', 1)
            ->get($this->table)
            ->row_array();
    }

    /**
     * Get categories for a topic
     */
    public function get_topic_categories($topic_id, $parent_id = null, $age_group = 'all')
    {
        $this->db->where('topic_id', $topic_id);
        
        if ($parent_id === null) {
            $this->db->where('parent_id IS NULL', null, false);
        } else {
            $this->db->where('parent_id', $parent_id);
        }
        
        if ($age_group !== 'all') {
            $this->db->group_start();
            $this->db->where('age_group', $age_group);
            $this->db->or_where('age_group', 'all');
            $this->db->group_end();
        }
        
        return $this->db
            ->order_by('row_order', 'ASC')
            ->get('tbl_category')
            ->result_array();
    }

    /**
     * Get Rhapsody categories for a specific date
     */
    public function get_rhapsody_by_date($year, $month = null, $day = null)
    {
        $topic = $this->get_topic_by_slug('rhapsody');
        if (!$topic) {
            return [];
        }

        $this->db->where('topic_id', $topic['id']);
        $this->db->where('year', $year);
        
        if ($month !== null) {
            $this->db->where('month', $month);
        }
        
        if ($day !== null) {
            $this->db->where('day', $day);
        }
        
        return $this->db
            ->order_by('year', 'ASC')
            ->order_by('month', 'ASC')
            ->order_by('day', 'ASC')
            ->get('tbl_category')
            ->result_array();
    }

    /**
     * Get Foundation School modules
     */
    public function get_foundation_school_modules()
    {
        $topic = $this->get_topic_by_slug('foundation_school');
        if (!$topic) {
            return [];
        }

        return $this->db
            ->where('topic_id', $topic['id'])
            ->where('category_type', 'module')
            ->order_by('row_order', 'ASC')
            ->get('tbl_category')
            ->result_array();
    }

    /**
     * Check if a category belongs to Foundation School topic
     * Foundation School quizzes don't award coins
     */
    public function is_foundation_school_category($category_id)
    {
        $topic = $this->get_topic_by_slug('foundation_school');
        if (!$topic) {
            return false;
        }

        // Check if category belongs to Foundation School
        $category = $this->db
            ->where('id', $category_id)
            ->get('tbl_category')
            ->row_array();

        if (!$category) {
            return false;
        }

        return $category['topic_id'] == $topic['id'];
    }

    /**
     * Add a new topic
     */
    public function add_topic($data)
    {
        $this->db->insert($this->table, $data);
        return $this->db->insert_id();
    }

    /**
     * Update a topic
     */
    public function update_topic($id, $data)
    {
        return $this->db
            ->where('id', $id)
            ->update($this->table, $data);
    }

    /**
     * Delete a topic (soft delete)
     */
    public function delete_topic($id)
    {
        return $this->db
            ->where('id', $id)
            ->update($this->table, ['is_active' => 0]);
    }

    /**
     * Get all Rhapsody years
     */
    public function get_rhapsody_years()
    {
        $topic = $this->get_topic_by_slug('rhapsody');
        if (!$topic) {
            return [];
        }

        return $this->db
            ->select('id, category_name as name, year')
            ->where('topic_id', $topic['id'])
            ->where('category_type', 'year')
            ->order_by('year', 'DESC')
            ->get('tbl_category')
            ->result_array();
    }

    /**
     * Get Rhapsody months for a specific year
     */
    public function get_rhapsody_months($year)
    {
        $topic = $this->get_topic_by_slug('rhapsody');
        if (!$topic) {
            return [];
        }

        $months = $this->db
            ->select('c.id, c.category_name as name, c.month, c.year, c.image,
                     (SELECT COUNT(*) FROM tbl_category d WHERE d.parent_id = c.id AND d.category_type = "day") as days_count,
                     (SELECT COUNT(*) FROM tbl_question q 
                      INNER JOIN tbl_category d ON q.category = d.id 
                      WHERE d.parent_id = c.id) as questions_count')
            ->where('c.topic_id', $topic['id'])
            ->where('c.category_type', 'month')
            ->where('c.year', $year)
            ->order_by('c.month', 'ASC')
            ->get('tbl_category c')
            ->result_array();

        return $months;
    }

    /**
     * Get Rhapsody days for a specific month
     */
    public function get_rhapsody_days($year, $month)
    {
        $topic = $this->get_topic_by_slug('rhapsody');
        if (!$topic) {
            return [];
        }

        return $this->db
            ->select('c.id, c.category_name as name, c.devotional_title as title, c.day, c.month, c.year,
                     (SELECT COUNT(*) FROM tbl_question q WHERE q.category = c.id) as questions_count')
            ->where('c.topic_id', $topic['id'])
            ->where('c.category_type', 'day')
            ->where('c.year', $year)
            ->where('c.month', $month)
            ->order_by('c.day', 'ASC')
            ->get('tbl_category c')
            ->result_array();
    }

    /**
     * Get Rhapsody day detail (full content)
     */
    public function get_rhapsody_day_detail($year, $month, $day)
    {
        $topic = $this->get_topic_by_slug('rhapsody');
        if (!$topic) {
            return null;
        }

        $detail = $this->db
            ->select('c.id, c.category_name as name, c.devotional_title as title, 
                     c.daily_text, c.scripture_ref, c.content_text, c.prayer_text, c.further_study,
                     c.day, c.month, c.year,
                     (SELECT COUNT(*) FROM tbl_question q WHERE q.category = c.id) as questions_count')
            ->where('c.topic_id', $topic['id'])
            ->where('c.category_type', 'day')
            ->where('c.year', $year)
            ->where('c.month', $month)
            ->where('c.day', $day)
            ->get('tbl_category c')
            ->row_array();

        return $detail;
    }

    /**
     * Get all Foundation School classes
     */
    public function get_foundation_classes()
    {
        $topic = $this->get_topic_by_slug('foundation_school');
        if (!$topic) {
            return [];
        }

        return $this->db
            ->select('c.id, c.category_name as name, c.devotional_title as title, 
                     c.content_text, c.row_order,
                     (SELECT COUNT(*) FROM tbl_question q WHERE q.category = c.id) as questions_count')
            ->where('c.topic_id', $topic['id'])
            ->where('c.parent_id IS NULL', null, false)
            ->order_by('c.row_order', 'ASC')
            ->get('tbl_category c')
            ->result_array();
    }

    /**
     * Get Foundation School class detail
     */
    public function get_foundation_class_detail($class_id)
    {
        $topic = $this->get_topic_by_slug('foundation_school');
        if (!$topic) {
            return null;
        }

        $detail = $this->db
            ->select('c.id, c.category_name as name, c.devotional_title as title, 
                     c.content_text, c.row_order,
                     (SELECT COUNT(*) FROM tbl_question q WHERE q.category = c.id) as questions_count')
            ->where('c.id', $class_id)
            ->where('c.topic_id', $topic['id'])
            ->get('tbl_category c')
            ->row_array();

        return $detail;
    }

    /**
     * Get latest Rhapsody months for home screen
     */
    public function get_latest_rhapsody_months($limit = 4)
    {
        $topic = $this->get_topic_by_slug('rhapsody');
        if (!$topic) {
            return [];
        }

        // Get current year and month
        $current_year = date('Y');
        $current_month = date('n');

        $months = $this->db
            ->select('c.id, c.category_name as name, c.month, c.year, c.image,
                     (SELECT COUNT(*) FROM tbl_question q 
                      INNER JOIN tbl_category d ON q.category = d.id 
                      WHERE d.parent_id = c.id) as questions_count')
            ->where('c.topic_id', $topic['id'])
            ->where('c.category_type', 'month')
            ->order_by('c.year', 'DESC')
            ->order_by('c.month', 'DESC')
            ->limit($limit)
            ->get('tbl_category c')
            ->result_array();

        return $months;
    }

    // =========================================================================
    // SOLO MODE (Practice Mode) - Random Questions by Topic
    // =========================================================================

    /**
     * Get random questions from ALL categories within a topic
     * Used for Solo Mode practice quizzes
     * 
     * @param string $topic_slug Topic slug (rhapsody or foundation_school)
     * @param int $count Number of questions to return (5, 10, 15, or 20)
     * @param int $language_id Optional language filter
     * @return array Random questions
     */
    public function get_random_questions_by_topic($topic_slug, $count = 10, $language_id = 0)
    {
        $topic = $this->get_topic_by_slug($topic_slug);
        if (!$topic) {
            return [];
        }

        // Build query to get random questions from all categories in this topic
        // Include category/source information for each question
        $this->db->select('q.*, c.id as source_id, c.category_name as source_name, c.year as source_year, c.month as source_month, c.day as source_day, c.topic_id as source_topic_id');
        $this->db->from('tbl_question q');
        $this->db->join('tbl_category c', 'q.category = c.id');
        $this->db->where('c.topic_id', $topic['id']);
        // Note: tbl_question doesn't have a status column
        
        if ($language_id > 0) {
            $this->db->where('q.language_id', $language_id);
        }
        
        // Random order and limit
        $this->db->order_by('RAND()');
        $this->db->limit($count);
        
        $questions = $this->db->get()->result_array();
        
        // Add human-readable source label to each question
        foreach ($questions as &$q) {
            $q['source_type'] = $topic_slug;
            $q['source_label'] = $this->_build_source_label($topic_slug, $q);
        }
        
        return $questions;
    }
    
    /**
     * Build human-readable source label for a question
     * @param string $topic_slug Topic slug (rhapsody or foundation_school)
     * @param array $question Question with source fields
     * @return string Source label e.g. "Rhapsody - December 25, 2025" or "Foundation - Module 1: Title"
     */
    private function _build_source_label($topic_slug, $question)
    {
        if ($topic_slug === 'rhapsody') {
            // Format: "Rhapsody - December 25, 2025"
            $year = $question['source_year'] ?? '';
            $month = $question['source_month'] ?? '';
            $day = $question['source_day'] ?? '';
            
            if ($year && $month && $day) {
                $month_name = date('F', mktime(0, 0, 0, intval($month), 1));
                return "Rhapsody - $month_name $day, $year";
            } elseif ($year && $month) {
                $month_name = date('F', mktime(0, 0, 0, intval($month), 1));
                return "Rhapsody - $month_name $year";
            }
            return "Rhapsody - " . ($question['source_name'] ?? 'Unknown');
        } else if ($topic_slug === 'foundation_school' || $topic_slug === 'foundation') {
            // Format: "Foundation - Module: Title"
            return "Foundation - " . ($question['source_name'] ?? 'Unknown Module');
        }
        
        return ($question['source_name'] ?? 'Quiz');
    }

    /**
     * Get total available questions count for a topic
     * 
     * @param string $topic_slug Topic slug
     * @return int Total questions count
     */
    public function get_topic_questions_count($topic_slug)
    {
        $topic = $this->get_topic_by_slug($topic_slug);
        if (!$topic) {
            return 0;
        }

        $this->db->from('tbl_question q');
        $this->db->join('tbl_category c', 'q.category = c.id');
        $this->db->where('c.topic_id', $topic['id']);
        // Note: tbl_question doesn't have a status column
        
        return $this->db->count_all_results();
    }

    /**
     * Get topics available for Solo Mode with question counts
     * 
     * @return array Topics with metadata for Solo Mode
     */
    public function get_solo_mode_topics()
    {
        $topics = $this->get_all_topics();
        $result = [];
        
        foreach ($topics as $topic) {
            $questions_count = $this->get_topic_questions_count($topic['slug']);
            
            // Only include topics that have questions
            if ($questions_count > 0) {
                $result[] = [
                    'id' => $topic['id'],
                    'slug' => $topic['slug'],
                    'name' => $topic['name'],
                    'description' => $topic['description'] ?? '',
                    'image' => $topic['image'] ?? '',
                    'topic_type' => $topic['topic_type'] ?? 'general',
                    'questions_count' => $questions_count,
                    'has_enough_questions' => $questions_count >= 5 // Minimum for Solo Mode
                ];
            }
        }
        
        return $result;
    }
}

