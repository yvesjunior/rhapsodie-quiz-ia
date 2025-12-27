<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Qcm extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'questions',
        'total_questions',
        'is_active',
    ];

    protected $casts = [
        'questions' => 'array',
        'is_active' => 'boolean',
    ];

    /**
     * Get all scores for this QCM
     */
    public function scores(): HasMany
    {
        return $this->hasMany(UserScore::class);
    }

    /**
     * Get leaderboard for this QCM
     */
    public function leaderboard(int $limit = 10)
    {
        return $this->scores()
            ->with('user:id,name')
            ->orderBy('score', 'desc')
            ->orderBy('completed_at', 'asc')
            ->limit($limit)
            ->get();
    }
}

