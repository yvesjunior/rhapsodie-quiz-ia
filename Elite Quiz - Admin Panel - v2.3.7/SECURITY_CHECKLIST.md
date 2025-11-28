# Security Checklist for Elite Quiz Admin Panel

## 🔒 Critical Security Actions Required

### ⚠️ IMMEDIATE ACTIONS (Do These First!)

1. **Rotate All Exposed Secrets**
   - [ ] Change database password from default `rootpassword`
   - [ ] Generate new JWT secret key (minimum 32 characters)
   - [ ] Change REST API credentials from default `admin:1234`
   - [ ] Regenerate Firebase service account key
   - [ ] Update all in-app purchase shared secrets

2. **Secure Firebase Credentials**
   - [ ] Verify `firebase_config.json` is in `.gitignore`
   - [ ] Remove `firebase_config.json` from git history if it was committed
   - [ ] Upload new Firebase config through admin panel
   - [ ] Revoke old Firebase service account key

3. **Environment Variables Setup**
   - [ ] Copy `.env.example` to `.env`
   - [ ] Fill in all required values in `.env`
   - [ ] Verify `.env` is in `.gitignore`
   - [ ] Never commit `.env` file to version control

4. **Database Security**
   - [ ] Change default database password
   - [ ] Use strong, unique password (minimum 16 characters)
   - [ ] Update `docker-compose.yml` to use environment variables
   - [ ] Restrict database access to application server only

### 📋 Configuration Checklist

#### Environment Variables
- [ ] `DB_HOST` - Database hostname
- [ ] `DB_USER` - Database username
- [ ] `DB_PASSWORD` - Strong database password
- [ ] `DB_NAME` - Database name
- [ ] `JWT_SECRET_KEY` - Strong random string (32+ characters)
- [ ] `REST_API_USERNAME` - REST API username
- [ ] `REST_API_PASSWORD` - Strong REST API password

#### Files to Secure
- [ ] `.env` file exists and is in `.gitignore`
- [ ] `firebase_config.json` is in `.gitignore`
- [ ] Database backup files are excluded from git
- [ ] Log files are excluded from git

#### Code Updates
- [ ] `database.php` reads from environment variables
- [ ] `rest.php` reads credentials from environment variables
- [ ] `Api.php` reads JWT secret from environment variables
- [ ] `docker-compose.yml` uses environment variables (no hardcoded defaults)

### 🔐 Best Practices

#### Password Requirements
- [ ] Database password: Minimum 16 characters, mix of letters, numbers, symbols
- [ ] JWT secret: Minimum 32 characters, cryptographically random
- [ ] REST API password: Minimum 12 characters, unique from other passwords

#### Access Control
- [ ] Review user permissions in admin panel
- [ ] Disable unused user accounts
- [ ] Enable two-factor authentication if available
- [ ] Regularly audit access logs

#### File Permissions
- [ ] `.env` file: 600 (read/write owner only)
- [ ] `firebase_config.json`: 600 (read/write owner only)
- [ ] Configuration files: 644 (read owner/group, read others)

#### Network Security
- [ ] Use HTTPS in production
- [ ] Restrict database port access
- [ ] Use firewall rules to limit access
- [ ] Enable SSL/TLS for database connections in production

### 🚨 Security Audit

#### Check for Exposed Secrets
- [ ] Search git history for committed secrets
- [ ] Review all configuration files for hardcoded credentials
- [ ] Check for secrets in log files
- [ ] Verify no secrets in error messages

#### Code Review
- [ ] No hardcoded passwords in source code
- [ ] No API keys in client-side code
- [ ] Proper input validation and sanitization
- [ ] SQL injection protection in place
- [ ] XSS protection enabled

### 📝 Documentation

- [ ] Document all environment variables
- [ ] Create runbook for secret rotation
- [ ] Document backup and recovery procedures
- [ ] Keep security incident response plan

### 🔄 Ongoing Maintenance

#### Regular Tasks
- [ ] Rotate secrets every 90 days
- [ ] Review access logs monthly
- [ ] Update dependencies regularly
- [ ] Review and update security policies
- [ ] Conduct security audits quarterly

#### Monitoring
- [ ] Set up alerts for failed login attempts
- [ ] Monitor for unusual database access
- [ ] Track API usage patterns
- [ ] Review error logs regularly

---

## 🛠️ Implementation Steps

1. **Create `.env` file from `.env.example`**
   ```bash
   cp .env.example .env
   ```

2. **Generate secure passwords**
   ```bash
   # Generate JWT secret
   openssl rand -base64 32
   
   # Generate database password
   openssl rand -base64 24
   ```

3. **Update environment variables**
   - Edit `.env` file with secure values
   - Update `docker-compose.yml` if using Docker

4. **Restart services**
   ```bash
   docker-compose down
   docker-compose up -d
   ```

5. **Verify configuration**
   - Test database connection
   - Test API authentication
   - Verify Firebase connectivity

---

## ⚠️ Important Notes

- **NEVER** commit `.env` file to version control
- **NEVER** commit `firebase_config.json` to version control
- **ALWAYS** use environment variables for secrets
- **ROTATE** all secrets immediately after exposure
- **REVIEW** this checklist regularly

---

## 📞 Security Incident Response

If secrets are exposed:
1. Rotate all affected secrets immediately
2. Review access logs for unauthorized access
3. Revoke compromised credentials
4. Notify relevant stakeholders
5. Document the incident

---

**Last Updated:** [Current Date]
**Next Review:** [Date + 90 days]

