<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_scores', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('qcm_id')->constrained()->onDelete('cascade');
            $table->integer('score')->default(0); // Points earned
            $table->integer('total_questions')->default(0);
            $table->integer('correct_answers')->default(0);
            $table->json('answers')->nullable(); // Store user's answers
            $table->integer('time_taken')->nullable(); // Time in seconds
            $table->timestamp('completed_at')->nullable();
            $table->timestamps();
            
            // Ensure one score per user per QCM
            $table->unique(['user_id', 'qcm_id']);
            
            // Index for leaderboard queries
            $table->index(['qcm_id', 'score', 'completed_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_scores');
    }
};

