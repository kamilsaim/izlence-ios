# İzlence iOS — doğrulama ve yayın durumu

Tarih: 12 Kasım 2026.

SwiftUI uygulaması `C:\mac\izlence` klasöründe hazırlanmıştır. Android/web kaynakları ve yayımlanan Android AAB değiştirilmemiştir.

## Uygulananlar

Beş ana ekran, Android ile aynı logo ve afişler, native cam alt menü, çevrimdışı örnek katalog, TMDB arama/ayrıntı/platform/seri bağlantıları, puan/not/listeler, dizi ilerlemesi, klasik ve Gemini önerileri, iki API anahtarı ve model seçimi, JSON yedek aktarımı, IMDb CSV ve istatistikler uygulanmıştır. Özellikler için README'ye bakınız.

## Doğrulama

- İlk macOS/Xcode derlemesi: GitHub Actions çalışması 43179339951; sonuç bekleniyor.
- Birim testleri: Android/web yedek uyumu; film/dizi kimliği çakışması; uzun Unicode notlar; puan, tarih, bölüm koruması; bozuk/yinelenen yedek; BOM; CSV tırnak/virgül/satır sonu; disk bozulması ve kurtarma.
- iPhone simülatörü testleri: çevrimdışı gezinme, arama, izledim/favori, not düzenleme, arşiv ve API ekranı; büyük yazı ve yatay ekran görüntüleri.
- Gerçek iPhone testi kullanıcı tarafından yapılacaktır. Bu bilgisayarda USB üzerinden iPhone ekranını kontrol eden bir araç yoktur.

## TestFlight öncesi açık adımlar

- GitHub/Xcode derleme ve otomatik test sonuçlarının alınması, varsa hataların düzeltilmesi.
- Ekran görüntülerinin görsel kontrolü.
- App Store Connect'te yeni iOS uygulama kaydı. Bundle ID Apple API ile kaydedildi: `com.kamilsaim.izlence`; henüz uygulama kaydı yok.
- iOS Keychain/dosya saklamasını açıklayan gizlilik metninin güncellenmesi.
- Tüm kontrollerden sonra TestFlight yüklemesi ve Apple işleme sonucunun doğrulanması.

**Henüz iPhone'da test edildi veya TestFlight'a yüklendi denemez.** Nihai sonuçlar bu dosyada güncellenecektir. App Store yayını bu çalışmanın kapsamında değildir.
