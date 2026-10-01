# eTermin – dokumentacija recommender sistema

## 1. Opis

eTermin sadrži jednostavan sistem preporuke usluga koji korisniku prikazuje usluge na osnovu njegovih prethodno rezervisanih usluga.

Sistem koristi podatke iz baze podataka i implementiran je u `RecommendationService` klasi.

## 2. API endpoint

Preporuke su dostupne putem endpointa:

`GET /api/Recommendations/my`

Endpoint zahtijeva autentifikaciju korisnika.

Korisnik se identifikuje na osnovu `NameIdentifier` claim-a iz JWT tokena.

## 3. Način rada

### 3.1. Korisnik nema prethodne rezervacije

Ako korisnik nema nijednu prethodno rezervisanu uslugu koja nije otkazana, sistem pronalazi najpopularnije usluge.

Popularnost se određuje na osnovu broja termina za pojedinu uslugu.

U obzir se uzimaju samo termini čiji status nije `Cancelled`.

Vraća se najviše 5 najpopularnijih usluga.

### 3.2. Korisnik ima prethodne rezervacije

Ako korisnik ima prethodno rezervisane usluge, sistem prvo pronalazi njihove identifikatore.

Iz baze se zatim učitavaju nazivi tih usluga.

Sistem među aktivnim uslugama traži one čiji se naziv podudara sa nazivom neke od prethodno rezervisanih usluga.

Poređenje naziva nije osjetljivo na velika i mala slova.

Preporučena usluga ne može biti usluga koju je korisnik već rezervisao.

### 3.3. Nema pronađenih podudaranja

Ako se ne pronađe nijedna usluga koja odgovara prethodno korištenim uslugama, sistem kao rezervnu opciju vraća prvih 5 aktivnih usluga.

## 4. Podaci preporuke

Svaka preporuka vraća sljedeće podatke:

- `ServiceId` – identifikator usluge
- `ServiceName` – naziv usluge
- `Description` – opis usluge
- `DurationInMinutes` – trajanje usluge u minutama
- `Price` – cijena usluge
- `SalonId` – identifikator salona
- `SalonName` – naziv salona

## 5. Arhitektura

Recommender je organizovan kroz aplikacijske slojeve:

- `IRecommendationService` – definiše servis za preporuke
- `RecommendationService` – implementira logiku preporučivanja
- `RecommendationDto` – definiše podatke koji se vraćaju klijentu
- `RecommendationsController` – izlaže HTTP endpoint

Servis je registrovan u ASP.NET Core dependency injection sistemu kao scoped servis.

## 6. Ograničenja implementacije

Trenutna implementacija ne koristi mašinsko učenje niti trenirani model.

Preporuke se generišu determinističkim pravilima na osnovu:

1. prethodno rezervisanih usluga korisnika,
2. sličnosti naziva usluga,
3. popularnosti usluga kada korisnik nema prethodne rezervacije.

Ovakav pristup omogućava jednostavnu i transparentnu implementaciju preporuka unutar eTermin sistema.
