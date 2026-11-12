# İzlence iOS — doğrulama ve yayın durumu

Tarih: 12 Kasım 2026.

SwiftUI uygulaması `C:\mac\izlence` klasöründe hazırlanmıştır. Android/web kaynakları ve yayımlanan Android AAB değiştirilmemiştir.

## Uygulananlar

Beş ana ekran, Android ile aynı logo ve afişler, native cam alt menü, çevrimdışı örnek katalog, TMDB arama/ayrıntı/platform/seri bağlantıları, puan/not/listeler, dizi ilerlemesi, klasik ve Gemini önerileri, iki API anahtarı ve model seçimi, JSON yedek aktarımı, IMDb CSV ve istatistikler uygulanmıştır. Özellikler için README'ye bakınız.

## Doğrulama

- İlk derleme başarılıydı; CSV CRLF ayrıştırma ve test ortamı hataları otomatik testlerle bulundu ve düzeltildi.
- GitHub Actions 43180868475: **10 birim/entegrasyon + 2 iPhone arayüz testi başarılı**, 0 hata. Xcode 26.6, iOS 26.5 iPhone 17 Pro Max simülatörü.
- Gerçek ortak TMDB bağlantısında IMDb kimliği, ayrıntılar, Tom Hardy filmografisi, Dune serisi ve trend sayfalama doğrulandı. İzole test anahtarlarıyla Keychain okuma/yazma/güncelleme geçti. Gerçek kişisel Google AI anahtarı CI'ya taşınmadı; ücretli Gemini üretimini fiziksel iPhone'da kullanıcı test edecek.
- Birim testleri: Android/web yedek uyumu; film/dizi kimliği çakışması; uzun Unicode notlar; puan, tarih, bölüm koruması; bozuk/yinelenen yedek; BOM; CSV tırnak/virgül/satır sonu; disk bozulması ve kurtarma.
- iPhone simülatörü testleri: çevrimdışı gezinme, arama, izledim/favori, not düzenleme, arşiv ve API ekranı; büyük yazı ve yatay ekran görüntüleri.
- Gerçek iPhone testi kullanıcı tarafından yapılacaktır. Bu bilgisayarda USB üzerinden iPhone ekranını kontrol eden bir araç yoktur.

## TestFlight öncesi açık adımlar

- Son istatistik uyarlaması (tam izlenen diziler, sezon ortalaması, yönetmen/dönem/puan dağılımı) için testlerin geçmesi.
- Ekran görüntüleri kontrol edildi; görselin doğal genişliğinden kaynaklanan hero taşması düzeltildi. Son sürüm ekran görüntüleri teslim edilecek.
- App Store Connect kaydı kullanıcı tarafından açıldı ve API ile doğrulandı: **6833832918**, SKU `izlence-ios`, bundle `com.kamilsaim.izlence`.
- iOS Keychain/dosya saklamasını açıklayan gizlilik metni hazırlandı; Firebase önizlemesi doğrulandıktan sonra canlıya taşınacak.
- Tüm kontrollerden sonra TestFlight yüklemesi ve Apple işleme sonucunun doğrulanması.

**Henüz iPhone'da test edildi veya TestFlight'a yüklendi denemez.** Nihai sonuçlar bu dosyada güncellenecektir. App Store yayını bu çalışmanın kapsamında değildir.
