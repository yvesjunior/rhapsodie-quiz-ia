# Google Login Stuck/Failing - Fix Guide

## Problem
Google login gets stuck or fails during authentication process.

## Root Cause Analysis

The login flow:
1. User clicks "Sign in with Google"
2. Mobile app authenticates with Firebase using Google credentials
3. Mobile app calls API endpoint `user_signup` with Firebase ID
4. API verifies Firebase ID using `verify_user()` function
5. API creates/updates user and returns JWT token
6. Mobile app stores token and navigates to home

**Potential Issues:**
- `verify_user()` function might be slow or timing out
- Firebase Admin SDK network call might be hanging
- API endpoint might not be accessible from mobile app
- Firebase project mismatch between mobile app and admin panel

## Solutions

### Solution 1: Check Firebase Configuration

1. **Verify Firebase Project Match:**
   - Mobile app uses: `rhapsodie-quizz` (from `firebase.json`)
   - Admin panel uses: `rhapsodie-quizz` (from `firebase_config.json`)
   - ✅ They match

2. **Check Firebase Config File:**
   ```bash
   cd "Rhapsody Quiz - Admin Panel - v2.3.7"
   ls -la Admin\ Panel/src/web/public/assets/firebase_config.json
   ```
   - File should exist and be readable
   - Should contain valid service account credentials

### Solution 2: Add Timeout Handling (Recommended)

The `verify_user()` function might be hanging. We can add timeout or disable verification for development.

**Option A: Disable Verification (Development Only)**

Edit `Api.php` line 76:
```php
// ------- Should be Enabled for server  ----------
// $is_verify = $this->verify_user($firebase_id);
// ---------------------------------------------------
// ------- Should be Disable for server  ----------
$is_verify = true;  // Disable for local development
// ---------------------------------------------------
```

**Option B: Add Timeout to verify_user()**

Modify the `verify_user()` function to add timeout handling.

### Solution 3: Check API Accessibility

1. **Test API Endpoint:**
   ```bash
   curl -X POST http://localhost:8080/api/user_signup \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "firebase_id=test123&type=gmail"
   ```

2. **Check Mobile App API URL:**
   - Open: `Rhapsody Quiz - Mobile - v2.3.7/lib/core/config/config.dart`
   - Verify `panelUrl` is correct:
     - iOS Simulator: `http://localhost:8080`
     - Physical device: Your Mac's IP (e.g., `http://10.0.0.39:8080`)

### Solution 4: Check Network Connectivity

1. **From Mobile App:**
   - Ensure device/simulator can reach `localhost:8080` or your Mac's IP
   - Check firewall settings
   - Verify admin panel is running: `docker-compose ps`

2. **Check API Logs:**
   ```bash
   cd "Rhapsody Quiz - Admin Panel - v2.3.7"
   docker logs elite-quiz-admin-web --tail 50
   ```

### Solution 5: Enable Debug Logging

Add logging to see where it's getting stuck:

1. **In Mobile App:**
   - Check Flutter console for errors
   - Look for network timeout errors
   - Check Firebase authentication errors

2. **In Admin Panel:**
   - Check PHP error logs
   - Add logging to `verify_user()` function

## Quick Fix (Development)

For local development, temporarily disable Firebase verification:

1. Edit: `Rhapsody Quiz - Admin Panel - v2.3.7/Admin Panel/src/web/public/application/controllers/Api.php`
2. Find line 76: `$is_verify = $this->verify_user($firebase_id);`
3. Replace with: `$is_verify = true;` (temporarily)
4. Rebuild admin panel: `docker-compose down && docker-compose up -d`

**⚠️ Warning:** Only do this for local development. Re-enable verification for production.

## Testing Steps

1. **Clear App Data:**
   - Uninstall and reinstall mobile app, OR
   - Clear app data/cache

2. **Test Google Login:**
   - Open app
   - Click "Sign in with Google"
   - Select Google account
   - Wait for authentication

3. **Check for Errors:**
   - Mobile app console
   - Admin panel logs
   - Network requests in browser dev tools (if testing web)

## Common Issues

### Issue: "Network Error" or Timeout
- **Cause:** API not accessible from mobile device
- **Fix:** Use Mac's IP address instead of localhost for physical devices

### Issue: "Invalid Firebase ID"
- **Cause:** Firebase verification failing
- **Fix:** Check Firebase config file, or temporarily disable verification

### Issue: "User Not Found" in Firebase
- **Cause:** Firebase project mismatch
- **Fix:** Ensure mobile app and admin panel use same Firebase project

### Issue: API Returns Error 101 (Invalid Access)
- **Cause:** Firebase verification failed
- **Fix:** Check Firebase config or disable verification for development

## Production Considerations

For production:
1. Keep `verify_user()` enabled
2. Add proper timeout handling
3. Monitor API response times
4. Set up proper error logging
5. Use HTTPS for API calls

