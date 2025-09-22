signal_read.sh - Telemetry Visibility Tool

Overview
signal_read.sh is a lightweight Bash script that inspects Ubuntu and Arch Linux
systems for telemetry-related services, packages, and configuration settings.
It highlights whether telemetry components are installed, enabled, or active,
and presents the results in a color-coded, human-readable format.

The purpose of this tool is to help system administrators, security enthusiasts,
and privacy-conscious users quickly identify background processes and services
that may be collecting or transmitting usage data.

Features
- Detects known telemetry components on Ubuntu (ubuntu-report, popularity-contest,
  apport, whoopsie, motd-news, livepatch tooling).
- Detects known telemetry components on Arch Linux (pkgstats and timer).
- Scans systemd unit files for telemetry/metrics/report-related services and timers.
- Displays results in clear, color-coded sections with headers.
- Works in read-only mode — no services are enabled, disabled, or modified.

Usage
1. Make the script executable: chmod +x signal_read.sh
2. Run the script: ./signal_read.sh
3. Review the results to see which telemetry-related components are present
   and their current states.

Legend
- RED    : Installed and active/opted-in
- YELLOW : Installed but inactive/unknown
- GREEN  : Not installed or disabled

Requirements
- Bash shell (>= 4)
- systemctl (systemd-based systems).
- dpkg (Ubuntu/Debian systems) or pacman (Arch-based systems).

Legal Disclaimer
This software is provided "as is" without any warranties, express or implied,
including but not limited to implied warranties of merchantability or fitness
for a particular purpose. The authors and contributors of signal_read.sh
assume no responsibility for errors or omissions, nor for damages resulting
from the use of this script.

Use of this tool is at your own risk. It is intended solely for informational
and educational purposes. By running this script, you agree that you are
responsible for ensuring that its use complies with all applicable laws,
regulations, and organizational policies.
