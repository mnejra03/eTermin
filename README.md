# eTermin

Seminarski projekat izrade sistema za upravljanje terminima u salonima.

**Student:** Nejra Muminović

---

## O projektu

eTermin je informacioni sistem namijenjen za upravljanje terminima u salonima za uljepšavanje.

Sistem omogućava korisnicima pregled salona, zaposlenika i usluga, rezervaciju termina, online plaćanje putem PayPal Sandbox sistema i pregled obavijesti.

Sistem se sastoji od:

- REST API backend aplikacije
- WPF desktop aplikacije za administraciju
- Flutter mobilne aplikacije za korisnike

Backend predstavlja centralni dio sistema i koristi SQL Server bazu podataka.

---

## Struktura projekta

```text
eTermin/
│
├── API/
│   └── eTermin.Api/
│
├── Application/
│   └── eTermin.Application/
│
├── Domain/
│   └── eTermin.Domain/
│
├── Infrastructure/
│   └── eTermin.Infrastructure/
│
├── Desktop/
│   └── eTermin.Desktop/
│
├── Mobile/
│   └── eTermin.Mobile/
│
└── eTermin.sln
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

WPF desktop aplikacija namijenjena administratoru sistema.

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

Za provjeru Flutter okruženja:

```bash
flutter doctor
```

---

# Pokretanje API aplikacije

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
https://localhost:7119/swagger
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

# Početni korisnici

## Administrator

```text
Email: admin@etermin.ba
Password: Admin123!
```

## Korisnik

```text
Email: user1@gmail.com
Password: User123!
```

Drugi testni korisnik:

```text
Email: user2@gmail.com
Password: User123!
```

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
https://localhost:7119/api/
```

Desktop aplikaciju moguće je pokrenuti direktno iz Visual Studija.

Nakon pokretanja administrator se prijavljuje administratorskim računom.

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
https://localhost:7119/swagger
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

Preporučeni redoslijed pokretanja:

### 1. SQL Server

Provjeriti da je SQL Server pokrenut.

### 2. API

Pokrenuti:

```text
API/eTermin.Api
```

Swagger:

```text
https://localhost:7119/swagger
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
- WPF desktop aplikaciju
- Flutter mobilnu aplikaciju
- PayPal Sandbox plaćanje
- sistem notifikacija
- upravljanje salonima
- upravljanje zaposlenicima
- upravljanje uslugama
- rezervaciju termina
