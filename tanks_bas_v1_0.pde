// Följande kan användas som bas inför uppgiften.
// Syftet är att sammanställa alla varabelvärden i scenariet.
// Variabelnamn har satts för att försöka överensstämma med exempelkoden.
// Klassen Tank är minimal och skickas mer med som koncept(anrop/states/vektorer).
// Testar att göra en ändring och pusha det till github
import java.util.Random;

boolean left, right, up, down;
boolean mouse_pressed;
Random random = new Random();

PImage tree_img;
PImage blue_tank_img;
PImage red_tank_img;
PVector tree1_pos, tree2_pos, tree3_pos;
Tree tree0, tree1, tree2;
Team team;

Tree[] allTrees   = new Tree[3];
Tank[] allTanks   = new Tank[6];

// Team0
color team0Color;
PVector team0_tank0_startpos;
PVector team0_tank1_startpos;
PVector team0_tank2_startpos;
Tank tank0, tank1, tank2;

// Team1
color team1Color;
PVector team1_tank0_startpos;
PVector team1_tank1_startpos;
PVector team1_tank2_startpos;
Tank tank3, tank4, tank5;

int tank_size;

boolean gameOver;
boolean pause;

//======================================
void setup() 
{
  size(800, 800);
  up             = false;
  down           = false;
  mouse_pressed  = false;
  
  gameOver       = false;
  pause          = true;

  
  
  // Trad
  tree_img = loadImage("tree01_v2.png");
  //Changed the tree's positions to be semi-randomly in the middle, som overlapp might happen but eh
  ArrayList<PVector> treePositions = new ArrayList<PVector>();

  for (int i = 0; i < 3; i++) {
    PVector newTreePos;
    do {
      newTreePos = new PVector(random(250, 600), random(250, 600)); // Trees in the middle
    } while (isOverlapping(newTreePos, treePositions, 100)); // Ensure no overlap

    treePositions.add(newTreePos);
    allTrees[i] = new Tree(tree_img, newTreePos.x, newTreePos.y);
  }
  
  tank_size = 50;
  
  // Team0
  team0Color  = color(204, 50, 50);             // Base Team 0(red)
  team0_tank0_startpos  = new PVector(50, 50);
  team0_tank1_startpos  = new PVector(50, 150);
  team0_tank2_startpos  = new PVector(50, 250);
  
  
  ArrayList<PVector> tankPositions = new ArrayList<PVector>();

  for (int i = 0; i < 3; i++) {
    PVector newTankPos;
    do {
      newTankPos = new PVector(random(450, 750), random(450, 750)); // Lower-right area
    } while (isOverlapping(newTankPos, tankPositions, 100)); // Ensure no overlap

    tankPositions.add(newTankPos);
  }


  //Teams
  team = new Team(team0Color, team1Color);
  
  //tank0_startpos = new PVector(50, 50);
  red_tank_img = loadImage("redtank.png");
  tank0 = new Tank("tank0", team0_tank0_startpos, red_tank_img);
  tank1 = new Tank("tank1", team0_tank1_startpos, red_tank_img );
  tank2 = new Tank("tank2", team0_tank2_startpos, red_tank_img );
  
  blue_tank_img = loadImage("bluetank.png");
    // Assign to blue tanks
  tank3 = new Tank("tank3", tankPositions.get(0), blue_tank_img);
  tank4 = new Tank("tank4", tankPositions.get(1), blue_tank_img);
  tank5 = new Tank("tank5", tankPositions.get(2), blue_tank_img);

  
  allTanks[0] = tank0;                         // Symbol samma som index!
  allTanks[1] = tank1;
  allTanks[2] = tank2;
  allTanks[3] = tank3;
  allTanks[4] = tank4;
  allTanks[5] = tank5;
}

boolean isOverlapping(PVector newPos, ArrayList<PVector> existingPositions, float minDistance) {
  for (PVector pos : existingPositions) {
    if (newPos.dist(pos) < minDistance) {
      return true; // Too close, overlap detected
    }
  }
  return false; // No overlap, position is valid
}

void draw()
{
  background(200);
  checkForInput(); // Kontrollera inmatning.
  
  if (!gameOver && !pause) {
    
    // UPDATE LOGIC
    updateTanksLogic();
    
    // CHECK FOR COLLISIONS
    checkForCollisions();
  
  }
  
  // UPDATE DISPLAY 
  displayHomeBase();
  displayTrees();
  displayTanks();  
  
  displayGUI();
}

//======================================
void checkForInput() {
    if (up) {
        if (!pause && !gameOver) {
            tank0.state = 1; // moveForward
        }
    } else if (down) {
        if (!pause && !gameOver) {
            tank0.state = 2; // moveBackward
        }
    }

    if (right) {
        if (!pause && !gameOver) {
            tank0.action("rotateRight"); // Rotate right
        }
    } else if (left) {
        if (!pause && !gameOver) {
            tank0.action("rotateLeft"); // Rotate left
        }
    }

    if (!up && !down) {
        tank0.state = 0;
    }
}

//======================================
void updateTanksLogic() {
  for (Tank tank : allTanks) {
    tank.update();
  }
}

void checkForCollisions() {
  //println("*** checkForCollisions()");
  for (Tank tank : allTanks) {
    tank.checkForCollisions(tank1);
    tank.checkForCollisions(new PVector(width, height));
  }
}

//======================================
void displayHomeBase() {
  team.display();
}
  

void displayTrees() {
  for (Tree tree : allTrees) {
    tree.display();
  }
}

void displayTanks() {
  for (Tank tank : allTanks) {
    tank.display();
  }
}

void displayGUI() {
  if (pause) {
    textSize(36);
    fill(30);
    text("...Paused! (\'p\'-continues)\n(upp/ner-change velocity)", width/1.7-150, height/2.5);
  }
  
  if (gameOver) {
    textSize(36);
    fill(30);
    text("Game Over!", width/2-150, height/2);
  }  
}

//======================================
void keyPressed() {
  System.out.println("keyPressed!");

    if (key == CODED) {
      switch(keyCode) {
      case LEFT:
        left = true;
        break;
      case RIGHT:
        right = true;
        break;
      case UP:
        up = true;
        break;
      case DOWN:
        down = true;
        break;
      }
    }

}

void keyReleased() {
  System.out.println("keyReleased!");
    if (key == CODED) {
      switch(keyCode) {
      case LEFT:
        left = false;
        break;
      case RIGHT:
        right = false;
        break;
      case UP:
        up = false;
        //tank0.stopMoving();
        break;
      case DOWN:
        down = false;
        //tank0.stopMoving();
        break;
      }
      
    }
    
    if (key == 'p') {
      pause = !pause;
    }
}

// Mousebuttons
void mousePressed() {
  println("---------------------------------------------------------");
  println("*** mousePressed() - Musknappen har tryckts ned.");
  
  mouse_pressed = true;
  
}
