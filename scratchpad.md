# Service Sanity Check Scratchpad

## Current State
- n8n service failing with "password authentication failed for user 'postgres'"
- Service shows `DynamicUser=true` (old config)
- Deployment keeps failing and rolling back
- Error: "Failed to spawn 'start-pre' task: No such file or directory"

## Root Cause Analysis
1. **Original Issue**: n8n service uses `DynamicUser=true` but secrets are owned by static `n8n` user
2. **My Fix**: Added preStart script + static user + environment file to read secrets and set DB_POSTGRESDB_PASSWORD
3. **Deployment Problem**: During deployment, systemd tries new config but preStart fails
4. **Rollback**: Deployment fails, rolls back to old config without preStart
5. **Error State**: systemd references preStart from failed deployment but old config has no preStart

## Why PreStart Fails
- Static `n8n` user can't access secret files during deployment
- OR preStart script path is incorrect/missing
- OR permissions issue with creating `/run/n8n-env`

## Evidence
- Twenty CRM works with same password → password itself is fine
- `/run/n8n-env` doesn't exist → preStart never ran successfully
- Service file shows old config → deployment rolled back
- systemd logs show "Failed to spawn 'start-pre' task" → preStart script missing/inaccessible

## Next Actions
1. Check if preStart script file exists and is executable
2. Verify static n8n user can access secret files
3. Test preStart script manually
4. Consider alternative approach (runtime environment script)

---

## RESOLUTION - July 16, 2025

### Final Root Cause
**n8n does NOT support `*_FILE` environment variables for reading secrets from files.**

The actual issue was NOT with:
- Database connectivity (✅ worked perfectly)
- Secret file permissions (✅ n8n user could read files)
- Network access (✅ localhost:5432 accessible)
- Password correctness (✅ manual connection worked)
- NixOS configuration (✅ environment variables set correctly)

### The Real Problem
n8n expects secret values **directly** in environment variables like:
- `DB_POSTGRESDB_PASSWORD=actual_password_value`
- `N8N_BASIC_AUTH_PASSWORD=actual_password_value`

NOT file references like:
- `DB_POSTGRESDB_PASSWORD_FILE=/path/to/password/file`
- `N8N_BASIC_AUTH_PASSWORD_FILE=/path/to/password/file`

### Solution
Created runtime systemd override with direct environment variables:
```bash
# /tmp/n8n-env
DB_POSTGRESDB_PASSWORD=actual_password_from_file
N8N_BASIC_AUTH_PASSWORD=actual_password_from_file
```

### Result
✅ n8n service running successfully
✅ Web interface accessible (HTTP 200)
✅ Database connection working
✅ nginx proxy working (https://n8n.workwithnextdesk.com)

### Lesson Learned
Always check application documentation for supported environment variable formats. Not all applications support the `*_FILE` pattern for secrets, even though it's a common Docker/container pattern.