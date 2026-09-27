# eTermin

## Sistem za elektronsko upravljanje terminima

**Seminarski projekat – Razvoj softvera II **  
**Student:** Nejra Muminović 

---

## O projektu

eTermin je sistem za elektronsko upravljanje terminima za više salona.

Projekat se sastoji od:

- ASP.NET Core Web API backend-a
- SQL Server baze podataka
- Entity Framework Core-a
- WPF desktop aplikacije za administraciju
- Angular web aplikacije

Desktop aplikacija omogućava administratoru upravljanje salonima, uslugama, zaposlenicima, terminima i statistikama.

---

## Struktura projekta

```text
eTermin/
├── API/
├── Application/
├── Domain/
├── Infrastructure/
├── Desktop/
├── Frontend/
└── eTermin.sln
```

---

## Tehnologije

- C#
- .NET 9
- ASP.NET Core Web API
- Entity Framework Core
- SQL Server
- WPF
- Angular
- JWT
- BCrypt
- Swagger

---

## Preduvjeti

Za pokretanje projekta potrebno je imati instalirano:

- Visual Studio 2022
- .NET 9 SDK
- SQL Server
- Node.js i npm

Provjera .NET verzije:

```powershell
dotnet --version
```

Projekt je razvijan uz .NET SDK verziju:

```text
9.0.308
```

---

## Pokretanje aplikacije

### 1. Pokrenuti SQL Server

Potrebno je imati pokrenut SQL Server.

Projekt koristi bazu:

```text
eTerminDb
```

Connection string nalazi se u:

```text
API/eTermin.Api/appsettings.json
```

```text
Server=localhost;Database=eTerminDb;Trusted_Connection=True;TrustServerCertificate=True;
```

---

### 2. Otvoriti projekat

Otvoriti:

```text
eTermin.sln
```

u Visual Studio 2022.

Nakon otvaranja projekta odabrati:

**Build → Build Solution**

---

### 3. Pokrenuti API

U **Solution Exploreru** pronaći:

```text
API
└── eTermin.Api
```

Desnim klikom na `eTermin.Api` odabrati:

**Set as Startup Project**

Zatim kliknuti **Start (▶)**.

API se pokreće na:

```text
https://localhost:7119
```

Swagger je dostupan na:

```text
https://localhost:7119/swagger
```

---

### 4. Pokrenuti Desktop aplikaciju

Nakon što je API pokrenut, u **Solution Exploreru** pronaći:

```text
Desktop
└── eTermin.Desktop
```

Desnim klikom na `eTermin.Desktop` odabrati:

**Set as Startup Project**

Zatim kliknuti **Start (▶)**.

Desktop aplikacija komunicira sa API-jem preko:

```text
https://localhost:7119/api/
```

**API mora ostati pokrenut dok se koristi Desktop aplikacija.**

---

### 5. Prijava u Desktop aplikaciju

Za prijavu koristiti administratorski račun:

```text
Email: admin@etermin.ba
Lozinka: Admin1234!
```

Nakon uspješne prijave otvara se Dashboard.

---

## Početni podaci

Prilikom prvog pokretanja API-ja automatski se kreiraju početni podaci za testiranje:

- administratorski račun
- korisnici
- saloni
- zaposlenici
- usluge
- termini

Nije potrebno ručno unositi početne podatke.

---

## Glavne funkcionalnosti

Desktop aplikacija omogućava:

- Dashboard i pregled statistike
- upravljanje salonima
- upravljanje uslugama
- upravljanje zaposlenicima
- upravljanje terminima
- pregled dostupnih termina
- filtriranje i pretragu
- statistiku
- pregled prihoda
- pregled statusa termina
- uređivanje profila administratora
- promjenu lozinke
- odjavu uz potvrdu

Sistem vrši validaciju termina, radnog vremena, preklapanja termina, usluga zaposlenika i drugih poslovnih pravila.

---

## Arhitektura

```text
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

Desktop aplikacija ne pristupa direktno SQL Server bazi, već komunikaciju ostvaruje preko REST API-ja.

---

## Reset baze

Ako je potrebno resetovati lokalnu bazu, izvršiti:

```sql
USE master;
GO

ALTER DATABASE eTerminDb
SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

DROP DATABASE eTerminDb;
GO
```

Nakon toga ponovo pokrenuti `eTermin.Api`.

Baza i početni podaci će se ponovo kreirati automatski.

**Napomena:** Reset baze briše postojeće lokalne podatke.

---

## Redoslijed pokretanja

```text
1. Pokrenuti SQL Server
2. Otvoriti eTermin.sln
3. Build → Build Solution
4. Pokrenuti eTermin.Api
5. Otvoriti Swagger
6. Ostaviti API pokrenut
7. Pokrenuti eTermin.Desktop
8. Prijaviti se kao Admin
```

---

