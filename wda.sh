#!/bin/zsh
# iPhone'u WebDriverAgent (WDA) üzerinden kontrol eden küçük yardımcı.
# Kullanım:
#   export WDA_URL=http://<iphone-ip>:8100     (kabloyla: iproxy 8100 8100 → http://localhost:8100)
#   ./wda.sh shot ekran.png        ekran görüntüsü
#   ./wda.sh tap 200 400           (x, y) noktasına dokun (birim: point)
#   ./wda.sh swipe 220 780 220 230 kaydır (başlangıç → bitiş)
#   ./wda.sh type "Merhaba dünya"  odaktaki alana yaz
#   ./wda.sh home                  ana ekrana dön
#   ./wda.sh source                ekrandaki öğeleri JSON olarak al
set -e
W=${WDA_URL:-http://localhost:8100}

sid() {
  local s=$(curl -s -m 5 $W/status | python3 -c "import sys,json;print(json.load(sys.stdin).get('sessionId') or '')")
  [[ -z $s ]] && s=$(curl -s -m 15 -X POST $W/session -d '{"capabilities":{}}' | python3 -c "import sys,json;print(json.load(sys.stdin)['sessionId'])")
  echo $s
}

case $1 in
  shot)
    curl -s -m 15 $W/screenshot | python3 -c "import sys,json,base64;open(sys.argv[1],'wb').write(base64.b64decode(json.load(sys.stdin)['value']))" "${2:-ekran.png}"
    echo "${2:-ekran.png}" ;;
  tap)
    curl -s -m 10 -X POST $W/session/$(sid)/wda/tap -d "{\"x\":$2,\"y\":$3}" >/dev/null ;;
  swipe)
    curl -s -m 10 -X POST $W/session/$(sid)/wda/dragfromtoforduration \
      -d "{\"fromX\":$2,\"fromY\":$3,\"toX\":$4,\"toY\":$5,\"duration\":0.2}" >/dev/null ;;
  type)
    python3 -c "import json,sys;print(json.dumps({'value':list(sys.argv[1]),'frequency':30}))" "$2" \
      | curl -s -m 120 -X POST $W/session/$(sid)/wda/keys -d @- >/dev/null ;;
  home)
    curl -s -m 10 -X POST $W/wda/homescreen >/dev/null ;;
  source)
    curl -s -m 30 "$W/source?format=json" ;;
  *)
    sed -n 2,11p $0 ;;
esac
