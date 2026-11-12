# App Store Connect son mağaza hazırlığı — 12 Kasım 2026

İzlence / Apple ID 6833832918 / mağaza sürümü 1.0.0 / bağlı build 61.

## Tamamlanan ve tekrar okunarak doğrulanan alanlar
- Header: creative-assets/header-3840x1646.png. Search: creative-assets/search-3840x2560.png. Her ikisi Apple tarafından işlendi ve Türkçe mağaza sürümünde doğru alana bağlandı. Mevcut logo ve gerçek build 61 arşiv ekranı kullanıldı.
- Altı iPhone ve bir iPad ekran görüntüsü, sıralarıyla birlikte korunuyor. Toplam dokuz görsel yerleşimi doğrulandı.
- Türkçe ad, alt başlık, açıklama, anahtar kelimeler, tanıtım metni; pazarlama/destek/gizlilik bağlantıları; Eğlence kategorisi ve telif metni hazır.
- İnceleme iletişimine kullanıcının verdiği telefon/e-posta girildi. Giriş hesabı gerekmediği belirtildi; İngilizce inceleme ve test adımları eklendi.
- Yaş anketi dolduruldu: film özetleri/afişlerinde karşılaşılabilecek temalar hafif/seyrek; reklam, sohbet/sosyal ağ, kumar ve herkese açık kullanıcı içeriği yok. Apple genel yaş derecesini 12+ hesapladı; bölgesel dereceler değişebilir. Yaş yükseltme seçeneği uygulanmadı.
- İçerik hakları alanında TMDB'den üçüncü taraf içerik kullanıldığı belirtildi.
- Kullanıcının seçimine göre ücretsiz fiyat ve 175 ülke/bölge ayarlandı; yeni bölgelerde kullanılabilirlik açık, ön sipariş kapalı.
- Build 61 işlenmiş ve iç testte; muaf olmayan şifreleme kullanımı false.

## Doğrulanamayan alan
App Privacy / Uygulama Gizliliği etiketi: genel App Store Connect API'sinde bu ankete erişim yok. Otomatik güvenlik denetimi Chrome adresini doğrulayamadığı için tarayıcı erişimini durdurdu. Bu etiketi doldurulmuş veya doğrulanmış saymıyoruz. Gizlilik politikası URL'si kayıtlıdır; URL anketin yerine geçmez.

İsteğe bağlı Gemini isteklerinde zevk profili ve öneri metni Google'a iletilir. Reklam/analitik SDK'sı olmamasını tek başına 'veri toplanmıyor' yanıtı için yeterli kabul etmeyin. Google AI ve TMDB'nin saklama uygulamaları, uygulamanın veri akışıyla birlikte değerlendirilmelidir. Kişisel notlar iOS AI isteğine eklenmez; API anahtarları JSON yedeğine dahil edilmez.
Apple açıklaması: https://developer.apple.com/app-store/app-privacy-details/

## Yayın durumu
PREPARE_FOR_SUBMISSION / MANUAL. App Review veya genel yayın başlatılmadı. Son gönderimi kullanıcı yapacak. Gizlilik etiketi ve hesap düzeyindeki yasal/bölgesel beyanların tamamlandığı bu raporla doğrulanmış değildir.

Kanıtlar: magaza-ek-bilgiler-sonucu.json, creative-assets/yukleme-sonucu.json ve app-store-hazirlik-sonucu.json.
