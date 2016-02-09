-- TP BASES DE DONNEES AVANCEES POUR LES BIOLOGISTES
-- Janvier-Février 2016
-- Victor Gaborit & Clara Jégousse
-- Master 2 Bioinformatique
-- Username: M2_BIO12@cienetdb
-- Password: m2db

-- I) Langage de définition de données

-- Suppression des tables (dans l'ordre pour ne pas avoir de problème avec les keys) :
DROP TABLE DetailsEmprunts; -- DROP TABLE Details;
DROP TABLE Emprunts;
DROP TABLE Membres;
DROP TABLE Exemplaires;
DROP TABLE Ouvrages;
DROP TABLE Genres;

DROP SEQUENCE seq_membre;

-- Pour visualiser les tables :
SELECT table_name FROM user_tables;

-- 1) Mise en place des tables en utilisant la syntaxe SQL Oracle
CREATE TABLE Genres (
code CHAR(5) CONSTRAINT pk_genres PRIMARY KEY,
libelle VARCHAR2(80) NOT NULL);

CREATE TABLE Ouvrages (
isbn NUMBER(10) CONSTRAINT pk_ouvrages PRIMARY KEY,
titre VARCHAR2(200) NOT NULL,
auteur VARCHAR2(80),
genre CHAR(5) NOT NULL CONSTRAINT fk_ouvrages_genres REFERENCES Genres(code),
editeur VARCHAR2(80));

CREATE TABLE Exemplaires (
isbn NUMBER(10),
numero NUMBER(3),
etat CHAR(5),
CONSTRAINT pk_exemplaires PRIMARY KEY(isbn, numero),
CONSTRAINT fk_exemplaires_ouvrages FOREIGN KEY(isbn) REFERENCES Ouvrages(isbn),
CONSTRAINT ck_exemplaires_etat check (etat IN('NE', 'BO', 'MO', 'MA')));

CREATE TABLE Membres (
numero NUMBER(6) CONSTRAINT pk_membres PRIMARY KEY,
nom VARCHAR2(80) NOT NULL,
prenom VARCHAR2(80) NOT NULL,
adresse VARCHAR2(200) NOT NULL,
telephone CHAR(10) NOT NULL,
adhesion date NOT NULL,
duree NUMBER(2) NOT NULL,
CONSTRAINT ck_membres_duree check (duree>=0));

CREATE TABLE Emprunts (
numero NUMBER(10) CONSTRAINT pk_emprunts PRIMARY KEY,
membre NUMBER(6) CONSTRAINT fk_emprunts_membres REFERENCES Membres(numero),
creele date default sysdate);

CREATE TABLE DetailsEmprunts (
emprunt NUMBER(10) CONSTRAINT fk_details_emprunts REFERENCES Emprunts(numero),
numero NUMBER(3),
isbn NUMBER(10),
exemplaire NUMBER(3),
rendule date,
CONSTRAINT pk_detailsemprunts PRIMARY KEY (emprunt, numero),
CONSTRAINT fk_detailsemprunts_exemplaires FOREIGN KEY (isbn, exemplaire) REFERENCES
Exemplaires(isbn, numero));

-- Pour verifier que les tables ont bien été créé :
SELECT table_name FROM user_tables;

-- 2) Définissez une séquence afin de faciliter la mise en place d’un numéro pour chaque membre. La séquence doit commencer avec la valeur 1 et elle possédera un pas d’incrément de 1.
CREATE SEQUENCE seq_membre START WITH 0 INCREMENT BY 1 MINVALUE 0;

-- 3) Définissez une contrainte d’intégrité afin de satisfaire cette nouvelle exigence. La contrainte sera ajoutée sur la table des membres par l’intermédiaire de l’instruction « alter table ».
ALTER TABLE Membres ADD CONSTRAINT uq_membres unique (nom, prenom, telephone);

--4)
ALTER TABLE Membres ADD mobile CHAR(10);
ALTER TABLE Membres ADD CONSTRAINT ck_membres_mobile check (mobile like '06%');

--5)
ALTER TABLE Membres DROP CONSTRAINT uq_membres;

ALTER TABLE Membres SET UNUSED (telephone);

ALTER TABLE Membres DROP UNUSED COLUMNS;

ALTER TABLE Membres ADD CONSTRAINT uq_membres UNIQUE (nom, prenom, mobile);

--6) 
CREATE index idx_ouvrages_genre ON Ouvrages(genre);
CREATE index idx_exemplaires_isbn ON Exemplaires(isbn);
CREATE index idx_emprunts_membre ON Emprunts(membre);
CREATE index idx_details_emprunt ON DetailsEmprunts(emprunt);
CREATE index idx_details_exemplaire ON DetailsEmprunts(isbn, exemplaire);

--7)
ALTER TABLE DetailsEmprunts DROP CONSTRAINT fk_details_emprunts;

ALTER TABLE DetailsEmprunts ADD CONSTRAINT fk_details_emprunts FOREIGN KEY (emprunt)
REFERENCES Emprunts(numero) ON DELETE CASCADE;

--8) 
ALTER TABLE Exemplaires MODIFY (etat CHAR(2) DEFAULT 'NE');

--9)
CREATE SYNONYM Abonnes FOR Membres;

--10)
RENAME DetailsEmprunts TO Details;

--II) Langage de Manipulation de Données

--1) 
-- Genres
INSERT INTO Genres(code, libelle) VALUES ('REC', 'Recit');
INSERT INTO Genres(code, libelle) VALUES ('POL', 'Policier');
INSERT INTO Genres(code, libelle) VALUES ('BD', 'Bande Dessinee');
INSERT INTO Genres(code, libelle) VALUES ('INF', 'Informatique');
INSERT INTO Genres(code, libelle) VALUES ('THE', 'Theatre');
INSERT INTO Genres(code, libelle) VALUES ('ROM', 'Roman');

SELECT * FROM Genres;

-- Ouvrages
INSERT INTO Ouvrages (isbn, titre, auteur, genre, editeur) VALUES (2203314168, 'LEFRANC-L''ultimatum', 'Martin, Carin', 'BD', 'Casterman');
INSERT INTO Ouvrages (isbn, titre, auteur, genre, editeur) VALUES (2746021285, 'HTML entrainez-vous pour maitriser le code source', 'Luc Van Lancker', 'INF', 'ENI');
INSERT INTO Ouvrages (isbn, titre, auteur, genre, editeur) VALUES (2746026090, 'Oracle 10g SQL, PL/SQL, SQL*Plus', 'J.Gabillaud', 'INF', 'ENI');
INSERT INTO Ouvrages (isbn, titre, auteur, genre, editeur) VALUES (2266085816, 'Pantagruel', 'F. Robert', 'ROM', 'Pocket');
INSERT INTO Ouvrages (isbn, titre, auteur, genre, editeur) VALUES (2266091611, 'Voyage au centre de la terre', 'Jules VERNE', 'ROM', 'Pocket');
INSERT INTO Ouvrages (isbn, titre, auteur, genre, editeur) VALUES (2253010219, 'Le crime de l''Orient Express', 'Agatha Christie', 'POL', 'Livre de Poche');
INSERT INTO Ouvrages (isbn, titre, auteur, genre, editeur) VALUES (2070400816, 'Le Bourgeois gentilhomme', 'Moliere', 'THE', 'Gallimard');
INSERT INTO Ouvrages (isbn, titre, auteur, genre, editeur) VALUES (2070367177, 'Le cure de Tours', 'Honore de Balzac', 'ROM', 'Gallimard');
INSERT INTO Ouvrages (isbn, titre, auteur, genre, editeur) VALUES (2080720872, 'Boule de suif', 'G. de Maupassant', 'REC', 'Flammarion');
INSERT INTO Ouvrages (isbn, titre, auteur, genre, editeur) VALUES (2877065073, 'La gloire de mon pere', 'Marcel Pagnol', 'ROM', 'Fallois');
INSERT INTO Ouvrages (isbn, titre, auteur, genre, editeur) VALUES (2020549522, 'L''aventure des manuscrits de la mer morte', default, 'REC', 'Seuil');
INSERT INTO Ouvrages (isbn, titre, auteur, genre, editeur) VALUES (2253006327, 'Vingt mille lieues sous les mers', 'Jules Verne', 'ROM', 'LGF');
INSERT INTO Ouvrages (isbn, titre, auteur, genre, editeur) VALUES (2038704015, 'De la terre a la lune', 'Jules Verne', 'ROM', 'Larousse');

SELECT * FROM Ouvrages;

--Exemplaires
-- étape1
INSERT INTO Exemplaires (isbn, numero, etat) SELECT isbn, 1, 'BO' FROM Ouvrages;
INSERT INTO Exemplaires (isbn, numero, etat) SELECT isbn, 2, 'MO' FROM Ouvrages;
-- étape2
DELETE FROM Exemplaires WHERE isbn=2746021285 and numero=2;
-- étape3
UPDATE Exemplaires SET etat='MO' where isbn=2203314168 and numero=1;
UPDATE Exemplaires SET etat='BO' where isbn=2203314168 and numero=2;
INSERT INTO Exemplaires (isbn, numero, etat) VALUES (2203314168, 3, 'NE');
INSERT INTO Exemplaires (isbn, numero, etat) VALUES (2746021285, 2, 'MO');

--2)
INSERT INTO Membres (numero, nom, prenom, adresse, mobile, adhesion, duree) VALUES (seq_membre.nextval, 'ALBERT', 'Anne', '13 rue des alpes', '0601020304', sysdate-60, 1);
INSERT INTO Membres (numero, nom, prenom, adresse, mobile, adhesion, duree) VALUES (seq_membre.nextval, 'BERNAUD', 'Barnabe', '6 rue des becasses', '0602030105', sysdate-10, 3);
INSERT INTO Membres (numero, nom, prenom, adresse, mobile, adhesion, duree) VALUES (seq_membre.nextval, 'CUVARD', 'Camille', '52 rue des cerisiers', '0602010509', sysdate-100, 6);
INSERT INTO Membres (numero, nom, prenom, adresse, mobile, adhesion, duree) VALUES (seq_membre.nextval, 'DUPOND', 'Daniel', '11 rue des daims', '0610236515', sysdate-250, 12);
INSERT INTO Membres (numero, nom, prenom, adresse, mobile, adhesion, duree) VALUES (seq_membre.nextval, 'EVROUX', 'Eglantine', '34 rue des elfes', '0658963125', sysdate-150, 6);
INSERT INTO Membres (numero, nom, prenom, adresse, mobile, adhesion, duree) VALUES (seq_membre.nextval, 'FREGEON', 'Fernand', '11 rue des Francs', '0602036987', sysdate-400, 6);
INSERT INTO Membres (numero, nom, prenom, adresse, mobile, adhesion, duree) VALUES (seq_membre.nextval, 'GORIT', 'Gaston', '96 rue de la glacerie', '0684235781', sysdate-150, 1);
INSERT INTO Membres (numero, nom, prenom, adresse, mobile, adhesion, duree) VALUES (seq_membre.nextval, 'HEVARD', 'Hector', '12 rue haute', '0608546578', sysdate-250, 12);
INSERT INTO Membres (numero, nom, prenom, adresse, mobile, adhesion, duree) VALUES (seq_membre.nextval, 'INGRAND', 'Irene', '54 rue des iris', '0605020409', sysdate-50, 12);
INSERT INTO Membres (numero, nom, prenom, adresse, mobile, adhesion, duree) VALUES (seq_membre.nextval, 'JUSTE', 'Julien', '5 place des Jacobins', '0603069876', sysdate-100, 6);

3)
-- Emprunts
INSERT INTO Emprunts (numero, membre, creele) VALUES (1, 1, sysdate-200);
INSERT INTO Emprunts (numero, membre, creele) VALUES (2, 3, sysdate-190);
INSERT INTO Emprunts (numero, membre, creele) VALUES (3, 4, sysdate-180);
INSERT INTO Emprunts (numero, membre, creele) VALUES (4, 1, sysdate-170);
INSERT INTO Emprunts (numero, membre, creele) VALUES (5, 5, sysdate-160);
INSERT INTO Emprunts (numero, membre, creele) VALUES (6, 2, sysdate-150);
INSERT INTO Emprunts (numero, membre, creele) VALUES (7, 4, sysdate-140);
INSERT INTO Emprunts (numero, membre, creele) VALUES (8, 1, sysdate-130);
INSERT INTO Emprunts (numero, membre, creele) VALUES (9, 9, sysdate-120);
INSERT INTO Emprunts (numero, membre, creele) VALUES (10, 6, sysdate-110);
INSERT INTO Emprunts (numero, membre, creele) VALUES (11, 1, sysdate-100);
INSERT INTO Emprunts (numero, membre, creele) VALUES (12, 6, sysdate-90);
INSERT INTO Emprunts (numero, membre, creele) VALUES (13, 2, sysdate-80);
INSERT INTO Emprunts (numero, membre, creele) VALUES (14, 4, sysdate-70);
INSERT INTO Emprunts (numero, membre, creele) VALUES (15, 1, sysdate-60);
INSERT INTO Emprunts (numero, membre, creele) VALUES (16, 3, sysdate-50);
INSERT INTO Emprunts (numero, membre, creele) VALUES (17, 1, sysdate-40);
INSERT INTO Emprunts (numero, membre, creele) VALUES (18, 5, sysdate-30);
INSERT INTO Emprunts (numero, membre, creele) VALUES (19, 4, sysdate-20);
INSERT INTO Emprunts (numero, membre, creele) VALUES (20, 1, sysdate-10);

-- Details
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (1, 1, 2038704015, 1, sysdate-195);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (1, 2, 2070367177, 2, sysdate-190);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (2, 1, 2080720872, 1, sysdate-180);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (2, 2, 2203314168, 1, sysdate-179);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (3, 1, 2038704015, 1, sysdate-170);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (4, 1, 2203314168, 2, sysdate-155);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (4, 2, 2080720872, 1, sysdate-155);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (4, 3, 2266085816, 1, sysdate-159);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (5, 1, 2038704015, 2, sysdate-140);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (6, 1, 2266085816, 2, sysdate-141);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (6, 2, 2080720872, 2, sysdate-130);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (6, 3, 2746021285, 2, sysdate-133);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (7, 1, 2070367177, 2, sysdate-100);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (8, 1, 2080720872, 1, sysdate-116);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (9, 1, 2038704015, 1, sysdate-100);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (10, 1, 2080720872, 2, sysdate-107);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (10, 2, 2746026090, 1, sysdate-78);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (11, 1, 2746021285, 1, sysdate-81);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (12, 1, 2203314168, 1, sysdate-86);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (12, 2, 2038704015, 1, sysdate-60);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (13, 1, 2070367177, 1, sysdate-65);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (14, 1, 2266091611, 1, sysdate-66);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (15, 1, 2266085816, 1, sysdate-50);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (16, 1, 2253010219, 2, sysdate-41);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (16, 2, 2070367177, 2, sysdate-41);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (17, 1, 2877065073, 2, sysdate-36);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (18, 1, 2070367177, 1, sysdate-14);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (19, 1, 2746026090, 1, sysdate-12);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (20, 1, 2266091611, 1, default);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (20, 2, 2253010219, 1, default);

--4) 
SELECT * FROM Genres;
SELECT * FROM Ouvrages;
SELECT * FROM Exemplaires;
SELECT * FROM Membres;
SELECT * FROM Emprunts;
SELECT * FROM Details;

--5)
ALTER TABLE Membres ENABLE ROW MOVEMENT;
ALTER TABLE Details ENABLE ROW MOVEMENT;

--6)
ALTER TABLE Emprunts ADD (etat CHAR(2) DEFAULT 'EC');
ALTER TABLE Emprunts ADD CONSTRAINT ck_emprunts_etat CHECK (etat IN ('EC', 'RE'));

UPDATE Emprunts SET etat='RE' WHERE etat='EC' AND numero NOT IN (SELECT emprunt FROM Details WHERE rendule IS NULL);

--7)
--mettre à jour le jeu d'essai
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (7, 2, 2038704015, 1, sysdate-136);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (8, 2, 2038704015, 1, sysdate-127);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (11, 2, 2038704015, 1, sysdate-95);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (15, 2, 2038704015, 1, sysdate-54);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (16, 3, 2038704015, 1, sysdate-43);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (17, 2, 2038704015, 1, sysdate-36);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (18, 2, 2038704015, 1, sysdate-24);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (19, 2, 2038704015, 1, sysdate-13);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (20, 3, 2038704015, 1, sysdate-3);

--réinitialiser l'état d'un exemplaire
UPDATE Exemplaires SET etat='NE' WHERE isbn=2038704015 AND numero=1;

-- étape1
CREATE TABLE tempoExemplaires AS SELECT isbn, exemplaire, count(*) AS locations 
FROM Details
GROUP BY isbn, exemplaire;
-- étape2
MERGE INTO Exemplaires e
USING (SELECT isbn, exemplaire, locations FROM tempoExemplaires) t 
ON (t.isbn=e.isbn AND t.exemplaire=e.numero)
WHEN MATCHED THEN
UPDATE SET etat='BO' WHERE t.locations BETWEEN 11 AND 25
DELETE WHERE t.locations>60;
-- étape3 
DROP TABLE tempoExemplaires;

--8) 
INSERT INTO Exemplaires (isbn, numero, etat) VALUES (2203314168, 4, 'MA');
INSERT INTO Exemplaires (isbn, numero, etat) VALUES (2746021285, 3, 'MA');
--Exécution de la requête de suppression
DELETE FROM Exemplaires WHERE etat='MA';

--9) 
SELECT * FROM Ouvrages;

--10) 
SELECT Membres.*, Ouvrages.titre
FROM Membres, Emprunts, Details, Ouvrages
WHERE Emprunts.membre=Membres.numero
AND Details.emprunt=Emprunts.numero
AND Trunc(sysdate, 'WW')-Trunc(creele, 'WW') > 2
AND Details.isbn=Ouvrages.isbn
AND Details.rendule IS NULL;

--11)
SELECT genre, count(*) as nombre
FROM Exemplaires, Ouvrages
WHERE Ouvrages.isbn=Exemplaires.isbn
GROUP BY genre;

--12) 
SELECT AVG(rendule-creele) AS "Duree Moyenne"
FROM Emprunts, Details
WHERE Emprunts.numero=Details.emprunt AND rendule IS NOT NULL;

--13) 
SELECT genre, AVG(rendule-creele) AS "Duree Moyenne"
FROM Emprunts, Details, Ouvrages
WHERE Emprunts.numero=Details.emprunt AND Details.isbn=Ouvrages.isbn AND rendule IS NOT NULL
GROUP BY genre;

--14) 
SELECT Exemplaires.isbn
FROM Emprunts, Details, Exemplaires
WHERE Details.exemplaire=Exemplaires.numero
AND Details.isbn=Exemplaires.isbn
AND Details.emprunt=Emprunts.numero
AND MONTHS_BETWEEN (Emprunts.creele, sysdate) > 12
GROUP BY Exemplaires.isbn
HAVING count(*) > 10;

--15) 
SELECT Ouvrages.*, Exemplaires.numero
FROM Ouvrages, Exemplaires
WHERE Ouvrages.isbn=Exemplaires.isbn(+);

--16) 
CREATE OR REPLACE VIEW OuvragesEmpruntes AS
SELECT Emprunts.membre, count(*) AS nombreEmprunts
FROM Emprunts, Details
WHERE Emprunts.numero=Details.emprunt
AND Details.rendule IS NULL
GROUP BY Emprunts.membre;

--17) 
CREATE OR REPLACE VIEW NombreEmpruntsParOuvrage AS 
SELECT isbn, count(*) AS nombreEmprunts
FROM Details
GROUP BY isbn;
--NB: Une interrogation sur cette vue en utilisant la clause ORDER BY permettra d'afficher les ouvrages par ordre décroissant du nombre de locations

--18) 
SELECT * FROM Membres ORDER BY nom, prenom;

--19)
--Création de la table temporaire globale
CREATE GLOBAL TEMPORARY TABLE tempoGlobaleEmprunts (
isbn CHAR(10),
exemplaire NUMBER(3),
nombreEmpruntsExemplaire NUMBER(10),
nombreEmpruntsOuvrage NUMBER(10)) 
ON COMMIT PRESERVE ROWS;
--Ajout d'informations pour chaque exemplaire
INSERT INTO tempoGlobaleEmprunts (
isbn, exemplaire, nombreEmpruntsExemplaire)
SELECT isbn, numero, count(*)
FROM Details
GROUP BY isbn, numero;
--Ajout d'informations pour chaque ouvrage
UPDATE tempoGlobaleEmprunts
SET nombreEmpruntsOuvrage= (SELECT count(*) FROM Details WHERE Details.isbn=tempoGlobaleEmprunts.isbn);
--Terminaison de la transaction 
COMMIT;
--Suppression des informations présentes dans la table
DELETE FROM tempoGlobaleEmprunts;
--Supprimer la table
DROP TABLE tempoGlobaleEmprunts;
--ERROR at line 1: ORA-14452: attempt to create, alter or drop an index on temporary table already in use

--20) 
SELECT Genres.libelle, Ouvrages.titre
FROM Ouvrages, Genres
WHERE Genres.code=Ouvrages.genre
ORDER BY Genres.libelle, Ouvrages.titre;

--IV) PL/SQL

--1) Mise à jour conditionnelle de l'état des examplaires en fonction du nombre d'emprunts

DECLARE 
	CURSOR c_Exemplaires IS
		SELECT * FROM Exemplaires FOR UPDATE OF etat;
	v_etat Exemplaires.etat%TYPE;
	v_nbre number (3);
BEGIN 
	FOR v_exemplaire IN c_Exemplaires LOOP
		SELECT COUNT(*) INTO v_nbre
		FROM Details
		WHERE Details.isbn=v_exemplaire.isbn
		AND Details.exemplaire=v_exemplaire.numero;
		IF (v_nbre<=10)
			THEN v_etat:='NE';
			ELSE IF (v_nbre<=25)
				THEN v_etat:='BO';
				ELSE IF (v_nbre<=40)
					THEN v_etat:='MO';
					ELSE v_etat:='MA';
				END IF;
			END IF;
		END IF;
		UPDATE Exemplaires SET etat=v_etat
		WHERE CURRENT OF c_Exemplaires;
	END LOOP;
END;
/

--2) Suppression conditionnelle

-- étape1 : vérifier que la colonne Membre de la table des Emprunts accepte les valeurs null.
DESC Emprunts;

-- étape 2 : dans le cas où la colonne n'accepte pas la valeur null, on doit modifier la définition de la table
ALTER TABLE Emprunts MODIFY (membre NUMBER(6) NULL);
-- RQ: si la colonne autorise deja les valeurs null, alors l'execution du script se termine par une erreur.

-- étape 3 : on définit enfin le bloc PL/SQL permettant d'obtenir le résultat souhaité
DECLARE
	--ADD_MONTHS(i,j) permet de calculer la date de fin en rajoutant j mois à la date i
	CURSOR c_Membres IS SELECT * FROM Membres WHERE MONTHS_BETWEEN (sysdate, ADD_MONTHS(adhesion, duree)) > 24;
	v_nombre number(5);

BEGIN
	FOR v_Membres IN c_Membres LOOP
		-- On regarde si ce membre possède encore des fiches d'emprunts
		SELECT COUNT(*) INTO v_nombre 
		FROM Emprunts, Details 
		WHERE rendule IS NULL 
		AND Details.emprunt = Emprunts.numero 
		AND emprunts.membre = v_Membres.numero;	
		IF (v_nombre = 0)
			--S'il a encore des fiches d'emprunts
			THEN 	SELECT COUNT(*) INTO v_nombre 
					FROM Emprunts 
					WHERE membre = v_Membres.numero;
			IF (v_nombre != 0) THEN 
	
						UPDATE Emprunts 
						SET membre = NULL 
						WHERE membre = v_Membres.numero;
			END IF;
		-- On supprime le membre
		DELETE FROM Membres WHERE numero = v_Membres.numero;
		-- On valide les modifications par un COMMIT
		COMMIT;
		END IF;
	END LOOP;
END;
/

--3)
SET serveroutput ON;

DECLARE
	--1er curseur pour l'ordre ascendant
	CURSOR c_ordre_croissant IS 
		SELECT E.membre, COUNT(*) 
		FROM Emprunts E, Details D
		WHERE E.numero = D.emprunt
		GROUP BY E.membre
		ORDER BY 2 ASC;

	--2ème curseur pour l'ordre descendant
	CURSOR c_ordre_decroissant IS
		SELECT E.membre, COUNT (*)
		FROM Emprunts E, Details D
		WHERE E.numero = D.emprunt
		GROUP BY E.membre
		ORDER BY 2 DESC;

	v_lecteur c_ordre_croissant%ROWTYPE;
	i NUMBER;
	v_membre Membres%ROWTYPE;

BEGIN
	DBMS_OUTPUT.PUT_LINE ('Membres ayant emprunte le plus d ouvrages au cours des 10 derniers mois');
	OPEN c_ordre_croissant;

	--Boucle du 1er au 3ème
	FOR i IN 1..3 LOOP
		FETCH c_ordre_croissant INTO v_lecteur;
		IF c_ordre_croissant%NOTFOUND
			THEN EXIT;
		END IF;
		SELECT * INTO v_membre
		FROM Membres
		WHERE numero = v_lecteur.membre;
		DBMS_OUTPUT.PUT_LINE(i||' _ '|| v_membre.numero || ' ' || v_membre.nom);
	END LOOP;
	CLOSE c_ordre_croissant;

	DBMS_OUTPUT.PUT_LINE('Membres ayant emprunte le moins d ouvrages au cours des 10 derniers mois');
	OPEN c_ordre_decroissant;
	--Boucle de 1 à 3
	FOR i IN 1..3 LOOP
		FETCH c_ordre_decroissant INTO v_lecteur;
		IF c_ordre_decroissant%NOTFOUND
			THEN EXIT;
		END IF;
		SELECT * INTO v_membre
		FROM Membres
		WHERE numero = v_lecteur.membre;
		DBMS_OUTPUT.PUT_LINE(i||' _ '||v_membre.numero||' '|| v_membre.nom);
	END LOOP;
	CLOSE c_ordre_decroissant;
END;
/


--4)

-- Pour afficher les résultats
SET serveroutput ON;

DECLARE
	CURSOR c_Ouvrages IS 
		SELECT isbn, COUNT(*) AS nombreEmprunts
		FROM Details
		GROUP BY isbn
		ORDER BY 2 DESC;
	v_ouvrage c_Ouvrages%ROWTYPE;
	i NUMBER;

BEGIN 
	OPEN c_Ouvrages;
	i:=0;
	LOOP
		i:=i+1; -- incrémentation
		EXIT WHEN i>5;
		FETCH c_Ouvrages INTO v_ouvrage;

		--Sortie de la boucle si le curseur est vide
		EXIT WHEN c_Ouvrages%NOTFOUND;
		DBMS_OUTPUT.PUT_LINE('Numero: '|| i ||' _isbn :' || v_ouvrage.isbn);
	END LOOP;
	CLOSE c_Ouvrages;
END;
/




--5)
-- en PL/SQL
SET serveroutput ON;

DECLARE
	CURSOR c_Membres IS SELECT * FROM Membres;
BEGIN
	-- On traite chaque membre
	FOR v_membre IN c_Membres LOOP
		--ADD_MONTHS(i,j) permet de calculer la date de fin en rajoutant j mois à la date i
		IF (ADD_MONTHS(v_membre.adhesion, v_membre.duree)<sysdate+30) THEN
			DBMS_OUTPUT.PUT_LINE('Numero '||v_membre.numero||' '||v_membre.nom);
		END IF;
	END LOOP;
END;
/

-- Même résultat avec une requête SQL -> execution plus rapide
SELECT numero, nom
FROM Membres
--ADD_MONTHS(i,j) permet de calculer la date de fin en rajoutant j mois à la date i
WHERE ADD_MONTHS(adhesion, duree)<=sysdate+30;

--6)
-- étape 1a : mise à jour de la structure de la table
ALTER TABLE Exemplaires ADD (
nombreEmprunts NUMBER(3) DEFAULT 0,
dateCalculEmprunts DATE DEFAULT SYSDATE);
-- étape 1b : mettre à jour les informations de la table
UPDATE Exemplaires SET dateCalculEmprunts = (
	SELECT MIN(creele) 
	FROM Emprunts E, Details D 
	WHERE E.numero=D.emprunt
	AND D.isbn=Exemplaires.isbn
	AND D.exemplaire=Exemplaires.numero);
UPDATE Exemplaires SET dateCalculEmprunts = SYSDATE
WHERE dateCalculEmprunts IS NULL;
COMMIT;
-- étape 2 : script PL/SQL
DECLARE
	CURSOR c_Exemplaires IS SELECT * FROM Exemplaires
	FOR UPDATE OF nombreEmprunts, dateCalculEmprunts;
	v_nbre Exemplaires.nombreEmprunts%TYPE;
BEGIN
	-- On parcourt l'ensemble des exemplaires
	FOR v_exemplaire IN c_Exemplaires LOOP
		-- On calcule le nombre d'emprunts
		SELECT COUNT(*) INTO v_nbre
		FROM Details, Emprunts
		WHERE Details.emprunt=Emprunts.numero
		AND isbn=v_exemplaire.isbn
		AND exemplaire=v_exemplaire.numero
		AND creele>=v_exemplaire.dateCalculEmprunts;

		-- Mise à jour des informations relatives aux exemplaires
		UPDATE Exemplaires SET
		nombreEmprunts=nombreEmprunts+v_nbre,
		dateCalculEmprunts=SYSDATE
		WHERE CURRENT OF c_Exemplaires;

		-- Mise à jour de l'état des exemplaires
		UPDATE Exemplaires SET etat='NE' WHERE nombreEmprunts<=10;
		UPDATE Exemplaires SET etat='BO' WHERE nombreEmprunts BETWEEN 11 AND 25;
		UPDATE Exemplaires SET etat='MO' WHERE nombreEmprunts BETWEEN 26 AND 40;
		UPDATE Exemplaires SET etat='MA' WHERE nombreEmprunts>=41;
	END LOOP;
	-- On valide les modifications effectuées
	COMMIT;
END;
/

--7)
DECLARE
	v_nbre number(6);
	v_total number(6);
BEGIN 
-- Calcul du rapport exemplaires dans un état moyen ou mauvais par rapport au nombre total d'exemplaires
	SELECT COUNT(*) INTO v_Nbre
	FROM Exemplaires
	WHERE etat IN ('MO', 'MA');
	SELECT COUNT(*) INTO v_total
	FROM Exemplaires;

	IF (v_nbre>v_total/2) THEN
		-- On supprime la contrainte existante
		EXECUTE IMMEDIATE 'ALTER TABLE Exemplaires DROP constraint ck_exemplaires_etat';
		-- On ajoute la nouvelle contrainte
		EXECUTE IMMEDIATE 'ALTER TABLE Exemplaires ADD constraint ck_exemplaires_etat CHECK etat IN (''NE'', ''BO'', ''MO'', ''DO'', ''MA'')';
		-- On met à jour l'état de l'exemplaire
		UPDATE Exemplaires SET etat = 'DO' WHERE nombreEmprunts BETWEEN 41 AND 60;
		-- On valide les modifications effectuées
		COMMIT;
	END IF;
END;
/

--8)
DELETE FROM Membres
WHERE numero IN (
	SELECT DISTINCT membre
	FROM Emprunts
	GROUP BY membre
	--ADD_MONTHS(i,j) permet de calculer la date de fin en rajoutant j mois à la date i
	HAVING MAX(creele)< ADD_MONTHS(SYSDATE, -36));

--9)
-- étape 1 : Modification de la structure de la table
ALTER TABLE Membres MODIFY (mobile CHAR(14));

-- étape 2 : Mise en forme du numéro de téléphone mobile
DECLARE
	-- On traite les membres un par un 
	CURSOR c_Membres IS
		SELECT mobile FROM Membres
		FOR UPDATE OF mobile;
	v_nouveauMobile Membres.mobile%TYPE;
BEGIN
	FOR v_numero IN c_Membres LOOP
		IF (INSTR(v_numero.mobile,' ')!=2) THEN
		-- On construit le nouveau numéro
			--Utilisation de SUBSTR(i,n) qui va prendre n lettres à la position i
			v_nouveauMobile:=SUBSTR(v_numero.mobile,1,2)||' '||
			SUBSTR(v_numero.mobile,3,2)||' '||
			SUBSTR(v_numero.mobile,5,2)||' '||
			SUBSTR(v_numero.mobile,7,2)||' '||
			SUBSTR(v_numero.mobile,9,2);
			UPDATE Membres
			SET mobile=v_nouveauMobile
			WHERE CURRENT OF c_Membres;
		END IF;
	END LOOP;
END;
/

-- étape 3 : Définition et activation de la contrainte d'intégrité
ALTER TABLE Membres ADD constraint ck_membres_mobile2 CHECK (REGEXP_LIKE (mobile, '^06 [[:digit:]]{2} [[:digit:]]{2} [[:digit:]]{2} [[:digit:]]{2}$')) ;


--V) PL/SQL procédures et fonctions

--1) Fonction FinValidite
CREATE OR REPLACE FUNCTION FinValidite (v_numero IN NUMBER) RETURN DATE IS v_fin DATE;
BEGIN
	--ADD_MONTHS(i,j) permet de calculer la date de fin en rajoutant j mois à la date i
	SELECT ADD_MONTHS(adhesion, duree) INTO v_fin
	FROM Membres
	WHERE numero=v_numero;
	RETURN v_fin;
END;
/

--Test
select Membres.numero, Membres.nom, FinValidite(Membres.numero) from Membres; 

--2) Fonction AdhesionAjour
CREATE OR REPLACE FUNCTION AdhesionAjour(v_numero NUMBER) RETURN BOOLEAN AS
BEGIN 
	IF (FinValidite(v_numero)>= SYSDATE())
		THEN RETURN TRUE;
	ELSE 
		RETURN FALSE;
	END IF;
END;
/

--Test
BEGIN
	FOR i IN (SELECT Membres.numero j, Membres.nom n FROM Membres) LOOP
		IF (AdhesionAjour(i.j)) THEN
			DBMS_OUTPUT.PUT_LINE('Membre ' ||i.n || ' de numero ' ||i.j||' : adhesion a jour');
		ELSE
			DBMS_OUTPUT.PUT_LINE('Membre ' ||i.n || ' de numero ' ||i.j||' : adhesion pas a jour');
		END IF;
	END LOOP;
END;
/

--3) Procédure RetourExemplaire
CREATE OR REPLACE PROCEDURE RetourExemplaire (v_isbn IN NUMBER, v_numero IN NUMBER) AS
BEGIN
	UPDATE Details SET rendule=SYSDATE
	WHERE rendule IS NULL
	AND isbn=v_isbn AND exemplaire=v_numero;
END;
/

--4) Procédure PurgeMembres
CREATE OR REPLACE PROCEDURE PurgeMembres AS
CURSOR c_Membres IS SELECT numero FROM Membres WHERE (TRUNC(SYSDATE(), 'YYYY') - TRUNC(ADD_MONTHS(adhesion, duree), 'YYYY'))>3;
BEGIN 
	FOR v_numero IN c_Membres LOOP
		BEGIN
			DELETE FROM Membres WHERE numero=v_numero.numero;
			-- On valide ensuite la transaction avec un commit
			COMMIT;
		EXCEPTION	
			WHEN OTHERS THEN NULL;
		END;
	END LOOP;
END;
/

--Test
EXECUTE PurgeMembres;

--5) Fonction MesureActivite
CREATE OR REPLACE FUNCTION MesureActivite (v_mois IN NUMBER) RETURN NUMBER IS
CURSOR c_activite(v_m IN NUMBER) IS
	SELECT membre, COUNT(*)
	FROM Emprunts, Details
	WHERE Details.emprunt=Emprunts.numero
	AND MONTHS_BETWEEN(SYSDATE, creele) <v_m
	GROUP BY membre
	ORDER BY 2 DESC;
v_membre c_activite%ROWTYPE;

BEGIN
	OPEN c_activite(v_mois);
	FETCH c_activite INTO v_membre;
	CLOSE c_activite;
	RETURN v_membre.membre;
END;
/

--Test sur 12 mois
SELECT numero, nom, prenom
FROM Membres
WHERE numero = MesureActivite(12);

DECLARE
	countEmprunt NUMBER;
	nomMembre Membres.nom%TYPE;
	prenomMembre Membres.prenom%TYPE;

BEGIN
	FOR i IN (SELECT numero j FROM Membres) LOOP
		SELECT (SELECT COUNT(*) FROM Details WHERE numero=i.j),
		m.nom n, 
		m.prenom p 
		INTO countEmprunt,nomMembre,prenomMembre
		FROM Membres M, Emprunts E
		WHERE M.numero = i.j 
		AND E.numero = M.numero
		AND E.creele < SYSDATE - 12;
		DBMS_OUTPUT.PUT_LINE('Dans les 12 derniers mois, le membre dont le prenom est ' ||prenomMembre || ' et le nom ' ||nomMembre|| ' a emprunte en tout ' ||countEmprunt || ' livres.');
	END LOOP;
END;
/

--6) Fonction EmpruntMoyen
CREATE OR REPLACE FUNCTION EmpruntMoyen (v_membre IN NUMBER) RETURN NUMBER IS v_dureeMoyenne NUMBER;
BEGIN 
	SELECT TRUNC(AVG(TRUNC(rendule,'DD')-TRUNC(creele,'DD')+1), 2) INTO v_dureeMoyenne
	FROM Emprunts, Details
	WHERE Emprunts.membre=v_membre
	AND Details.emprunt=Emprunts.numero
	AND Details.rendule IS NOT NULL;
	RETURN v_dureeMoyenne;
END;
/

--test
DECLARE
	EmpruntMoyenMembre NUMBER;

BEGIN
	FOR i IN (SELECT Membres.numero j, Membres.nom n FROM Membres) LOOP
		SELECT EmpruntMoyen(i.j) INTO EmpruntMoyenMembre FROM dual;
			IF (EmpruntMoyen(i.j) != 0) THEN
				DBMS_OUTPUT.PUT_LINE('Membre ' ||i.n || ' de numero ' ||i.j||' : Moyenne en jour de duree d''emprunts : ' ||EmpruntMoyenMembre);
			ELSE
				DBMS_OUTPUT.PUT_LINE('Membre ' ||i.n || ' de numero ' ||i.j||' : N''a jamais emprunte.');
			END IF;
	END LOOP;
END;
/



--7) Fonction DureeMoyenne
CREATE OR REPLACE FUNCTION DureeMoyenne (v_isbn IN NUMBER, v_exemplaire IN NUMBER DEFAULT NULL) RETURN NUMBER IS v_duree NUMBER;
BEGIN
	IF (v_exemplaire IS NULL) THEN
		SELECT AVG(TRUNC(rendule,'DD')-TRUNC(creele,'DD')+1) INTO v_duree
		FROM Emprunts, Details
		WHERE Emprunts.numero=Details.emprunt
		AND Details.isbn=v_isbn
		AND rendule IS NOT NULL;
	ELSE
		SELECT AVG(TRUNC(rendule,'DD')-TRUNC(creele,'DD')+1) INTO v_duree
		FROM Emprunts, Details
		WHERE Emprunts.numero=Details.emprunt
		AND Details.exemplaire=v_exemplaire
		AND rendule IS NOT NULL;
	END IF;
	RETURN v_Duree;
END;
/

--test
DECLARE
	DureeMoyenneEmprunt NUMBER;
BEGIN
	FOR i IN (SELECT isbn j, titre k FROM Ouvrages) LOOP
		SELECT DureeMoyenne(i.j) INTO DureeMoyenneEmprunt FROM dual;
		IF (DureeMoyenneEmprunt != 0) THEN
			DBMS_OUTPUT.PUT_LINE('Pour le livre ''' ||i.k || ''' la duree moyenne d''emprunt est : ' ||DureeMoyenneEmprunt);
		ELSE
			DBMS_OUTPUT.PUT_LINE('Pour le livre ''' ||i.k|| ''' il n''y a pas de duree moyenne d''emprunts.');
		END IF;
	END LOOP;
END;
/

--8) Procédure MajEtatExemplaire
CREATE OR REPLACE PROCEDURE MajEtatExemplaire IS 
	CURSOR c_Exemplaires IS SELECT * FROM Exemplaires
		FOR UPDATE OF nombreEmprunts, dateCalculEmprunts;
	v_nbre Exemplaires.nombreEmprunts%TYPE;
BEGIN 
	-- On parcoure d'abord l'ensemble des Exemplaires
	FOR v_exemplaire IN c_Exemplaires LOOP
		-- On calcule le nombre d'emprunts
		SELECT COUNT(*) INTO v_nbre
		FROM Details, Emprunts
		WHERE Details.emprunt=Emprunts.numero
		AND isbn=v_exemplaire.isbn
		AND exemplaire=v_exemplaire.numero
		AND creele >= v_exemplaire.dateCalculEmprunts;
		-- On met à jour les informations concernant les exemplaires
		UPDATE Exemplaires SET
		nombreEmprunts=nombreEmprunts+v_nbre, dateCalculEmprunts=SYSDATE
		WHERE CURRENT OF c_Exemplaires;
		-- On met à jour l'état des exemplaires
		UPDATE Exemplaires SET etat='NE' WHERE nombreEmprunts <= 10;
		UPDATE Exemplaires SET etat='BO' WHERE nombreEmprunts BETWEEN 11 AND 25;
		UPDATE Exemplaires SET etat='MO' WHERE nombreEmprunts BETWEEN 26 AND 40;
		UPDATE Exemplaires SET etat='DO' WHERE nombreEmprunts BETWEEN 41 AND 60;
		UPDATE Exemplaires SET etat='MA' WHERE nombreEmprunts >= 61;
		-- Pour finir on valide les modifications
		COMMIT;
	END LOOP;
END;
/

-- Utilisation du package DBMS_SCHEDULER
BEGIN
	DBMS_SCHEDULER.CREATE_JOB('CalculEtatExemplaire','MajEtatExemplaire', SYSTIMESTAMP, 'systimestamp+14');
END;
/
-- insufficient privileges

--9) Fonction AjouteMembre
CREATE OR REPLACE FUNCTION AjouteMembre (v_nom IN CHAR, v_prenom IN CHAR, v_adresse IN CHAR, v_mobile IN CHAR, v_adhesion IN DATE, v_duree IN NUMBER) RETURN NUMBER AS v_numero Membres.numero%TYPE;
BEGIN 
	INSERT INTO Membres (Numero, Nom, Prenom, Adresse, Mobile, Adhesion, Duree)
	VALUES (seq_membre.nextval, v_Nom, v_Prenom, v_Adresse, v_Mobile, v_Adhesion, v_Duree)
	RETURNING Numero INTO v_Numero;
	RETURN v_Numero;
END;
/

--test
DECLARE
	v_Numero Membres.Numero%TYPE;

BEGIN
	v_Numero := AjouteMembre('Personne','Paul','4 rue du centre','06 36 65 65 65',sysdate,3);
	DBMS_OUTPUT.PUT_LINE('Le numero du nouveau membre est le suivant : '||v_Numero);
END;
/

--10) Procédure SupprimeExemplaire
CREATE OR REPLACE PROCEDURE SupprimeExemplaire (v_Isbn IN number, v_Numero IN number) AS
BEGIN
	-- On supprime l'exemplaire choisi
	DELETE FROM Exemplaires WHERE Isbn=v_Isbn AND Numero=v_Numero;
	IF (SQL%ROWCOUNT=0) THEN RAISE NO_DATA_FOUND;
	END IF;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
	RAISE_APPLICATION_ERROR(-20510,'Cet exemplaire n''existe pas');
END;
/

--test
 execute SupprimeExemplaire(203440861,3); 

--11) Procédure EmpruntExpress
-- étape 1 : recherche de la plus grande valeur attribuée à un numéro d'emprunt
SELECT MAX(Numero) FROM Emprunts;
-- étape 2 : création d'une séquence
CREATE SEQUENCE seq_emprunts START WITH 20;
-- étape 3 : création de la procédure
CREATE OR REPLACE PROCEDURE EmpruntExpress (v_Membre number, v_Isbn number, v_Exemplaire number) AS v_Emprunt Emprunts.Numero%TYPE;
BEGIN
	INSERT INTO Emprunts (Numero, Membre, Creele) VALUES (seq_emprunts.nextval, v_Membre, sysdate)
	RETURNING Numero INTO v_Emprunt;
	INSERT INTO Details (Emprunt, Numero, Isbn, Exemplaire) VALUES (v_Emprunt, 1, v_Isbn, v_Exemplaire);
END;
/

--test
execute EmpruntExpress(11,123456789)

--12) Création de package
-- a) création de l'entête
CREATE OR REPLACE PACKAGE Livre AS
	FUNCTION AdhesionAjour(v_Numero number) RETURN boolean;
	FUNCTION AjouteMembre(v_Nom IN char, v_Prenom IN char, v_Adresse IN char, v_Mobile IN char, v_Adhesion IN date, v_Duree IN number) RETURN number;
	FUNCTION DureeMoyenne(v_Isbn IN number, v_Exemplaire IN number default NULL) RETURN number;
	PROCEDURE EmpruntExpress(v_Membre number, v_Isbn number, v_Exemplaire number);
	FUNCTION EmpruntMoyen(v_Membre IN number) RETURN number;
	FUNCTION FinValidite(v_Numero IN number) RETURN Date;
	PROCEDURE MajEtatExemplaire;
	FUNCTION MesureActivite(v_Mois IN number) RETURN number;
	PROCEDURE PurgeMembres;
	PROCEDURE RetourExemplaire(v_Isbn IN number, v_Numero IN number);
	PROCEDURE SupprimeExemplaire(v_Isbn IN number, v_Numero IN number);
END Livre;
/
-- b) création du corps
CREATE OR REPLACE PACKAGE BODY Livre AS
--*****Fonction AdhesionAjour*****
FUNCTION AdhesionAjour(v_Numero number) RETURN boolean AS
BEGIN 
	IF (FinValidite(v_Numero)>= sysdate())
		THEN RETURN TRUE;
	ELSE 
		RETURN FALSE;
	END IF;
END;

--*****Fonction AjouteMembre*****
FUNCTION AjouteMembre (v_Nom IN char, v_Prenom IN char, v_Adresse IN char, v_Mobile IN char, v_Adhesion IN date, v_Duree IN number) RETURN number AS v_Numero Membres.Numero%TYPE;
BEGIN 
	INSERT INTO Membres (Numero, Nom, Prenom, Adresse, Mobile, Adhesion, Duree)
	VALUES (seq_membre.nextval, v_Nom, v_Prenom, v_Adresse, v_Mobile, v_Adhesion, v_Duree)
	RETURNING Numero INTO v_Numero;
	RETURN v_Numero;
END;

--*****Fonction DureeMoyenne*****
FUNCTION DureeMoyenne (v_Isbn IN number, v_Exemplaire IN number default NULL) RETURN number IS v_Duree number;
BEGIN
	IF (v_Exemplaire IS NULL) THEN
		SELECT AVG(TRUNC(Rendule,'DD')-TRUNC(Creele,'DD')+1) INTO v_Duree
		FROM Emprunts, Details
		WHERE Emprunts.Numero=Details.Emprunt
		AND Details.Isbn=v_Isbn
		AND Rendule IS NOT NULL;
	ELSE
		SELECT AVG(TRUNC(Rendule,'DD')-TRUNC(Creele,'DD')+1) INTO v_Duree
		FROM Emprunts, Details
		WHERE Emprunts.Numero=Details.Emprunt
		AND Details.Exemplaire=v_Exemplaire
		AND Rendule IS NOT NULL;
	END IF;
	RETURN v_Duree;
END;

--*****Fonction EmpruntExpress*****
PROCEDURE EmpruntExpress (v_Membre number, v_Isbn number, v_Exemplaire number) AS v_Emprunt Emprunts.Numero%TYPE;
BEGIN
	INSERT INTO Emprunts (Numero, Membre, Creele) VALUES (seq_emprunts.nextval, v_Membre, sysdate)
	RETURNING Numero INTO v_Emprunt;
	INSERT INTO Details (Emprunt, Numero, Isbn, Exemplaire) VALUES (v_Emprunt, 1, v_Isbn, v_Exemplaire);
END;

--*****Fonction EmpruntMoyen*****
FUNCTION EmpruntMoyen (v_Membre IN number) RETURN number IS v_DureeMoyenne number;
BEGIN 
	SELECT TRUNC(AVG(TRUNC(Rendule,'DD')-TRUNC(Creele,'DD')+1), 2) INTO v_DureeMoyenne
	FROM Emprunts, Details
	WHERE Emprunts.Membre=v_Membre
	AND Details.Emprunt=Emprunts.Numero
	AND Details.Rendule IS NOT NULL;
	RETURN v_DureeMoyenne;
END;

--*****Fonction FinValidite*****
FUNCTION FinValidite(v_Numero IN number) RETURN Date IS v_fin date;
BEGIN
	SELECT ADD_MONTHS(Adhesion, Duree) INTO v_fin
	FROM Membres
	WHERE Numero=v_Numero;
	RETURN v_fin;
END;

--*****Fonction MajEtatExemplaire*****
PROCEDURE MajEtatExemplaire IS 
	CURSOR c_Exemplaires IS SELECT * FROM Exemplaires
		FOR UPDATE OF NombreEmprunts, DateCalculEmprunts;
	v_Nbre Exemplaires.NombreEmprunts%TYPE;
BEGIN 
	-- On parcoure d'abord l'ensemble des Exemplaires
	FOR v_Exemplaire IN c_Exemplaires LOOP
		-- On calcule le nombre d'emprunts
		SELECT count(*) INTO v_Nbre
		FROM Details, Emprunts
		WHERE Details.Emprunt=Emprunts.Numero
		AND Isbn=v_Exemplaire.Isbn
		AND Exemplaire=v_Exemplaire.Numero
		AND Creele >= v_Exemplaire.DateCalculEmprunts;
		-- On met à jour les informations concernant les exemplaires
		UPDATE Exemplaires SET
		NombreEmprunts=NombreEmprunts+v_Nbre, DateCalculEmprunts=sysdate
		WHERE CURRENT OF c_Exemplaires;
		-- On met à jour l'état des exemplaires
		UPDATE Exemplaires SET Etat='NE' WHERE NombreEmprunts <= 10;
		UPDATE Exemplaires SET Etat='BO' WHERE NombreEmprunts BETWEEN 11 AND 25;
		UPDATE Exemplaires SET Etat='MO' WHERE NombreEmprunts BETWEEN 26 AND 40;
		UPDATE Exemplaires SET Etat='DO' WHERE NombreEmprunts BETWEEN 41 AND 60;
		UPDATE Exemplaires SET Etat='MA' WHERE NombreEmprunts >= 61;
		-- POur finir on valide les modifications
		COMMIT;
	END LOOP;
END;

--*****Fonction MesureActivite*****
FUNCTION MesureActivite (v_Mois IN number) RETURN number IS
CURSOR c_Activite(v_M IN number) IS
	SELECT Membre, count(*)
	FROM Emprunts, Details
	WHERE Details.Emprunt=Emprunts.Numero
	AND MONTHS_BETWEEN(sysdate, Creele) <v_M
	GROUP BY Membre
	ORDER BY 2 DESC;
v_Membre c_Activite%ROWTYPE;

BEGIN
	OPEN c_Activite(v_Mois);
	FETCH c_Activite INTO v_Membre;
	CLOSE c_Activite;
	RETURN v_Membre.Membre;
END;

--*****Fonction PurgeMembres*****
PROCEDURE PurgeMembres AS
CURSOR c_Membres IS SELECT Numero FROM Membres WHERE (TRUNC(sysdate(), 'YYYY') - TRUNC(ADD_MONTHS(Adhesion, Duree), 'YYYY'))>3;
BEGIN 
	FOR v_Numero IN c_Membres LOOP
		BEGIN
			DELETE FROM Membres WHERE Numero=v_Numero.Numero;
			-- On valide ensuite la transaction avec un commit
			COMMIT;
		EXCEPTION	
			WHEN OTHERS THEN NULL;
		END;
	END LOOP;
END;

--*****Fonction RetourExemplaire*****
PROCEDURE RetourExemplaire (v_Isbn IN number, v_Numero IN number) AS
BEGIN
	UPDATE Details SET Rendule=sysdate
	WHERE Rendule IS NULL
	AND Isbn=v_Isbn AND Exemplaire=v_Numero;
END;

--*****Fonction SupprimeExemplaire*****
PROCEDURE SupprimeExemplaire (v_Isbn IN number, v_Numero IN number) AS
BEGIN
	-- On supprime l'exemplaire choisi
	DELETE FROM Exemplaires WHERE Isbn=v_Isbn AND Numero=v_Numero;
	IF (SQL%ROWCOUNT=0) THEN RAISE NO_DATA_FOUND;
	END IF;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
	RAISE_APPLICATION_ERROR(-20510,'Cet exemplaire n''existe pas ou plus dans la bibliothèque');
END;

END Livre;
/

-------------------------------------------------------------------------------------------

--VI) Déclencheurs de bases de données

--1)
CREATE TRIGGER after_delete_Exemplaires
	AFTER DELETE ON Exemplaires
	FOR EACH ROW 
DECLARE
	v_Nbre number(3);
BEGIN
	DELETE FROM Ouvrages WHERE Isbn= :old.Isbn;
EXCEPTION
	WHEN OTHERS THEN NULL;
END;
/

--2)
CREATE OR REPLACE TRIGGER after_insert_Emprunts
	AFTER INSERT ON Emprunts
	FOR EACH ROW
DECLARE
	v_FinValidite date;
BEGIN
	-- On calcule la date de fin de validité de l'adhésion d'un membre voulant emprunter un exemplaire
	--ADD_MONTHS(i,j) permet de calculer la date de fin en rajoutant j mois à la date i
	SELECT ADD_MONTHS(Adhesion, Duree) INTO v_FinValidite
	FROM Membres
	WHERE Numero= :new.Membre;
	-- On compare la date de fin de validité avec la date du jour
	IF(v_FinValidite<sysdate) THEN
		-- On lève une exception 
		RAISE_APPLICATION_ERROR(-20602,'Le membre n''est pas à jour, il ne peut pas emprunter d''ouvrages');
	END IF;
END;
/

--3)
CREATE OR REPLACE TRIGGER before_update_Emprunts
	BEFORE UPDATE ON Emprunts
	FOR EACH ROW
	WHEN (new.Membre != old.Membre)
BEGIN
	-- Exécution du déclencheur si une modification sur le membre est effectuée
	RAISE_APPLICATION_ERROR(-20603, 'Il est impossible de modifier ce membre');
END;
/

--4)
CREATE OR REPLACE TRIGGER after_update_Details
	AFTER UPDATE ON Details
	FOR EACH ROW
	WHEN ((old.Isbn != new.Isbn) OR (old.Exemplaire != new.Exemplaire))
BEGIN
	-- On regarde si l'ancien ISBN est différent du nouveau ou pas
	IF ( :old.Isbn != :new.Isbn) THEN
		RAISE_APPLICATION_ERROR(-20641, 'Il est impossible de changer d''ouvrage');
	ELSE
		RAISE_APPLICATION_ERROR(-20642, 'Il est impossible de changer d''exemplaire');
	END IF;
END;
/

--5)
CREATE OR REPLACE TRIGGER bef_ins_update_Exemplaires
	BEFORE INSERT OR UPDATE OF NombreEmprunts ON Exemplaires
	FOR EACH ROW
BEGIN
	--On regarde le nombre d'emprunts en comptant celui là
	IF (:new.NombreEmprunts<=10) THEN :new.Etat :='NE';
	END IF;
	IF (:new.NombreEmprunts BETWEEN 11 AND 25) THEN :new.Etat :='BO';
	END IF;
	IF (:new.NombreEmprunts BETWEEN 26 AND 40) THEN :new.Etat :='MO';
	END IF;
	IF (:new.NombreEmprunts BETWEEN 41 AND 60) THEN :new.Etat :='DO';
	END IF;
	IF (:new.NombreEmprunts>=61) THEN :new.Etat :='MA';
	END IF;
END;
/

--6)
CREATE OR REPLACE TRIGGER after_delete_Details
	AFTER DELETE ON Details
	FOR EACH ROW
DECLARE
	-- Le pragma permet les roll back/commit si besoin.
	PRAGMA AUTONOMOUS_TRANSACTION;
	v_Creele Emprunts.Creele%TYPE;
	v_DateCalculEmprunts Exemplaires.DateCalculEmprunts%TYPE;
BEGIN
	--calcul ne concernant que les éléments les plus récents
	SELECT Creele INTO v_Creele FROM Emprunts WHERE Numero=:old.Emprunt;
	SELECT DateCalculEmprunts INTO v_DateCalculEmprunts FROM Exemplaires WHERE Exemplaires.Isbn=:old.Isbn AND Exemplaires.Numero=:old.Exemplaire;
	IF(v_DateCalculEmprunts<v_Creele) THEN 
		-- la valoraisation du nombre d'emprunts est antérieure à la location
		UPDATE Exemplaires
		SET NombreEmprunts=NombreEmprunts+1
		WHERE Exemplaires.Isbn=:old.Isbn AND Exemplaires.Numero=:old.Exemplaire;
	END IF;
	COMMIT;
END;
/
-- Impossible d'effectuer une mise à jour plus complète de la valeur contenue dans la colonne NombreEmprunts car il n'est pas possible de faire une requête SELECT dans le déclencheur

--7)
-- étape 1 : Modification de la structure des tables des Emprunts et des Details en y ajoutant une colonne pour conserver le nom de l'utilisateur et une autre pour conserver la date et l'heure de l'opération
ALTER TABLE Emprunts ADD(AjoutePar varchar2(80), AjouteLe date);
ALTER TABLE Details ADD(ModifiePar varchar2(80), ModifieLe date);
-- étape 2a : Définition d'un déclencheur dans la table des Emprunts
CREATE OR REPLACE TRIGGER before_insert_Emprunts
	BEFORE INSERT ON Emprunts
	FOR EACH ROW
BEGIN
	-- On récupère le nom de l'utilisateur = employé
	:new.AjoutePar :=user();
	-- On récupère la date et l'heure 
	:new.AjouteLe :=sysdate();
END;
/
-- étape 2b : Définition d'un déclencheur dans la table des Details
CREATE OR REPLACE TRIGGER before_update_Details
	BEFORE UPDATE ON Emprunts
	FOR EACH ROW
	WHEN (old.Rendule IS NULL AND new.Rendule IS NOT NULL)
BEGIN
	-- On récupère le nom de l'utilisateur = employé
	:new.ModifiePar :=user();
	-- On récupère la date et l'heure 
	:new.ModifieLe :=sysdate();
END;
/

--8)
CREATE OR REPLACE FUNCTION AnalyseActivite(v_Employe in char default NULL, v_Jour in date default NULL) 
RETURN number IS
	v_ResultatDeparts number(6) :=0;
	v_ResultatRetours number(6) :=0;
BEGIN
	-- On traite le cas où l'analyse porte sur un utilisateur
	IF(v_Employe IS NOT NULL AND v_Jour IS NULL) THEN
		SELECT count(*) INTO v_ResultatDeparts FROM Emprunts WHERE AjoutePar=v_Employe;
		SELECT count(*) INTO v_ResultatRetours FROM DEtails WHERE ModifiePar=v_Employe;
		-- On retourne le résultat et on quitte la fonction
		RETURN v_ResultatDeparts+v_ResultatRetours;
	END IF;
	-- On traite le cas où l'analyse porte sur une journée
	IF (v_Employe IS NULL AND v_Jour IS NOT NULL) THEN 
		SELECT count(*) INTO v_ResultatDeparts FROM Emprunts WHERE AjouteLe=v_Jour;
		SELECT count(*) INTO v_ResultatRetours FROM DEtails WHERE ModifieLe=v_Jour;
		-- On retourne le résultat et on quitte la fonction
		RETURN v_ResultatDeparts+v_ResultatRetours;	
	END IF;
	-- On traite le cas où l'analyse porte sur un utilisateur et une journée
	IF(v_Employe IS NOT NULL AND v_Jour IS NOT NULL) THEN
		SELECT count(*) INTO v_ResultatDeparts FROM Emprunts WHERE AjoutePar=v_Employe AND AjouteLe=v_Jour;
		SELECT count(*) INTO v_ResultatRetours FROM DEtails WHERE ModifiePar=v_Employe AND ModifieLe=v_Jour;
		-- On retourne le résultat et on quitte la fonction
		RETURN v_ResultatDeparts+v_ResultatRetours;
	END IF;
	-- POur le dernier cas restant, le retour est 0
	RETURN 0;
END;
/

--9)
CREATE OR REPLACE TRIGGER before_insert_Details
	BEFORE INSERT ON Details
	FOR EACH ROW
DECLARE 
	v_Etat Emprunts.Etat%TYPE;
BEGIN
	SELECT Etat INTO v_Etat FROM Emprunts WHERE Numero=:new.Emprunt;
	IF (v_Etat !='EC') THEN RAISE_APPLICATION_ERROR (-20610, 'Il est interdit d''ajouter des détails pour cet exemplaire');
	END IF;
END;
/
