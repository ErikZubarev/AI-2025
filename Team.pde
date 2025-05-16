//Anton Lundqvist
//Erik Zubarev
class Team {
  ArrayList<Tank> members = new ArrayList<>();
  ArrayList<Tank> currentlyHome = new ArrayList();
  ArrayList<Tank> enemyQueue = new ArrayList<>();
  color teamColor;
  int x, y;
  boolean radioComs = false; // #################################### SWITCH BETWEEN RADIO OR VISION COMMUNICATIONS, SWITCH TO FALSE FOR VISION ####################################
  Boundry boundry;

  public Team(int x, int y, color teamColor) {
    this.x = x;
    this.y = y;
    this.teamColor = teamColor;
    this.boundry = new Boundry(x, y, 150, 350);
  }

  // =================================================
  // ===  RADIO
  // =================================================
  // ==================================================================================================
  
  void removeEnemy(Tank t){
    enemyQueue.remove(t);  
    sortQueue();
  }
  
  boolean isQueueEmpty(){
     return enemyQueue.isEmpty();
  }
  
  void addEnemyToQueue(Tank enemy){
    if(!enemyQueue.contains(enemy)){
      enemyQueue.add(enemy);
      sortQueue();
    }
  }
  
  void sortQueue(){
    PVector baseCenter = new PVector(x + 75, y + 175); // Center of the base
    enemyQueue.sort((a, b) -> {
      float distA = a.position.dist(baseCenter);
      float distB = b.position.dist(baseCenter);
      return Float.compare(distA, distB);
    });
  }
  
  void setReported(){
    for(Tank t : members){
      t.reported = true;
    }
  }
  
  // =================================================
  // ===  VISION
  // =================================================
  // ==================================================================================================
  
  void checkIfTankHome() {
    // Check if tanks have entered the base
    for (Tank tank : members) {
      if (!currentlyHome.contains(tank) && boundry.intersects(tank.boundry)) {
        currentlyHome.add(tank);
      }
    }

    boolean anyReported = false;
    for (Tank tank : currentlyHome) {
      if (tank.reported) {
      anyReported = true;
      break;
      }
    }
    if (currentlyHome.size() >= 2 && anyReported) {
      linkTanks();
    }

    // Check if tanks have left the base
    // Apprently if you dont iterate backwards it could cause issues lol
    for (int i = currentlyHome.size() - 1; i >= 0; i--) {
      Tank tank = currentlyHome.get(i);
      if (!boundry.intersects(tank.boundry)) {
        currentlyHome.remove(i);
      }
    }
  }

  void linkTanks() {
    Tank tankWithEnemies1 = null;
    Tank tankWithEnemies2 = null;

    // Find the first two tanks with enemies in their queue that are not already linked
    for (Tank tank : currentlyHome) {
      if (tank.enemyQueue.size() > 0 && !tank.linked) {
        if (tankWithEnemies1 == null) {
            tankWithEnemies1 = tank;
        } else if (tankWithEnemies2 == null) {
            tankWithEnemies2 = tank;
            break;
        }
      }
    }

    if (tankWithEnemies1 != null && tankWithEnemies2 != null) {
      // Link the two tanks with enemies
      PVector baseCenter = new PVector(x + 75, y + 175); // Center of the base
      tankWithEnemies1.collateWithAlly(tankWithEnemies2, baseCenter);
      tankWithEnemies2.collateWithAlly(tankWithEnemies1, baseCenter);

      // Mark both tanks as linked
      tankWithEnemies1.linked = true;
      tankWithEnemies2.linked = true;
    } 
    else if (tankWithEnemies1 != null) {
      // If only one tank has enemies, link it with any other unlinked tank
      for (Tank tank : currentlyHome) {
        if (tank != tankWithEnemies1 && !tank.linked) {
            PVector baseCenter = new PVector(x + 75, y + 175);
            tankWithEnemies1.collateWithAlly(tank, baseCenter);
            tank.collateWithAlly(tankWithEnemies1, baseCenter);

            // Mark both tanks as linked
            tankWithEnemies1.linked = true;
            tank.linked = true;
            break;
        }
      }
    }

    //Removes the targets from memory for garbage collection.
    for (int i = placedPositions.size() - 1; i >= 0; i--) {
      Sprite sprite = placedPositions.get(i);
      if (sprite instanceof Target) {
        placedPositions.remove(i);
      }
    }
  }

  

  void display() {
    pushMatrix();
    strokeWeight(1);
    stroke(0);
    fill(teamColor, 100);
    rect(x, y, 150, 350);
    popMatrix();
  }
}
