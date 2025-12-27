<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Global Leaderboard - QCM API</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
        }
        .header {
            background: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 20px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            text-align: center;
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
        .leaderboard-card {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .leaderboard-item {
            display: flex;
            align-items: center;
            padding: 20px;
            margin-bottom: 15px;
            background: #f8f9fa;
            border-radius: 10px;
            transition: transform 0.2s;
        }
        .leaderboard-item:hover {
            transform: translateX(5px);
        }
        .leaderboard-item.top-1 {
            background: linear-gradient(135deg, #ffd700 0%, #ffed4e 100%);
        }
        .leaderboard-item.top-2 {
            background: linear-gradient(135deg, #c0c0c0 0%, #e8e8e8 100%);
        }
        .leaderboard-item.top-3 {
            background: linear-gradient(135deg, #cd7f32 0%, #e6a85c 100%);
        }
        .rank {
            font-size: 32px;
            font-weight: bold;
            color: #667eea;
            min-width: 60px;
            text-align: center;
        }
        .top-1 .rank, .top-2 .rank, .top-3 .rank {
            color: #333;
        }
        .user-info {
            flex: 1;
            margin-left: 20px;
        }
        .user-info strong {
            color: #333;
            font-size: 18px;
        }
        .user-info .meta {
            color: #666;
            font-size: 14px;
            margin-top: 5px;
        }
        .score-section {
            text-align: right;
        }
        .score {
            font-size: 28px;
            font-weight: bold;
            color: #28a745;
        }
        .badge {
            display: inline-block;
            padding: 5px 10px;
            background: #667eea;
            color: white;
            border-radius: 20px;
            font-size: 12px;
            margin-left: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🏆 Global Leaderboard</h1>
            <p>Top performers across all QCMs</p>
            <a href="/" class="btn">← Back to Dashboard</a>
        </div>

        <div class="leaderboard-card">
            @if($leaderboard->isEmpty())
                <p style="text-align: center; padding: 40px; color: #666;">
                    No scores yet. Start competing!
                </p>
            @else
                @foreach($leaderboard as $index => $entry)
                    <div class="leaderboard-item {{ $index < 3 ? 'top-' . ($index + 1) : '' }}">
                        <div class="rank">
                            @if($index === 0) 🥇
                            @elseif($index === 1) 🥈
                            @elseif($index === 2) 🥉
                            @else #{{ $index + 1 }}
                            @endif
                        </div>
                        <div class="user-info">
                            <strong>{{ $entry->user->name ?? 'Guest User' }}</strong>
                            <div class="meta">
                                Completed {{ $entry->qcms_completed }} QCM{{ $entry->qcms_completed !== 1 ? 's' : '' }}
                                @if($entry->last_activity)
                                    • Last activity: {{ \Carbon\Carbon::parse($entry->last_activity)->diffForHumans() }}
                                @endif
                            </div>
                        </div>
                        <div class="score-section">
                            <div class="score">{{ number_format($entry->total_score) }} pts</div>
                        </div>
                    </div>
                @endforeach
            @endif
        </div>
    </div>
</body>
</html>

