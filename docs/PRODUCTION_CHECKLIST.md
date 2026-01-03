# Production Deployment Checklist

## 📋 Pre-Deployment

### 1. Environment Configuration
- [ ] Copy `.env.example` to `.env`
- [ ] Set `CI_ENV=production`
- [ ] Generate strong `DB_PASSWORD` (min 20 chars)
- [ ] Generate strong `JWT_SECRET_KEY` (min 32 chars)
- [ ] Generate strong `REST_API_PASSWORD`
- [ ] Set correct `TZ` timezone
- [ ] Set `DAILY_CONTEST_AUTO_CREATE=true`
- [ ] Configure `NOTIFICATION_HOURS`

### 2. Firebase Setup
- [ ] Create Firebase project
- [ ] Download `firebase-service-account.json`
- [ ] Set `FCM_PROJECT_ID` in `.env`
- [ ] Configure APNs key for iOS notifications
- [ ] Deploy Firestore security rules

### 3. SSL Certificate
- [ ] Obtain SSL certificate (Let's Encrypt recommended)
- [ ] Place `fullchain.pem` in `infra/ssl/`
- [ ] Place `privkey.pem` in `infra/ssl/`
- [ ] Set `SSL_CERT_PATH` and `SSL_KEY_PATH` in `.env`

### 4. Domain Configuration
- [ ] Point domain A record to server IP
- [ ] Set `DOMAIN` in `.env`
- [ ] Update Nginx config if needed

---

## 🚀 Deployment

### 1. Server Setup
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt install docker-compose-plugin
```

### 2. Deploy Application
```bash
# Clone repository
git clone <repo-url> /opt/rhapsodie-quiz
cd /opt/rhapsodie-quiz

# Configure environment
cp .env.example .env
nano .env  # Edit configuration

# Deploy
./scripts/deploy.sh --build --ssl
```

### 3. Verify Deployment
```bash
# Check containers
docker compose ps

# Check logs
docker compose logs -f rhapsody-web
docker compose logs -f rhapsody-cron

# Test endpoints
curl -I https://your-domain.com
curl https://your-domain.com/api/health
```

---

## 📱 Mobile App Build

### Android
```bash
# Build release APK
./scripts/build-mobile.sh android

# Build App Bundle for Play Store
./scripts/build-mobile.sh android --aab --clean
```

### iOS
```bash
# Build iOS
./scripts/build-mobile.sh ios --clean

# Then in Xcode:
# 1. Open ios/Runner.xcworkspace
# 2. Product → Archive
# 3. Distribute App → App Store Connect
```

### Pre-Build Checklist
- [ ] Update `pubspec.yaml` version
- [ ] Update app icons
- [ ] Configure `firebase_options.dart`
- [ ] Update Android signing keys
- [ ] Update iOS provisioning profiles

---

## 🔒 Security Hardening

### Server
- [ ] Configure firewall (UFW)
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp
sudo ufw enable
```

- [ ] Disable root SSH login
- [ ] Use SSH keys only
- [ ] Install fail2ban

### Application
- [ ] Change default admin credentials
- [ ] Disable debug mode
- [ ] Enable HTTPS only
- [ ] Set secure cookies
- [ ] Configure rate limiting

### Database
- [ ] Use strong passwords
- [ ] Restrict database port access
- [ ] Enable query logging (temporary)
- [ ] Regular backups

---

## 📊 Monitoring Setup

### Essential Monitoring
- [ ] Uptime monitoring (UptimeRobot, Pingdom)
- [ ] Error tracking (Sentry)
- [ ] Log aggregation
- [ ] Database backup verification

### Recommended Tools
- **Uptime**: UptimeRobot (free tier)
- **Logs**: Docker logging driver + logrotate
- **Metrics**: Prometheus + Grafana (optional)
- **Alerts**: Discord/Slack webhooks

---

## 💾 Backup Strategy

### Automated Backups
```bash
# Add to crontab
0 3 * * * /opt/rhapsodie-quiz/scripts/export-db.sh

# Backup to cloud (optional)
0 4 * * * aws s3 cp /opt/rhapsodie-quiz/backups/ s3://bucket/backups/ --recursive
```

### Backup Retention
- Daily backups: Keep 7 days
- Weekly backups: Keep 4 weeks
- Monthly backups: Keep 12 months

---

## 🔄 Update Process

### Rolling Update
```bash
# Pull latest code
git pull origin main

# Rebuild and deploy
./scripts/deploy.sh --build --backup

# Verify
docker compose ps
curl -I https://your-domain.com
```

### Rollback
```bash
# Stop current
./scripts/stop.sh

# Restore backup
./scripts/import-db.sh backups/backup_YYYYMMDD.sql.gz

# Deploy previous version
git checkout <previous-commit>
./scripts/deploy.sh --build
```

---

## ✅ Post-Deployment

### Immediate Checks
- [ ] Admin panel accessible
- [ ] API endpoints responding
- [ ] Push notifications working
- [ ] Daily contest created
- [ ] Mobile app connecting

### Week 1 Monitoring
- [ ] Monitor error logs daily
- [ ] Check backup completion
- [ ] Verify notification delivery
- [ ] Test contest submission
- [ ] Check leaderboard updates

### Ongoing
- [ ] Weekly log review
- [ ] Monthly security updates
- [ ] Quarterly dependency updates
- [ ] Regular backup testing

