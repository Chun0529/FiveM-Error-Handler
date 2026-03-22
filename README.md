https://fivem-docs-aptx7otz.manus.space/?code=5bXLR3jbBwgWzncyG4WR4p

這是一個專為 FiveM 伺服器設計的自動錯誤偵測與修復插件。它能夠即時監控伺服器與客戶端的各類錯誤，並提供一個美觀的 NUI 控制面板供管理員查看與操作。此外，它還具備自動重啟崩潰資源、清除問題實體以及 Discord Webhook 推播等強大功能。

🌟 核心功能

•
全面錯誤監控：捕捉 Lua 執行錯誤、資源崩潰、資料庫連線錯誤（oxmysql）、網路同步異常等。

•
自動修復機制：

•
自動偵測並重啟意外停止的資源（可設定最大重啟次數與冷卻時間）。

•
自動清除導致同步錯誤的無效實體（車輛、NPC、物件）。



•
NUI 控制面板：提供美觀的 HTML/CSS/JS 介面，包含儀表板統計、錯誤日誌過濾、資源狀態監控與手動操作功能。

•
Discord Webhook 整合：將中高嚴重程度的錯誤即時推播至 Discord 頻道，支援自訂顏色與機器人資訊。

•
多框架支援：自動偵測並相容於 ESX、QBCore、QBX Core，或使用獨立的 ACE Permissions 進行權限管理。



📥 安裝說明

1.
將 fivem-error-handler 資料夾放入伺服器的 resources 目錄中。

2.
在 server.cfg 中加入以下設定：
# 確保 oxmysql 在此插件之前啟動 (若有使用)
ensure oxmysql

# 啟動錯誤監控插件
ensure fivem-error-handler

# 設定 ACE 權限 (若使用獨立模式)
add_ace group.admin errorhandler.admin allow
add_ace group.admin command.errorpanel allow

1.開啟 shared/config.lua，根據您的需求進行設定（特別是 Discord Webhook URL）。

2.重啟伺服器或在控制台輸入 refresh 後 start fivem-error-handler。

🎮 使用方式

•
開啟面板：在遊戲中輸入指令 /<指令名稱>（預設為 /errorpanel），或按下快捷鍵 F8。

•
關閉面板：在面板開啟狀態下按下 ESC 鍵，或點擊側邊欄的「關閉面板」按鈕。

•
手動操作：在「自動修復」頁籤中，您可以手動觸發實體清除、測試 Webhook，或強制重啟特定資源。

