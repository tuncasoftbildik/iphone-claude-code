# Claude Code ile iPhone kontrolü (kablosuz)

Claude Code'un iPhone'unu kullanmasını sağlayan kısa kurulum rehberi. Ekranı görüyor, dokunuyor, kaydırıyor, yazı yazıyor.

Sırrı **WebDriverAgent (WDA)**: Apple'ın XCTest altyapısı üzerine kurulu açık kaynak bir araç. Telefona küçük bir test uygulaması olarak yükleniyor ve `8100` portundan HTTP ile komut alıyor. Claude Code da bu komutları çağırıyor.

```
Mac (Claude Code)  ──HTTP / Wi-Fi──▶  iPhone (WebDriverAgent :8100)
```

## Gerekenler

- Mac + Xcode
- Apple geliştirici hesabı (ücretsiz hesapla da imzalanır, ama imza 7 günde bir yenilenmeli)
- iPhone'da **Geliştirici Modu** açık: *Ayarlar → Gizlilik ve Güvenlik → Geliştirici Modu*
- iPhone ve Mac aynı Wi-Fi ağında (ya da kablo)

## 1. WebDriverAgent'ı indir

```bash
git clone https://github.com/appium/WebDriverAgent.git
cd WebDriverAgent
```

## 2. İmzala ve derle

Telefonun kimliğini (UDID) bul:

```bash
xcrun devicectl list devices
```

Derle (`TAKIM_ID` = Apple geliştirici takım kimliğin, `com.senin.WebDriverAgentRunner` = sana özel bir bundle id):

```bash
xcodebuild build-for-testing \
  -project WebDriverAgent.xcodeproj \
  -scheme WebDriverAgentRunner \
  -destination "id=<UDID>" \
  -derivedDataPath ./derleme \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM=<TAKIM_ID> \
  PRODUCT_BUNDLE_IDENTIFIER=com.senin.WebDriverAgentRunner
```

> İmza hatası alırsan projeyi Xcode'da aç, `WebDriverAgentRunner` hedefinde *Signing & Capabilities* bölümünden takımını seç ve bundle id'yi değiştir.

## 3. Telefonda başlat

```bash
xcodebuild test-without-building \
  -xctestrun ./derleme/Build/Products/*.xctestrun \
  -destination "id=<UDID>"
```

İlk seferde telefonda geliştiriciye güvenmen gerekebilir: *Ayarlar → Genel → VPN ve Cihaz Yönetimi*.

Komut açık kaldığı sürece WDA çalışır. Çıktıda telefonun adresi görünür (`ServerURLHere->http://192.168.x.x:8100<-`). Kontrol et:

```bash
curl http://<iphone-ip>:8100/status
```

> Kabloyla kullanmak istersen: `brew install libimobiledevice` → `iproxy 8100 8100` → adres `http://localhost:8100`.

## 4. Yardımcı betik

Bu depodaki [`wda.sh`](wda.sh) en sık kullanılan komutları sarmalıyor:

```bash
export WDA_URL=http://<iphone-ip>:8100

./wda.sh shot ekran.png          # ekran görüntüsü
./wda.sh tap 200 400             # (x, y) noktasına dokun
./wda.sh swipe 220 780 220 230   # aşağıdan yukarı kaydır
./wda.sh type "Merhaba dünya"    # odaktaki alana yaz (Türkçe karakterler sorunsuz)
./wda.sh home                    # ana ekran
./wda.sh source                  # ekrandaki öğeler (JSON, konumlarıyla)
```

Koordinatlar **point** cinsinden, piksel değil. Örneğin iPhone Pro Max için ekran 440×956 point. Ekran görüntüsündeki pikseli ekran ölçeğine (3x) bölerek point'e çevirirsin.

## 5. Claude Code'a öğret

Projendeki `CLAUDE.md` dosyasına şunu ekle:

```markdown
## iPhone kontrolü
iPhone'a WebDriverAgent ile erişebilirsin: `WDA_URL=http://<iphone-ip>:8100 ./wda.sh ...`
- Her adımdan önce `shot` ile ekran görüntüsü al ve bak; körlemesine dokunma.
- Koordinatlar point cinsinden (ekran 440×956).
- Gönderi paylaşma, mesaj gönderme ve satın alma gibi geri alınamaz adımlardan önce bana sor.
```

Sonra Claude Code'a düz Türkçe ile ne istediğini söyle: *"X'i aç, bildirimlerimi oku ve özetle."*

## Dikkat edilecekler

- **Aynı sayfa içindeki işler çok güvenilir; sayfalar arası sürükleme şaşabiliyor.** Ana ekranda bir uygulamayı başka sayfaya taşırken kenar beklemesi bazen bir sayfa eksik çeviriyor. Her adımda ekran görüntüsü al.
- **Face ID ve şifre ekranları sende kalır.** WDA bunları geçemez, geçmemeli de.
- **Hız:** Her adım yaklaşık 1 saniye. Uzun otomasyonları izle, gerekirse durdur.
- Mac uyursa ya da `xcodebuild` kapanırsa WDA da durur; 3. adımı tekrar çalıştır.

## Neler yapılabilir

- Kendi uygulamanı gerçek cihazda uçtan uca test etmek
- App Store için gerçek cihazdan ekran görüntüsü serisi almak
- Ana ekranı ve klasörleri düzenlemek
- Bildirimleri ve akışı okuyup özetlemek

---

Hazırlayan: [@tuncabildik](https://x.com/tuncabildik) · Lisans: MIT
