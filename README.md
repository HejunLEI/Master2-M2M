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
#### Installation ####
