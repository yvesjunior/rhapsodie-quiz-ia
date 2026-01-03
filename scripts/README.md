# Rhapsodie Quiz IA - Scripts

## 🚀 Deployment Scripts

### `deploy.sh` - Production Deployment
Deploy the backend to production. Pulls images from Docker Hub and starts services.

```bash
# Standard deploy (pull from Docker Hub)
./scripts/deploy.sh

# Deploy with database backup
./scripts/deploy.sh --backup

# Build images locally (dev only)
./scripts/deploy.sh --build

# Quick deploy (skip health checks)
./scripts/deploy.sh --quick
```

Options:
- `--build` - Build Docker images locally (dev machine only)
- `--backup` - Backup database before deploying
- `--migrate` - Run migrations after deploy
- `--quick` - Skip health checks

> **Note:** SSL is handled by your external Nginx reverse proxy (kiwanoinc.ca)

### `build-mobile.sh` - Mobile App Build
Build the Flutter mobile app for release.

```bash
# Build Android APK
./scripts/build-mobile.sh android

# Build Android App Bundle (for Play Store)
./scripts/build-mobile.sh android --aab

# Build iOS (requires macOS)
./scripts/build-mobile.sh ios

# Build both platforms
./scripts/build-mobile.sh all

# Clean build
./scripts/build-mobile.sh android --clean
```

---

## 🔧 Development Scripts

### `start.sh` - Start Development Environment
```bash
# Start core services
./scripts/start.sh

# Start with development tools
./scripts/start.sh --tools

# Start with AI services
./scripts/start.sh --ai
```

### `stop.sh` - Stop Services
```bash
# Stop containers
./scripts/stop.sh

# Stop and remove volumes
./scripts/stop.sh --volumes

# Stop and remove everything
./scripts/stop.sh --all
```

---

## 📊 Database Scripts

### `export-db.sh` - Export Database
```bash
./scripts/export-db.sh
```

### `import-db.sh` - Import Database
```bash
./scripts/import-db.sh backup_file.sql
```

---

## 🏆 Contest Scripts

### `create_daily_contest.sh` - Create Daily Contest
```bash
# Create today's contest
./scripts/create_daily_contest.sh

# Force create (even if exists)
./scripts/create_daily_contest.sh --force
```

### `clear_today_contest.sh` - Delete Today's Contest
Delete today's daily contest to test cron job creation. User scores are preserved.
```bash
./scripts/clear_today_contest.sh
```

### `check_daily_contest.sh` - Check Contest Status
```bash
./scripts/check_daily_contest.sh
```

### `set_contest_hour.sh` - Set Daily Contest Creation Hour
Configure when the daily contest cron job runs.
```bash
# Show current setting and help
./scripts/set_contest_hour.sh

# Set to 5 PM (for testing)
./scripts/set_contest_hour.sh 17

# Set to midnight (production default)
./scripts/set_contest_hour.sh 0

# Other examples
./scripts/set_contest_hour.sh 8   # 8 AM
./scripts/set_contest_hour.sh 12  # Noon
```

---

## 🔔 Notification Scripts

### `test_fcm.sh` - Test Push Notifications
```bash
./scripts/test_fcm.sh
```

### `test_weekly_rewards.sh` - Test Weekly Rewards
```bash
./scripts/test_weekly_rewards.sh
```

---

## 🔐 Security Scripts

### `generate-secrets.sh` - Generate Secure Credentials
```bash
./scripts/generate-secrets.sh
```

---

## 📁 File Structure

```
scripts/
├── deploy.sh               # Production deployment
├── build-mobile.sh         # Mobile app build
├── start.sh                # Start development
├── stop.sh                 # Stop services
├── export-db.sh            # Database export
├── import-db.sh            # Database import
├── create_daily_contest.sh # Create daily contest
├── clear_today_contest.sh  # Delete today's contest (for testing)
├── check_daily_contest.sh  # Check contest status
├── set_contest_hour.sh     # Configure cron schedule
├── test_fcm.sh             # Test notifications
├── test_weekly_rewards.sh  # Test rewards
├── generate-secrets.sh     # Generate secrets
└── README.md               # This file
```

---

## ⚙️ Environment Variables

These can be set in `.env`:

| Variable | Default | Description |
|----------|---------|-------------|
| `DAILY_CONTEST_AUTO_CREATE` | `false` | Enable automatic daily contest creation |
| `DAILY_CONTEST_HOUR` | `0` | Hour to create contest (0-23, 0=midnight) |
| `NOTIFICATION_HOURS` | `8,13,22` | Hours to send notifications (24h format) |
| `TZ` | `America/Montreal` | Timezone for cron jobs |
