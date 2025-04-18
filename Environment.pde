import java.util.Random;

// GLOBAL VARIABLES ====================================
boolean left, right, up, down;
boolean debugMode;
Random random = new Random();

PImage tree_img;
PImage blue_tank_img;
PImage red_tank_img;
PVector tree1_pos, tree2_pos, tree3_pos;
Tree tree0, tree1, tree2;
Team team;

Tree[] allTrees   = new Tree[3];
Tank[] allTanks   = new Tank[6];
ArrayList<Landmine> allMines = new ArrayList<Landmine>();

// Team0
PVector team0_tank0_startpos;
PVector team0_tank1_startpos;
PVector team0_tank2_startpos;
Tank tank0, tank1, tank2;

// Team1
PVector team1_tank0_startpos;
PVector team1_tank1_startpos;
PVector team1_tank2_startpos;
Tank tank3, tank4, tank5;

boolean gameOver;
boolean pause;
//Positions for obstacles
ArrayList<Sprite> placedPositions = new ArrayList<Sprite>();

//Landmine assets
enum DogState { ENTERING, RUNNING_TO_TARGET, LAUGHING, EXITING }
DogState dogState = DogState.ENTERING;

PImage landmineImg;
PImage[] runningFrames = new PImage[3];
PImage[] laughingFrames = new PImage[2];
Dog dog;
PVector newLandMinePos;
int landmineCounter = 0;
PVector dogExit;


// SETUP ============================================================================
void setup() {
  size(800, 800);
  up             = false;
  down           = false;
  debugMode      = false;
  
  gameOver       = false;
  pause          = true;
  
  //MINE STUFF
  landmineImg = loadImage("landmine.png");
  landmineImg.resize(50, 50);
  
  //LOADS IN THE FRAMES OF THE ANIMATIONS SINCE GIFS CANT BE USED
  for (int i = 0; i < runningFrames.length; i++) {
    PImage img = loadImage("dog_run_" + i + ".png");
    img.resize(50, 75);
    runningFrames[i] = img;
  }
  for (int i = 0; i < laughingFrames.length; i++) {
    PImage img = loadImage("dog_laugh_" + i + ".png");
    img.resize(50, 75);
    laughingFrames[i] = img;
  }
  //Instantiate dog with its frames
  dog = new Dog(runningFrames, laughingFrames);

  
  // Trees, randomly placed in the middle of the playing field
  tree_img = loadImage("tree01_v2.png");
  for (int i = 0; i < 3; i++) {
    PVector newTreePos;
    do {
      newTreePos = new PVector(random(250, 600), random(250, 600)); 
    } while (isOverlapping(newTreePos, placedPositions, 150));

    allTrees[i] = new Tree(tree_img, newTreePos.x, newTreePos.y);
    placedPositions.add(allTrees[i]);
    
  }

  //Team
  team = new Team();

  //Tank Images
  red_tank_img = loadImage("redtank.png");
  blue_tank_img = loadImage("bluetank.png");
  
  // Team0
  // Base Team 0(red)
  team0_tank0_startpos  = new PVector(50, 50);
  team0_tank1_startpos  = new PVector(50, 150);
  team0_tank2_startpos  = new PVector(50, 250);

  tank0 = new Tank("ally", team0_tank0_startpos, red_tank_img);
  tank1 = new Tank("ally", team0_tank1_startpos, red_tank_img);
  tank2 = new Tank("ally", team0_tank2_startpos, red_tank_img);

  allTanks[0] = tank0;                         // Symbol samma som index!
  allTanks[1] = tank1;
  allTanks[2] = tank2;
  
  placedPositions.add(tank0);
  placedPositions.add(tank1);
  placedPositions.add(tank2);
  
  // Team1 randomly placed in the lower right quadrant
  for (int i = 0; i < 3; i++) {
    PVector newTankPos;
    do {
      newTankPos = new PVector(random(450, 750), random(450, 750)); 
    } while (isOverlapping(newTankPos, placedPositions, 150)); 

    Tank newTank = new Tank("enemy", newTankPos, blue_tank_img);
    placedPositions.add(newTank);
    allTanks[3 + i] = newTank;
  }
}

// DRAW ==========================================================================================
void draw() {
  
  background(200);
  
  checkForInput();
  
  if (!gameOver && !pause) {
    updateTanksLogic();
    checkForCollisions();
    landmineCounter++;
    tank0.memory.display();
  }

  displayHomeBase();
  displayTrees();
  displayTanks();  
  displayGUI();
  

  if (landmineCounter == 1000) {
    deployLandmine();
    landmineCounter = 0; 
  }
  
  displayMines();
  dog.update();
  dog.display();
 
}

// HELPER METHODS ======================================

//Created helper fucntion to check if the generated pos is too close to a existing one
boolean isOverlapping(PVector newPos, ArrayList<Sprite> existingPositions, float minDistance) {
  for (Sprite obj : existingPositions) {
    if (newPos.dist(obj.position) < minDistance) {
      return true; 
    }
  }
  return false; 
}

// ===============================================
void deployLandmine() {
  PVector targetPos;
  do {
    targetPos = new PVector(random(100, 700), random(100, 700));
  } while (isOverlapping(targetPos, placedPositions, 100));

  dog.startRun(targetPos);
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
  for (Tank tank : allTanks) {
    tank.detectObject();
  }

  
}

// DISPLAY ======================================
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
  tank0.drawViewArea();
}

void displayMines(){
  for(Landmine mine : allMines){
    mine.display();
  }
}

void displayGUI() {
  if (pause) {
    textSize(36);
    fill(30);
    text("...Paused! (\'p\'-continues)\n(up/down/left/right to move)\n('d' for debug)", width/1.7-150, height/2.5);
  }
  
  if (gameOver) {
    textSize(36);
    fill(30);
    text("Game Over!", width/2-150, height/2);
  }  
}

// KEY PRESSED ======================================
void keyPressed() {
  //System.out.println("keyPressed!");

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
    
    if (key == 'd') {
      debugMode = !debugMode;
    }
}
