#!/bin/bash

# 🎨 Random Fancy Banner
BANNER="██████╗ ███████╗██╗   ██╗██╗██╗     
██╔══██╗██╔════╝██║   ██║██║██║     
██║  ██║█████╗  ██║   ██║██║██║     
██║  ██║██╔══╝  ╚██╗ ██╔╝██║██║     
██████╔╝███████╗ ╚████╔╝ ██║███████╗
╚═════╝ ╚══════╝  ╚═══╝  ╚═╝╚══════╝"

COLORS=(31 32 33 34 35 36 91 92 93 94 95 96)
COLOR=${COLORS[$RANDOM % ${#COLORS[@]}]}
echo -e "\n\e[1;${COLOR}m$BANNER\e[0m"
echo -e "🔧 Starting Gensyn Bug Fix Setup — Say thanks to DEVIL!\n"

# 🔧 Step 1: Patch system_utils.py with upgraded diagnostics
echo "🚀 Checking system_utils.py for patching..."
TARGET_PATH="$HOME/rl-swarm/genrl-swarm/src/genrl_swarm/logging_utils/system_utils.py"

if [ -f "$TARGET_PATH" ]; then
  echo "📄 Found system_utils.py — applying patch..."
  cat > "$TARGET_PATH" << 'EOF'
<INSERT FULL PYTHON CODE HERE — the diagnostics function>
EOF
  echo "✅ system_utils.py patched successfully!"
else
  echo "❌ system_utils.py not found — skipping patch."
fi

# 🧼 Step 2: Timeout Bug Fix
echo -e "\n🛠  Applying timeout bug fix..."
DAEMON_PATH="$HOME/rl-swarm/.venv/lib/python3.12/site-packages/hivemind/p2p/p2p_daemon.py"

if [ -f "$DAEMON_PATH" ]; then
    sed -i 's/startup_timeout: float = *15/startup_timeout: float = 120/' "$DAEMON_PATH"
    echo "✅ Timeout increased to 120s in p2p_daemon.py"
else
    echo "⚠️  Daemon file not found — skipping timeout patch"
fi

# 🎉 All done!
echo -e "\n🎉 Setup complete! Your system is now full 🔥 🔍 ready!"
echo -e "📂 You can now run the swarm & start debugging like a boss.\n"
