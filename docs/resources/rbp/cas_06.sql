/*
 * 1. Predmeti se kategorišu kao laki ukoliko nose manje od 6 bodova,
 * kao teški ukoliko nose više od 8 bodova, inače su srednje teški.
 * Prebrojati koliko predmeta pripada kojoj kategoriji. Izdvojiti
 * kategoriju i broj predmeta iz te kategorije.
 */

-- Rešenje 1:

SELECT CASE
           WHEN ESPB < 6 THEN 'lak'
           WHEN ESPB > 8 THEN 'tezak'
           ELSE 'srednje tezak'
       END AS KATEGORIJA,
       COUNT(*) AS BROJ_PREDMETA
FROM DA.PREDMET
GROUP BY CASE
             WHEN ESPB < 6 THEN 'lak'
             WHEN ESPB > 8 THEN 'tezak'
             ELSE 'srednje tezak'
         END;

-- Objašnjenje:
--
-- Krenimo od toga što za svaki predmet odredimo njegovu kategoriju. Nakon toga,
-- potrebno je prebrojati broj predmeta u okviru svake od kategorija. Za to možemo
-- koristiti grupisanje po kategoriji i COUNT agregatnu funkciju.
--
-- Međutim, ako bi pokušali da napišemo GROUP BY KATEGORIJA, ubrzo bi videli da takav
-- upit nije validan. Razlog iza ovoga je redosled izvršavanja naredbi - SELECT se
-- izvršava tek nakon GROUP BY, tako da tu ne možemo referisati na ime KATEGORIJA!
--
-- Rešenje je onda da samo kopiramo ceo CASE izraz u GROUP BY naredbu. Međutim, bilo
-- bi lepo kada bi imali način da zaobiđemo ovo dupliranje komplikovanog izraza. Upravo
-- to ćemo videti u drugom rešenju.

-- Rešenje 2:

WITH KATEGORIZACIJA AS ( -- WITH <ime> AS ( <upit> )
    SELECT CASE
               WHEN ESPB < 6 THEN 'lak'
               WHEN ESPB > 8 THEN 'tezak'
               ELSE 'srednje tezak'
           END AS KATEGORIJA -- Moramo dati ime svim kolonama u pomoćnoj tabeli!
    FROM DA.PREDMET
)
SELECT KATEGORIJA, COUNT(*) AS BROJ_PREDMETA
FROM KATEGORIZACIJA
GROUP BY KATEGORIJA;

-- Objašnjenje:
--
-- Da bi izbegli prethodni problem, koristićemo pomoćnu tabelu! Naime, pomoću WITH naredbe,
-- možemo dati ime rezultatu nekog upita, a taj rezultat onda možemo dalje koristiti u
-- glavnom upitu kao i bilo koju drugu tabelu.
--
-- Pošto se ova pomoćna tabela kreira pre izvršavanja glavnog upita, na njene kolone možemo
-- referisati iz bilo kog dela glavnog upita, uključujući u GROUP BY (što nismo mogli u
-- prethodnom rešenju).
--
-- Ono što je važno napomenuti je da sve kolone u pomoćnoj tabeli moraju biti imenovane.
-- Ako nekoj koloni ne dodelimo ime, upit nije validan! Dodatno, moguće je definisati i
-- više pomoćnih tabela za jedan upit, što ćemo videti u jednom od narednih zadataka.

/*
 * 2. Izračunati koliko studenata je položilo više od 10 bodova.
 */

-- Pre nego što krenemo u prebrojavanje, bilo bi dobro da prvo odredimo koliko (ESPB) bodova
-- je položio svaki student. Svakako nam je taj podatak neophodan da bi uopšte razmatrali dalje
-- prebrojavanje studenata po nekom uslovu.

SELECT D.INDEKS,
       COALESCE(SUM(P.ESPB), 0) AS POLOZENO_BODOVA -- COALESCE koristimo zato što će suma za one koji nisu položili ništa da vrati NULL
FROM DA.DOSIJE AS D LEFT JOIN -- Levo spajanje da bi zadržali i one studente koji nisu položili ništa
     DA.ISPIT AS I ON D.INDEKS = I.INDEKS AND
                      I.STATUS = 'o' AND
                      I.OCENA > 5 LEFT JOIN -- Opet, neophodno levo spajanje da bi zadržali one studente koji
     DA.PREDMET AS P ON I.IDPREDMETA = P.ID -- nisu položili ništa usled provere I.IDPREDMETA = P.ID (NULL = P.ID)
GROUP BY D.INDEKS;

-- Napomena! Zbog uslova da prebrojavamo samo studente koji su položili više od 10 bodova u krajnjem rezultatu,
-- leva spajanja da bi zadržali i one studente koji nisu položili ništa (0 ESPB) suštinski nisu neophodna za
-- dobijanje konačnog rezultata. Ipak, zadatak je rešen ovako radi vežbe.

-- Rešenje 1:

SELECT COUNT(*) AS BROJ_STUDENATA
FROM (
    SELECT D.INDEKS,
           COALESCE(SUM(P.ESPB), 0) AS POLOZENO_BODOVA
    FROM DA.DOSIJE AS D LEFT JOIN
         DA.ISPIT AS I ON D.INDEKS = I.INDEKS AND
                          I.STATUS = 'o' AND
                          I.OCENA > 5 LEFT JOIN
         DA.PREDMET AS P ON I.IDPREDMETA = P.ID
    GROUP BY D.INDEKS
)
WHERE POLOZENO_BODOVA > 10;

-- Objašnjenje:
--
-- Prva opcija - prethodni upit koji za svakog studenta određuje ESPB koristimo kao podupit u FROM-u.
-- Filtriramo redove sa uslovom WHERE POLOZENO_BODOVA > 10, nakon čega ih samo prebrojavamo.

-- Rešenje 2:

WITH POLOZENO_BODOVA AS (
    SELECT D.INDEKS,
           COALESCE(SUM(P.ESPB), 0) AS POLOZENO_BODOVA
    FROM DA.DOSIJE AS D LEFT JOIN
         DA.ISPIT AS I ON D.INDEKS = I.INDEKS AND
                          I.STATUS = 'o' AND
                          I.OCENA > 5 LEFT JOIN
         DA.PREDMET AS P ON I.IDPREDMETA = P.ID
    GROUP BY D.INDEKS
)
SELECT COUNT(*) AS BROJ_STUDENATA
FROM POLOZENO_BODOVA
WHERE POLOZENO_BODOVA > 10;

-- Objašnjenje:
--
-- Druga opcija - umesto da koristimo podupit u FROM, kreiramo pomoćnu tabelu sa WITH.
-- Iako su oba rešenja suštinski ekvivalentna (i po rezultatu, a i po efikasnosti), rešenje
-- sa pomoćnom tabelom može biti čitkije, naručito ako bi u nekom zadatku bilo potrebno
-- dalje spajanje tabela u FROM-u.

/*
 * 3. Naći broj ispitnih rokova u kojima je neki student položio
 * bar 3 različita predmeta.
 */

-- Rešenje 1:

SELECT INDEKS, SKGODINA, OZNAKAROKA,
           COUNT(*) AS BROJ_POLOZENIH_ISPITA
    FROM DA.ISPIT
    WHERE STATUS = 'o' AND OCENA > 5
    GROUP BY INDEKS, SKGODINA, OZNAKAROKA;

WITH POLOZENI_ISPITI_STUDENATA_PO_ROKOVIMA AS (
    SELECT INDEKS, SKGODINA, OZNAKAROKA,
           COUNT(*) AS BROJ_POLOZENIH_ISPITA
    FROM DA.ISPIT
    WHERE STATUS = 'o' AND OCENA > 5
    GROUP BY INDEKS, SKGODINA, OZNAKAROKA
)
SELECT COUNT(DISTINCT SKGODINA || OZNAKAROKA) AS BROJ_ROKOVA
FROM POLOZENI_ISPITI_STUDENATA_PO_ROKOVIMA
WHERE BROJ_POLOZENIH_ISPITA >= 3;

-- Objašnjenje:
--
-- U pomoćnoj tabeli POLOZENI_ISPITI_STUDENATA_PO_ROKOVIMA ćemo odrediti broj položenih
-- ispita za studente po rokovima (ako neki student nije položio ništa u nekom roku,
-- nećemo imati takav red - što je okej jer svakako imamo uslov za bar tri različita
-- položena predmeta).
--
-- Sadržaj ove pomoćne tabele onda izgleda otprilike ovako:
--
-- INDEKS   | SKGODINA | OZNAKAROKA | BROJ_POLOZENIH_ISPITA
-- 20150001 | 2015     | jan1       | 3
-- 20150001 | 2016     | jan1       | 1
-- 20150001 | 2017     | jan1       | 1
-- ...
-- 20150001 | 2016     | sep1       | 1
-- ...
-- 20150022 | 2015     | jan1       | 1
-- 20150022 | 2017     | jan1       | 2
-- ...
--
-- Sa WHERE BROJ_POLOZENIH_ISPITA >= 3 u glavnom upitu zadržavamo samo one rokove gde je
-- neki student položio bar 3 različita predmeta. Međutim, ovde i dalje imamo raspodelu
-- po studentima, a nas interesuje broj ispitnih rokova. Ono što nam je potrebno jeste
-- da prebrojimo broj različitih rokova u ovakvom rezultatu, za šta se može iskoristiti
-- COUNT(DISTINCT ...).
--
-- Ako bi probali da napišemo COUNT(DISTINCT SKGODINA, OZNAKAROKA), ubrzo bi videli da
-- ovakav upit nije validan - ukoliko se DISTINCT koristi unutar funkcije COUNT, on može
-- referisati samo na jednu kolonu! Srećom, ovo možemo prevazići sledećim trikom - samo
-- spojimo kolone SKGODINA i OZNAKAROKA konkatenacijom, čime, na primer, dobijamo
-- 2015jan1 za SKGODINA 2015 i OZNAKAROKA jan1.

-- Rešenje 2:

WITH PT1 AS (
    SELECT INDEKS, SKGODINA, OZNAKAROKA,
           COUNT(*) AS BROJ_POLOZENIH_ISPITA
    FROM DA.ISPIT
    WHERE STATUS = 'o' AND OCENA > 5
    GROUP BY INDEKS, SKGODINA, OZNAKAROKA
), PT2 AS (
    SELECT DISTINCT SKGODINA, OZNAKAROKA
    FROM PT1
    WHERE BROJ_POLOZENIH_ISPITA >= 3
)
SELECT COUNT(*) AS BROJ_ROKOVA
FROM PT2;

-- Objašnjenje:
--
-- Trik sa spajanjem kolona iz prethodnog rešenja se može izbeći tako što koristimo još
-- jednu pomoćnu tabelu. Prva pomoćna tabela, PT1, ima istu ulogu kao i pomoćna tabela
-- POLOZENI_ISPITI_STUDENATA_PO_ROKOVIMA iz prethodnog rešenja. Druga pomoćna tabela, PT2,
-- uzima jedinstvene ispitne rokove iz PT1 pomoću SELECT DISTINCT (i uz to filtrira po
-- broju položenih ispita). Konačno, u glavnom upitu onda samo prebrojavamo redove iz PT2.
--
-- Ovde je važno primetiti da ukoliko imamo više pomoćnih tabela, možemo referisati na prethodne
-- tabele iz kasnijih (npr. na PT1 iz PT2).

/*
 * 4. Za svaki predmet izdvojiti identifikator i broj različitih studenata
 * koji su ga polagali. Uz identifikatore predmeta koje niko nije polagao
 * izdvojiti 0.
 */

-- Rešenje:

SELECT P.ID,
       COUNT(DISTINCT I.INDEKS)
FROM DA.PREDMET AS P LEFT JOIN -- Levo spajanje da zadržimo i predmete koje niko nije polagao
     DA.ISPIT AS I ON P.ID = I.IDPREDMETA AND
                      I.STATUS NOT IN ('p', 'n') -- Nećemo ispite koji imaju status "prijavljen" ili "nije izašao"
GROUP BY P.ID;                                   -- jer oni nisu "polagani"

/*
 * 5. Za studenta koji ima ocenu 8 ili 9 izračunati iz koliko ispita
 * je dobio ocenu 8 i iz koliko ispita je dobio ocenu 9. Izdvojiti
 * indeks studenta, broj ispita iz kojih je student dobio ocenu 8 i
 * broj ispita iz kojih je student dobio ocenu 9.
 */

-- Prvi pokušaj:

WITH BROJ_OSMICA AS (
    SELECT INDEKS, COUNT(*) AS OSMICE
    FROM DA.ISPIT
    WHERE STATUS = 'o' AND OCENA = 8
    GROUP BY INDEKS
), BROJ_DEVETKI AS (
    SELECT INDEKS, COUNT(*) AS DEVETKE
    FROM DA.ISPIT
    WHERE STATUS = 'o' AND OCENA = 9
    GROUP BY INDEKS
)
SELECT BO.INDEKS AS INDEKS,
       BO.OSMICE AS OSMICE,
       BD.DEVETKE AS DEVETKE
FROM BROJ_OSMICA AS BO JOIN
     BROJ_DEVETKI AS BD ON BO.INDEKS = BD.INDEKS;

-- Objašnjenje:
--
-- Ideja je sledeća - napravimo dve pomoćne tabele. Jedna sadrži broj osmica za svakog studenta (koji ima
-- bar jednu osmicu), a druga sadrži broj devetki za svakog studenta (opet, koji ima bar jednu devetku).
-- Nakon toga, spajamo ove dve tabele po indeksu i time dobijamo broj osmica i broj devetki za studente.
--
-- Međutim, ovde postoji jedan propust - u rezultatu nisu prikazani studenti koji imaju osmice, ali nemaju
-- devetke, ili obrnuto. Ove studente smo izgubili prilikom spajanja sa JOIN - ako neki od studenata u jednoj
-- od tabela nema parnjaka u onoj drugoj, taj student nije zadržan. Ovo ćemo rešiti tako što koristimo
-- spoljašnje spajanje, tj. FULL OUTER JOIN.

-- Drugi pokušaj (FULL JOIN):

WITH BROJ_OSMICA AS (
    SELECT INDEKS, COUNT(*) AS OSMICE
    FROM DA.ISPIT
    WHERE STATUS = 'o' AND OCENA = 8
    GROUP BY INDEKS
), BROJ_DEVETKI AS (
    SELECT INDEKS, COUNT(*) AS DEVETKE
    FROM DA.ISPIT
    WHERE STATUS = 'o' AND OCENA = 9
    GROUP BY INDEKS
)
SELECT BO.INDEKS AS INDEKS,
       BO.OSMICE AS OSMICE,
       BD.DEVETKE AS DEVETKE
FROM BROJ_OSMICA AS BO FULL JOIN
     BROJ_DEVETKI AS BD ON BO.INDEKS = BD.INDEKS;

-- Objašnjenje:
--
-- Dodali smo spoljašnje spajanje i time smo zadržali sve studente, tj. i one koji imaju samo osmice ili
-- samo devetke. Međutim, ako pogledamo rezultate, videćemo da za takve studente imamo NULL vrednosti
-- u odgovarajućim kolonama (npr. ako je neko imao samo devetke, tj. nije imao parnjaka u tabeli BROJ_OSMICA,
-- odgovarajući red ima oblik (NULL, NULL, broj_devetki)).
--
-- Ovo ćemo rešiti pomoću funkcije COALESCE (podsetimo se - COALESCE prihvata listu vrednosti i vraća
-- prvu vrednost iz te liste koja nije NULL).

-- Rešenje 1:

WITH BROJ_OSMICA AS (
    SELECT INDEKS, COUNT(*) AS OSMICE
    FROM DA.ISPIT
    WHERE STATUS = 'o' AND OCENA = 8
    GROUP BY INDEKS
), BROJ_DEVETKI AS (
    SELECT INDEKS, COUNT(*) AS DEVETKE
    FROM DA.ISPIT
    WHERE STATUS = 'o' AND OCENA = 9
    GROUP BY INDEKS
)
SELECT COALESCE(BO.INDEKS, BD.INDEKS) AS INDEKS,
       COALESCE(BO.OSMICE, 0) AS OSMICE,
       COALESCE(BD.DEVETKE, 0) AS DEVETKE
FROM BROJ_OSMICA AS BO FULL JOIN
     BROJ_DEVETKI AS BD ON BO.INDEKS = BD.INDEKS;

-- Objašnjenje:
--
-- Nakon obmotavanja sve tri kolone sa COALESCE, dobijamo ispravan rezultat.

-- Rešenje 2:

SELECT INDEKS,
       COUNT(CASE WHEN OCENA = 8 THEN 42 END) AS OSMICE,
       COUNT(CASE WHEN OCENA = 9 THEN 42 END) AS DEVETKE
FROM DA.ISPIT
WHERE STATUS = 'o' AND OCENA IN (8, 9)
GROUP BY INDEKS;

-- Objašnjenje:
--
-- Zadatak je zapravo bilo moguće rešiti na mnogo jednostavniji način. Doboljno je
-- samo pronaći sve položene ispite sa osmicom ili devetkom, grupisati rezultat po indeksu
-- studenta i konačno prebrojati osmice i devetke u okviru svake od grupa pomoću CASE izraza.

/*
 * 6. Studentima koji su položili neki ispit, izdvojti pored imena i prezimena,
 * naziv predmeta koji su položili iz prvog pokušaja.
 */

-- Rešenje 1:

SELECT D.IME, D.PREZIME, P.NAZIV
FROM DA.DOSIJE AS D JOIN
     DA.ISPIT AS I ON D.INDEKS = I.INDEKS JOIN
     DA.PREDMET AS P ON I.IDPREDMETA = P.ID
WHERE I.STATUS = 'o' AND I.OCENA > 5 AND -- Krenemo od toga da izvučemo sve položene ispite za studente
      NOT EXISTS ( -- Sada je samo potrebno izbaciti iz rezultata one ispite koji su polagani više puta
          SELECT *
          FROM DA.ISPIT AS IP
          WHERE (IP.INDEKS, IP.IDPREDMETA) = (I.INDEKS, I.IDPREDMETA) AND
                (IP.SKGODINA, IP.OZNAKAROKA) <> (I.SKGODINA, I.OZNAKAROKA)
      );

-- Objašnjenje:
--
-- Rešavanje ovog zadatka možemo početi od pronalaženja svih položenih predmeta za studente.
-- To dobijamo jednostavnim spajanjem tabele DOSIJE, ISPIT i PREDMET i filtriranjem po uspešno
-- položenom ispitu (status = 'o' i ocena > 5).
--
-- Ono što preostaje je da se iz ovakvog rezultata izbace oni predmeti koji nisu položeni iz prvog
-- pokušaja (za tog studenta). Ovaj uslov možemo formulisati i na sledeći način:
-- Student D je položio predmet P iz prvog pokušaja I ukoliko ne postoji polaganje IP
-- za studenta D i predmet P koje se desilo u ispitnom roku različitom od polaganja I.
--
-- Za ovakav uslov se može koristiti operator EXISTS. Poređenje da li je ispitni rok polaganja IP
-- drugačiji od polaganja I možemo da izvršimo na osnovu kolona SKGODINA i OZNAKAROKA, tj.
-- (IP.SKGODINA, IP.OZNAKAROKA) <> (I.SKGODINA, I.OZNAKAROKA)
--
-- Napomena - neko bi pokušao da prethodni uslov (različit ispitni rok) predstavi pomoću kolone
-- DATPOLAGANJA, tj. IP.DATPOLAGANJA <> I.DATPOLAGANJA. Međutim, ovde bi nastao problem usled
-- toga što DATPOLAGANJA može imati NULL vrednost, pa u tim slučajevima poređenje ne bi prošlo!

-- Rešenje 2:

WITH POLAGANJA_STUDENATA_PO_PREDMETIMA AS (
    SELECT INDEKS, IDPREDMETA,
        COUNT(*) AS BROJ_POLAGANJA,
        COUNT(CASE WHEN STATUS = 'o' AND OCENA > 5 THEN 42 END) AS POLOZEN
    FROM DA.ISPIT
    GROUP BY INDEKS, IDPREDMETA
)
SELECT D.IME, D.PREZIME, P.NAZIV
FROM POLAGANJA_STUDENATA_PO_PREDMETIMA AS PSPP JOIN
     DA.DOSIJE AS D ON PSPP.INDEKS = D.INDEKS JOIN
     DA.PREDMET AS P ON PSPP.IDPREDMETA = P.ID
WHERE BROJ_POLAGANJA = 1 AND POLOZEN = 1;

-- Objašnjenje:
--
-- Alternativno rešenje podrazumeva upotrebu pomoćne tabele u kojoj čuvamo broj polaganja
-- predmeta po studentima, uz marker da li je predmet položen. Ukoliko je BROJ_POLAGANJA = 1 i
-- marker POLOZEN = 1, onda znamo da je student položio taj predmet iz prvog pokušaja.

/*
 * 7. Izdvojiti ime i prezime studenta i naziv ispitnog roka
 * u kome student ima svoj najmanji procenat uspešnosti na ispitima.
 *
 * Izdvojiti i procenat uspešnosti na ispitima u tom roku kao decimalni broj
 * sa 2 cifre iza decimalne tačke. Procenat uspešnosti studenta u ispitnom
 * roku se računa kao procenat broja položenih ispita u odnosu na broj
 * prijavljenih ispita.
 *
 * Izdvojiti samo podatke za studente iz Aranđelovca i koji u tom roku imaju
 * najmanji procenat uspešnosti u poređenju sa ostalim studentima.
 */

-- Rešenje:

WITH USPEH_STUDENATA_PO_ROKOVIMA AS (
    SELECT INDEKS, SKGODINA, OZNAKAROKA,
           COUNT(CASE WHEN STATUS = 'o' AND OCENA > 5 THEN 42 END) * 1.0 / COUNT(*) AS USPEH
    FROM DA.ISPIT
    GROUP BY INDEKS, SKGODINA, OZNAKAROKA
)
SELECT D.IME, D.PREZIME, IR.NAZIV,
       DECIMAL(ROUND(USPR.USPEH, 2), 3, 2) AS USPEH
FROM USPEH_STUDENATA_PO_ROKOVIMA AS USPR JOIN
     DA.DOSIJE AS D ON USPR.INDEKS = D.INDEKS JOIN
     DA.ISPITNIROK AS IR ON (USPR.SKGODINA, USPR.OZNAKAROKA) = (IR.SKGODINA, IR.OZNAKAROKA) -- Potrebno zbog naziva roka
WHERE USPR.USPEH = ( -- Želimo samo onaj rok u kojem je student D ostvario svoj najmanji uspeh
          SELECT MIN(USPEH)
          FROM USPEH_STUDENATA_PO_ROKOVIMA
          WHERE INDEKS = D.INDEKS
      ) AND USPR.USPEH = ( -- Želimo samo one studente koji su ostvarili najmanji uspeh u roku IR
          SELECT MIN(USPEH)
          FROM USPEH_STUDENATA_PO_ROKOVIMA
          WHERE (SKGODINA, OZNAKAROKA) = (IR.SKGODINA, IR.OZNAKAROKA)
      ) AND D.MESTORODJENJA = 'Arandjelovac';

-- Objašnjenje:
--
-- U zadatku primećujemo da se u više navrata i u različitim kontekstima traži uspeh
-- studenta:
-- (1) Moramo da izdvojimo samo podatke o roku gde je student ostvario svoj najmanji uspeh;
-- (2) Moramo da izdvojimo i sam uspeh u tom roku;
-- (3) Traže se samo podaci za one studente koji su imali najgori uspeh u određenom roku.
--
-- Zbog ovoga, verovatno bi bilo dobro izračunati uspeh studenta po rokovima u pomoćnoj tabeli.
-- Tu tabelu onda možemo koristiti kasnije kroz glavni upit.
--
-- Računanje uspeha studenata po rokovima je relativno jednostavno - interesuje nas tabela ISPIT,
-- a grupisaćemo po indeksu (kolona INDEKS) i ispitnom roku (kolone SKGODINA i OZNAKAROKA). Nakon
-- grupisanja, samo treba da prebrojimo položene ispite u svakoj od grupa i podelimo to sa svim
-- ispitima u grupi (množenje sa 1.0 je tu radi izbegavanja celobrojnog deljenja).
--
-- Sada kada imamo pomoćnu tabelu sa uspesima studenata po rokovima, glavni upit se zadaje
-- relativno pravolinijski (par komenatara ostavljeno u samom kodu).

/*
 * 8. Za sva imena studenata izdvojiti predmete na kojima su studenti
 * sa tim imenom dobili najveću ocenu. Ukoliko su za neko ime studenti
 * sa tim imenom iz više predmeta dobili najveću ocenu, izdvojiti
 * sve takve predmete. Izdvojiti ime, naziv predmeta i dobijenu ocenu.
 *
 * Pored toga, izdvojiti takozvani dugi kod imena. Dugi kod imena dobija se na sledeći način:
 * - ukoliko je ocena koja je izdvojena uz ime nepoznata, dugi kod jeste niska 'NULL';
 * - ukoliko je ocena koja je izdvojena uz ime manja od deset, dugi kod jeste niska koja
 *   se dobija prema forumli "inicijali iz imena i naziva predmeta * ocena".
 *   Npr. ako je Mirko položio Analizu 3 sa ocenom 6, kod je 'MAMAMAMAMAMA';
 * - ukoliko je dobijena ocena deset, kod predstavlja poslednje slovo imena ponovljeno
 *   10 puta.
 * Kolonu nazvati dugi kod.
 *
 * Rezultat urediti prema imenu u opadajućem poretku.
 */

-- Prvi deo:

WITH NAJVECA_OCENA_PO_IMENU AS (
    SELECT D.IME, MAX(I.OCENA) AS MAX_OCENA
    FROM DA.DOSIJE AS D JOIN
         DA.ISPIT AS I ON D.INDEKS = I.INDEKS
    WHERE I.STATUS = 'o' AND I.OCENA > 5
    GROUP BY D.IME
)
SELECT DISTINCT D.IME, P.NAZIV, I.OCENA
FROM DA.DOSIJE AS D JOIN
     DA.ISPIT AS I ON D.INDEKS = I.INDEKS JOIN
     DA.PREDMET AS P ON I.IDPREDMETA = P.ID
WHERE I.STATUS = 'o' AND
      (D.IME, I.OCENA) IN (SELECT * FROM NAJVECA_OCENA_PO_IMENU);

-- Objašnjenje:
--
-- Fokusirajmo se za sada samo na prvi deo zadatka, tj.
-- "Za sva imena studenata izdvojiti predmete na kojima su studenti sa tim imenom dobili najveću ocenu.".
--
-- Jedan pravac u rešavanju je da napravimo pomoćnu tabelu u kojoj se, za svako
-- različito ime studenta, čuva najveća ocena koju je student sa tim imenom dobio.
-- Imati u vidu da u gornjem rešenju fale studenti koji nisu položili ništa.
--
-- Nakon toga, u glavnom upitu jednostavno izvučemo sve položene predmete za svakog studenta,
-- nakon čega zadržavamo samo one gde je predmet položen sa ocenom koja je najveća za njegovo ime
-- (tu informaciju imamo u pomoćnoj tabeli).
--
-- Pošto spajamo tabelu DOSIJE sa tabelom ISPIT, moguće je da su dva različita studenta (različiti indeksi)
-- sa istim imenom položila isti predmet sa najvećom ocenom. Npr.
-- Petar, 20150001 je položio Programiranje 1 sa ocenom 10, i
-- Petar, 20150002 je položio Programiranje 1 sa ocenom 10.
-- Da bi se rešili dupliranih redova, koristimo DISTINCT.

-- Drugi deo:

WITH NAJVECA_OCENA_PO_IMENU AS (
    SELECT D.IME, MAX(I.OCENA) AS MAX_OCENA
    FROM DA.DOSIJE AS D JOIN
         DA.ISPIT AS I ON D.INDEKS = I.INDEKS
    WHERE I.STATUS = 'o' AND I.OCENA > 5
    GROUP BY D.IME
)
SELECT D.IME, P.NAZIV, I.OCENA
FROM DA.DOSIJE AS D JOIN
     DA.ISPIT AS I ON D.INDEKS = I.INDEKS JOIN
     DA.PREDMET AS P ON I.IDPREDMETA = P.ID
WHERE I.STATUS = 'o' AND
      (D.IME, I.OCENA) IN (SELECT * FROM NAJVECA_OCENA_PO_IMENU)
UNION
SELECT D.IME, NULL, NULL
FROM DA.DOSIJE AS D
WHERE D.IME NOT IN (SELECT IME FROM NAJVECA_OCENA_PO_IMENU);

-- Objašnjenje:
--
-- Do sada nismo vodili računa o studentima, tj. imenima studenata, koji nisu položili ništa.
-- Da bi dodali i njih u rezultat, možemo napraviti uniju. Smatramo da za neko ime studenta
-- nema položenog ispita ukoliko se to ime ne nalazi u našoj pomoćnoj tabeli.
--
-- Pošto sada koristimo operator UNION, koji uklanja duplikate, možemo ukloniti i DISTINCT iz
-- prvog dela upita.

-- Rešenje:

WITH NAJVECA_OCENA_PO_IMENU AS (
    SELECT D.IME, MAX(I.OCENA) AS MAX_OCENA
    FROM DA.DOSIJE AS D JOIN
         DA.ISPIT AS I ON D.INDEKS = I.INDEKS
    WHERE I.STATUS = 'o' AND I.OCENA > 5
    GROUP BY D.IME
)
SELECT D.IME, P.NAZIV, I.OCENA,
       CASE
           WHEN I.OCENA < 10 THEN REPEAT(SUBSTR(D.IME, 1, 1) || SUBSTR(P.NAZIV, 1, 1), I.OCENA)
           WHEN I.OCENA = 10 THEN REPEAT(SUBSTR(D.IME, LENGTH(D.IME), 1), 10)
       END AS DUGI_KOD
FROM DA.DOSIJE AS D JOIN
     DA.ISPIT AS I ON D.INDEKS = I.INDEKS JOIN
     DA.PREDMET AS P ON I.IDPREDMETA = P.ID
WHERE I.STATUS = 'o' AND
      (D.IME, I.OCENA) IN (SELECT * FROM NAJVECA_OCENA_PO_IMENU)
UNION
SELECT D.IME, NULL, NULL, 'NULL' AS DUGI_KOD
FROM DA.DOSIJE AS D
WHERE D.IME NOT IN (SELECT IME FROM NAJVECA_OCENA_PO_IMENU)
ORDER BY IME DESC;

-- Objašnjenje:
--
-- Konačno, jedino što je ostalo je određivanje dugog koda i sortiranje.
-- Korisna funkcija za ovo je funkcija REPEAT koja, kao prvi argument, prihvata neku nisku,
-- a kao drugi argument prihvata broj ponavljanja. Rezultat je niska ponovljena određeni
-- broj puta (npr. REPEAT('abc', 3) = 'abcabcabc').
