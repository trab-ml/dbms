-- ÉCRIRE DES FONCTIONS SQL ET PL/SQL
-- EXO1: Retourne le nombre de livres associés à une oeuvre
CREATE OR REPLACE FUNCTION nbre_exemplaires(id_oeuvre INTEGER) RETURNS INTEGER AS $$
    SELECT  COUNT(l.id_livre)
    FROM livre l
    WHERE l.id_oeuvre = nbre_exemplaires.id_oeuvre; 
$$ LANGUAGE SQL;

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

-- EXO3: Retourne les livres actuellement présents sur les rayons de la bibliothèque

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'les_livres_presents_type') THEN
        CREATE TYPE les_livres_presents_type AS (
            id_livre INTEGER,
            id_oeuvre INTEGER,
            date_acquisition DATE,
            prix real
        );
    END IF;
END $$;

CREATE OR REPLACE FUNCTION les_livres_presents() RETURNS SETOF les_livres_presents_type AS $$ 
    SELECT  l.id_livre, l.id_oeuvre, l.date_acquisition, l.prix 
    FROM livre l
    LEFT JOIN emprunt e
    ON l.id_livre = e.id_livre
    WHERE e.date_emprunt IS NULL;  
$$ LANGUAGE SQL;

-- EXO4: Retourne le nombre de livres empruntés (depuis l'ouverture de la bibliothèque) 
-- associés à une même oeuvre.
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

-- EXO5: Retourne les n oeuvres les plus
-- empruntées depuis l'ouverture de la bibliothèque (en cas d'égalité,
-- ranger par ordre alphabétique sur leur titre).
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

-- EXO6: Retourne (pour une oeuvre donnée) une chaîne de caractères qui contient des informations sur cette oeuvre. 
-- Si l'oeuvre est écrite par une seule personne, alors la chaîne retournée devra être Titre : Le titre de
-- l'oeuvre - Auteur : Le nom de l'auteur; si l'oeuvre a été écrite par plusieurs
-- personnes, alors la chaîne retournée sera Titre : Le titre de l'oeuvre - Auteurs : Le
-- nom du premier auteur et al..;
-- ET Appelle cette fonction sur toutes les oeuvres de la base.
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

CREATE OR REPLACE FUNCTION all_infos_oeuvres() RETURNS VOID AS $$
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

-- LES DÉCLENCHEURS 
-- EXO1: Un adhérent ne peut pas emprunter plus de trois livres.

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

-- EXO2: On ne peut pas emprunter un livre qui est déjà emprunté.

-- Vérifie si un livre est déja emprunté
CREATE OR REPLACE FUNCTION check_deja_emprunte() RETURNS TRIGGER AS $$
    BEGIN
        IF (est_emprunte(NEW.id_livre)) THEN
            RAISE EXCEPTION 'Ce livre est déjà emprunté !';
        ELSE 
            RETURN NEW;
        END IF;
    END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER trigger_check_deja_emprunte BEFORE INSERT
ON emprunt FOR EACH ROW EXECUTE FUNCTION check_deja_emprunte();

-- EXO3: Un emprunt qui vient de se terminer doit être enregistré dans histoemprunt 
-- (sauf si la date d'emprunt est également la date du retour).

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
                RAISE EXCEPTION 'Aucun emprunt pour le livre ayant pour id %, et pour date d''entrée % !', NEW.id_livre, NEW.date_emprunt;
            END IF;
        END IF;
    END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER trigger_est_termine_emprunt BEFORE
INSERT ON histoemprunt FOR EACH ROW EXECUTE FUNCTION est_termine_emprunt();

-- EXO4: Un adhérent ne peut pas emprunter s'il a une dette,
-- ou s'il a un livre en retard (la durée du prêt est de trois semaines).

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

-- EXO5: Lorsqu'un adhérent rend un livre, il aura une amende de deux euros
-- par semaine de retard.

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

CREATE OR REPLACE TRIGGER trigger_retourne_livre AFTER INSERT
ON histoemprunt FOR EACH ROW EXECUTE FUNCTION retourne_livre();

-- EXO6: Lorsqu'un livre est supprimé de la base (et des rayons), dans
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

-- EXO7: On ne peut rien supprimer dans histoemprunt (sauf les enregistrements
-- dont date la date d'emprunt est la même que la date du retour ou bien les
-- enregistrements dont la référence du livre est null).

-- Pour le test
-- ALTER TABLE histoemprunt DISABLE TRIGGER ALL;

-- Supprime les livres ayant une ref nulle ou une date d'emprunt égale à celle de retour
CREATE OR REPLACE FUNCTION supprime_reference_nulle() RETURNS TRIGGER AS $$
BEGIN
    IF OLD.date_emprunt = OLD.date_retour OR OLD.id_livre IS NULL THEN 
        RETURN OLD;
    ELSE
        RAISE NOTICE 'Seuls les livres ayant une référence nulle ou une date d''emprunt égale à celle de retour sont supprimables !';
    END IF;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER trigger_supprime_reference_nulle BEFORE DELETE
ON histoemprunt FOR EACH ROW EXECUTE FUNCTION supprime_reference_nulle();

-- EXO8: Ajouter un champ booléen sorti dans la table livre. 
-- (Pour savoir plus rapidement si un livre est emprunté)

-- Ajoute un champ booléen "sorti" avec la valeur par défaut "false" à la table "livre"
CREATE OR REPLACE FUNCTION ajouter_champ_sorti() RETURNS VOID AS $$
    BEGIN
        PERFORM 'sorti' FROM information_schema.columns
        WHERE table_name = 'livre' AND column_name = 'sorti';

        IF NOT FOUND THEN 
            ALTER TABLE livre
            ADD sorti boolean DEFAULT FALSE;
        END IF;
    END;
$$ LANGUAGE PLPGSQL;

-- Ajoute le champ sorti
SELECT ajouter_champ_sorti();

-- EXO9: Maintenir le champ sorti toujours à jour.

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

-- EXO10: Ajouter un champ reserve_adh (qui est une
-- clé étrangère pour adherent) dans la table livre.

CREATE OR REPLACE FUNCTION ajouter_champ_reserve_adh() RETURNS VOID AS $$
    BEGIN
        PERFORM 'reserve_adh' FROM information_schema.columns
        WHERE table_name = 'livre' AND column_name = 'reserve_adh';

        IF NOT FOUND THEN 
            ALTER TABLE livre
            ADD reserve_adh INTEGER REFERENCES adherent(id_adherent);
        END IF;
    END;
$$ LANGUAGE PLPGSQL;

-- Ajoute le champ reserve_adh
SELECT ajouter_champ_reserve_adh();

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

-- EXO11: On ne peut emprunter un livre s'il est déjà réservé, 
-- à moins que l'emprunteur ne soit celui qui a fait la réservation (au quel cas 
-- reserve_adh doit être remis à null).

-- Autorise qu'un livre soit emprunté
CREATE OR REPLACE FUNCTION autorise_emprunt() RETURNS TRIGGER AS $$
DECLARE
    param_sorti BOOLEAN;
    param_reserve_adh INTEGER;
BEGIN
    SELECT sorti, reserve_adh INTO param_sorti, param_reserve_adh 
    FROM livre l 
    WHERE l.id_livre = NEW.id_livre;

    IF param_sorti = FALSE THEN
        IF param_reserve_adh IS NULL THEN
            UPDATE livre
            SET reserve_adh = NULL, sorti = TRUE
            WHERE id_livre = NEW.id_livre;
            RETURN NEW;
        ELSE
            RAISE EXCEPTION 'Un livre doit être réservé avant son emprunt.';
        END IF;
    ELSE
        RAISE EXCEPTION 'Ce livre est déjà sorti, essayez un livre qui ne l''est pas.';
    END IF;
END;
$$ LANGUAGE PLPGSQL;


CREATE OR REPLACE TRIGGER trigger_autorise_emprunt BEFORE INSERT
ON emprunt FOR EACH ROW EXECUTE FUNCTION autorise_emprunt();
