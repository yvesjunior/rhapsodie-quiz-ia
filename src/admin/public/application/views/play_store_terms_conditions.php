<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <title>Terms & Conditions | <?php echo (is_settings('app_name')) ? is_settings('app_name') : "Rhapsody Quiz" ?></title>
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            line-height: 1.7;
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
        }
        .content {
            padding: 2rem;
        }
        h2 {
            color: #1a1a2e;
            margin: 2rem 0 1rem;
            font-size: 1.3rem;
            border-bottom: 2px solid #667eea;
            padding-bottom: 0.5rem;
        }
        h3 {
            color: #444;
            margin: 1.5rem 0 0.5rem;
            font-size: 1.1rem;
        }
        p {
            margin-bottom: 1rem;
            color: #555;
        }
        ul {
            margin: 1rem 0 1rem 1.5rem;
            color: #555;
        }
        li {
            margin-bottom: 0.5rem;
        }
        a {
            color: #667eea;
        }
        .footer {
            text-align: center;
            padding: 1.5rem;
            background: #f8f9fa;
            color: #666;
            font-size: 0.9rem;
        }
        @media (max-width: 600px) {
            body { padding: 1rem; }
            .content { padding: 1.5rem; }
        }
    </style>
</head>

<body>
    <div class="container">
        <div class="header">
            <h1>📜 Terms & Conditions</h1>
            <p><?php echo (is_settings('app_name')) ? is_settings('app_name') : "Rhapsody Quiz" ?></p>
        </div>
        
        <div class="content">
            <?php if (!empty($setting['message'])): ?>
                <?php echo $setting['message']; ?>
            <?php else: ?>
                <p><strong>Last Updated:</strong> January 2026</p>

                <p>Welcome to Rhapsody Quiz! By downloading, accessing, or using our application, you agree to be bound by these Terms and Conditions.</p>

                <h2>1. Acceptance of Terms</h2>
                <p>By using Rhapsody Quiz, you agree to these terms. If you do not agree, please do not use the app.</p>

                <h2>2. Description of Service</h2>
                <p>Rhapsody Quiz is an educational quiz application based on Rhapsody of Realities devotional content. Features include:</p>
                <ul>
                    <li>Daily quizzes and contests</li>
                    <li>Leaderboards and rankings</li>
                    <li>Foundation School learning modules</li>
                    <li>Multiplayer battle modes</li>
                    <li>In-app coins and rewards</li>
                </ul>

                <h2>3. User Accounts</h2>
                <ul>
                    <li>You must provide accurate information when creating an account</li>
                    <li>You are responsible for maintaining the security of your account</li>
                    <li>One account per person is allowed</li>
                    <li>We reserve the right to suspend accounts that violate these terms</li>
                </ul>

                <h2>4. User Conduct</h2>
                <p>You agree NOT to:</p>
                <ul>
                    <li>Use cheats, exploits, or automation software</li>
                    <li>Create multiple accounts to gain unfair advantages</li>
                    <li>Harass or abuse other users</li>
                    <li>Use offensive usernames or profile pictures</li>
                    <li>Attempt to access other users' accounts</li>
                    <li>Reverse engineer or modify the app</li>
                </ul>

                <h2>5. In-App Coins</h2>
                <ul>
                    <li>Coins are virtual currency with no real-world value</li>
                    <li>Coins cannot be exchanged for real money</li>
                    <li>We may adjust coin values and rewards at any time</li>
                    <li>Coins may be forfeited if terms are violated</li>
                </ul>

                <h2>6. Intellectual Property</h2>
                <ul>
                    <li>All content, including questions and images, is our property or licensed to us</li>
                    <li>Rhapsody of Realities content is used with appropriate permissions</li>
                    <li>You may not copy, distribute, or modify our content</li>
                </ul>

                <h2>7. Disclaimers</h2>
                <ul>
                    <li>The app is provided "as is" without warranties</li>
                    <li>We do not guarantee uninterrupted service</li>
                    <li>We are not liable for any indirect damages</li>
                    <li>Quiz content is for educational purposes only</li>
                </ul>

                <h2>8. Modifications</h2>
                <p>We reserve the right to:</p>
                <ul>
                    <li>Modify or discontinue features at any time</li>
                    <li>Update these terms with notice through the app</li>
                    <li>Change leaderboard rules and contest formats</li>
                </ul>

                <h2>9. Termination</h2>
                <p>We may terminate or suspend your account if you:</p>
                <ul>
                    <li>Violate these terms</li>
                    <li>Engage in fraudulent activity</li>
                    <li>Abuse the platform or other users</li>
                </ul>

                <h2>10. Governing Law</h2>
                <p>These terms are governed by the laws of Canada. Any disputes will be resolved in the courts of Quebec, Canada.</p>

                <h2>11. Contact</h2>
                <p>For questions about these terms, contact us at:</p>
                <p>📧 Email: <a href="mailto:kiwanoinc@gmail.com">kiwanoinc@gmail.com</a></p>
            <?php endif; ?>
        </div>

        <div class="footer">
            <p>© <?php echo date('Y'); ?> <?php echo (is_settings('app_name')) ? is_settings('app_name') : "Rhapsody Quiz" ?>. All rights reserved.</p>
            <p><a href="play-store-privacy-policy">Privacy Policy</a></p>
        </div>
    </div>
</body>

</html>
