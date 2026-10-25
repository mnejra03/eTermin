# eTermin

Seminarski projekat izrade sistema za upravljanje terminima u salonima.

**Student:** Nejra Muminović

---

## O projektu

eTermin je informacioni sistem namijenjen za upravljanje terminima u salonima za uljepšavanje.

Sistem omogućava korisnicima pregled salona, zaposlenika i usluga, rezervaciju termina, online plaćanje putem PayPal Sandbox sistema i pregled obavijesti.

Sistem se sastoji od:

- REST API backend aplikacije
- Flutter Windows desktop aplikacije za administraciju (legacy WPF kod je u `Desktop/eTermin.Desktop/`)
- Flutter mobilne aplikacije za korisnike

Backend predstavlja centralni dio sistema i koristi SQL Server bazu podataka.

---

## Struktura projekta

```text
eTermin/
|-- API/eTermin.Api/
|-- Application/eTermin.Application/
|-- Domain/eTermin.Domain/
|-- Infrastructure/eTermin.Infrastructure/
|-- Worker/eTermin.Worker/
|-- Desktop/eTermin.Admin/       # Flutter Windows admin
|-- Desktop/eTermin.Desktop/     # legacy WPF client
|-- Mobile/eTermin.Mobile/       # Flutter mobile app
|-- docker-compose.yml
|-- Dockerfile.api
|-- Dockerfile.worker
`-- eTermin.sln
```
### API

ASP.NET Core Web API aplikacija koja predstavlja backend sistema.

### Application

Sadrži aplikacijsku logiku, servise, DTO klase i interfejse.

### Domain

Sadrži domenske entitete sistema.

### Infrastructure

Sadrži pristup bazi podataka, Entity Framework Core konfiguraciju i implementacije servisa.

### Desktop

Flutter Windows desktop aplikacija namijenjena administratoru nalazi se u `Desktop/eTermin.Admin/`; `Desktop/eTermin.Desktop/` je stari WPF klijent.

### Mobile

Flutter mobilna aplikacija namijenjena korisnicima sistema.

---

## Korištene tehnologije

### Backend

- .NET 9
- ASP.NET Core Web API
- Entity Framework Core
- SQL Server
- JWT Authentication
- BCrypt
- Swagger / OpenAPI

### Desktop

- Flutter
- Dart
- Windows desktop

### Mobile

- Flutter
- Dart
- HTTP REST API
- PayPal Sandbox
- Android Emulator

---

# Preduvjeti

Prije pokretanja projekta potrebno je imati instalirano:

- .NET 9 SDK
- SQL Server
- Visual Studio 2022
- Flutter SDK
- Android Studio
- Android SDK
- Android Emulator
- Git

Za provjeru .NET verzije:

```bash
dotnet --version
```

Za provjeru Flutter instalacije:

```bash
flutter --version
```

Za provjeru Flutter okruženja:

```bash
flutter doctor
```

---

# Preuzimanje i raspakivanje ZIP projekta

Ako je projekat dostavljen kao ZIP arhiva:

1. Sačuvati ZIP fajl na računaru.
2. Desnim klikom na ZIP odabrati **Extract All / Izdvoji sve**.
3. Odabrati lokaciju na kojoj će projekat biti raspakovan.
4. Ući u raspakovani glavni folder projekta.
5. Provjeriti da se u njemu nalazi `eTermin.sln` i folderi `API`, `Application`, `Domain`, `Infrastructure`, `Desktop` i `Mobile`.

Sve naredne putanje u ovom README-u odnose se na glavni folder projekta nakon raspakivanja. Ne pokretati komande direktno unutar ZIP arhive.

---

# Konfiguracija aplikacije i `.env` fajl

Ako projekat sadrži `.env.example`, potrebno je napraviti lokalni `.env` fajl na lokaciji koju očekuje aplikacija.

1. Otvoriti `.env.example` u editoru teksta, npr. Visual Studio Code ili Notepad.
2. Označiti **sav sadržaj** fajla (`Ctrl+A`) i kopirati ga (`Ctrl+C`).
3. U istom folderu napraviti novi fajl pod nazivom tačno `.env` — bez dodatne ekstenzije poput `.txt`.
4. Otvoriti novi `.env` fajl, zalijepiti cijeli kopirani sadržaj (`Ctrl+V`) i sačuvati ga.
5. Zamijeniti primjer-vrijednosti stvarnim lokalnim postavkama koje su potrebne za pokretanje, npr. adresama servisa ili pristupnim podacima, ako ih primjer sadrži.
6. Sačuvati `.env` i ponovo pokrenuti aplikaciju ako je već bila pokrenuta.

**Važno:** `.env.example` je predložak, a `.env` je lokalni konfiguracijski fajl. Nemojte javno objavljivati niti slati lozinke, API ključeve, tokene ili druge tajne vrijednosti. Nemojte uklanjati postojeće nazive varijabli. Ako `.env.example` nije prisutan u ZIP-u, nemojte izmišljati njegov sadržaj — provjerite u projektnom kodu koja konfiguracija se očekuje.

# Podaci za prijavu

Za pregled rada koristite ove testne naloge. `DbSeeder` ih kreira pri prvom pokretanju Docker Compose sistema s praznom bazom `220043`.

| Kontekst | Korisničko ime | Lozinka |
|---|---|---|
| Desktop administrator | `admin@example.local` | `Local_Admin_Password_123!` |
| Mobilni korisnik | `user@example.local` | `Local_User_Password_123!` |

Nalozi i lozinke su razvojni testni podaci. Vrijednosti Compose profila nalaze se u `.env.example` (`Docker__Seed__Admin...` i `Docker__Seed__User...`). PayPal i ostale tajne ostaju u lokalnom `.env` fajlu.

# Pokretanje API aplikacije

## Docker Compose: API, SQL Server, RabbitMQ i Worker

Napravite lokalni `.env` kopiranjem `.env.example`, zatim iz glavnog foldera projekta pokrenite:

```powershell
docker compose up --build -d
```

Ova komanda pokreće API, SQL Server s bazom `220043`, RabbitMQ i zaseban Worker kontejner. API pri startu primjenjuje migracije i, na praznoj bazi, kreira testne naloge i demonstracione podatke. Swagger je na `http://localhost:5130/swagger`; RabbitMQ Management je na `http://localhost:15672`. Desktop Flutter koristi `http://localhost:5130/api/`, a Android emulator `http://10.0.2.2:5130/api/`. Worker prima poruke za termine preko RabbitMQ-a i zakazuje podsjetnike koji se korisniku prikazuju u aplikaciji u konfigurisanom roku.

Za zaustavljanje servisa bez brisanja podataka koristite:

```powershell
docker compose down
```

Sve pristupne vrijednosti i servisi podešavaju se u `.env`; Compose više ne zahtijeva poseban profil.

### Lokalno pokretanje bez Compose-a

Za lokalni API i Flutter desktop koristite `Start-eTermin.vbs`; connection string u `.env` cilja SQL Server na `localhost,14330` i bazu `220043`. SQL Server i RabbitMQ i dalje moraju biti pokrenuti, npr. kroz Docker Compose.

### API

API projekat nalazi se u:

```text
API/eTermin.Api/
```

API se može pokrenuti iz Visual Studija ili terminala.

U terminalu je potrebno otvoriti folder:

```text
API/eTermin.Api
```

i izvršiti:

```bash
dotnet restore
```

Zatim:

```bash
dotnet build
```

Nakon uspješnog build-a:

```bash
dotnet run
```

API je konfigurisan tako da je Swagger dostupan na:

```text
http://localhost:5130/swagger
```

Swagger omogućava pregled i testiranje dostupnih API endpointa.

---

# Baza podataka

Projekat koristi Microsoft SQL Server i Entity Framework Core.

Prilikom pokretanja aplikacije izvršavaju se potrebne migracije baze.

Početni podaci se kreiraju putem `DbSeeder`.

Seeder kreira početne korisnike, salone, usluge, zaposlenike, povezivanje zaposlenika sa uslugama i termine.

Ako se projekat pokreće prvi put, početni podaci će biti automatski kreirani.

---

# Pokretanje Desktop aplikacije

Aktivna desktop aplikacija je Flutter Windows klijent u `Desktop/eTermin.Admin/`. `Desktop/eTermin.Desktop/` je legacy WPF kod.

1. Pokrenite Docker Desktop.
2. Iz glavnog foldera projekta pokrenite backend:

```powershell
docker compose up --build -d
```

3. U VS Code otvorite **Run and Debug**, izaberite **Flutter Admin (Windows)** i pritisnite **F5**. API u Dockeru već sluša na `http://localhost:5130`; nemojte paralelno pokretati lokalni API.

Testni administratorski nalog za čistu bazu naveden je u tabeli **Podaci za prijavu**.

---
# Pokretanje Mobile aplikacije

Mobilna aplikacija nalazi se u:

```text
Mobile/eTermin.Mobile/
```

Mobilna aplikacija razvijena je u Flutter frameworku i namijenjena je Android uređajima.

Prije prvog pokretanja potrebno je otvoriti terminal u folderu:

```text
Mobile/eTermin.Mobile
```

i izvršiti:

```bash
flutter pub get
```

## Pokretanje Android emulatora

Flutter neće automatski pokrenuti Android emulator kada se izvrši samo:

```bash
flutter run
```

Ako Android emulator nije pokrenut, Flutter može prikazati samo uređaje kao što su:

```text
Windows
Chrome
Edge
```

U tom slučaju nije potrebno pokretati aplikaciju na Windowsu ili web pregledniku.

Prvo je potrebno provjeriti dostupne Android emulatore:

```bash
flutter emulators
```

Primjer rezultata:

```text
1 available emulator:

Id      • Name    • Manufacturer • Platform

Pixel_7 • Pixel 7 • Google       • android
```

Android emulator se zatim pokreće pomoću:

```bash
flutter emulators --launch Pixel_7
```

Ako je naziv emulatora drugačiji, potrebno je koristiti ID koji je prikazan naredbom:

```bash
flutter emulators
```

Nakon pokretanja potrebno je sačekati da se Android emulator potpuno otvori.

---

## Provjera dostupnih uređaja

Kada se Android emulator pokrene, izvršiti:

```bash
flutter devices
```

Flutter će tada prikazati dostupne uređaje.

Primjer:

```text
Android SDK built for x86_64 • emulator-5554 • android
Windows (desktop)             • windows       • windows-x64
Chrome                        • chrome        • web-javascript
Edge                          • edge          • web-javascript
```

Potrebno je pronaći ID Android emulatora.

U prethodnom primjeru ID je:

```text
emulator-5554
```

Međutim, ID ne mora uvijek biti isti. Zato nije potrebno pretpostavljati da će kod svakog korisnika biti `emulator-5554`.

---

## Pokretanje Mobile aplikacije

Nakon što je Android emulator pokrenut i prikazan pomoću:

```bash
flutter devices
```

aplikacija se pokreće pomoću:

```bash
flutter run -d <ANDROID_DEVICE_ID>
```

Na primjer, ako je ID:

```text
emulator-5554
```

koristi se:

```bash
flutter run -d emulator-5554
```

Ako Flutter prikaže neki drugi Android ID, koristi se taj ID.

Primjer:

```bash
flutter run -d emulator-5556
```

---

## Instaliranje gotove Android APK aplikacije

Ako je uz projekat dostavljen gotov APK, nije potrebno pokretati `flutter run` da bi se aplikacija instalirala na Android telefon.

### Lokacija APK fajla u dostavljenoj build arhivi

U izdanju koje je pripremljeno na računaru za izgradnju aplikacije, APK se nalazi na putanji:

```text
 eTermin.Mobile/build/app/outputs/flutter-apk/app-release.apk
```

Na računaru na kojem je napravljen ovaj build puna putanja je bila:

```text
C:\Users\PC\Desktop\eTermin-build-2026-10-01\eTermin.Mobile\build\app\outputs\flutter-apk\app-release.apk
```

Puna putanja zavisi od lokacije na kojoj je ZIP raspakovan. U File Exploreru otvoriti folder `eTermin.Mobile/build/app/outputs/flutter-apk/` i pronaći `app-release.apk`.

### Instalacija na Android telefon

1. Kopirati `app-release.apk` na Android telefon, npr. USB kablom u folder **Downloads/Preuzimanja**.
2. Na telefonu otvoriti aplikaciju **Files/Datoteke** i pronaći `app-release.apk`.
3. Dodirnuti APK fajl i odabrati **Install/Instaliraj**.
4. Ako Android prikaže upozorenje o instaliranju aplikacija iz tog izvora, dozvoliti instalaciju za aplikaciju kojom je APK otvoren.
5. Nakon instalacije izabrati **Open/Otvori** ili pronaći eTermin među instaliranim aplikacijama.

Android može prikazati upozorenje zato što se APK instalira izvan Google Play prodavnice. Instalirati samo APK koji dolazi iz pouzdanog izvora.

### Instalacija na pokrenuti emulator preko ADB-a

Pokrenuti Android emulator, otvoriti PowerShell u folderu s APK fajlom i izvršiti:

```powershell
adb install -r app-release.apk
```

Ako PowerShell nije otvoren u tom folderu, prvo pokrenuti (prilagoditi putanju ako je projekat raspakovan na drugoj lokaciji):

```powershell
cd "C:\Users\PC\Desktop\eTermin-build-2026-10-01\eTermin.Mobile\build\app\outputs\flutter-apk"
```

Zatim izvršiti naredbu `adb install -r app-release.apk`. Ako `adb` nije prepoznat, potrebno je instalirati/podesiti Android SDK Platform-Tools ili koristiti terminal u Android Studiju.

### Ako je aplikacija instalirana, ali ne može pristupiti API-ju

Telefon i emulator ne koriste isti način pristupa lokalnom računaru:

- Android emulator standardno koristi `http://10.0.2.2:5130/api` za pristup API-ju koji radi na računaru.
- Fizički telefon ne može koristiti `localhost` ili `10.0.2.2` kao adresu računara. Potrebna mu je dostupna lokalna mrežna IP adresa računara, API koji sluša na toj mreži i odgovarajuća mrežna/firewall konfiguracija.
- API mora biti pokrenut. Ako se API adresa ugrađuje tokom builda ili je definisana u kodu, promjena konfiguracije može zahtijevati ponovno pravljenje APK-a.

U projektu provjeriti API adresu u `lib/services/api_service.dart` i koristiti adresu koja odgovara uređaju na kojem se aplikacija pokreće.

---

## API adresa za Mobile aplikaciju

Mobilna aplikacija koristi API adresu definisanu u:

```text
lib/services/api_service.dart
```

Za Android emulator koristi se:

```text
http://10.0.2.2:5130/api
```

Adresa `10.0.2.2` omogućava Android emulatoru pristup lokalnom računaru.

> **Napomena:** API mora biti pokrenut prije korištenja Mobile aplikacije.

---

# Redoslijed pokretanja Mobile aplikacije

Za pokretanje mobilne aplikacije potrebno je izvršiti sljedeće korake:

### 1. Otvoriti Mobile projekat

```text
Mobile/eTermin.Mobile
```

### 2. Preuzeti dependencies

```bash
flutter pub get
```

### 3. Provjeriti dostupne emulatore

```bash
flutter emulators
```

### 4. Pokrenuti Android emulator

Primjer:

```bash
flutter emulators --launch Pixel_7
```

### 5. Sačekati da se Android emulator potpuno pokrene

### 6. Provjeriti dostupne uređaje

```bash
flutter devices
```

### 7. Pokrenuti Flutter aplikaciju na Android emulatoru

```bash
flutter run -d <ANDROID_DEVICE_ID>
```

Na primjer:

```bash
flutter run -d emulator-5554
```

---

# Početni podaci

`DbSeeder` automatski kreira početne podatke.

Sistem sadrži četiri salona:

1. Belle Studio – Mostar
2. Glow Beauty – Mostar
3. Beauty Studio – Sarajevo
4. Elegance Beauty Studio – Sarajevo

Svaki salon ima približno jednak broj usluga i zaposlenika.

Primjer usluga:

- Šišanje
- Farbanje kose
- Manikir
- Tretman lica
- Masaža
- Feniranje
- Šminkanje
- Lash Lift
- Oblikovanje obrva
- Pedikir
- Gel nokti
- Depilacija

Početni podaci uključuju i zaposlenike, njihove usluge i rezervisane termine.

---

# Glavne funkcionalnosti

## Autentifikacija

Korisnik se može:

- registrovati
- prijaviti
- koristiti JWT autentifikaciju
- pristupiti funkcionalnostima na osnovu svoje uloge

---

## Saloni

Korisnik može:

- pregledati salone
- pregledati osnovne informacije o salonima
- pregledati usluge salona
- pregledati zaposlenike salona

---

## Usluge

Za svaku uslugu dostupne su informacije kao što su:

- naziv
- opis
- cijena
- trajanje

---

## Zaposlenici

Sistem omogućava pregled zaposlenika koji rade u određenom salonu i usluga koje pružaju.

---

## Rezervacija termina

Korisnik može:

1. odabrati salon
2. odabrati uslugu
3. odabrati zaposlenika
4. odabrati datum
5. odabrati slobodan termin
6. kreirati rezervaciju
7. izvršiti plaćanje

Sistem provjerava zauzetost termina i sprječava dvostruku rezervaciju.

---

# PayPal plaćanje

Za online plaćanje koristi se PayPal Sandbox.

Proces plaćanja:

```text
Kreiranje rezervacije
        ↓
Kreiranje pending payment zapisa
        ↓
Kreiranje PayPal Order-a
        ↓
Otvaranje PayPal stranice
        ↓
Korisnik odobrava plaćanje
        ↓
Capture PayPal Order
        ↓
Payment = Completed
        ↓
Appointment = Confirmed
        ↓
Kreiranje notifikacije
```

Koristi se PayPal Sandbox okruženje, tako da se za testiranje ne koriste stvarne bankovne kartice niti stvarni novac.

---

# Notifikacije

Sistem omogućava kreiranje i pregled notifikacija.

Korisnik može:

- pregledati notifikacije
- označiti notifikaciju kao pročitanu
- obrisati notifikaciju

Nakon uspješnog PayPal plaćanja korisnik dobija notifikaciju da je plaćanje uspješno izvršeno i da je termin potvrđen.

Na glavnom ekranu mobilne aplikacije prikazuje se crvena tačkica na ikoni za notifikacije kada postoje nepročitane notifikacije.

---

# Sigurnost

Za autentifikaciju se koristi JWT.

Lozinke korisnika se hashiraju pomoću BCrypt algoritma.

API endpointi koji zahtijevaju autentifikaciju zaštićeni su odgovarajućim autorizacijskim mehanizmima.

---

# Arhitektura

Backend koristi slojevitu arhitekturu:

```text
API
 ↓
Application
 ↓
Domain
 ↑
Infrastructure
```

### API layer

Prima HTTP zahtjeve i vraća HTTP odgovore.

### Application layer

Sadrži poslovnu logiku, servise, DTO klase i interfejse.

### Domain layer

Sadrži osnovne domenske entitete.

### Infrastructure layer

Implementira pristup bazi podataka i vanjskim servisima.

---

# Swagger

Swagger se koristi za dokumentaciju i testiranje REST API-ja.

Nakon pokretanja API aplikacije Swagger je dostupan na:

```text
http://localhost:5130/swagger
```

Swagger omogućava pregled svih dostupnih endpointa i slanje testnih zahtjeva.

---

# SQL Server

Sistem koristi Microsoft SQL Server bazu podataka.

Entity Framework Core koristi se za:

- mapiranje entiteta
- migracije
- pristup podacima
- kreiranje i ažuriranje baze

---

# Reset baze podataka

Ako je potrebno ponovo kreirati početne podatke, moguće je obrisati postojeću bazu i ponovo pokrenuti API.

Nakon toga `DbSeeder` ponovo kreira početne podatke.

> **Napomena:** Seeder provjerava da li već postoji administratorski korisnik. Ako baza već sadrži početne podatke, novi seed podaci se neće automatski dodati. Za potpuno novi skup početnih podataka potrebno je resetovati bazu.

---

# Redoslijed pokretanja cijelog sistema

### 1. Backend servisi

Pokrenite Docker Desktop, otvorite terminal u glavnom folderu projekta i izvršite:

```powershell
docker compose up --build -d
```

Ova komanda pokreće SQL Server, API, RabbitMQ i Worker. Swagger je dostupan na `http://localhost:5130/swagger`.

### 2. Flutter desktop aplikacija

U VS Code-u otvorite **Run and Debug**, izaberite **Flutter Admin (Windows)** i pritisnite **F5**. Ne pokrećite lokalni API paralelno s Docker API-jem.
### 5. Mobile aplikacija

Provjeriti uređaje:

```bash
flutter devices
```

Pokrenuti aplikaciju na Android emulatoru:

```bash
flutter run -d <ANDROID_DEVICE_ID>
```

---

# Napomena

eTermin je razvijen kao seminarski projekat sa ciljem demonstracije primjene modernih tehnologija za razvoj distribuiranog informacionog sistema.

Projekat objedinjuje:

- REST API
- SQL Server
- Entity Framework Core
- JWT autentifikaciju
- Flutter Windows desktop aplikaciju
- Flutter mobilnu aplikaciju
- PayPal Sandbox plaćanje
- sistem notifikacija
- upravljanje salonima
- upravljanje zaposlenicima
- upravljanje uslugama
- rezervaciju termina
