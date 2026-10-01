# eTermin

Seminarski projekat izrade sistema za upravljanje terminima u salonima.

**Student:** Nejra MuminoviÄ‡

---

## O projektu

eTermin je informacioni sistem namijenjen za upravljanje terminima u salonima za uljepĹˇavanje.

Sistem omoguÄ‡ava korisnicima pregled salona, zaposlenika i usluga, rezervaciju termina, online plaÄ‡anje putem PayPal Sandbox sistema i pregled obavijesti.

Sistem se sastoji od:

- REST API backend aplikacije
- WPF desktop aplikacije za administraciju
- Flutter mobilne aplikacije za korisnike

Backend predstavlja centralni dio sistema i koristi SQL Server bazu podataka.

---

## Struktura projekta

```text
eTermin/
â”‚
â”śâ”€â”€ API/
â”‚   â””â”€â”€ eTermin.Api/
â”‚
â”śâ”€â”€ Application/
â”‚   â””â”€â”€ eTermin.Application/
â”‚
â”śâ”€â”€ Domain/
â”‚   â””â”€â”€ eTermin.Domain/
â”‚
â”śâ”€â”€ Infrastructure/
â”‚   â””â”€â”€ eTermin.Infrastructure/
â”‚
â”śâ”€â”€ Desktop/
â”‚   â””â”€â”€ eTermin.Desktop/
â”‚
â”śâ”€â”€ Mobile/
â”‚   â””â”€â”€ eTermin.Mobile/
â”‚
â””â”€â”€ eTermin.sln
```

### API

ASP.NET Core Web API aplikacija koja predstavlja backend sistema.

### Application

SadrĹľi aplikacijsku logiku, servise, DTO klase i interfejse.

### Domain

SadrĹľi domenske entitete sistema.

### Infrastructure

SadrĹľi pristup bazi podataka, Entity Framework Core konfiguraciju i implementacije servisa.

### Desktop

WPF desktop aplikacija namijenjena administratoru sistema.

### Mobile

Flutter mobilna aplikacija namijenjena korisnicima sistema.

---

## KoriĹˇtene tehnologije

### Backend

- .NET 9
- ASP.NET Core Web API
- Entity Framework Core
- SQL Server
- JWT Authentication
- BCrypt
- Swagger / OpenAPI

### Desktop

- WPF
- .NET 9

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

Za provjeru Flutter okruĹľenja:

```bash
flutter doctor
```

---

# Konfiguracija aplikacije

Osjetljivi podaci nisu dio repozitorija. Za lokalno pokretanje potrebno je napraviti `.env` fajl u root folderu projekta.

Kopirati:

```text
.env.example
```


# Pokretanje API aplikacije

API projekat nalazi se u:

```text
API/eTermin.Api/
```

API se moĹľe pokrenuti iz Visual Studija ili terminala.

U terminalu je potrebno otvoriti folder:

```text
API/eTermin.Api
```

i izvrĹˇiti:

```bash
dotnet restore
```

Zatim:

```bash
dotnet build
```

Nakon uspjeĹˇnog build-a:

```bash
dotnet run
```

API je konfigurisan tako da je Swagger dostupan na:

```text
http://localhost:5130/swagger
```

Swagger omoguÄ‡ava pregled i testiranje dostupnih API endpointa.

---

# Baza podataka

Projekat koristi Microsoft SQL Server i Entity Framework Core.

Prilikom pokretanja aplikacije izvrĹˇavaju se potrebne migracije baze.

PoÄŤetni podaci se kreiraju putem `DbSeeder`.

Seeder kreira poÄŤetne korisnike, salone, usluge, zaposlenike, povezivanje zaposlenika sa uslugama i termine.

Ako se projekat pokreÄ‡e prvi put, poÄŤetni podaci Ä‡e biti automatski kreirani.

---

---

# Pokretanje Desktop aplikacije

Desktop aplikacija nalazi se u:

```text
Desktop/eTermin.Desktop/
```

Desktop aplikacija je WPF aplikacija namijenjena administratoru.

Prije pokretanja potrebno je osigurati da je API pokrenut.

API adresa koju Desktop aplikacija koristi je:

```text
http://localhost:5130/api/
```

Desktop aplikaciju moguÄ‡e je pokrenuti direktno iz Visual Studija.

Nakon pokretanja administrator se prijavljuje administratorskim raÄŤunom.

---

# Pokretanje Mobile aplikacije

Mobilna aplikacija nalazi se u:

```text
Mobile/eTermin.Mobile/
```

Mobilna aplikacija razvijena je u Flutter frameworku i namijenjena je Android ureÄ‘ajima.

Prije prvog pokretanja potrebno je otvoriti terminal u folderu:

```text
Mobile/eTermin.Mobile
```

i izvrĹˇiti:

```bash
flutter pub get
```

## Pokretanje Android emulatora

Flutter neÄ‡e automatski pokrenuti Android emulator kada se izvrĹˇi samo:

```bash
flutter run
```

Ako Android emulator nije pokrenut, Flutter moĹľe prikazati samo ureÄ‘aje kao Ĺˇto su:

```text
Windows
Chrome
Edge
```

U tom sluÄŤaju nije potrebno pokretati aplikaciju na Windowsu ili web pregledniku.

Prvo je potrebno provjeriti dostupne Android emulatore:

```bash
flutter emulators
```

Primjer rezultata:

```text
1 available emulator:

Id      â€˘ Name    â€˘ Manufacturer â€˘ Platform

Pixel_7 â€˘ Pixel 7 â€˘ Google       â€˘ android
```

Android emulator se zatim pokreÄ‡e pomoÄ‡u:

```bash
flutter emulators --launch Pixel_7
```

Ako je naziv emulatora drugaÄŤiji, potrebno je koristiti ID koji je prikazan naredbom:

```bash
flutter emulators
```

Nakon pokretanja potrebno je saÄŤekati da se Android emulator potpuno otvori.

---

## Provjera dostupnih ureÄ‘aja

Kada se Android emulator pokrene, izvrĹˇiti:

```bash
flutter devices
```

Flutter Ä‡e tada prikazati dostupne ureÄ‘aje.

Primjer:

```text
Android SDK built for x86_64 â€˘ emulator-5554 â€˘ android
Windows (desktop)             â€˘ windows       â€˘ windows-x64
Chrome                        â€˘ chrome        â€˘ web-javascript
Edge                          â€˘ edge          â€˘ web-javascript
```

Potrebno je pronaÄ‡i ID Android emulatora.

U prethodnom primjeru ID je:

```text
emulator-5554
```

MeÄ‘utim, ID ne mora uvijek biti isti. Zato nije potrebno pretpostavljati da Ä‡e kod svakog korisnika biti `emulator-5554`.

---

## Pokretanje Mobile aplikacije

Nakon Ĺˇto je Android emulator pokrenut i prikazan pomoÄ‡u:

```bash
flutter devices
```

aplikacija se pokreÄ‡e pomoÄ‡u:

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

Ako Flutter prikaĹľe neki drugi Android ID, koristi se taj ID.

Primjer:

```bash
flutter run -d emulator-5556
```

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

Adresa `10.0.2.2` omoguÄ‡ava Android emulatoru pristup lokalnom raÄŤunaru.

> **Napomena:** API mora biti pokrenut prije koriĹˇtenja Mobile aplikacije.

---

# Redoslijed pokretanja Mobile aplikacije

Za pokretanje mobilne aplikacije potrebno je izvrĹˇiti sljedeÄ‡e korake:

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

### 5. SaÄŤekati da se Android emulator potpuno pokrene

### 6. Provjeriti dostupne ureÄ‘aje

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

# PoÄŤetni podaci

`DbSeeder` automatski kreira poÄŤetne podatke.

Sistem sadrĹľi ÄŤetiri salona:

1. Belle Studio â€“ Mostar
2. Glow Beauty â€“ Mostar
3. Beauty Studio â€“ Sarajevo
4. Elegance Beauty Studio â€“ Sarajevo

Svaki salon ima pribliĹľno jednak broj usluga i zaposlenika.

Primjer usluga:

- Ĺ iĹˇanje
- Farbanje kose
- Manikir
- Tretman lica
- MasaĹľa
- Feniranje
- Ĺ minkanje
- Lash Lift
- Oblikovanje obrva
- Pedikir
- Gel nokti
- Depilacija

PoÄŤetni podaci ukljuÄŤuju i zaposlenike, njihove usluge i rezervisane termine.

---

# Glavne funkcionalnosti

## Autentifikacija

Korisnik se moĹľe:

- registrovati
- prijaviti
- koristiti JWT autentifikaciju
- pristupiti funkcionalnostima na osnovu svoje uloge

---

## Saloni

Korisnik moĹľe:

- pregledati salone
- pregledati osnovne informacije o salonima
- pregledati usluge salona
- pregledati zaposlenike salona

---

## Usluge

Za svaku uslugu dostupne su informacije kao Ĺˇto su:

- naziv
- opis
- cijena
- trajanje

---

## Zaposlenici

Sistem omoguÄ‡ava pregled zaposlenika koji rade u odreÄ‘enom salonu i usluga koje pruĹľaju.

---

## Rezervacija termina

Korisnik moĹľe:

1. odabrati salon
2. odabrati uslugu
3. odabrati zaposlenika
4. odabrati datum
5. odabrati slobodan termin
6. kreirati rezervaciju
7. izvrĹˇiti plaÄ‡anje

Sistem provjerava zauzetost termina i sprjeÄŤava dvostruku rezervaciju.

---

# PayPal plaÄ‡anje

Za online plaÄ‡anje koristi se PayPal Sandbox.

Proces plaÄ‡anja:

```text
Kreiranje rezervacije
        â†“
Kreiranje pending payment zapisa
        â†“
Kreiranje PayPal Order-a
        â†“
Otvaranje PayPal stranice
        â†“
Korisnik odobrava plaÄ‡anje
        â†“
Capture PayPal Order
        â†“
Payment = Completed
        â†“
Appointment = Confirmed
        â†“
Kreiranje notifikacije
```

Koristi se PayPal Sandbox okruĹľenje, tako da se za testiranje ne koriste stvarne bankovne kartice niti stvarni novac.

---

# Notifikacije

Sistem omoguÄ‡ava kreiranje i pregled notifikacija.

Korisnik moĹľe:

- pregledati notifikacije
- oznaÄŤiti notifikaciju kao proÄŤitanu
- obrisati notifikaciju

Nakon uspjeĹˇnog PayPal plaÄ‡anja korisnik dobija notifikaciju da je plaÄ‡anje uspjeĹˇno izvrĹˇeno i da je termin potvrÄ‘en.

Na glavnom ekranu mobilne aplikacije prikazuje se crvena taÄŤkica na ikoni za notifikacije kada postoje neproÄŤitane notifikacije.

---

# Sigurnost

Za autentifikaciju se koristi JWT.

Lozinke korisnika se hashiraju pomoÄ‡u BCrypt algoritma.

API endpointi koji zahtijevaju autentifikaciju zaĹˇtiÄ‡eni su odgovarajuÄ‡im autorizacijskim mehanizmima.

---

# Arhitektura

Backend koristi slojevitu arhitekturu:

```text
API
 â†“
Application
 â†“
Domain
 â†‘
Infrastructure
```

### API layer

Prima HTTP zahtjeve i vraÄ‡a HTTP odgovore.

### Application layer

SadrĹľi poslovnu logiku, servise, DTO klase i interfejse.

### Domain layer

SadrĹľi osnovne domenske entitete.

### Infrastructure layer

Implementira pristup bazi podataka i vanjskim servisima.

---

# Swagger

Swagger se koristi za dokumentaciju i testiranje REST API-ja.

Nakon pokretanja API aplikacije Swagger je dostupan na:

```text
http://localhost:5130/swagger
```

Swagger omoguÄ‡ava pregled svih dostupnih endpointa i slanje testnih zahtjeva.

---

# SQL Server

Sistem koristi Microsoft SQL Server bazu podataka.

Entity Framework Core koristi se za:

- mapiranje entiteta
- migracije
- pristup podacima
- kreiranje i aĹľuriranje baze

---

# Reset baze podataka

Ako je potrebno ponovo kreirati poÄŤetne podatke, moguÄ‡e je obrisati postojeÄ‡u bazu i ponovo pokrenuti API.

Nakon toga `DbSeeder` ponovo kreira poÄŤetne podatke.

> **Napomena:** Seeder provjerava da li veÄ‡ postoji administratorski korisnik. Ako baza veÄ‡ sadrĹľi poÄŤetne podatke, novi seed podaci se neÄ‡e automatski dodati. Za potpuno novi skup poÄŤetnih podataka potrebno je resetovati bazu.

---

# Redoslijed pokretanja cijelog sistema

PreporuÄŤeni redoslijed pokretanja:

### 1. SQL Server

Provjeriti da je SQL Server pokrenut.

### 2. API

Pokrenuti:

```text
API/eTermin.Api
```

Swagger:

```text
http://localhost:5130/swagger
```

### 3. Desktop aplikacija

Pokrenuti:

```text
Desktop/eTermin.Desktop
```

### 4. Android emulator

Provjeriti dostupne emulatore:

```bash
flutter emulators
```

Pokrenuti emulator:

```bash
flutter emulators --launch Pixel_7
```

### 5. Mobile aplikacija

Provjeriti ureÄ‘aje:

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
- WPF desktop aplikaciju
- Flutter mobilnu aplikaciju
- PayPal Sandbox plaÄ‡anje
- sistem notifikacija
- upravljanje salonima
- upravljanje zaposlenicima
- upravljanje uslugama
- rezervaciju termina
