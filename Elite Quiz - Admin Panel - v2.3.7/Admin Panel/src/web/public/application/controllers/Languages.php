<?php

defined('BASEPATH') or exit('No direct script access allowed');

class Languages extends CI_Controller
{

    public function __construct()
    {
        parent::__construct();
        if (!$this->session->userdata('isLoggedIn')) {
            redirect('/');
        }
        $this->load->config('quiz');
    }

    public function index()
    {
        // Check if user has permission to view either languages or system languages
        $has_languages_permission = has_permissions('read', 'languages');
        $has_system_languages_permission = has_permissions('read', 'system_languages');
        
        if (!$has_languages_permission && !$has_system_languages_permission) {
            redirect('/');
        }
        
        // Handle Languages POST actions
        if ($this->input->post('btncreate')) {
            if (!has_permissions('create', 'languages')) {
                $this->session->set_flashdata('error', lang(PERMISSION_ERROR_MSG));
            } else {
                $result = $this->Language_model->add_new_data();

                $setData = [
                    'language_name' => $this->input->post('language_name'),
                    'language_code' => $this->input->post('language_code'),
                ];
                if ($result['error']) {
                    $this->session->set_userdata($setData);
                    $this->session->set_flashdata('error', $result['message']);
                } else {
                    $this->session->unset_userdata($setData);
                    $this->session->set_flashdata('success', $result['message']);
                }
            }
            redirect('languages');
        } else if ($this->input->post('btnadd')) {
            if (!has_permissions('create', 'languages')) {
                $this->session->set_flashdata('error', lang(PERMISSION_ERROR_MSG));
            } else {
                $this->Language_model->add_data();
                $this->session->set_flashdata('success', lang('language_added_successfully'));
            }
            redirect('languages');
        } else if ($this->input->post('btnupdate')) {
            if (!has_permissions('update', 'languages')) {
                $this->session->set_flashdata('error', lang(PERMISSION_ERROR_MSG));
            } else {
                $result = $this->Language_model->update_data();
                if ($result && $result['message']) {
                    $this->session->set_flashdata('success', $result['message']);
                }
            }
            redirect('languages');
        }
        
        // Handle System Languages POST actions - redirect to System_Languages controller
        $system_lang_actions = ['btnadd', 'btnupdate', 'btnaddapp', 'btnupdateapp', 'btnaddweb', 'btnupdateweb'];
        $is_system_lang_action = false;
        $system_action = '';
        
        foreach ($system_lang_actions as $action) {
            if ($this->input->post($action)) {
                // Check if this is a system language action (not languages action)
                if ($action == 'btnadd' && !$this->input->post('language_id')) {
                    // This is system language add (no language_id means it's system language)
                    $is_system_lang_action = true;
                    $system_action = $action;
                    break;
                } elseif ($action != 'btnadd') {
                    // All other actions are system language actions
                    $is_system_lang_action = true;
                    $system_action = $action;
                    break;
                }
            }
        }
        
        if ($is_system_lang_action && $has_system_languages_permission) {
            // Redirect to System_Languages controller to handle the action
            redirect('system-languages');
            return;
        }
        
        // Load data for both sections
        $this->result['language'] = $has_languages_permission ? $this->Language_model->get_all_lang() : [];
        $this->result['has_languages_permission'] = $has_languages_permission;
        $this->result['has_system_languages_permission'] = $has_system_languages_permission;
        
        // Load unified view with tabs
        $this->load->view('languages_unified', $this->result);
    }

    public function delete_language()
    {
        if (!has_permissions('delete', 'languages')) {
            echo FALSE;
        } else {
            $id = $this->input->post('id');
            $this->Language_model->delete_data($id);
            echo TRUE;
        }
    }
}
