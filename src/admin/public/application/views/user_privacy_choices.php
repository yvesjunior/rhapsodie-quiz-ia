<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <title>User Privacy Choices | <?php echo (is_settings('app_name')) ? is_settings('app_name') : "Rhapsody Quiz" ?></title>
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            line-height: 1.6;
            color: #333;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 2rem;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 16px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            color: white;
            padding: 2rem;
            text-align: center;
        }
        .header h1 {
            font-size: 1.8rem;
            margin-bottom: 0.5rem;
        }
        .header p {
            opacity: 0.8;
            font-size: 1rem;
        }
        .content {
            padding: 2rem;
        }
        h2 {
            color: #1a1a2e;
            margin: 1.5rem 0 1rem;
            font-size: 1.3rem;
        }
        p {
            margin-bottom: 1rem;
            color: #555;
        }
        ul {
            margin: 1rem 0 1rem 2rem;
            color: #555;
        }
        li {
            margin-bottom: 0.5rem;
        }
        .contact-box {
            background: #f8f9fa;
            border-left: 4px solid #667eea;
            padding: 1.5rem;
            margin: 1.5rem 0;
            border-radius: 0 8px 8px 0;
        }
        .contact-box a {
            color: #667eea;
            text-decoration: none;
            font-weight: 600;
        }
        .contact-box a:hover {
            text-decoration: underline;
        }
        .btn {
            display: inline-block;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 12px 24px;
            border-radius: 8px;
            text-decoration: none;
            font-weight: 600;
            margin-top: 1rem;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
        }
        .footer {
            text-align: center;
            padding: 1.5rem;
            background: #f8f9fa;
            color: #666;
            font-size: 0.9rem;
        }
        @media (max-width: 600px) {
            body {
                padding: 1rem;
            }
            .content {
                padding: 1.5rem;
            }
        }
    </style>
</head>

<body>
    <div class="container">
        <div class="header">
            <h1>🔒 User Privacy Choices</h1>
            <p><?php echo (is_settings('app_name')) ? is_settings('app_name') : "Rhapsody Quiz" ?></p>
        </div>
        
        <div class="content">
            <h2>Your Privacy Rights</h2>
            <p>We respect your privacy and give you control over your personal data. You have the right to:</p>
            <ul>
                <li><strong>Access</strong> - Request a copy of your personal data</li>
                <li><strong>Correction</strong> - Request correction of inaccurate data</li>
                <li><strong>Deletion</strong> - Request deletion of your account and data</li>
                <li><strong>Portability</strong> - Receive your data in a portable format</li>
            </ul>

            <h2>Data We Collect</h2>
            <p>Our app collects minimal data to provide our services:</p>
            <ul>
                <li>Account information (email, username, profile picture)</li>
                <li>Quiz progress and scores</li>
                <li>Device tokens for push notifications (optional)</li>
            </ul>

            <h2>Request Account Deletion</h2>
            <p>To delete your account and all associated data, you can:</p>
            <ul>
                <li>Go to <strong>Settings → Delete Account</strong> in the app</li>
                <li>Or email us at the address below</li>
            </ul>
            <p>Account deletion is processed within 30 days. Some data may be retained for legal compliance.</p>

            <h2>Opt-Out Options</h2>
            <ul>
                <li><strong>Push Notifications</strong> - Disable in your device settings or app settings</li>
                <li><strong>Analytics</strong> - We use anonymous analytics to improve the app</li>
            </ul>

            <div class="contact-box">
                <h2 style="margin-top: 0;">Contact Us</h2>
                <p>For privacy-related requests or questions, please contact us:</p>
                <p>📧 Email: <a href="mailto:kiwanoinc@gmail.com">kiwanoinc@gmail.com</a></p>
                <a href="mailto:kiwanoinc@gmail.com?subject=Privacy%20Request%20-%20Rhapsody%20Quiz" class="btn">
                    Submit Privacy Request
                </a>
            </div>
        </div>

        <div class="footer">
            <p>Last updated: <?php echo date('F Y'); ?></p>
            <p><a href="play-store-privacy-policy" style="color: #667eea;">View Full Privacy Policy</a></p>
        </div>
    </div>
</body>

</html>

