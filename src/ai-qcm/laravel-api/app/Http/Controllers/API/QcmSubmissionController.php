<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Qcm;
use App\Models\UserScore;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class QcmSubmissionController extends Controller
{
    /**
     * Submit answers for a QCM and calculate score
     */
    public function submit(Request $request, $qcmId)
    {
        $qcm = Qcm::findOrFail($qcmId);
        
        $validator = Validator::make($request->all(), [
            'answers' => 'required|array',
            'answers.*' => 'required|array', // Each answer is an array of selected options
            'time_taken' => 'nullable|integer|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $userAnswers = $request->answers;
        $questions = $qcm->questions;
        $score = 0;
        $correctAnswers = 0;
        $totalQuestions = count($questions);

        // Calculate score
        foreach ($questions as $index => $question) {
            $userAnswer = $userAnswers[$index] ?? [];
            $correctAnswer = $question['correct_answers'] ?? [];
            
            // Sort arrays for comparison
            sort($userAnswer);
            sort($correctAnswer);
            
            if ($userAnswer === $correctAnswer) {
                $score += 10; // 10 points per correct answer
                $correctAnswers++;
            }
        }

        // Get or create user score
        $userScore = UserScore::updateOrCreate(
            [
                'user_id' => Auth::id() ?? 1, // Use guest user ID 1 if not authenticated
                'qcm_id' => $qcmId,
            ],
            [
                'score' => $score,
                'total_questions' => $totalQuestions,
                'correct_answers' => $correctAnswers,
                'answers' => $userAnswers,
                'time_taken' => $request->time_taken,
                'completed_at' => now(),
            ]
        );

        return response()->json([
            'success' => true,
            'score' => $score,
            'total_questions' => $totalQuestions,
            'correct_answers' => $correctAnswers,
            'percentage' => $userScore->percentage,
            'rank' => $this->getUserRank($qcmId, $userScore->id),
            'leaderboard' => $qcm->leaderboard(10),
        ]);
    }

    /**
     * Get leaderboard for a specific QCM
     */
    public function leaderboard($qcmId)
    {
        $qcm = Qcm::findOrFail($qcmId);
        
        return response()->json([
            'success' => true,
            'qcm_id' => $qcmId,
            'qcm_title' => $qcm->title,
            'leaderboard' => $qcm->leaderboard(50),
        ]);
    }

    /**
     * Get user's rank for a QCM
     */
    private function getUserRank($qcmId, $userScoreId): int
    {
        $rank = UserScore::where('qcm_id', $qcmId)
            ->where('id', '<=', $userScoreId)
            ->orderBy('score', 'desc')
            ->orderBy('completed_at', 'asc')
            ->count();
        
        return $rank;
    }
}

