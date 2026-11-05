# eTermin

Seminarski projekat za upravljanje terminima u salonima za uljepšavanje.

## Projekat ukratko

Sistem omogućava korisniku da pronađe salon i uslugu, rezerviše termin, plati ga kroz PayPal Sandbox, prati obavijesti i upravlja svojim profilom. Administrator kroz desktop aplikaciju upravlja salonima, zaposlenicima, uslugama, korisnicima i terminima te pregledava statistiku i izvještaje.

### Tehnologije

- **Backend:** .NET 9, ASP.NET Core Web API, Entity Framework Core, SQL Server, JWT
- **Poruke i pozadinski posao:** RabbitMQ i zaseban .NET Worker
- **Desktop:** Flutter za Windows
- **Mobile:** Flutter za Android
- **Plaćanje:** PayPal Sandbox

## Struktura repozitorija

```text
eTermin/
├── API/
│   ├── eTermin.Api/             # REST API, kontroleri, konfiguracija i Dockerfile
│   ├── eTermin.Application/     # DTO-i, interfejsi, validatori i poslovni ugovori
│   ├── eTermin.Domain/          # Entiteti, statusi i pravila domene
│   └── eTermin.Infrastructure/  # EF Core, migracije i implementacije servisa
├── Worker/eTermin.Worker/       # RabbitMQ potrošač i podsjetnici za termine
├── Desktop/eTermin.Admin/       # Flutter Windows aplikacija za administratora
├── Mobile/eTermin.Mobile/       # Flutter Android aplikacija za korisnike
├── docker-compose.yml           # SQL Server, RabbitMQ, API i Worker
├── .env.example                 # Predložak lokalne konfiguracije
└── eTermin.sln                  # .NET rješenje
```

Glavne tabele uključuju korisnike, salone i slike salona, zaposlenike i njihovo radno vrijeme, usluge, termine i historiju statusa, uplate i obavijesti. Gradovi i kategorije usluga su šifarnici; veze zaposlenika i usluga čuvaju se u spojnoj tabeli.

## Potrebni alati

Za backend su potrebni Docker Desktop s Docker Compose podrškom. Za klijentske aplikacije instalirajte Flutter SDK i Flutter/Dart dodatak za VS Code.

- **Windows desktop:** Visual Studio 2022 s workloadom **Desktop development with C++** i Windows SDK-om.
- **Android:** Android Studio, Android SDK, prihvaćene Android licence i pokrenut Android emulator.
- **PayPal:** Sandbox Client ID i Secret ako želite isprobati plaćanje.
- **Email reset lozinke:** SMTP vrijednosti ako želite isprobati dostavu reset koda emailom.

Provjera Flutter instalacije:

```powershell
flutter doctor -v
```

## Konfiguracija

1. Otvorite glavni folder repozitorija, isti folder u kojem se nalazi `docker-compose.yml`.
2. Repozitorij sadrži šifriranu arhivu `.env-tajne.zip`. Za predajnu konfiguraciju preuzmite šifru iz DLWMS-a i raspakujte `.env` u glavni folder. Ako arhivu ne koristite, kopirajte `.env.example` u novi fajl `.env`.
3. U `.env` postavite svoje lokalne vrijednosti. Compose koristi `Docker__ConnectionString` za SQL bazu `220043`, podatke za JWT i RabbitMQ te opcionalne PayPal i SMTP vrijednosti.
4. Ne šaljite obični `.env` na GitHub. Repozitorij sadrži `.env.example` i šifrirani `.env-tajne.zip`, bez javno izloženog sadržaja `.env` fajla.

Ako promijenite seed email ili lozinku, prijavljujte se vrijednostima iz odgovarajućih `Docker__Seed__...` varijabli u `.env`. Seeder pravi naloge kada je baza prazna; promjena `.env` sama po sebi ne mijenja već postojeću lozinku u trajnoj bazi.

## Testni nalozi

Ovi su zadani razvojni nalozi za praznu bazu kada se koriste vrijednosti iz `.env.example`:

| Aplikacija i uloga | Email | Lozinka |
|---|---|---|
| Desktop — administrator | `admin@example.local` | `Local_Admin_Password_123!` |
| Mobile — korisnik | `user@example.local` | `Local_User_Password_123!` |

Ako lokalni `.env` mijenja `Docker__Seed__AdminEmail`, `Docker__Seed__AdminPassword`, `Docker__Seed__UserEmail` ili `Docker__Seed__UserPassword`, koristite te izmijenjene podatke. Za postojeću bazu pogledajte napomenu o trajnim podacima iznad.

## Release paketi

Predajni paket nalazi se na [GitHub Release-u za 5. novembar 2026](https://github.com/mnejra03/eTermin/releases/tag/predaja-26-11-05-r1). ZIP sadrži Android APK i kompletne Windows Flutter fajlove za desktop aplikaciju. Backend nije kopiran u ZIP: pokrenite ga iz izvornog projekta prema uputama ispod, pa će mu se desktop aplikacija povezati preko `http://localhost:5130/api/`, a Android emulator preko `http://10.0.2.2:5130/api/`.

U ZIP-u su putanje:

- `Desktop/eTermin.Admin/build/windows/x64/runner/Release/` — pokrenuti `etermin_admin.exe`.
- `Mobile/eTermin.Mobile/build/app/outputs/flutter-apk/app-release.apk` — instalirati na Android uređaj/emulator.

## Pokretanje backend sistema

Pokrenite Docker Desktop i sačekajte da bude spreman. Otvorite PowerShell ili terminal u **glavnom folderu projekta**, pa izvršite:

```powershell
docker compose up --build -d
```

Compose pokreće četiri servisa: SQL Server, RabbitMQ, API i Worker. API pri pokretanju primjenjuje migracije i pokreće seeder. Worker preko RabbitMQ-a obrađuje zahtjeve za podsjetnike i kreira podsjetnik za termin u podešenom roku.

Provjera statusa i logova:

```powershell
docker compose ps
docker compose logs -f api worker
```

Otvorite:

- **Swagger:** `http://localhost:5130/swagger`
- **RabbitMQ Management:** `http://localhost:15672` (podaci za prijavu su u `.env`)
- **SQL Server iz SSMS-a:** server `localhost,14330`, SQL Server Authentication, korisnik `sa` i lozinka `MSSQL_SA_PASSWORD` iz `.env`. Baza je `220043`.

Za zaustavljanje kontejnera, uz zadržavanje baze i ostalih volumena:

```powershell
docker compose down
```

Za ponovno pokretanje bez rebuilda:

```powershell
docker compose up -d
```

> **Pažnja:** `docker compose down -v` briše Compose volumene, uključujući lokalne podatke SQL baze i RabbitMQ-a. Koristite ga samo ako namjerno želite praznu bazu i novi seed.

## Pokretanje Flutter desktop aplikacije

Backend mora biti pokrenut prije desktop klijenta. Flutter aplikacija koristi API na `http://localhost:5130/api/`.

### Iz VS Code-a

1. U VS Code-u izaberite **File → Open Folder** i otvorite `Desktop/eTermin.Admin`.
2. Ako VS Code ponudi instalaciju Flutter dodatka, instalirajte **Flutter** (Dart dodatak će se instalirati uz njega).
3. Otvorite `lib/main.dart`.
4. U biraču uređaja u donjem desnom uglu izaberite **Windows**.
5. Otvorite **Run and Debug** i izaberite pokretanje Flutter aplikacije. Ako VS Code traži konfiguraciju, izaberite **Dart & Flutter**.

### Iz terminala

Otvorite terminal u `Desktop/eTermin.Admin`:

```powershell
flutter pub get
flutter run -d windows
```

Windows desktop build može prijaviti nedostajuće C++ alate ako Visual Studio 2022 nema workload **Desktop development with C++**.

## Pokretanje Flutter mobile aplikacije

1. U Android Studio-u otvorite **Device Manager** i pokrenite Android emulator.
2. Provjerite da se emulator pojavio u VS Code biraču uređaja kao Android uređaj, npr. `sdk gphone64 x86 64`. Nemojte izabrati **Windows**, jer bi se tada pokrenula desktop varijanta.
3. Otvorite `Mobile/eTermin.Mobile` u VS Code-u, zatim `lib/main.dart`.
4. Izaberite Android emulator i pokrenite **Run and Debug**.

Ili iz terminala otvorenog u `Mobile/eTermin.Mobile` pokrenite:

```powershell
flutter pub get
flutter devices
flutter run -d <ANDROID_DEVICE_ID>
```

Android emulator pristupa API-ju na host računaru preko `http://10.0.2.2:5130/api`. API je zato potrebno pokrenuti prije aplikacije. Za fizički Android telefon emulator adresa `10.0.2.2` ne važi; telefon i računar trebaju biti na istoj mreži, a API adresa u mobilnom klijentu treba pokazivati na LAN IP računara.

## Šta se može pregledati

### Desktop administrator

- Dashboard, termini, statusi i historija termina
- Saloni, galerija slika, zaposlenici i raspored po danima
- Usluge, gradovi i kategorije usluga
- Korisnici, obavijesti, statistika i PDF izvještaji
- Pretraga i serverska paginacija na listama koje podržavaju listanje

### Mobile korisnik

- Registracija, prijava, profil i reset zaboravljene lozinke
- Pretraga salona i usluga, detalji salona i preporuke
- Rezervacija, PayPal Sandbox plaćanje, moji termini i detalji/otkazivanje
- Stanje plaćanja i obavijesti, uključujući podsjetnike

### API i sigurnost

Swagger dokumentuje REST endpoint-e. Zaštićene operacije koriste JWT i ulogu administratora gdje je potrebno. Vlasništvo termina i uplata se provjerava na backendu. Greške se obrađuju centralno; poslovne i validacijske poruke vraćaju se klijentu, a neočekivane greške se loguju i vraćaju kao opšta serverska greška.

List endpoint-i prihvataju `page` i `pageSize`, vraćaju `items`, `totalCount`, `page`, `pageSize` i `totalPages`; API ograničava veličinu stranice. Statistika se računa nad bazom, a izvještaji u desktop aplikaciji prate izabrani period i filtere.

## Korisne komande

Iz glavnog foldera:

```powershell
docker compose up --build -d
docker compose logs -f api worker
docker compose down
```

Iz Flutter foldera odgovarajuće aplikacije:

```powershell
flutter pub get
flutter analyze
```

Za backend build, iz glavnog foldera:

```powershell
dotnet build eTermin.sln
```
