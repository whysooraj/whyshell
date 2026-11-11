#!/bin/bash
# Reads notification counts from window titles using hyprctl
# Output format: appId|count per line
# Apps like Discord put "(1)" or "[2]" in their window title

hyprctl clients -j 2>/dev/null | python3 -c "
import sys, json, re

try:
    clients = json.load(sys.stdin)
except Exception:
    sys.exit(0)

IGNORE_NUMBERS = {2024, 2025, 2026, 2027, 2028, 1920, 1080}

for c in clients:
    title = c.get('title', '')
    class_name = c.get('class', '')
    if not title or not class_name:
        continue
    
    # Strictly require parentheses or square brackets around notification counts.
    # Bare numbers in titles (e.g. issue #583, line 583, ports, dates) are NOT badges.
    # Priority 1: Leading count: '(1) Discord', '[2] Slack', '(99+) WhatsApp'
    m = re.search(r'^\s*[\(\[]\s*(\d+)\+?\s*[\)\]]', title)
    if not m:
        # Priority 2: Bracketed count anywhere: 'Discord (1)', 'Inbox - Mail [3]'
        m = re.search(r'[\(\[]\s*(\d+)\+?\s*[\)\]]', title)
    
    count = 0
    if m:
        try:
            val = int(m.group(1))
            if val > 0 and val not in IGNORE_NUMBERS and val < 10000:
                count = val
        except ValueError:
            count = 0
    
    if count > 0:
        print(f'{class_name}|{count}')
" 2>/dev/null
