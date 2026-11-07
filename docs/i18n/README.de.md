# Status

Eine Mac-App, die in der Menüleiste sitzt und den Rechner ruhig liest. Ein Klick auf das Symbol oben öffnet Prozessor, Speicher, Netzwerk und Batterie. Die Tafel zeigt das ganze Bild. Sie lässt sich auch als Widget auf den Schreibtisch legen, in vier Größen.

Die Zahlen bleiben auf dem Mac. Nichts geht an einen Server, und ein Konto ist nicht nötig.

<p align="center">
  <a href="../../README.md"><img alt="English" src="https://img.shields.io/badge/English-E7E4DC?style=for-the-badge&labelColor=E7E4DC&color=3A3A3A"></a>
  <a href="./README.ar.md"><img alt="Arabic" src="https://img.shields.io/badge/%D8%A7%D9%84%D8%B9%D8%B1%D8%A8%D9%8A%D8%A9-E7E4DC?style=for-the-badge&labelColor=E7E4DC&color=3A3A3A"></a>
  <a href="./README.fr.md"><img alt="French" src="https://img.shields.io/badge/Fran%C3%A7ais-E7E4DC?style=for-the-badge&labelColor=E7E4DC&color=3A3A3A"></a>
  <a href="./README.es.md"><img alt="Spanish" src="https://img.shields.io/badge/Espa%C3%B1ol-E7E4DC?style=for-the-badge&labelColor=E7E4DC&color=3A3A3A"></a>
  <a href="./README.de.md"><img alt="German" src="https://img.shields.io/badge/Deutsch-174F46?style=for-the-badge"></a>
  <a href="./README.tr.md"><img alt="Turkish" src="https://img.shields.io/badge/T%C3%BCrk%C3%A7e-E7E4DC?style=for-the-badge&labelColor=E7E4DC&color=3A3A3A"></a>
</p>

## Laden

Kein Xcode, und kein Terminal.

1. [Status.zip](https://github.com/0xx9/Status/releases/latest/download/Status.zip) laden.
2. Die Datei doppelklicken. Die App **Status** kommt heraus.
3. **Status** in **Programme** ziehen.
4. Beim ersten Mal **Status** mit Control-Klick öffnen, **Öffnen** wählen, dann noch einmal **Öffnen**. macOS fragt einmal, weil diese Kopie nicht aus dem App Store stammt.

Danach bleibt sie in der Menüleiste. Auf das Symbol klicken.

<p align="center">
  <img src="../screenshots/dashboard-light.png" alt="Die Status-Tafel in heller Darstellung" width="920">
</p>

## Was zu sehen ist

Die Tafel ist keine Zahlenliste. Jedes Instrument hat ein Gesicht: einen Ring, eine Spur und einen Zustand.

- **Prozessor.** Der aktuelle Anteil, Benutzerzeit und Systemzeit, Leistungs- und Effizienzkerne, und die Last über eine, fünf und fünfzehn Minuten. Eine Grafikablesung erscheint daneben, wenn der Rechner sie meldet.
- **Speicher.** Apps, fest verdrahtet, komprimiert und zwischengespeichert, mit Druck, Swap und dem, was noch frei ist.
- **Netzwerk.** Download und Upload auf der echten Schnittstelle, mit Adresse und Spur. Interne Systemschnittstellen zählen nicht mit.
- **Batterie.** Ladung oder Restzeit, Zyklen, und Temperatur, wenn die Hardware sie liefert.
- **Platten.** Lese- und Schreibrate, und wie voll jedes Volume ist.
- **Prozesse.** Was gerade am schwersten ist, mit Suche, sortiert nach Prozessor oder Speicher.
- **Der Rechner.** Chip, System, Laufzeit und Wärmezustand.

Eine Zeile über der Tafel sagt, was Aufmerksamkeit verdient: ruhig, beschäftigt, unter Druck, heiß, oder schwache Batterie.

<p align="center">
  <img src="../screenshots/dashboard-dark.png" alt="Die Status-Tafel in dunkler Darstellung" width="920">
</p>

## Menüleiste

Ein Linksklick öffnet das kleine Feld. Ein Rechtsklick öffnet das Menü: Überwachung pausieren, aktualisieren, Details, Einstellungen und beenden.

Neben dem Symbol stehen Prozessor, Speicher, Netzwerk oder Batterie, bis zu drei zugleich. Eine einzelne Messung zeichnet eine kleine Spur statt einer Zahl.

Die Überwachung läuft von allein. Sie lässt sich anhalten oder auf Batterie und im Energiesparmodus sanfter stellen. Das Tempo ist eine Sekunde, zwei Sekunden oder fünf.

Eine Mitteilung kommt, wenn Prozessor, Speicher oder Wärme die gesetzte Grenze überschreitet. Die ersten Augenblicke nach dem Start bleiben still.

Der Start bei der Anmeldung liegt in den Einstellungen. Ein lokal signierter Build kann macOS einmal um Zustimmung bitten, in den Systemeinstellungen.

## Widgets

Vier Größen: klein, mittel, groß und extragroß. Dieselbe Tafel: ein Prozessorring, Speicher, Netzwerk, Batterie und eine Spur der letzten Messungen. Die Uhr im Gesicht ist die Zeit der letzten Messung. Bewegt sie sich, sind die Zahlen neu.

Das Widget liest den Zustand, den die App schreibt, und folgt deshalb der Menüleiste statt einer dünnen eigenen Probe. Läuft die App nicht, misst es selbst.

<p align="center">
  <img src="../screenshots/widget-small-light.png" alt="Kleines Status-Widget" width="220">
  &nbsp;&nbsp;
  <img src="../screenshots/widget-medium-light.png" alt="Mittleres Status-Widget" width="460">
</p>

<p align="center">
  <img src="../screenshots/widget-large-light.png" alt="Großes Status-Widget" width="420">
  &nbsp;&nbsp;
  <img src="../screenshots/widget-extra-light.png" alt="Extragroßes Status-Widget" width="640">
</p>

Nach einem neuen Build das alte Status-Widget vom Schreibtisch entfernen und neu hinzufügen. macOS bindet ein Widget an die App-Kopie, aus der es hinzugefügt wurde.

## Sprache

Die App folgt der Systemsprache. Auf Arabisch läuft das Layout von rechts nach links, und die Zahlen bleiben an ihrem Platz. Die Einstellungen wechseln zwischen Arabisch und Englisch.

Die Seiten dieses Depots sind getrennt. Die Knöpfe oben öffnen dieselbe Erklärung auf Englisch, Arabisch, Französisch, Spanisch und Türkisch.

## Bauen

Nur wenn Sie selbst kompilieren wollen. Der Download oben ist die App. macOS 15 und Xcode 16 oder neuer.

```bash
git clone https://github.com/0xx9/Status.git
cd Status
xcodebuild -project Status.xcodeproj -scheme Status -destination 'platform=macOS' -configuration Release build
open ~/Library/Developer/Xcode/DerivedData/Status-*/Build/Products/Release/Status.app
```

Oder `Status.xcodeproj` öffnen und starten.

Die App selbst ist nicht in einer Sandbox, weil Prozesse, Platten und das Netzwerk das brauchen. Die Widget-Erweiterung ist es, und sie liest die Zustandsdatei, die die App in den Widget-Container schreibt.

## Im Projekt

| Ordner | Inhalt |
| --- | --- |
| `Status` | Menüleiste, Tafel, Einstellungen und Hinweise |
| `StatusWidgets` | Das macOS-Widget |
| `Shared` | Messung, Rechnung, Format und Texte |
| `StatusTests` | Rechnung, Format und eine echte Probe vom Rechner |
| `tools` | Die Zeichnung des Symbols |

Version 1.0. Kennung `com.muhsan.status`.
