
-- ÉCRIRE DES FONCTIONS SQL ET PL/SQL

-- EXO1: Retourne le nombre de livres associés à une oeuvre
CREATE OR REPLACE FUNCTION nbre_exemplaires(id_oeuvre INTEGER) RETURNS INTEGER AS $$
    SELECT  COUNT(l.id_livre)
    FROM livre l
    WHERE l.id_oeuvre = nbre_exemplaires.id_oeuvre; 
$$ LANGUAGE SQL;

-- test
CREATE OR REPLACE FUNCTION test_nbre_exemplaires_exo1() RETURNS INTEGER AS $$
    SELECT nbre_exemplaires(1);
$$ LANGUAGE SQL;

SELECT test_nbre_exemplaires_exo1();


-- EXO2: Retourne un booléen suivant qu'un livre est actuellement emprunté ou non
CREATE OR REPLACE FUNCTION est_emprunte(id_livre INTEGER) RETURNS boolean AS $$ 
    BEGIN 
        PERFORM *
        FROM emprunt e
        WHERE e.id_livre = est_emprunte.id_livre; 

        IF FOUND THEN
            RAISE NOTICE 'Le livre ayant pour id % est actuellement emprunté !', est_emprunte.id_livre;
        ELSE
            RAISE NOTICE 'Le livre ayant pour id % n''est pas actuellement emprunté !', est_emprunte.id_livre;
        END IF;
        
        RETURN FOUND; 
    END; 
$$ LANGUAGE PLPGSQL;

-- test 
CREATE OR REPLACE FUNCTION test_est_emprunte_exo2() RETURNS boolean AS $$
    SELECT est_emprunte(1);
$$ LANGUAGE SQL;

SELECT test_est_emprunte_exo2(); 


-- EXO3: Retourne les livres actuellement présents sur les rayons de la bibliothèque
CREATE OR REPLACE FUNCTION les_livres_presents() RETURNS SETOF livre AS $$ 
    SELECT  l.id_livre, l.id_oeuvre, l.date_acquisition, l.prix 
    FROM livre l
    LEFT JOIN emprunt e
    ON l.id_livre = e.id_livre
    WHERE e.date_emprunt IS NULL;  
$$ LANGUAGE SQL;

-- test 
CREATE OR REPLACE FUNCTION test_les_livres_presents_exo3() RETURNS SETOF livre AS $$
    SELECT les_livres_presents(); 
$$ LANGUAGE SQL;

SELECT * FROM test_les_livres_presents_exo3();


-- EXO4
-- Retourne le nombre de livres empruntés
-- (depuis l'ouverture de la bibliothèque) associés à une même oeuvre.
CREATE OR REPLACE FUNCTION nbre_emprunts(id_oeuvre INTEGER) RETURNS INTEGER AS $$
    SELECT  COUNT(DISTINCT l.id_livre)
    FROM
    (histoemprunt NATURAL
        JOIN livre l
    )
    LEFT JOIN emprunt e
    ON l.id_livre = e.id_livre
    WHERE l.id_oeuvre = nbre_emprunts.id_oeuvre; 
$$ LANGUAGE SQL;

-- test 
CREATE OR REPLACE FUNCTION test_nbre_emprunts_exo4() RETURNS INTEGER AS $$
    SELECT nbre_emprunts(1);
$$ LANGUAGE SQL;

SELECT * FROM test_nbre_emprunts_exo4();

-- EXO5
-- Retourne les n oeuvres les plus
-- empruntées depuis l'ouverture de la bibliothèque. En cas d'égalité, on rangera les
-- oeuvres par ordre alphabétique sur leur titre.
CREATE OR REPLACE FUNCTION les_plus_empruntes() RETURNS TABLE ( titre_oeuvre TEXT, emprunts INT ) AS $$
    SELECT  o.titre AS titre_oeuvre
        ,COUNT(o.id_oeuvre) AS emprunts
    FROM livre l
    INNER JOIN histoemprunt he
    ON l.id_livre = he.id_livre
    INNER JOIN oeuvre o
    ON l.id_oeuvre = o.id_oeuvre
    GROUP BY  o.titre
    ORDER BY emprunts DESC
            ,titre_oeuvre
    LIMIT 10; 
$$ LANGUAGE SQL;

-- test 
CREATE OR REPLACE FUNCTION test_les_plus_empruntes_exo5() RETURNS TABLE ( titre_oeuvre TEXT, emprunts INT ) AS $$
    SELECT les_plus_empruntes();
$$ LANGUAGE SQL;

SELECT 'EXO5' AS INFO;
SELECT * FROM test_les_plus_empruntes_exo5(); 


-- EXO6
-- Retourne (pour une oeuvre donnée) une chaîne de caractères qui contient des informations sur cette oeuvre. 
-- Si l'oeuvre est écrite par une seule personne, alors la chaîne retournée devra être Titre : Le titre de
-- l'oeuvre - Auteur : Le nom de l'auteur; si l'oeuvre a été écrite par plusieurs
-- personnes, alors la chaîne retournée sera Titre : Le titre de l'oeuvre - Auteurs : Le
-- nom du premier auteur et al..;
-- ET Appele cette fonction sur toutes les oeuvres de la base.
CREATE OR REPLACE FUNCTION infos_oeuvres(titre_recherche TEXT) RETURNS TEXT AS $$
    DECLARE
        cnt_auteurs INT;
        nom_du_premier_auteur TEXT;
        message TEXT;
    BEGIN
        -- Compte le nbr d'auteurs de l'oeuvre concernée.
        SELECT COUNT(o.id_oeuvre)
        INTO cnt_auteurs
        FROM oeuvre o 
        NATURAL JOIN oeuvreauteur oa 
        WHERE o.titre = titre_recherche;
        
        -- Compte le nbr d'auteurs de l'oeuvre concernée 
        -- (sachant que aucune oeuvre n'est sensée être sans auteur).
        SELECT a.nom_auteur
        INTO nom_du_premier_auteur
        FROM oeuvre o 
        NATURAL JOIN oeuvreauteur oa 
        NATURAL JOIN auteur a 
        WHERE o.titre = titre_recherche;

        IF cnt_auteurs > 1 THEN
            message := 'Titre : ' || titre_recherche || ' - Auteurs : ' || nom_du_premier_auteur || E' et al.. \n';
        ELSE
            message := 'Titre : ' || titre_recherche || ' - Auteur : ' || nom_du_premier_auteur || E'\n';
        END IF;
        
        RETURN message;
    END;
$$ LANGUAGE PLPGSQL;

-- test: teste infos oeuvres sur toutes les oeuvres de la base
CREATE OR REPLACE FUNCTION test_infos_oeuvres() RETURNS VOID AS $$
    DECLARE
        titre_courant TEXT;
    BEGIN
        FOR titre_courant IN (SELECT titre FROM oeuvre)
        LOOP
            RAISE NOTICE 'Pour le titre : %', titre_courant;
            RAISE NOTICE '%', infos_oeuvres(titre_courant);
        END LOOP;
    END;
$$ LANGUAGE PLPGSQL;

SELECT 'EXO6' AS INFO;
-- Execute test function
SELECT * FROM test_infos_oeuvres();

-- REACHED -- REACHED -- REACHED -- REACHED -- REACHED -- REACHED -- REACHED -- REACHED 


-- LES DÉCLENCHEURS 
-- EXO1
-- Un adhérent ne peut pas emprunter plus de trois livres.

-- Fonction associée au Trigger nbre_livres_empruntes
CREATE OR REPLACE FUNCTION check_livres_empruntes() RETURNS TRIGGER AS $$
    DECLARE 
        nbre_emprunts INT;
    BEGIN
        SELECT COUNT(*)
        INTO nbre_emprunts
        FROM emprunt e
        WHERE e.id_adherent = NEW.id_adherent;

        IF nbre_emprunts < 3 THEN
            RETURN NEW;
        ELSE
            RAISE EXCEPTION 'L''Adhérent a atteint le maximum d''emprunts !';
        END IF;
    END;
$$ LANGUAGE PLPGSQL;

-- Trigger de check_livres_empruntes
CREATE OR REPLACE TRIGGER trigger_check_livres_empruntes BEFORE INSERT
ON emprunt FOR EACH ROW EXECUTE FUNCTION check_livres_empruntes();

-- test
CREATE OR REPLACE FUNCTION test_trigger_check_livres_empruntes_exo1() RETURNS VOID AS $$
    BEGIN
        INSERT INTO emprunt(id_adherent, id_livre, date_emprunt) VALUES (1, 1, NOW());
        INSERT INTO emprunt(id_adherent, id_livre, date_emprunt) VALUES (1, 2, NOW());
        INSERT INTO emprunt(id_adherent, id_livre, date_emprunt) VALUES (1, 3, NOW());
        INSERT INTO emprunt(id_adherent, id_livre, date_emprunt) VALUES (1, 4, NOW());
    END;
$$ LANGUAGE PLPGSQL;

SELECT 'EXO1_DECLENCHEURS' AS INFO;
SELECT test_trigger_check_livres_empruntes_exo1();


-- EXO2
-- On ne peut pas emprunter un livre qui est déjà emprunté.

-- Vérifie si un livre est déja emprunté
CREATE OR REPLACE FUNCTION check_deja_emprunte() RETURNS TRIGGER AS $$
    BEGIN
        IF (est_emprunte(NEW.id_livre)) THEN
            RAISE EXCEPTION 'Ce livre et déjà emprunté !';
        ELSE 
            RETURN NEW;
        END IF;
    END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER trigger_check_deja_emprunte BEFORE INSERT
ON emprunt FOR EACH ROW EXECUTE FUNCTION check_deja_emprunte();

-- test
-- L'adhérent ayant pour identifiant 2 (id_adherent = 2) essaie d'emprunter un livre (id_livre = 1) déja emprunté.
CREATE OR REPLACE FUNCTION test_trigger_check_deja_emprunte_exo2() RETURNS VOID AS $$
    BEGIN
        INSERT INTO emprunt(id_adherent, id_livre, date_emprunt) VALUES (1, 1, NOW());
        INSERT INTO emprunt(id_adherent, id_livre, date_emprunt) VALUES (2, 1, NOW());
    END;
$$ LANGUAGE PLPGSQL;

SELECT 'EXO2_DECLENCHEURS' AS INFO;
SELECT test_trigger_check_deja_emprunte_exo2();


-- EXO3 
-- Lorsqu'un livre est rendu au retour d'un prêt, alors l'emprunt qui vient
-- de se terminer doit être enregistré dans histoemprunt. La seule exception est le cas
-- où la date d'emprunt est également la date du retour.

-- Vérifie si un un emprunt est terminé, et lorsque c'est le cas le supprime de la table emprunt et l'ajoute dans histoemprunt
CREATE OR REPLACE FUNCTION est_termine_emprunt() RETURNS TRIGGER AS $$
    BEGIN 
        IF NEW.date_emprunt >= NEW.date_retour THEN 
            RAISE EXCEPTION 'La date d''emprunt ne doit être égale ou supérieure à la date de retour !';
        ELSE
            DELETE FROM emprunt e WHERE e.id_livre = NEW.id_livre AND e.date_emprunt = NEW.date_emprunt;

            IF FOUND THEN
                RAISE NOTICE 'L''emprunt ayant pour id_livre % et pour date_emprunt % a été supprimé de la table 
                emprunt et est en cours d''insertion dans histoemprunt !', NEW.id_livre, NEW.date_emprunt;
                RETURN NEW;
            ELSE
                RAISE NOTICE 'Aucun emprunt pour le livre ayant pour id %, et pour date d''entrée % !', NEW.id_livre, NEW.date_emprunt;
                RETURN NULL;
            END IF;
        END IF;
    END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER trigger_est_termine_emprunt BEFORE
INSERT ON histoemprunt FOR EACH ROW EXECUTE FUNCTION est_termine_emprunt();

-- test 
CREATE OR REPLACE FUNCTION test_trigger_est_termine_emprunt_exo3() RETURNS SETOF histoemprunt AS $$
    BEGIN
        INSERT INTO histoemprunt(id_adherent, id_livre, date_emprunt, date_retour) VALUES (1, 1, '2011-09-18', '2012-09-18');
        INSERT INTO histoemprunt(id_adherent, id_livre, date_emprunt, date_retour) VALUES (8, 9, '2011-09-03', '2012-09-03');
        INSERT INTO histoemprunt(id_adherent, id_livre, date_emprunt, date_retour) VALUES (2, 12, '2011-09-19', '2023-09-19');

        RETURN QUERY SELECT * FROM histoemprunt;
    END;
$$ LANGUAGE PLPGSQL;

SELECT 'EXO3_DECLENCHEURS' AS INFO;
SELECT * FROM test_trigger_est_termine_emprunt_exo3();


-- EXO4 
-- Un adhérent ne peut pas emprunter s'il a une dette, ou s'il a un livre en
-- retard (la durée du prêt est de trois semaines).

-- Retourne la dernière date d'emprunt de l'adhérent dont l'id est spécifié
CREATE OR REPLACE FUNCTION obtenir_derniere_date_emprunt(param_id_adherent INTEGER) RETURNS DATE AS $$
    SELECT e.date_emprunt
    FROM emprunt e 
    WHERE e.id_adherent = param_id_adherent
    ORDER BY e.date_emprunt DESC
    LIMIT 1;
$$ LANGUAGE SQL;

-- Retourne TRUE si l'adhérent est en retard pour le dernier prêt, sinon FALSE
CREATE OR REPLACE FUNCTION est_retard_adherent(param_id_adherent INTEGER) RETURNS BOOLEAN AS $$
    DECLARE
        date_emprunt DATE;
        duree_pret_en_jours INTEGER; 
        fin_pret DATE;
    BEGIN
        SELECT obtenir_derniere_date_emprunt(param_id_adherent) INTO date_emprunt;

        IF date_emprunt IS NULL THEN
            -- L'adhérent n'a pas de prêts en cours
            RETURN FALSE;
        END IF;

        duree_pret_en_jours := 21;
        fin_pret := date_emprunt + duree_pret_en_jours;

        IF fin_pret < NOW() THEN
            RETURN TRUE; 
        ELSE
            RETURN FALSE;
        END IF;
    END;
$$ LANGUAGE PLPGSQL;

-- Retourne l'amende associée à l'adherent dont l'id est spécifié
CREATE OR REPLACE FUNCTION obtenir_amende_adherent(param_id_adherent INTEGER) RETURNS INTEGER AS $$
    SELECT amende_adherent
    FROM adherent a
    WHERE a.id_adherent = param_id_adherent;
$$ LANGUAGE SQL;

-- Vérifie si l'adhérent qui veut emprunter a une dette ou un livre en retard
CREATE OR REPLACE FUNCTION peut_emprunter() RETURNS TRIGGER AS $$
    DECLARE
        amende_adherent INTEGER;
    BEGIN
        SELECT obtenir_amende_adherent(NEW.id_adherent) INTO amende_adherent;

        -- Cet adherent a t-il une amende? 
        IF amende_adherent > 0  THEN 
            RAISE EXCEPTION 'Un adhérent ne peut emprunter avant de régler sa dette !';
        END IF;

        -- Cet adherent est-il en retard?        
        IF est_retard_adherent(NEW.id_adherent)  THEN 
            RAISE EXCEPTION 'Un adhérent ne peut emprunter s''il a un livre en retard (la durée du prêt est de trois semaines) !';
        ELSE
            RETURN NEW;
        END IF;
    END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER trigger_peut_emprunter BEFORE INSERT
ON emprunt FOR EACH ROW EXECUTE FUNCTION peut_emprunter();

-- test
CREATE OR REPLACE FUNCTION test_peut_emprunter_exo4() RETURNS VOID AS $$
    INSERT INTO emprunt(id_adherent, id_livre, date_emprunt) VALUES (1, 2, '2011-09-03');
    INSERT INTO emprunt(id_adherent, id_livre, date_emprunt) VALUES (1, 1, NOW());
$$ LANGUAGE SQL;

SELECT 'EXO4_DECLENCHEURS' AS INFO;
-- Execute test function
SELECT test_peut_emprunter_exo4();


-- EXO5 
-- Lorsqu'un adhérent rend un livre, il aura une amende de deux euros
-- par semaine de retard (le cas échéant).

-- Pour le test
ALTER TABLE histoemprunt DISABLE TRIGGER ALL;

-- Retourne la date d'emprunt correspondante à l'id d'un adhérent et l'id d'un livre passés en paramètres
CREATE OR REPLACE FUNCTION obtenir_date_emprunt(param_id_adherent INTEGER, param_id_livre INTEGER) RETURNS DATE AS $$
    SELECT  e.date_emprunt
    FROM emprunt e
    WHERE e.id_adherent = param_id_adherent
    AND e.id_livre = param_id_livre 
$$ LANGUAGE SQL;

-- Met à jour l'amende qu'un adhérent doit régler.
CREATE OR REPLACE FUNCTION retourne_livre() RETURNS TRIGGER AS $$
    DECLARE
        duree_pret_en_jours INTEGER := 21;
        amende INTEGER;
        date_debut_emprunt DATE;
        date_fin_emprunt DATE;
        nbr_jours_retard INTEGER := 0;
        nbr_semaines_retard INTEGER := 0;
        amende_supplementaire INTEGER;
        increment_amende_jours INTEGER := 7;
    BEGIN
        SELECT obtenir_date_emprunt(NEW.id_adherent, NEW.id_livre) INTO date_debut_emprunt;

        IF date_debut_emprunt IS NULL THEN
            RAISE EXCEPTION 'L''adherent ayant id_adherent = % n''a aucun emprunt dont id_livre = %', NEW.id_adherent, NEW.id_livre;
        END IF;

        SELECT obtenir_amende_adherent(NEW.id_adherent) INTO amende;

        date_fin_emprunt := date_debut_emprunt + duree_pret_en_jours;
        nbr_jours_retard := (NEW.date_retour - date_fin_emprunt)::INTEGER;
        nbr_semaines_retard := CEIL(nbr_jours_retard / increment_amende_jours)::INTEGER;

        IF nbr_semaines_retard > 0 THEN
            amende_supplementaire := nbr_semaines_retard * 2;
            amende := amende + amende_supplementaire;

            RAISE NOTICE 'Vous avez une amende de % € à régler !', amende;
        ELSE
            RAISE NOTICE 'Vous avez 0 semaine de retard !';
        END IF;

        RETURN NEW;
    END;
$$ LANGUAGE PLPGSQL;


-- SELECT tgname, tgtype, tgenabled, tgfoid, tgrelid, tgqual FROM pg_trigger WHERE tgrelid = 'histoemprunt'::regclass;

CREATE OR REPLACE TRIGGER trigger_retourne_livre AFTER INSERT
ON histoemprunt FOR EACH ROW EXECUTE FUNCTION retourne_livre();

-- test
CREATE OR REPLACE FUNCTION test_retourne_livre_exo5() RETURNS VOID AS $$
    DECLARE
        param_id_adherent INTEGER := 2;
        param_id_livre INTEGER := 3;
        param_date_emprunt DATE := '2011-09-03';
        param_date_retour DATE := '2023-09-18';
    BEGIN
        INSERT INTO emprunt(id_adherent, id_livre, date_emprunt) VALUES (param_id_adherent, param_id_livre, param_date_emprunt);
        INSERT INTO histoemprunt(id_adherent, id_livre, date_emprunt, date_retour) VALUES (param_id_adherent, param_id_livre, param_date_emprunt, param_date_retour);

        DELETE FROM emprunt e WHERE e.id_livre = param_id_livre AND e.date_emprunt = param_date_emprunt;
    END;
$$ LANGUAGE PLPGSQL;

SELECT 'EXO5_DECLENCHEURS' AS INFO;
SELECT test_retourne_livre_exo5();

ALTER TABLE histoemprunt ENABLE TRIGGER ALL;


-- EXO6 
-- Lorsqu'un livre est supprimé de la base (et des rayons), dans
-- l'historique des emprunts (histoemprunt), on remplace sa référence par null.

-- Remplace la référence d'un livre supprimé par null
CREATE OR REPLACE FUNCTION remplace_livre_supprime_par_null() RETURNS TRIGGER AS $$
    BEGIN
        UPDATE histoemprunt
        SET id_livre = NULL
        WHERE id_livre = OLD.id_livre;
        RETURN OLD;
    END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER trigger_remplace_livre_supprime_par_null BEFORE DELETE
ON livre FOR EACH ROW EXECUTE FUNCTION remplace_livre_supprime_par_null();

-- test
CREATE OR REPLACE FUNCTION test_remplace_livre_supprime_par_null_exo6() RETURNS SETOF histoemprunt AS $$
    DECLARE
        check_if_exist boolean;
        param_id_livre INTEGER := 1;
    BEGIN
        SELECT 1 FROM livre WHERE id_livre = param_id_livre INTO check_if_exist;

        IF check_if_exist IS NULL THEN
            RAISE NOTICE 'Le livre ayant pour id % n''existe pas !', param_id_livre;
        ELSE
            DELETE FROM livre WHERE id_livre = param_id_livre;
            RAISE NOTICE 'Le livre ayant pour id % a été supprimé !', param_id_livre;
        END IF;

        RETURN QUERY SELECT * FROM histoemprunt;
    END;
$$ LANGUAGE PLPGSQL;

SELECT 'EXO6_DECLENCHEURS' AS INFO;
SELECT * FROM test_remplace_livre_supprime_par_null_exo6();


-- EXO7 
-- On ne peut rien supprimer dans histoemprunt, sauf les enregistrements
-- dont date la date d'emprunt est la même que la date du retour ou bien les
-- enregistrements dont la référence du livre est null.

-- Pour le test
ALTER TABLE histoemprunt DISABLE TRIGGER ALL;

-- Supprime les livres ayant une ref nulle ou une date d'emprunt égale à celle de retour
CREATE OR REPLACE FUNCTION supprime_reference_nulle() RETURNS TRIGGER AS $$
BEGIN
    IF OLD.date_emprunt = OLD.date_retour OR OLD.id_livre IS NULL THEN 
        RETURN OLD;
    ELSE
        RAISE EXCEPTION 'Seuls les livres ayant une référence nulle ou une date d''emprunt égale à celle de retour sont supprimables !';
    END IF;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER trigger_supprime_reference_nulle BEFORE DELETE
ON histoemprunt FOR EACH ROW EXECUTE FUNCTION supprime_reference_nulle();

-- test
CREATE OR REPLACE FUNCTION test_supprime_reference_nulle_exo7() RETURNS VOID AS $$
    DECLARE
        test_entry histoemprunt;
    BEGIN
        INSERT INTO histoemprunt(id_livre, date_emprunt, date_retour) VALUES (NULL, '2023-01-01', '2023-01-01');
        DELETE FROM histoemprunt WHERE date_emprunt = '2023-01-01' AND date_retour = '2023-01-01';

        IF FOUND THEN
            RAISE NOTICE 'Suppression réussie.';
        ELSE
            RAISE EXCEPTION 'Anomalie !.';
        END IF;
    END;
$$ LANGUAGE PLPGSQL;

SELECT 'EXO7_DECLENCHEURS' AS INFO;
SELECT test_supprime_reference_nulle_exo7();

ALTER TABLE histoemprunt ENABLE TRIGGER ALL;



-- EXO8
-- Pour savoir plus rapidement si un livre est emprunté, on décide
-- d'ajouter un champ booléen sorti dans la table livre. Ajoutez ce champ, avec
-- comme valeur par défaut false.

-- Ajoute un champ booléen "sorti" avec la valeur par défaut "false" à la table "livre"
CREATE OR REPLACE FUNCTION ajouter_champ_sorti() RETURNS VOID AS $$
    ALTER TABLE livre
    ADD sorti boolean DEFAULT FALSE;
$$ LANGUAGE SQL;

-- Ajoute le champ sorti
SELECT ajouter_champ_sorti();

-- test
SELECT 'EXO8_DECLENCHEURS' AS INFO;
SELECT * FROM livre;


-- EXO9
-- Proposer des solutions pour que le champ sorti soit toujours à jour.

ALTER TABLE histoemprunt DISABLE TRIGGER ALL; 

-- Met à jour le booléen sorti de la table livre suite à l'emprunt d'un livre
CREATE OR REPLACE FUNCTION maj_sorti_emprunt() RETURNS TRIGGER AS $$
    BEGIN
        UPDATE livre
        SET sorti = TRUE 
        WHERE id_livre = NEW.id_livre;

        RETURN NEW; 
    END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER trigger_maj_sorti_emprunt AFTER INSERT
ON emprunt FOR EACH ROW EXECUTE FUNCTION maj_sorti_emprunt();

-- Met à jour le booléen sorti de la table livre suite au retour d'un livre
CREATE OR REPLACE FUNCTION maj_sorti_retour() RETURNS TRIGGER AS $$
    BEGIN
        UPDATE livre
        SET sorti = FALSE
        WHERE id_livre = NEW.id_livre;

        RETURN NEW;
    END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER trigger_maj_sorti_retour AFTER INSERT
ON histoemprunt FOR EACH ROW EXECUTE FUNCTION maj_sorti_retour();

-- test
CREATE OR REPLACE FUNCTION test_maj_sorti_exo9() RETURNS VOID AS $$
DECLARE
    param_date_emprunt DATE := NOW();
    param_id_adherent INTEGER := 1;
    param_id_livre INTEGER := 8;
BEGIN
    -- Ajout d'un emprunt
    INSERT INTO emprunt(id_adherent, id_livre, date_emprunt) VALUES (param_id_adherent, param_id_livre, param_date_emprunt);

    -- Vérification
    IF NOT EXISTS (SELECT 1 FROM livre WHERE id_livre = param_id_livre AND sorti = TRUE) THEN
        RAISE EXCEPTION 'Le champ sorti n''a pas été mis à jour après l''emprunt.';
    END IF;

    -- Ajout d'un retour
    INSERT INTO histoemprunt(id_adherent, id_livre, date_emprunt, date_retour) 
    VALUES (param_id_adherent, param_id_livre, param_date_emprunt, '2024-01-01');

    -- Pour ne pas salir la table
    DELETE FROM emprunt WHERE id_livre = param_id_livre AND date_emprunt = param_date_emprunt;

    -- Vérification
    IF NOT EXISTS (SELECT 1 FROM livre WHERE id_livre = param_id_livre AND sorti = FALSE) THEN
        RAISE EXCEPTION 'Le champ sorti n''a pas été mis à jour après le retour.';
    END IF;

    RAISE NOTICE 'Le champ sorti a été mis à jour après l''emprunt et le retour !';
END;
$$ LANGUAGE PLPGSQL;

-- Exécute la fonction de test
SELECT 'EXO9_DECLENCHEURS' AS INFO;
SELECT test_maj_sorti_exo9();

ALTER TABLE histoemprunt ENABLE TRIGGER ALL; 


-- EXO10 
-- On décide maintenant d'ajouter un champ reserve_adh (qui est une
-- clé étrangère pour adherent) dans la table livre. Ajoutez ce champ. Il permettra
-- d'indiquer si un livre est réservé par un adhérent.

CREATE OR REPLACE FUNCTION ajouter_champ_reserve_adh() RETURNS VOID AS $$
    ALTER TABLE livre
    ADD reserve_adh INTEGER REFERENCES adherent(id_adherent);
$$ LANGUAGE SQL;

-- Ajoute le champ sorti
SELECT ajouter_champ_reserve_adh();

-- test
SELECT 'EXO10_DECLENCHEURS' AS INFO;
SELECT * FROM livre;


-- EXO11
-- Maintenant on ne peut pas emprunter un livre s'il est déjà réservé, à
-- moins que l'emprunteur ne soit celui qui a fait la réservation. Dans ce cas, le champ
-- reserve_adh doit être remis à null lors de l'emprunt.

ALTER TABLE histoemprunt DISABLE TRIGGER ALL;

-- Vérifie si un livre peut être emprunté
CREATE OR REPLACE FUNCTION verifie_emprunt() RETURNS TRIGGER AS $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM livre l
            WHERE l.id_livre = NEW.id_livre
            AND (l.sorti = FALSE
            OR 
                l.reserve_adh IS NULL AND l.reserve_adh = NEW.id_adherent
            )
        ) THEN
            UPDATE livre
            SET reserve_adh = NEW.id_adherent
            WHERE id_livre = NEW.id_livre;

            RETURN NEW;
        ELSE
            RAISE EXCEPTION 'Impossible d''emprunter ce livre.';
            
            RETURN NULL;
        END IF;
    END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER trigger_verifie_emprunt BEFORE INSERT
ON histoemprunt FOR EACH ROW EXECUTE FUNCTION verifie_emprunt();

-- AFTER DELETE
CREATE OR REPLACE FUNCTION maj_reserve_adh_apres_retour() RETURNS TRIGGER AS $$
    BEGIN
        -- Màj de reserve_adh
        UPDATE livre
        SET reserve_adh = NULL
        WHERE id_livre = OLD.id_livre;

        RETURN OLD;
    END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER trigger_maj_reserve_adh_apres_retour AFTER DELETE
ON histoemprunt FOR EACH ROW EXECUTE FUNCTION maj_reserve_adh_apres_retour();

-- Contrainte de clé étrangère
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE table_name = 'livre'
          AND constraint_name = 'fk_reserve_adh_adherent'
    ) THEN
        ALTER TABLE livre
        ADD CONSTRAINT fk_reserve_adh_adherent
        FOREIGN KEY (reserve_adh)
        REFERENCES adherent (id_adherent);
    END IF;
END $$;

-- test
CREATE OR REPLACE FUNCTION test_exo11() RETURNS VOID AS $$
BEGIN

    UPDATE livre SET reserve_adh = 1 WHERE id_livre = 4;

    INSERT INTO histoemprunt(id_adherent, id_livre, date_emprunt, date_retour) 
    VALUES (1, 4, NOW(), '2024-01-01');

    IF NOT EXISTS (
        SELECT 1 FROM livre WHERE id_livre = 4 AND reserve_adh IS NULL
    ) THEN
        RAISE EXCEPTION 'Le champ reserve_adh n''a pas été correctement mis à jour après l''emprunt par le même adhérent.';
    END IF;
END;
$$ LANGUAGE PLPGSQL;

-- Exécution du test
SELECT 'EXO11_DECLENCHEURS' AS INFO;
SELECT test_exo11();

ALTER TABLE histoemprunt ENABLE TRIGGER ALL;