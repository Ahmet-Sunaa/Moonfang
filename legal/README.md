# ⚖️ `legal/` — Google Play'in istediği web sayfaları

Google Play, **hesap oluşturulabilen** her uygulamadan iki şey ister:

| # | Zorunluluk | Nerede karşılanıyor |
|---|------------|---------------------|
| 1 | **Uygulama içi** hesap silme yolu | `Ayarlar → 👤 Profil → 🗑️ Hesabımı ve Tüm Verilerimi Sil` (`Settings.jsx` + `App.jsx → handleDeleteAccount`) |
| 2 | **Web sitesinden** silme talebi (URL) | Bu klasördeki `account-deletion.html` |
| 3 | **Gizlilik politikası** (URL) | Bu klasördeki `privacy-policy.html` |

Bu klasördeki üç dosya **olduğu gibi** bir web sitesine yüklenebilir; sunucu/veritabanı
gerektirmez (silme talebi e-posta ile alınır, uygulama içi silme ise anındadır).

---

## 1) Yer Tutucuları Doldur (5 dakika)

Üç HTML dosyasında toplam **27** yer tutucu var + `privacy-policy.html` içinde
yayın öncesi **silinmesi gereken** bir geliştirici notu. Hepsini tek komutla
`fill-placeholders.ps1` hallediyor:

```powershell
cd "C:\Users\ahmet\OneDrive\Desktop\GithubRepo\Tower Defense"

# Değerleri kendine göre düzenle:
.\legal\fill-placeholders.ps1 -Name "Ahmet Yilmaz" -Email "SENIN_ADRESIN@gmail.com"
# (Tarih verilmezse bugünün tarihi kullanılır: -Date "01.11.2026" ile değiştirilir)
```

Script ne yapar:

| İş | Ayrıntı |
|----|---------|
| Yer tutucuları doldurur | `[GELİŞTİRİCİ ADI]` · `[E-POSTA]` · `[GG.AA.YYYY]` · `[YIL]` |
| Geliştirici notunu **kaldırır** | "⚠️ Yayın öncesi doldurulacak alanlar" kutusu (içinde `[SARI KÖŞELİ PARANTEZ]` yazar) müşteriye görünmemeli |
| Sarı vurguyu temizler | Doldurulmuş değerler `<span class="ph">` içinde kalmamalı (yoksa "doldurulmamış" gibi görünür) |
| Kontrol eder | Kalan yer tutucu/vurgu varsa listeler ve `exit 1` verir |

| Parametre | Zorunlu | Açıklama |
|-----------|---------|----------|
| `-Name` | ✅ | Play Console'daki hesap/geliştirici adın (ör. `Ahmet Yilmaz`) |
| `-Email` | ✅ | Oyuncuların sana ulaştığı adres (**kendi adresini yaz**) |
| `-Date` | — | Yürürlük/son güncelleme tarihi `GG.AA.YYYY` (varsayılan: bugün) |
| `-Year` | — | Telif yılı (varsayılan: `-Date`'in yılı) |
| `-PrivacyUrl` `/` `-DeletionUrl` | — | Verilirse adresler `client/src/legal.js` içine de yazılır (bkz. 3. adım) |
| `-DryRun` | — | Sadece rapor verir, hiçbir dosyayı değiştirmez |

> ℹ️ Script dosyaları **UTF-8 (BOM'suz)** yazar; mevcut kodlama korunur.
> `Select-String -Path legal\*.html -Pattern '\[' -SimpleMatch` ile her zaman
> elle de kontrol edebilirsin (hiç satır dönmemeli).


---

## 2) ÜCRETSIZ Yayınla (GitHub Pages)

> ℹ️ Bu klasör şu an **git deposu değil** (`git status` → "not a git repository").
> GitHub Pages kullanacaksan önce bir kez: `git init && git add . && git commit -m "..."`
> sonra GitHub'da repo oluşturup pushla. Git istemiyorsan **Netlify Drop** daha kolay:
> `legal` klasörünü https://app.netlify.com/drop sayfasına sürükle-bırak, 10 saniyede
> `https://rastgele-ad.netlify.app/privacy-policy.html` gibi bir adres verir.

1. Bu `legal/` klasörünü GitHub'daki bir repoya koy (mevcut repon yeterlidir).
2. GitHub → **Settings → Pages → Build and deployment → Source: `Deploy from a branch`**
   → Branch: `main` / `/ (root)` → **Save**.
   - ⚠️ `legal/` klasörü kökte değilse ya klasörü köke taşı ya da bir dal/klasör yapısı
     kullan: adres `https://KULLANICI.github.io/REPO/legal/index.html` olur.
3. 1 dakika bekle, sayfayı aç: `https://KULLANICI.github.io/REPO/legal/index.html`
   (Site görünmüyorsa Pages ayarında dalı tekrar kaydet.)
4. Alternatifler (aynı iş, daha kısa adres): **Netlify Drop** (klasörü sürükle-bırak),
   **Cloudflare Pages**, kendi domain'in. Önemli olan: **herkesin görebildiği,
   `https://` ile başlayan bir bağlantı** olması.

---

## 3) Adresleri Uygulamaya ve Play Console'a Yaz

**a) Uygulama:** `client/src/legal.js`

```js
export const PRIVACY_POLICY_URL  = "https://KULLANICI.github.io/REPO/legal/privacy-policy.html";
export const ACCOUNT_DELETION_URL= "https://KULLANICI.github.io/REPO/legal/account-deletion.html";
export const SUPPORT_EMAIL       = "SENIN_ADRESIN@gmail.com";
```

> ⚡ **Kısayol:** sayfaları yayınladıktan sonra aynı script bu üç alanı da doldurabilir:
> `.\legal\fill-placeholders.ps1 -Name "SENIN_ADIN" -Email "SENIN_ADRESIN@gmail.com" -PrivacyUrl "https://ADRES/privacy-policy.html" -DeletionUrl "https://ADRES/account-deletion.html"`

Bu üç alan dolmadan `.\android-build.ps1 -Mode release` **bilerek durur**
(Play Console reddedeceği bir paket derlemeyiz).

**b) Play Console** → *App content → App privacy → Privacy policy* → gizlilik URL'si.
Play Console'un **App account deletion** alanına hesap silme URL'sini (veya aynı
sayfanın bağlantısını) yaz. Uygulama içi yolu anlatan metni de "Data deletion"
sorularına işle.

---

## 4) Doğrulama Listesi

- [ ] Yer tutucuların hepsi dolduruldu (`[İÇERİK]` kalmadı)
- [ ] Her iki sayfa **giriş yapmadan** telefondan açılıyor
- [ ] `legal.js` içindeki iki URL de `https://` ile başlıyor ve sayfa açılıyor
- [ ] E-posta adresi gerçek ve sana ulaşıyor (kendi kendine test maili at)
- [ ] Sayfadaki **uygulama içi yol** anlatımı, sürümdeki gerçek buton adıyla birebir aynı
- [ ] Firestore kurallarında `allow delete` var (`client/firestore.rules.example`)
- [ ] Test: gerçek bir Google hesabıyla giriş → Ayarlar → 🗑️ sil → aynı hesapla
      tekrar giriş → **boş hesap** gelmeli (eski elmas/rekor gelmemeli)
