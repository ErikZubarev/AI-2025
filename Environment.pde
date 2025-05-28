//Anton Lundqvist
//Erik Zubarev

// =================================================
// ===  SETUP METHOD
// =================================================
// =============================================================================================
void setup() {
  size(800, 800);
  up               = false;
  down             = false;
  debugMode        = false;
  gameOver         = false;
  pause            = false;
  startGameTimer   = System.currentTimeMillis();
  startPauseTimer  = System.currentTimeMillis();
  currentGameTimer = 0L;
  totalPauseTime   = 0L;
  currentPauseTime = 0L;
  landmineCounter  = 0;

  random           = new Random();
  healthImages     = new PImage[4];
  runningFrames    = new PImage[3];
  laughingFrames   = new PImage[2];
  explosionImages  = new PImage[5];

  allMines         = new ArrayList<Landmine>();
  allCannonBalls   = new ArrayList<CannonBall>();
  allExplosions    = new ArrayList<Explosion>();

  placedPositions  = new ArrayList<Sprite>(); //Positions for every entitiy

  allTrees         = new Tree[3];
  allTanks         = new Tank[4];
  
  eventsRewards    = new HashMap<>();
  assignRewards();
  
  previousState    = null; //Reset between new epochs
  previousAction   = null;
  
  if(qLearner == null){
    //Assures that Q-learning element does not reset every epoch
    alpha            = 1.0;
    gamma            = 1.0;
    eps              = 1.0;
    qLearner         = new QLearner(alpha, gamma, eps);
  }

  dogState         = DogState.ENTERING;

  bomb = loadImage("bomb.png");

  for (int i = 0; i < healthImages.length; i++) {
    PImage img = loadImage("health"+i+".png");
    healthImages[i] = img;
  }

  for (int i = 0; i < explosionImages.length; i++) {
    PImage img = loadImage("explosion"+i+".png");
    explosionImages[i] = img;
  }

  //MINE STUFF
  landmineImg = loadImage("landmine.png");

  //LOADS IN THE FRAMES OF THE ANIMATIONS SINCE GIFS CANT BE USED
  for (int i = 0; i < runningFrames.length; i++) {
    PImage img = loadImage("dog_run_" + i + ".png");
    runningFrames[i] = img;
  }
  for (int i = 0; i < laughingFrames.length; i++) {
    PImage img = loadImage("dog_laugh_" + i + ".png");
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
  team0 = new Team(0, 0, color(204, 50, 50));
  team1 = new Team(width - 151, height - 351, color(0, 150, 200));

  //Tank Images
  red_tank_img = loadImage("redtank.png");
  blue_tank_img = loadImage("bluetank.png");

  // Team0
  // Base Team 0(red)
  team0_tank0_startpos  = new PVector(50, 50);
  team0_tank1_startpos  = new PVector(50, 150);
  team0_tank2_startpos  = new PVector(50, 250);

  QuadTreeMemory memory0         = new QuadTreeMemory(new Boundry(0, 0, 800, 800), 6);
  QuadTreeMemory memory1         = new QuadTreeMemory(new Boundry(0, 0, 800, 800), 6);

  //TEMP HIVE MIND
  tank0 = new Tank("ally", team0_tank0_startpos, red_tank_img, memory0);

  allTanks[0] = tank0;                         // Symbol samma som index!

  placedPositions.add(tank0);
  team0.members.add(tank0);
  tank0.team = team0;
  tank0.putBaseIntoMemory(team0.boundry);

  // Team1 randomly placed in the lower right quadrant
  for (int i = 0; i < 3; i++) {
    PVector newTankPos;
    do {
      newTankPos = new PVector(random(450, 750), random(450, 750));
    } while (isOverlapping(newTankPos, placedPositions, 150));

    Tank newTank = new Tank("enemy", newTankPos, blue_tank_img, memory1);
    placedPositions.add(newTank);
    allTanks[1 + i] = newTank;
    team1.members.add(newTank);
    newTank.putBaseIntoMemory(team1.boundry);
  }
}


// =================================================
// ===  DRAW METHOD
// =================================================
// ==========================================================================================
void draw() {

  boolean allDead = true;
  for (Tank enemy : team1.members) {
    if (enemy.health > 0) {
      allDead = false;
      break;
    }
  }
  if (allDead) {
    gameOver = true;
    gameWon = true;
    checkRewards(); //Updates gameover rewards
    setup();
  }

  background(200);

  checkForInput();

  checkRewards();
    
  displayHomeBase();
  displayTrees();
  displayTanks();


  if (landmineCounter == 1000) {
    deployLandmine();
    landmineCounter = 0;
  }
  displayMines();
  dog.update();
  dog.display();

  if (!gameOver && !pause) {
    currentGameTimer = (System.currentTimeMillis() - startGameTimer - totalPauseTime) / 1000;
    displayExplosions();
    checkForCollisions();
    updateTanksLogic();
    displayCannonBalls();
    updateCannonBalls();
    checkLandMineCollision();
    landmineCounter++;
    if (debugMode) {
      tank0.memory.display();
    }

    currentPauseTime = totalPauseTime; // Save prev pause time
  } else if (pause) {
    totalPauseTime = currentPauseTime + System.currentTimeMillis() - startPauseTimer; // Update current prev pause + current pause time
  }

  displayGUI();
}

// ================================================================================================== TWEAK REWARDS HERE
void assignRewards(){
  eventsRewards.put("Game Over",-100);
  eventsRewards.put("Win",+100);
  eventsRewards.put("Enemy Hit",+5);
  eventsRewards.put("Enemy Destroyed",+10);
  eventsRewards.put("Agent Damage",-5);
  eventsRewards.put("Time",-1);
}

// ================================================================================================== TWEAK Q-LEARNING HERE
void checkRewards(){
  //TODO
  //Checks whether the agent triggered an event (e.g., fired a shot, stepped on a landmine).
  //Check gameOver and assign
  //Update previousState and previousAction
  //Update said event by using the rewards table above
  //updateQ()
}


// HELPER METHODS ======================================

//Created helper fucntion to check if the generated pos is too close to a existing one
// ==================================================================================================
boolean isOverlapping(PVector newPos, ArrayList<Sprite> existingPositions, float minDistance) {
  for (Sprite obj : existingPositions) {
    if (newPos.dist(obj.position) < minDistance) {
      return true;
    }
  }
  return false;
}

// ==================================================================================================
void deployLandmine() {
  PVector targetPos;
  do {
    targetPos = new PVector(random(100, 700), random(100, 700));
  } while (isOverlapping(targetPos, placedPositions, 100));

  dog.startRun(targetPos);
}

// ==================================================================================================
void addCannonBall(CannonBall cannonBall) {
  allCannonBalls.add(cannonBall);
}

// ==================================================================================================
void updateCannonBalls() {
  for (int i = allCannonBalls.size() - 1; i >= 0; i--) {
    CannonBall cannonBall = allCannonBalls.get(i);
    cannonBall.moveForward();
    if (checkCollision(cannonBall)) {
      allCannonBalls.remove(i);
    }
  }
}


// ==================================================================================================
boolean checkCollision(CannonBall cannonBall) {
  for (Sprite obj : placedPositions) {
    if (obj instanceof Tree) {
      if (cannonBall.boundry.intersects(obj.boundry)) {
        println("Tree hit!");
        cannonBall.drawExplosion();
        return true;
      }
    }

    if (obj instanceof Tank) {
      Tank tank = (Tank) obj;
      if (cannonBall.boundry.intersects(tank.boundry) && cannonBall.shooter != tank) {
        println("Tank hit!");
        tank.reduceHealth();
        cannonBall.drawExplosion();
        return true;
      }
    }
  }
  return false;
}

// ==================================================================================================
void checkLandMineCollision() {
  Iterator<Landmine> mineIterator = allMines.iterator();
  while (mineIterator.hasNext()) {
    Landmine landmine = mineIterator.next();
    for (Tank tank : allTanks) {
      if (tank != null && landmine.boundry.intersects(tank.boundry)) {
        // Remove the landmine safely using the iterator
        mineIterator.remove();
        placedPositions.remove(landmine);
        landmine.displayExplosion();
        tank.reduceHealth();
        println("Landmine removed!");
        break; // Exit the inner loop since the landmine is already removed
      }
    }
  }
}


// ==================================================================================================
void updateTanksLogic() {
  for (Tank tank : allTanks) {
    tank.update();
  }
}

// ==================================================================================================
void checkForCollisions() {
  for (Tank tank : allTanks) {
    if (team0.members.contains(tank)) {
      tank.detectObject();
    }
  }
}

// ==================================================================================================
void keyPressed() {
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

// ==================================================================================================
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
      break;
    case DOWN:
      down = false;
      break;
    }
  }

  if (key == 'p') {
    startPauseTimer = System.currentTimeMillis();
    pause = !pause;
  }

  if (key == 'd') {
    debugMode = !debugMode;
  }

  if (key == 's') {
    tank0.action("fire");
  }

}

// PLAYER TANK INPUTS =================================================================================
void checkForInput() {
  if (pause || gameOver)
    return;

  if (up) {
    tank0.state = 1; // moveForward
  } else if (down) {
    tank0.state = 2; // moveBackward
  } else tank0.state = 0;

  if (right) {
    tank0.action("rotateRight"); // Rotate right
  } else if (left) {
    tank0.action("rotateLeft"); // Rotate left
  }
}

// ==================================================================================================
void mousePressed() {
  println("---------------------------------------------------------");
  println("*** mousePressed() - Musknappen har tryckts ned.");

  mouse_pressed = true;

  PVector mousePos = new PVector(mouseX, mouseY);
  deployLandmine(mousePos);
}


void deployLandmine(PVector targetPos) {
  dog.startRun(targetPos);
}
