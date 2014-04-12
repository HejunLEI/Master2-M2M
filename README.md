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
* **Mosquitto publisher:** mosquitto_pub compilé pour l'OS "Clanton". Client mosquitto dédié à la publication sur un serveur mosquitto.
* **Serveur mosquitto:** Serveur mosquitto standard. Permet d'utiliser un système de "Publish and subscribe" sur des mots clés donnés.
* **openHAB:** Récupères le status du detecteur de fumée (ON/OFF). Détermines si il y a vraiment incendie, et publie sur le serveur mosquitto la présence ou l'absence réelle d'un incendie.
* **Node-RED:** Fait passerelle entre le serveur mosquitto et MongoDB. Chaque évènement publié sur le serveur mosquitto est enregistré en base. Node-RED sert à réaliser facilement des liens entres divers applications, I/O, ... .
* **MongoDB:** Base de donnée enregistrant tous les évènements liés aux capteurs. MongoDB est un base de donnée de type SQL.
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


Puis nous avons décompressé l'OS Clanton sur une carte SD, en prévision d'utiliser openHAB sur l'Intel Galileo nous avons utilisé la version "Yocto Project Linux image w/ Clanton-full kernel + general SDKs + Oracle JDK 8 + Tomcat", mais une version moins complète (du moins sans Java), devrai suffire. Clanton est téléchargeable à l'adresse suivante: http://ccc.ntu.edu.tw/index.php/en/news/40 .

L'Intel Galileo bootera automatiquement sur la version de Clanton que vous aurez installé.

Avant de continuer, vous devrez pouvoir vous connecter en SSH à votre Intel Galileo. Pour cela, branchez votre Intel Galileo à votre routeur, ou mettez en palce un serveur DHCP sur votre propre machine et connectez l'Intel Galileo directement à celle-ci. Les manipulations à venir se feront directement sur votre carte Intel Galileo via SSH (ou autre protocol).

Afin de communiquer via mosquitto, nous avons dut compiler une version de ce dernier. Hors mosquitto possède une dépendance à la bibliothèque "c-ares", qui n'est malheureusement pas présente sur l'installation initiale de Clanton. Nous avons donc dut build notre propre version de c-ares sur notre Intel Galileo. Pour cela, nous vous conseillons de suivre les indications du fichier "INSTALL" présent dans [l'archive de c-ares](http://c-ares.haxx.se/download/).

Vous pouvez dèsormais build votre propre version de mosquitto pour l'Intel Galileo! Pour cela, téléchargez la [dernière version de mosquitto](http://mosquitto.org/download/). Vous pouvez ensuite utiliser la commande "make" pour compiler votre version de mosquitto.

La principale difficulté ensuite a résidé dans le fait qu'il nous était impossible d'utiliser un sketch arduino standard en même temps que le Galileo était sous Clanton. Nous avons donc dut nous documenter afin de récupérer les entrées/sorties de l'Intel Galileo sous Clanton et les traiter via un script shell.
Une fois mosquitto installé, vous pouvez utiliser le [script shell](https://github.com/DevYourWorld/Master2-M2M/blob/master/galileo/hacksignal.sh) disponible sur ce même repository. Pour mieux comprendre le fonctionnement de ce script, nous vous invitons à consulter le site [malinov.com](http://www.malinov.com/Home/sergey-s-blog/intelgalileo-programminggpiofromlinux) qui nous a aidé à récupérer les entrées/sorties désirées de l'Intel Galileo.

**ATTENTION:** Pour que celui-ci fonctionne, vous devrez impérativement brancher votre détecteur de fumée sur l'entrée analogique 0 (A0) de votre Intel Galileo. 
Afin de ne pas griller votre carte, nous vous invittons à respecter le schéma suivant:

![alt tag](https://github.com/DevYourWorld/Master2-M2M/blob/master/etc/branchements.png?raw=true)

### Serveur distant ###
Le serveur distant que nous avons utilisé fut une machine utilisant Xubuntu 13.10. La configuration et l'installation expliquée ci-dessous concerneront donc cette version de Xubuntu.


**Mosquitto et MongoDB**

Tout d'abord, certaines briques ne necessitent pas ou très peu de configuration, c'est le cas de Mosquitto et de MongoDB. Nnous vous proposons de vous les procurer en premier:

	sudo add-apt-repository ppa:mosquitto-dev/mosquitto-ppa
	sudo apt-get update
	sudo apt-get install mosquitto
	sudo apt-get install mongodb-server

Editez ensuite le fichier "/etc/init.d/mongodb" pour ajouter l'argument "--rest" au lancement de ce dernier. L'option "--rest" de MongoDB permet de consulter toutes les entrées en base à partir de son lancement à une URL de type: "http://localhost:28017/BD/Collection" par défaut. Les données consultablent respectent le format JSON.


**openHAB**

L'étape suivante consiste à récupérer et configurer openHAB. Nous aurons besoin du "runtime core" et des addons téléchargeables tous deux à [ici](http://www.openhab.org/downloads.html).

Les deux choses qu'aura à faire openHAB seront:
* Identifier la présence d'un incendie (ici, typiquement, à chaque fois que l'alarme sonne).
* Emettre un son au déclenchement et à l'extinction d'un incendie.

Pour cela, il faut qu'openHAB puisse écouter notre serveur mosquitto et emettre sur ce dernier, addons respectifs:
* org.openhab.binding.mqtt-1.4.0.jar
* org.openhab.persistence.mqtt-1.4.0.jar

Afin de pouvoir émettre un son, openHAB a aussi besoin d'un addon de synthèse vocale:
* org.openhab.persistence.mqtt-1.4.0.jar

Nous devons maintenant utiliser ces différentes briques. Pour cela, nous allons d'abord apprendre à contacter notre serveur mosquitto fraichement installé en rajoutant la ligne suivante au fichier "configuration/openhab_default.cfg":

	mqtt:mosquitto.url=tcp://localhost:1883

Puis déclarer des items utilisant mosquitto en entrée/sortie dans le fichier "configuration/items/m2m.items":

	Switch M2M_Fumee { mqtt="<[mosquitto:smokedetector:state:default]" }
	Switch M2M_Feu { mqtt=">[mosquitto:fire:command:ON:ON],>[mosquitto:fire:command:OFF:OFF]" }

Ici, <[...] correspond à un subscribe et >[...] correspond à un publish. Les items sont tous les deux des switch car ils ne possèdent que deux états: allumé lors de la présence de fumée et éteint sinon.

Le lien entre les 2 items et l'émission d'un son se fait dans les règles d'openHAB, plus précisement dans le fichier "configuration/rules/rules.rules".

Les fichiers relatifs à notre utilisation d'openHAB sont disponibles sur ce même repository ([openHAB](https://github.com/DevYourWorld/Master2-M2M/blob/master/serveur_distant/openHAB)).


**Node-RED**

Il ne nous reste maintenant plus que deux briques à mettre en place: mqtt-panel et Node-RED. Nous nous interesserons à cette dernière téléchargeable [ici](http://nodered.org/).

Node-RED est ici utilisé pour subscribe à notre serveur mqtt et notifier MongoDB quand un nouvel évènement se produit. Pour cela, vous devrez installer via npm les extensions necessaires pour communiquer via mqtt et pour écrire dans une base de donnée mongodb.

Une fois lancé, Node-RED peut être utilisé à l'adresse suivante: "http://localhost:1880/". Afin que les données stockées soient réellement utilisables, nous avons aussi stoqué leur timestamp afin de pouvoir les classer par ordre d'évènements.

![alt tag](https://github.com/DevYourWorld/Master2-M2M/blob/master/etc/node-red.png?raw=true)

Les fichiers relatifs à notre installation de node-red sont disponibles sur ce même repository ([Node-RED](https://github.com/DevYourWorld/Master2-M2M/blob/master/serveur_distant/node-red)).


**mqtt-panel**

Avant toutes choses, il faut nous procurer mqtt-panel, téléchargeable ici: [ici](https://github.com/fabaff/mqtt-panel).

Il faut tout comme Node-RED, installer les dépendances exigées via npm:

	npm install mqtt socket.io

Puis ensuite éditer le fichier "index.html" afin que celui-ci couvre nos besoins. Dans le cas présent, nous avons besoin que le status de "smokedetector" et "fire" soient donnés, nous avons aussi rajouté un graphe lié à la présence d'un incendie, juste pour comprendre un peu mieux mqtt.

Le fichier index.html est disponible sur ce même repository ([mqtt-panel](https://github.com/DevYourWorld/Master2-M2M/blob/master/serveur_distant/mqtt-panel)).
