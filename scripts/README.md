# Rhapsodie Quiz IA - Scripts

## 🚀 Deployment Scripts

### `deploy.sh` - Production Deployment
Deploy the backend to production.

```bash
# Standard deploy
./scripts/deploy.sh

# Rebuild images and deploy
./scripts/deploy.sh --build

# Deploy with SSL enabled
./scripts/deploy.sh --ssl

# Full deploy with backup
./scripts/deploy.sh --build --backup --ssl
```

Options:
- `--build` - Rebuild Docker images
- `--ssl` - Enable HTTPS with Nginx reverse proxy
- `--backup` - Backup database before deploying
- `--migrate` - Run migrations after deploy
- `--quick` - Skip health checks

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

### `check_daily_contest.sh` - Check Contest Status
```bash
./scripts/check_daily_contest.sh
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
├── deploy.sh              # Production deployment
├── build-mobile.sh        # Mobile app build
├── start.sh               # Start development
├── stop.sh                # Stop services
├── export-db.sh           # Database export
├── import-db.sh           # Database import
├── create_daily_contest.sh # Create contest
├── check_daily_contest.sh  # Check contest
├── test_fcm.sh            # Test notifications
├── test_weekly_rewards.sh  # Test rewards
├── generate-secrets.sh     # Generate secrets
└── README.md              # This file
```
