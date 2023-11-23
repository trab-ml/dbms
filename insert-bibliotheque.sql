insert into theme values(1,'litterature francaise');
insert into theme values(2,'politique');
insert into theme values(3,'litterature etrangere');

SELECT pg_catalog.setval('theme_id_theme_seq', 3, true);

insert into auteur values(1,'Vargas','Fred','Marseille');
insert into auteur values(2,'Coe','Jonathan','Londres');
insert into auteur values(3,'Mahfouz','Nagib','Le Caire');
insert into auteur values(4,'Boyden','Joseph','Toronto');
insert into auteur values(5,'Gaude','Laurent','Paris');
insert into auteur values(6,'Quint','Michel','Lille');
insert into auteur values(7,'Fernandez','Dominique','Naples');
insert into auteur values(8,'Ferranti','Ferrante','Naples');

SELECT pg_catalog.setval('auteur_id_auteur_seq', 8, true);

insert into editeur values(1,'folio','Paris');
insert into editeur values(2,'gorgone','Lille');
insert into editeur values(3,'babel','Arles');
insert into editeur values(4,'fayard','Arles');
insert into editeur values(5,'seuil','Paris');	
insert into editeur values(6,'10-18','Paris');

SELECT pg_catalog.setval('editeur_id_editeur_seq', 6, true);

insert into oeuvre values(1,1,'Le soleil des Scorta',3);
insert into oeuvre values(2,3,'Le chemin des âmes',5);
insert into oeuvre values(3,3,'Bienvenue au club',1);
insert into oeuvre values(4,2,'Le cercle fermé',6);
insert into oeuvre values(5,1,'Et mon mal est délicieux',2);
insert into oeuvre values(6,1,'Sous les vents de Neptune',1);
insert into oeuvre values(7,1,'Dans les bois éternels',2);
insert into oeuvre values(8,1,'Effroyables jardins',2);
insert into oeuvre values(9,1,'La perle et le croissant',5);

SELECT pg_catalog.setval('oeuvre_id_oeuvre_seq', 9, true);

insert into oeuvreauteur values(1,5);
insert into oeuvreauteur values(2,4);
insert into oeuvreauteur values(3,2);
insert into oeuvreauteur values(4,2);
insert into oeuvreauteur values(5,6);
insert into oeuvreauteur values(6,1);
insert into oeuvreauteur values(7,1);
insert into oeuvreauteur values(8,6);
insert into oeuvreauteur values(9,7);
insert into oeuvreauteur values(9,8);


insert into adherent values(1,'Patamob','Adhémar',0);
insert into adherent values(2,'Zeublouse','Agathe',0);
insert into adherent values(3,'Rivenbusse','Elsa',0);
insert into adherent values(4,'Comindieu','Thibaud',0);
insert into adherent values(5,'Ardelpic','Helmut',0);
insert into adherent values(6,'Peulafenetre','Firmin',20);
insert into adherent values(7,'Locale','Anasthasie',0);
insert into adherent values(8,'Bierrekeuchprefere','Michel',0);

SELECT pg_catalog.setval('adherent_id_adherent_seq', 8, true);

insert into livre values(1,1,'2006-01-08',0);
insert into livre values(2,1,'2007-01-08',0);
insert into livre values(3,1,'2008-01-08',0);
insert into livre values(4,2,'2006-01-08',0);
insert into livre values(5,3,'2008-01-08',0);
insert into livre values(6,2,'1970-01-08',0);
insert into livre values(7,4,'2001-01-08',0);
insert into livre values(8,5,'2001-01-08',0);
insert into livre values(9,6,'2003-11-03',0);
insert into livre values(10,7,'2003-11-03',0);
insert into livre values(11,7,'2003-11-03',0);
insert into livre values(12,9,'2010-10-03',0);
insert into livre values(13,9,'2010-10-03',0);
insert into livre values(14,9,'2010-10-03',0);

SELECT pg_catalog.setval('livre_id_livre_seq', 14, true);

insert into emprunt values(1,8,9,'2011-09-03');
insert into emprunt values(2,3,10,'2011-09-03');
insert into emprunt values(3,4,11,'2011-09-03');
insert into emprunt values(4,3,12,'2011-09-19');
insert into emprunt values(5,3,5,'2011-09-17');
insert into emprunt values(6,8,6,'2011-09-18');

SELECT pg_catalog.setval('emprunt_id_emprunt_seq', 6, true);

insert into histoemprunt values(1,1,1,'2011-08-01','2011-08-12');
insert into histoemprunt values(2,1,2,'2011-08-01','2011-08-26');
insert into histoemprunt values(3,2,3,'2011-08-01','2011-08-12');
insert into histoemprunt values(4,2,4,'2011-08-01','2011-08-14');
insert into histoemprunt values(5,5,5,'2011-08-01','2011-08-20');
insert into histoemprunt values(6,4,6,'2011-08-01','2011-09-05');
insert into histoemprunt values(7,3,7,'2011-08-01','2011-08-26');
insert into histoemprunt values(8,8,8,'2011-08-01','2011-08-26');
insert into histoemprunt values(9,1,9,'2011-05-25','2011-06-25');
insert into histoemprunt values(10,3,7,'2011-08-30','2011-09-20');
insert into histoemprunt values(11,8,8,'2011-08-27','2011-08-31');
insert into histoemprunt values(12,1,9,'2011-07-25','2011-08-25');

SELECT pg_catalog.setval('histoemprunt_id_histoemprunt_seq', 12, true);
