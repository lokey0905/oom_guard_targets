OOM Guard Targets Module
========================

Language
--------
- English (this page)
- 中文: [README.md](README.md)

Purpose
-------
This module continuously reads target.txt and reapplies oom_score_adj (preferred) or
oom_adj (legacy fallback) to matching processes, reducing the chance they are killed too early
under memory pressure. Intended for rooted devices with Magisk.

Current Project Files
---------------------
- module.prop: Magisk module metadata
- service.sh: late_start service loop for OOM enforcement
- config.sh: module settings (boot delay, loop interval, logging)
- target.txt: target process list and OOM values

Config Settings (config.sh)
---------------------------
You can tune the following parameters:

```sh
BOOT_DELAY=25
LOOP_INTERVAL=2
LOG_ENABLED=1
LOG_FILE="/data/local/tmp/oom_guard.log"
LOG_BOOT_CLEAN_ENABLED=1
LOG_BOOT_CLEAN_MAX_KB=1024
```

Details:
- BOOT_DELAY: delay (seconds) after boot before enforcement starts
- LOOP_INTERVAL: interval (seconds) between each protection pass
- LOG_ENABLED: 1 enables logging, 0 disables logging
- LOG_FILE: log output path
- LOG_BOOT_CLEAN_ENABLED: 1 enables boot-time log size check and cleanup, 0 disables it
- LOG_BOOT_CLEAN_MAX_KB: cleanup threshold in KB; when log size is greater than or equal to this value, old log is removed (1024 = 1MB)

After changing config, reboot is recommended so the service starts with new values.

target.txt Format
-----------------
One process per line, fields separated by spaces:

```text
process_name oom_score_adj oom_adj
```

Examples:

```text
com.example.app -900 -17
com.example.app:overlay -1000 -17
com.example.app:map_overlay -1000 -17
```

Rules:
- If column 2 is omitted, oom_score_adj defaults to -900
- If column 3 is omitted, oom_adj defaults to -17
- Lines beginning with # are ignored

Recommended Values
------------------
- Main process: -800 or -900
- Critical overlays: -900 or -1000
- Use -1000 carefully; it is aggressive and may increase pressure on other apps.

Log
---
Default log path:

```text
/data/local/tmp/oom_guard.log
```

View log:

```sh
su -c 'tail -f /data/local/tmp/oom_guard.log'
```

Boot cleanup behavior:
- At service start, log size is checked once
- If `LOG_BOOT_CLEAN_ENABLED=1` and file size >= `LOG_BOOT_CLEAN_MAX_KB` (KB), old log is removed
- Logging then continues in a new file

Notes
-----
- Android may rewrite oom_score_adj as process states change, so this module reapplies repeatedly.
- This does NOT turn an app into a true system daemon like system_server.
- Some OEM battery/background policies can still interfere; disable battery optimization for target apps.
