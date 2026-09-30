# eTermin

## Sistem za elektronsko upravljanje terminima

**Seminarski projekat – Razvoj softvera II**  
**Student:** Nejra Muminović

---

## O projektu

eTermin je sistem za elektronsko upravljanje terminima namijenjen salonima koji omogućava organizaciju salona, zaposlenika, usluga i termina, kao i upravljanje korisnicima i plaćanjima.

Projekat se sastoji od:

- ASP.NET Core Web API backend-a
- SQL Server baze podataka
- Entity Framework Core-a
- WPF desktop aplikacije za administraciju
- Flutter mobilne aplikacije za korisnike

Desktop aplikacija omogućava administratoru upravljanje salonima, uslugama, zaposlenicima, terminima i statistikama.

Mobilna aplikacija omogućava korisniku pregled salona i usluga, odabir zaposlenika i termina, rezervaciju termina, PayPal plaćanje i pregled obavijesti.

---

## Struktura projekta

```text
eTermin/
├── API/
│   └── eTermin.Api/
├── Application/
│   └── eTermin.Application/
├── Domain/
│   └── eTermin.Domain/
├── Infrastructure/
│   └── eTermin.Infrastructure/
├── Desktop/
│   └── eTermin.Desktop/
├── Mobile/
│   └── eTermin.Mobile/
└── eTermin.sln

Opis glavnih dijelova
API – ASP.NET Core Web API koji predstavlja centralni backend sistema.
Application – aplikacijski sloj sa servisima, DTO klasama i poslovnom logikom.
Domain – domenski modeli i entiteti sistema.
Infrastructure – pristup bazi podataka i implementacija infrastrukturnih komponenti.
Desktop – WPF aplikacija namijenjena administratoru.
Mobile – Flutter aplikacija namijenjena krajnjem korisniku.

Tehnologije
Backend
C#
.NET 9
ASP.NET Core Web API
Entity Framework Core
SQL Server
JWT
BCrypt
Swagger
Desktop aplikacija
WPF
C#
.NET 9
Mobilna aplikacija
Flutter
Dart
HTTP REST API
PayPal Sandbox

Preduvjeti

Za pokretanje projekta potrebno je imati instalirano:

Visual Studio 2022
.NET 9 SDK
SQL Server
Flutter SDK
Android Studio / Android Emulator
Git

Provjera .NET verzije:

dotnet --version

Projekt je razvijan uz .NET SDK verziju:

9.0.308

Provjera Flutter instalacije:

flutter --version

Provjera dostupnih Flutter uređaja:

flutter device



Pokretanje backend-a
1. Pokrenuti SQL Server

Potrebno je imati pokrenut SQL Server.

Projekt koristi bazu:

eTerminDb

Connection string nalazi se u:

API/eTermin.Api/appsettings.json

Primjer connection stringa:

Server=localhost;Database=eTerminDb;Trusted_Connection=True;TrustServerCertificate=True;


2. Otvoriti projekat

Otvoriti:

eTermin.sln

u Visual Studio 2022.

Nakon otvaranja projekta odabrati:

Build → Build Solution

3. Pokrenuti API

U Solution Exploreru pronaći:

API
└── eTermin.Api

Desnim klikom na eTermin.Api odabrati:

Set as Startup Project

Zatim kliknuti Start (▶).

API se pokreće na:

https://localhost:7119

Swagger dokumentacija dostupna je na:

https://localhost:7119/swagger

Swagger omogućava pregled i testiranje dostupnih API endpointa.

API mora ostati pokrenut dok Desktop ili Mobile aplikacija koriste sistem.

Pokretanje Desktop aplikacije

Nakon što je API pokrenut, u Solution Exploreru pronaći:

Desktop
└── eTermin.Desktop

Desnim klikom na eTermin.Desktop odabrati:

Set as Startup Project

Zatim kliknuti Start (▶).

Desktop aplikacija komunicira sa API-jem preko:

https://localhost:7119/api/

API mora ostati pokrenut dok se koristi Desktop aplikacija.

Prijava u Desktop aplikaciju

Za prijavu koristiti administratorski račun:

Email: admin@etermin.ba
Lozinka: Admin1234!

Nakon uspješne prijave otvara se Dashboard.

Pokretanje Mobile aplikacije

Mobilna aplikacija nalazi se u:

Mobile/eTermin.Mobile/

Mobilna aplikacija razvijena je u Flutter frameworku.

Prije prvog pokretanja potrebno je otvoriti terminal u folderu:

Mobile/eTermin.Mobile

i izvršiti:

flutter pub get

Provjeriti dostupne uređaje:

flutter devices

Za pokretanje aplikacije:

flutter run

Mobilna aplikacija može se pokrenuti na Android emulatoru ili fizičkom Android uređaju.

API adresa za Mobile aplikaciju

Mobilna aplikacija koristi API adresu definisanu u:

lib/services/api_service.dart

Za Android emulator koristi se:

http://10.0.2.2:5130/api

Adresa 10.0.2.2 omogućava Android emulatoru pristup lokalnom računaru.

API mora biti pokrenut prije korištenja Mobile aplikacije.

Početni podaci

Prilikom prvog pokretanja API-ja automatski se kreiraju početni podaci za testiranje.

Početni podaci uključuju:

administratorski račun
korisnike
salone
zaposlenike
usluge
termine

Nije potrebno ručno unositi početne podatke.

Glavne funkcionalnosti
Desktop aplikacija

Desktop aplikacija omogućava administratoru:

Dashboard i pregled statistike
upravljanje salonima
upravljanje uslugama
upravljanje zaposlenicima
upravljanje terminima
pregled dostupnih termina
filtriranje i pretragu
pregled prihoda
pregled statusa termina
uređivanje profila administratora
promjenu lozinke
odjavu uz potvrdu
Mobile aplikacija

Mobilna aplikacija omogućava korisniku:

registraciju i prijavu
pregled salona
pregled usluga
pregled zaposlenika
odabir datuma
pregled dostupnih termina
rezervaciju termina
pregled rezerviranih termina
PayPal Sandbox plaćanje
potvrdu termina nakon uspješnog plaćanja
primanje obavijesti
pregled obavijesti
označavanje obavijesti kao pročitane
brisanje obavijesti
indikator nepročitanih obavijesti

Rezervacija termina

Proces rezervacije termina odvija se kroz nekoliko koraka:

Odabir salona
      ↓
Odabir usluge
      ↓
Odabir zaposlenika
      ↓
Odabir datuma
      ↓
Odabir dostupnog termina
      ↓
Kreiranje rezervacije
      ↓
Kreiranje plaćanja
      ↓
PayPal plaćanje
      ↓
Potvrda termina

Sistem provjerava dostupnost termina i sprječava preklapanje rezervacija.

Vrše se provjere kao što su:

zauzetost zaposlenika
zauzetost korisnika
radno vrijeme
dostupnost zaposlenika
dostupnost odabrane usluge
validnost odabranog termina
PayPal plaćanje

Za realizaciju online plaćanja koristi se PayPal Sandbox okruženje.

Proces plaćanja:

Kreiranje rezervacije
      ↓
Kreiranje Pending plaćanja
      ↓
Kreiranje PayPal Order-a
      ↓
PayPal Sandbox
      ↓
Odobravanje plaćanja
      ↓
Capture Order
      ↓
Status plaćanja: Completed
      ↓
Status termina: Confirmed

Nakon uspješnog plaćanja:

plaćanje dobija status Completed
termin dobija status Confirmed
čuva se PayPal transaction ID
korisniku se kreira obavijest o uspješnom plaćanju

Za testiranje plaćanja koriste se PayPal Sandbox korisnički računi.

Sistem obavijesti

Sistem omogućava kreiranje i upravljanje obavijestima korisnika.

Obavijest se, između ostalog, kreira nakon uspješnog PayPal plaćanja.

Korisnik može:

pregledati obavijesti
označiti obavijest kao pročitanu
obrisati obavijest

Na glavnom ekranu Mobile aplikacije prikazuje se crvena tačkica na ikoni obavijesti kada postoji nepročitana obavijest.

Autentifikacija i sigurnost

Za autentifikaciju korisnika koristi se JWT (JSON Web Token).

Nakon uspješne prijave korisnik dobija autentifikacijski token koji se koristi prilikom pozivanja zaštićenih API endpointa.

Lozinke korisnika se ne čuvaju u otvorenom obliku, već se koriste hashirane lozinke pomoću BCrypt algoritma.

API koristi autorizaciju za zaštitu funkcionalnosti koje zahtijevaju prijavljenog korisnika ili administratorske privilegije.

Arhitektura

Osnovna arhitektura sistema:

                 ┌──────────────────┐
                 │  WPF Desktop     │
                 │  Administrator   │
                 └────────┬─────────┘
                          │
                          │ HTTP / JSON
                          │
                 ┌────────▼─────────┐
                 │ ASP.NET Core API │
                 │                  │
                 │ Application      │
                 │ Domain           │
                 │ Infrastructure   │
                 └────────┬─────────┘
                          │
                          │ EF Core
                          │
                 ┌────────▼─────────┐
                 │    SQL Server    │
                 │    eTerminDb     │
                 └──────────────────┘
                          ▲
                          │
                    HTTP / JSON
                          │
                 ┌────────┴─────────┐
                 │ Flutter Mobile   │
                 │     Korisnik     │
                 └──────────────────┘

Desktop i Mobile aplikacija ne pristupaju direktno SQL Server bazi.

Komunikacija sa bazom odvija se preko ASP.NET Core Web API-ja.

API dokumentacija

Nakon pokretanja API-ja, dostupna je Swagger dokumentacija:

https://localhost:7119/swagger

Swagger omogućava pregled API endpointa i testiranje zahtjeva.

API obuhvata funkcionalnosti vezane za:

autentifikaciju
korisnike
salone
zaposlenike
usluge
termine
dostupne termine
plaćanja
PayPal
obavijesti
statistiku
preporuke
Baza podataka

Sistem koristi Microsoft SQL Server bazu:

eTerminDb

Entity Framework Core koristi se za komunikaciju između aplikacije i baze podataka.

Podaci o korisnicima, salonima, zaposlenicima, uslugama, terminima, plaćanjima i obavijestima čuvaju se u bazi podataka.

Reset baze

Ako je potrebno resetovati lokalnu bazu, izvršiti:

USE master;
GO

ALTER DATABASE eTerminDb
SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

DROP DATABASE eTerminDb;
GO

Nakon toga ponovo pokrenuti eTermin.Api.

Baza i početni podaci će se ponovo kreirati automatski.

Napomena: Reset baze briše postojeće lokalne podatke.

Redoslijed pokretanja

Za pokretanje kompletnog sistema preporučuje se sljedeći redoslijed:

1. Pokrenuti SQL Server
2. Otvoriti eTermin.sln
3. Build → Build Solution
4. Pokrenuti eTermin.Api
5. Provjeriti Swagger
6. Ostaviti API pokrenut
7. Pokrenuti eTermin.Desktop ili Mobile aplikaciju
8. Prijaviti se u aplikaciju

Za Mobile aplikaciju dodatno:

1. Otvoriti folder Mobile/eTermin.Mobile
2. Pokrenuti flutter pub get
3. Pokrenuti Android emulator
4. Pokrenuti flutter run
