<?php

namespace App\Http\Controllers;

use App\Models\Qcm;
use App\Models\UserScore;
use Illuminate\Http\Request;

class QcmViewController extends Controller
{
    /**
     * Display QCM management dashboard
     */
    public function index()
    {
        $qcms = Qcm::withCount('scores')
            ->orderBy('created_at', 'desc')
            ->get();
        
        return view('qcms.index', compact('qcms'));
    }

    /**
     * Display a specific QCM with leaderboard
     */
    public function show($id)
    {
        $qcm = Qcm::findOrFail($id);
        $leaderboard = $qcm->leaderboard(20);
        $totalSubmissions = $qcm->scores()->count();
        
        return view('qcms.show', compact('qcm', 'leaderboard', 'totalSubmissions'));
    }

    /**
     * Display global leaderboard
     */
    public function leaderboard()
    {
        $leaderboard = UserScore::with(['user:id,name', 'qcm:id,title'])
            ->selectRaw('user_id, SUM(score) as total_score, COUNT(*) as qcms_completed, MAX(completed_at) as last_activity')
            ->groupBy('user_id')
            ->orderBy('total_score', 'desc')
            ->limit(50)
            ->get();
        
        return view('leaderboard', compact('leaderboard'));
    }
}

