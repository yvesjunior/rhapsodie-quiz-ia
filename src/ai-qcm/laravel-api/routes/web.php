<?php

use App\Http\Controllers\QcmViewController;
use Illuminate\Support\Facades\Route;

Route::get('/', [QcmViewController::class, 'index']);
Route::get('/qcm/{id}', [QcmViewController::class, 'show']);
Route::get('/leaderboard', [QcmViewController::class, 'leaderboard']);
