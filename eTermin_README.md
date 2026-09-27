# eTermin

## Sistem za elektronsko upravljanje terminima

**Seminarski projekat -- Razvoj softvera II (2025/2026)**\
**Student:** Nejra Muminović\
**IB:** IB220043

------------------------------------------------------------------------

## O projektu

eTermin je informacioni sistem za elektronsko upravljanje terminima za
više salona/poslovnih organizacija. Sistem je realizovan kroz ASP.NET
Core Web API, SQL Server, Entity Framework Core, JWT autentifikaciju i
autorizaciju, WPF desktop aplikaciju i Angular frontend.

Desktop aplikacija predstavlja administrativni dio sistema, dok je API
centralni sloj koji sadrži poslovna pravila, validacije i pristup bazi.

## Struktura repository-ja

``` text
eTermin/
├── API/eTermin.Api/
├── Application/eTermin.Application/
├── Domain/eTermin.Domain/
├── Infrastructure/eTermin.Infrastructure/
├── Desktop/eTermin.Desktop/
├── Frontend/eTermin.Web/
└── eTermin.sln
```

-   **Domain** -- domenski entiteti.
-   **Application** -- DTO klase, interfejsi i aplikacijska logika.
-   **Infrastructure** -- implementacije servisa i EF Core pristup bazi.
-   **API** -- ASP.NET Core Web API i REST endpointi.
-   **Desktop** -- WPF administrativna aplikacija.
-   **Frontend** -- Angular web frontend.

## Tehnologije

### Backend

-   C#
-   .NET 9
-   ASP.NET Core Web API
-   Entity Framework Core
-   SQL Server
-   JWT Bearer Authentication
-   BCrypt
-   Swagger / OpenAPI

### Desktop

-   C#
-   WPF
-   XAML
-   .NET 9

### Frontend

-   Angular
-   TypeScript
-   HTML
-   CSS

## Preduvjeti

Potrebno je imati:

1.  Visual Studio 2022
2.  .NET 9 SDK
3.  SQL Server
4.  Git
5.  Node.js i npm ako se pokreće Angular frontend

Provjera .NET SDK-a:

``` powershell
dotnet --version
```

Razvojno okruženje projekta koristi `9.0.308`.

## SQL Server

Projekt koristi lokalni SQL Server i bazu `eTerminDb`.

Connection string u `API/eTermin.Api/appsettings.json`:

``` text
Server=localhost;Database=eTerminDb;Trusted_Connection=True;TrustServerCertificate=True;
```

Provjera SQL Server servisa:

``` powershell
Get-Service *SQL*
```

SQL Server mora biti pokrenut prije API-ja.

## Prvo pokretanje

Preporučeni redoslijed:

``` text
SQL Server
    ↓
ASP.NET Core API
    ↓
Swagger
    ↓
WPF Desktop
```

Otvoriti:

``` text
eTermin.sln
```

Zatim:

``` powershell
dotnet restore
dotnet build
```

## Pokretanje API-ja

U Visual Studio-u postaviti `API/eTermin.Api` kao Startup Project.

API koristi:

``` text
https://localhost:7119
```

HTTP:

``` text
http://localhost:5130
```

Swagger:

``` text
https://localhost:7119/swagger
```

Ako se Swagger otvori, backend je uspješno pokrenut.

API mora biti pokrenut prije Desktop aplikacije.

## Baza i migracije

Projekt koristi Entity Framework Core migrations.

Migracije uključuju:

``` text
20260920113141_InitialCreate
20260920113402_AddRelationshipsAndPrecision
20260922165827_AddEmployeeServices
```

Prilikom pokretanja API-ja izvršava se migration logika i seed početnih
podataka. Početni podaci uključuju korisnike, salone, zaposlenike,
usluge i termine.

Nije potrebno ručno unositi početne podatke za prvo pokretanje.

## Početni korisnički podaci

### Administrator

``` text
Email: admin@etermin.ba
Lozinka: Admin1234!
Uloga: Admin
```

Ovaj račun se koristi za Desktop aplikaciju.

### Korisnici

``` text
Email: nejra@etermin.ba
Lozinka: User123!
```

``` text
Email: sara@etermin.ba
Lozinka: User123!
```

Desktop aplikacija provjerava da prijavljeni korisnik ima `Admin` rolu.

## Pokretanje Desktop aplikacije

Nakon pokretanja API-ja:

1.  U Solution Exploreru pronaći `Desktop/eTermin.Desktop`.
2.  Postaviti ga kao Startup Project.
3.  Pokrenuti aplikaciju.

Desktop koristi:

``` text
https://localhost:7119/api/
```

Na login ekranu koristiti:

``` text
admin@etermin.ba
Admin1234!
```

Nakon uspješne prijave otvara se Dashboard.

## Funkcionalnosti Desktop aplikacije

### Dashboard

Dashboard prikazuje:

-   broj termina
-   broj korisnika
-   broj salona
-   prihod
-   najpopularniju uslugu
-   najaktivnijeg korisnika
-   najaktivniji salon
-   današnje termine
-   dostupne slotove
-   statističke prikaze
-   filter po salonu
-   Quick Actions

### Saloni

Moguće je:

-   pregledati salone
-   dodavati salone
-   uređivati salone
-   brisati salone
-   pregledati detalje
-   pretraživati
-   filtrirati
-   aktivirati/deaktivirati salon

### Usluge

Moguće je upravljati:

-   nazivom
-   opisom
-   trajanjem
-   cijenom
-   salonom
-   statusom aktivnosti

Podržane su CRUD operacije, pretraga i filtriranje.

### Zaposlenici

Podaci zaposlenika uključuju:

-   ime
-   prezime
-   email
-   telefon
-   poziciju
-   radno vrijeme
-   salon
-   aktivnost
-   usluge koje pruža

Jedan zaposlenik može pružati više usluga. Veza je realizovana preko
`EmployeeService`.

### Termini

Prilikom kreiranja termina odabiru se:

-   korisnik
-   salon
-   usluga
-   zaposlenik
-   datum
-   vrijeme
-   status

Statusi:

``` text
Pending
Confirmed
Completed
Cancelled
```

Sistem provjerava:

-   pripadnost zaposlenika salonu
-   pripadnost usluge salonu
-   da li zaposlenik pruža uslugu
-   radno vrijeme
-   preklapanje termina
-   termin u prošlosti
-   trajanje termina
-   cijenu usluge

### Dostupni slotovi

Dostupni slotovi računaju se na osnovu:

-   radnog vremena zaposlenika
-   trajanja usluge
-   postojećih termina
-   statusa termina

Otkazani termini ne blokiraju slot.

### Statistika

Statistika podržava filtere po:

-   periodu
-   salonu
-   statusu

Prikazuje:

-   broj termina
-   broj korisnika
-   broj salona
-   prihod
-   popularnu uslugu
-   aktivnog korisnika
-   aktivni salon
-   statuse termina
-   termine po danima

Prihod se računa na osnovu završenih termina.

## Postavke

Desktop aplikacija sadrži:

``` text
Postavke
├── Moj profil
└── Sigurnost
```

### Moj profil

Administrator može mijenjati:

-   ime
-   prezime
-   email

Uloga je read-only.

Validira se:

-   obaveznost imena
-   obaveznost prezimena
-   obaveznost emaila
-   format emaila
-   jedinstvenost emaila

Primjeri:

``` text
ime@domena.ba
ime@domena.com
```

Uspješno spremanje prikazuje potvrdu, a neuspješno spremanje prikazuje
poruku o grešci.

### Sigurnost

Administrator može promijeniti lozinku.

Potrebno je unijeti:

-   trenutnu lozinku
-   novu lozinku
-   potvrdu nove lozinke

Provjerava se:

-   trenutna lozinka
-   minimalno 6 znakova
-   različitost nove i stare lozinke
-   podudaranje potvrde

Lozinke se hashiraju pomoću BCrypt-a.

## Odjava

Klikom na **Odjava** prvo se prikazuje potvrda:

``` text
Da li ste sigurni da se želite odjaviti?
```

Ako korisnik potvrdi, Dashboard se zatvara i otvara Login ekran. Ako
odustane, ostaje prijavljen.

## Autentifikacija

API koristi JWT Bearer autentifikaciju.

Nakon prijave API vraća JWT token, a Desktop ga koristi u:

``` text
Authorization: Bearer <token>
```

Administrativni Desktop dio zahtijeva `Admin` ulogu.

## Arhitektura komunikacije

Desktop aplikacija ne pristupa direktno SQL Serveru.

``` text
WPF Desktop
      │
      │ HTTP / JSON
      ▼
ASP.NET Core Web API
      │
      │ Entity Framework Core
      ▼
SQL Server
```

Centralizacija poslovne logike u API-ju omogućava da različiti klijenti
koriste ista pravila i validacije.

## Pokretanje iz terminala

Iz root foldera:

``` powershell
cd C:\Users\PC\Nejra\eTermin
```

Restore:

``` powershell
dotnet restore
```

Build:

``` powershell
dotnet build
```

Pokretanje API-ja:

``` powershell
dotnet run --project API/eTermin.Api
```

Desktop je preporučeno pokrenuti kroz Visual Studio.

## Reset baze

Ako je potrebno potpuno resetovati lokalnu razvojnu bazu:

``` sql
USE master;
GO

ALTER DATABASE eTerminDb
SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

DROP DATABASE eTerminDb;
GO
```

Nakon toga pokrenuti API. Migracije i seed podaci će se ponovo
pripremiti.

**Pažnja:** ovaj postupak briše lokalnu bazu i podatke.

## Najčešći problemi

### API se ne pokreće

Provjeriti:

-   SQL Server
-   connection string
-   port 7119
-   NuGet restore

Pokrenuti:

``` powershell
dotnet restore
dotnet build
```

### Desktop ne može da se poveže

Provjeriti:

``` text
https://localhost:7119/swagger
```

Ako Swagger radi, provjeriti da Desktop koristi:

``` text
https://localhost:7119/api/
```

### Login ne radi

Provjeriti da je API pokrenut i koristiti:

``` text
admin@etermin.ba
Admin1234!
```

### Baza nije dostupna

Provjeriti:

``` powershell
Get-Service *SQL*
```

i connection string u:

``` text
API/eTermin.Api/appsettings.json
```

## Preporučeni postupak za pregled projekta

1.  Pokrenuti SQL Server.
2.  Otvoriti `eTermin.sln`.
3.  Restore/build solution.
4.  Pokrenuti `eTermin.Api`.
5.  Otvoriti `https://localhost:7119/swagger`.
6.  Pokrenuti `eTermin.Desktop`.
7.  Prijaviti se sa `admin@etermin.ba` / `Admin1234!`.
8.  Pregledati Dashboard.
9.  Pregledati salone.
10. Pregledati usluge.
11. Pregledati zaposlenike.
12. Kreirati ili urediti termin.
13. Pregledati statistiku.
14. Otvoriti Postavke → Moj profil.
15. Otvoriti Postavke → Sigurnost.
16. Testirati Odjavu.

## Informacije o projektu

**Naziv:** eTermin\
**Student:** Nejra Muminović\
**IB:** IB220043\
**Predmet:** Razvoj softvera II\
**Akademska godina:** 2025/2026
