
CREATE TABLE theme (
    id_theme serial primary key,
    nom_theme character varying(30)
);



CREATE TABLE auteur (
    id_auteur serial  primary key,
    nom_auteur character varying(50),
    prenom_auteur character varying(50),
    ville_auteur character varying(50)
);



CREATE TABLE editeur (
    id_editeur serial primary key,
    nom_editeur character varying(50),
    ville_editeur character varying(50)
);



CREATE TABLE oeuvre (
    id_oeuvre serial primary key,
    id_theme integer references theme,
    titre character varying(50),
    id_editeur integer references editeur
);


CREATE TABLE oeuvreauteur (
    id_oeuvre integer NOT NULL references oeuvre,
    id_auteur integer NOT NULL references auteur,
    CONSTRAINT oeuvreauteur_pkey PRIMARY KEY (id_oeuvre, id_auteur)
);



CREATE TABLE adherent (
    id_adherent serial  primary key,
    nom_adherent character varying(50),
    prenom_adherent character varying(50),
    amende_adherent integer DEFAULT 0
);


CREATE TABLE livre (
    id_livre serial  primary key,
    id_oeuvre integer,
    date_acquisition date,
    prix real DEFAULT 0
);


CREATE TABLE emprunt (
    id_emprunt serial  primary key,
    id_adherent integer,
    id_livre integer,
    date_emprunt date
);


CREATE TABLE histoemprunt (
    id_histoemprunt serial primary key,
    id_adherent integer references adherent,
    id_livre integer references livre,
    date_emprunt date NOT NULL,
    date_retour date
);

