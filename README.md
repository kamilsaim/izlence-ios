# İzlence · Yerel iOS

SwiftUI, iOS 17 ve üzeri. Android sürümündeki koyu petrol/kehribar tasarım ve aynı logo kullanılır. Sistem TabView'i iOS 26 ve üzerinde Liquid Glass görünümünü sağlar. WebView ve üçüncü taraf Swift paketi yoktur.

## Çalıştırma

Mac'te Xcode ve XcodeGen ile:

```sh
brew install xcodegen
xcodegen generate
open Izlence.xcodeproj
```

GitHub → Actions → **iOS test ve TestFlight** elle çalıştırılır. Önce birim testleri ve iPhone simülatörü arayüz testleri koşar. `testflight=true` seçilmişse yalnız başarılı testlerden sonra imzalı IPA yüklenir. App Store inceleme/yayın gönderimi yapılmaz.

## Özellikler

- Ana Sayfa: çevrimdışı paketli afişler, öne çıkanlar, listelerin sayıları, takip edilen diziler.
- Keşfet: trendler, yapım/kişi/IMDb/yıl/seri/anahtar kelime araması, tür filtresi ve sayfalama; klasik kişisel öneriler; kendi Google anahtarınla, açık veri aktarım onayıyla Gemini önerileri. Modeller API'den listelenir; otomatik seçim başarısız modellerde diğerlerini dener. Sonuçlar TMDB'de başlık/yıl/tür ile doğrulanır. Kendi TMDB anahtarın isteğe bağlıdır; yoksa Android/web ile aynı ortak bağlantı kullanılır.
- Arşivim: tür, arama ve sıralama. Yapım ayrıntılarında izledim/izleyeceğim/favori, puan, not, dizi ilerlemesi, yayın platformları, benzerler, fragman, IMDb ve sahne görselleri.
- Listeler: izlenecekler, izlenenler, favoriler, dizi takibi ve arşivden seri taraması.
- Profil: iki kişisel API anahtarı, model/dil/ülke/platform tercihleri, istatistikler, JSON yedek/geri yükleme, IMDb CSV aktarımı, arşiv ve anahtar silme.

## Veriler ve güvenlik

Arşiv Application Support içinde atomik dosya yazımı ve iOS dosya korumasıyla saklanır. Arşiv ve kurtarma kopyaları otomatik yedekten hariçtir. API anahtarları `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` ile Keychain'de saklanır. Kaynakta veya GitHub'da kullanıcı API anahtarı yoktur. Google isteğine kişisel yapım notları eklenmez. HTTP hata metinleri ham URL/anahtar/yanıt gövdesi içermez; yönlendirmeler engellenir, yanıt boyutu sınırlanır.

Android/web JSON yedekleri puan, not, tarih, listeler ve bölüm ilerlemesiyle içe aktarılır. Aynı sayısal film ve dizi kimliği ayrı tutulur. Bozuk yedek, geçersiz kimlik ve yinelenen yapım reddedilir. İçe aktarım öncesi mevcut dosya kurtarma kopyası olarak korunur. Birleştirme mevcut kayıtları değiştirmez; değiştirme seçeneği bütün arşivi aktarır. JSON yedeklerinde API anahtarı yoktur. iOS ile Android arasında otomatik senkronizasyon yoktur.

IMDb CSV aktarımı tüm eşleştirmeler bitince tek seferde yazılır. İptal veya ağ hatasında kısmi arşiv yazılmaz. Mevcut notlar korunur. Kotalı yanıtlarda sınırlı yeniden deneme yapılır.

## Apple / GitHub yapılandırması

Bundle ID: `com.kamilsaim.izlence`. Takım: `NBTXFU47EV`. İlk iOS sürümü: `1.0.0`. GitHub deposu kullanıcının onayıyla herkese açıktır: https://github.com/kamilsaim/izlence-ios . Standart macOS GitHub Actions derleyicileri kullanılır.

Actions secrets: `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8_BASE64`, `DIST_CERT_P12_BASE64`, `DIST_CERT_PASSWORD`. Sertifika veya özel anahtar dosyaları depoya alınmaz. Ortak mevcut dağıtım sertifikası kullanılır; yeni sertifika üretilmez. TestFlight için Apple web ekranındaki uygulama kaydının ayrıca mevcut olması gerekir.

Test raporları ve ekran görüntüleri Actions artifact'ında saklanır. Ücretli gerçek Gemini istekleri CI testlerine eklenmez. Gerçek API anahtarı/kotası ve fiziksel cihaz davranışı iPhone testinde doğrulanmalıdır.
