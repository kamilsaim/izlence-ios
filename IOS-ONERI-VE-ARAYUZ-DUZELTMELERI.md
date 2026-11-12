# iOS öneri ve arayüz düzeltmeleri — 12 Kasım 2026

## Bildirilen sorunlar ve değişiklikler
- İzledim işaretlenen yapım ana sayfada kalıyordu: izlenen ve gizlenen yapımlar ana kart, film/dizi rafları, benzer yapımlar ve kişisel/AI önerilerinde aynı kuralla elenir.
- İstenmeyen yapım için seçenek yoktu: öneri kartlarında üç nokta menüsüne İzledim ve Bunu bir daha önerme eklendi. Gizlemeler diskte ve JSON yedeğinde tutulur. Profil'den yalnızca gizlenen öneriler sıfırlanabilir.
- Ana sayfada Filmler, Diziler, Belgeseller ve Araştır yoktu: ikonlu dört kısayol eklendi; Keşfet aramasını ilgili tür filtresiyle açar.
- Arşivde ikonlar eksikti: ikonlu ve sayılı tür filtreleri, liste/kart görünümü düğmesi ve yapım ekleme ikonu eklendi. Liste satırlarında izlendi, favori, izlenecek ve not durumları ikonlarla da gösterilir.

## Kaynak ve test durumu
Kaynak commit: 780c2cea5d4e74c895047673ed36a5f76ddad6e9.
Bulut test/derleme: https://github.com/kamilsaim/izlence-ios/actions/runs/43206030967

Son kaynakta 12 birim/entegrasyon ve 4 arayüz testi geçti: toplam 16 test, 0 hata. Dört kategori kısayolunun doğru filtreyi açması, arşiv kategorilerinin seçilmesi, görünüm değiştirme ve yapım ekleme düğmeleri iPhone simülatöründe doğrulandı. Önerilerde izledim/gizleme, arşiv/notlar, büyük yazı ve yatay görünüm de test edildi. TestFlight 1.0.0 (61) Apple işleme kontrolünden geçti (VALID) ve mevcut iç test grubunda IN_BETA_TESTING olarak doğrulandı.

Son kaynak iPad Pro 13 simülatöründe derlendi ve gerçek ekran görüntüsü alındı: https://github.com/kamilsaim/izlence-ios/actions/runs/43206107188

App Store açıklaması, anahtar kelimeler, alt başlık, gizlilik/destek bağlantıları ve kategori taslakta hazırlandı. Altı iPhone ve bir iPad ekran görüntüsünün işleme durumu ve sırası API ile doğrulandı. Taslak mağaza sürümüne build 61 bağlandı. App Review veya genel yayın başlatılmadı. Fiziksel iPhone ve kişisel Gemini anahtarıyla kullanım testi kullanıcı tarafından yapılacak.
