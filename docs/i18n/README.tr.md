# Status

Menü çubuğunda duran ve makineyi sessizce okuyan bir Mac uygulaması. Üstteki simgeye tıklayınca işlemci, bellek, ağ ve pil açılır. Tam resmi pano verir. Masaüstüne dört boyutta widget olarak da konur.

Rakamlar Mac’te kalır. Bir sunucuya bir şey gitmez, hesap da gerekmez.

<p align="center">
  <a href="../../README.md"><img alt="English" src="https://img.shields.io/badge/English-E7E4DC?style=for-the-badge&labelColor=E7E4DC&color=3A3A3A"></a>
  <a href="./README.ar.md"><img alt="Arabic" src="https://img.shields.io/badge/%D8%A7%D9%84%D8%B9%D8%B1%D8%A8%D9%8A%D8%A9-E7E4DC?style=for-the-badge&labelColor=E7E4DC&color=3A3A3A"></a>
  <a href="./README.fr.md"><img alt="French" src="https://img.shields.io/badge/Fran%C3%A7ais-E7E4DC?style=for-the-badge&labelColor=E7E4DC&color=3A3A3A"></a>
  <a href="./README.es.md"><img alt="Spanish" src="https://img.shields.io/badge/Espa%C3%B1ol-E7E4DC?style=for-the-badge&labelColor=E7E4DC&color=3A3A3A"></a>
  <a href="./README.de.md"><img alt="German" src="https://img.shields.io/badge/Deutsch-E7E4DC?style=for-the-badge&labelColor=E7E4DC&color=3A3A3A"></a>
  <a href="./README.tr.md"><img alt="Turkish" src="https://img.shields.io/badge/T%C3%BCrk%C3%A7e-174F46?style=for-the-badge"></a>
</p>

## İndir

Xcode yok, terminal yok.

1. [Status.zip](https://github.com/0xx9/Status/releases/latest/download/Status.zip) dosyasını indirin.
2. Dosyaya çift tıklayın. **Status** uygulaması çıkar.
3. **Status**’u **Applications** klasörüne sürükleyin.
4. İlk seferde **Status**’a Control-tıklayıp **Aç** deyin, sonra yeniden **Aç**. macOS bir kez sorar, çünkü bu kopya App Store’dan gelmez.

Sonra menü çubuğunda kalır. Simgeye tıklayın.

<p align="center">
  <img src="../screenshots/dashboard-light.png" alt="Açık görünümde Status panosu" width="920">
</p>

## Ne görünür

Pano bir sayı listesi değildir. Her aletin bir yüzü vardır: halka, iz ve durum.

- **İşlemci.** O anki pay, kullanıcı ve sistem süresi, performans ve verimlilik çekirdekleri, bir, beş ve on beş dakikalık yük. Makine bildirirse grafik okuması yanında durur.
- **Bellek.** Uygulamalar, sabitlenmiş, sıkıştırılmış ve önbellekteki bellek; basınç, takas ve hâlâ boş olan.
- **Ağ.** Gerçek arabirimde indirme ve yükleme, adres ve bir iz. Sistemin iç arabirimleri sayılmaz.
- **Pil.** Şarj ya da kalan süre, döngü sayısı ve donanım verirse sıcaklık.
- **Diskler.** Okuma ve yazma hızı, her birimin ne kadar dolu olduğu.
- **Süreçler.** Şu an en ağır olanlar, aramayla, işlemciye ya da belleğe göre sıralı.
- **Makine.** Çip, sistem, açık kalma süresi ve ısıl durum.

Panonun üstündeki tek satır neye bakmak gerektiğini söyler: sakin, meşgul, baskı altında, sıcak ya da düşük pil.

<p align="center">
  <img src="../screenshots/dashboard-dark.png" alt="Koyu görünümde Status panosu" width="920">
</p>

## Menü çubuğu

Sol tık küçük paneli açar. Sağ tık menüyü açar: izlemeyi durdur, yenile, ayrıntılar, ayarlar ve çık.

Simgenin yanında ne duracağını seçersiniz: işlemci, bellek, ağ ya da pil, aynı anda en fazla üç. Tek ölçü, sayının yerine küçük bir iz çizer.

İzleme kendi başına çalışır. Durdurulabilir ya da pilde ve Düşük Güç Modunda daha yumuşak tutulabilir. Tempo bir saniye, iki saniye ya da beştir.

İşlemci, bellek ya da ısı koyduğunuz sınırı geçince bildirim gelir. Açılıştan sonraki ilk anlar sessizdir.

Oturum açılışında başlatma Ayarlar’dadır. Yerelde imzalanmış bir derleme, Sistem Ayarları’nda bir kez onay isteyebilir.

## Widget’lar

Dört boy: küçük, orta, büyük ve çok büyük. Aynı pano: işlemci halkası, bellek, ağ, pil ve son okumaların izi. Yüzdeki saat son okumanın saatidir. İlerlerse rakamlar yenidir.

Widget, uygulamanın yazdığı durumu okur; bu yüzden menü çubuğuyla aynıdır, kendi başına ince bir örnek almaz. Uygulama çalışmıyorsa kendisi ölçer.

<p align="center">
  <img src="../screenshots/widget-small-light.png" alt="Küçük Status widget" width="220">
  &nbsp;&nbsp;
  <img src="../screenshots/widget-medium-light.png" alt="Orta Status widget" width="460">
</p>

<p align="center">
  <img src="../screenshots/widget-large-light.png" alt="Büyük Status widget" width="420">
  &nbsp;&nbsp;
  <img src="../screenshots/widget-extra-light.png" alt="Çok büyük Status widget" width="640">
</p>

Yeni bir derlemeden sonra eski Status widget’ını masaüstünden kaldırıp yeniden ekleyin. macOS, widget’ı eklendiği uygulama kopyasına bağlar.

## Dil

Uygulama sistem dilini izler. Arapçada düzen sağdan sola akar, rakamlar yerinde kalır. Ayarlar istediğiniz an Arapça ile İngilizce arasında geçer.

Bu deponun sayfaları ayrıdır. Üstteki düğmeler aynı açıklamayı İngilizce, Arapça, Fransızca, İspanyolca ve Almanca açar.

## Derleme

Yalnızca kendiniz derlemek isterseniz. Yukarıdaki indirme uygulamanın kendisidir. macOS 15 ve Xcode 16 ya da daha yenisi.

```bash
git clone https://github.com/0xx9/Status.git
cd Status
xcodebuild -project Status.xcodeproj -scheme Status -destination 'platform=macOS' -configuration Release build
open ~/Library/Developer/Xcode/DerivedData/Status-*/Build/Products/Release/Status.app
```

Ya da `Status.xcodeproj` dosyasını açıp çalıştırın.

Uygulamanın kendisi kum havuzunda değildir; süreçler, diskler ve ağ bunu ister. Widget eklentisi kum havuzundadır ve uygulamanın widget kabına yazdığı durum dosyasını okur.

## Projenin içi

| Klasör | Ne tutar |
| --- | --- |
| `Status` | Menü çubuğu, pano, ayarlar ve uyarılar |
| `StatusWidgets` | macOS widget’ı |
| `Shared` | Ölçüm, hesap, biçim ve metinler |
| `StatusTests` | Hesap, biçim ve makineden canlı bir örnek |
| `tools` | Uygulama simgesinin çizimi |

Sürüm 1.0. Tanımlayıcı `com.muhsan.status`.
