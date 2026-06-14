/*
 * 1. Napisati korisnički definisanu funkciju koja vraća nisku sa imenima studenata.
 * Kao argument se prosleđuje karakter za pol. Ako pol nije m ili z vratiti nisku
 * 'Pol ne moze biti *prosledjen_argument*'. U rezultatu, imena sortirati opadajuće.
 */

-- Neuspešan pokušaj 1:

-- Za sada ćemo zanemariti kreiranje funkcije. Umesto toga, započećemo sa upitom koji
-- vraća nisku sa imenima svih muških studenata:

SELECT LISTAGG(IME)
FROM DA.DOSIJE
WHERE POL = 'm';

-- Objašnejnje:
--
-- Za ovako nešto možemo koristiti (do sada neviđenu) agregatnu funkciju LISTAGG.
-- Kao što, na primer, agregatna funkcija SUM sumira vrednosti, tako funkcija LISTAGG
-- vrši njihovu konkatenaciju (konkatenaciju niski).
--
-- Međutim, ako probamo sa izvršavanjem prethodnog upita, dobijamo grešku! Ona nas obaveštava
-- da je rezultujuća niska veće dužine od maksimalnih 4000 karaktera. Naime, funkcija
-- LISTAGG podrazumevano vraća vrednost tipa VARCHAR(4000), te rezultat ne sme probiti
-- tu dužinu. Postoje načini za promenu dužine rezultata (pomoću CAST funkcije), ali
-- nećemo ulaziti u te detalje. Koga interesuje, može da pogleda:
-- https://www.ibm.com/docs/en/db2/11.5.x?topic=functions-listagg
--
-- Umesto promene maksimalne dužine rezultata, pokušajmo da rešimo ovaj problem na
-- malo drugačiji način - umesto da spojimo imena SVIH muških studenata, spojićemo
-- samo JEDINSTVENA imena.

-- Pokušaj 2:

SELECT LISTAGG(DISTINCT IME)
FROM DA.DOSIJE
WHERE POL = 'm';

-- Objašnjenje:
--
-- Slično kao kod drugih agregatnih funkcija (COUNT, SUM, ...), i ovde možemo primeniti
-- DISTINCT nad vrednostima koje agregiramo. Upit se sada uspešno izvršava - kao rezultat
-- smo dobili jedan red u kojem su spojena sva (jedinstvena) imena muških studenata.
--
-- Sada bi bilo lepo kada bi imena bila razdvojena nekim separatorom, npr. "Aco, Adam, Adil, ..."
-- umesto "AcoAdamAdil".

-- Pokušaj 3:

SELECT LISTAGG(DISTINCT IME, ', ')
FROM DA.DOSIJE
WHERE POL = 'm';

-- Objašnjenje:
--
-- Funkcija LISTAGG opciono prihvata i drugi argument koji predstavlja separator prilikom
-- konkatenacije.
--
-- Ostalo je još da uredimo imena u opadajućem poretku.

-- Pokušaj 4:

SELECT LISTAGG(DISTINCT IME, ', ') WITHIN GROUP (ORDER BY IME DESC)
FROM DA.DOSIJE
WHERE POL = 'm';

-- Objašnjenje:
--
-- Opciono, funkciju LISTAGG može pratiti WITHIN GROUP u okviru kojeg se može naglasiti
-- uređenje vrednosti u okviru rezultujuće niske. U ovom slučaju, sa ORDER BY IME DESC,
-- naglasili smo da želimo da imena budu sortirana opadajuće.
--
-- Ostalo je još samo da se ovo pretoči u traženu funkciju...

-- Rešenje:

CREATE FUNCTION IMENA_STUDENATA(POL_STUDENATA CHAR) RETURNS VARCHAR(4000)
RETURN
CASE
    WHEN POL_STUDENATA IN ('m', 'z') THEN (
        SELECT LISTAGG(DISTINCT IME, ', ') WITHIN GROUP (ORDER BY IME DESC)
        FROM DA.DOSIJE
        WHERE POL = POL_STUDENATA
    )
    ELSE 'Pol ne moze biti ' || POL_STUDENATA
END;

VALUES (IMENA_STUDENATA('m')),
       (IMENA_STUDENATA('z')),
       (IMENA_STUDENATA('x'));

DROP FUNCTION IMENA_STUDENATA;

-- Objašnjenje:
--
-- Funkcija će vraćati VARCHAR(4000), pošto smo videli da je to gornja granica funkcije
-- LISTAGG (ukoliko ne koristimo CAST). Za obradu nevalidnog argumenta, koristimo CASE
-- izraz (u slučaju nevalidnog ulaza, konkatenaciju vršimo sa operatorom ||).

/*
 * 2. Napisati korisnički definisanu funkciju koja vraća nisku sa indeksima studenata
 * koji imaju prosek jednak vrednosti prosleđenoj kao argument.
 * Ispred niske sa indeksima ispisti koliko ima indeksa, a indekse razdvojiti crticama.
 * Prosek gledati na dve decimale. Izlaz treba da bude, na primer: '2:20170325-20170349'.
 */

-- Rešenje:

CREATE FUNCTION STUDENTI_SA_PROSEKOM(TRAZENI_PROSEK DECIMAL(4, 2)) RETURNS VARCHAR(4000)
RETURN
WITH PROSEK_STUDENATA AS (
    SELECT INDEKS,
           DECIMAL(ROUND(AVG(OCENA * 1.0), 2), 4, 2) AS PROSEK
    FROM DA.ISPIT
    WHERE STATUS = 'o' AND OCENA > 5
    GROUP BY INDEKS
)
SELECT COUNT(*) || ':' || LISTAGG(INDEKS, '-')
FROM PROSEK_STUDENATA
WHERE PROSEK = TRAZENI_PROSEK;

VALUES STUDENTI_SA_PROSEKOM(10.00);

DROP FUNCTION STUDENTI_SA_PROSEKOM;

-- Objašnjenje:
--
-- Proseke studenata možemo "sačuvati" u pomoćnoj tabeli PROSEK_STUDENATA u okviru upita.
-- Nakon toga, samo filtriramo odgovarajuće redove po prosleđenom argumentu. Prebrojavanje
-- indeksa u rezultatu vršimo sa COUNT.
--
-- Napomena: Ako nije pronađen ni jedan student sa traženim prosekom, rezultat funkcije je NULL.

/*
 * 3. Napisati SQL naredbu koja:
 * (a) Pravi tabelu PREDMET_STUDENT koja čuva podatke koliko studenata je položilo koji predmet.
 *     Tabela ima kolone: IDPREDMETA (tipa integer) i BROJ_STUDENATA (tipa smallint).
 * (b) Unosi u tabelu PREDMET_STUDENT podatke o obaveznim predmetima na smeru Informatika na
 *     osnovnim akademskim studijama (može se uzeti da je id 103). Za svaki predmet uneti podatak
 *     da ga je položilo 5 studenata.
 * (c) Ažurira tabelu PREDMET_STUDENT, tako što predmetima o kojima postoji evidencija ažurira
 *     broj studenata koji su ga položili, a za predmete o kojima ne postoji evidencija unosi podatke.
 */

-- Rešenje (a):

CREATE TABLE PREDMET_STUDENT (
    IDPREDMETA INT NOT NULL,
    BROJ_STUDENATA SMALLINT NOT NULL,

    PRIMARY KEY (IDPREDMETA),
    FOREIGN KEY (IDPREDMETA) REFERENCES DA.PREDMET
);

-- Rešenje (b):

INSERT INTO PREDMET_STUDENT
SELECT IDPREDMETA, 5
FROM DA.PREDMETPROGRAMA
WHERE IDPROGRAMA = 103 AND
      VRSTA = 'obavezan';

SELECT * FROM PREDMET_STUDENT;

-- Rešenje (c):

MERGE INTO PREDMET_STUDENT AS PS
USING (
    SELECT P.ID, COUNT(I.IDPREDMETA) AS BROJ_STUDENATA
    FROM DA.PREDMET AS P LEFT JOIN
         DA.ISPIT AS I ON P.ID = I.IDPREDMETA AND
                          I.STATUS = 'o' AND
                          I.OCENA > 5
    GROUP BY P.ID
) AS TMP
ON PS.IDPREDMETA = TMP.ID
WHEN MATCHED THEN
    UPDATE
    SET PS.BROJ_STUDENATA = TMP.BROJ_STUDENATA
WHEN NOT MATCHED THEN
    INSERT
    VALUES (TMP.ID, TMP.BROJ_STUDENATA);

SELECT * FROM PREDMET_STUDENT;

DROP TABLE PREDMET_STUDENT;

-- Objašnjenje:
--
-- Situacija gde imamo neku tabelu u kojoj želimo da ažuriramo postojeće redove, a
-- nedostajuće da ubacimo, javlja se dosta često u praksi. Kolokvijalno, ova operacija
-- se zove i "upsert" (update/insert) operacija.
--
-- Jedan od načina na koji se ovo može izvesti je izvršavanjem dve odvojene UPDATE i INSERT
-- naredbe. Međutim, isto je moguće uraditi lakše i istovremeno pomoću tzv. MERGE INTO
-- (tj. upsert) naredbe.
--
-- Osnovna struktura naredbe je sledeća:
-- MERGE INTO <tabela u kojoj hoćemo da ubacimo/izmenimo redove> AS <alias tabele - PS>
-- USING (<definicija pomoćne tabele>) AS <alias pomoćne tabele - TMP>
-- ON <uslov spajanja tabele PS i TMP>
-- WHEN MATCHED THEN <naredba koja se izvršava ako je spajanje uspešno>
-- WHEN NOT MATCHED THEN <naredba koja se izvršava ako spajanje nije uspešno>;
--
-- Tabela koju menjamo u ovom zadatku je tabela PREDMET_STUDENT. Sada je potrebno
-- razmisliti o tome šta treba da bude definicija naše pomoćne tabele (u USING delu
-- naredbe). Mi želimo sledeće - ako predmet već postoji u tabeli PREDMET_STUDENT,
-- onda želimo da se taj red ažurira, a u suprotnom, predmet (i odgovarajući broj
-- položenih ispita) treba da se ubaci u tabelu. Prema ovome, pomoćna tabela bi trebalo
-- da sadrži podatke o SVIM predmetima na fakultetu.
--
-- Sada, ukoliko je spajanje uspešno (što bi značilo da u PREDMET_STUDENT već imamo
-- taj predmet), iskoristićemo broj položenih ispita iz TMP za ažuriranje, a ako je
-- neuspešno (nema odgovarajućeg predmeta u tabeli PREDMET_STUDENT), onda ćemo samo
-- umetnuti novi red na osnovu podataka iz nje.
--
-- Naredbe koje navodimo WHEN MATCHED / WHEN NOT MATCHED blokovima mogu biti
-- INSERT, UPDATE ili DELETE naredbe. One se implicitno odnose na tabelu koju
-- menjamo (u našem slučaju, PREDMET_STUDENT), te nije potrebno pisati
-- UPDATE PREDMET_STUDENT ili INSERT INTO PREDMET_STUDENT.

/*
 * 4. Napisati SQL naredbu koja:
 * (a) Pravi tabelu STUDENT_PODACI sa kolonama:
 *     INDEKS (tipa integer), BROJ_PREDMETA (tipa smallint), PROSEK (tipa float) i DATUPISA (tipa date);
 * (b) U tabelu STUDENT_PODACI unosi indeks, broj položenih predmeta i prosek za studente koji imaju prosek
 *     iznad 8 i nisu diplomirali; za studente koji su diplomirali kao broj predmeta uneti vrednost 10,
 *     a kao prosek vrednost 10;
 * (c) Ažurira tabelu STUDENT_PODACI tako što:
 *      - studentima o kojima u tabeli postoje podaci i koji su diplomirali ažurira datum upisa na fakultet
 *      - studentima o kojima u tabeli postoje podaci i koji su trenutno na budžetu ažurira broj položenih predmeta i prosek;
 *      - studentima o kojima u tabeli postoje podaci i koji su ispisani briše iz tabele;
 *      - unosi podatke o studentima koji nisu ispisani i o njima ne postoje podaci u tabeli (uneti indeks, broj položenih predmeta i prosek);
 * (d) Uklanja tabelu STUDENT_PODACI.
 */

-- Rešenje (a):

CREATE TABLE STUDENT_PODACI (
    INDEKS INT NOT NULL,
    BROJ_PREDMETA SMALLINT,
    PROSEK FLOAT,
    DATUPISA DATE,

    PRIMARY KEY (INDEKS),
    FOREIGN KEY (INDEKS) REFERENCES DA.DOSIJE
);

-- Rešenje (b):

INSERT INTO STUDENT_PODACI (INDEKS, BROJ_PREDMETA, PROSEK)
SELECT D.INDEKS,
       COUNT(*) AS BROJ_POLOZENIH,
       AVG(I.OCENA * 1.0) AS PROSEK
FROM DA.DOSIJE AS D JOIN
     DA.STUDENTSKISTATUS AS SS ON D.IDSTATUSA = SS.ID JOIN
     DA.ISPIT AS I ON D.INDEKS = I.INDEKS
WHERE SS.NAZIV <> 'Diplomirao' AND
      I.STATUS = 'o' AND I.OCENA > 5
GROUP BY D.INDEKS
HAVING AVG(I.OCENA * 1.0) > 8.0
-- Ovo su bili studenti koji nisu diplomirali i imaju prosek preko 8.0...
UNION
-- A sada i diplomci...
SELECT D.INDEKS, 10, 10.0
FROM DA.DOSIJE AS D JOIN
     DA.STUDENTSKISTATUS AS SS ON D.IDSTATUSA = SS.ID
WHERE SS.NAZIV = 'Diplomirao';

SELECT * FROM STUDENT_PODACI;

-- Rešenje (c):

MERGE INTO STUDENT_PODACI AS SP
USING (
    SELECT D.INDEKS,
           D.DATUPISA,
           SS.NAZIV AS STATUS,
           COUNT(I.INDEKS) AS BROJ_POLOZENIH,
           AVG(I.OCENA * 1.0) AS PROSEK
    FROM DA.DOSIJE AS D JOIN
         DA.STUDENTSKISTATUS AS SS ON D.IDSTATUSA = SS.ID LEFT JOIN
         DA.ISPIT AS I ON D.INDEKS = I.INDEKS AND
                          I.STATUS = 'o' AND
                          I.OCENA > 5
    GROUP BY D.INDEKS, D.DATUPISA, SS.NAZIV
) AS TMP
ON SP.INDEKS = TMP.INDEKS
WHEN MATCHED AND TMP.STATUS = 'Diplomirao' THEN
    UPDATE
    SET SP.DATUPISA = TMP.DATUPISA
WHEN MATCHED AND TMP.STATUS = 'Budzet' THEN
    UPDATE
    SET SP.BROJ_PREDMETA = TMP.BROJ_POLOZENIH,
        SP.PROSEK = TMP.PROSEK
WHEN MATCHED AND LOWER(TMP.STATUS) LIKE '%ispis%' THEN
    DELETE
WHEN NOT MATCHED AND LOWER(TMP.STATUS) NOT LIKE '%ispis%' THEN
    -- Nećemo da popunimo i DATUPISA - možemo eksplicitno navesti kolone u koje
    -- ubacujemo vrednosti, isto kao i sa standardnom INSERT naredbom (samo što,
    -- kao i do sada, ovde ne navodimo naziv tabele jer se podrazumeva da je to
    -- tabela STUDENT_PODACI).
    INSERT (INDEKS, BROJ_PREDMETA, PROSEK)
    VALUES (TMP.INDEKS, TMP.BROJ_POLOZENIH, TMP.PROSEK)
ELSE IGNORE;

-- Objašnjenje:
--
-- U tabeli STUDENT_PODACI imamo neke studente, a neke nemamo. One koje nemamo, želimo
-- da ubacimo u tabelu, pa pomoćna tabela mora da sadrži podatke o svim studentima
-- (iz tog razloga radimo LEFT JOIN nad ispitima - želimo da zadržimo i one studente
-- koji nisu položili ništa).
--
-- Za razliko od prethodnog zadatka (zadatka 3), ovde imamo i dodatne uslove u zavisnosti
-- od kojih želimo da izvršimo nešto drugačiju akciju. Srećom, u MERGE into zapravo možemo
-- navoditi proizvoljan broj WHEN MATCHED / WHEN NOT MATCHED blokova, pri čemu dodatne uslove
-- navodimo sa AND (npr. WHEN MATCHED AND <dodatni uslov>). Možemo navesti ELSE IGNORE na kraju
-- ako želimo da eksplicitno naglasimo da se ništa ne dešava ako nijedan uslov nije ispunjen.
--
-- Napomena: Više različitih statusa odgovara tome da je student ispisan. Smatraćemo da se
-- student ispisao ukoliko naziv njemu odgovarajućeg statusa studiranja sadrži "ispis" u sebi.

SELECT * FROM STUDENT_PODACI;

-- Rešenje (d):

DROP TABLE STUDENT_PODACI;

/*
 * 5. Napraviti okidač koji sprečava brisanje studenata koji su diplomirali.
 * U tabelu uneti studenta koji je diplomirao i proveriti da li okidač radi.
 * Na kraju obrisati okidač.
 */

-- Ukratko o okidačima:
--
-- Prilikom izmena podataka u tabelama (usled INSERT/UPDATE i DELETE naredbi), dosta često
-- se stvara potreba za izvršavanjem nekih dodatnih akcija uz te izmene. Primera radi, možda
-- želimo da validiramo da je student položio sve obavezne predmete pre nego što se njegov
-- status promeni na "Diplomirao" kroz UPDATE naredbu, ili, kada bi razmatrali neku veb prodavnicu
-- i prateću bazu narudžbina, čak i da pošaljemo mejl naručiocu proizvoda da je narudžbina uspešno
-- napravljena prilikom umetanja svakog novog reda u odgovarajuću tabelu.
--
-- Ovo se sve može rešiti pomoću koncepta okidača (eng. trigger). Okidači predstavljaju upravo
-- neke dodatne akcije koje možemo vezati za izvršavanje operacija nad određenom tabelom.
--
-- Njihovo kreiranje se vrši sa CREATE TRIGGER naredbom čija je osnovna struktura sledeća:
--
-- CREATE TRIGGER <naziv okidača>
-- <BEFORE ili AFTER> <INSERT, UPDATE ili DELETE> on <ime tabele za koju se okidač vezuje>
-- REFERENCING OLD AS <alias> NEW AS <alias> (ovo je opciono)
-- FOR EACH <ROW ili STATEMENT>
-- WHEN (<uslov za kada izvršiti akciju okidača>) (ovo je opciono)
-- BEGIN <opciono ATOMIC>
--     <akcija koju treba izvršiti>
-- END;
--
-- Okidače možemo vezati za izvršavanje INSERT, UPDATE ili DELETE naredbe nad nekom tabelom
-- (videćemo kasnije da je moguće vezati ih i za više naredbi istovremeno). Uz to, potrebno
-- je navesti i da li se akcija izvršava pre (BEFORE) ili nakon (AFTER) što je naredba za koju
-- je okidač vezan kompletirana. U zavisnosti od ovoga, akcija u okidaču će imati određena
-- ograničenja koja ćemo videti uskoro, ali intuitivno - ako želimo da uradimo neku validaciju
-- u okidaču, i sprečimo izvršavanje neke naredbe ako validacija nije uspešna, logično je da
-- se da validacija izvrši pre kompletiranja naredbe koju validiramo (u suprotnom, prekasno je
-- za bilo kakvo obustavljanje naredbe). Slično, ako želimo da ažuriramo neke dodatne tabele
-- po izvršavanju INSERT, DELETE ili UPDATE naredbi nad ciljnom tabelom, logično je da se do
-- desi tek pošto je naredba zapravo izvršena.
--
-- U zavisnosti od toga da li želimo da se akcija okidača izvrši za svaki red pogođen naredbom
-- (npr. DELETE naredba može brisati više redova od jednog), ili samo jednom za svaku naredbu,
-- koristićemo, redom, FOR EACH ROW ili FOR EACH STATEMENT. U našim primerima, uglavnom će imati
-- smisla koristiti FOR EACH ROW, tj. izvršavati akciju okidača za svaki red pojedinačno.
--
-- Akciju implementiramo u BEGIN - END bloku. Ako želimo da se ona izvrši atomički (ili u celosti,
-- ili ne uopšte), možemo blok označiti sa ATOMIC.
--
-- Opciono, u slučaju FOR EACH ROW okidača, možemo referisati na redove koje brišemo / ubacujemo / ažuriramo
-- tako što uvedemo referencu na njih kroz REFERENCING deo naredbe. Na primer, ako u definiciji DELETE
-- okidača navedemo REFERENCING OLD AS O, onda možemo proveriti vrednosti kolona reda koji pokušavamo
-- da obrišemo kroz novu promenljivu O. Slično, za INSERT okidače možemo koristiti REFERENCING NEW AS N
-- da bi imali uvid u red koji pokušavamo da dodamo. U slučaju UPDATE okidača, možemo imati i referencu
-- na OLD (stanje reda pre izvršavanja UPDATE naredbe) i na NEW (stanje reda nakon izvršavanja UPDATE naredbe).
--
-- Opciono možemo navesti i uslov za kada treba izvršiti akciju okidača. Ovaj uslov se navodi u WHEN
-- i videćemo ga već u ovom primeru.

-- Rešenje:

CREATE TRIGGER SPRECI_BRISANJE_DIPLOMACA
BEFORE DELETE ON DA.DOSIJE -- želimo da se akcija izvršava PRE brisanja da bi to brisanje mogli i da sprečimo!
REFERENCING OLD AS O -- Moramo da proverimo da li je student kojeg pokušavamo da obrišemo diplomirao, te uvodimo referencu koja odgovara redu koji se briše
FOR EACH ROW -- Želimo da proverimo svaki red koji je ciljan sa DELETE zasebno
WHEN (O.IDSTATUSA IN (SELECT ID FROM DA.STUDENTSKISTATUS WHERE NAZIV = 'Diplomirao')) -- Izvršavamo akciju okidača samo za studente koji su diplomirali!
BEGIN ATOMIC
    -- Ispaljivanje greške možemo izvršiti sa SIGNAL naredbom!
    SIGNAL SQLSTATE '75000' ('Brisanje diplomiranih studenata nije dozvoljeno!');
END;

INSERT INTO DA.DOSIJE (INDEKS, IDPROGRAMA, IME, PREZIME, IDSTATUSA, DATUPISA, DATDIPLOMIRANJA)
VALUES (20250001, 103, 'Pera', 'Peric', -2, CURRENT_DATE  - 1 YEAR, CURRENT_DATE);

-- Nije uspešno! Dobili smo grešku "Brisanje diplomiranih studenata nije dozvoljeno!".
DELETE FROM DA.DOSIJE
WHERE INDEKS = 20250001;

DROP TRIGGER SPRECI_BRISANJE_DIPLOMACA;

-- Sada kada više nema okidača, brisanje je uspešno.
DELETE FROM DA.DOSIJE
WHERE INDEKS = 20250001;

-- Objašnjenje:
--
-- Kao što je već pomenuto, želimo da sprečimo brisanje diplomaca, te se validacija mora izvršiti PRE samog
-- brisanja, pa zato pravimo BEFORE DELETE okidač. Nakon što smo uveli referencu na OLD red, možemo, na primer,
-- proveriti koja je vrednost O.IDSTATUSA, tj. da proverimo status studenta kojeg upravo pokušavamo da obrišemo.
--
-- Nakon kreiranja okidača, ako probamo sa brisanjem Pere Perića (koji je diplomirao), dobijamo grešku i on
-- ostaje netaknut u tabeli. Nakon uklanjanja okidača, brisanje je uspešno pri novom pokušaju.

/*
 * 6. Napraviti okidač koji dozvoljava ažuriranje broja espb bodova predmetima samo za jedan bod.
 * Ako je nova vrednost espb bodova veća od postojeće, broj bodova se povećava za 1, a ako je manja smajuje se za 1.
 */

-- Rešenje:

CREATE TRIGGER OGRANICI_MODIFIKACIJU_ESPB
BEFORE UPDATE ON DA.PREDMET
REFERENCING NEW AS N OLD AS O -- UPDATE okidači mogu referisati i na NEW i na OLD
FOR EACH ROW
BEGIN ATOMIC
    SET N.ESPB = CASE -- Modifikujemo operaciju ažuriranja kroz SET N.ESPB
        WHEN N.ESPB > O.ESPB THEN O.ESPB + 1
        WHEN N.ESPB < O.ESPB THEN O.ESPB - 1
        ELSE O.ESPB
    END;
END;

INSERT INTO DA.PREDMET
VALUES (1, 'T100', 'TEST', 5);

-- Trenutno nosi 5 ESPB
SELECT * FROM DA.PREDMET
WHERE ID = 1;

UPDATE DA.PREDMET
SET ESPB = 17
WHERE ID = 1;

-- Sada nosi 6 ESPB, iako smo u prethodnoj naredbi tražili da se ESPB ažurira na 17
SELECT * FROM DA.PREDMET
WHERE ID = 1;

UPDATE DA.PREDMET
SET ESPB = 2
WHERE ID = 1;

-- Sada ponovo nosi 5 ESPB, iako smo u prethodnoj naredbi tražili da se ESPB ažurira na 2
SELECT * FROM DA.PREDMET
WHERE ID = 1;

DELETE FROM DA.PREDMET
WHERE ID = 1;

DROP TRIGGER OGRANICI_MODIFIKACIJU_ESPB;

-- Objašnjenje:
--
-- I ovde želimo da uradimo nekakav vid validacije izmena, mada sada, umesto izbacivanja greške,
-- želimo da validiramo izmene tako što ćemo ih "ograničiti" njihovom modifikacijom.
--
-- U BEFORE INSERT ili BEFORE UPDATE okidačima, možemo izmeniti vrednosti u redu koji ubacujemo,
-- tj. menjamo, kroz SET N.kolona = <neka vrednost> (pri čemu je N referenca na NEW) i time
-- modifikujemo originalnu naredbu umetanja / ažuriranja. Ovo je moguće uraditi samo i isključivo
-- u BEFORE okidačima!!!

/*
 * 7.
 * (a) Napraviti tabelu broj_predmeta koja ima jednu kolonu broj tipa smallint i
 *     u nju uneti jedan red koji predstavlja broj predmeta u tabeli predmet.
 * (b) Napraviti okidač koji ažurira tabelu broj_predmeta tako što povećava vrednosti
 *     u koloni broj za 1 kada se unese novi predmet u tabelu predmet.
 * (c) Napisati okidač koji ažurira tabelu broj_predmeta tako što smanjuje vrednost
 *     u koloni broj za 1 kada se obriše predmet iz tabele predmet.
 * (d) Uneti podatke o novom predmetu čiji je id 2002, oznaka predm1, naziv Predmet 1 i ima 15 espb.
 */

-- Rešenje (a):

CREATE TABLE BROJ_PREDMETA AS (
    -- COUNT vraća tip INT, a u zadatku se traži da tip kolone bude SMALLINT.
    -- Ovo možemo rešiti pomoću CAST funkcije - CAST(<vrednost> AS <novi tip>).
    -- Alternativno, mogli smo da napravimo tabelu i popunimo je u odvojenim naredbama.
    SELECT CAST(COUNT(*) AS SMALLINT) AS BROJ
    FROM DA.PREDMET
) WITH DATA;

SELECT * FROM BROJ_PREDMETA;

-- Rešenje (b):

CREATE TRIGGER DODAVANJE_PREDMETA
AFTER INSERT ON DA.PREDMET
FOR EACH ROW
BEGIN ATOMIC
    UPDATE BROJ_PREDMETA
    SET BROJ = BROJ + 1;
END;

-- Rešenje (c):

CREATE TRIGGER BRISANJE_PREDMETA
AFTER DELETE ON DA.PREDMET
FOR EACH ROW
BEGIN ATOMIC
    UPDATE BROJ_PREDMETA
    SET BROJ = BROJ - 1;
END;

-- Rešenje (d):

INSERT INTO DA.PREDMET
VALUES (2002, 'predm1', 'Predmet 1', 15);

SELECT * FROM BROJ_PREDMETA;

DELETE FROM DA.PREDMET
WHERE ID = 2002;

SELECT * FROM BROJ_PREDMETA;

DROP TRIGGER DODAVANJE_PREDMETA;

DROP TRIGGER BRISANJE_PREDMETA;

DROP TABLE BROJ_PREDMETA;

-- Objašnjenje:
--
-- Tabela BROJ_PREDMETA treba da ostane ažurna prilikom izmena nad tabelom DA.PREDMET,
-- te je potrebno napraviti dva okidača - jedan za slučaj da brišemo predmete i jedan
-- za slučaj kada dodajemo nove predmete. Primetimo da u ovim okidačima referišemo na
-- neku drugu tabelu i koristimo UPDATE naredbu. Ovako nešto je moguće samo i isključivo
-- u AFTER okidačima! Upotreba INSERT, UPDATE i DELETE naredbi u telu okidača zahteva
-- da taj okidač bude AFTER okidač.

-- Alternativno rešenje za (b) i (c):

CREATE TRIGGER IZMENA_NAD_PREDMETIMA
AFTER INSERT OR DELETE ON DA.PREDMET
FOR EACH ROW
BEGIN
    IF INSERTING THEN -- Ako je u pitanju INSERT...
        UPDATE BROJ_PREDMETA
        SET BROJ = BROJ + 1;
    ELSEIF DELETING THEN -- Ako je u pitanju DELETE...
        UPDATE BROJ_PREDMETA
        SET BROJ = BROJ - 1;
    END IF;
END;

DROP TRIGGER IZMENA_NAD_PREDMETIMA;

-- Objašnjenje:
--
-- Umesto da pravimo odvojene okidače za slučaj dodavanja i slučaj brisanja predmeta,
-- možemo napraviti i jedan, kombinovani okidač u okviru kojeg onda proveravamo koja
-- operacija je zapravo izvršena. Proveru operacije možemo izvršiti pomoću IF-THEN-ELSE
-- konstrukta.
--
-- Jedna napomena - ovako imamo ograničenje da osnovni blok okidača ne može biti ATOMIC!

/*
 * 8.
 * (a) Napraviti tabelu STUDENT_POLOZENO koja za svakog studenta koji je položio barem jedan predmet sadrži
 *     podatak koliko je espb bodova položio. Tabela ima kolone INDEKS i ESPB.
 * (b) Napraviti tabelu PREDMET_POLOZENO koja za svaki predmet koji je položio barem jedan student sadrži
 *     podatak koliko je studenata položilo taj predmet. Tabela ima kolone IDPREDMETA i BROJ_STUDENATA.
 * (c) Uneti podatke u tabelu STUDENT_POLOZENO za studente koji su položili sve obavezne predmete na smeru koji studiraju.
 * (d) Napisati naredbu koja menja tabelu STUDENT_POLOZENO tako što ažurira broj položenih espb bodova
 *     za studente o kojima sadrži podatke, a unosi informaicje za studente o kojima ne postoje podaci
 *     u tabeli STUDENT_POLOZENO.
 * (e) Uneti podatke u tabelu PREDMET_POLOZENO.
 * (f) Napraviti okidač koji nakon unosa položenog ispita ažurira tabele STUDENT_POLOZENO i
 *     PREDMET_POLOZENO tako da sadrže podatak o novom ispitu.
 * (g) Uneti podatak da je student sa indeksom 20150320 polagao predmet sa id 2010 u ispitnom roku
 *     jun2 2017/2018. šk. godine. Student je ispit položio sa 95 poena i dobio ocenu 10.
 * (h) Uneti podatak da je student sa indeksom 20152003 polagao predmet sa id 1695 u ispitnom roku
 *     jun1 2017/2018. šk. godine. Student je ispit položio sa 95 poena i dobio je ocenu 10.
 */

-- Rešenje (a):

CREATE TABLE STUDENT_POLOZENO (
    INDEKS INT NOT NULL,
    ESPB SMALLINT NOT NULL,

    PRIMARY KEY (INDEKS),
    FOREIGN KEY (INDEKS) REFERENCES DA.DOSIJE
);

-- Rešenje (b):

CREATE TABLE PREDMET_POLOZENO (
    IDPREDMETA INT NOT NULL,
    BROJ_STUDENATA INT NOT NULL,

    PRIMARY KEY (IDPREDMETA),
    FOREIGN KEY (IDPREDMETA) REFERENCES DA.PREDMET
);

-- Rešenje (c):

INSERT INTO STUDENT_POLOZENO
SELECT D.INDEKS, SUM(P.ESPB) AS ESPB
FROM DA.DOSIJE AS D JOIN
     DA.ISPIT AS I ON D.INDEKS = I.INDEKS JOIN
     DA.PREDMET AS P ON I.IDPREDMETA = P.ID
WHERE I.STATUS = 'o' AND I.OCENA > 5 AND
      NOT EXISTS ( -- položio je sve svoje obavezne predmete (ne postoji obavezan predmet koji nije položio)
          SELECT *
          FROM DA.PREDMETPROGRAMA AS PP
          WHERE PP.IDPROGRAMA = D.IDPROGRAMA AND
                PP.VRSTA = 'obavezan' AND
                NOT EXISTS (
                    SELECT *
                    FROM DA.ISPIT AS IP
                    WHERE IP.INDEKS = D.INDEKS AND
                    IP.IDPREDMETA = PP.IDPREDMETA AND
                    IP.STATUS = 'o' AND IP.OCENA > 5
                )
      )
GROUP BY D.INDEKS;

-- Rešenje (d):

MERGE INTO STUDENT_POLOZENO AS SP
USING (
    SELECT I.INDEKS, SUM(P.ESPB) AS ESPB
    FROM DA.ISPIT AS I JOIN
         DA.PREDMET AS P ON I.IDPREDMETA = P.ID
    WHERE I.STATUS = 'o' AND I.OCENA > 5
    GROUP BY I.INDEKS
) AS TMP
ON SP.INDEKS = TMP.INDEKS
WHEN MATCHED THEN
    UPDATE
    SET SP.ESPB = TMP.ESPB
WHEN NOT MATCHED THEN
    INSERT
    VALUES (TMP.INDEKS, TMP.ESPB);

-- Rešenje (e):

INSERT INTO PREDMET_POLOZENO
SELECT IDPREDMETA, COUNT(*) AS BROJ_POLOZENIH
FROM DA.ISPIT
WHERE STATUS = 'o' AND OCENA > 5
GROUP BY IDPREDMETA;

SELECT * FROM PREDMET_POLOZENO;

-- Rešenje (f):

CREATE TRIGGER AZURIRAJ_SUMARNE_TABELE_PRI_NOVOM_ISPITU
AFTER INSERT ON DA.ISPIT
REFERENCING NEW AS N
FOR EACH ROW
WHEN (N.STATUS = 'o' AND N.OCENA > 5) -- Tabele treba ažurirati samo ako je ispit položen
BEGIN ATOMIC
    -- Ovo je moglo biti rešeno i preko MERGE INTO, ali je u ovom slučaju
    -- dosta jednostavnije to uraditi samo preko IF-THEN-ELSE.

    -- Ako već imamo studenta u tabelu STUDENT_POLOZENO...
    IF N.INDEKS IN (SELECT INDEKS FROM STUDENT_POLOZENO) THEN
        -- onda je potrebno ažurirati njegove bodove...
        UPDATE STUDENT_POLOZENO
        SET ESPB = ESPB + (SELECT P.ESPB FROM DA.PREDMET AS P WHERE P.ID = N.IDPREDMETA)
        WHERE INDEKS = N.INDEKS;
    -- a u suprotnom...
    ELSE
        -- samo ubacujemo novi red.
        INSERT INTO STUDENT_POLOZENO
        VALUES (N.INDEKS, (SELECT P.ESPB FROM DA.PREDMET AS P WHERE P.ID = N.IDPREDMETA));
    END IF;

    -- Slično važi i za tabelu PREDMET_POLOZENO.
    IF N.IDPREDMETA IN (SELECT IDPREDMETA FROM PREDMET_POLOZENO) THEN
        UPDATE PREDMET_POLOZENO
        SET BROJ_STUDENATA = BROJ_STUDENATA + 1
        WHERE IDPREDMETA = N.IDPREDMETA;
    ELSE
        INSERT INTO PREDMET_POLOZENO
        VALUES (N.IDPREDMETA, 1);
    END IF;
END;

SELECT *
FROM STUDENT_POLOZENO
WHERE INDEKS = 20150320;

SELECT *
FROM PREDMET_POLOZENO
WHERE IDPREDMETA = 2010;

-- Rešenje (g):

INSERT INTO DA.ISPIT
VALUES (2017, 'jun2', 20150320, 2010, 'o', NULL, 95, 10);

SELECT *
FROM STUDENT_POLOZENO
WHERE INDEKS = 20152003;

SELECT *
FROM PREDMET_POLOZENO
WHERE IDPREDMETA = 1695;

-- Rešenje (h):

INSERT INTO DA.ISPIT
VALUES (2017, 'jun1', 20152003, 1695, 'o', NULL, 95, 10);

DELETE FROM DA.ISPIT
WHERE (SKGODINA, OZNAKAROKA, INDEKS, IDPREDMETA) IN (
    VALUES (2017, 'jun2', 20150320, 2010),
           (2017, 'jun1', 20152003, 1695)
);

DROP TRIGGER AZURIRAJ_SUMARNE_TABELE_PRI_NOVOM_ISPITU;

DROP TABLE STUDENT_POLOZENO;

DROP TABLE PREDMET_POLOZENO;
