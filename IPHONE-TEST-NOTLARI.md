# İzlence iPhone testi

1. TestFlight'ta İzlence'yi yükle. İlk iOS sürümü `1.0.0` olarak görünür. Uygulama hesabı veya giriş gerekmez.
2. Ana sayfada Filmler, Diziler, Belgeseller ve Araştır ikonlarına bas; ilgili arama filtresi açılmalı. Arşivim’de ikonlu tür sayaçlarını, görünüm düğmesini ve + işaretini dene. Ana Sayfa, Keşfet, Arşivim, Listeler ve Profil sekmelerini dene. Alt menü iOS 26 ve üstünde sistemin cam görünümünü kullanır.
3. Keşfet'te yapım adı, `Interstellar 2014`, `Tom Hardy` veya `tt0816692` ara. Film/dizi/belgesel filtrelerini ve daha fazla sonuç düğmesini dene.
4. Bir yapımı İzledim, İzleyeceğim veya Favori listesine ekle; puan ve not kaydet. Uygulamayı kapatıp yeniden açınca kayıtların korunmalı.
5. Ana sayfadaki öneriden İzledim seç; yapım önerilerden kalkıp arşivde kalmalı. Üç nokta → Bunu bir daha önerme ile başka bir yapımı gizle; kapatıp açınca geri gelmemeli. Profil’de gizlediğin önerileri sıfırlayabilirsin. Bir dizide takibi başlat, sezon/bölüm ayarla ve “Bir bölüm izledim” düğmesini dene.
6. Profil → API ayarlarım bölümüne kendi Google AI anahtarını gir. TMDB anahtarı isteğe bağlıdır; boşken ortak bağlantı kullanılır. Arşivine en az üç yapım ekledikten sonra Keşfet → AI Önerileri'ni dene. Gönderim açıklaması onayından sonra Google AI kotan kullanılır. Anahtarını sohbet veya hata raporuna yazma.
7. Android/web arşivini taşımak için oradan JSON yedeği al; iPhone'da Profil → Android / Web / iOS yedeği aktar yolunu kullan. “Birleştir” mevcut kayıtları korur, “Değiştir” yedekteki arşivi kullanır. Cihazlar arasında otomatik eşitleme yoktur.
8. JSON yedeği dışa aktar ve dosyayı yeniden içe al. Puan, not, favori ve bölüm ilerlemesini karşılaştır. API anahtarları yedekte bulunmaz.
9. Profil'deki istatistikleri ve Listeler → Seriler taramasını kontrol et. IMDb'den indirdiğin CSV dosyasını Profil'den aktarabilirsin.

Bir sorun görürsen hangi ekranda ve hangi adımlardan sonra olduğunu, iPhone modelini ve iOS sürümünü belirt. Ekran görüntüsü veya kısa ekran kaydı ekleyebilirsin. Anahtarların veya kişisel notların göründüğü kısımları paylaşma.

Fiziksel iPhone ve kişisel Gemini anahtarıyla son test kullanıcı tarafından yapılır. Otomatik testlerde kişisel Google anahtarı kullanılmaz.
