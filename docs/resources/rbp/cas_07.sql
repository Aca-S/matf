/*
 * 1. Napraviti tabelu kandidati_za_upis u kojoj će se nalaziti podaci o prijavama
 * za upis na fakultet. Tabela ima kolone:
 *
 *  id - identifikator prijave, ceo broj
 *  idprograma - identifikator željenog studijskog programa
 *  ime - ime kandidata, niska maksimalne dužine 50 karaktera
 *  prezime - prezime kandidata, niska maksimalne dužine 50 karaktera
 *  pol - pol kandidata; moguće vrednosti su karakteri 'm' ili 'z'
 *  mestorodjenja - mesto rođenja kandidata, niska maksimalne dužine 50 karaktera
 *  datumprijave - datum prijave kandidata
 *  bodovi - bodovi za upis
 *
 * Definisati primarni ključ u tabeli kandidati_za_upis i strani ključ na tabelu
 * studijskiprogram. Postaviti ograničenje za moguće vrednosti kolone pol.
 */

-- Prvi deo rešenja (kreiranje tabele):

CREATE TABLE KANDIDATI_ZA_UPIS (
    ID INT,
    IDPROGRAMA INT,
    IME VARCHAR(50),
    PREZIME VARCHAR(50),
    POL CHAR,
    MESTORODJENJA VARCHAR(50),
    DATUMPRIJAVE DATE,
    BODOVI DECIMAL(5, 2)
);

-- Objašnjenje:
--
-- Za početak, samo ćemo kreirati osnovnu tabelu sa nazivom KANDIDATI_ZA_UPIS i sa
-- traženim kolonama odgovarajućeg tipa. Dodatna ograničenja na vrednosti u kolonama
-- i ključeve ćemo postaviti u nastavku.
--
-- Tabele kreiramo sa naredbom CREATE TABLE <naziv tabele> (<struktura tabele>);.
-- U okviru strukture tabele navodimo kolone tabele (njihove nazive) i njihove
-- tipove - na primer, u ovom primeru, prva kolona ima naziv "ID" i tipa je "INT".
--
-- Prilikom kreiranja tabele (ili bilo kojih drugih objekata u bazi, o kojima će
-- više reči biti narednih časova), moguće je specifikovati i shemu u kojoj će tabela
-- biti kreirana. Ovo se postiže navođenjem naziva sheme uz naziv tabele u sledećem
-- formatu: CREATE TABLE <naziv sheme>.<naziv tabele> (<struktura tabele>);.
-- Kada bi hteli da kreiramo tabelu KANDIDATI_ZA_UPIS u shemi DA, to bi postigli sa
-- naredbom CREATE TABLE DA.KANDIDATI_ZA_UPIS (...);. Ukoliko shema nije navedena,
-- tabela će biti kreirana u podrazumevanoj shemi (ukoliko to nismo menjali, podrazumevana
-- shema ima naziv korisnika baze koji izvršava naredbu, a to je podrazumevano DB2INST1).
--
-- Nešto više o korišćenim tipovima kolona:
--
-- INT (ili INTEGER) - Označeni 32-bitni ceo broj. U zavisnosti od konkretnog slučaja,
-- nekada je pogodnije koristiti cele brojeve drugih širina (manjih ako želimo da uštedimo
-- na memoriji, ili većih ako manja širina nije dovoljna). Zbog ovoga, na raspolaganju
-- su nam tipovi SMALLINT, tj. 16-bitni int, i BIGINT, tj. 64-bitni int. Kao jedan primer,
-- kolona SKGODINA u tabeli DA.ISPITNIROK je tipa SMALLINT jer će se u njoj nalaziti
-- samo godine, a 16-bitni broj (opseg od -32,768 do +32,767) je i više nego dovoljan
-- za to.
--
-- CHAR(n) i VARCHAR(n) - Ova dva tipa predstavljaju niske dužine n, ali sa jednom
-- bitnom razlikom između njih. Naime, CHAR(n) označava niske fiksne dužine n,
-- tj. skladišti niske tačno dužine n (manje niske će se dopuniti blanko karakterima
-- do dužine n), dok VARCHAR(n) označava niske promenljive dužine, ali do dužine n.
-- U nekim situacijama, upotreba CHAR umesto VARCHAR može biti efikasnija jer je
-- dužina niske onda unapred poznata, ali po cenu većeg, možda nepotrebnog, zauzeća
-- memorije. Ukoliko se dužina ne navede uz CHAR(n), tj. koristimo samo CHAR,
-- podrazumevana dužina je 1 (tj. jedan karakter). Isto nije moguće uraditi za VARCHAR.
--
-- DATE - Predstavlja datum. Ukoliko nam je potrebno vreme, onda možemo koristiti tip TIME,
-- a ukoliko su nam potrebni i datum i vreme, onda možemo koristiti tip TIMESTAMP.
--
-- DECIMAL(n, m) - Decimalni broj sa do n cifara od kojih je m rezervisano za mesta iza
-- decimalne tačke. DECIMAL(5, 2) je onda dovoljan za predstavljanje brojeva poput
-- 100.00, 42.42, 1.59 i slično, ali ne i za, na primer, 1234.5678. Sinonim za DECIMAL
-- je NUMERIC.
-- Ukoliko ne želimo da ovako fiksiramo preciznost decimalnog broja, možemo koristiti
-- i tipove REAL, FLOAT, DOUBLE.

-- Drugi deo rešenja (uslovi za NULL vrednosti i primarni ključ):

DROP TABLE KANDIDATI_ZA_UPIS; -- Brišemo prethodno definisanu tabelu da bi kreirali novu sa dodatnim uslovima

CREATE TABLE KANDIDATI_ZA_UPIS (
    ID INT NOT NULL PRIMARY KEY,
    IDPROGRAMA INT NOT NULL,
    IME VARCHAR(50) NOT NULL,
    PREZIME VARCHAR(50) NOT NULL,
    POL CHAR,
    MESTORODJENJA VARCHAR(50),
    DATUMPRIJAVE DATE,
    BODOVI DECIMAL(5, 2)
);

-- Objašnjenje:
--
-- U nastavku, želimo da dodamo neke dodatne uslove za vrednosti koje se mogu naći
-- u kolonama prethodno kreirane tabele. Da bi uradili to, prvo ćemo obrisati prethodnu
-- tabelu sa naredbom DROP TABLE <naziv tabele>;. Važna napomena - brisanje tabele sa
-- naredbom DROP briše i sve podatke u toj tabeli (kojih, u ovom slučaju, još uvek
-- nemamo).
--
-- Naime, sa prvom definicijom tabele, sve od njenih kolona bi zapravo mogle da prihvate
-- nepoznatu, tj. NULL, vrednost. Ukoliko želimo da zabranimo ovo za neku kolonu,
-- potrebno je navesti NOT NULL uz nju. Ovako smo se osigurali da vrednosti kolona
-- ID, IDPROGRAMA, IME i PREZIME moraju biti poznate.
--
-- Pored ovoga, želimo da dodelimo i primarni ključ našoj tabeli. Očigledan kandidat
-- za to je upravo kolona ID. Nju proglašavamo za primarni ključ navođenjem PRIMARY KEY
-- uz njenu definiciju. Napomena - da bi neku kolonu proglasili za PRIMARY KEY, ona
-- prethodno mora biti označena sa NOT NULL!
--
-- Postoje situacije kada nam je primarni ključ kolone sačinjen od više od jedne kolone.
-- Na primer, ako pogledamo tabelu DA.ISPITNIROK, primarnki ključ je tu sačinjen od kolona
-- SKGODINA i OZNAKAROKA. U ovom slučaju, postavljanje primarnog ključa moramo uraditi
-- na malo drugačiji način:
--
-- CREATE TABLE DA.ISPITNIROK (
--     SKGODINA SMALLINT NOT NULL,
--     OZNAKAROKA VARCHAR(20) NOT NULL,
--     ...
--     PRIMARY KEY (SKGODINA, OZNAKAROKA) - Navodimo PRIMARY KEY u novom redu, sa svim njegovim kolonama u zagradama!
-- );
--
-- Ovo je naravno moguće uraditi i u našem slučaju, tj. ako je primarni ključ sačinjen
-- od samo jedne kolone:
--
-- CREATE TABLE KANDIDATI_ZA_UPIS (
--     ID INT NOT NULL,
--     IDPROGRAMA INT NOT NULL,
--     IME VARCHAR(50) NOT NULL,
--     PREZIME VARCHAR(50) NOT NULL,
--     POL CHAR,
--     MESTORODJENJA VARCHAR(50),
--     DATUMPRIJAVE DATE,
--     BODOVI DECIMAL(5, 2),
--
--     PRIMARY KEY (ID)
-- );

-- Treći deo rešenja (strani ključ od IDPROGRAMA na DA.STUDIJSKIPROGRAM):

DROP TABLE KANDIDATI_ZA_UPIS;

CREATE TABLE KANDIDATI_ZA_UPIS (
    ID INT NOT NULL,
    IDPROGRAMA INT NOT NULL,
    IME VARCHAR(50) NOT NULL,
    PREZIME VARCHAR(50) NOT NULL,
    POL CHAR,
    MESTORODJENJA VARCHAR(50),
    DATUMPRIJAVE DATE,
    BODOVI DECIMAL(5, 2),

    PRIMARY KEY (ID),
    FOREIGN KEY (IDPROGRAMA) REFERENCES DA.STUDIJSKIPROGRAM
);

-- Objašnjenje:
--
-- Želimo da se osiguramo da IDPROGRAMA kandidata odgovara identifikatoru nekog
-- studijskog programa iz tabele DA.STUDIJSKIPROGRAM. Da bi to obezbedili, napravićemo
-- strani ključ iz kolone IDPROGRAMA na tabelu DA.STUDIJSKIPROGRAM.
--
-- Ovo postižemo pomoću FOREIGN KEY (<lista kolona>) REFERENCES <naziv tabele> naredbe.
-- Ovako kreira strani ključ od kolona <lista kolona> prema primarnom ključu tabele <naziv tabele>.
-- Tipovi kolona stranog ključa i primarnog ključa u ciljnoj tabeli se moraju poklapati.
--
-- Nakon ovoga, ako bi neko pokušao da ubaci identifikator nepostojećeg programa u tabelu
-- KANDIDATI_ZA_UPIS, dobio bi grešku.
--
-- Ukoliko je strani ključ sačinjen od samo jedne kolone (kao što je slučaj ovde), on
-- se može definisati i odmah uz kolonu umesto u odvojenom redu (slično kao i za PRIMARY KEY),
-- tj. "IDPROGRAMA INT NOT NULL REFERENCES DA.STUDIJSKIPROGRAM".

-- Četvrti deo rešenja (ograničenje nad vrednostima kolone POL):

DROP TABLE KANDIDATI_ZA_UPIS;

CREATE TABLE KANDIDATI_ZA_UPIS (
    ID INT NOT NULL,
    IDPROGRAMA INT NOT NULL,
    IME VARCHAR(50) NOT NULL,
    PREZIME VARCHAR(50) NOT NULL,
    POL CHAR,
    MESTORODJENJA VARCHAR(50),
    DATUMPRIJAVE DATE,
    BODOVI DECIMAL(5, 2),

    PRIMARY KEY (ID),
    FOREIGN KEY (IDPROGRAMA) REFERENCES DA.STUDIJSKIPROGRAM,
    CHECK (POL IN ('m', 'z'))
);

-- Objašnejnje:
--
-- Sada želimo da se osiguramo da, ukoliko pol kandidata nije izostavljen (NULL),
-- onda mora imati vrednosti ili 'm' ili 'z'. Ovo postižemo naredbom CHECK (<uslov, tj. predikat>).
-- U uslovu možemo referisati na vrednosti kolona tabele. Svi redovi u tabeli onda moraju
-- zadovoljavati zadati uslov.
--
-- Slično kao i za PRIMARY KEY i FOREIGN KEY, ako uslov referiše samo na jednu kolonu,
-- on se može navesti i direktno uz nju, tj. "POL CHAR CHECK (POL IN ('m', 'z'))".

-- Peti (i konačni) deo rešenja (zadavanje naziva uslovima tabele):

DROP TABLE KANDIDATI_ZA_UPIS;

CREATE TABLE KANDIDATI_ZA_UPIS (
    ID INT NOT NULL,
    IDPROGRAMA INT NOT NULL,
    IME VARCHAR(50) NOT NULL,
    PREZIME VARCHAR(50) NOT NULL,
    POL CHAR,
    MESTORODJENJA VARCHAR(50),
    DATUMPRIJAVE DATE,
    BODOVI DECIMAL(5, 2),

    CONSTRAINT PK_ID PRIMARY KEY (ID),
    CONSTRAINT FK_IDPROGRAMA FOREIGN KEY (IDPROGRAMA) REFERENCES DA.STUDIJSKIPROGRAM,
    CONSTRAINT CK_POL CHECK (POL IN ('m', 'z'))
);

-- Objašnjenje:
--
-- Primetite kako smo do sada, da bi napravili izmene nad strukturom / uslovima tabele,
-- uvek brisali prethodnu verziju tabele pre toga. Ovime bi se obrisali i podaci koji
-- se mogu nalaziti u tabeli. U većini slučajeva, želimo da izbegnemo ovako nešto.
--
-- Da bi omogućili kasnije izmene uslova koje smo postavili (npr. brisanje postojećih uslova)
-- bez prethodnog brisanja i rekreiranja tabele, potrebno je dati nazive tim uslovima (da bi
-- nekako mogli da referišemo na njih). Ovo se postiže pomoću CONSTRAINT <naziv uslova> <uslov>.
--
-- Kasnije ćemo videti kako onda možemo koristiti ove nazive u naredbi ALTER.

/*
 * 2. U tabelu kandidati_za_upis uneti novog kandidata Marka Markovića,
 * muškog pola, koji je rođen u Kragujevcu, a prijavio se 12.11.2020.
 * za studjski program Informatika (id 103).
 */

-- Rešenje 1:

INSERT INTO KANDIDATI_ZA_UPIS
VALUES (1, 103, 'Marko', 'Markovic', 'm', 'Kragujevac', '12.11.2020', NULL);

SELECT * FROM KANDIDATI_ZA_UPIS;

-- Objašnjenje:
--
-- U osnovnom obliku, unos novih podataka u tabelu radimo pomoću naredbe
-- INSERT INTO <naziv tabele> VALUES (red 1), (red 2), ...
--
-- Kolone u svakom redu se navode u redosledu u kom su one definisane prilikom
-- kreiranja tabele. Tipovi vrednosti i kolona se moraju poklapati.

-- Rešenje 2:

INSERT INTO KANDIDATI_ZA_UPIS (ID, IDPROGRAMA, IME, PREZIME, POL, MESTORODJENJA, DATUMPRIJAVE)
VALUES (2, 103, 'Marko', 'Markovic', 'm', 'Kragujevac', '12.11.2020');

SELECT * FROM KANDIDATI_ZA_UPIS;

-- Objašnjenje:
--
-- Umesto navođenja vrednosti svih kolona u redosledu njihove definicije prilikom kreiranja
-- tabele, mi možemo postaviti taj redosled navođenjem liste kolona nakon naziva tabele.
-- Ukoliko je u listi neka kolona izostavljena, ona će biti popunjena podrazumevanom vrednošću
-- za tu kolonu (NULL ukoliko nije navedeno drugačije).

-- Rešenje 3:

DROP TABLE KANDIDATI_ZA_UPIS;

CREATE TABLE KANDIDATI_ZA_UPIS (
    ID INT NOT NULL GENERATED ALWAYS AS IDENTITY,
    IDPROGRAMA INT NOT NULL,
    IME VARCHAR(50) NOT NULL,
    PREZIME VARCHAR(50) NOT NULL,
    POL CHAR,
    MESTORODJENJA VARCHAR(50),
    DATUMPRIJAVE DATE,
    BODOVI DECIMAL(5, 2),

    CONSTRAINT PK_ID PRIMARY KEY (ID),
    CONSTRAINT FK_IDPROGRAMA FOREIGN KEY (IDPROGRAMA) REFERENCES DA.STUDIJSKIPROGRAM,
    CONSTRAINT CK_POL CHECK (POL IN ('m', 'z'))
);

INSERT INTO KANDIDATI_ZA_UPIS(IDPROGRAMA, IME, PREZIME, POL, MESTORODJENJA, DATUMPRIJAVE)
VALUES (103, 'Marko', 'Markovic', 'm', 'Kragujevac', '12.11.2020');

SELECT * FROM KANDIDATI_ZA_UPIS;

-- Objašnjenje:
--
-- Do sada smo, prilikom ubacivanja novih redova, mi morali da odredimo jedinstveni
-- identifikator za svaki red. Bilo bi jako korisno kada bi sama baza automatski dodeljivala
-- vrednosti ovim identifikatorima.
--
-- Ovo postižemo dodavanjem "GENERATED ALWAYS AS IDENTITY" uz kolonu ID. Sada više ne moramo
-- (zapravo, i ne možemo!) samostalno da određujemo jedinstvene identifikatore pri unosu novih
-- redova.
--
-- Ako želimo da zadržimo mogućnost samostalnog izbora identifikatora (pri čemu bi se u ostalim
-- slučajevima on svakako automatski generisao), umesto ALWAYS bi naveli BY DEFAULT, ali o tome
-- više reči narednog časa.

/*
 * 3. Iz tabele kandidati_za_upis ukloniti kolonu mestorodjenja.
 */

-- Rešenje:

ALTER TABLE KANDIDATI_ZA_UPIS
DROP COLUMN MESTORODJENJA;

SELECT * FROM KANDIDATI_ZA_UPIS;

-- Objašnjenje:
--
-- Do sada smo, da bi menjali strukturu ili uslove u našoj tabeli, prvo
-- brisali prethodnu tabelu, pa kreirali novu sa izmenjenom strukturom.
-- Međutim, to je dovodilo do brisanja i podataka u tabeli.
--
-- Ako želimo da izbegnemo brisanje tabele, možemo koristiti naredbu
-- ALTER TABLE <naziv tabele>, praćenu listom izmena. Uklanjanje kolone
-- smo izveli pomoću DROP COLUMN <ime kolone>.

/*
 * 4. U tabelu kandidati_za_upis vratiti kolonu mestorodjenja.
 */

-- Rešenje:

ALTER TABLE KANDIDATI_ZA_UPIS
ADD COLUMN MESTORODJENJA VARCHAR(50);

SELECT * FROM KANDIDATI_ZA_UPIS;

-- Objašnjenje:
--
-- Slično kao i pre, menjamo strukturu tabele, pa koristimo naredbu ALTER TABLE.
-- Dodavanje kolone vršimo naredbom ADD COLUMN <naziv kolone> <tip kolone>.

/*
 * 5. Postaviti uslov u tabeli kandidati_za_upis da bodovi za upis mogu biti
 * samo između 0 i 100 i da je podrazumevan datum prijave datum izvršavanja naredbe.
 */

-- Rešenje:

ALTER TABLE KANDIDATI_ZA_UPIS
ADD CONSTRAINT CK_BODOVI CHECK (BODOVI BETWEEN 0.00 AND 100.00)
ALTER COLUMN DATUMPRIJAVE SET DEFAULT CURRENT_DATE;

-- Objašnjenje:
--
-- Isto kao što smo dodali (vratili) kolonu MESTORODJENJA sa ADD COLUMN
-- naredbom, možemo dodati i novi uslov sa naredbom ADD CONSTRAINT!
--
-- Pošto smo uslovu dali ime, njega bi kasnije mogli da izbrišemo pomoću
-- DROP CONSTRAINT <naziv uslova> ukoliko bi to bilo potrebno.
--
-- Izmenu kolona (podrazumevanih vrednosti, NOT NULL ograničenja i slično)
-- možemo izvesti pomoću ALTER COLUMN. U ovom slučaju, sa SET DEFAULT smo
-- postavili podrazumevanu vrednost kolone na CURRENT_DATE - sada, ukoliko
-- se eksplicitno ne navede datum prijave, podrazumevano će biti unet trenutni
-- datum, a ne NULL što je bio slučaj do sada.
--
-- Podrazumevane vrednosti smo mogli da postavljamo i prilikom definicije same
-- tabele tako što bi je naveli uz kolonu: "DATUMPRIJAVE DATE DEFAULT CURRENT_DATE".

/*
 * 6. U tabelu kandidati_za_upis uneti nove kandidate sa podacima:
 * - Snezana Peric, pol ženski, željeni smer Informatika (id 103)
 * - Marija Peric, pol ženski, željeni smer Matematika (id 101)
 */

-- Rešenje:

-- db2 "?" 57007
-- db2 reorg table kandidati_za_upis

INSERT INTO KANDIDATI_ZA_UPIS (IDPROGRAMA, IME, PREZIME, POL)
VALUES (103, 'Snezana', 'Peric', 'z'),
       (101, 'Marija', 'Peric', 'z');

SELECT * FROM KANDIDATI_ZA_UPIS;

-- Objašnjenje:
--
-- Nekada, nakon izmene uslova i strukture neke tabele, dolazi do problema gde
-- ne možemo da ubacujemo nove podatke u tabelu pre "reorganizacije" podataka
-- u njoj (INSERT izbacuje grešku sa kodom 57007).
--
-- U ovoj situaciji, potrebno je izvršiti reorganizaciju pokretanjem naredbe
-- "db2 reorg table <naziv tabele>" iz terminala. Napomena - nekada se dešava
-- da prilikom pokušaja reorganizacije tabele pukne konekcija sa bazom. U tom
-- slučaju, ponovo se konektovati sa "db2 connect to stud2020", pa opet probati
-- sa reorg naredbom.

/*
 * 7. U tabelu kandidati_za_upis uneti kao kandidate studente koji
 * imaju status Ispisan u tabeli dosije. Kao željeni studijski program
 * navesti studijski program koji su studirali kada su se ispisali.
 * Kao broj ostvarenih bodova za upis uneti vrednost 90.
 */

-- Rešenje:

INSERT INTO KANDIDATI_ZA_UPIS (IDPROGRAMA, IME, PREZIME, POL, MESTORODJENJA, BODOVI)
SELECT D.IDPROGRAMA, D.IME, D.PREZIME,
       D.POL, D.MESTORODJENJA, 90
FROM DA.DOSIJE AS D JOIN
     DA.STUDENTSKISTATUS AS SS ON D.IDSTATUSA = SS.ID
WHERE SS.NAZIV = 'Ispisan';

SELECT * FROM KANDIDATI_ZA_UPIS;

-- Objašnjenje:
--
-- Uz INSERT naredbu ne moramo ubacivati samo pojedinačne, unapred poznate redove sa VALUES.
-- Umesto toga, moguće je navesti i upit koji vraća odgovarajuće redove, tj.
-- INSERT INTO <naziv tabele> (<kolone tabele>) <upit>;.
--
-- Naravno, važno je da se tipovi i broj kolona u SELECT-u u okviru upita poklapaju sa onim
-- što je navedeno u listi kolona pri INSERT-u (ili sa svim kolonama tabele ukoliko lista
-- nije navedena).

/*
 * 8. Iz tabele kandidati_za_upis obrisati podatke o kandidatima za
 * koje je nepoznat broj bodova za upis.
 */

-- Rešenje:

DELETE FROM KANDIDATI_ZA_UPIS
WHERE BODOVI IS NULL;

SELECT * FROM KANDIDATI_ZA_UPIS;

-- Objašnjenje:
--
-- Brisanje iz tabele se radi pomoću DELETE FROM <naziv tabele> naredbe.
-- Uslov filtriranja (koji redovi će biti obrisani) se zadaje pod WHERE.
-- Važna napomena: ukoliko se WHERE izostavi, bezuslovno se brišu svi redovi u tabeli!
--
-- Predlog - pre izvršavanja DELETE naredbe, prvo zamenite DELETE sa SELECT da bi proverili
-- koje bi sve redove obrisali. Tek kada ste sigurni da su to ti redovi, onda izvršite
-- DELETE naredbu (naravno, u praksi postoje određeni mehanizmi kojima možemo poništiti
-- izmene destruktivnih akcija - tzv. ROLLBACK mehanizam).

/*
 * 9. Iz tabele kandidati_za_upis obrisati podatke o kandidatima
 * koji se zovu kao neki student koji ima položen ispit.
 */

-- Rešenje:

DELETE FROM KANDIDATI_ZA_UPIS AS KU
WHERE (KU.IME, KU.PREZIME) IN (
    SELECT D.IME, D.PREZIME
    FROM DA.DOSIJE AS D JOIN
         DA.ISPIT AS I ON D.INDEKS = I.INDEKS
    WHERE I.OCENA > 5 AND I.STATUS = 'o'
);

SELECT * FROM KANDIDATI_ZA_UPIS;

-- Važna napomena: kada radimo DELETE FROM <tabela>, ne možemo spajati tabele u FROM-u!

/*
 * 10. Svim kandidatima za upis na fakultet koji su se prijavili u
 * poslednja dva dana i imaju unet broj bodova za upis povećati
 * broj bodova za upis za 20%.
 */

-- Rešenje:

UPDATE KANDIDATI_ZA_UPIS
SET BODOVI = CASE
                 WHEN BODOVI * 1.2 <= 100.0 THEN BODOVI * 1.2 -- ne želimo da pređemo 100 poena
                 WHEN BODOVI IS NOT NULL THEN 100.0
             END
WHERE BODOVI IS NOT NULL AND
      DATUMPRIJAVE >= CURRENT_DATE - 2 DAYS;

-- Objašnjenje:
--
-- Ažuriranje podataka se vrši pomoću UPDATE naredbe. Menjanje vrednosti
-- u nekoj koloni se onda radi sa SET <naziv kolone> = <nova vrednost>.
--
-- Slično kao i sa DELETE, filtriramo redove koje hoćemo da ažuriramo sa WHERE.
-- Ukoliko je WHERE izostavljen, ažuriranje je bezuslovno, tj. ažuriraju se svi
-- redovi.
--
-- Napomena - u ovom primeru koristimo CASE da se ograničimo na maksimalnih 100 poena.
-- U suprotnom bi narušili ograničenje CK_BODOVI koje smo dodali ranije.

/*
 * 11. Ukloniti tabelu kandidati_za_upis.
 */

-- Rešenje:

DROP TABLE KANDIDATI_ZA_UPIS;

/*
 * 12. Promeniti broj indeksa studenta sa indeksom 20171063 u
 * indeks 20172063 u tabeli dosije.
 */

-- Pokušaj rešenja:

UPDATE DA.DOSIJE
SET INDEKS = 20172063
WHERE INDEKS = 20171063;

-- Objašnjenje:
--
-- Pokušaj ažuriranja vraća grešku - narušen je uslov stranog ključa DA.UPISGODINE.FK_UPISGODINE_DOSIJE.
--
-- Šta se ovde desilo? Naime, određene tabele (npr. tabela UPISGODINE) imaju strani ključ prema
-- tabeli DOSIJE (tj. prema njenom primarnom ključu - koloni INDEKS). U ovom slučaju, DB2 ne dozvoljava
-- ažuriranje kolone tog primarnog ključa (to bi podrazumevalo da se moraju ažurirati i sve kolone
-- koje odgovaraju stranim ključevima).
--
-- Ovo bi eventualno mogli da zaobiđemo dodavanjem novog reda i brisanjem starog (uključujući i redove
-- koji imaju strani ključ ka njemu) umesto upotrebe ažuriranja.

/*
 * 13. Na svim ispitima na kojima su u ispitnom roku jun1 2015. godine
 * studenti polagali Analizu 1 promeniti rok u jan1 2015.
 * Za datum polaganja staviti da je nepoznat.
 */

-- Rešenje:

CREATE TABLE ISPIT_P AS (
    SELECT *
    FROM DA.ISPIT
) WITH DATA;

UPDATE ISPIT_P AS I
SET I.OZNAKAROKA = 'jan1',
    I.DATPOLAGANJA = NULL
WHERE I.SKGODINA = 2015 AND I.OZNAKAROKA = 'jun1' AND
      I.IDPREDMETA IN (
          SELECT P.ID
          FROM DA.PREDMET AS P
          WHERE NAZIV = 'Analiza 1'
      );

DROP TABLE ISPIT_P;

-- Objašnjenje:
--
-- Da bi izbegli izmene u pravoj tabeli DA.ISPIT (ovo izbegavamo samo radi lakšeg
-- vežbanja i poređenja rezultata kasnijih zadataka), možemo napraviti njenu kopiju,
-- pa sve izmene praviti na njoj.
--
-- Kreiranje tabele od upita radimo sa naredbom "CREATE TABLE <naziv tabele> AS (<upit>) WITH DATA".
-- Ukoliko nas ne interesuju samo podaci, već želimo da kreiramo (praznu) tabelu koja samo ima istu
-- strukturu kao rezultat navedenog upita, onda možemo navesti "WITH NO DATA" u naredbi.
--
-- Ostatak je jednostavan. Jedina razlika u odnosu na prethodne primere je to
-- što ovde istovremeno ažuriramo više kolona istovremeno - SET zapravo prihvata
-- listu kolona.

/*
 * 14. Predmetima koje su polagali studenti iz Beograda postaviti
 * broj bodova na najveći broj bodova koji postoji u tabeli predmet.
 */

-- Rešenje:

CREATE TABLE PREDMET_P AS (
    SELECT *
    FROM DA.PREDMET
) WITH DATA;

UPDATE PREDMET_P
SET ESPB = (SELECT MAX(ESPB) FROM DA.PREDMET)
WHERE ID IN (
    SELECT I.IDPREDMETA
    FROM DA.ISPIT AS I JOIN
         DA.DOSIJE AS D ON I.INDEKS = D.INDEKS
    WHERE I.STATUS NOT IN ('n', 'p') AND
          D.MESTORODJENJA LIKE 'Beograd%'
);

SELECT * FROM PREDMET_P;

DROP TABLE PREDMET_P;

/*
 * 15. Promeniti sve padove iz predmeta Programiranje 1 na polaganja sa ocenom 6.
 */

-- Rešenje:

CREATE TABLE ISPIT_P AS (
    SELECT *
    FROM DA.ISPIT
) WITH DATA;

UPDATE ISPIT_P
SET OCENA = 6,
    POENI = 51
WHERE STATUS = 'o' AND OCENA = 5 AND
      IDPREDMETA IN (
          SELECT ID
          FROM DA.PREDMET
          WHERE NAZIV = 'Programiranje 1'
      );

DROP TABLE ISPIT_P;
