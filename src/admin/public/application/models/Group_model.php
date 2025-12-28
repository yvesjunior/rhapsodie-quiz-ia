<?php

defined('BASEPATH') or exit('No direct script access allowed');

/**
 * Group Model
 * Handles operations for groups and group battles
 */
class Group_model extends CI_Model
{
    /**
     * Create a new group
     */
    public function create_group($owner_id, $name, $description = null, $image = null, $is_public = 0, $max_members = 50)
    {
        $invite_code = $this->generate_invite_code();
        
        $data = [
            'name' => $name,
            'description' => $description,
            'image' => $image,
            'owner_id' => $owner_id,
            'invite_code' => $invite_code,
            'is_public' => $is_public,
            'max_members' => $max_members,
            'member_count' => 1,
            'status' => 'active'
        ];
        
        $this->db->insert('tbl_group', $data);
        $group_id = $this->db->insert_id();
        
        // Add owner as member
        $this->add_member($group_id, $owner_id, 'owner');
        
        return $group_id;
    }

    /**
     * Generate unique invite code
     */
    private function generate_invite_code()
    {
        do {
            $code = strtoupper(substr(md5(uniqid(mt_rand(), true)), 0, 8));
            $exists = $this->db->where('invite_code', $code)->count_all_results('tbl_group');
        } while ($exists > 0);
        
        return $code;
    }

    /**
     * Get group by ID
     */
    public function get_group($group_id)
    {
        return $this->db
            ->where('id', $group_id)
            ->where('status', 'active')
            ->get('tbl_group')
            ->row_array();
    }

    /**
     * Get group by invite code
     */
    public function get_group_by_code($invite_code)
    {
        return $this->db
            ->where('invite_code', $invite_code)
            ->where('status', 'active')
            ->get('tbl_group')
            ->row_array();
    }

    /**
     * Get user's groups
     */
    public function get_user_groups($user_id)
    {
        return $this->db
            ->select('g.*, gm.role, gm.joined_at')
            ->from('tbl_group g')
            ->join('tbl_group_member gm', 'gm.group_id = g.id')
            ->where('gm.user_id', $user_id)
            ->where('gm.status', 'active')
            ->where('g.status', 'active')
            ->order_by('gm.joined_at', 'DESC')
            ->get()
            ->result_array();
    }

    /**
     * Add member to group
     */
    public function add_member($group_id, $user_id, $role = 'member')
    {
        // Check if already a member
        $existing = $this->db
            ->where('group_id', $group_id)
            ->where('user_id', $user_id)
            ->get('tbl_group_member')
            ->row_array();
        
        if ($existing) {
            if ($existing['status'] === 'active') {
                return false; // Already a member
            }
            // Reactivate membership
            $this->db
                ->where('id', $existing['id'])
                ->update('tbl_group_member', ['status' => 'active', 'role' => $role]);
        } else {
            $this->db->insert('tbl_group_member', [
                'group_id' => $group_id,
                'user_id' => $user_id,
                'role' => $role,
                'status' => 'active'
            ]);
        }
        
        // Update member count
        $this->update_member_count($group_id);
        
        return true;
    }

    /**
     * Remove member from group
     */
    public function remove_member($group_id, $user_id)
    {
        $this->db
            ->where('group_id', $group_id)
            ->where('user_id', $user_id)
            ->update('tbl_group_member', ['status' => 'banned']);
        
        $this->update_member_count($group_id);
        
        return true;
    }

    /**
     * Leave group
     */
    public function leave_group($group_id, $user_id)
    {
        // Check if owner
        $group = $this->get_group($group_id);
        if ($group && $group['owner_id'] == $user_id) {
            return false; // Owner cannot leave
        }
        
        $this->db
            ->where('group_id', $group_id)
            ->where('user_id', $user_id)
            ->delete('tbl_group_member');
        
        $this->update_member_count($group_id);
        
        return true;
    }

    /**
     * Get group members
     */
    public function get_members($group_id)
    {
        return $this->db
            ->select('gm.*, u.name, u.profile, u.email')
            ->from('tbl_group_member gm')
            ->join('tbl_users u', 'u.id = gm.user_id')
            ->where('gm.group_id', $group_id)
            ->where('gm.status', 'active')
            ->order_by('gm.role', 'ASC')
            ->order_by('gm.joined_at', 'ASC')
            ->get()
            ->result_array();
    }

    /**
     * Check if user is member
     */
    public function is_member($group_id, $user_id)
    {
        return $this->db
            ->where('group_id', $group_id)
            ->where('user_id', $user_id)
            ->where('status', 'active')
            ->count_all_results('tbl_group_member') > 0;
    }

    /**
     * Check if user is admin/owner
     */
    public function is_admin($group_id, $user_id)
    {
        return $this->db
            ->where('group_id', $group_id)
            ->where('user_id', $user_id)
            ->where('status', 'active')
            ->where_in('role', ['owner', 'admin'])
            ->count_all_results('tbl_group_member') > 0;
    }

    /**
     * Update member count
     */
    private function update_member_count($group_id)
    {
        $count = $this->db
            ->where('group_id', $group_id)
            ->where('status', 'active')
            ->count_all_results('tbl_group_member');
        
        $this->db
            ->where('id', $group_id)
            ->update('tbl_group', ['member_count' => $count]);
    }

    /**
     * Update group
     */
    public function update_group($group_id, $data)
    {
        return $this->db
            ->where('id', $group_id)
            ->update('tbl_group', $data);
    }

    /**
     * Delete group (soft delete)
     */
    public function delete_group($group_id)
    {
        return $this->db
            ->where('id', $group_id)
            ->update('tbl_group', ['status' => 'deleted']);
    }

    /**
     * Search public groups
     */
    public function search_groups($query, $limit = 20)
    {
        return $this->db
            ->like('name', $query)
            ->where('is_public', 1)
            ->where('status', 'active')
            ->limit($limit)
            ->get('tbl_group')
            ->result_array();
    }

    /**
     * Get all public groups (for discovery)
     * Excludes groups where user is already a member
     */
    public function get_public_groups($user_id = null, $limit = 50, $offset = 0)
    {
        $this->db
            ->select('g.*')
            ->from('tbl_group g')
            ->where('g.is_public', 1)
            ->where('g.status', 'active');
        
        // Exclude groups where user is already a member
        if ($user_id) {
            $this->db->where("g.id NOT IN (SELECT group_id FROM tbl_group_member WHERE user_id = $user_id AND status = 'active')", null, false);
        }
        
        return $this->db
            ->order_by('g.member_count', 'DESC')
            ->limit($limit, $offset)
            ->get()
            ->result_array();
    }

    /**
     * Join public group directly (no invite code needed)
     */
    public function join_public_group($group_id, $user_id)
    {
        $group = $this->get_group($group_id);
        
        if (!$group) {
            return ['success' => false, 'message' => 'Group not found'];
        }
        
        if ($group['is_public'] != 1) {
            return ['success' => false, 'message' => 'This group is private. You need an invite code to join.'];
        }
        
        if ($group['member_count'] >= $group['max_members']) {
            return ['success' => false, 'message' => 'Group is full'];
        }
        
        if ($this->is_member($group_id, $user_id)) {
            return ['success' => false, 'message' => 'You are already a member'];
        }
        
        $this->add_member($group_id, $user_id, 'member');
        
        return ['success' => true, 'group' => $this->get_group($group_id)];
    }

    /**
     * Get user's role in a group (or null if not a member)
     */
    public function get_user_role($group_id, $user_id)
    {
        $member = $this->db
            ->select('role, status')
            ->where('group_id', $group_id)
            ->where('user_id', $user_id)
            ->get('tbl_group_member')
            ->row_array();
        
        if ($member && $member['status'] === 'active') {
            return $member['role'];
        }
        return null;
    }

    /**
     * Delete a group and all related data (members, battles, entries)
     */
    public function delete_group_cascade($group_id)
    {
        // Delete group battle entries
        if ($this->db->table_exists('tbl_group_battle')) {
            $battles = $this->db->where('group_id', $group_id)->get('tbl_group_battle')->result_array();
            foreach ($battles as $battle) {
                if ($this->db->table_exists('tbl_group_battle_entry')) {
                    $this->db->where('battle_id', $battle['id'])->delete('tbl_group_battle_entry');
                }
            }
            $this->db->where('group_id', $group_id)->delete('tbl_group_battle');
        }
        
        // Delete group members
        $this->db->where('group_id', $group_id)->delete('tbl_group_member');
        
        // Delete the group
        $this->db->where('id', $group_id)->delete('tbl_group');
        
        return true;
    }

    /**
     * Delete all groups owned by a user
     */
    public function delete_user_groups($user_id)
    {
        $owned_groups = $this->db->where('owner_id', $user_id)->get('tbl_group')->result_array();
        
        foreach ($owned_groups as $group) {
            $this->delete_group_cascade($group['id']);
        }
        
        // Also remove user from any groups they are a member of
        $this->db->where('user_id', $user_id)->delete('tbl_group_member');
        
        return true;
    }

    /**
     * Cleanup orphaned groups (groups where owner no longer exists)
     */
    public function cleanup_orphaned_groups()
    {
        $orphaned = $this->db
            ->select('g.id')
            ->from('tbl_group g')
            ->where('g.owner_id NOT IN (SELECT id FROM tbl_users)', null, false)
            ->get()
            ->result_array();
        
        $count = 0;
        foreach ($orphaned as $group) {
            $this->delete_group_cascade($group['id']);
            $count++;
        }
        
        return $count;
    }
}

