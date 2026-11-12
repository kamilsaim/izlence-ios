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

## Son durum: GitHub ücretsiz kotası doldu

- Son uygulama kodu commit'i: `43e470b7844a22de82003ddd8240053aef3c3096`.
- Son istatistik uyarlaması (tam izlenen diziler, sezon ortalaması, yönetmen/dönem/puan dağılımı) için test eklendi; bu son commit'in testleri henüz çalışamadı.
- GitHub Actions çalışması **43181446982**, testflight=true girdisiyle başlatıldı; hesap kotası nedeniyle **hiçbir iş adımı başlamadan** engellendi. TestFlight işi atlandı. Bu sonuç kod/derleme hatası değildir.
- GitHub API ile doğrulama: hesap Free; Kasım 2026 gizli depo hesaplama kullanımı **12,00 USD**, ek ücret **0,00 USD**. Free aylık hesaplama hakkı 12 USD. macOS 184,645161 dakika ve gizli depolarda Linux 92 dakika kullanılmış. Herkese açık depoların ücretsiz kullanımı bu toplama dahil edilmedi.
- Hesabın bütçe/ödeme ayarı değiştirilmedi. Kullanıcı engelin kalktığını bildirdikten sonra `gh run rerun 43181446982 --failed -R kamilsaim/izlence-ios` ile aynı sürüm ve aynı kaynak üzerinden devam edilebilir. İş akışı, başarılı testlerden sonra imzalı IPA'yı TestFlight'a yükler. Tekrar başlamadan Apple'da yeni bir build oluşmadığı ve kaynak SHA kontrol edilmelidir.
- Ekran görüntüleri kontrol edildi; görselin doğal genişliğinden kaynaklanan hero taşması düzeltildi. Son sürüm ekran görüntüleri teslim edilecek.
- App Store Connect kaydı kullanıcı tarafından açıldı ve API ile doğrulandı: **6833832918**, SKU `izlence-ios`, bundle `com.kamilsaim.izlence`.
- iOS Keychain/dosya saklamasını açıklayan gizlilik metni Firebase önizlemesinde doğrulandı ve canlıya taşındı: https://izlence.web.app/gizlilik.html . app.js, sw.js, index.html ve version.json dosyalarının mevcut canlı sürümle aynı olduğu doğrulandı.
- Türkçe TestFlight açıklaması/geri bildirim adresi ve **İzlence İç Test** grubu hazırlandı. Derleme yokken testçi erişimi doğrulanamaz; yüklemeden sonra kullanıcının iç test grubuna erişimi kontrol edilecektir.
- Tüm kontrollerden sonra TestFlight yüklemesi ve Apple işleme sonucunun doğrulanması.

**Henüz fiziksel iPhone'da test edildi veya TestFlight'a yüklendi denemez.** Son kodun doğrulaması ve yüklemesi, kota engelinin kalkmasını bekliyor. Kaynak ve ekran görüntüleri teslim klasöründe saklanır. App Store yayını bu çalışmanın kapsamında değildir.

## Kaynaklar

- GitHub ücretsiz kullanım: https://docs.github.com/en/billing/concepts/product-billing/github-actions
- Başarılı test: https://github.com/kamilsaim/izlence-ios/actions/runs/43180868475
- Hesap kotası nedeniyle başlamayan son iş: https://github.com/kamilsaim/izlence-ios/actions/runs/43181446982
