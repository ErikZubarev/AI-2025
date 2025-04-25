# AI Tank Simulation

## Funktioner
- Tankar: Navigerar och undviker hinder.
- Landminor: Slumpmässigt placerade av en hund som rör sig i spelvärlden.
- Träd: Statisk miljö som fungerar som hinder.
- Pathfinding: Implementering av GBFS och BFS för att beräkna vägar.
- QuadTreeMemory: Hanterar minne och utforskade områden i spelvärlden.

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
   Klicka på "Play"-knappen (p) i Processing IDE för att köra programmet.
   OBS tillse att inte ha caps-lock igång då det ger en annan ascii kod som programmet inte reagerar på.

2. Interagera med simuleringen  
   - Använd piltangenterna för att styra den röda tanken:
     - Upp: Framåt
     - Ner: Bakåt
     - Vänster: Rotera vänster
     - Höger: Rotera höger
   - Tryck på `p` för att pausa/återuppta simuleringen.
   - Tryck på `d` för att aktivera/deaktivera debug-läge.

3. Testa landminor  
   - Vänta tills hunden placerar en landmina automatiskt.
   - Alternativt, klicka med musen för att manuellt placera en landmina på musens position.

4. Byt mellan GBFS och BFS algoritmen.
    - Från början används BFS. Om du vill bytta till GBFS så gå till Tank.pde filen och kommentera ut rad 16 och av-kommentera rad 15 som skapar objekt av algoritmerna.
    Samt att kommentera ut rad 74 och av-kommentera rad 73

5. Debug-läge  
   - Aktivera debug-läge (`d`) för att se gränser, utforskade områden och QuadTree-strukturen.

---

## Struktur

### Filstruktur
- `Environment.pde`: Huvudfil som hanterar spelvärlden och logiken.
- `Tank.pde`: Hanterar tankarnas beteende och rörelse.
- `Tree.pde`: Representerar träd som hinder.
- `Landmine.pde`: Hanterar landminor.
- `Dog.pde`: Hanterar hundens rörelse och placering av landminor.
- `GBFS.pde`: Implementering av Greedy Best-First Search.
- `BFS.pde`: Implementering av Breadth-First Search.
- `QuadTreeMemory.pde`: Hanterar minne och utforskade områden.
- `Boundry.pde`: Hanterar gränser och kollisioner.

---

### Debugging
- Använd debug-läget (`d`) för att visualisera gränser och utforskade områden.
- Lägg till `println`-utskrifter i koden för att spåra variabler och flöden.

---

## Författare
- Anton Lundqvist
- Erik Zubarev
- Gr04
---