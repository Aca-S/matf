CREATE TABLE Student
(
	indeks CHAR(9) PRIMARY KEY NOT NULL,
	ime VARCHAR(40) NOT NULL,
	prezime VARCHAR(40) NOT NULL
);

CREATE TABLE Sportista
(
	indeks CHAR(9) PRIMARY KEY NOT NULL,
	sport VARCHAR(30) NOT NULL,
	godina SMALLINT DEFAULT 0,
	nivo VARCHAR(20) DEFAULT 'amater',
	CONSTRAINT fk_sportista_indeks FOREIGN KEY (indeks) REFERENCES Student(indeks)
		ON DELETE CASCADE ON UPDATE RESTRICT
);

CREATE TABLE Muzicar
(
	indeks CHAR(9) PRIMARY KEY NOT NULL,
	instrument VARCHAR(30) NOT NULL,
	CONSTRAINT fk_muzicar_indeks FOREIGN KEY (indeks) REFERENCES Student(indeks)
		ON DELETE CASCADE ON UPDATE RESTRICT
);

CREATE TABLE Umetnik
(
	indeks CHAR(9) PRIMARY KEY NOT NULL,
	tip VARCHAR(30) NOT NULL,
	CONSTRAINT fk_umetnik_indeks FOREIGN KEY (indeks) REFERENCES Student(indeks)
		ON DELETE CASCADE ON UPDATE RESTRICT
);

--#SET TERMINATOR @

CREATE TRIGGER Sportista_update BEFORE UPDATE ON Sportista
REFERENCING NEW AS n OLD AS o
FOR EACH ROW
BEGIN ATOMIC
	SET n.nivo = CASE
		WHEN n.godina < 2 THEN 'amater'
		WHEN n.godina < 5 THEN 'pocetnik'
		ELSE 'profesionalac'
	END;
END@

--#SET TERMINATOR ;

CREATE VIEW Studenti_zanimanja AS
SELECT	st.indeks, st.ime, st.prezime,
		s.sport, s.godina, s.nivo,
		m.instrument, u.tip
FROM	Student AS st LEFT JOIN
		Sportista AS s ON st.indeks = s.indeks LEFT JOIN
		Muzicar AS m ON st.indeks = m.indeks LEFT JOIN
		Umetnik AS u ON st.indeks = u.indeks;
		
--#SET TERMINATOR @

CREATE TRIGGER Studenti_zanimanja_insert INSTEAD OF INSERT ON Studenti_zanimanja
REFERENCING NEW AS n
FOR EACH ROW
BEGIN ATOMIC
	INSERT INTO Student VALUES
		(n.indeks, n.ime, n.prezime);
	IF n.sport IS NOT NULL THEN
		INSERT INTO Sportista VALUES
			(n.indeks, n.sport, n.godina, n.nivo);
	END IF;
	IF n.instrument IS NOT NULL THEN
		INSERT INTO Muzicar VALUES
			(n.indeks, n.instrument);
	END IF;
	IF n.tip IS NOT NULL THEN
		INSERT INTO Umetnik VALUES
			(n.indeks, n.tip);
	END IF;
END@

--#SET TERMINATOR ;

DROP TRIGGER Studenti_zanimanja_insert;
		
DROP VIEW Studenti_zanimanja;

DROP TRIGGER Sportista_update;

DROP TABLE Umetnik;
DROP TABLE Muzicar;
DROP TABLE Sportista;
DROP TABLE Student;




