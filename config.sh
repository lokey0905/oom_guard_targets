# OOM Guard module config
# Seconds to wait after boot completed enough for apps/services to appear
BOOT_DELAY=25
# Seconds between protection passes
LOOP_INTERVAL=2
# 1 = write log, 0 = disable log
LOG_ENABLED=1
# Log file path
LOG_FILE="/data/local/tmp/oom_guard.log"
# 1 = check log size at boot and remove file if too large
LOG_BOOT_CLEAN_ENABLED=1
# Boot cleanup threshold in KB (1024 = 1MB)
LOG_BOOT_CLEAN_MAX_KB=1024
