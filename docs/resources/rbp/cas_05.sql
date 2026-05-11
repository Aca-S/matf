/*
 * 1. Izdvojiti ukupan broj studenata.
 */

-- Rešenje:

SELECT COUNT(*)
FROM DA.DOSIJE;

-- Objašnjenje:
--
-- Do sada su upiti koje smo pisali uvek imali nekakav skup redova kao njihov rezultat.
-- Međutim, šta ako želimo da prebrojimo koliko redova se nalazi u rezultatu nekog upita?
-- Za tako nešto nam je potrebna nekakva funkcija koja bi, kao argument, primila skup redova,
-- a kao rezultat vratila jednu vrednost - u ovom slučaju, kardinalnost tog ulaznog skupa.
--
-- Funkcije koje kao argument prihvataju skup redova, a kao rezultat vraćaju jednu,
-- sumarnu, vrednost, nazivaju se AGREGATNE FUNKCIJE.
--
-- Osnovni primer agregatne funkcije je funkcija COUNT, koja, ako joj kao argument prosledimo
-- specijalnu vrednost * (zvezdica predstavlja sve redove i sve kolone, kao i u osnovnoj upotrebi
-- u SELECT-u), tj. COUNT(*), vraća broj redova u rezultatu odgovarajućeg upita.

/*
 * 2. Izdvojiti broj studenata koji su diplomirali.
 */

-- Rešenje 1 (gore rešenje!):

SELECT COUNT(*)
FROM (
    SELECT *
    FROM DA.DOSIJE
    WHERE DATDIPLOMIRANJA IS NOT NULL
);

-- Objašnjenje:
--
-- Studenti kojima je DATDIPLOMIRANJA poznat (tj. nije NULL vrednost) su diplomirali.
-- Podupit (u FROM-u) nam vraća baš takve studente, nakon čega dobijamo broj svih redova
-- rezultata pomoću agregatne funkcije COUNT. Međutim, moguće je dobiti bolje rešenje
-- na nešto drugačiji način.

-- Rešenje 2 (bolje rešenje!):

SELECT COUNT(DATDIPLOMIRANJA)
FROM DA.DOSIJE;

-- Objašnjenje:
--
-- Do sada smo videli samo slučaj gde COUNT pozivamo sa argumentom *, u kom slučaju
-- je značenje ove agregatne funkcije "prebroj sve redove rezultata, kakvi god oni bili".
-- Međutim, funkcija COUNT zapravo može prihvatiti i skup vrednosti (ne nužno celih redova!)
-- kao argument, u kom slučaju ona vraća broj onih vrednosti iz tog skupa koje nisu NULL.
--
-- Zamislimo da imamo naredne redove iz tabele DOSIJE:
--
-- INDEKS   | IME  | PREZIME | DATDIPLOMIRANJA | ...
-- 20170001 | Pera | Perić   | 2021-09-09      | ...
-- 20170002 | Mika | Mikić   | NULL            | ...
-- 20170003 | Žika | Žikić   | 2022-10-04      | ...
--
-- Poziv COUNT(*) bi se "razvio" u:
-- COUNT (
--     (20170001, Pera, Perić, 2021-09-09, ...),
--     (20170002, Mika, Mikić, NULL, ...),
--     (20170003, Žika, Žikić, 2022-10-04, ...),
-- ) = 3
--
-- Poziv COUNT(DATDIPLOMIRANJA) bi se "razvio" u:
-- COUNT (
--     2021-09-09,
--     NULL,
--     2022-10-04
-- ) = 2

/*
 * 3. Izdvojiti ukupan broj studenata koji bar iz jednog predmeta imaju ocenu 10.
 */

-- Prvi pokušaj (pogrešan):

SELECT COUNT(*)
FROM DA.ISPIT
WHERE OCENA = 10 AND STATUS = 'o';

-- Objašnjenje:
--
-- Sa ovakvim upitom dohvatamo sve ispite koji su položeni sa desetkom. Ukoliko
-- je jedan student položio tri ispita sa ocenom 10, on će se računati tri puta
-- prilikom prebrojavanja, a mi bismo hteli da se računa samo jednom. Potrebno
-- je da nekako izbacimo duplikate.

-- Rešenje 1:

SELECT COUNT(*)
FROM (
    SELECT DISTINCT INDEKS
    FROM DA.ISPIT
    WHERE OCENA = 10 AND STATUS = 'o'
);

-- Objašnjenje:
--
-- Slično kao u prethodnom primeru, problem smo nekako rešili pravljenjem podupita
-- u kojem uklanjamo duplikate. Međutim, verovatno postoji bolji način.

-- Rešenje 2:

SELECT COUNT(*)
FROM DA.DOSIJE
WHERE INDEKS IN (
    SELECT INDEKS
    FROM DA.ISPIT
    WHERE OCENA = 10 AND STATUS = 'o'
);

-- Objašnjenje:
--
-- Slično kao i pre, samo što smo podupit pomerili iz FROM u WHERE...
-- Da li je moguće rešiti ovo bez podupita?

-- Rešenje 3:

SELECT COUNT(DISTINCT INDEKS)
FROM DA.ISPIT
WHERE OCENA = 10 AND STATUS = 'o';

-- Objašnjenje:
--
-- Funkcija COUNT dopušta upotrebu modifikatora DISTINCT kojim se, pre prebrojavanja,
-- uklanjaju duplikati iz skupa prosleđenih vrednosti!
--
-- Zamislimo naredne redove u tabeli ISPIT:
--
-- INDEKS   | IDPREDMETA | OCENA | ...
-- 20170001 | 123        | 10    | ...
-- 20170001 | 456        | 10    | ...
-- 20170001 | 789        | 10    | ...
-- 20190042 | 123        | 10    | ...
--
-- Poziv COUNT(*) se razvija u:
-- COUNT (
--     (20170001, 123, 10, ...),
--     (20170001, 456, 10, ...),
--     (20170001, 789, 10, ...),
--     (20190042, 123, 10, ...)
-- ) = 4
--
-- Poziv COUNT(INDEKS) se razvija u:
-- COUNT (
--     20170001,
--     20170001,
--     20170001,
--     20190042
-- ) = 4
--
-- Poziv COUNT(DISTINCT INDEKS) se razvija u:
-- COUNT (
--     20170001,
--     20190042
-- ) = 2

/*
 * 4. Izdvojiti ukupan broj položenih predmeta i položenih espb bodova
 * za studenta sa indeksom 25/2016.
 */

-- Rešenje:

SELECT COUNT(*) AS BROJ_POLOZENIH_PREDMETA,
       SUM(ESPB) AS BROJ_POLOZENIH_BODOVA
FROM DA.ISPIT AS I JOIN
     DA.PREDMET AS P ON I.IDPREDMETA = P.ID
WHERE I.INDEKS = 20160025 AND
      I.OCENA > 5 AND I.STATUS = 'o';

-- Objašnjenje:
--
-- Podatke o položenim predmetima studenta možemo naći u tabeli ISPIT,
-- dok podatke o ESPB bodovima odgovarajućih predmeta možemo naći samo
-- u tabeli PREDMET, te je neophodno izvršiti spajanje ovih tabela.
--
-- Nakon toga, broj položenih predmeta dobijamo pomoću funkcije COUNT,
-- isto kao i do sada. Međutim, za broj položenih bodova moramo da upotrebimo
-- novu agregatnu funkciju - funkciju SUM. Ova funkcija sumira ne-NULL vrednosti
-- iz prosleđenog skupa!
--
-- Primer:
--
-- INDEKS   | IDPREDMETA | OCENA | NAZIV         | ESPB | ...
-- 20160025 | 2174       | 9     | Engl. jezik 1 | 3    | ...
-- 20160025 | 2176       | 7     | Engl. jezik 2 | 3    | ...
-- 20160025 | 1580       | 6     | DS 1          | 6    | ...
-- 20160025 | 2171       | 6     | LAAG          | 7    | ...
-- 20160025 | 2179       | 9     | Osnovi astro. | 6    | ...
--
-- SUM(ESPB) se razvija u SUM(3, 3, 6, 7, 6) = 25.

/*
 * 5. Izlistati ocene dobijene na ispitima i ako je ocena jednaka 5 ispisati NULL.
 */

-- Rešenje 1:

SELECT CASE
           WHEN OCENA = 5 THEN NULL
           ELSE OCENA
       END
FROM DA.ISPIT;

-- Rešenje 2:

SELECT NULLIF(OCENA, 5)
FROM DA.ISPIT;

-- Objašnjenje:
--
-- Funkcija NULLIF (napomena - nije agregatna, nemojte se zbuniti!) prihvata
-- dva argumenta i poredi ih. Ukoliko su jednaki, rezultat je NULL, a ukoliko
-- nisu, rezultat je levi argument (prema tome, NULLIF(5, OCENA) ne bi bilo tačno!).

/*
 * 6. Koliko ima različitih ocena dobijenih na ispitima, a da ocena nije 5?
 */

-- Rešenje:

SELECT COUNT(DISTINCT NULLIF(OCENA, 5))
FROM DA.ISPIT;

-- Objašnjenje:
--
-- Prvo, ne želimo da uračunamo petice u naš rezultat. Pošto COUNT ne broji NULL
-- vrednosti, to možemo rešiti tako što sve petice konvertujemo u NULL.
-- Nakon toga, duplikate uklanjamo sa DISTINCT (traže se RAZLIČITE ocene).

/*
 * 7. Odrediti prosečan broj ESPB svih predmeta.
 */

-- Prvi pokušaj (pogrešan):

SELECT AVG(ESPB) AS PROSECAN_BROJ_ESPB
FROM DA.PREDMET;

-- Objašnjenje:
--
-- Agregatna funkcija AVG prihvata skup vrednosti i vraća prosek ne-NULL vrednosti
-- iz tog skupa. Međutim, u ovom pokušaju smo kao rezultat dobili 7 kao prosečan
-- broj ESPB. U bazi imamo veliki broj predmeta, te je jako mala verovatnoća da je
-- baš neki ceo broj prosek njihovih ESPB. Zašto/kako se ovo desilo?
--
-- Ukoliko je tip vrednosti koje prosleđujemo agregatnoj funkciji AVG celobrojan,
-- vršiće se celobrojno deljenje! Ukoliko želimo broj sa decimalama kao rezultat,
-- moramo konvertovati celobrojne vrednosti u realne. U narednim rešenjima, to je
-- izvedeno na nekoliko načina (implicitno konvertovanje množenjem ili sabiranjem
-- sa neutralom, ili eksplicitno pomoću funkcije CAST).

-- Rešenje 1:

SELECT AVG(ESPB * 1.0) AS PROSECAN_BROJ_ESPB
FROM DA.PREDMET;

-- Rešenje 2:

SELECT AVG(ESPB + 0.0) AS PROSECAN_BROJ_ESPB
FROM DA.PREDMET;

-- Rešenje 3:

SELECT AVG(CAST(ESPB AS REAL)) AS PROSECAN_BROJ_ESPB
FROM DA.PREDMET;

/*
 * 7. Izdvojiti oznake, nazive i espb bodove predmeta čiji je broj espb bodova
 * veći od prosečnog broja espb bodova svih predmeta.
 */

-- Rešenje 1:

SELECT OZNAKA, NAZIV, ESPB
FROM DA.PREDMET
WHERE ESPB > (
    SELECT AVG(ESPB * 1.0)
    FROM DA.PREDMET
);

-- Objašnjenje:
--
-- U podupitu samo izvlačimo prosek svih ESPB kao u prethodnom primeru, pa pomoću
-- njega filtriramo sve predmete.

-- Rešenje 2:

SELECT OZNAKA, NAZIV, ESPB
FROM DA.PREDMET
WHERE ESPB > (
    SELECT AVG(ESPB)
    FROM DA.PREDMET
);

-- Objašnjenje:
--
-- Pošto su ESPB celobrojni, a ovde ih koristimo samo za filtriranje, zapravo
-- neće biti razlike u rezultatu čak i ako radimo celobrojno deljenje u AVG...

/*
 * 8. Izdvojiti broj položenih predmeta za svakog studenta koji ima bar jedan
 * položen ispit.
 */

-- Rešenje:

SELECT INDEKS,
       COUNT(*) AS BROJ_POLOZENIH_PREDMETA
FROM DA.ISPIT
WHERE OCENA > 5 AND STATUS = 'o'
GROUP BY INDEKS;

-- Objašnjenje:
--
-- Pogledajmo zadatak 4. - i tu je trebalo odrediti broj položenih predmeta, ali
-- samo za jednog studenta. Šta ako želimo da proširimo to rešenje na sve studente
-- (koji su položili barem nešto)?
--
-- Nekako bi morali da pozovemo agregatnu funkciju COUNT, ali za svakog studenta
-- (indeks) ponaosob (za razliku od do sada, gde smo agregatne funkcije koristili
-- bez bilo kakvog "grupisanja"). Za ovakve potrebe se koristi naredba grupisanja
-- GROUP BY.
--
-- GROUP BY, na osnovu vrednosti nekog izraza (ili nekoliko izraza, videćemo to kasnije)
-- particioniše rezultate upita u grupe. Sve agregatne funkcije se nakon toga izvršavaju
-- ne globalno, već po dobijenim grupama!
--
-- Primer (položeni ispiti studenata):
--
-- INDEKS   | IDPREDMETA | OCENA | ...
-- 20160001 | 2174       | 9     | ...
-- 20160001 | 2176       | 7     | ...
-- 20160001 | 1580       | 6     | ...
-- 20160002 | 2171       | 6     | ...
-- 20160003 | 2179       | 9     | ...
-- 20160003 | 2174       | 9     | ...
--
-- GROUP BY INDEKS (položene ispite studenata po njihovom indeksu):
--
-- *INDEKS* | IDPREDMETA | OCENA | ...
-- -----------------------------------
-- 20160001 | 2174       | 9     | ...
--          | 2176       | 7     | ...
--          | 1580       | 6     | ...
-- -----------------------------------
-- 20160002 | 2171       | 6     | ...
-- -----------------------------------
-- 20160003 | 2179       | 9     | ...
--          | 2174       | 9     | ...
-- -----------------------------------
--
-- COUNT(*) (prebrojavamo broj redova u okviru grupa):
--
-- INDEKS   | COUNT(*)
-- 20160001 | 3
-- 20160002 | 1
-- 20160003 | 2
--
-- Logički redosled izvršavanja naredbi je:
-- 1. FROM
-- 2. WHERE
-- 3. GROUP BY
-- 4. SELECT
-- 5. ORDER BY
--
-- IZUZETNO VAŽNO!!!
--
-- Ukoliko koristimo nekakvu agregatnu funkciju u SELECT-u, NE MOŽEMO referisati
-- na bilo koje druge vrednosti (van drugih agregatnih funkcija) ukoliko prvo ne
-- grupišemo po njima!
-- Na primer, pošto u prethodnom rešenju referišemo na kolonu INDEKS, greška bi
-- bila prijavljena ukoliko ne bi imali GROUP BY INDEKS u upitu!

/*
 * 9. Za svakog studenta upisanog na fakultet 2018. godine, koji ima bar jedan
 * položen ispit, izdvojiti broj indeksa, prosečnu ocenu zaokruženu na dve decimale,
 * najmanju ocenu i najveću ocenu iz položenih ispita.
 */

-- Rešenje:

SELECT D.INDEKS,
       DECIMAL(AVG(I.OCENA * 1.0), 4, 2) AS PROSEK,
       MIN(I.OCENA) AS NAJMANJA_OCENA,
       MAX(I.OCENA) AS NAJVECA_OCENA
FROM DA.DOSIJE AS D JOIN
     DA.ISPIT AS I ON D.INDEKS = I.INDEKS
WHERE YEAR(D.DATUPISA) = 2018 AND
      I.STATUS = 'o' AND I.OCENA > 5
GROUP BY D.INDEKS;

-- Objašnjenje:
--
-- Sličan princip kao i prethodni primer, samo što umesto prebrojavanja tražimo
-- prosek, a uvodimo i nove agregatne funkcije - MIN i MAX.
--
-- Da bi imali pristup podatku o godini upisa studenta za potrebe filtriranja,
-- potrebno je da izvršimo spajanje tabele DOSIJE i tabele ISPIT.

/*
 * 10. Izdvojiti identifikator predmeta, školsku godinu u kojoj je održan ispit iz tog
 * predmeta i najveću ocenu dobijenu na ispitima iz tog predmeta u toj školskoj godini.
 */

-- Rešenje:

SELECT IDPREDMETA, SKGODINA,
       MAX(OCENA) AS NAJVECA_OCENA
FROM DA.ISPIT
GROUP BY IDPREDMETA, SKGODINA;

-- Objašnjenje:
--
-- U ovom slučaju ne želimo samo najveću ocenu po predmetu, već želimo da to dodatno
-- particionišemo i po školskim godinama. U GROUP BY naredbi možemo navesti listu
-- više izraza po kojima želimo da grupišemo rezultat.
--
-- Primer:
--
-- INDEKS   | IDPREDMETA | SKGODINA | OCENA | ...
-- 20150001 | 1578       | 2015     | 9     | ...
-- 20150002 | 1578       | 2015     | 6     | ...
-- 20160003 | 1578       | 2015     | 10    | ...
-- 20160042 | 1578       | 2016     | 7     | ...
-- 20150053 | 1578       | 2016     | 7     | ...
-- 20160001 | 1578       | 2017     | 8     | ...
-- 20150052 | 1595       | 2015     | 7     | ...
-- 20150033 | 1595       | 2019     | 10    | ...
-- 20160003 | 1595       | 2019     | 5     | ...
-- 20160003 | 1595       | 2020     | 6     | ...
--
-- GROUP BY IDPREDMETA (prvo grupišemo po IDPREDMETA):
--
-- *IDPREDMETA* | INDEKS   | SKGODINA | OCENA | ...
-- ------------------------------------------------
-- 1578         | 20150001 | 2015     | 9     | ...
--              | 20150002 | 2015     | 6     | ...
--              | 20160003 | 2015     | 10    | ...
--              | 20160042 | 2016     | 7     | ...
--              | 20150053 | 2016     | 7     | ...
--              | 20160001 | 2017     | 8     | ...
-- ------------------------------------------------
-- 1595         | 20150052 | 2015     | 7     | ...
--              | 20150033 | 2019     | 10    | ...
--              | 20160003 | 2019     | 5     | ...
--              | 20160003 | 2020     | 6     | ...
-- ------------------------------------------------
--
-- GROUP BY SKGODINA (onda pravimo još manje grupe po SKGODINA):
--
-- *IDPREDMETA* | *SKGODINA* | INDEKS   | OCENA | ...
-- --------------------------------------------------
-- 1578         | 2015       | 20150001 | 9     | ...
--              |            | 20150002 | 6     | ...
--              |            | 20160003 | 10    | ...
--              |------------------------------------
--              | 2016       | 20160042 | 7     | ...
--              |            | 20150053 | 7     | ...
--              |------------------------------------
--              | 2017       | 20160001 | 8     | ...
-- --------------------------------------------------
-- 1595         | 2015       | 20150052 | 7     | ...
--              |------------------------------------
--              | 2019       | 20150033 | 10    | ...
--              |            | 20160003 | 5     | ...
--              |------------------------------------
--              | 2020       | 20160003 | 6     | ...
-- --------------------------------------------------
--
-- MAX(OCENA) (tražimo najveću ocenu u svakoj od dobijenih grupa):
--
-- IDPREDMETA | SKGODINA | MAX(OCENA)
-- 1578       | 2015     | 10 <------ MAX(9, 6, 10)
-- 1578       | 2016     | 7
-- 1578       | 2017     | 8
-- 1595       | 2015     | 7
-- 1595       | 2019     | 10 <------ MAX(10, 5)
-- 1595       | 2020     | 6

/*
 * 11. U prethodnom zadatku dodatno izdvojiti i naziv predmeta.
 */

-- Rešenje:

SELECT P.ID, P.NAZIV, I.SKGODINA,
       MAX(I.OCENA) AS NAJVECA_OCENA
FROM DA.PREDMET AS P JOIN
     DA.ISPIT AS I ON P.ID = I.IDPREDMETA
GROUP BY P.ID, P.NAZIV, I.SKGODINA;

-- Objašnjenje:
--
-- Zbog naziva predmeta, potrebno je da spojimo tabelu ISPIT sa tabelom PREDMET.
-- Princip je isti kao i prethodni primer, samo što moramo dodati i NAZIV u
-- GROUP BY jer ga koristimo u SELECT-u.

/*
 * 12. Za svaki predmet izračunati koliko studenata ga je položilo.
 * Izdvojite i predmete koje niko nije položio.
 */

-- Rešenje 1:

SELECT P.ID, P.NAZIV, (
           SELECT COUNT(*)
           FROM DA.ISPIT AS I
           WHERE I.IDPREDMETA = P.ID AND
                 I.STATUS = 'o' AND I.OCENA > 5
       ) AS BROJ_POLOZENIH
FROM DA.PREDMET AS P
ORDER BY BROJ_POLOZENIH;

-- Objašnjenje:
--
-- Pošto moramo da izdvojimo sve predmete (i one koje niko nije položio), moramo
-- koristiti tabelu PREDMET. Broj studenata koji su položili predmet se onda može
-- dobiti jednostavnim podupitom koji za određeni predmet (P.ID) prebrojava broj
-- položenih ispita.
--
-- Međutim, ovakva upotreba podupita je često neefikasna (primetite da imamo korelisani
-- podupit!), te možemo razmotriti neko potencijalno efikasnije rešenje.

-- Pokušaj (sa malim propustom!) efikasnijeg rešenja:

SELECT P.ID, P.NAZIV,
       COUNT(*) AS BROJ_POLOZENIH
FROM DA.PREDMET AS P LEFT JOIN
     DA.ISPIT AS I ON P.ID = I.IDPREDMETA AND
                      I.STATUS = 'o' AND
                      I.OCENA > 5
GROUP BY P.ID, P.NAZIV
ORDER BY BROJ_POLOZENIH;

-- Objašnjenje:
--
-- Ovde ćemo, umesto podupita, koristiti spajanje i grupisanje. Da bi zadržali sve predmete
-- (i one koji nemaju parnjaka u vidu položenog ispita), spajanje će biti levo spoljašnje.
-- Pošto nas interesuje broj položenih ispita po predmetu, grupisaćemo po njegovom identifikatoru,
-- ali i po nazivu jer želimo i to da izdvojimo u SELECT-u.
--
-- Međutim, ovde postoji jedan propust! Ako pogledamo rezultat ovog upita, primetićemo da nigde
-- nema predmeta gde je 0 položenih ispita - svi imaju najmanje 1. U rešenju 1 smo videli da
-- to nije slučaj. Greška je u tome što smo iskoristili COUNT(*)! COUNT(*) broji SVE redove
-- u rezultatu, čak iako oni sadrže neke NULL vrednosti, a to je upravo slučaj za one predmete
-- koji nemaju parnjaka u vidu položenog ispita. Na primer, u rezultatu upita (pre prebrojavanja)
-- imamo red oblika:
-- (P.ID = 2250, P.NAZIV = 'Racionalna mehanika', ..., I.INDEKS = NULL, I.IDPREDMETA = NULL, I.OCENA = NULL, ...)
-- Ovaj red je nastao zato što predmet 'Racionalna mehanika' nema položene ispite. Međutim, COUNT(*)
-- ga broji kao i bilo kakav drugi red.

-- Rešenje 2:

SELECT P.ID, P.NAZIV,
       COUNT(I.INDEKS) AS BROJ_POLOZENIH
FROM DA.PREDMET AS P LEFT JOIN
     DA.ISPIT AS I ON P.ID = I.IDPREDMETA AND
                      I.STATUS = 'o' AND
                      I.OCENA > 5
GROUP BY P.ID, P.NAZIV
ORDER BY BROJ_POLOZENIH;

-- Objašnjenje:
--
-- Time što smo upotrebili COUNT(I.INDEKS) umesto COUNT(*) smo rešili problem. Tamo gde predmet
-- nema položeni ispit, postojaće red, ali kolona I.INDEKS će imati vrednost NULL u tom slučaju.

/*
 * 13. Izdvojiti identifikatore predmeta za koje je ispit prijavilo više od 50 različitih studenata.
 */

-- Rešenje 1:

SELECT P.ID
FROM DA.PREDMET AS P
WHERE 50 < (
    SELECT COUNT(DISTINCT I.INDEKS)
    FROM DA.ISPIT AS I
    WHERE I.IDPREDMETA = P.ID
);

-- Objašnjenje:
--
-- Slično kao i u prethodnom primeru, možemo napraviti podupit. Pošto nas interesuju RAZLIČITI
-- studenti (ako je neki student prijavio ispit 3 puta, želimo da ga brojimo samo jednom), koristimo
-- DISTINCT pri pozivu funkcije COUNT.
--
-- Isto kao i pre, i ovde imamo korelisani podupit, te bi bilo dobro razmotriti efikasnije rešenje.

-- Neispravan pokušaj:

SELECT IDPREDMETA,
       COUNT(DISTINCT INDEKS) AS BROJ_PRIJAVLJENIH_STUDENATA
FROM DA.ISPIT
WHERE COUNT(DISTINCT INDEKS) > 50
GROUP BY IDPREDMETA;

-- Objašnjenje:
--
-- Ovaj podupit je neispravan i ne može se izvršiti! Agregatne funkcije NE MOŽEMO koristiti u
-- okviru WHERE-a zbog logičkog redosleda izvršavanja naredbi. Prisetimo se, redosled je bio:
-- 1. FROM
-- 2. WHERE
-- 3. GROUP BY
-- 4. SELECT
-- 5. ORDER BY
-- a agregatne funkcije možemo koristiti tek nakon grupisanja.
--
-- Upravo za ovakve slučajeve (gde je potrebno postaviti uslov nad nekom grupom, tj. rezultatom
-- agregatne funkcije), koristi se HAVING umesto WHERE.

-- Rešenje 2:

SELECT IDPREDMETA,
       COUNT(DISTINCT INDEKS) AS BROJ_PRIJAVLJENIH_STUDENATA
FROM DA.ISPIT
GROUP BY IDPREDMETA
HAVING COUNT(DISTINCT INDEKS) > 50;

-- Objašnjenje:
--
-- Logički redosled izvršavanja naredbi, ukoliko uračunamo i HAVING, je sada:
-- 1. FROM
-- 2. WHERE
-- 3. GROUP BY
-- 4. HAVING
-- 5. SELECT
-- 6. ORDER BY
--
-- Ovde možemo zadavati uslove nad rezultatima agregatnih funkcija, ali, slično kao
-- i u SELECT-u (a i u ORDER BY-u), ne možemo referisati na kolone koje nisu deo
-- GROUP BY naredbe.

/*
 * 14. Za ispitne rokove koji su održani u 2016. godini i u kojima su svi regularno
 * polagani ispiti i položeni, izdvojiti oznaku roka, broj položenih ispita u tom roku
 * i broj studenata koji su položili ispite u tom roku.
 */

-- Rešenje:

SELECT I.OZNAKAROKA,
       COUNT(*) AS BROJ_POLOZENIH,
       COUNT(DISTINCT I.INDEKS) AS BROJ_STUDENATA
FROM DA.ISPIT AS I
WHERE I.SKGODINA = 2016 AND I.STATUS = 'o'
GROUP BY I.OZNAKAROKA
HAVING MIN(I.OCENA) > 5;

/*
 * 15. Za svakog studenta izdvojiti broj indeksa i mesec u kome je položio
 * više od dva ispita (nije važno koje godine). Izdvojiti indeks studenta,
 * ime meseca i broj položenih predmeta. Rezultat urediti prema broju indeksa
 * i mesecu polaganja.
 */

-- Rešenje:

SELECT I.INDEKS,
       MONTHNAME(I.DATPOLAGANJA) AS MESEC,
       COUNT(*) AS BROJ_POLOZENIH_PREDMETA
FROM DA.ISPIT AS I
WHERE I.STATUS = 'o' AND I.OCENA > 5
GROUP BY I.INDEKS, MONTHNAME(I.DATPOLAGANJA)
HAVING COUNT(*) > 2
ORDER BY I.INDEKS, MESEC;

-- Objašnjenje:
--
-- Grupisanje se ne mora vršiti po direktnim kolonama - može i po izvedenim.
-- Imati u vidu da bi, zamenom MONTHNAME(I.DATPOLAGANJA) u SELECT-u sa
-- I.DATPOLAGANJA napravili grešku - to je neispravan upit!

/*
 * 16. Za svaki predmet koji nosi najmanje espb bodova izdvojiti studente
 * koji su ga položili. Izdvojiti naziv predmeta i ime i prezime studenta.
 * Ime i prezime studenta izdvojiti u jednoj koloni.
 * Za predmete sa najmanjim brojem espb koje nije položio nijedan student
 * umesto imena i prezimena ispisati nema.
 */

-- Rešenje 1:

SELECT P.NAZIV,
       COALESCE(D.IME || ' ' || D.PREZIME, 'Nema') AS STUDENT
FROM DA.PREDMET AS P LEFT JOIN
     DA.ISPIT AS I ON P.ID = I.IDPREDMETA AND
                      I.STATUS = 'o' AND
                      I.OCENA > 5 LEFT JOIN
     DA.DOSIJE AS D ON I.INDEKS = D.INDEKS
WHERE P.ESPB <= ALL (
    SELECT ESPB
    FROM DA.PREDMET
);

-- Rešenje 2:

SELECT P.NAZIV,
       COALESCE(D.IME || ' ' || D.PREZIME, 'Nema') AS STUDENT
FROM DA.PREDMET AS P LEFT JOIN
     DA.ISPIT AS I ON P.ID = I.IDPREDMETA AND
                      I.STATUS = 'o' AND
                      I.OCENA > 5 LEFT JOIN
     DA.DOSIJE AS D ON I.INDEKS = D.INDEKS
WHERE P.ESPB = (
    SELECT MIN(ESPB)
    FROM DA.PREDMET
);

/*
 * 17. Za svakog studenta koji je položio između 15 i 25 bodova i čije ime sadrži
 * malo ili veliko slovo o ili prezime sadrži malo ili veliko slovo a izdvojiti
 * indeks, ime, prezime, broj prijavljenih ispita, broj različitih predmeta koje
 * je prijavio, broj ispita koje je položio i prosečnu ocenu.
 * Rezultat urediti prema indeksu.
 */

-- Rešenje:

-- Korak 1 - izdvojimo sve studente čije ime sadrži malo ili veliko slovo o
-- ili prezime sadrži malo ili veliko slovo a:

SELECT D.INDEKS, D.IME, D.PREZIME
FROM DA.DOSIJE AS D
WHERE LOWER(D.IME) LIKE '%o%' OR LOWER(D.PREZIME) LIKE '%a%';

-- Objašnjenje:
--
-- Funkcija LOWER konvertuje sva velika slova u prosleđenoj niski u mala slova.
-- Ovako izbegavamo dupliranje uslova za slučajeve velikog i malog slova.

-- Korak 2 - izbacimo sve studente iz rezultata koji nisu osvojili između 15 i 25
-- ESPB boda:

SELECT D.INDEKS, D.IME, D.PREZIME
FROM DA.DOSIJE AS D JOIN
     DA.ISPIT AS I ON D.INDEKS = I.INDEKS JOIN
     DA.PREDMET AS P ON I.IDPREDMETA = P.ID
WHERE LOWER(D.IME) LIKE '%o%' OR LOWER(D.PREZIME) LIKE '%a%'
GROUP BY D.INDEKS, D.IME, D.PREZIME
HAVING SUM(CASE WHEN I.STATUS = 'o' AND I.OCENA > 5 THEN P.ESPB END) BETWEEN 15 AND 25;

-- Objašnjenje:
--
-- Želimo da zadržimo samo one studente koji su do sada osvojili između 15 i 25 ESPB.
-- Podatke o položenim predmetima imamo u tabeli ISPIT, a podatke o ESPB bodovima koje
-- ti predmeti nose imamo u tabeli PREDMET, te spajamo te tabele sa tabelom DOSIJE.
-- Napomena - ovako (koristimo INNER JOIN) gubimo studente koji nemaju prijavljenih ispita,
-- ali to je u redu, jer svakako nam trebaju samo oni koji su položili bar 15 ESPB.
--
-- Hoćemo da odredimo koliko je ESPB položio svaki student, pa je potrebno da grupišemo
-- po njihovim indeksima. Pošto u SELECT-u prikazujemo i ime i prezime, i njih ćemo dodati
-- u GROUP BY.
--
-- Nakon grupisanja, u HAVING proveravamo sumu ESPB za položene ispite. Ukoliko je ispit
-- položen, izraz "CASE WHEN I.STATUS = 'o' AND I.OCENA > 5 THEN P.ESPB END" vraća broj
-- ESPB odgovarajućeg predmeta. Ukoliko ispit nije položen, implicitno se vraća NULL
-- (jer ne upadamo ni u jedan WHEN slučaj), a NULL se ne računa prilikom poziva funkcije
-- SUM (alternativno, mogli smo da napišemo "CASE WHEN I.STATUS = 'o' AND I.OCENA > 5 THEN P.ESPB ELSE 0 END").

-- Korak 3 - u SELECT dodajemo prebrojavanje prijava ispita, prijava različitih predmeta,
-- položenih ispita i računanje prosečne ocene:

SELECT D.INDEKS, D.IME, D.PREZIME,
       COUNT(*) AS BROJ_PRIJAVLJENIH_ISPITA,
       COUNT(DISTINCT I.IDPREDMETA) AS BROJ_PRIJAVLJENIH_PREDMETA,
       COUNT(CASE WHEN I.STATUS ='o' AND I.OCENA > 5 THEN 42 END) AS BROJ_POLOZENIH_ISPITA,
       DECIMAL(ROUND(AVG(CASE WHEN I.STATUS ='o' AND I.OCENA > 5 THEN I.OCENA * 1.0 END), 2), 4, 2) AS PROSECNA_OCENA
FROM DA.DOSIJE AS D JOIN
     DA.ISPIT AS I ON D.INDEKS = I.INDEKS JOIN
     DA.PREDMET AS P ON I.IDPREDMETA = P.ID
WHERE LOWER(D.IME) LIKE '%o%' OR LOWER(D.PREZIME) LIKE '%a%'
GROUP BY D.INDEKS, D.IME, D.PREZIME
HAVING SUM(CASE WHEN I.STATUS = 'o' AND I.OCENA > 5 THEN P.ESPB END) BETWEEN 15 AND 25;

-- Objašnjenje:
--
-- Obratite pažnju na "COUNT(CASE WHEN I.STATUS ='o' AND I.OCENA > 5 THEN 42 END)".
-- Ovde je vrednost 42 izabrana proizvoljno - može biti bilo šta (osim NULL), jer
-- jednako će uticati na rezultat funkcije COUNT.
--
-- DECIMAL i ROUND oko računanja proseka su tu u svrhu zaokruživanja na dve decimale.
-- Zašto ROUND pre DECIMAL?
-- Zato što je DECIMAL(7.239, 4, 2) = 7.23 - samo se odsecaju decimalna mesta, bez zaokruživanja!

/*
 * 18. Izdvojiti parove studenata čija imena počinju na slovo M i za koje
 * važi da su bar dva ista predmeta položili u istom ispitnom roku.
 */

-- Rešenje 1:

SELECT D1.INDEKS, D1.IME, D1.PREZIME,
       D2.INDEKS, D2.IME, D2.PREZIME
FROM DA.DOSIJE AS D1,
     DA.DOSIJE AS D2
WHERE D1.INDEKS < D2.INDEKS AND
      D1.IME LIKE 'M%' AND
      D2.IME LIKE 'M%' AND
      2 <= (
          SELECT COUNT(*)
          FROM DA.ISPIT AS I1 JOIN
               DA.ISPIT AS I2 ON I1.IDPREDMETA = I2.IDPREDMETA AND
                                 I1.SKGODINA = I2.SKGODINA AND
                                 I1.OZNAKAROKA = I2.OZNAKAROKA
          WHERE I1.INDEKS = D1.INDEKS AND
                I1.STATUS = 'o' AND I1.OCENA > 5 AND
                I2.INDEKS = D2.INDEKS AND
                I2.STATUS = 'o' AND I2.OCENA > 5
      );

-- Objašnjenje:
--
-- Ideja je sledeća - prvo izdvojimo parove svih studenata čije ime počinje sa M
-- (sa uslovom D1.INDEKS < D2.INDEKS razbijamo simetriju u rezultatu - ne želimo
-- da imamo redove sa istim podacima, samo sa obrnutim pozicijama, npr.
-- (20180275, 20180277) i (20180277, 20180275)).
--
-- Nakon toga, u podupitu izdvajamo parove istih položenih predmeta u istim
-- ispitnim rokovima, npr.:
-- (20180275, 'Programiranje 1', Januar 1 2018) i
-- (20180277, 'Programiranje 1', Januar 1 2018)
--
-- Ukoliko takvih parova ispita ima barem 2, uslov je zadovoljen.
--
-- Iako korektan, prethodni upit je izuzetno neefikasan - potrebno je više sekundi
-- da se izvrši u potpunosti zbog podupita. Ovo se može izbeći spajanjem i grupisanjem
-- umesto pravljenjem podupita.

-- Rešenje 2:

SELECT D1.INDEKS, D1.IME, D1.PREZIME,
       D2.INDEKS, D2.IME, D2.PREZIME
FROM DA.ISPIT AS I1 JOIN
     DA.ISPIT AS I2 ON (I1.IDPREDMETA, I1.SKGODINA, I1.OZNAKAROKA) =
                       (I2.IDPREDMETA, I2.SKGODINA, I2.OZNAKAROKA) JOIN
     DA.DOSIJE AS D1 ON D1.INDEKS = I1.INDEKS JOIN
     DA.DOSIJE AS D2 ON D2.INDEKS = I2.INDEKS
WHERE D1.INDEKS < D2.INDEKS AND
      D1.IME LIKE 'M%' AND
      D2.IME LIKE 'M%' AND
      I1.STATUS = 'o' AND I1.OCENA > 5 AND
      I2.STATUS = 'o' AND I2.OCENA > 5
GROUP BY D1.INDEKS, D1.IME, D1.PREZIME,
         D2.INDEKS, D2.IME, D2.PREZIME
HAVING COUNT(*) >= 2;

-- Objašnjenje:
--
-- Odmah spajamo odgovarajuće ispite u parove (isti predmet, isti rok), nakon
-- čega tim ispitima pridodajemo i podatke o odgovarajućim studentima (jer su
-- nam potrebna njihova imena).
--
-- Zadržavamo samo redove koji odgovaraju položenim ispitima i studentima čije
-- ime počinje sa slovom M. Nakon toga, rezultat grupišemo po indeksima studenata
-- zadržavamo samo one studente gde u grupi odgovarajućih ispita postoji bar dva reda.
--
-- Ovaj upit se izvršava mnogo brže nego prethodni.
