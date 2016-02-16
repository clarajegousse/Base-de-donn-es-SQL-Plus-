-- TP BASES DE DONNEES AVANCEES POUR LES BIOLOGISTES
-- 26 Janvier 2016
-- Clara Jegousse/Victor Gaborit
-- Master 2 Bioinformatique

	------------------------------------------

-- * Supression des tables
-- si on souhaite recommencer le projet depuis le début il faut supprimer les tables dans l'ordre donnée si dessous 
-- si les tables sont supprimées dans le désordre, on aura une erreur du fait des contraintes de clés que l'on a ajouté et les tables ne seront pas supprimées
DROP TABLE Details;
DROP TABLE Emprunts;
DROP TABLE Membres;
DROP TABLE Exemplaires;
DROP TABLE Ouvrages;
DROP TABLE Genres;
DROP SEQUENCE seq_membre;

	------------------------------------------

-- I) Langage de définition de données

-- 1) Mise en place des tables en utilisant la syntaxe SQL Oracle

-- Création de la table Genres
CREATE TABLE Genres (
code CHAR(5),
libelle VARCHAR2(80) NOT NULL,
CONSTRAINT pk_genres PRIMARY KEY(code)); 
-- L'attribut code sera la clé primaire de cette table

-- Création de la table Ouvrages
CREATE TABLE Ouvrages (
isbn NUMBER(10), 
titre VARCHAR2(200) NOT NULL,
auteur VARCHAR2(80),
genre CHAR(5) NOT NULL, 
editeur VARCHAR2(80),
CONSTRAINT pk_ouvrages PRIMARY KEY(isbn),
-- Le numero isbn du livre est la clé primaire de la table
CONSTRAINT fk_ouvrages_genres FOREIGN KEY(genre) REFERENCES Genres(code));
-- L'attribut genre est une clé étrangère qui fait référence à l'attribut code dans la table Genres 

-- Création de la table Exemplaires
CREATE TABLE Exemplaires (
isbn NUMBER(10),
numero NUMBER(3),
etat CHAR(5),
CONSTRAINT pk_exemplaires PRIMARY KEY(isbn, numero),
-- Le numero isbn du livre et le numero de l'exemplaire forment à eux deux la clé primaire de la table
CONSTRAINT fk_exemplaires_ouvrages FOREIGN KEY(isbn) REFERENCES Ouvrages(isbn),
-- L'attribut isbn est une clé étrangère qui fait référence à l'attribut isbn dans la table Ouvrages 
CONSTRAINT ck_exemplaires_etat CHECK (etat IN('NE', 'BO', 'MO', 'MA')));
-- La contrainte ck_exemplaires_etat définie les seules valeurs possibles pour l'attribut etat de la table

-- Création de la table Membres
CREATE TABLE Membres (
numero NUMBER(6), 
nom VARCHAR2(80) NOT NULL,
prenom VARCHAR2(80) NOT NULL,
adresse VARCHAR2(200) NOT NULL,
telephone CHAR(10) NOT NULL,
adhesion date NOT NULL,
duree NUMBER(2) NOT NULL,
CONSTRAINT pk_membres PRIMARY KEY(numero),
-- Le numero du membre est unique, c'est la clé primaire de la table
CONSTRAINT ck_membres_duree check (duree>=0));
-- L'attribut durée correspond à la durée de l'abonnement c'est forcément une valeur positive qui est vérifiée par la contrainte ck_membres_duree 

-- Création de la table Emprunts
CREATE TABLE Emprunts (
numero NUMBER(10), 
membre NUMBER(6),
creele DATE DEFAULT SYSDATE,
-- La valeur par défault de l'attribut creele est la date au moment de l'emprunt
CONSTRAINT pk_emprunts PRIMARY KEY(numero),
-- Le numero d'emprunt sera unique, c'est la clé primaire de la table
CONSTRAINT fk_emprunts_membres FOREIGN KEY(membre) REFERENCES Membres(numero));
-- L'attribut membre est une clé étrangère faisant référence à l'attribut numero dans la table Membres

-- Création de la table DetailsEmprunts
CREATE TABLE DetailsEmprunts (
emprunt NUMBER(10), 
numero NUMBER(3),
-- Si le membre emprunte plusieurs ouvrages lors d'un même emprunt, on peut les différencier grâce à cet attribut
isbn NUMBER(10),
exemplaire NUMBER(3),
rendule DATE,
CONSTRAINT pk_detailsemprunts PRIMARY KEY (emprunt, numero),
-- Le numéro d'emprunt ainsi que le numero correspondant a chaque ouvrage d'un même emprunt forment à eux deux la clé primaire de la table
CONSTRAINT fk_details_emprunts FOREIGN KEY(emprunt) REFERENCES Emprunts(numero),
-- Le numéro d'emprunt est un clé étrangère faisant référence au numero d'emprunt dans la table Emprunts
CONSTRAINT fk_detailsemprunts_exemplaires FOREIGN KEY (isbn, exemplaire) REFERENCES Exemplaires(isbn, numero));
-- Le numéro isbn et le numéro d'exemplaire forment une autre clé étrangère faisant référence à l'identifiant isbn et au numéro d'exemplaire dans la table Exemplaires

-- 2) Création d'une séquence demarrant à 1 avec un pas de 1
CREATE SEQUENCE seq_membre START WITH 0 INCREMENT BY 1 MINVALUE 0;

-- 3) Ajout d'une nouvelle contrainte qui vérifie que chaque ligne nom, prenom et telephone est unique
ALTER TABLE Membres ADD CONSTRAINT ck_uniq_membres UNIQUE (nom, prenom, telephone);

-- 4) Ajout de l'attribut mobile dans la table Membres pour récupérer le numero de téléphone portable 
ALTER TABLE Membres ADD mobile CHAR(10);
-- Ajout d'une contrainte qui va vérifier que le numéro pour cet attribut est bien celui d'un portable (commencant par 06)
ALTER TABLE Membres ADD CONSTRAINT ck_membres_mobile CHECK (mobile LIKE '06%');

-- 5) Suppression de la colonne contenant le numéro de téléphone fixe dans la table Membres
-- On doit d'abord enlever la contrainte d'unicité déclarée à la question 3)
ALTER TABLE Membres DROP CONSTRAINT ck_uniq_membres;
--On passe l'attribut telephone comme inutilisé
ALTER TABLE Membres SET UNUSED (telephone);
--On supprime de la table Membres toutes les colonnes inutilisées
ALTER TABLE Membres DROP UNUSED COLUMNS;
--On crée à nouveau la contrainte d'unicité avec, non plus l'attribut téléphone, mais l'attribut mobile
ALTER TABLE Membres ADD CONSTRAINT ck_uniq_membres UNIQUE (nom, prenom, mobile);

-- 6) Création des index de chaque table pour faciliter les jointures sur les clés étrangères
CREATE index idx_ouvrages_genre ON Ouvrages(genre);
CREATE index idx_exemplaires_isbn ON Exemplaires(isbn);
CREATE index idx_emprunts_membre ON Emprunts(membre);
CREATE index idx_details_emprunt ON DetailsEmprunts(emprunt);
CREATE index idx_details_exemplaire ON DetailsEmprunts(isbn, exemplaire);

-- 7) Suppression de toutes les lignes précédentes dans la table DetailsEmprunts qui font référence à la table Emprunts
-- On élimine d'abord la contrainte sur la clé étrangère courante de la table DetailsEmprunts
ALTER TABLE DetailsEmprunts DROP CONSTRAINT fk_details_emprunts;
--On rajoute cette même contrainte en précisant que la supression d'une ligne se fait en cascade,
-- c'est a dire que toute les lignes correspondant à un emprunt sont effacées
ALTER TABLE DetailsEmprunts ADD CONSTRAINT fk_details_emprunts FOREIGN KEY (emprunt) REFERENCES Emprunts(numero) ON DELETE CASCADE;

--8) Modifiez la table Exemplaires 
-- On précise que la valeur Neuf est la valeur par défault de l'attribut etat dans la table Exemplaires 
ALTER TABLE Exemplaires MODIFY (etat CHAR(2) DEFAULT 'NE');
-- lorsque l'on rajouteras des ouvrages, si on ne précise rien pour cet attribut, il seront automatiquement mis à neuf

--9) Création d'un synonyme Abonnes pour la table Membres
-- ainsi elle peut être appelée des deux facons
CREATE SYNONYM Abonnes FOR Membres;

-- NB: Cette commande ne fonctionne pas sur les ordinateurs de la faculté car on ne possède pas les bons privilèges

-- 10) Renommage de table DetailsEmprunts
-- Le nouveau nom de la table est Details
RENAME DetailsEmprunts TO Details;

	------------------------------------------

-- II) Langage de Manipulation de Données

--1) Insertion de valeurs :

-- Dans la table Genres
INSERT INTO Genres(code, libelle) VALUES ('REC', 'Recit');
INSERT INTO Genres(code, libelle) VALUES ('POL', 'Policier');
INSERT INTO Genres(code, libelle) VALUES ('BD', 'Bande Dessinee');
INSERT INTO Genres(code, libelle) VALUES ('INF', 'Informatique');
INSERT INTO Genres(code, libelle) VALUES ('THE', 'Theatre');
INSERT INTO Genres(code, libelle) VALUES ('ROM', 'Roman');

-- Vérification de la table
SELECT * FROM Genres;

-- Dans la table Ouvrages
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
INSERT INTO Ouvrages (isbn, titre, auteur, genre, editeur) VALUES (2020549522, 'L''aventure des manuscrits de la mer morte', DEFAULT, 'REC', 'Seuil');
INSERT INTO Ouvrages (isbn, titre, auteur, genre, editeur) VALUES (2253006327, 'Vingt mille lieues sous les mers', 'Jules Verne', 'ROM', 'LGF');
INSERT INTO Ouvrages (isbn, titre, auteur, genre, editeur) VALUES (2038704015, 'De la terre a la lune', 'Jules Verne', 'ROM', 'Larousse');

-- Vérification de la table
SELECT * FROM Ouvrages;

-- Dans la table Exemplaires
-- Etape1 : Pour tous les ouvrages, on crée deux exemplaires, un en bon etat et un autre en moyen
INSERT INTO Exemplaires (isbn, numero, etat) SELECT isbn, 1, 'BO' FROM Ouvrages;
INSERT INTO Exemplaires (isbn, numero, etat) SELECT isbn, 2, 'MO' FROM Ouvrages;
-- Etape2 : On supprime pour l'ouvrage correspondant au numero 2746021285 l'exemplaire 2 car on ne dispose que d'un seul exemplaire pour cet ouvrage
DELETE FROM Exemplaires WHERE isbn=2746021285 and numero=2;
-- Etape3 : On modifie pour l'etat des exemplaires du livre numero 2203314168 (inversion des etats)
UPDATE Exemplaires SET etat='MO' WHERE isbn=2203314168 AND numero=1;
UPDATE Exemplaires SET etat='BO' WHERE isbn=2203314168 AND numero=2;
-- On rajoute un exemplaire en etat neuf pour le livre numero 2203314168
INSERT INTO Exemplaires (isbn, numero, etat) VALUES (2203314168, 3, 'NE');

-- 2) Remplissage de la table Membre
-- On utilise la séquence crée en I-2) pour remplir l'attribut numero
INSERT INTO Membres (numero, nom, prenom, adresse, mobile, adhesion, duree) VALUES (seq_membre.nextval, 'ALBERT', 'Anne', '13 rue des alpes', '0601020304', SYSDATE-60, 1);
INSERT INTO Membres (numero, nom, prenom, adresse, mobile, adhesion, duree) VALUES (seq_membre.nextval, 'BERNAUD', 'Barnabe', '6 rue des becasses', '0602030105', SYSDATE-10, 3);
INSERT INTO Membres (numero, nom, prenom, adresse, mobile, adhesion, duree) VALUES (seq_membre.nextval, 'CUVARD', 'Camille', '52 rue des cerisiers', '0602010509', SYSDATE-100, 6);
INSERT INTO Membres (numero, nom, prenom, adresse, mobile, adhesion, duree) VALUES (seq_membre.nextval, 'DUPOND', 'Daniel', '11 rue des daims', '0610236515', SYSDATE-250, 12);
INSERT INTO Membres (numero, nom, prenom, adresse, mobile, adhesion, duree) VALUES (seq_membre.nextval, 'EVROUX', 'Eglantine', '34 rue des elfes', '0658963125', SYSDATE-150, 6);
INSERT INTO Membres (numero, nom, prenom, adresse, mobile, adhesion, duree) VALUES (seq_membre.nextval, 'FREGEON', 'Fernand', '11 rue des Francs', '0602036987', SYSDATE-400, 6);
INSERT INTO Membres (numero, nom, prenom, adresse, mobile, adhesion, duree) VALUES (seq_membre.nextval, 'GORIT', 'Gaston', '96 rue de la glacerie', '0684235781', SYSDATE-150, 1);
INSERT INTO Membres (numero, nom, prenom, adresse, mobile, adhesion, duree) VALUES (seq_membre.nextval, 'HEVARD', 'Hector', '12 rue haute', '0608546578', SYSDATE-250, 12);
INSERT INTO Membres (numero, nom, prenom, adresse, mobile, adhesion, duree) VALUES (seq_membre.nextval, 'INGRAND', 'Irene', '54 rue des iris', '0605020409', SYSDATE-50, 12);
INSERT INTO Membres (numero, nom, prenom, adresse, mobile, adhesion, duree) VALUES (seq_membre.nextval, 'JUSTE', 'Julien', '5 place des Jacobins', '0603069876', SYSDATE-100, 6);

-- 3) Remplissage

-- De la table Emprunts : 
INSERT INTO Emprunts (numero, membre, creele) VALUES (1, 1, SYSDATE-200);
INSERT INTO Emprunts (numero, membre, creele) VALUES (2, 3, SYSDATE-190);
INSERT INTO Emprunts (numero, membre, creele) VALUES (3, 4, SYSDATE-180);
INSERT INTO Emprunts (numero, membre, creele) VALUES (4, 1, SYSDATE-170);
INSERT INTO Emprunts (numero, membre, creele) VALUES (5, 5, SYSDATE-160);
INSERT INTO Emprunts (numero, membre, creele) VALUES (6, 2, SYSDATE-150);
INSERT INTO Emprunts (numero, membre, creele) VALUES (7, 4, SYSDATE-140);
INSERT INTO Emprunts (numero, membre, creele) VALUES (8, 1, SYSDATE-130);
INSERT INTO Emprunts (numero, membre, creele) VALUES (9, 9, SYSDATE-120);
INSERT INTO Emprunts (numero, membre, creele) VALUES (10, 6, SYSDATE-110);
INSERT INTO Emprunts (numero, membre, creele) VALUES (11, 1, SYSDATE-100);
INSERT INTO Emprunts (numero, membre, creele) VALUES (12, 6, SYSDATE-90);
INSERT INTO Emprunts (numero, membre, creele) VALUES (13, 2, SYSDATE-80);
INSERT INTO Emprunts (numero, membre, creele) VALUES (14, 4, SYSDATE-70);
INSERT INTO Emprunts (numero, membre, creele) VALUES (15, 1, SYSDATE-60);
INSERT INTO Emprunts (numero, membre, creele) VALUES (16, 3, SYSDATE-50);
INSERT INTO Emprunts (numero, membre, creele) VALUES (17, 1, SYSDATE-40);
INSERT INTO Emprunts (numero, membre, creele) VALUES (18, 5, SYSDATE-30);
INSERT INTO Emprunts (numero, membre, creele) VALUES (19, 4, SYSDATE-20);
INSERT INTO Emprunts (numero, membre, creele) VALUES (20, 1, SYSDATE-10);

-- De la table Details :
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (1, 1, 2038704015, 1, SYSDATE-195);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (1, 2, 2070367177, 2, SYSDATE-190);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (2, 1, 2080720872, 1, SYSDATE-180);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (2, 2, 2203314168, 1, SYSDATE-179);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (3, 1, 2038704015, 1, SYSDATE-170);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (4, 1, 2203314168, 2, SYSDATE-155);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (4, 2, 2080720872, 1, SYSDATE-155);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (4, 3, 2266085816, 1, SYSDATE-159);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (5, 1, 2038704015, 2, SYSDATE-140);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (6, 1, 2266085816, 2, SYSDATE-141);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (6, 2, 2080720872, 2, SYSDATE-130);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (6, 3, 2746021285, 2, SYSDATE-133);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (7, 1, 2070367177, 2, SYSDATE-100);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (8, 1, 2080720872, 1, SYSDATE-116);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (9, 1, 2038704015, 1, SYSDATE-100);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (10, 1, 2080720872, 2, SYSDATE-107);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (10, 2, 2746026090, 1, SYSDATE-78);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (11, 1, 2746021285, 1, SYSDATE-81);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (12, 1, 2203314168, 1, SYSDATE-86);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (12, 2, 2038704015, 1, SYSDATE-60);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (13, 1, 2070367177, 1, SYSDATE-65);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (14, 1, 2266091611, 1, SYSDATE-66);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (15, 1, 2266085816, 1, SYSDATE-50);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (16, 1, 2253010219, 2, SYSDATE-41);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (16, 2, 2070367177, 2, SYSDATE-41);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (17, 1, 2877065073, 2, SYSDATE-36);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (18, 1, 2070367177, 1, SYSDATE-14);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (19, 1, 2746026090, 1, SYSDATE-12);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (20, 1, 2266091611, 1, DEFAULT);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (20, 2, 2253010219, 1, DEFAULT);

-- 4) Consultation des données des tables
SELECT * FROM Genres;
SELECT * FROM Ouvrages;
SELECT * FROM Exemplaires;
SELECT * FROM Membres;
SELECT * FROM Emprunts;
SELECT * FROM Details;

-- 5) Activation de l'historique des mouvements sur les tables Membres et Details
ALTER TABLE Membres ENABLE ROW MOVEMENT;
ALTER TABLE Details ENABLE ROW MOVEMENT;

-- 6) Ajout d’une colonne 
-- On ajoute par défault la valeur EC pour l'attribut etat de la table Emprunts qui signifie que l'emprunt est en cours
ALTER TABLE Emprunts ADD (etat CHAR(2) DEFAULT 'EC');
-- On ajoute une contrainte qui n'autorise que les valeurs EC ou RE (pour Rendu) pour l'attribut etat de la table Emprunts
ALTER TABLE Emprunts ADD CONSTRAINT ck_emprunts_etat CHECK (etat IN ('EC', 'RE'));
-- On met à jour l'attribut etat avec la valeur RE pour tous les emprunts qui ont une date de retour (rendule différent de NULL)
UPDATE Emprunts SET etat='RE' WHERE etat='EC' AND numero NOT IN (SELECT emprunt FROM Details WHERE rendule IS NULL);

-- 7) Mise à jour conditionnelle de la table Details
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (7, 2, 2038704015, 1, SYSDATE-136);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (8, 2, 2038704015, 1, SYSDATE-127);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (11, 2, 2038704015, 1, SYSDATE-95);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (15, 2, 2038704015, 1, SYSDATE-54);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (16, 3, 2038704015, 1, SYSDATE-43);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (17, 2, 2038704015, 1, SYSDATE-36);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (18, 2, 2038704015, 1, SYSDATE-24);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (19, 2, 2038704015, 1, SYSDATE-13);
INSERT INTO Details (emprunt, numero, isbn, exemplaire, rendule) VALUES (20, 3, 2038704015, 1, SYSDATE-3);

-- On réinitialise l'état de l'exemplaire 1 du livre numero 2038704015
UPDATE Exemplaires SET etat='NE' WHERE isbn=2038704015 AND numero=1;

-- Etape 1 : Création d'une table temporaire qui va permettre de compter le nombre de locations de chaque exemplaire
CREATE TABLE tempoExemplaires AS SELECT isbn, exemplaire, COUNT(*) AS locations 
FROM Details
GROUP BY isbn, exemplaire;

-- Etape 2 : On met à jour l'état des exemplaires
MERGE INTO Exemplaires E
USING (SELECT isbn, exemplaire, locations FROM tempoExemplaires) T 
ON (T.isbn=E.isbn AND T.exemplaire=E.numero)
WHEN MATCHED THEN
-- Si les exemplaires ont été loués entre 11 et 25 fois on les met à BO (Bon)
UPDATE SET etat='BO' WHERE T.locations BETWEEN 11 AND 25
-- S'ils ont été loués plus de 60 fois, on les supprime
DELETE WHERE T.locations>60;
-- Si on souhaite plutôt marquer leur état comme mauvais : 
-- UPDATE SET etat='MA' WHERE T.locations>60;

-- Etape 3 : On supprime la table temporaire
DROP TABLE tempoExemplaires;

-- 8)  Suppression de tous les exemplaires dont l’état est mauvais
-- Ajout de valeur test pour la suppression des exemplaires en mauvais état
INSERT INTO Exemplaires (isbn, numero, etat) VALUES (2203314168, 4, 'MA');
INSERT INTO Exemplaires (isbn, numero, etat) VALUES (2746021285, 3, 'MA');
-- On supprime les exemplaires dont l'état est Mauvais (si on a choisi de les noter MA sans les supprimer à la question précédente)
DELETE FROM Exemplaires WHERE etat='MA';

-- 9) Liste des ouvrages de la bibliothèque
SELECT * FROM Ouvrages;

-- Si on ne veut que les titres des ouvrages :
-- SELECT titre FROM Ouvrages;

-- 10)  On affiche les membres qui ont emprunté un ouvrage depuis plus de 2 semaines et le titre de l'ouvrage 
-- (On ne regarde que les emprunts qui n'ont pas étés rendu)
SELECT Membres.*, Ouvrages.titre
FROM Membres, Emprunts, Details, Ouvrages
WHERE Emprunts.membre=Membres.numero
AND Details.emprunt=Emprunts.numero
AND TRUNC(SYSDATE, 'WW')-TRUNC(creele, 'WW') > 2
AND Details.isbn=Ouvrages.isbn
AND Details.rendule IS NULL;

-- 11) On affiche le nombre d'ouvrages par Genre
SELECT genre, COUNT(*) as nombre
FROM Exemplaires, Ouvrages
WHERE Ouvrages.isbn=Exemplaires.isbn
GROUP BY genre;

-- 12) On affiche la durée moyenne d'un emprunt
SELECT AVG(rendule-creele) AS "Duree Moyenne"
FROM Emprunts, Details
WHERE Emprunts.numero=Details.emprunt AND rendule IS NOT NULL;

-- 13) On affiche la durée moyenne d'un emprunt selon le genre de l'ouvrage
SELECT genre, AVG(rendule-creele) AS "Duree Moyenne"
FROM Emprunts, Details, Ouvrages
WHERE Emprunts.numero=Details.emprunt AND Details.isbn=Ouvrages.isbn AND rendule IS NOT NULL
GROUP BY genre;

-- 14) On affiche les ouvrages loués plus de 10 fois au cours des 12 derniers mois
SELECT Exemplaires.isbn
FROM Emprunts, Details, Exemplaires
WHERE Details.exemplaire=Exemplaires.numero
AND Details.isbn=Exemplaires.isbn
AND Details.emprunt=Emprunts.numero
AND MONTHS_BETWEEN (SYSDATE, Emprunts.creele) <= 12
GROUP BY Exemplaires.isbn
HAVING COUNT(*) > 10;

-- 15) On affiche les ouvrages avec tous les numero d'exemplaires présents dans la base
SELECT Ouvrages.*, Exemplaires.numero
FROM Ouvrages, Exemplaires
WHERE Ouvrages.isbn=Exemplaires.isbn(+);

-- 16) Création d'une vue qui permet de connaitre le nombre d'ouvrages emprunté par chaque membre et donc de connaitre les ouvrages non restitués
CREATE OR REPLACE VIEW OuvragesEmpruntes AS
SELECT Emprunts.membre, COUNT(*) AS nombreEmprunts
FROM Emprunts, Details
WHERE Emprunts.numero=Details.emprunt
AND Details.rendule IS NULL
GROUP BY Emprunts.membre;

-- Cette commande ne fonctionne pas sur les ordinateurs de la faculté car on ne possède pas les bons privilèges

-- 17) On crée une vue qui permet de connaître le nombre d'emprunts par ouvrage
CREATE OR REPLACE VIEW NombreEmpruntsParOuvrage AS 
SELECT isbn, COUNT(*) AS nombreEmprunts
FROM Details
GROUP BY isbn;
-- NB: Une interrogation sur cette vue en utilisant la clause ORDER BY permettra d'afficher les ouvrages par ordre décroissant du nombre de locations
-- Cette commande ne fonctionne pas sur les ordinateurs de la fac car on ne possède pas les bons privilèges

-- 18) On affiche les membres par ordre alphabétique
SELECT * FROM Membres ORDER BY nom, prenom;

-- 19) Création de la table temporaire globale
CREATE GLOBAL TEMPORARY TABLE tempoGlobaleEmprunts (
isbn CHAR(10),
exemplaire NUMBER(3),
nombreEmpruntsExemplaire NUMBER(10),
nombreEmpruntsOuvrage NUMBER(10)) 
ON COMMIT PRESERVE ROWS;
-- Ajout d'informations pour chaque exemplaire
INSERT INTO tempoGlobaleEmprunts (
isbn, exemplaire, nombreEmpruntsExemplaire)
SELECT isbn, numero, COUNT(*)
FROM Details
GROUP BY isbn, numero;
-- Ajout d'informations pour chaque ouvrage
UPDATE tempoGlobaleEmprunts
SET nombreEmpruntsOuvrage= (SELECT COUNT(*) FROM Details WHERE Details.isbn=tempoGlobaleEmprunts.isbn);
-- Terminaison de la transaction 
COMMIT;
-- Suppression des informations présentes dans la table
TRUNCATE TABLE tempoGlobaleEmprunts;
-- DELETE FROM tempoGlobaleEmprunts; -- cette commande ne permet pas de supprimer la table temporaire par la suite
-- Supprimer la table
DROP TABLE tempoGlobaleEmprunts;

-- 20) On affiche la liste des genres avec pour chaque genre, les ouvrages correspondant
SELECT Genres.libelle, Ouvrages.titre
FROM Ouvrages, Genres
WHERE Genres.code=Ouvrages.genre
ORDER BY Genres.libelle, Ouvrages.titre;

	------------------------------------------

-- III) SQL avancé

-- 1) Affichage du nombre d'emprunts par ouvrage et par exemplaire 
SELECT isbn,exemplaire,COUNT(*) AS nombre
FROM Details
GROUP BY ROLLUP(isbn, exemplaire);
-- solution plus lisible en utilisant DECODE :
SELECT isbn, DECODE(GROUPING(exemplaire), 1, 'Tous exemplaires confondus', exemplaire) AS exemplaire, COUNT(*) AS nombre
FROM Details
GROUP BY ROLLUP(isbn, exemplaire);

-- 2) Affichage de la liste des exemplaires n'ayant pas été empruntés lors des 3 derniers mois
SELECT *
FROM Exemplaires E
WHERE NOT EXISTS (
	SELECT *
	FROM Details D
	WHERE MONTHS_BETWEEN(SYSDATE, rendule) < 3
	AND D.isbn=E.isbn
	AND D.exemplaire=E.numero); 

-- 3) Affichage des ouvrages qui n'ont pas d'exemplaire à l'état neuf
SELECT *
FROM Ouvrages 
WHERE isbn NOT IN (
	SELECT isbn
	FROM Exemplaires
	WHERE etat='NE'); 

-- 4) Affichage de tous les ouvrages qui possèdent le mot 'mer' dans leur titre
SELECT isbn, titre
FROM Ouvrages 
WHERE LOWER (titre) LIKE '%mer%';

-- 5) Affichage de tout les auteurs qui ont la particule 'de' avant leur nom de famille
SELECT DISTINCT auteur
FROM Ouvrages
-- WHERE REGEXP_LIKE (auteur, '^[[:alpha:]]*[[:space:]]de[[:space:]][[:alpha:]]+$'); -- Ne ressort qu'un seul nom sur les deux attendus
WHERE auteur LIKE '% de %';

-- 6) On affiche le public concerné par chaque ouvrage de la bibliothèque
SELECT isbn, titre, CASE genre
WHEN 'BD' THEN 'Jeunesse'
WHEN 'INF' THEN 'Professionnel'
WHEN 'POL' THEN 'Adulte'
WHEN 'REC' THEN 'Tous'
WHEN 'ROM' THEN 'Tous'
WHEN 'THE' THEN 'Tous'
END AS "Public"
FROM Ouvrages;

-- 7) Ajout de commentaires de description de chaque tables de la base
COMMENT ON TABLE Membres
IS 'Descriptifs des membres. Possède le synonymes Abonnes';
COMMENT ON TABLE Genres
IS 'Descriptifs des genres possibles des ouvrages';
COMMENT ON TABLE Ouvrages
IS 'Descriptifs des ouvrages référencés par la bibliothèque';
COMMENT ON TABLE Exemplaires
IS 'Définition précise des livres présents dans la bibliothèque';
COMMENT ON TABLE Emprunts
IS 'Fiche d’emprunt de livres, toujours associée à un et un seul membre';
COMMENT ON TABLE Details
IS 'Chaque ligne correspond à un livre emprunté';

-- 8) Affichage des commentaires associés à chaque table de la base
SELECT table_name, comments
FROM USER_TAB_COMMENTS
WHERE comments IS NOT NULL;

-- 9) Rendre possible cette nouvelle contrainte de fonctionnement
-- On supprime d'abord la contrainte sur la clé etrangère de la table Emprunts
ALTER TABLE Emprunts DROP CONSTRAINT fk_emprunts_membres;
-- On crée à nouveau la contrainte de clé étrangère en rajoutant une vérification de cette contrainte uniquement à la fin de la transaction
ALTER TABLE Emprunts ADD CONSTRAINT fk_emprunts_membres FOREIGN KEY (membre) REFERENCES Membres (numero) INITIALLY DEFERRED;

-- 10) Suppression de la table Details
DROP TABLE Details;

-- 11) Annulation de la précédente commande
FLASHBACK TABLE Details TO BEFORE DROP;

-- 13) On affiche un commentaire sur le nombre d'exemplaires pour chaque ouvrage (Aucun, peu, normal, beaucoup)
SELECT Ouvrages.isbn, Ouvrages.titre, CASE COUNT(*)
WHEN 0 THEN 'Aucun'
WHEN 1 THEN 'Peu'
WHEN 2 THEN 'Peu'
WHEN 3 THEN 'Normal'
WHEN 4 THEN 'Normal'
WHEN 5 THEN 'Normal'
ELSE 'Beaucoup'
END AS "Nombre exemplaires"
FROM Ouvrages, Exemplaires
WHERE Ouvrages.isbn=Exemplaires.isbn
GROUP BY Ouvrages.isbn, Ouvrages.titre;

	------------------------------------------

-- IV) PL/SQL

-- 1) Mise à jour conditionnelle de l'état des examplaires en fonction du nombre d'emprunts

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

-- 2) Suppression conditionnelle

-- Etape1 : vérifier que la colonne Membre de la table des Emprunts accepte les valeurs null.
DESC Emprunts;
-- Si elle n'accepte pas la valeur NULL on fait la modification suivante:
-- ALTER TABLE Emprunts MODIFY (membre NUMBER(6) NULL);

-- Etape 2 : dans le cas où la colonne n'accepte pas la valeur null, on doit modifier la définition de la table
ALTER TABLE Emprunts MODIFY (membre NUMBER(6) NULL);
-- RQ: si la colonne autorise deja les valeurs null, alors l'execution du script se termine par une erreur.

-- Etape 3 : on définit enfin le bloc PL/SQL permettant d'obtenir le résultat souhaité
DECLARE
	-- ADD_MONTHS(i,j) permet de calculer la date de fin en rajoutant j mois à la date i
	CURSOR c_Membres IS SELECT * FROM Membres WHERE MONTHS_BETWEEN (SYSDATE, ADD_MONTHS(adhesion, duree)) > 24;
	v_nombre NUMBER(5);

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

-- 3)
SET serveroutput ON;

DECLARE
	-- 1er curseur pour l'ordre ascendant
	CURSOR c_ordre_croissant IS 
		SELECT E.membre, COUNT(*) 
		FROM Emprunts E, Details D
		WHERE E.numero = D.emprunt
		GROUP BY E.membre
		ORDER BY 2 ASC;

	-- 2ème curseur pour l'ordre descendant
	CURSOR c_ordre_decroissant IS
		SELECT E.membre, COUNT(*)
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

	-- Boucle du 1er au 3ème
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
	-- Boucle de 1 à 3
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


-- 4)

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

		-- Sortie de la boucle si le curseur est vide
		EXIT WHEN c_Ouvrages%NOTFOUND;
		DBMS_OUTPUT.PUT_LINE('Numero: '|| i ||' _isbn :' || v_ouvrage.isbn);
	END LOOP;
	CLOSE c_Ouvrages;
END;
/

-- 5)
-- en PL/SQL
SET serveroutput ON;

DECLARE
	CURSOR c_Membres IS SELECT * FROM Membres;
BEGIN
	-- On traite chaque membre
	FOR v_membre IN c_Membres LOOP
		--ADD_MONTHS(i,j) permet de calculer la date de fin en rajoutant j mois à la date i
		IF (ADD_MONTHS(v_membre.adhesion, v_membre.duree)<SYSDATE+30) THEN
			DBMS_OUTPUT.PUT_LINE('Numero '||v_membre.numero||' '||v_membre.nom);
		END IF;
	END LOOP;
END;
/

-- Même résultat avec une requête SQL -> execution plus rapide
SELECT numero, nom
FROM Membres
-- ADD_MONTHS(i,j) permet de calculer la date de fin en rajoutant j mois à la date i
WHERE ADD_MONTHS(adhesion, duree)<=SYSDATE+30;

-- 6)
-- Etape 1a : mise à jour de la structure de la table
ALTER TABLE Exemplaires ADD (
nombreEmprunts NUMBER(3) DEFAULT 0,
dateCalculEmprunts DATE DEFAULT SYSDATE);
-- Etape 1b : mettre à jour les informations de la table
UPDATE Exemplaires SET dateCalculEmprunts = (
	SELECT MIN(creele) 
	FROM Emprunts E, Details D 
	WHERE E.numero=D.emprunt
	AND D.isbn=Exemplaires.isbn
	AND D.exemplaire=Exemplaires.numero);
UPDATE Exemplaires SET dateCalculEmprunts = SYSDATE
WHERE dateCalculEmprunts IS NULL;
COMMIT;

-- Etape 2 : script PL/SQL
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

-- 7)
DECLARE
	v_nbre NUMBER(6);
	v_total NUMBER(6);
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

-- 8)
DELETE FROM Membres
WHERE numero IN (
	SELECT DISTINCT membre
	FROM Emprunts
	GROUP BY membre
	--ADD_MONTHS(i,j) permet de calculer la date de fin en rajoutant j mois à la date i
	HAVING MAX(creele)< ADD_MONTHS(SYSDATE, -36));

-- 9)
-- Etape 1 : Modification de la structure de la table
ALTER TABLE Membres MODIFY (mobile CHAR(14));

-- Etape 2 : Mise en forme du numéro de téléphone mobile
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
			-- Utilisation de SUBSTR(i,n) qui va prendre n lettres à la position i
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

-- Etape 3 : Définition et activation de la contrainte d'intégrité
ALTER TABLE Membres ADD constraint ck_membres_mobile2 CHECK (REGEXP_LIKE (mobile, '^06 [[:digit:]]{2} [[:digit:]]{2} [[:digit:]]{2} [[:digit:]]{2}$')) ;

	------------------------------------------

--V) PL/SQL procédures et fonctions

-- 1) Fonction FinValidite
CREATE OR REPLACE FUNCTION FinValidite (v_numero IN NUMBER) RETURN DATE IS v_fin DATE;
BEGIN
	--ADD_MONTHS(i,j) permet de calculer la date de fin en rajoutant j mois à la date i
	SELECT ADD_MONTHS(adhesion, duree) INTO v_fin
	FROM Membres
	WHERE numero=v_numero;
	RETURN v_fin;
END;
/

-- Test
select Membres.numero, Membres.nom, FinValidite(Membres.numero) from Membres; 

-- 2) Fonction AdhesionAjour
CREATE OR REPLACE FUNCTION AdhesionAjour(v_numero NUMBER) RETURN BOOLEAN AS
BEGIN 
	IF (FinValidite(v_numero)>= SYSDATE())
		THEN RETURN TRUE;
	ELSE 
		RETURN FALSE;
	END IF;
END;
/

-- Test
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

-- 3) Procédure RetourExemplaire
CREATE OR REPLACE PROCEDURE RetourExemplaire (v_isbn IN NUMBER, v_numero IN NUMBER) AS
BEGIN
	UPDATE Details SET rendule=SYSDATE
	WHERE rendule IS NULL
	AND isbn=v_isbn AND exemplaire=v_numero;
END;
/

-- 4) Procédure PurgeMembres
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

-- Test
EXECUTE PurgeMembres;

-- 5) Fonction MesureActivite
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

-- Test sur 12 mois
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

-- 6) Fonction EmpruntMoyen
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

-- Test
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



-- 7) Fonction DureeMoyenne
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

-- Test
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

-- 8) Procédure MajEtatExemplaire
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
-- RQ: insufficient privileges :(

-- 9) Fonction AjouteMembre
CREATE OR REPLACE FUNCTION AjouteMembre (v_nom IN CHAR, v_prenom IN CHAR, v_adresse IN CHAR, v_mobile IN CHAR, v_adhesion IN DATE, v_duree IN NUMBER) RETURN NUMBER AS v_numero Membres.numero%TYPE;
BEGIN 
	INSERT INTO Membres (numero, nom, prenom, adresse, mobile, adhesion, duree)
	VALUES (seq_membre.nextval, v_nom, v_prenom, v_adresse, v_mobile, v_adhesion, v_duree)
	RETURNING numero INTO v_numero;
	RETURN v_numero;
END;
/

-- Test
DECLARE
	v_numero Membres.numero%TYPE;

BEGIN
	v_numero := AjouteMembre('Personne','Paul','4 rue du centre','06 36 65 65 65',sysdate,3);
	DBMS_OUTPUT.PUT_LINE('Le numero du nouveau membre est le suivant : '||v_numero);
END;
/

-- 10) Procédure SupprimeExemplaire
CREATE OR REPLACE PROCEDURE SupprimeExemplaire (v_isbn IN NUMBER, v_numero IN NUMBER) AS
BEGIN
	-- On supprime l'exemplaire choisi
	DELETE FROM Exemplaires WHERE isbn=v_isbn AND numero=v_numero;
	IF (SQL%ROWCOUNT=0) THEN RAISE NO_DATA_FOUND;
	END IF;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
	RAISE_APPLICATION_ERROR(-20510,'Cet exemplaire n''existe pas');
END;
/

-- Test
 EXECUTE SupprimeExemplaire(203440861,3); 

-- 11) Procédure EmpruntExpress
-- Etape 1 : recherche de la plus grande valeur attribuée à un numéro d'emprunt
SELECT MAX(numero) FROM Emprunts;
-- Etape 2 : création d'une séquence
CREATE SEQUENCE seq_emprunts START WITH 20;
-- Etape 3 : création de la procédure
CREATE OR REPLACE PROCEDURE EmpruntExpress (v_membre NUMBER, v_isbn NUMBER, v_exemplaire NUMBER) AS v_emprunt Emprunts.numero%TYPE;
BEGIN
	INSERT INTO Emprunts (numero, membre, creele) VALUES (seq_emprunts.nextval, v_membre, SYSDATE)
	RETURNING numero INTO v_emprunt;
	INSERT INTO Details (emprunt, numero, isbn, exemplaire) VALUES (v_emprunt, 1, v_isbn, v_exemplaire);
END;
/

-- Test
EXECUTE EmpruntExpress(11,2038704015,1);

-- 12) Création de package
-- a) création de l'entête
CREATE OR REPLACE PACKAGE Livre AS
	FUNCTION AdhesionAjour(v_numero NUMBER) RETURN BOOLEAN;
	FUNCTION AjouteMembre(v_nom IN CHAR, v_prenom IN CHAR, v_adresse IN CHAR, v_mobile IN CHAR, v_adhesion IN DATE, v_duree IN NUMBER) RETURN NUMBER;
	FUNCTION DureeMoyenne(v_isbn IN NUMBER, v_exemplaire IN NUMBER DEFAULT NULL) RETURN NUMBER;
	PROCEDURE EmpruntExpress(v_membre NUMBER, v_isbn NUMBER, v_exemplaire NUMBER);
	FUNCTION EmpruntMoyen(v_membre IN NUMBER) RETURN NUMBER;
	FUNCTION FinValidite(v_numero IN NUMBER) RETURN DATE;
	PROCEDURE MajEtatExemplaire;
	FUNCTION MesureActivite(v_mois IN NUMBER) RETURN NUMBER;
	PROCEDURE PurgeMembres;
	PROCEDURE RetourExemplaire(v_isbn IN NUMBER, v_numero IN NUMBER);
	PROCEDURE SupprimeExemplaire(v_isbn IN NUMBER, v_numero IN NUMBER);
END Livre;
/
--ERROR at line 1:
--ORA-02091: transaction rolled back
--ORA-02291: integrity constraint (M2_BIO12.FK_EMPRUNTS_MEMBRES) violated -
--parent key not found

-- b) création du corps
CREATE OR REPLACE PACKAGE BODY Livre AS

--*****Fonction AdhesionAjour*****
FUNCTION AdhesionAjour(v_numero NUMBER) RETURN BOOLEAN AS
BEGIN 
	IF (finValidite(v_numero)>= SYSDATE())
		THEN RETURN TRUE;
	ELSE 
		RETURN FALSE;
	END IF;
END;

--*****Fonction AjouteMembre*****
FUNCTION AjouteMembre (v_nom IN CHAR, v_prenom IN CHAR, v_adresse IN CHAR, v_mobile IN CHAR, v_adhesion IN DATE, v_duree IN NUMBER) RETURN NUMBER AS v_numero Membres.numero%TYPE;
BEGIN 
	INSERT INTO Membres (numero, nom, prenom, adresse, mobile, adhesion, duree)
	VALUES (seq_membre.nextval, v_nom, v_prenom, v_adresse, v_mobile, v_adhesion, v_duree)
	RETURNING numero INTO v_numero;
	RETURN v_numero;
END;

--*****Fonction DureeMoyenne*****
FUNCTION DureeMoyenne (v_isbn IN NUMBER, v_exemplaire IN NUMBER DEFAULT NULL) RETURN NUMBER IS v_duree NUMBER;
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
	RETURN v_duree;
END;

--*****Fonction EmpruntExpress*****
PROCEDURE EmpruntExpress (v_membre NUMBER, v_isbn NUMBER, v_exemplaire NUMBER) AS v_emprunt Emprunts.numero%TYPE;
BEGIN
	INSERT INTO Emprunts (numero, membre, creele) VALUES (seq_emprunts.nextval, v_membre, SYSDATE)
	RETURNING numero INTO v_emprunt;
	INSERT INTO Details (emprunt, numero, isbn, exemplaire) VALUES (v_emprunt, 1, v_isbn, v_exemplaire);
END;

--*****Fonction EmpruntMoyen*****
FUNCTION EmpruntMoyen (v_membre IN NUMBER) RETURN NUMBER IS v_dureeMoyenne NUMBER;
BEGIN 
	SELECT TRUNC(AVG(TRUNC(rendule,'DD')-TRUNC(creele,'DD')+1), 2) INTO v_dureeMoyenne
	FROM Emprunts, Details
	WHERE Emprunts.membre=v_membre
	AND Details.emprunt=Emprunts.numero
	AND Details.rendule IS NOT NULL;
	RETURN v_dureeMoyenne;
END;

--*****Fonction FinValidite*****
FUNCTION FinValidite(v_numero IN NUMBER) RETURN DATE IS v_fin DATE;
BEGIN
	SELECT ADD_MONTHS(adhesion, duree) INTO v_fin
	FROM Membres
	WHERE numero=v_numero;
	RETURN v_fin;
END;

--*****Fonction MajEtatExemplaire*****
PROCEDURE MajEtatExemplaire IS 
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

--*****Fonction MesureActivite*****
FUNCTION MesureActivite (v_mois IN NUMBER) RETURN NUMBER IS
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

--*****Fonction PurgeMembres*****
PROCEDURE PurgeMembres AS
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

--*****Fonction RetourExemplaire*****
PROCEDURE RetourExemplaire (v_isbn IN NUMBER, v_numero IN NUMBER) AS
BEGIN
	UPDATE Details SET rendule=SYSDATE
	WHERE rendule IS NULL
	AND isbn=v_isbn AND exemplaire=v_numero;
END;

--*****Fonction SupprimeExemplaire*****
PROCEDURE SupprimeExemplaire (v_isbn IN NUMBER, v_numero IN NUMBER) AS
BEGIN
	-- On supprime l'exemplaire choisi
	DELETE FROM Exemplaires WHERE isbn=v_isbn AND numero=v_numero;
	IF (SQL%ROWCOUNT=0) THEN RAISE NO_DATA_FOUND;
	END IF;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
	RAISE_APPLICATION_ERROR(-20510,'Cet exemplaire n''existe pas ou plus dans la bibliothèque');
END;

END Livre;
/

	------------------------------------------

-- VI) Déclencheurs de bases de données

-- 1) Définition d'un déclencheur : Suppresion des informations relatives à un ouvrage lors de sa suppression
CREATE TRIGGER after_delete_Exemplaires
	AFTER DELETE ON Exemplaires
	FOR EACH ROW 
DECLARE
	v_nbre NUMBER(3);
BEGIN
	DELETE FROM Ouvrages WHERE isbn=:old.isbn;
EXCEPTION
	WHEN OTHERS THEN NULL;
END;
/

-- 2) Définition d'un déclencheur
CREATE OR REPLACE TRIGGER after_insert_Emprunts
	AFTER INSERT ON Emprunts
	FOR EACH ROW
DECLARE
	v_finValidite DATE;
BEGIN
	-- On calcule la date de fin de validité de l'adhésion d'un membre voulant emprunter un exemplaire
	-- ADD_MONTHS(i,j) permet de calculer la date de fin en rajoutant j mois à la date i
	SELECT ADD_MONTHS(adhesion, duree) INTO v_finValidite
	FROM Membres
	WHERE numero=:new.membre;
	-- On compare la date de fin de validité avec la date du jour
	IF(v_finValidite<SYSDATE) THEN
		-- On lève une exception 
		RAISE_APPLICATION_ERROR(-20602,'Le membre n''est pas à jour, il ne peut pas emprunter d''ouvrages');
	END IF;
END;
/

-- 3) Définition d'un déclencheur
CREATE OR REPLACE TRIGGER before_update_Emprunts
	BEFORE UPDATE ON Emprunts
	FOR EACH ROW
	WHEN (new.membre != old.membre)
BEGIN
	-- Exécution du déclencheur si une modification sur le membre est effectuée
	RAISE_APPLICATION_ERROR(-20603, 'Il est impossible de modifier ce membre');
END;
/

-- 4) Définition d'un déclencheur
CREATE OR REPLACE TRIGGER after_update_Details
	AFTER UPDATE ON Details
	FOR EACH ROW
	WHEN ((old.isbn != new.isbn) OR (old.exemplaire != new.exemplaire))
BEGIN
	-- On regarde si l'ancien isbn est différent du nouveau ou pas
	IF ( :old.isbn != :new.isbn) THEN
		RAISE_APPLICATION_ERROR(-20641, 'Il est impossible de changer d''ouvrage');
	ELSE
		RAISE_APPLICATION_ERROR(-20642, 'Il est impossible de changer d''exemplaire');
	END IF;
END;
/

-- 5) Définition d'un deéclencheur automatique
CREATE OR REPLACE TRIGGER bef_ins_update_Exemplaires
	BEFORE INSERT OR UPDATE OF nombreEmprunts ON Exemplaires
	FOR EACH ROW
BEGIN
	-- On regarde le nombre d'emprunts en comptant celui là
	IF (:new.nombreEmprunts<=10) THEN :new.etat :='NE';
	END IF;
	IF (:new.nombreEmprunts BETWEEN 11 AND 25) THEN :new.etat :='BO';
	END IF;
	IF (:new.nombreEmprunts BETWEEN 26 AND 40) THEN :new.etat :='MO';
	END IF;
	IF (:new.nombreEmprunts BETWEEN 41 AND 60) THEN :new.etat :='DO';
	END IF;
	IF (:new.nombreEmprunts>=61) THEN :new.etat :='MA';
	END IF;
END;
/

-- 6) Assurer la prise en compte d'un emprunt après suppression d'un détail
CREATE OR REPLACE TRIGGER after_delete_Details
	AFTER DELETE ON Details
	FOR EACH ROW
DECLARE
	-- Le pragma permet les roll back/commit si besoin.
	PRAGMA AUTONOMOUS_TRANSACTION;
	v_creele Emprunts.creele%TYPE;
	v_dateCalculEmprunts Exemplaires.dateCalculEmprunts%TYPE;
BEGIN
	-- Calcul ne concernant que les éléments les plus récents
	SELECT creele INTO v_creele FROM Emprunts WHERE numero=:old.emprunt;
	SELECT dateCalculEmprunts INTO v_dateCalculEmprunts FROM Exemplaires WHERE Exemplaires.isbn=:old.isbn AND Exemplaires.numero=:old.exemplaire;
	IF(v_dateCalculEmprunts<v_creele) THEN 
		-- la valoraisation du nombre d'emprunts est antérieure à la location
		UPDATE Exemplaires
		SET nombreEmprunts=nombreEmprunts+1
		WHERE Exemplaires.isbn=:old.isbn AND Exemplaires.numero=:old.exemplaire;
	END IF;
	COMMIT;
END;
/
-- Impossible d'effectuer une mise à jour plus complète de la valeur contenue dans la colonne NombreEmprunts 
-- car il n'est pas possible de faire une requête SELECT dans le déclencheur

-- 7) Amélioration
-- Etape 1 : Modification de la structure des tables des Emprunts et des Details en y ajoutant une colonne pour conserver le nom de l'utilisateur et une autre pour conserver la date et l'heure de l'opération
ALTER TABLE Emprunts ADD(ajoutePar VARCHAR2(80), ajouteLe DATE);
ALTER TABLE Details ADD(modifiePar VARCHAR2(80), ModifieLe DATE);
-- Etape 2a : Définition d'un déclencheur dans la table des Emprunts
CREATE OR REPLACE TRIGGER before_insert_Emprunts
	BEFORE INSERT ON Emprunts
	FOR EACH ROW
BEGIN
	-- On récupère le nom de l'utilisateur = employé
	:new.ajoutePar :=USER();
	-- On récupère la date et l'heure 
	:new.ajouteLe :=SYSDATE();
END;
/
-- Etape 2b : Définition d'un déclencheur dans la table des Details
CREATE OR REPLACE TRIGGER before_update_Details
	BEFORE UPDATE ON Details
	FOR EACH ROW
	WHEN (old.rendule IS NULL AND new.rendule IS NOT NULL)
BEGIN
	-- On récupère le nom de l'utilisateur = employé
	:new.modifiePar :=USER();
	-- On récupère la date et l'heure 
	:new.modifieLe :=SYSDATE();
END;
/

-- 8) Fonction AnalyseActivite
CREATE OR REPLACE FUNCTION AnalyseActivite(v_employe IN CHAR DEFAULT NULL, v_jour IN DATE DEFAULT NULL) 

-- La valeur de cette fonction est toujours un nombre entier
RETURN NUMBER IS
	v_resultatDeparts NUMBER(6) :=0;
	v_resultatRetours NUMBER(6) :=0;
BEGIN
	-- On traite le cas où l'analyse porte sur un utilisateur
	IF(v_employe IS NOT NULL AND v_jour IS NULL) THEN
		SELECT COUNT(*) INTO v_resultatDeparts FROM Emprunts WHERE ajoutePar=v_employe;
		SELECT COUNT(*) INTO v_resultatRetours FROM Details WHERE modifiePar=v_employe;
		-- On retourne le résultat et on quitte la fonction
		RETURN v_resultatDeparts+v_resultatRetours;
	END IF;
	-- On traite le cas où l'analyse porte sur une journée
	IF (v_employe IS NULL AND v_jour IS NOT NULL) THEN 
		SELECT COUNT(*) INTO v_resultatDeparts FROM Emprunts WHERE ajouteLe=v_jour;
		SELECT COUNT(*) INTO v_resultatRetours FROM Details WHERE modifieLe=v_jour;
		-- On retourne le résultat et on quitte la fonction
		RETURN v_resultatDeparts+v_resultatRetours;	
	END IF;
	-- On traite le cas où l'analyse porte sur un utilisateur et une journée
	IF(v_employe IS NOT NULL AND v_jour IS NOT NULL) THEN
		SELECT COUNT(*) INTO v_resultatDeparts FROM Emprunts WHERE ajoutePar=v_employe AND ajouteLe=v_jour;
		SELECT COUNT(*) INTO v_resultatRetours FROM Details WHERE modifiePar=v_employe AND modifieLe=v_jour;
		-- On retourne le résultat et on quitte la fonction
		RETURN v_resultatDeparts+v_resultatRetours;
	END IF;
	-- Pour le dernier cas restant, le retour est 0
	RETURN 0;
END;
/

-- 9) Interdiction d'un ajout de détails si tous les exemplaires référencés sur une fiche ont été rendus
CREATE OR REPLACE TRIGGER before_insert_Details
	BEFORE INSERT ON Details
	FOR EACH ROW
DECLARE 
	v_etat Emprunts.etat%TYPE;
BEGIN
	SELECT etat INTO v_etat FROM Emprunts WHERE numero=:new.emprunt;
	IF (v_etat !='EC') THEN RAISE_APPLICATION_ERROR (-20610, 'Il est interdit d''ajouter des détails pour cet exemplaire');
	END IF;
END;
/
