## Son güncelleme — öneriler ve arayüz (build 61)

12 Kasım 2026: TestFlight 1.0.0 (61), VALID / IN_BETA_TESTING olarak doğrulandı. 12 birim/entegrasyon + 4 arayüz testi geçti. İzlenen/gizlenen öneriler elenir; ana sayfa kategori kısayolları ve arşiv ikonları tamamlandı. App Store Connect: Türkçe bilgiler + altı iPhone / bir iPad ekran görüntüsü taslakta; App Review gönderilmedi. Ayrıntılar IOS-ONERI-VE-ARAYUZ-DUZELTMELERI.md dosyasında.

Önceki build 42 kaydı aşağıda tarihçe olarak korunur.

# İzlence iOS — test ve TestFlight sonucu

12 Kasım 2026.

**1.0.0 (42)**, App Store Connect **6833832918** kaydına yüklendi. Apple işleme durumu **VALID**. Derleme **İzlence İç Test** grubuna bağlandı ve kullanıcının kendi testçi üyeliği doğrulandı. Fiziksel iPhone testi kullanıcı tarafından yapılacak; App Store incelemesine/yayınına gönderilmedi.

## Kaynak ve dağıtım

- Bundle ID: `com.kamilsaim.izlence`; takım: `NBTXFU47EV`.
- Depo kullanıcı onayıyla herkese açıldı: https://github.com/kamilsaim/izlence-ios
- Yüklenen uygulama kodu: `43e470b7844a22de82003ddd8240053aef3c3096`. Sonraki belge güncellemeleri uygulama kodunu değiştirmez.
- GitHub Actions: https://github.com/kamilsaim/izlence-ios/actions/runs/43181446982 (ikinci deneme).
- Önceki gizli depo kota engeli, depoyu herkese açarak aşıldı. Hesabın ödeme veya harcama ayarları değiştirilmedi.
- Açmadan önce 86 Git geçmişi blob'u, yerel Apple özel anahtar/sertifika/parola değerleri ve anahtar kalıplarıyla tarandı; eşleşme bulunmadı. İmzalama dosyaları GitHub Secrets üzerinden kullanılır; kaynakta yer almaz.

## Doğrulananlar

**11 birim/entegrasyon + 2 arayüz testi geçti; 0 hata.** Xcode 26.6, iOS 26.5, iPhone 17 Pro Max simülatörü kullanıldı.

- Android/web JSON yedeğinde aynı sayısal film/dizi kimliğinin ayrı tutulması; puan, tarih, listeler, bölüm ve uzun Unicode notların korunması.
- Bozuk/yinelenen/geçersiz yedeğin reddedilmesi; mevcut arşivin korunması, diske tekrar açılışta kayıtların gelmesi ve kurtarma kopyası.
- IMDb CSV içinde Windows CRLF satır sonu, virgül, tırnak, çok satırlı alanlar, yinelenen IMDb kimliği ve tarih/puan ayrıştırması.
- Ayrı test alanında Keychain okuma, yazma ve güncelleme.
- Gerçek ortak TMDB bağlantısıyla IMDb bulma, ayrıntı, Tom Hardy filmografisi, Dune serisi ve farklı trend sayfaları.
- Tam izlenen dizi ve kısmi bölüm ilerlemesinden süre hesaplama; sezon sayısı ortalaması ve bilinmeyen bölüm süresi varsayımı.
- Beş sekme, çevrimdışı katalog araması, izledim/favori, not kaydetme, arşiv ve API ekranı; büyük yazı ve yatay ekran görüntüleri.

Son test kaydı `basarili-test-kaydi.log`; sekiz ekran görüntüsü bu teslim klasöründedir. İlk bulunan CSV ve hero görsel taşma sorunları düzeltildi.

## Uygulanan özellikler

SwiftUI ile beş ekran, Android'deki logo/renkler, iOS sisteminin cam alt menüsü, çevrimdışı görseller, canlı arama/tür/yıl/kişi/IMDb/seri/anahtar kelime araması ve sayfalama; izledim/izleyeceğim/favori; puan/not; dizi takibi; seri taraması; platform/benzer/fragman/IMDb bağlantıları; Gemini ve klasik kişisel öneriler; model/dil/ülke/platform seçimi; JSON yedek aktarımı; IMDb CSV ve istatistikler.

TMDB anahtarı isteğe bağlıdır; boşken Android/web ile aynı ortak bağlantı kullanılır. Kendi Google AI anahtarı Profil'den girilir; anahtarlar Keychain'de saklanır ve JSON yedeğine eklenmez. AI isteği öncesinde veri gönderimi açıklanır; kişisel film notları gönderilmez. Güncel gizlilik metni: https://izlence.web.app/gizlilik.html

## iPhone'da kullanıcı testi

`IPHONE-TEST-NOTLARI.md` dosyasındaki adımlarla test edilebilir. Gerçek kişisel Gemini anahtarı CI'ya kopyalanmadı ve ücretli Gemini üretim testi iOS'ta yapılmadı. Bu ve fiziksel cihaz davranışları kullanıcı testinde doğrulanacak. Cihazlar arasında otomatik eşitleme yoktur; arşiv JSON yedeğiyle taşınır.
