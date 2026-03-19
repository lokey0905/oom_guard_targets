#!/system/bin/sh
MODDIR="${0%/*}"
CFG="$MODDIR/config.sh"
TARGETS="$MODDIR/target.txt"
LOG_FILE_DEFAULT="/data/local/tmp/oom_guard.log"
LOG_ENABLED=1
LOG_FILE="$LOG_FILE_DEFAULT"
LOOP_INTERVAL=10
BOOT_DELAY=25

[ -f "$CFG" ] && . "$CFG"

log_msg() {
  [ "$LOG_ENABLED" = "1" ] || return 0
  local msg="$(date '+%Y-%m-%d %H:%M:%S') $*"
  echo "$msg" >> "$LOG_FILE"
}

trim() {
  local s="$*"
  s="${s#${s%%[![:space:]]*}}"
  s="${s%${s##*[![:space:]]}}"
  printf '%s' "$s"
}

find_pids_exact() {
  local proc="$1"
  local pids

  pids="$(pidof "$proc" 2>/dev/null)"
  if [ -n "$pids" ]; then
    echo "$pids"
    return 0
  fi

  ps -A 2>/dev/null | awk -v target="$proc" '
    NR > 1 {
      name=$NF
      if (name == target) print $2
    }
  '
}

write_oom_for_pid() {
  local pid="$1"
  local score="$2"
  local legacy="$3"
  local proc_name="$4"
  local current

  [ -n "$pid" ] || return 1
  [ -d "/proc/$pid" ] || return 1

  if [ -f "/proc/$pid/oom_score_adj" ]; then
    current="$(cat "/proc/$pid/oom_score_adj" 2>/dev/null)"
    if [ "$current" != "$score" ]; then
      echo "$score" > "/proc/$pid/oom_score_adj" 2>/dev/null
      current="$(cat "/proc/$pid/oom_score_adj" 2>/dev/null)"
      log_msg "set oom_score_adj proc=$proc_name pid=$pid target=$score actual=$current"
    fi
    return 0
  fi

  if [ -f "/proc/$pid/oom_adj" ]; then
    current="$(cat "/proc/$pid/oom_adj" 2>/dev/null)"
    if [ "$current" != "$legacy" ]; then
      echo "$legacy" > "/proc/$pid/oom_adj" 2>/dev/null
      current="$(cat "/proc/$pid/oom_adj" 2>/dev/null)"
      log_msg "set oom_adj proc=$proc_name pid=$pid target=$legacy actual=$current"
    fi
    return 0
  fi

  log_msg "skip no oom interface proc=$proc_name pid=$pid"
  return 1
}

protect_one_target() {
  local line="$1"
  local proc score legacy pids pid

  # Use whitespace-separated columns: process_name oom_score_adj oom_adj
  set -- $line
  proc="$(trim "$1")"
  score="$(trim "$2")"
  legacy="$(trim "$3")"

  [ -n "$proc" ] || return 0
  [ -n "$score" ] || score="-900"
  [ -n "$legacy" ] || legacy="-17"

  pids="$(find_pids_exact "$proc")"
  if [ -z "$pids" ]; then
    return 0
  fi

  for pid in $pids; do
    write_oom_for_pid "$pid" "$score" "$legacy" "$proc"
  done
}

main_loop() {
  while true; do
    if [ -f "$TARGETS" ]; then
      while IFS= read -r raw_line || [ -n "$raw_line" ]; do
        case "$raw_line" in
          ''|'#'*) continue ;;
        esac
        protect_one_target "$raw_line"
      done < "$TARGETS"
    else
      log_msg "target file not found: $TARGETS"
    fi
    sleep "$LOOP_INTERVAL"
  done
}

mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null
log_msg "service start boot_delay=$BOOT_DELAY interval=$LOOP_INTERVAL targets=$TARGETS"
sleep "$BOOT_DELAY"
main_loop
