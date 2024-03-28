DROP DATABASE IF EXISTS atletski_savez;
CREATE DATABASE atletski_savez;

-- Mogli smo i da pozovemo USE atletski_savez; da ne bi morali svuda da navodimo ime baze

CREATE TABLE atletski_savez.takmicenje
(
	sifra INT PRIMARY KEY,
	naziv VARCHAR(40) NOT NULL,
	datum_pocetka DATE NOT NULL
);

CREATE TABLE atletski_savez.disciplina
(
	sifra INT PRIMARY KEY,
	naziv VARCHAR(40) NOT NULL,
	rekord SMALLINT DEFAULT 0 CHECK (rekord BETWEEN 0 AND 100) NOT NULL
);

-- U zadatku nije bas najjasnije naznaceno preko kog dodatnog atributa se, uz sifru takmicenja,
-- jedinstveno identifikuje borba. Ovde je izabrano da to bude stepen (samo jedna borba datog stepena
-- se odrzava u okviru takmicenja) da bi se pokazala upotreba UNIQUE-a.

CREATE TABLE atletski_savez.borba
(
	sifra_takmicenja INT,
	stepen VARCHAR(4) CHECK (stepen IN ('I', 'II', 'III', 'IV')),
	sifra_discipline INT NOT NULL,
	datum DATE NOT NULL,
	rezultat INT NOT NULL CHECK (rezultat BETWEEN 0 AND 100),
	PRIMARY KEY (sifra_takmicenja, stepen),
	UNIQUE (sifra_takmicenja, datum),
	CONSTRAINT fk_takmicenje FOREIGN KEY (sifra_takmicenja) REFERENCES atletski_savez.takmicenje(sifra)
		ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT fk_disciplina FOREIGN KEY (sifra_discipline) REFERENCES atletski_savez.disciplina(sifra)
		ON DELETE CASCADE ON UPDATE CASCADE
);
