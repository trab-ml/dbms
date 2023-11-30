-- TEST POUR "ÉCRIRE DES FONCTIONS SQL ET PL/SQL"
-- EXO1
CREATE OR REPLACE FUNCTION test_nbre_exemplaires_exo1() RETURNS INTEGER AS $$
    SELECT nbre_exemplaires(1);
$$ LANGUAGE SQL;

SELECT test_nbre_exemplaires_exo1();

-- EXO2
CREATE OR REPLACE FUNCTION test_est_emprunte_exo2() RETURNS boolean AS $$
    SELECT est_emprunte(1);
$$ LANGUAGE SQL;

SELECT test_est_emprunte_exo2(); 

-- EXO3
CREATE OR REPLACE FUNCTION test_les_livres_presents_exo3() RETURNS SETOF les_livres_presents_type AS $$
    SELECT les_livres_presents(); 
$$ LANGUAGE SQL;

SELECT * FROM test_les_livres_presents_exo3();

-- EXO4
CREATE OR REPLACE FUNCTION test_nbre_emprunts_exo4() RETURNS INTEGER AS $$
    SELECT nbre_emprunts(1);
$$ LANGUAGE SQL;

SELECT * FROM test_nbre_emprunts_exo4();

-- EXO5
CREATE OR REPLACE FUNCTION test_les_plus_empruntes_exo5() RETURNS TABLE ( titre_oeuvre TEXT, emprunts INT ) AS $$
    SELECT les_plus_empruntes();
$$ LANGUAGE SQL;

SELECT 'EXO5' AS INFO;
SELECT * FROM test_les_plus_empruntes_exo5(); 

-- EXO6
CREATE OR REPLACE FUNCTION test_infos_oeuvres() RETURNS VOID AS $$
    SELECT all_infos_oeuvres();
$$ LANGUAGE SQL;

-- Exécution du test
SELECT 'EXO6' AS INFO;
SELECT test_infos_oeuvres();

-- TEST POUR "LES DÉCLENCHEURS"
-- EXO1
CREATE OR REPLACE FUNCTION test_trigger_check_livres_empruntes_exo1() RETURNS VOID AS $$
    BEGIN
        INSERT INTO emprunt(id_adherent, id_livre, date_emprunt) VALUES (1, 1, NOW());
        INSERT INTO emprunt(id_adherent, id_livre, date_emprunt) VALUES (1, 2, NOW());
        INSERT INTO emprunt(id_adherent, id_livre, date_emprunt) VALUES (1, 3, NOW());
        INSERT INTO emprunt(id_adherent, id_livre, date_emprunt) VALUES (1, 4, NOW());
    END;
$$ LANGUAGE PLPGSQL;

-- Exécution du test
SELECT 'EXO1_DECLENCHEURS' AS INFO;
SELECT test_trigger_check_livres_empruntes_exo1();

-- EXO2
-- L'adhérent ayant pour identifiant 2 (id_adherent = 2) essaie d'emprunter un livre (id_livre = 1) déjà emprunté.
CREATE OR REPLACE FUNCTION test_trigger_check_deja_emprunte_exo2() RETURNS VOID AS $$
    BEGIN
        INSERT INTO emprunt(id_adherent, id_livre, date_emprunt) VALUES (1, 1, NOW());
        INSERT INTO emprunt(id_adherent, id_livre, date_emprunt) VALUES (2, 1, NOW());
    END;
$$ LANGUAGE PLPGSQL;

SELECT 'EXO2_DECLENCHEURS' AS INFO;
SELECT test_trigger_check_deja_emprunte_exo2();

-- EXO3
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
CREATE OR REPLACE FUNCTION test_peut_emprunter_exo4() RETURNS VOID AS $$
    INSERT INTO emprunt(id_adherent, id_livre, date_emprunt) VALUES (1, 2, '2011-09-03');
    INSERT INTO emprunt(id_adherent, id_livre, date_emprunt) VALUES (1, 1, NOW());
$$ LANGUAGE SQL;

SELECT 'EXO4_DECLENCHEURS' AS INFO;
SELECT test_peut_emprunter_exo4();

-- EXO5
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

-- EXO6: 
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

-- EXO8
CREATE OR REPLACE FUNCTION test_ajouter_champ_sorti_exo8() RETURNS VOID AS $$
BEGIN
    PERFORM 'sorti' FROM information_schema.columns
    WHERE table_name = 'livre' AND column_name = 'sorti';
    
    IF FOUND THEN
        RAISE NOTICE 'Le champ sorti existe dans la table livre !';
    ELSE
        RAISE NOTICE 'Le champ sorti n''existe pas dans la table livre !';
    END IF;
END;
$$ LANGUAGE PLPGSQL;

SELECT 'EXO8_DECLENCHEURS' AS INFO;
SELECT test_ajouter_champ_sorti_exo8();

-- EXO9
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

    -- Suppression des modifications apportées par le test
    DELETE FROM emprunt WHERE id_livre = param_id_livre AND date_emprunt = param_date_emprunt;

    -- Vérification
    IF NOT EXISTS (SELECT 1 FROM livre WHERE id_livre = param_id_livre AND sorti = FALSE) THEN
        RAISE EXCEPTION 'Le champ sorti n''a pas été mis à jour après le retour.';
    END IF;

    RAISE NOTICE 'Le champ sorti a été mis à jour après l''emprunt et le retour !';
END;
$$ LANGUAGE PLPGSQL;

SELECT 'EXO9_DECLENCHEURS' AS INFO;
SELECT test_maj_sorti_exo9();

-- EXO10
CREATE OR REPLACE FUNCTION test_ajouter_champ_reserve_adh_exo10() RETURNS VOID AS $$
BEGIN
    PERFORM 'sorti' FROM information_schema.columns
    WHERE table_name = 'livre' AND column_name = 'sorti';
    
    IF FOUND THEN
        RAISE NOTICE 'Le champ reserve_adh existe dans la table livre !';
    ELSE
        RAISE NOTICE 'Le champ reserve_adh n''existe pas dans la table livre !';
    END IF;
END;
$$ LANGUAGE PLPGSQL;

SELECT 'EXO10_DECLENCHEURS' AS INFO;
SELECT test_ajouter_champ_reserve_adh_exo10();

-- EXO11: L'adhérent 1 essaie d'emprunter le livre 4 (qu'il a déjà réservé).
CREATE OR REPLACE FUNCTION test_autorise_emprunt_exo11() RETURNS VOID AS $$
DECLARE
    param_id_adherent INTEGER := 1;
    param_id_livre INTEGER := 4;
    param_date_emprunt DATE := NOW();
BEGIN
    -- L'adhérent 1 réserve le livre 4
    UPDATE livre SET reserve_adh = param_id_adherent WHERE id_livre = param_id_livre;

    -- L'adhérent 1 emprunte le livre 4
    INSERT INTO emprunt(id_adherent, id_livre, date_emprunt) VALUES (param_id_adherent, param_id_livre, param_date_emprunt);

    IF NOT EXISTS (
        SELECT 1 FROM livre WHERE id_livre = param_id_livre AND reserve_adh IS NULL
    ) THEN
        RAISE EXCEPTION 'Le champ reserve_adh n''a pas été correctement mis à jour après l''emprunt par le même adhérent.';
    END IF;

    DELETE FROM emprunt e 
    WHERE e.id_adherent = param_id_adherent
     AND e.id_livre = param_date_emprunt 
     AND e.date_emprunt = param_date_emprunt; 

    UPDATE livre SET sorti = FALSE 
    WHERE id_livre = param_id_livre AND reserve_adh IS NULL;
END;
$$ LANGUAGE PLPGSQL;

ALTER TABLE livre DISABLE TRIGGER ALL;
ALTER TABLE emprunt DISABLE TRIGGER ALL;

ALTER TABLE emprunt ENABLE TRIGGER trigger_autorise_emprunt;

SELECT 'EXO11_DECLENCHEURS' AS INFO;
SELECT test_autorise_emprunt_exo11();

ALTER TABLE livre ENABLE TRIGGER ALL;
ALTER TABLE emprunt ENABLE TRIGGER ALL;