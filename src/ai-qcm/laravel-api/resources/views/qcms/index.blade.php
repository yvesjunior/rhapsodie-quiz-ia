<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>QCM Management - Laravel API</title>
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
        .header p {
            color: #666;
        }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .stat-card h3 {
            color: #667eea;
            font-size: 14px;
            text-transform: uppercase;
            margin-bottom: 10px;
        }
        .stat-card .value {
            font-size: 32px;
            font-weight: bold;
            color: #333;
        }
        .qcms-grid {
            display: grid;
            gap: 20px;
        }
        .qcm-card {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            transition: transform 0.2s;
        }
        .qcm-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 12px rgba(0,0,0,0.15);
        }
        .qcm-card h2 {
            color: #333;
            margin-bottom: 10px;
        }
        .qcm-card .meta {
            display: flex;
            gap: 20px;
            margin-top: 15px;
            color: #666;
            font-size: 14px;
        }
        .qcm-card .meta span {
            display: flex;
            align-items: center;
            gap: 5px;
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
        .btn-secondary {
            background: #6c757d;
        }
        .btn-secondary:hover {
            background: #5a6268;
        }
        .nav {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
        }
        .empty-state {
            background: white;
            padding: 60px;
            text-align: center;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .empty-state h2 {
            color: #666;
            margin-bottom: 10px;
        }
        .empty-state p {
            color: #999;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📚 QCM Management Dashboard</h1>
            <p>Manage and view all your QCMs (Multiple Choice Questions)</p>
        </div>

        <div class="nav">
            <a href="/" class="btn">🏠 Dashboard</a>
            <a href="/leaderboard" class="btn btn-secondary">🏆 Global Leaderboard</a>
            <a href="/api/qcm" class="btn btn-secondary" target="_blank">📡 API Endpoint</a>
        </div>

        <div class="stats">
            <div class="stat-card">
                <h3>Total QCMs</h3>
                <div class="value">{{ $qcms->count() }}</div>
            </div>
            <div class="stat-card">
                <h3>Total Questions</h3>
                <div class="value">{{ $qcms->sum('total_questions') }}</div>
            </div>
            <div class="stat-card">
                <h3>Total Submissions</h3>
                <div class="value">{{ $qcms->sum('scores_count') }}</div>
            </div>
        </div>

        @if($qcms->isEmpty())
            <div class="empty-state">
                <h2>No QCMs yet</h2>
                <p>Start by generating QCMs using your Python generator and pushing them to the API</p>
            </div>
        @else
            <div class="qcms-grid">
                @foreach($qcms as $qcm)
                    <div class="qcm-card">
                        <h2>{{ $qcm->title }}</h2>
                        <div class="meta">
                            <span>📝 {{ $qcm->total_questions }} questions</span>
                            <span>👥 {{ $qcm->scores_count }} submissions</span>
                            <span>📅 {{ $qcm->created_at->format('M d, Y') }}</span>
                        </div>
                        <a href="/qcm/{{ $qcm->id }}" class="btn">View Details & Leaderboard</a>
                    </div>
                @endforeach
            </div>
        @endif
    </div>
</body>
</html>

