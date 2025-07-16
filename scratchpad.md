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

### Final Root Cause (CORRECTED)
**n8n DOES support `*_FILE` environment variables, BUT with a critical requirement!**

The actual issue was NOT with:
- Database connectivity (✅ worked perfectly)
- Secret file permissions (✅ n8n user could read files)
- Network access (✅ localhost:5432 accessible)
- Password correctness (✅ manual connection worked)
- NixOS configuration (✅ environment variables set correctly)

### The Real Problem
n8n's `_FILE` implementation has a crucial requirement that wasn't immediately obvious:

**The base environment variable key MUST exist in the config schema for `_FILE` to work.**

From n8n's source code:
```javascript
if (variableName in this) {
  const data = await readFile(filePath, 'utf8');
  // @ts-ignore
  this[variableName] = data.trim();
}
```

This means:
- `DB_POSTGRESDB_PASSWORD_FILE` only works if `DB_POSTGRESDB_PASSWORD` is already known to the config system
- `N8N_BASIC_AUTH_PASSWORD_FILE` only works if `N8N_BASIC_AUTH_PASSWORD` is already in the schema

### Why It Failed
The NixOS n8n module was generating a minimal config file (`/nix/store/.../n8n.json`) with:
```json
{
  "port": 5678
}
```

This config file didn't include the database or auth configuration keys, so when n8n's config system loaded:
1. It only knew about `port` from the config file
2. Environment variables like `DB_POSTGRESDB_PASSWORD_FILE` were ignored because `DB_POSTGRESDB_PASSWORD` wasn't in the loaded config schema
3. The `_FILE` handling code skipped these variables entirely

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
1. **Documentation can be misleading**: n8n docs claim `_FILE` support but don't mention the schema requirement
2. **Implementation details matter**: Always check the source code when things don't work as documented
3. **Config generation matters**: The NixOS module's minimal config generation prevented the `_FILE` feature from working

### Permanent Fix Options
1. **Override systemd environment** (current workaround): Set direct password values in runtime override
2. **Fix NixOS module**: Modify the n8n NixOS module to generate a complete config with all schema keys
3. **Use preStart script**: Create a wrapper that reads `_FILE` variables and exports direct values
4. **Patch n8n**: Submit PR to n8n to handle `_FILE` variables without schema requirement