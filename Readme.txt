# AI Tank Simulation

## Funktioner
- Tankar: Navigerar och undviker hinder.
- Träd: Statisk miljö som fungerar som hinder.

---

## Förutsättningar

### Systemkrav
- Operativsystem: Windows, macOS eller Linux.
- Java: Java Development Kit (JDK) version 8 eller senare.
- Processing IDE: Version 3.5.4 eller senare.

### Bibliotek
Inga externa bibliotek krävs utöver de som medföljer Processing.

---

## Installation

1. Kopiera projektet  
   Kopiera hela projektmappen (`AI`) till din dator.

2. Öppna projektet  
   Öppna `Environment.pde` i Processing IDE. Detta är huvudfilen som startar simuleringen.

---

## Testning

### Steg-för-steg-guide för att testa systemet

1. Starta simuleringen 

2. Interagera med simuleringen  
   - tryck på `w` för att spara agents qtable samt agentens statistik, om epsilon är under 0.1, till fil.
   - Tryck på `d` för att aktivera/deaktivera debug-läge. Debug läget visar en heatmap på agentens Q-table.
   ERIK SKREV MER OM HEATMAP HÄR********************************************************************************************

3. Debug-läge  
   - Aktivera debug-läge (`d`) för att se gränser, utforskade områden och QuadTree-strukturen.

---

## Struktur

### Filstruktur
- `Environment.pde`: Huvudfil som hanterar spelvärlden och logiken.
- `ENV_display.pde`: Display metoder som fanns i Environment.pde har flyttats ut hit.
- `ENV_variables.pde`: Samltiga Global variabler som fanns i Environment.pde har flyttas hits.
- `Tank.pde`: Hanterar tankarnas beteende och rörelse.
- `Tree.pde`: Representerar träd som hinder.
- `Boundry.pde`: Hanterar gränser och kollisioner.
- `CannonBall.pde`: Representerar stridsvagenens projektiler.
- 'Explosion.pde`: Hjälpklass för att förenkla visualisering av explosions skapade av kannonkulor och landminor.
- 'QLearner.pde`: Huvudklass för RL-logiken. Nyttjar en Q-learning struktur med epsilon-greedy exploration som tar in state, action, reward, new state för att lära sig.
- 'Heatmap.pde`: Hjälpklass för att förenkla visualisering av agentens lärande.

---

### Debugging
- Använd debug-läget (`d`) för att visualisera gränser och se en heatmap på agentens lärande.
- Lägg till `println`-utskrifter i koden för att spåra variabler och flöden.

---

## Författare
- Anton Lundqvist
- Erik Zubarev
- Gr04
---