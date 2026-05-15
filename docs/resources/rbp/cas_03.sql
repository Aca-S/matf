/*
 * 1. Izdvojiti nazive predmeta koje je POLAGAO student sa indeksom 22/2017.
 */

-- Rešenje 1:

SELECT P.NAZIV
FROM DA.ISPIT AS I JOIN
     DA.PREDMET AS P ON P.ID = I.IDPREDMETA
WHERE I.INDEKS = 20170022 AND
      I.STATUS NOT IN ('p', 'n');

-- Objašnjenje:
--
-- Rešenje zasnovano na spajanju tabela - nalazimo sve ispite studenta 20170022 i
-- izbacujemo one ispite koji imaju status p (prijavljen) ili n (nije izašao), tj.
-- zadržavamo samo one ispite koje je student zapravo polagao.
-- Spajanje sa tabelom DA.PREDMET koristimo radi izvlačenja naziva predmeta.

-- Pokušaj na drugačiji način:

-- Naime, u rešavanju ovog zadatka možemo primetiti sledeće - mi zapravo želimo
-- sve predmete čiji se identifikator nalazi u skupu predmeta koje je polagao
-- student sa indeksom 20170022. Te predmete ćemo lako naći u tabeli DA.ISPIT:

SELECT IDPREDMETA
FROM DA.ISPIT
WHERE INDEKS = 20170022 AND
      STATUS NOT IN ('p', 'n');

-- Rezultat ovog upita su identifikatori (2170, 1580, 2174). Sada kada ih imamo,
-- možemo lako izvući i odgovarajuće predmete sledećim upitom:

SELECT P.NAZIV
FROM DA.PREDMET AS P
WHERE P.ID IN (2170, 1580, 2174);

-- Ovaj upit daje ono rešenje koje smo i očekivali. Međutim, da bismo ga napravili,
-- pre njega smo morali da izvršimo drugi upit. Da li je nekako moguće spojiti ova
-- dva upita? Odgovor je potvrdan, i to zahvaljujući PODUPITIMA!

-- Rešenje 2:

SELECT P.NAZIV
FROM DA.PREDMET AS P
WHERE P.ID IN (
    -- Primetimo: ovo je "prvi" upit iz prethodnog pokušaja
    SELECT IDPREDMETA
    FROM DA.ISPIT
    WHERE INDEKS = 20170022 AND
          STATUS NOT IN ('p', 'n')
);

-- Objašnjenje:
--
-- Već smo videli primere gde kao desni operand operatora IN prosleđujemo nekakvu listu,
-- konstanti. Međutim, ta lista uopšte ne mora biti fiksirana takav način - ona se može
-- dobiti i kao rezultat izvršavanja nekog drugog upita, tj. podupita. Jedino što je bitno
-- je da taj podupit, kao rezultat, vraća skup vrednosti istog tipa kao i vrednost sa leve
-- strane operatora (u našem slučaju, to je vrednost P.ID).
--
-- Podupite ćemo navoditi u okviru ( ... ) zagrada i oni se, u zavisnosti od strukture rezultata
-- njihovog izvršavanja, mogu koristiti na različitim mestima. Uglavnom će to biti u okviru
-- WHERE-a, ali viđaćemo situacije (i narednih časova) u kojima se podupiti koriste i u okviru
-- FROM-a, SELECT-a i slično.

-- Rešenje 3:

SELECT P.NAZIV
FROM DA.PREDMET AS P
WHERE 20170022 IN (
    SELECT INDEKS
    FROM DA.ISPIT
    WHERE STATUS NOT IN ('p', 'n') AND
          IDPREDMETA = P.ID
);

-- Objašnjenje
--
-- Možemo rešiti ovaj zadatak i na malo drugačiji način. U ovakvom slučaju u suštini
-- za svaki predmet ponaosob proveravamo da li se indeks 20170022 nalazi u skupu
-- polaganja tog predmeta.
--
-- Međutim, postavlja se pitanje - koje od ova dva rešenja (rešenje 2 i rešenje 3) je
-- bolje? Primetimo sledeće - u rešenju 2, u podupitu se nigde ne referiše na tabelu
-- P iz spoljnjeg (glavnog) upita, dok u rešenju 3 imamo proveru IDPREDMETA = P.ID u
-- podupitu. Ovo znači da podupit iz rešenja 2 uvek ima isti rezultat i može se izvršiti
-- nezavisno od glavnog, spoljnjeg upita, dok podupit iz ovog rešenja mora da se izvrši
-- ponovo za svaki predmet iz tabele P! Iz ovog razloga, preferiramo rešenje 2, zato
-- što bi ono (bar u teoriji) trebalo da bude efikasnije (linearna složenost izvršavanja,
-- tj. O(|P|+|I|), naspram kvadratne složenosti, tj. O(|P|*|I|)).
--
-- Podupit koji ne referiše na tabele iz spoljnjeg upita, poput onog iz rešenja 2,
-- zove se NEKORELISANI podupit. Onaj koji referiše na tabele iz spoljnjeg upita,
-- poput ovog u rešenju 3, zove se KORELISANI podupit. Ukoliko je to moguće, poželjno
-- je izbegavati korelisane podupite.
--
-- Mali "disclaimer": U praksi, optimizatori modernih sistema za uprvaljanje bazom podataka
-- su dosta "pametni", pa, bar za ovako jednostavne upite, uspevaju da generišu podjednako
-- dobar plan izvršavanja i za korelisane i za nekorelisane upite. Svakako, ne treba se uvek
-- oslanjati na to da će optimizator upita odraditi dobar posao.

/*
 * 2. Izdvojiti ime i prezime studenta koji ima ispit položen sa ocenom 9.
 */

-- Rešenje 1:

SELECT DISTINCT D.IME, D.PREZIME
FROM DA.ISPIT AS I JOIN
     DA.DOSIJE AS D ON I.INDEKS = D.INDEKS
WHERE I.OCENA = 9 AND I.STATUS = 'o';

-- Objašnjenje:
--
-- Jednostavno rešenje zasnovano na spajanju. Duplikate (jedan student je možda položio više
-- ispita sa devetkom) uklanjamo sa DISTINCT.

-- Rešenje 2:

SELECT D.IME, D.PREZIME
FROM DA.DOSIJE AS D
WHERE D.INDEKS IN (
    SELECT I.INDEKS
    FROM DA.ISPIT AS I
    WHERE I.OCENA = 9 AND I.STATUS = 'o'
);

-- Objašnjenje:
--
-- Pravimo nekorelisani podupit koji vraća sve ispite položene sa devetkom, a onda proveravamo
-- da li se indeks studenta nalazi u skupu tih ispita.
--
-- Primetimo da su rezultati izvršavanja upita iz rešenja 1 i rešenja 2 drugačiji - onaj upit
-- iz rešenja 1 vraća nešto manje redova od rešenja zasnovanog na podupitu. Zašto? Razlog su
-- duplikati u imenima i prezimenima - postoje različiti studenti (sa drugim ispitom) koji imaju
-- isto ime i prezime. Rešenje 1 uklanja takve slučajeve, dok ih rešenje 2 zadržava.

/*
 * 3. Izdvojiti indekse studenata koji su položili bar jedan predmet koji nije položio student
 * sa indeksom 22/2017.
 */

-- Rešenje 1:

SELECT DISTINCT I1.INDEKS
FROM DA.ISPIT AS I1
WHERE I1.OCENA > 5 AND I1.STATUS = 'o' AND
      I1.IDPREDMETA NOT IN (
          SELECT I2.IDPREDMETA
          FROM DA.ISPIT AS I2
          WHERE I2.INDEKS = 20170022 AND
                I2.OCENA > 5 AND I2.STATUS = 'o'
      );

-- Objašnjenje:
--
-- Podupitom ćemo naći identifikatore predmeta za sve ispite koje je položio student
-- 22/2017, nakon čega u glavnom podupitu samo dohvatamo sve položene ispite (nevezano
-- za kog studenta) i zadržavamo samo one koji se ne nalaze u rezultatu podupita.
--
-- DISTINCT je tu da bi uklonili duplikate (isti student je možda položio više od jednog
-- ispita koje nije položio student 22/2017, pa bi se bez DISTINCT njegov indeks javio
-- više puta u rezultatu).

-- Rešenje 2:

SELECT DISTINCT INDEKS
FROM DA.ISPIT
WHERE OCENA > 5 AND STATUS = 'o' AND
      IDPREDMETA NOT IN (
          SELECT IDPREDMETA
          FROM DA.ISPIT
          WHERE INDEKS = 20170022 AND
                OCENA > 5 AND STATUS = 'o'
      );

-- Objašnjenje:
--
-- Struktura rešenja je ista kao i rešenje 1, samo što ovde ne koristimo alias-e za tabele (I1 i I2).
-- Naime, u slučaju podupita gde imamo ista imena kolona kao i u spoljnjem upitu, prioritet imaju
-- tabele iz podupita, pa u ovom slučaju nije neophodno postaviti alias za tabele da bi se izbegle
-- kolizije.

/*
 * 4. Korišćenjem egzistencijalnog kvantifikatora exists izdvojiti nazive predmeta koje je
 * položio student sa indeksom 22/2017.
 */

-- Rešenje:

SELECT NAZIV
FROM DA.PREDMET
WHERE EXISTS (
    SELECT *
    FROM DA.ISPIT
    WHERE IDPREDMETA = ID AND
          INDEKS = 20170022 AND
          OCENA > 5 AND STATUS = 'o'
);

-- Objašnjenje:
--
-- Prethodni zadatak možemo preformulisati i na sledeći način:
-- Izdvojiti nazive predmeta ZA KOJE POSTOJI student sa indeksom 22/2017 koji je položio taj predmet.
--
-- Ili, još preciznije:
-- Izdvojiti nazive predmeta ZA KOJE POSTOJI uspešno polaganje tog predmeta od strane studenta sa indeksom 22/2017.
--
-- Sada se možemo upoznati sa operatorom EXISTS. Naime, ovaj operator prihvata podupit kao
-- operand i vraća TRUE ako rezultat podupita nije prazan (sadrži barem jedan red, kakav god
-- taj red bio), a FALSE u suprotnom. Upravo ovo odgovara značenju "postojanja" - ako rezultat
-- podupita kojim tražimo uspešna polaganja nekog predmeta za studenta 22/2017 nije prazan,
-- onda takvo polaganje očigledno postoji. Ako je rezultat podupita prazan, onda ono ne postoji.

/*
 * 5. Izdvojiti nazive predmeta čiji je kurs organizovan u svim školskim godinama
 * o kojima postoje podaci u bazi podataka.
 */

-- Rešenje 1:

SELECT P.NAZIV
FROM DA.PREDMET AS P
WHERE NOT EXISTS (
    SELECT *
    FROM DA.SKOLSKAGODINA AS SG
    WHERE NOT EXISTS (
        SELECT *
        FROM DA.KURS AS K
        WHERE K.IDPREDMETA = P.ID AND K.SKGODINA = SG.SKGODINA
    )
);

-- Objašnjenje:
--
-- Za rešavanje ovog zadatka, potrebno je nekako postaviti uslov da je kurs iz predmeta
-- organizovan u SVIM školskim godinama. Na žalost, u SQL-u nemamo način da direktno
-- predstavimo ovakav uslov (nema FOR ALL operatora). Međutim, ono što je moguće
-- uraditi je "simulirati" ovaj operator pomoću operatora EXISTS!
--
-- Naime, prethodni zadatak je moguće preformulisati na sledeći način:
-- Izdvojiti nazive predmeta za koje NE POSTOJI školska godina u kojoj kurs za
-- taj predmet NIJE organizovan.
--
-- Iako je intuitivno jasno da su ove dve formulacije zadatka ekvivalentne,
-- formalno opravdanje se može naći u logici prvog reda:
-- ∀x.P(x) ≡ ~∃x.~P(x)
--
-- Prema tome, uvek kada imamo uslov ovog tipa, možemo se rukovoditi time da je
-- SVAKI isto što i NE POSTOJI NEKI KOJI NIJE. Predlog je uvek prvo preformulisati
-- zahtev u (ekvivalentnim) terminima koje možemo izraziti SQL-om, pa tek onda preći
-- na implementaciju samog upita.
--
-- Na primeru ovog zadatka:
--
-- (1) Izdvojiti nazive predmeta čiji je kurs organizovan u svim školskim godinama
-- o kojima postoje podaci u bazi podataka.
-- <je isto što i>
-- (2) Izdvojiti nazive predmeta za koje ne postoji školska godina u kojoj kurs za
-- taj predmet nije organizovan.
-- <je isto što i>
-- (3) Izdvojiti nazive predmeta za koje ne postoji školska godina u kojoj ne postoji
-- kurs za taj predmet.
--
-- Nakon ovakve formulacije zahteva, implementacija samog upita je potpuno pravolonijska.

-- Rešenje 2:

SELECT P.NAZIV
FROM DA.PREDMET AS P
WHERE NOT EXISTS (
    SELECT *
    FROM DA.SKOLSKAGODINA AS SG
    WHERE P.ID NOT IN (
        SELECT K.IDPREDMETA
        FROM DA.KURS AS K
        WHERE K.SKGODINA = SG.SKGODINA
    )
);

-- Objašnjenje:
--
-- Alternativno rešenje u kojem se samo umesto unutrašnjeg EXISTS operatora koristi IN operator.
-- Osim toga, oba rešenja su ekvivalentna i iste efikasnosti.
--
-- "Izdvojiti nazive predmeta za koje ne postoji školska godina u kojoj se identifikator tog predmeta
-- ne nalazi u skupu identifikatora organizovanih kurseva za tu godinu."

-- Rešenje 3:

SELECT P.NAZIV
FROM DA.PREDMET AS P
WHERE NOT EXISTS (
    SELECT *
    FROM DA.SKOLSKAGODINA AS SG
    WHERE SG.SKGODINA NOT IN (
        SELECT K.SKGODINA
        FROM DA.KURS AS K
        WHERE K.IDPREDMETA = P.ID
    )
);

-- Objašnjenje:
--
-- Slično kao i prethodno rešenje, samo što su ID predmeta i školska godina obrnuli uloge u podupitima.
--
-- "Izdvojiti nazive predmeta za koje ne postoji školska godina koja se ne nalazi u skupu školskih godina
-- u kojima je kurs iz tog predmeta održan."
--
-- Mala zanimljivost - ovo rešenje je zapravo najgore efikasnosti od sva tri! Možete proveriti to izvršavanjem sve
-- tri varijante upita i poređenjem njihovog vremena izvršavanja (u Session > Output prozoru u DataGrip okruženju).
-- O razlogu iza ovoga (indeksi) biće više reči na osmom času.

/*
 * 6. Izdvojiti podatke o studentima koji su upisali sve školske godine
 * o kojima postoje podaci u bazi podataka.
 */

-- Rešenje 1:

SELECT D.*
FROM DA.DOSIJE AS D
WHERE NOT EXISTS (
    SELECT *
    FROM DA.SKOLSKAGODINA AS SK
    WHERE NOT EXISTS (
        SELECT *
        FROM DA.UPISGODINE AS UG
        WHERE UG.INDEKS = D.INDEKS AND UG.SKGODINA = SK.SKGODINA
    )
);

-- Objašnjenje:
--
-- (1) Izdvojiti podatke o studentima koji su upisali sve školske godine
-- o kojima postoje podaci u bazi podataka.
-- <je isto što i>
-- (2) Izdvojiti podatke o studentima za koje ne postoji školska godina
-- u kojoj se nisu upisali.
-- <je isto što i>
-- (3) Izdvojiti podatke o studentima za koje ne postoji školska godina
-- u kojoj ne postoji upis godine za tog studenta.

-- Rešenje 2:

SELECT D.*
FROM DA.DOSIJE AS D
WHERE NOT EXISTS (
    SELECT *
    FROM DA.SKOLSKAGODINA AS SK
    WHERE D.INDEKS NOT IN (
        SELECT UG.INDEKS
        FROM DA.UPISGODINE AS UG
        WHERE UG.SKGODINA = SK.SKGODINA
    )
);

-- Objašnjenje:
--
-- Isti princip kao prethodni primer.

-- Rešenje 3:

SELECT D.*
FROM DA.DOSIJE AS D
WHERE NOT EXISTS (
    SELECT *
    FROM DA.SKOLSKAGODINA AS SK
    WHERE SK.SKGODINA NOT IN (
        SELECT UG.SKGODINA
        FROM DA.UPISGODINE AS UG
        WHERE UG.INDEKS = D.INDEKS
    )
);

-- Objašnjenje:
--
-- Isti princip kao prethodni primer. Opet, i ovo je najneefikasnije rešenje!

/*
 * 7. Izdvojiti indekse studenata koji su polagali u svim ispitnim rokovima.
 */

-- Rešenje:

SELECT D.INDEKS
FROM DA.DOSIJE AS D
WHERE NOT EXISTS (
    SELECT *
    FROM DA.ISPITNIROK AS IR
    WHERE NOT EXISTS (
        SELECT *
        FROM DA.ISPIT AS I
        WHERE I.INDEKS = D.INDEKS AND
              I.SKGODINA = IR.SKGODINA AND
              I.OZNAKAROKA = IR.OZNAKAROKA AND
              I.STATUS NOT IN ('p', 'n')
    )
);

-- Objašnjenje:
--
-- (1) Izdvojiti indekse studenata koji su polagali u svim ispitnim rokovima.
-- <je isto što i>
-- (2) Izdvojiti indekse studenata za koje ne postoji ispitni rok u kojem nisu polagali.
-- <je isto što i>
-- (3) Izdvojiti indekse studenata za koje ne postoji ispitni rok u kojem ne postoji
-- polagani (status nije p - prijavljen ili n - nije izašao) ispit tog studenta.

/*
 * 8. Izdvojiti indekse studenata koji su polagali u svim ispitnim rokovima održanim u 2018/2019. šk. godini.
 */

-- Rešenje:

SELECT D.INDEKS
FROM DA.DOSIJE AS D
WHERE NOT EXISTS (
    SELECT *
    FROM DA.ISPITNIROK AS IR
    WHERE IR.SKGODINA = 2018 AND NOT EXISTS (
        SELECT *
        FROM DA.ISPIT AS I
        WHERE I.INDEKS = D.INDEKS AND
              I.SKGODINA = IR.SKGODINA AND
              I.OZNAKAROKA = IR.OZNAKAROKA AND
              I.STATUS NOT IN ('p', 'n')
    )
);

-- Objašnjenje:
--
-- Isto kao i prethodni primer, samo smo se ograničili na ispitne rokove u SKGODINA = 2018.
-- "Izdvojiti indekse studenata za koje ne postoji ispitni rok iz 2018. u kojem nisu polagali."

/*
 * 9. Izdvojiti podatke o predmetima sa najvećim brojem espb bodova.
 */

-- Rešenje 1:

SELECT *
FROM DA.PREDMET AS P
WHERE NOT EXISTS (
    SELECT *
    FROM DA.PREDMET AS PP
    WHERE PP.ESPB > P.ESPB
);

-- Objašnjenje:
--
-- Predmet sa najvećim brojem espb je onaj predmet za koji ne postoji predmet koji
-- nosi više espb od njega.

-- Rešenje 2:

SELECT *
FROM DA.PREDMET
WHERE ESPB >= ALL (
    SELECT ESPB
    FROM DA.PREDMET
);

-- Objašnjenje:
--
-- Jedna od alternativa upotrebi operatora EXISTS u ovom slučaju je upotreba operatora ALL.
-- Slično kao i operatori EXISTS ili IN, operator ALL prihvata podupit sa desne strane koji
-- vraća nekakvu listu vrednosti. Sa leve strane operatora navodi se vrednost i operator poređenja
-- (<, >, =, >=, <=, <>). Rezultat izvršavanja operatora ALL je TRUE ukoliko je poređenje vrednosti
-- sa leve strane, u skladu sa navedenim operatorom, uspešno (vraća TRUE) sa SVIM vrednostima
-- iz liste vrednosti koju je vratio podupit. U suprotnom, rezultat je FALSE.
--
-- U ovom slučaju, podupit vraća listu ESPB svih predmeta. Predikat u WHERE delu upita
-- vraća TRUE za svaki predmet čiji je broj ESPB veći ili jednak svim ESPB iz liste koju je vratio podupit,
-- a to su upravo predmeti "Izdrada doktorske disertacije" 1, 2 i 3 sa svojih 30 ESPB.
--
-- Napomena - za razliku od IN operatora, ALL prihvata samo podupit sa desne strane - ne možemo
-- direktno navesti listu nekih fiksiranih vrednosti.

/*
 * 10. Izdvojiti podatke o studentima sa najranijim datumom diplomiranja.
 */

-- Neuspešan pokušaj 1:

SELECT *
FROM DA.DOSIJE AS D
WHERE NOT EXISTS (
    SELECT *
    FROM DA.DOSIJE AS DP
    WHERE DP.DATDIPLOMIRANJA < D.DATDIPLOMIRANJA
);

-- Objašnjenje:
--
-- Ovaj upit je naizgled korektan - student sa najranijim datumom diplomiranja je onaj za
-- kojeg ne postoji neki student sa ranijim datumom diplomiranja od njega, slično kao i u
-- prethodnom primeru. Međutim, kada izvršimo ovaj upit, dobijemo preko 3000 studenata u
-- rezultatu. To sigurno nije tačno. Šta se zapravo desilo?
--
-- Problem nastaje u tome što smo sa ovakvim upitom zapravo dobili i sve studente koji
-- nemaju datum diplomiranja, tj. DATDIPLOMIRANJA ima NULL vrednost. Ovo se desilo zato
-- što za takve studente, u podupitu, onda imamo poređenje oblika
-- "WHERE DP.DATDIPLOMIRANJA < NULL"!
-- Već znamo da bilo kakvo poređenje sa NULL (van IS NULL / IS NOT NULL) ponovo vraća
-- NULL vrednost. Prema tome, rezultat prethodnog poređenja je onda WHERE NULL za
-- svakog studenta koji nema datum diplomiranja. Iz tog razloga, podupit uvek vraća
-- prazan rezultat za takve studente, te NOT EXISTS vraća TRUE.

-- Rešenje 1:

SELECT *
FROM DA.DOSIJE AS D
WHERE NOT EXISTS (
    SELECT *
    FROM DA.DOSIJE AS DP
    WHERE DP.DATDIPLOMIRANJA < D.DATDIPLOMIRANJA
) AND D.DATDIPLOMIRANJA IS NOT NULL;

-- Objašnjenje:
--
-- Problem iz prethodnog pokušaja možemo rešiti jednostavnim dodavanjem dodatne provere za studente:
-- Želimo sve studente SA POZNATIM DATUMOM DIPLOMIRANJA za koje ne postoji neki student sa ranijim
-- datumom diplomiranja od njega.
-- Kao rezultat sada dobijamo jednog studenta sa datumom diplomiranja 2016-06-17!

-- Neuspešan pokušaj 2 (pokušaj sa ALL):

SELECT *
FROM DA.DOSIJE
WHERE DATDIPLOMIRANJA <= ALL (
    SELECT DATDIPLOMIRANJA
    FROM DA.DOSIJE
);

-- Objašnjenje:
--
-- Pokušajmo da rešimo zadatak pomoću operatora ALL - želimo studente čiji je datum diplomiranja
-- manji ili jednak datumima diplomiranja svih studenata.
--
-- Međutim, ako probamo da izvršimo ovakav upit, dobijamo prazan rezultat - zašto?
-- Problem je opet u NULL vrednostima. Neki od studenata iz podupita imaju nepoznat (NULL)
-- datum diplomiranja. Zbog toga imamo poređenje oblika:
-- WHERE DATDIPLOMIRANJA <= ALL (..., NULL, ...). Poređenje DATDIPLOMIRANJA <= NULL vraća
-- NULL kao rezultat, te je rezultat celog poređenja sa ALL takođe NULL, te ne vraćamo ni
-- jednog studenta kao rezultat!

-- Rešenje 2:

SELECT *
FROM DA.DOSIJE
WHERE DATDIPLOMIRANJA <= ALL (
    SELECT DATDIPLOMIRANJA
    FROM DA.DOSIJE
    WHERE DATDIPLOMIRANJA IS NOT NULL
);

-- Objašnjenje:
--
-- Rešenje za prethodni problem je samo dodavanje provere da DATDIPLOMIRANJA nije NULL
-- u podupitu!

/*
 * 11. Izdvojiti podatke o svim studentima osim onih sa najranijim datumom diplomiranja.
 */

-- Rešenje 1:

SELECT *
FROM DA.DOSIJE AS D
WHERE EXISTS (
    SELECT *
    FROM DA.DOSIJE AS DP
    WHERE DP.DATDIPLOMIRANJA < D.DATDIPLOMIRANJA
) OR D.DATDIPLOMIRANJA IS NULL;

-- Objašnjenje:
--
-- Suštinski samo negacija od prethodnog primera (više nije NOT EXISTS, već EXISTS). Želimo
-- da zadržimo sve studente za koje postoji neki student sa ranijim datumom diplomiranja. Uz to
-- dodajemo i sve studente sa NULL datumom diplomiranja.

-- Rešenje 2:

SELECT *
FROM DA.DOSIJE
WHERE NOT DATDIPLOMIRANJA <= ALL (
    SELECT DATDIPLOMIRANJA
    FROM DA.DOSIJE
    WHERE DATDIPLOMIRANJA IS NOT NULL
) OR DATDIPLOMIRANJA IS NULL;

-- Objašnjenje:
--
-- Isti princip - samo negacija prethodnog rešenja.

-- Rešenje 3:

SELECT *
FROM DA.DOSIJE
WHERE DATDIPLOMIRANJA > SOME (
    SELECT DATDIPLOMIRANJA
    FROM DA.DOSIJE
) OR DATDIPLOMIRANJA IS NULL;

-- Objašnjenje:
--
-- Ovde ćemo se upoznati sa operatorom SOME. Ideja je slična kao kod operatora ALL
-- (isto imamo podupit sa desne strane, sa leve neku vrednost i operator poređenja).
-- Razlika je u tome što ovaj operator vraća TRUE ukoliko je BILO KOJE poređenje leve
-- vrednosti sa onim vrednostima iz liste koju vraća podupit tačno.
--
-- Ovaj upit se onda prevodi na:
-- Želimo sve studente čiji je datum diplomiranja nepoznat ili je veći od bar jednog
-- (bilo kog) datuma diplomiranja koji su poznati.
--
-- Napomena - umesto operatora SOME može se koristiti i operator ANY. Sinonimi su.

/*
 * 12. Izdvojiti podatke o predmetima koje su upisali neki studenti.
 */

-- Rešenje 1:

SELECT P.*
FROM DA.PREDMET AS P
WHERE EXISTS (
    SELECT *
    FROM DA.UPISANKURS AS UK
    WHERE UK.IDPREDMETA = P.ID
);

-- Rešenje 2:

SELECT *
FROM DA.PREDMET
WHERE ID IN (
    SELECT IDPREDMETA
    FROM DA.UPISANKURS
);

-- Rešenje 3:

SELECT *
FROM DA.PREDMET
WHERE ID = ANY (
    SELECT IDPREDMETA
    FROM DA.UPISANKURS
);

-- Objašnjenje:
--
-- X = ANY (...), tj. X = SOME (...) je ekvivalentno sa X IN (...)!

/*
 * 13. Za studente koji su polagali neki ispit u ispitnom roku održanom u 2018/2019. šk. godini
 * izdvojiti podatke o svim (ne samo u 2018/2019.) položenim ispitima.
 * Izdvojiti indeks, ime, prezime studenta, naziv položenog predmeta, oznaku ispitnog roka
 * i školsku godinu u kojoj je ispit položen.
 */

-- Rešenje:

SELECT D.INDEKS, D.IME, D.PREZIME,
       P.NAZIV,
       I.OZNAKAROKA, I.SKGODINA
FROM DA.DOSIJE AS D JOIN
     DA.ISPIT AS I ON D.INDEKS = I.INDEKS JOIN
     DA.PREDMET AS P ON I.IDPREDMETA = P.ID
WHERE I.OCENA > 5 AND I.STATUS = 'o' AND EXISTS (
    SELECT *
    FROM DA.ISPIT AS IP
    WHERE IP.INDEKS = D.INDEKS AND
          IP.SKGODINA = 2018 AND
          IP.STATUS NOT IN ('p', 'n')
);

/*
 * 14. Izdvojiti podatke o predmetima koje su polagali svi studenti iz Berana koji studiraju smer sa oznakom I.
 */

-- Rešenje:

SELECT P.*
FROM DA.PREDMET AS P
WHERE NOT EXISTS (
    SELECT *
    FROM DA.DOSIJE AS D JOIN
         DA.STUDIJSKIPROGRAM AS SP ON D.IDPROGRAMA = SP.ID
    WHERE D.MESTORODJENJA = 'Berane' AND SP.OZNAKA = 'I' AND NOT EXISTS (
        SELECT *
        FROM DA.ISPIT AS I
        WHERE I.INDEKS = D.INDEKS AND
              I.IDPREDMETA = P.ID AND
              I.STATUS NOT IN ('p', 'n')
    )
);

-- Objašnjenje:
--
-- Ako preformulišemo zadatak, dobijamo:
-- Izdvojiti podatke o predmetima za koje ne postoji student iz Berana sa I smera koji ga nije polagao.
--
-- Još preciznije, dobijamo:
-- Izdvojiti podatke o predmetima za koje ne postoji student iz Berana sa I smera za kog ne postoji
-- polagani (status nije p ili n) ispit iz tog predmeta.
