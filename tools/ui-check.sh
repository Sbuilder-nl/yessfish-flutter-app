#!/bin/bash
# UI-waakhond YessFish-app — draait vóór elke release (naast flutter analyze).
# Bewaakt de leesbaarheids-afspraken van 20-08-2026:
#  1. geen verticale lijst met vaste padding ZONDER navigatiebalk-inset
#  2. geen schermbrede onderbalk zonder padding.bottom
#  3. geen AlertDialog zonder scrollable: true
# Melding = release blokkeren en eerst fixen.
cd /opt/yessfish-flutter-app || exit 1
FOUT=0

# 1) lijsten met vaste const-padding zonder inset (horizontale lijsten uitgezonderd)
while IFS= read -r r; do
  file=${r%%:*}; line=$(echo "$r" | cut -d: -f2)
  ctx=$(sed -n "${line},$((line+3))p" "$file")
  echo "$ctx" | grep -q 'Axis.horizontal' && continue
  echo "$ctx" | grep -q 'NeverScrollable' && continue
  echo "$ctx" | grep -q 'padding.bottom' && continue
  echo "❌ lijst zonder navigatiebalk-inset: $r"
  FOUT=1
done < <(grep -rn 'padding: const EdgeInsets' lib/screens lib/widgets 2>/dev/null | grep -v '.bak' | grep -E 'ListView|GridView' | grep -v 'padding.bottom')

# 2) onderbalken op schermbreedte zonder safe-area
if grep -rn 'Positioned(left: 8, right: 8, bottom: [0-9]' lib/screens lib/widgets 2>/dev/null | grep -v '.bak' | grep -v 'padding.bottom'; then
  echo "❌ onderbalk zonder padding.bottom (zie hierboven)"; FOUT=1
fi

# 3) dialogen zonder scrollable (scrollable mag op dezelfde óf de volgende regel staan)
while IFS= read -r r; do
  file=${r%%:*}; line=$(echo "$r" | cut -d: -f2)
  sed -n "${line},$((line+1))p" "$file" | grep -q 'scrollable' && continue
  echo "❌ AlertDialog zonder scrollable: $r"
  FOUT=1
done < <(grep -rn 'AlertDialog(' lib/screens lib/widgets lib/core 2>/dev/null | grep -v '.bak')

[ $FOUT -eq 0 ] && echo "✅ UI-check: alles leesbaar en scrollbaar"
exit $FOUT
