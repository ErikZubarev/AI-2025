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
  previousTime     = 0L;

  random           = new Random();
  healthImages     = new PImage[4];
  explosionImages  = new PImage[5];

  allCannonBalls   = new ArrayList<CannonBall>();
  allExplosions    = new ArrayList<Explosion>();

  placedPositions  = new ArrayList<Sprite>(); //Positions for every entitiy

  allTrees         = new Tree[3];
  allTanks         = new Tank[4];

  eventsRewards    = new HashMap<>();
  stuckCounter     = 0;
  assignRewards();


  if (qLearner == null) {
    alpha            = 0.2;
    gamma            = 0.95;
    eps              = 1.0; // Initial epsilon is high for exploration
    qLearner         = new QLearner(alpha, gamma, eps);
  } else {
    float decayStep = 0.05; //Gradual epislon decay
    float min_epsilon = 0.01;
    qLearner.epsilon = max(min_epsilon, qLearner.epsilon - decayStep);
    qLearner.learningRate = max(0, qLearner.learningRate - 0.005  );
    if (qLearner.epsilon < 0.1 && statsEpochCounter == -1) { //If we have reached epsilon < 0.1 we start gathering stats for report
      println("Starting stat gathering");
      statsEpochCounter = 0;
    }
    println(qLearner.epsilon + " - " + qLearner.learningRate);
  }

  bomb = loadImage("bomb.png");

  for (int i = 0; i < healthImages.length; i++) {
    PImage img = loadImage("health"+i+".png");
    healthImages[i] = img;
  }

  for (int i = 0; i < explosionImages.length; i++) {
    PImage img = loadImage("explosion"+i+".png");
    explosionImages[i] = img;
  }

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



  // Team1 randomly placed in the lower right quadrant
  for (int i = 0; i < 3; i++) {
    PVector newTankPos;
    do {
      newTankPos = new PVector(random(450, 750), random(450, 750));
    } while (isOverlapping(newTankPos, placedPositions, 150));

    Tank newTank = new Tank("enemy", newTankPos, blue_tank_img);
    placedPositions.add(newTank);
    allTanks[i] = newTank;
    team1.members.add(newTank);
  }

  // Team0
  // Base Team 0(red)
  team0_tank0_startpos  = new PVector(50, 50);

  tank0 = new Tank("ally", team0_tank0_startpos, red_tank_img);

  allTanks[3] = tank0;                         

  placedPositions.add(tank0);
  team0.members.add(tank0);
  tank0.team = team0;

  previousState    = tank0.getCurrentState(); //Reset between new epochs
  previousAction   = "stop";
  qHeatmap = new Heatmap(qLearner.qTable.size(), qLearner.actions.length);
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
    if (statsEpochCounter >= 0) {
      stats.put(statsEpochCounter++, "3 killed in " + currentGameTimer  + " seconds");
    }
    setup();
  }

  background(200);




  displayHomeBase();
  displayTrees();
  displayTanks();

  if (!gameOver && !pause) {
    currentGameTimer = (System.currentTimeMillis() - startGameTimer - totalPauseTime) / 1000;
    displayExplosions();
    displayCannonBalls();
    updateCannonBalls();

    Tank.State newState = tank0.getCurrentState();
    String newAction = qLearner.chooseAction(newState);
    previousPosition = tank0.position;
    tank0.action(newAction);
    updateTanksLogic();
    previousState = newState;
    previousAction = newAction;
    checkRewards();

    currentPauseTime = totalPauseTime; // Save prev pause time
  } else if (pause) {
    totalPauseTime = currentPauseTime + System.currentTimeMillis() - startPauseTimer; // Update current prev pause + current pause time
  }

  displayGUI();
  //keybind for saving qTable and stats to file
  if (keyPressed && key == 'w') {
    saveQTableToFile();
    saveStatsToFile();
  }
  
  if (debugMode) {
    qHeatmap.updateHeatmap(qLearner.qTable);  // Update the Q-values
    qHeatmap.display();  // Draw the heatmap
  }
}

//Helper method for saving the Qtable hashmap to file
void saveQTableToFile() {
  String[] lines = new String[qLearner.qTable.size()];
  int idx = 0;
  for (Object state : qLearner.qTable.keySet()) {
    HashMap<String, Float> actions = qLearner.qTable.get(state);
    StringBuilder sb = new StringBuilder();
    sb.append(state.toString()).append(": ");
    for (String action : actions.keySet()) {
      sb.append(action).append("=").append(actions.get(action)).append(" ");
    }
    lines[idx++] = sb.toString().trim();
  }
  saveStrings("qtable.txt", lines);
}

//Helper method for saving stats for report
void saveStatsToFile() {
  println("This is stats" + stats.toString());
  String[] lines = new String[stats.size()];
  int idx = 0;
  for (Object key : stats.keySet()) {
    lines[idx++] = key + ": " + stats.get(key);
  }
  saveStrings("stats.txt", lines);
}



// ================================================================================================== TWEAK REWARDS HERE
void assignRewards() {
  eventsRewards.put("Lost", -1.0);
  eventsRewards.put("Win", 1.0);   
  eventsRewards.put("Enemy Hit", 0.5); 
  eventsRewards.put("Enemy Destroyed", 0.7);
  eventsRewards.put("Time", -0.1); 
  eventsRewards.put("See Enemy", 0.05);  
  eventsRewards.put("Facing Wall Move", -0.2);
  eventsRewards.put("Good Fire Attempt", 0.2);  
  eventsRewards.put("Approach Enemy", 0.2);  
  eventsRewards.put("Escaped Wall", 0.1);
  eventsRewards.put("Stand Still For No Reason", -0.2);
  eventsRewards.put("Good Movevemnt", 0.02);
  eventsRewards.put("Moved Away From Enemy", -0.25);
}

// ================================================================================================== TWEAK Q-LEARNING HERE
void checkRewards() {
  float totalStepReward = 0;
  boolean gameActuallyEndedThisStep = false;
  Tank.State ps = previousState instanceof Tank.State? (Tank.State) previousState : null;
  Tank.State currentState = tank0.getCurrentState();

  //Enemy damage rewards
  if (!gameActuallyEndedThisStep && ps != null && previousAction != null && previousAction.equals("fire") && ps.enemyInLOS && !enemyHit) {
    totalStepReward += eventsRewards.get("Good Fire Attempt");
  }
  if (enemyHit) {
    totalStepReward += eventsRewards.get("Enemy Hit");
    enemyHit = false; // Reset flag
  }
  if (enemyDead) {
    totalStepReward += eventsRewards.get("Enemy Destroyed");
    enemyDead = false; // Reset flag
  }

  //Game Over rewards
  if (gameOver) {
    totalStepReward += gameWon ? eventsRewards.get("Win") : eventsRewards.get("Lost");
    gameActuallyEndedThisStep = true;
  }
  
  if (gameActuallyEndedThisStep || ps == null) {
    setReward(totalStepReward, currentState);
    return; // RETURN IF GAME ENDED ##############
  }
  
  //Movement related rewards
  //Pseudoreward to keep moving forward
  boolean clear = true;
  float centerX = tank0.position.x + (tank0.viewArea.width-20) * cos(tank0.angle);
  float centerY = tank0.position.y + (tank0.viewArea.height-20) * sin(tank0.angle);
  fill(255, 0, 0);
  ellipse(centerX, centerY, 10, 10);
  Boundry point = new Boundry(centerX, centerY, 1, 1);
  for(Tree tree : allTrees){
    if(point.isWithin(tree.boundry) || centerX > 800 || centerY > 800)
       clear = false;
  } 
  if(clear && !ps.facingWall && previousAction == "move" && !ps.enemyInLOS)
    totalStepReward += eventsRewards.get("Good Movevemnt");
  
  //Penalty for standing still
  if(previousAction == "stop" && !ps.enemyInLOS){
    totalStepReward += eventsRewards.get("Stand Still For No Reason");
  }

  //Penalty for looking at wall
  if (ps.facingWall && (previousAction == "move" || previousAction == "stop") && !ps.enemyInLOS) {
    totalStepReward += eventsRewards.get("Facing Wall Move") * ++stuckCounter;
  }
  
  //Reward for going from looking at wall to not
  if (ps.facingWall && !currentState.facingWall) {
    totalStepReward += eventsRewards.get("Escaped Wall");
    stuckCounter = 0;
  }

  //Reward for getting closer to enemy
  if ((ps.nearestEnemyDistCategory == 3 && currentState.nearestEnemyDistCategory == 2) || 
      (ps.nearestEnemyDistCategory == 2 && currentState.nearestEnemyDistCategory == 1)) {
    totalStepReward += eventsRewards.get("Approach Enemy");
  }
  
  //Penalty for moving away from enemy
  if ((ps.nearestEnemyDistCategory == 1 && currentState.nearestEnemyDistCategory == 2) || 
      (ps.nearestEnemyDistCategory == 2 && currentState.nearestEnemyDistCategory == 3)) {
    totalStepReward += eventsRewards.get("Moved Away From Enemy");
  }
  
  
  
  // Time based rewards
  if (previousTime < currentGameTimer) {
    //Same position every second penalty
    if(previousPosition != null && previousPosition == tank0.position){
      totalStepReward += eventsRewards.get("Stand Still For No Reason");
    }
    
    //Keep LOS
    if (ps.enemyInLOS && currentState.enemyInLOS) {
      totalStepReward += eventsRewards.get("See Enemy");
    }
    
    previousPosition = tank0.position;
    previousTime = currentGameTimer;
    totalStepReward += eventsRewards.get("Time");
  }
    
  setReward(totalStepReward, currentState);
}

void setReward(float reward, Tank.State newState) {
  //***** UNCOMMENT THE MULTIPLICATION TO TRY OUT *10 REWARDS MENTIONED IN REPORT *********
  //reward = reward * 10;
  qLearner.updateQ(previousState, previousAction, reward, newState);
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
        cannonBall.drawExplosion();
        return true;
      }
    }

    if (obj instanceof Tank) {
      Tank tank = (Tank) obj;
      if (cannonBall.boundry.intersects(tank.boundry) && cannonBall.shooter != tank) {
        tank.reduceHealth();
        cannonBall.drawExplosion();
        return true;
      }
    }
  }
  return false;
}

// ==================================================================================================


// ==================================================================================================
void updateTanksLogic() {
  for (Tank tank : allTanks) {
    tank.update();
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
