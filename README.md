OOM 保護目標模組
================

語言 / Language
---------------
- 中文（目前頁面）
- English: [README_EN.md](README_EN.md)

用途
----
本模組會持續讀取 target.txt，對符合的程序反覆套用 oom_score_adj（優先）或 oom_adj（舊版備援），
降低被低記憶體機制提早清掉的機率。適用於已 Root 並安裝 Magisk 的裝置。

目前專案檔案
------------
- module.prop: Magisk 模組資訊
- service.sh: late_start 服務主迴圈，持續執行 OOM 保護
- config.sh: 模組參數（開機延遲、輪詢間隔、日誌設定）
- target.txt: 目標程序清單與 OOM 值

config 設定（config.sh）
-----------------------
可調整以下參數：

```sh
BOOT_DELAY=25
LOOP_INTERVAL=10
LOG_ENABLED=1
LOG_FILE="/data/local/tmp/oom_guard.log"
```

說明：
- BOOT_DELAY: 開機後延遲幾秒才開始保護，避免太早啟動抓不到程序
- LOOP_INTERVAL: 每次重套 OOM 值的間隔秒數
- LOG_ENABLED: 1 為啟用日誌，0 為停用日誌
- LOG_FILE: 日誌輸出路徑

調整後建議重新開機，讓服務用新設定啟動

target.txt 格式
---------------
每行一個程序，欄位以空格分隔：

```text
process_name oom_score_adj oom_adj
```

範例：

```text
com.example.app -900 -17
com.example.app:overlay -1000 -17
com.example.app:map_overlay -1000 -17
```

規則：
- 第 2 欄省略時，oom_score_adj 預設為 -900
- 第 3 欄省略時，oom_adj 預設為 -17
- 以 # 開頭的行會被忽略

建議值
------
- 主程序：-800 或 -900
- 關鍵 overlay：-900 或 -1000
- -1000 較激進，請謹慎使用，可能增加其他 App 被回收的壓力

日誌
----
預設路徑：

```text
/data/local/tmp/oom_guard.log
```

查看方式：

```sh
su -c 'tail -f /data/local/tmp/oom_guard.log'
```

注意事項
--------
- Android 會隨程序狀態改寫 oom_score_adj，本模組因此採用持續重套策略
- 這不會把一般 App 變成 system_server 那種真正系統常駐程序
- 部分 OEM 的省電/後台策略仍可能干擾，建議關閉目標 App 的電池最佳化
