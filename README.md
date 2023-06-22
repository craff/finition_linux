
Script pour finaliser un poste linux dans eole
==============================================

Les principaux intérêts de ce script:
-------------------------------------

- authentification sur le proxy eole de firefox et chromium (et en fait de
  http/https/ftp/wss (attention, il y a une astuce pour chromium)

- utilisation du dossier perso scribe comme home!
  - évite que l'élève ne sauvegarde pas un fichier
  - pour l'instant la configuration du mount est avec noexec ce qui posent
    des problèmes avec certaines appli comme jupyter-notebook.On contourne
    le problème, mais peut-être qu'autoriser noexec serait mieux.

- utilisation d'un script python qui interroge une base de données
  pour faire tourner des script sur les machines. Voire
  scripts/run_scripts.sql pour la structure de la base à créer.  Ce
  script ce charge aussi de nommer les machines, car le nommage via le
  dhcp d'eole est plutôt pénible. Il faut alors rentrer le hostname
  dans la table une foix que le script a tourné sur la machine

- pleins d'autres choses à voir dans le fichier finition.sh

Pour utiliser ce script, il faut:
---------------------------------

- personnaliser les variables au début du finition.sh

- Dans le makefile, éventuellement mettre à jour les liens vers les .deb
  les plus récents

- taper `make` pour ramener les .deb qui ne sont pas dans les dépôts et notre
  cntlm patché. Ce cntlm ce trouve sur `https://github.com/craff/cntlm`

- installer le poste avec linux mint 20.3 (à tester avec une version
  plus récente et à adapter pour debian)

- mettre une exception dans amon pour l'IP du poste ou vérifier que les
  sites utilisés ne demandent pas de proxy authentifié (la seconde solution
  est préférable).

- lancer le script avec
    `sudo bash -e finition.sh`
    ou
    `source cp.sh` (copie la clef dans tmp, on peut l'enlever dès qu'il demande le mot de passe de sudo)

- enlever l'exception pour le poste dans amon.
