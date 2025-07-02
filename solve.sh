#!/bin/bash

echo "🔧 Starting System Diagnostics Patch..."

# Step 1: Define target path
TARGET_PATH="genrl-swarm/src/genrl_swarm/logging_utils/system_utils.py"

# Step 2: Overwrite with enhanced system utility
cat > "$TARGET_PATH" << 'EOF'
import platform
import subprocess
import sys
import os
from shutil import which
import psutil

DIVIDER = "[---------] SYSTEM INFO [---------]"

def get_system_info():
    lines = ['\n']
    lines.append(DIVIDER)
    lines.append("")

    lines.append("Python Version:")
    lines.append(f"  {sys.version}")

    lines.append("\nPlatform Information:")
    lines.append(f"  System: {platform.system()}")
    lines.append(f"  Release: {platform.release()}")
    lines.append(f"  Version: {platform.version()}")
    lines.append(f"  Machine: {platform.machine()}")
    lines.append(f"  Processor: {platform.processor()}")

    lines.append("\nCPU Information:")
    lines.append(f"  Physical cores: {psutil.cpu_count(logical=False)}")
    lines.append(f"  Total cores: {psutil.cpu_count(logical=True)}")
    cpu_freq = psutil.cpu_freq()
    if cpu_freq:
        lines.append(f"  Max Frequency: {cpu_freq.max:.2f} Mhz")
        lines.append(f"  Current Frequency: {cpu_freq.current:.2f} Mhz")

    lines.append("\nMemory Information:")
    vm = psutil.virtual_memory()
    lines.append(f"  Total: {vm.total / (1024**3):.2f} GB")
    lines.append(f"  Available: {vm.available / (1024**3):.2f} GB")
    lines.append(f"  Used: {vm.used / (1024**3):.2f} GB")

    lines.append("\nDisk Information (>80%):")
    partitions = psutil.disk_partitions()
    for partition in partitions:
        try:
            if not os.path.exists(partition.mountpoint):
                continue
            usage = psutil.disk_usage(partition.mountpoint)
            if usage.used / usage.total > 0.8:
                lines.append(f"  Device: {partition.device}")
                lines.append(f"    Mount point: {partition.mountpoint}")
                lines.append(f"      Total size: {usage.total / (1024**3):.2f} GB")
                lines.append(f"      Used: {usage.used / (1024**3):.2f} GB")
                lines.append(f"      Free: {usage.free / (1024**3):.2f} GB")
        except (PermissionError, FileNotFoundError):
            lines.append(f"      Skipped (Access/File error) -> {partition.mountpoint}")

    lines.append("")

    if which('nvidia-smi'):
        try:
            lines.append("\nNVIDIA GPU Information:")
            output = subprocess.check_output([
                'nvidia-smi',
                '--query-gpu=gpu_name,memory.total,memory.used,memory.free,temperature.gpu,utilization.gpu',
                '--format=csv,noheader,nounits'
            ]).decode()
            for gpu_line in output.strip().split('\n'):
                name, total, used, free, temp, util = gpu_line.split(', ')
                lines.append(f"  GPU: {name}")
                lines.append(f"    Memory Total: {total} MB")
                lines.append(f"    Memory Used: {used} MB")
                lines.append(f"    Memory Free: {free} MB")
                lines.append(f"    Temperature: {temp}°C")
                lines.append(f"    Utilization: {util}%")
        except Exception:
            lines.append("  Error getting NVIDIA GPU information")

    if which('rocm-smi'):
        try:
            lines.append("\nAMD GPU Information:")
            rocm_output = subprocess.check_output([
                'rocm-smi', '--showproductname', '--showmeminfo', '--showtemp'
            ]).decode()
            lines.extend(f"  {line}" for line in rocm_output.strip().split('\n'))
        except Exception:
            lines.append("  Error getting AMD GPU information")

    if platform.system() == 'Darwin' and platform.machine() == 'arm64':
        try:
            lines.append("\nApple Silicon Information:")
            brand = subprocess.check_output([
                'sysctl', '-n', 'machdep.cpu.brand_string'
            ]).decode().strip()
            lines.append(f"  Processor: {brand}")
            try:
                import torch
                if torch.backends.mps.is_available():
                    lines.append("  MPS: Available")
                    lines.append(f"  MPS Device: {torch.device('mps')}")
                else:
                    lines.append("  MPS: Not available")
            except ImportError:
                lines.append("  PyTorch not installed, cannot check MPS availability")
        except Exception:
            lines.append("  Error getting Apple Silicon information")

    lines.append("")
    lines.append(DIVIDER)
    return "\n".join(lines)
EOF

echo "✅ system_utils.py replaced with enhanced version."

# Step 3: Patch the Timeout Bug
DAEMON_PATH=~/rl-swarm/.venv/lib/python3.12/site-packages/hivemind/p2p/p2p_daemon.py

if [ -f "$DAEMON_PATH" ]; then
    sed -i 's/startup_timeout: float = *15/startup_timeout: float = 120/' "$DAEMON_PATH"
    echo "🧼 Timeout bug fixed in p2p_daemon.py"
else
    echo "⚠️ Timeout patch skipped — file not found: $DAEMON_PATH"
fi

echo "🎉 All tasks completed successfully!"
