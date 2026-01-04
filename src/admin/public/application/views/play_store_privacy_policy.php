<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <title>Privacy Policy | <?php echo (is_settings('app_name')) ? is_settings('app_name') : "Rhapsody Quiz" ?></title>
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
            <h1>🔒 Privacy Policy</h1>
            <p><?php echo (is_settings('app_name')) ? is_settings('app_name') : "Rhapsody Quiz" ?></p>
        </div>
        
        <div class="content">
            <?php if (!empty($setting['message'])): ?>
                <?php echo $setting['message']; ?>
            <?php else: ?>
                <p><strong>Last Updated:</strong> January 2026</p>

                <p>Rhapsody Quiz ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application.</p>

                <h2>1. Information We Collect</h2>

                <h3>Account Information</h3>
                <ul>
                    <li>Email address (when signing up with email)</li>
                    <li>Username and profile picture</li>
                    <li>Phone number (if using phone authentication)</li>
                    <li>Authentication data from Google, Apple, or Firebase</li>
                </ul>

                <h3>Usage Data</h3>
                <ul>
                    <li>Quiz scores and progress</li>
                    <li>Leaderboard rankings</li>
                    <li>Daily contest participation</li>
                    <li>In-app coins and rewards</li>
                </ul>

                <h3>Device Information</h3>
                <ul>
                    <li>Device type and operating system</li>
                    <li>Push notification tokens (if notifications enabled)</li>
                    <li>App version</li>
                </ul>

                <h2>2. How We Use Your Information</h2>
                <ul>
                    <li>To provide and maintain the app functionality</li>
                    <li>To track your quiz progress and display leaderboards</li>
                    <li>To send push notifications about daily contests (if enabled)</li>
                    <li>To improve our services and user experience</li>
                    <li>To respond to your support requests</li>
                </ul>

                <h2>3. Data Sharing</h2>
                <p>We do not sell your personal information. We may share data with:</p>
                <ul>
                    <li><strong>Firebase (Google)</strong> - For authentication and data storage</li>
                    <li><strong>Service providers</strong> - Who help us operate the app</li>
                    <li><strong>Legal authorities</strong> - When required by law</li>
                </ul>

                <h2>4. Data Security</h2>
                <p>We implement industry-standard security measures to protect your data, including:</p>
                <ul>
                    <li>Encrypted data transmission (HTTPS/SSL)</li>
                    <li>Secure authentication via Firebase</li>
                    <li>Regular security updates</li>
                </ul>

                <h2>5. Your Rights</h2>
                <p>You have the right to:</p>
                <ul>
                    <li><strong>Access</strong> - Request a copy of your data</li>
                    <li><strong>Correction</strong> - Update inaccurate information</li>
                    <li><strong>Deletion</strong> - Request account deletion</li>
                    <li><strong>Opt-out</strong> - Disable push notifications</li>
                </ul>

                <h2>6. Account Deletion</h2>
                <p>To delete your account:</p>
                <ul>
                    <li>Go to Settings → Delete Account in the app, or</li>
                    <li>Email us at <a href="mailto:kiwanoinc@gmail.com">kiwanoinc@gmail.com</a></li>
                </ul>
                <p>Account deletion is processed within 30 days.</p>

                <h2>7. Children's Privacy</h2>
                <p>Our app is designed for users of all ages. We do not knowingly collect personal information from children under 13 without parental consent.</p>

                <h2>8. Changes to This Policy</h2>
                <p>We may update this Privacy Policy from time to time. We will notify you of any significant changes through the app.</p>

                <h2>9. Contact Us</h2>
                <p>For privacy-related questions or requests, contact us at:</p>
                <p>📧 Email: <a href="mailto:kiwanoinc@gmail.com">kiwanoinc@gmail.com</a></p>
            <?php endif; ?>
        </div>

        <div class="footer">
            <p>© <?php echo date('Y'); ?> <?php echo (is_settings('app_name')) ? is_settings('app_name') : "Rhapsody Quiz" ?>. All rights reserved.</p>
        </div>
    </div>
</body>

</html>
