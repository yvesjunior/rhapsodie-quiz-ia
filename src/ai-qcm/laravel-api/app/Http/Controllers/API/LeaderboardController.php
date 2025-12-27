<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\UserScore;
use Illuminate\Http\Request;

class LeaderboardController extends Controller
{
    /**
     * Get global leaderboard across all QCMs
     */
    public function index(Request $request)
    {
        $limit = $request->get('limit', 50);
        
        $leaderboard = UserScore::with(['user:id,name', 'qcm:id,title'])
            ->selectRaw('user_id, SUM(score) as total_score, COUNT(*) as qcms_completed')
            ->groupBy('user_id')
            ->orderBy('total_score', 'desc')
            ->limit($limit)
            ->get()
            ->map(function ($item) {
                return [
                    'user' => $item->user,
                    'total_score' => $item->total_score,
                    'qcms_completed' => $item->qcms_completed,
                ];
            });

        return response()->json([
            'success' => true,
            'leaderboard' => $leaderboard,
        ]);
    }
}

