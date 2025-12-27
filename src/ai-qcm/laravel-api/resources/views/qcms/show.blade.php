<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $qcm->title }} - QCM Details</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .header {
            background: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 20px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .header h1 {
            color: #333;
            margin-bottom: 10px;
        }
        .btn {
            display: inline-block;
            padding: 10px 20px;
            background: #667eea;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin-top: 15px;
            transition: background 0.2s;
        }
        .btn:hover {
            background: #5568d3;
        }
        .content {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }
        .card {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .card h2 {
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #667eea;
        }
        .question-item {
            padding: 15px;
            margin-bottom: 15px;
            background: #f8f9fa;
            border-radius: 5px;
            border-left: 4px solid #667eea;
        }
        .question-item strong {
            color: #333;
        }
        .options {
            margin-top: 10px;
            padding-left: 20px;
        }
        .options li {
            margin: 5px 0;
            color: #666;
        }
        .correct {
            color: #28a745;
            font-weight: bold;
        }
        .leaderboard-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 15px;
            margin-bottom: 10px;
            background: #f8f9fa;
            border-radius: 5px;
        }
        .rank {
            font-size: 24px;
            font-weight: bold;
            color: #667eea;
            min-width: 40px;
        }
        .user-info {
            flex: 1;
            margin-left: 15px;
        }
        .user-info strong {
            color: #333;
        }
        .score {
            font-size: 20px;
            font-weight: bold;
            color: #28a745;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 15px;
            margin-bottom: 20px;
        }
        .stat {
            text-align: center;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 5px;
        }
        .stat .value {
            font-size: 28px;
            font-weight: bold;
            color: #667eea;
        }
        .stat .label {
            color: #666;
            font-size: 12px;
            text-transform: uppercase;
            margin-top: 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>{{ $qcm->title }}</h1>
            <a href="/" class="btn">← Back to Dashboard</a>
        </div>

        <div class="stats-grid">
            <div class="stat">
                <div class="value">{{ $qcm->total_questions }}</div>
                <div class="label">Questions</div>
            </div>
            <div class="stat">
                <div class="value">{{ $totalSubmissions }}</div>
                <div class="label">Submissions</div>
            </div>
            <div class="stat">
                <div class="value">{{ $leaderboard->count() }}</div>
                <div class="label">Leaderboard Entries</div>
            </div>
        </div>

        <div class="content">
            <div class="card">
                <h2>📝 Questions</h2>
                @foreach($qcm->questions as $index => $question)
                    <div class="question-item">
                        <strong>Q{{ $index + 1 }}: {{ $question['question'] }}</strong>
                        <ul class="options">
                            @foreach($question['options'] as $option)
                                <li class="{{ in_array($option[0], $question['correct_answers']) ? 'correct' : '' }}">
                                    {{ $option }}
                                    @if(in_array($option[0], $question['correct_answers']))
                                        ✓
                                    @endif
                                </li>
                            @endforeach
                        </ul>
                        @if(isset($question['explanation']) && $question['explanation'])
                            <p style="margin-top: 10px; color: #666; font-style: italic;">
                                💡 {{ $question['explanation'] }}
                            </p>
                        @endif
                        @if(isset($question['reference']) && $question['reference'])
                            <p style="margin-top: 5px; color: #667eea; font-size: 12px;">
                                📖 {{ $question['reference'] }}
                            </p>
                        @endif
                    </div>
                @endforeach
            </div>

            <div class="card">
                <h2>🏆 Leaderboard</h2>
                @if($leaderboard->isEmpty())
                    <p style="color: #666; text-align: center; padding: 40px;">
                        No submissions yet. Be the first!
                    </p>
                @else
                    @foreach($leaderboard as $index => $score)
                        <div class="leaderboard-item">
                            <div class="rank">#{{ $index + 1 }}</div>
                            <div class="user-info">
                                <strong>{{ $score->user->name ?? 'Guest' }}</strong><br>
                                <small style="color: #666;">
                                    {{ $score->correct_answers }}/{{ $score->total_questions }} correct
                                    @if($score->time_taken)
                                        • {{ gmdate('i:s', $score->time_taken) }}
                                    @endif
                                </small>
                            </div>
                            <div class="score">{{ $score->score }} pts</div>
                        </div>
                    @endforeach
                @endif
            </div>
        </div>
    </div>
</body>
</html>

