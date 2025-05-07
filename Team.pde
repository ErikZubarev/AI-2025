//Anton Lundqvist
//Erik Zubarev
class Team {
  ArrayList<Tank> members = new ArrayList<>();
  ArrayList<Tank> currentlyHome = new ArrayList();
  color teamColor;
  int x,y;
  Boundry boundry;

  public Team(int x, int y, color teamColor){
    this.x = x;
    this.y = y;
    this.teamColor = teamColor;
    this.boundry = new Boundry(x, y, 150, 350); 
  }

  void checkIfTankHome() {
    // Check if tanks have entered the base
    for (Tank tank : members) {
      if (!currentlyHome.contains(tank) && boundry.intersects(tank.boundry)) {
        currentlyHome.add(tank);
      }
    }

    if(currentlyHome.size() > 2){
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

  // Find the first two tanks with enemies in their queue
  for (Tank tank : currentlyHome) {
    if (tank.enemyQueue.size() > 0) {
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
    PVector baseCenter = new PVector(x + 75, y + 175); // Center of the base, used for the tanks to determine which enemy to go for first.
    tankWithEnemies1.collateWithAlly(tankWithEnemies2, baseCenter);
    tankWithEnemies2.collateWithAlly(tankWithEnemies1, baseCenter);
  } else if (tankWithEnemies1 != null) {
    // If only one tank has enemies, link it with any other tank
    for (Tank tank : currentlyHome) {
      if (tank != tankWithEnemies1) {
        PVector baseCenter = new PVector(x + 75, y + 175); 
        tankWithEnemies1.collateWithAlly(tank, baseCenter);
        tank.collateWithAlly(tankWithEnemies1, baseCenter);
        break;
      }
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
