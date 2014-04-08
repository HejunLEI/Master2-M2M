# Projet M2M de Master 2 #

## Introduction ##
Dans le cadre de l'UE M2M, nous avons été emmennés à mettre en place une infrastructure de collecte de données depuis des capteurs à l'aide d'une carte de type arduino. Pour cela, le matériel mis à notre disposition fut:
* 1 Carte Intel Galileo (et de quoi la brancher en USB et en Ethernet)
* 1 Détecteur de fumée
* 1 Platine d'expérimentation (Prototype breadboard) 
* 2 Résistances
* 2 Cables électriques
* Une distribution "Clanton" pour Intel Galileo

Notre but fut alors de remonter les données de notre détecteur de fumée vers un serveur réunissant en théorie les données de plusieurs capteurs. L'infrastructure imaginée est telle que ci-dessous:

![alt tag](https://github.com/DevYourWorld/Master2-M2M/blob/master/etc/infrastructure.png?raw=true)



Expliquons brievement le rôle joué par chacune des briques visibles sur ce schéma:
* **Script d'initialisation et de lecture des données du capteur:** Initialiser l'entrée analogique A0 de l'Intel Galileo. Lire celle-ci, et envoyé les données reçues en entrée via "mosquitto_pub".
* **Mosquitto publisher:** mosquitto_pub compilé pour l'OS "Clanton".
* **Serveur mosquitto:** Serveur mosquitto standard.
* **openHAB:** Récupères le status du detecteur de fumée (ON/OFF). Détermines si il y a vraiment incendie, et publie sur le serveur mosquitto la présence ou l'absence réel d'un incendie.
* **Node-RED:** Fait passerelle entre le serveur mosquitto et MongoDB. Chaque évènement publié sur le serveur mosquitto est enregistré en base.
* **MongoDB:** Base de donnée enregistrant tous les évènements liés aux capteurs.
* **mqtt-panel:** Permet de visualiser via une interface web l'état actuel de l'infrastructure.


## Mise en place ##
### Intel Galileo ###
Avant de commencer, il nous a fallu mettre à jour le firmware de notre Intel Galileo. Pour celà, nous avons suivi les instructions disponibles à l'adresse suivante: http://air.imag.fr/images/2/29/Galileo_GettingStarted.pdf .

Nous avons ensuite formaté une carte miniSD de façon à ce que celle-ci soit bootable.

**Sous Windows :**

	diskpart.exe
	select vol e	//la lettre correspondant à la carte SD
	clean
	create part primary
	active
	format quick label="BOOTME"
	exit

**Sous Linux :**
	TODO


Puis nous avons décompressé l'OS Clanton sur une carte SD, en prévision d'utiliser openHAB sur l'Intel Galileo nous avons utilisé la version "Yocto Project Linux image w/ Clanton-full kernel + general SDKs + Oracle JDK 8 + Tomcat", mais une version moins complète (du moins sans Java), devrai suffire. Clanton est téléchargeable à l'adresse suivante: http://ccc.ntu.edu.tw/index.php/en/news/40 .

L'Intel Galileo bootera automatiquement sur la version de Clanton que vous aurez installé.

Avant de continuer, vous devrez pouvoir vous connecter en SSH à votre Intel Galileo. Pour cela, branchez votre Intel Galileo à votre routeur, ou mettez en palce un serveur DHCP sur votre propre machine et connectez l'Intel Galileo directement à celle-ci. Les manipulations à venir se feront directement sur votre carte Intel Galileo via SSH (ou autre protocol).

Afin de communiquer via mosquitto, nous avons dut compiler une version de ce dernier. Hors mosquitto possède une dépendance à la bibliothèque "c-ares", qui n'est malheureusement pas présente sur l'installation initiale de Clanton. Nous avons donc dut build notre propre version de c-ares sur notre Intel Galileo. Pour cela, nous vous conseillons de suivre les indications du fichier "INSTALL" présent dans [l'archive de c-ares](http://c-ares.haxx.se/download/).

Vous pouvez dèsormais build votre propre version de mosquitto pour l'Intel Galileo! Pour cela, téléchargez la [dernière version de mosquitto](http://mosquitto.org/download/). Vous pouvez ensuite utiliser la commande "make" pour compiler votre version de mosquitto.

Une fois mosquitto installé, vous pouvez utiliser le [script](https://github.com/DevYourWorld/Master2-M2M/blob/master/files/hacksignal.sh) disponible sur ce même repository. Pour mieux comprendre le fonctionnement de ce script, nous vous invitons à consulter le site [malinov.com](http://www.malinov.com/Home/sergey-s-blog/intelgalileo-programminggpiofromlinux).

Pour que celui-ci fonctionne, vous devrez impérativement brancher votre détecteur de fumée sur l'entrée analogique 0 (A0) de votre Intel Galileo. 
Afin de ne pas griller votre carte, nous vous invittons à respecter le schéma suivant:

![alt tag](https://github.com/DevYourWorld/Master2-M2M/blob/master/etc/branchements.png?raw=true)

