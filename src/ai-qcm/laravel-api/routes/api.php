<?php

use App\Http\Controllers\API\QcmController;
use App\Http\Controllers\API\QcmSubmissionController;
use App\Http\Controllers\API\LeaderboardController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Public routes
Route::post('/register', [App\Http\Controllers\API\AuthController::class, 'register']);
Route::post('/login', [App\Http\Controllers\API\AuthController::class, 'login']);

// QCM routes (public read, protected write)
Route::get('/qcm', [QcmController::class, 'index']);
Route::get('/qcm/{id}', [QcmController::class, 'show']);
Route::post('/qcm', [QcmController::class, 'store'])->middleware('auth:sanctum'); // Protected - for Python generator

// QCM submission routes
Route::post('/qcm/{id}/submit', [QcmSubmissionController::class, 'submit']);
Route::get('/qcm/{id}/leaderboard', [QcmSubmissionController::class, 'leaderboard']);

// Leaderboard routes
Route::get('/leaderboard', [LeaderboardController::class, 'index']);

// Protected routes (require authentication)
Route::middleware('auth:sanctum')->group(function () {
    Route::delete('/qcm/{id}', [QcmController::class, 'destroy']);
    Route::get('/user/scores', function (Request $request) {
        return $request->user()->scores()->with('qcm:id,title')->get();
    });
    Route::post('/logout', [App\Http\Controllers\API\AuthController::class, 'logout']);
});
