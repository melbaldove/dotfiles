# Docker Secret Mounting Implementation Plan

## Overview
Implement robust secret management by mounting agenix secrets directly into Docker containers, eliminating build-time secret reading issues.

## Implementation Plan

### Phase 1: Update Twenty CRM Arion Compose
1. **Remove `builtins.readFile` logic** from `twenty-crm.nix` module
2. **Modify Twenty `arion-compose.nix`** to:
   - Add volume mounts for `/run/agenix/` → `/secrets/` in containers
   - Support `passwordFile` and `appSecretFile` options  
   - Use file-based environment variables (e.g., `POSTGRES_PASSWORD_FILE=/secrets/twenty-db-password`)
3. **Update PostgreSQL service** to use `POSTGRES_PASSWORD_FILE` instead of `POSTGRES_PASSWORD`

### Phase 2: Update Ghost CMS Arion Compose  
1. **Remove `builtins.readFile` logic** from `ghost-cms.nix` module
2. **Modify Ghost `ghost-arion-compose.nix`** to:
   - Add volume mounts for agenix secrets
   - Support `passwordFile` for database and SMTP
   - Use file-based secrets for MySQL and Ghost containers

### Phase 3: Deploy and Test (Enhanced Verification)

#### 3.1 Deploy Changes
1. **Commit changes** to both dotfiles and Ghost repositories
2. **Update flake inputs** and deploy to newton

#### 3.2 Verify Secret Mounting
1. **Check secret files are mounted**:
   ```bash
   ssh newton "docker exec twenty-db-1 ls -la /secrets/"
   ssh newton "docker exec twenty-db-1 cat /secrets/twenty-db-password"
   ```

2. **Compare with host secrets**:
   ```bash
   ssh newton "sudo cat /run/agenix/twenty-db-password"
   # Should match the container output above
   ```

#### 3.3 Verify Correct Secret Usage
1. **Test Twenty CRM database connection** with agenix password:
   ```bash
   ssh newton "docker exec twenty-db-1 psql -U postgres -c 'SELECT current_user;'"
   ```

2. **Verify app secret** is the agenix value, not default:
   ```bash
   ssh newton "docker exec twenty-server-1 printenv APP_SECRET"
   # Should show: ZCeVt7Pf3vvaYVrof7Z1eROVxBLc6yq37M9TBdVZpWI=
   # NOT: replace_me_with_a_random_string
   ```

3. **Test Ghost CMS database** with agenix password:
   ```bash
   ssh newton "docker exec ghost-db-1 mysql -uroot -p\$(cat /secrets/ghost-db-password) -e 'SELECT USER();'"
   ```

#### 3.4 Functional Testing
1. **Twenty CRM web interface** loads correctly at https://crm.workwithnextdesk.com
2. **Ghost CMS web interface** loads correctly at https://blog.workwithnextdesk.com  
3. **No authentication errors** in container logs
4. **Existing data intact** - verify users can still log in

#### 3.5 Security Verification
1. **Confirm no secrets in environment**:
   ```bash
   ssh newton "docker exec twenty-db-1 printenv | grep -i password"
   # Should show POSTGRES_PASSWORD_FILE, not POSTGRES_PASSWORD
   ```

2. **Verify secret file permissions**:
   ```bash
   ssh newton "docker exec twenty-db-1 ls -la /secrets/"
   # Should be read-only for containers
   ```

## Key Changes Required

### Twenty arion-compose.nix
- Add volume: `/run/agenix:/secrets:ro` to all containers
- Change `POSTGRES_PASSWORD=value` to `POSTGRES_PASSWORD_FILE=/secrets/twenty-db-password`
- Change `APP_SECRET=value` to read from `/secrets/twenty-app-secret`

### Ghost arion-compose.nix
- Add volume: `/run/agenix:/secrets:ro` to containers  
- Change `MYSQL_ROOT_PASSWORD=value` to `MYSQL_ROOT_PASSWORD_FILE=/secrets/ghost-db-password`
- Update Ghost environment to read from mounted secret files

## Benefits
1. **Follows Docker security best practices** - using file-based secrets
2. **No secrets in environment variables** - which can be visible in process lists
3. **Direct secret access** - containers read from mounted files, not env vars
4. **Better for secret rotation** - files can be updated without restarting containers
5. **Eliminates build-time secret reading** - fixes pure evaluation mode errors

## Security Improvements
- Secrets never appear in process lists or environment dumps
- Read-only secret mounts prevent container compromise from modifying secrets
- Clear separation between secret management (host) and secret consumption (containers)
- Follows principle of least privilege for secret access