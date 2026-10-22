# DRIFT 0.3.1 — Balancing-Bericht

Godot 4.7.stable.official.5b4e0cb0f, 60 Hz, 2026-10-22. Basis: bf98faf. Dies sind reale Headless-Physikläufe mit Sensorik, Schub, Kollisionsereignissen und endlicher Munition, keine interaktiven Spieltests. Zwei Seeds pro Modus/Schwierigkeit sind eine kleine reproduzierbare Stichprobe, keine statistisch belastbare allgemeine Winrate.

## Warum 0.3 ohne Spieler gewann

Vor Änderungen wurden sechs Gefechte mit der alten Implementierung ausgeführt ([Messdaten](balance-0.3-baseline.json)). Zwei FULL-AUTO-Startlagen endeten identisch nach 43,85 s mit Sieg, drei eigenen Schiffstreffern und zwei gegnerischen, tatsächlich abgefangenen Raketen; DRIFT blieb unbeschädigt. ALPHA hatte keine eigene Abwehr, schoss erst bei 14 s und danach alle 18 s; DRIFT begann bei 12 s und schoss alle 14 s. Eine vorhandene Verfolgung genügte sofort zur Feuerfreigabe. Die eigene Drohne startete automatisch und fing sämtliche gestarteten Angriffe dieser beiden Läufe ab. Ohne Drohne gab es einen Sieg/eine Niederlage, ohne eigene Waffen/Drohne zwei Niederlagen nach etwa 54,5 s.

Damit war der Standard selbst eine siegreiche Strategie. Ein bloßes neues Statuslabel hätte das Problem nicht gelöst. 0.3.1 stellt den Standard auf MANUAL, verlangt Startbefehle und einen aufgebauten Lock, führt unabhängige Racks und gegnerische Abwehr ein und validiert automatische Befehlsgewalt direkt am Aktuator. Die gemeinsame Abwehrfeuerlösung berücksichtigt nun Eigenbewegung, aus Beobachtungen geschätzte Beschleunigung und bekannte Übermittlungslatenz; sie liest keine perfekte Zielgeschwindigkeit.

## Reproduktion und Versuchsaufbau

```sh
GODOT_BIN=/workspace/tools/godot-4.7/Godot_v4.7-stable_linux.x86_64 ./tools/check.sh
# Gesamte Matrix, schreibt docs/balance-0.3.1.json:
godot --headless --fixed-fps 60 --path . --script res://tests/balance_report.gd
```

Die erste Zeile verwendet die in dieser Umgebung vorhandene 4.7-Binärdatei; bei der zweiten muss `godot` ebenfalls 4.7 sein. `tests/balance_scenario.gd` enthält die vollständigen Abläufe. Für die alte Baseline kann `tests/legacy_balance.gd` mit einem separaten bf98faf-Checkout als Godot-Projektpfad ausgeführt werden; der Fixture verweigert die neue Projektversion. Alte Variante 1 verändert ausschließlich die anfängliche Gegnerposition um `(40,10,-120) m`; es gibt keine Positionskorrektur während des Gefechts.

- MANUAL/idle: keinerlei Spielerbefehle, keine Rollenfreigabe.
- ASSISTED/granted-guard: Waffenrolle ausdrücklich freigegeben; der Skriptoperator startet bei 3 s eine Drohne und erteilt bei 3,2 s DEFEND am vorderen Standardwegpunkt. Das ist ausdrücklich **kein** Lauf ohne Spieleraufträge.
- FULL AUTO/idle: expliziter Demonstrationsmodus; keine Bedienaufträge nötig.
- Seeds 1741 und 71 verändern die anfängliche gegnerische Ausweichphase. Gesundheit, Raketenmasse/-schub, Schaden und Bestände der Schiffsracks sind gleich.
- Zeithorizont 120 s. ACTIVE bedeutet ein noch laufendes Gefecht/Patt, keine erzwungene Entscheidung. Treffer zählen nur die gegnerischen **Schiffsrümpfe**, nicht Asteroiden oder Drohnen. Bei Gefechtsende können weitere Flugkörper noch unterwegs sein: Treffer/Starts sind keine unverzerrte Trefferwahrscheinlichkeits-Schätzung.

## Matrix: je zwei Gefechte pro Modus und Schwierigkeit

| Modus | Schwierigkeit | Seed | Ergebnis / Zeit s | Eigene Treffer/Starts | Feindtreffer/Starts | Abfang DRIFT/ALPHA | DRIFT Rumpf |
|---|---|---:|---|---:|---:|---:|---:|
| MANUAL | EASY | 1741 | DEFEAT / 53.95 | 0/0 | 3/3 | 0/0 | 0 |
| MANUAL | EASY | 71 | DEFEAT / 54.03 | 0/0 | 3/3 | 0/0 | 0 |
| MANUAL | NORMAL | 1741 | DEFEAT / 41.43 | 0/0 | 3/3 | 0/0 | 0 |
| MANUAL | NORMAL | 71 | DEFEAT / 41.43 | 0/0 | 3/3 | 0/0 | 0 |
| MANUAL | HARD | 1741 | DEFEAT / 42.55 | 0/0 | 3/4 | 0/0 | 0 |
| MANUAL | HARD | 71 | DEFEAT / 42.62 | 0/0 | 3/4 | 0/0 | 0 |
| ASSISTED SOLO | EASY | 1741 | VICTORY / 43.90 | 3/3 | 1/2 | 1/0 | 66 |
| ASSISTED SOLO | EASY | 71 | VICTORY / 43.78 | 3/3 | 0/2 | 2/0 | 100 |
| ASSISTED SOLO | NORMAL | 1741 | VICTORY / 85.83 | 3/6 | 0/6 | 6/3 | 100 |
| ASSISTED SOLO | NORMAL | 71 | VICTORY / 85.73 | 3/6 | 1/6 | 5/2 | 66 |
| ASSISTED SOLO | HARD | 1741 | VICTORY / 113.98 | 3/8 | 1/8 | 7/5 | 66 |
| ASSISTED SOLO | HARD | 71 | ACTIVE / 120.00 | 2/8 | 0/8 | 8/5 | 100 |
| FULL AUTO / DEMO | EASY | 1741 | VICTORY / 43.90 | 3/3 | 0/2 | 2/0 | 100 |
| FULL AUTO / DEMO | EASY | 71 | VICTORY / 43.78 | 3/3 | 0/2 | 2/0 | 100 |
| FULL AUTO / DEMO | NORMAL | 1741 | VICTORY / 85.83 | 3/6 | 0/6 | 6/3 | 100 |
| FULL AUTO / DEMO | NORMAL | 71 | VICTORY / 85.73 | 3/6 | 0/6 | 6/2 | 100 |
| FULL AUTO / DEMO | HARD | 1741 | VICTORY / 113.98 | 3/8 | 0/8 | 8/5 | 100 |
| FULL AUTO / DEMO | HARD | 71 | ACTIVE / 120.00 | 1/5 | 1/8 | 7/2 | 66 |

## Vergleich bewusster Entscheidungen auf NORMAL

Die folgenden acht Läufe verwenden zusätzlich explizite Modellbefehle eines Skriptoperators. Sie simulieren weder menschliche Gehzeiten noch echtes Controllergefühl. Es wird kein Treffer/Schaden/Ergebnis injiziert und keine physikalische Geschwindigkeit direkt geändert.

Das Annäherungsprofil fordert 0–4 s normalen Vorwärts-RCS an, lässt anschließend treiben und bremst 10–13⅓ s mit Rückwärts-RCS. Dadurch wird die Distanz physikalisch verkürzt. Ab etwa 4 s, danach alle 8 s, befiehlt der Operator zwei **einzelne** Starts mit Rackwechsel und 0,2 s Abstand. Jeder Start benötigt eine gültige Lösung und verbraucht eine Rakete. Guard verwendet DEFEND bei `(-60,20,-80) m`; bad-position verwendet bei identischer Angriffsfolge den hinteren Punkt `(0,-30,900) m`; no-drone startet keine Drohne.

Lateral verwendet stattdessen kontinuierlichen seitlichen RCS und **keine Drohne**. Die Beschleunigung führt zu großer seitlicher Geschwindigkeit und verändert sowohl eigene als auch feindliche Sensor-/Abfanggeometrie; ein Entkommen ist kein automatisch gewonnener Kampf.

| Plan | Seed | Ergebnis / Zeit s | Eigene Treffer/Starts | Feindtreffer/Starts | Eigene Abfänge | DRIFT Rumpf |
|---|---:|---|---:|---:|---:|---:|
| no-drone | 1741 | VICTORY / 24.27 | 3/6 | 1/2 | 0 | 66 |
| no-drone | 71 | VICTORY / 24.15 | 3/6 | 1/2 | 0 | 66 |
| guard | 1741 | VICTORY / 24.27 | 3/6 | 0/2 | 1 | 100 |
| guard | 71 | VICTORY / 24.15 | 3/6 | 0/2 | 1 | 100 |
| bad-position | 1741 | VICTORY / 24.27 | 3/6 | 1/2 | 0 | 66 |
| bad-position | 71 | VICTORY / 24.15 | 3/6 | 1/2 | 0 | 66 |
| lateral | 1741 | ACTIVE / 120.00 | 0/6 | 0/1 | 0 | 100 |
| lateral | 71 | ACTIVE / 120.00 | 0/6 | 0/1 | 0 | 100 |

Die untätigen MANUAL-Läufe verlieren auf NORMAL nach 41,43 s mit null eigenen Starts und unbeschädigtem ALPHA. Das aktive Annäherungs-/Rackprofil gewinnt in beiden Seeds nach 24,15–24,27 s. Mit vorgeschobener DEFEND-Drohne bleiben 100 % Rumpf; ohne Drohne oder bei schlechter hinterer Position bleiben nur 66 %. Die gleiche Angriffsfolge isoliert hier den Effekt der Verteidigungsposition. Kontinuierlicher Seitenschub ohne Abwehr reduziert die tatsächlich einschlagenden gegnerischen Raketen von drei auf null, verliert aber auch die eigene wirksame Feuerposition; beide Schiffe bleiben im 120-s-Horizont intakt.

FULL AUTO bleibt leistungsfähig, ist aber kein Standard und keine Spielbarkeitsbehauptung: NORMAL benötigt hier sechs eigene Starts und etwa 85,8 s statt zuvor drei Starts/43,85 s. HARD führt auch zu laufenden Gefechten nach 120 s; gegnerische Abwehr und Manöver verbrauchen reale Munition und ändern den Verlauf. Die Drohne ist weiterhin stark, wenn sie rechtzeitig und passend positioniert wird. Ihre idealisierte Richtmechanik und die kleine Stichprobe begrenzen jede weitergehende Aussage zur Schwierigkeitsbalance. Als Nächstes folgen menschliche Desktop-/Controller-Abnahme, endliche Turmschwenkung, Sensor-Sichtlinien und mehr Startgeometrien. Kein Health-Buff, künstlicher Trefferbonus oder garantierter Gewinner wurde eingeführt.
