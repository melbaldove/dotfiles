# Migration Plan: Twenty CRM PostgreSQL Password to Agenix

## Current Situation Analysis

### Identified Issues
- **Hardcoded password**: "postgres" in `/home/melbournebaldove/twenty/arion-compose.nix:14` and `arion-compose.nix:189`
- **Security risk**: Database password is stored in plain text in the configuration
- **Existing data**: PostgreSQL data volume `twenty_db-data` at `/var/lib/docker/volumes/twenty_db-data/_data`
- **Agenix infrastructure**: Already configured in `twenty-crm.nix:100-104` but not currently used

### Current Configuration
- **Database volume**: `twenty_db-data` (local Docker volume)
- **PostgreSQL version**: 16
- **Current password**: "postgres"
- **Data location**: `/var/lib/docker/volumes/twenty_db-data/_data`

## Migration Strategy Options

### Option 1: Zero-Downtime Migration (Recommended)

This approach creates a new PostgreSQL instance with the secure password and migrates data without service interruption.

#### Phase 1: Preparation (No Downtime)
1. **Create database backup**:
   ```bash
   ssh newton "docker exec twenty-db-1 pg_dump -U postgres -d default > /tmp/twenty_backup_$(date +%Y%m%d_%H%M%S).sql"
   ```

2. **Generate and encrypt new password**:
   ```bash
   # Generate strong password
   openssl rand -base64 32 > /tmp/new_postgres_password
   
   # Encrypt with agenix
   cd /home/melbournebaldove/dotfiles
   agenix -e secrets/twenty-db-password.age
   # Paste the generated password and save
   
   # Clean up temporary password file
   rm /tmp/new_postgres_password
   ```

3. **Create new PostgreSQL volume**:
   ```bash
   ssh newton "docker volume create twenty_db-data-new"
   ```

#### Phase 2: Data Migration (Minimal Downtime)
1. **Start new PostgreSQL instance with secure password**:
   ```bash
   ssh newton "docker run -d --name twenty-db-migration \
     -v twenty_db-data-new:/var/lib/postgresql/data \
     -e POSTGRES_USER=postgres \
     -e POSTGRES_PASSWORD=\$(cat /run/agenix/twenty-db-password) \
     -p 5434:5432 \
     postgres:16"
   ```

2. **Wait for new database to initialize**:
   ```bash
   ssh newton "docker logs -f twenty-db-migration"
   # Wait for "database system is ready to accept connections"
   ```

3. **Restore data to new instance**:
   ```bash
   ssh newton "docker exec -i twenty-db-migration psql -U postgres -d postgres < /tmp/twenty_backup_*.sql"
   ```

4. **Verify data integrity**:
   ```bash
   ssh newton "docker exec twenty-db-migration psql -U postgres -d default -c '\dt'"
   ```

#### Phase 3: Configuration Update
1. **Update Twenty CRM configuration**:
   ```bash
   # Edit hosts/newton/default.nix
   # Add to services.twenty-crm.database:
   passwordFile = config.age.secrets.twenty-db-password.path;
   ```

2. **Update arion-compose.nix to use passwordFile**:
   ```bash
   # Modify the configuration to read from passwordFile instead of hardcoded value
   ```

#### Phase 4: Atomic Switchover
1. **Stop Twenty services**:
   ```bash
   ssh newton "sudo systemctl stop twenty"
   ```

2. **Rename volumes for atomic switch**:
   ```bash
   ssh newton "docker volume create twenty_db-data-backup"
   ssh newton "docker run --rm -v twenty_db-data:/from -v twenty_db-data-backup:/to alpine ash -c 'cd /from && cp -a . /to'"
   ssh newton "docker volume rm twenty_db-data"
   ssh newton "docker volume create twenty_db-data"
   ssh newton "docker run --rm -v twenty_db-data-new:/from -v twenty_db-data:/to alpine ash -c 'cd /from && cp -a . /to'"
   ```

3. **Deploy new configuration**:
   ```bash
   deploy --remote-build --skip-checks --hostname newton .#newton
   ```

4. **Verify service startup**:
   ```bash
   ssh newton "sudo systemctl status twenty"
   ssh newton "docker ps | grep twenty"
   ```

#### Phase 5: Verification and Cleanup
1. **Test Twenty CRM functionality**:
   ```bash
   curl -f https://crm.workwithnextdesk.com/healthz
   ```

2. **Clean up migration containers and volumes**:
   ```bash
   ssh newton "docker stop twenty-db-migration"
   ssh newton "docker rm twenty-db-migration"
   ssh newton "docker volume rm twenty_db-data-new"
   ssh newton "rm /tmp/twenty_backup_*.sql"
   ```

3. **Keep backup volume for safety**:
   ```bash
   # Keep twenty_db-data-backup for 7 days before removal
   ```

### Option 2: Simple Migration (Brief Downtime)

This approach updates the password in the existing volume with a brief service interruption.

#### Steps:
1. **Create backup** (same as Option 1, Phase 1, step 1)
2. **Stop Twenty services**:
   ```bash
   ssh newton "sudo systemctl stop twenty"
   ```

3. **Start temporary PostgreSQL with old password**:
   ```bash
   ssh newton "docker run --rm -d --name temp-postgres \
     -v twenty_db-data:/var/lib/postgresql/data \
     -e POSTGRES_PASSWORD=postgres \
     -p 5433:5432 \
     postgres:16"
   ```

4. **Change password**:
   ```bash
   ssh newton "docker exec temp-postgres psql -U postgres -c \"ALTER USER postgres PASSWORD '\$(cat /run/agenix/twenty-db-password)';\""
   ```

5. **Stop temporary container**:
   ```bash
   ssh newton "docker stop temp-postgres"
   ```

6. **Deploy new configuration** (same as Option 1, Phase 4, step 3)

## Rollback Plan

### If Migration Fails
1. **Restore from backup volume**:
   ```bash
   ssh newton "docker volume rm twenty_db-data"
   ssh newton "docker volume create twenty_db-data"
   ssh newton "docker run --rm -v twenty_db-data-backup:/from -v twenty_db-data:/to alpine ash -c 'cd /from && cp -a . /to'"
   ```

2. **Revert configuration changes**:
   ```bash
   git checkout HEAD~1 -- hosts/newton/default.nix
   deploy --remote-build --skip-checks --hostname newton .#newton
   ```

### If Service Won't Start
1. **Check logs**:
   ```bash
   ssh newton "sudo journalctl -u twenty -f"
   ssh newton "docker logs twenty-db-1"
   ```

2. **Manual database restoration**:
   ```bash
   ssh newton "docker exec -i twenty-db-1 psql -U postgres -d postgres < /tmp/twenty_backup_*.sql"
   ```

## Configuration Changes Required

### 1. hosts/newton/default.nix
```nix
services.twenty-crm = {
  enable = true;
  serverUrl = "https://crm.workwithnextdesk.com";
  port = 3000;
  
  database = {
    user = "postgres";
    passwordFile = config.age.secrets.twenty-db-password.path;  # Add this line
  };
  
  # ... rest of configuration
};
```

### 2. modules/system/linux/twenty-crm.nix
Update the configuration reading logic to properly handle passwordFile:
```nix
# Around line 126-128, ensure passwordFile is used when available
database = config.services.twenty-crm.database // {
  password = if config.services.twenty-crm.database.passwordFile != null
    then builtins.readFile config.services.twenty-crm.database.passwordFile
    else "postgres";
};
```

## Pre-Migration Checklist

- [ ] Verify agenix is working and can decrypt existing secrets
- [ ] Confirm backup strategy is tested and working
- [ ] Check available disk space for backup volumes
- [ ] Verify network connectivity to newton
- [ ] Plan maintenance window (if using Option 2)
- [ ] Test new password strength and compliance
- [ ] Verify all team members are aware of the migration

## Post-Migration Verification

- [ ] Twenty CRM web interface loads correctly
- [ ] Database connections are working
- [ ] All existing data is intact
- [ ] Performance is normal
- [ ] Logs show no authentication errors
- [ ] Backup processes are working with new password

## Security Improvements Achieved

1. **Eliminated hardcoded passwords** in configuration files
2. **Encrypted password storage** using agenix
3. **Reduced attack surface** by removing plain text secrets
4. **Improved secret rotation** capability for future updates
5. **Better compliance** with security best practices

## Estimated Timeline

- **Option 1 (Zero-downtime)**: 2-3 hours total
  - Preparation: 30 minutes
  - Migration: 1 hour
  - Verification: 30 minutes
  - Cleanup: 30 minutes

- **Option 2 (Brief downtime)**: 1-1.5 hours total
  - Downtime: 15-30 minutes
  - Total process: 1 hour

## Notes

- Use Option 1 for production environments
- Option 2 is acceptable for development/staging
- Always test the rollback procedure before migration
- Keep backup volumes for at least 7 days after successful migration
- Document the new password location for team members