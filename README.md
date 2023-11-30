# Bibliothèque

Créer les fonctions nécessaires pour gérer les opérations quotidiennes d'une bibliothèque.

## Exemple d'utilisation

```bash
$ ls
README.md  ressources  scripts

$ sudo -u postgres psql
psql (14.9 (Ubuntu 14.9-0ubuntu0.22.04.1))
Type "help" for help.

biblio# create database biblio_traore;
CREATE DATABASE
postgres=# \c biblio_traore
You are now connected to database "biblio_traore" as user "postgres".

postgres=# \i ./ressources/bibliotheque.sql
postgres=# \i ./ressources/insert-bibliotheque.sql

postgres=# \dt # Afficher les relations de la base de données

# Créer les fonctions de la bibliothèque
postgres=# \i ./scripts/mesFctsBiblio.sql

# Tester les fonctions de la bibliothèque
postgres=# \i ./scripts/testMesFctsBiblio.sql
```

### DÉPENDANCES

[SQL](https://sql.sh/)
[PostgreSQL](https://www.postgresql.org/)
[PSQL](https://docs.postgresql.fr/13/app-psql.html)
