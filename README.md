[La version française suit.](#référentiel-terraform-du-serveur-de-simulation-covid-shield)

# COVID Shield server staging terraform

This is main terraform repository for the Covid Shield server staging service.

## Bootstrap folder

The booptstrap folder contains the configuration for the S3 bucket that the main terraform will live in. It used a DynamoDB for state locking and also sets up the Route53 domain so that it is not a blocker during the main Terraform deploy process. Because it itself does not have a remote state bucket, the state file is commited as `terraform.tfstate-local`.

If changes need to be made to the bootstrap configuration it is recommend that your rename `terraform.tfstate-local` to `terraform.tfstate` to apply the changes.

## Server folder

The server folder contains the main Terraform files for the Covid Shield server. It is configured to use the bootstrapped S3 bucket and DynamoDB to handle state..

---

# Référentiel Terraform du serveur de simulation COVID Shield

Référentiel principal du service Terraform pour le serveur de simulation Covid Shield.

## Dossier d’amorçage

Le dossier d’amorçage contient la configuration du compartiment S3 dans lequel Terraform est hébergé. Il repose sur une table DynamoDB pour verrouiller l’état et sert à configurer le domaine Route53 afin d’éviter qu’il devienne un obstacle lors du déploiement principal de Terraform. Comme il n’a pas de compartiment d’état à distance, le fichier d’état est enregistré sous le nom `terraform.tfstate-local`.

Si des modifications doivent être apportées à la configuration d’amorçage, il est recommandé de renommer `terraform.tfstate-local` à `terraform.tfstate` pour les appliquer.

## Dossier du serveur

Le dossier du serveur contient les principaux fichiers Terraform pour le serveur Covid Shield. Il est configuré de sorte à utiliser le compartiment S3 et la table DynamoDB pour gérer l’état.

