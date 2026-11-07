# Status

Une application pour Mac qui reste dans la barre des menus et lit la machine sans bruit. Un clic sur l’icône en haut ouvre le processeur, la mémoire, le réseau et la batterie. Le tableau donne l’image complète. On peut aussi l’épingler sur le bureau, en quatre tailles.

Les chiffres restent sur le Mac. Rien n’est envoyé à un serveur, et aucun compte n’est demandé.

<p align="center">
  <a href="../../README.md"><img alt="English" src="https://img.shields.io/badge/English-E7E4DC?style=for-the-badge&labelColor=E7E4DC&color=3A3A3A"></a>
  <a href="./README.ar.md"><img alt="Arabic" src="https://img.shields.io/badge/%D8%A7%D9%84%D8%B9%D8%B1%D8%A8%D9%8A%D8%A9-E7E4DC?style=for-the-badge&labelColor=E7E4DC&color=3A3A3A"></a>
  <a href="./README.fr.md"><img alt="French" src="https://img.shields.io/badge/Fran%C3%A7ais-174F46?style=for-the-badge"></a>
  <a href="./README.es.md"><img alt="Spanish" src="https://img.shields.io/badge/Espa%C3%B1ol-E7E4DC?style=for-the-badge&labelColor=E7E4DC&color=3A3A3A"></a>
  <a href="./README.de.md"><img alt="German" src="https://img.shields.io/badge/Deutsch-E7E4DC?style=for-the-badge&labelColor=E7E4DC&color=3A3A3A"></a>
  <a href="./README.tr.md"><img alt="Turkish" src="https://img.shields.io/badge/T%C3%BCrk%C3%A7e-E7E4DC?style=for-the-badge&labelColor=E7E4DC&color=3A3A3A"></a>
</p>

## Télécharger

Pas de Xcode, et pas de terminal.

1. Téléchargez [Status.zip](https://github.com/0xx9/Status/releases/latest/download/Status.zip).
2. Double-cliquez sur le fichier. L’application **Status** en sort.
3. Glissez **Status** dans **Applications**.
4. La première fois, Control-clic sur **Status**, choisissez **Ouvrir**, puis **Ouvrir** encore. macOS le demande une fois, parce que cette copie ne vient pas de l’App Store.

Ensuite elle reste dans la barre des menus. Cliquez sur l’icône.

<p align="center">
  <img src="../screenshots/dashboard-light.png" alt="Le tableau Status en apparence claire" width="920">
</p>

## Ce que l’on voit

Le tableau n’est pas une liste de chiffres. Chaque instrument a un visage : un anneau, une trace, et un état.

- **Processeur.** La part actuelle, le temps utilisateur et le temps système, les cœurs performance et les cœurs efficacité, et la charge sur une, cinq et quinze minutes. Une lecture graphique apparaît à côté quand la machine en fournit une.
- **Mémoire.** Applications, mémoire câblée, compressée et en cache, avec la pression, le swap, et ce qui reste libre.
- **Réseau.** Descendant et montant sur l’interface réelle, avec l’adresse et une trace. Les interfaces internes du système sont ignorées.
- **Batterie.** Charge ou temps restant, cycles, et température quand le matériel la donne.
- **Disques.** Débit de lecture et d’écriture, et le remplissage de chaque volume.
- **Processus.** Ce qui pèse le plus en ce moment, avec une recherche, classé par processeur ou par mémoire.
- **La machine.** Puce, système, durée de fonctionnement, et état thermique.

Une ligne au-dessus du tableau dit ce qui mérite l’attention : calme, occupé, sous tension, chaud, ou batterie basse.

<p align="center">
  <img src="../screenshots/dashboard-dark.png" alt="Le tableau Status en apparence sombre" width="920">
</p>

## Barre des menus

Un clic gauche ouvre le petit panneau. Un clic droit ouvre le menu : pause, actualiser, détails, réglages, et quitter.

On choisit ce qui accompagne l’icône : processeur, mémoire, réseau ou batterie, jusqu’à trois à la fois. Une seule mesure dessine une petite trace à la place d’un nombre.

La surveillance tourne seule. On peut la mettre en pause, ou la rendre plus douce sur batterie et en mode économie d’énergie. Le rythme est d’une seconde, de deux, ou de cinq.

Une notification arrive quand le processeur, la mémoire ou la chaleur dépasse la limite choisie. Les premiers instants après le lancement restent silencieux.

Le lancement à l’ouverture de session se règle dans Réglages. Une version signée localement peut demander une autorisation unique dans Réglages Système.

## Widgets

Quatre tailles : petit, moyen, grand, et très grand. Le même tableau : un anneau pour le processeur, la mémoire, le réseau, la batterie, et une trace des dernières lectures. L’horloge sur le visage est l’heure de la dernière lecture. Quand elle avance, les chiffres sont nouveaux.

Le widget lit l’état écrit par l’application, donc il suit la barre des menus au lieu d’un échantillon trop mince. Si l’application ne tourne pas, il mesure lui-même.

<p align="center">
  <img src="../screenshots/widget-small-light.png" alt="Petit widget Status" width="220">
  &nbsp;&nbsp;
  <img src="../screenshots/widget-medium-light.png" alt="Widget Status moyen" width="460">
</p>

<p align="center">
  <img src="../screenshots/widget-large-light.png" alt="Grand widget Status" width="420">
  &nbsp;&nbsp;
  <img src="../screenshots/widget-extra-light.png" alt="Très grand widget Status" width="640">
</p>

Après une nouvelle version, retirez l’ancien widget Status du bureau et ajoutez-le de nouveau. macOS garde un widget lié à la copie de l’application depuis laquelle il a été ajouté.

## Langue

L’application suit la langue du système. En arabe, la mise en page va de droite à gauche et les chiffres restent en place. Les réglages basculent entre l’arabe et l’anglais.

Les pages de ce dépôt sont distinctes. Les boutons en haut ouvrent la même explication en anglais, arabe, espagnol, allemand et turc.

## Compilation

Seulement si vous voulez compiler vous-même. Le téléchargement ci-dessus est l’application. macOS 15 et Xcode 16 ou plus récent.

```bash
git clone https://github.com/0xx9/Status.git
cd Status
xcodebuild -project Status.xcodeproj -scheme Status -destination 'platform=macOS' -configuration Release build
open ~/Library/Developer/Xcode/DerivedData/Status-*/Build/Products/Release/Status.app
```

Ou ouvrez `Status.xcodeproj` et lancez-le.

L’application elle-même n’est pas sandboxée, parce que les processus, les disques et le réseau l’exigent. L’extension du widget l’est, et elle lit le fichier d’état que l’application écrit dans le conteneur du widget.

## Dans le projet

| Dossier | Rôle |
| --- | --- |
| `Status` | Barre des menus, tableau, réglages et alertes |
| `StatusWidgets` | Le widget macOS |
| `Shared` | Mesure, calcul, format et textes |
| `StatusTests` | Calcul, format, et un échantillon réel de la machine |
| `tools` | Le dessin de l’icône |

Version 1.0. Identifiant `com.muhsan.status`.
