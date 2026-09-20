# eTermin

**eTermin** je sistem za elektronsko upravljanje terminima namijenjen salonima i drugim poslovnim subjektima koji pružaju usluge po principu rezervacije termina.

Projekat se razvija u okviru predmeta **Razvoj softvera II** u akademskoj 2025/2026. godini.

## Autor

**Nejra Muminović**

---

## O projektu

Cilj sistema eTermin je omogućiti korisnicima jednostavno pregledanje salona, njihovih usluga i dostupnih termina, kao i online rezervaciju termina.

Sistem je zamišljen kao **multi-salon platforma**, gdje svaki salon ima vlastite podatke, zaposlenike, usluge, radno vrijeme i termine.

Administrativni dio sistema omogućava upravljanje salonima, zaposlenicima, uslugama i terminima, kao i pregled statističkih podataka.

Planirane funkcionalnosti uključuju:

* registraciju i prijavu korisnika
* upravljanje korisničkim ulogama
* pregled salona i njihovih usluga
* pregled dostupnih termina
* rezervaciju i otkazivanje termina
* upravljanje zaposlenicima
* upravljanje uslugama
* upravljanje terminima
* evidenciju plaćanja
* PayPal integraciju
* sistem notifikacija i podsjetnika
* statistiku i izvještaje
* preporuke salona/usluga na osnovu prethodnih rezervacija
* administraciju više salona

---

## Arhitektura

Projekat koristi višeslojnu arhitekturu zasnovanu na client-server principu.

Osnovna struktura projekta:

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
│
├── Mobile/
│
├── tests/
│
├── eTermin.sln
└── README.md
```

### Slojevi

#### API

ASP.NET Core Web API projekat koji predstavlja ulaznu tačku za HTTP zahtjeve.

Sadrži:

* Controllers
* API konfiguraciju
* Swagger/OpenAPI
* Dependency Injection konfiguraciju

#### Application

Sloj koji sadrži aplikacijsku logiku i ugovore između slojeva.

Trenutno sadrži:

* DTO klase
* service interfejse

#### Domain

Centralni domen projekta koji sadrži entitete sistema.

Trenutno postoje:

* `User`
* `Salon`
* `Employee`
* `Service`
* `Appointment`
* `Payment`
* `Notification`

#### Infrastructure

Sloj zadužen za tehničku implementaciju pristupa podacima.

Koristi:

* Entity Framework Core
* SQL Server
* `eTerminDbContext`
* EF Core migrations
* implementacije application servisa

---

## Tehnologije

### Backend

* C#
* ASP.NET Core Web API
* .NET 9
* Entity Framework Core 9
* SQL Server
* Swagger / OpenAPI
* JWT Authentication — planirano

### Klijentske aplikacije

* .NET MAUI — mobilna aplikacija
* .NET Desktop — desktop aplikacija
* WebStorm — frontend/web razvoj gdje bude potrebno

### Ostale tehnologije

* Git
* GitHub
* PayPal REST API — planirana integracija

---

## Baza podataka

Sistem koristi **Microsoft SQL Server** kao relacionu bazu podataka.

Trenutna baza:

```text
eTerminDb
```

Konekcija se konfiguriše kroz:

```text
API/eTermin.Api/appsettings.json
```

Entity Framework Core se koristi za:

* mapiranje entiteta
* kreiranje baze
* migracije
* rad sa relacionim podacima

### Trenutni entiteti

```text
User
Salon
Employee
Service
Appointment
Payment
Notification
```

---

## Trenutno implementirano

Trenutna verzija projekta sadrži osnovnu infrastrukturu backend sistema.

### Salon modul

Implementiran je kompletan CRUD za salone:

```text
GET     /api/Salons
GET     /api/Salons/{id}
POST    /api/Salons
PUT     /api/Salons/{id}
DELETE  /api/Salons/{id}
```

Salon modul koristi slojevitu arhitekturu:

```text
SalonsController
        ↓
ISalonService
        ↓
Infrastructure SalonService
        ↓
eTerminDbContext
        ↓
SQL Server
```

Za komunikaciju između API-ja i domenskih podataka koristi se `SalonDto`.

Sve navedene operacije su testirane kroz Swagger.

---

## Pokretanje projekta

### Preduvjeti

Za pokretanje projekta potrebno je imati instalirano:

* Visual Studio 2022
* .NET 9 SDK
* Microsoft SQL Server
* Git

### Kloniranje repozitorija

```bash
git clone https://github.com/mnejra03/eTermin.git
```

Ulazak u folder projekta:

```bash
cd eTermin
```

### Baza podataka

Connection string se nalazi u:

```text
API/eTermin.Api/appsettings.json
```

Primjer:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=eTerminDb;Trusted_Connection=True;TrustServerCertificate=True;"
  }
}
```

### EF Core migracije

Migracije se nalaze u:

```text
Infrastructure/eTermin.Infrastructure/Migrations/
```

Za ažuriranje baze moguće je koristiti Package Manager Console:

```powershell
Update-Database
```

### Pokretanje API-ja

Pokrenuti projekat:

```text
eTermin.Api
```

Swagger se automatski otvara u browseru.

Trenutni HTTPS URL:

```text
https://localhost:7119/swagger
```

HTTP URL:

```text
http://localhost:5130
```

Portovi se mogu razlikovati ako se promijene postavke u:

```text
API/eTermin.Api/Properties/launchSettings.json
```

---

## Swagger

Swagger se koristi za dokumentovanje i testiranje REST API-ja.

Nakon pokretanja aplikacije dostupne su API operacije kroz Swagger UI.

Primjer:

```text
GET /api/Salons
```

može se koristiti za dohvat svih salona.

---

## Git

Projekat koristi Git za kontrolu verzija.

Glavna grana:

```text
main
```

GitHub repozitorij:

```text
https://github.com/mnejra03/eTermin
```

Primjer osnovnog Git workflowa:

```bash
git status
git add .
git commit -m "Opis promjene"
git push
```

---

## Plan razvoja

Razvoj sistema će se odvijati kroz nekoliko faza.

### 1. Backend osnova

* [x] Kreiranje solution-a
* [x] Kreiranje projekata i slojeva
* [x] Povezivanje projekata
* [x] SQL Server konfiguracija
* [x] Entity Framework Core
* [x] DbContext
* [x] Migracije
* [x] Swagger
* [x] Salon CRUD
* [x] DTO za salon
* [x] Application service interface
* [x] Infrastructure service

### 2. Poslovna logika

* [ ] Validacija podataka
* [ ] Korisnici i autentifikacija
* [ ] Role-based authorization
* [ ] Zaposlenici
* [ ] Usluge
* [ ] Radno vrijeme
* [ ] Termini
* [ ] Sprečavanje preklapanja termina
* [ ] Statusi termina

### 3. Dodatne funkcionalnosti

* [ ] Plaćanje putem PayPal-a
* [ ] Notifikacije
* [ ] Podsjetnici
* [ ] Statistika
* [ ] Izvještaji
* [ ] Preporuke
* [ ] Filtriranje i pretraga

### 4. Klijentske aplikacije

* [ ] Desktop aplikacija
* [ ] Mobilna aplikacija
* [ ] Povezivanje klijenata sa REST API-jem
* [ ] Login i registracija
* [ ] Pregled salona
* [ ] Rezervacija termina
* [ ] Pregled vlastitih termina

### 5. Testiranje

* [ ] Unit testovi
* [ ] Integration testovi
* [ ] Testiranje API endpointa
* [ ] Validacija poslovnih pravila
* [ ] Testiranje korisničkih scenarija

---

## Status projekta

**Status: U razvoju**

Trenutno je završena osnovna backend infrastruktura i prvi kompletan modul za upravljanje salonima.

Dalji razvoj obuhvata implementaciju ostalih domena sistema, poslovne logike, autentifikacije, plaćanja, notifikacija i klijentskih aplikacija.
