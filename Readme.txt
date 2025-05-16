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
   - När du klickar på 'p' så startar simuleringen. Stridsvagnarna kör autonomt och inga användarinput förväntas eller utförs.
   - Tryck på `p` för att pausa/återuppta simuleringen.
   - Tryck på `d` för att aktivera/deaktivera debug-läge.

3. Testa landminor  
   - Vänta tills hunden placerar en landmina automatiskt.
   - Alternativt, klicka med musen för att manuellt placera en landmina på musens position.

4. Byt mellan Synbaserad och Radiobaserad samarbetsmetod.
    - För att prova de två olika implementationerna så behövs endast boolean variabeln radioComs i Team.pde (rad 9) bytas. 
    - Om radioComs = true så används Radiobaserad. Om radioComs = false används synbaserad.

5. Debug-läge  
   - Aktivera debug-läge (`d`) för att se gränser, utforskade områden och QuadTree-strukturen.

---

## Struktur

### Filstruktur
- `Environment.pde`: Huvudfil som hanterar spelvärlden och logiken.
- `ENV_display.pde`: Display metoder som fanns i Environment.pde har flyttats ut hit.
- `ENV_variables.pde`: Samltiga Global variabler som fanns i Environment.pde har flyttas hits.
- `Tank.pde`: Hanterar tankarnas beteende och rörelse.
- `Tree.pde`: Representerar träd som hinder.
- `Landmine.pde`: Hanterar landminor.
- `Dog.pde`: Hanterar hundens rörelse och placering av landminor.
- `Search.pde': Har både GBFS och BFS algoritmen som nyttjas för pathfinding. Endast GBFS har nyttjats under testning men om BFS skulle vela prövas är det bara att bytta return i Search.pde (rad 34&35)
- `QuadTreeMemory.pde`: Hanterar minne och utforskade områden.
- `Boundry.pde`: Hanterar gränser och kollisioner.
- `CannonBall.pde`: Representerar stridsvagenens projektiler.
- 'Explosion.pde`: Hjälpklass för att förenkla visualisering av explosions skapade av kannonkulor och landminor.
- `Target.pde`: Hjälpklass för stridsvagnarnas planering av sökvägen. Agerar som ett hinder så andra vagnar inte kan planera sin väg där.

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