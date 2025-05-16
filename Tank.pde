//Anton Lundqvist
//Erik Zubarev
class Tank extends Sprite {
  PVector velocity,
    startpos,
    enemy,
    prevPos;
  PImage img;
  String name;
  int tankwidth,
    tankheight,
    state,
    currentWaypointIndex,
    lastFired,
    fireCooldown,
    health,
    actionTime,
    randomAction;
  long reportTimer,
    reloadTimer,
    movementTimer;
  float speed,
    maxspeed,
    angle;
  boolean goHome,
    reporting,
    reported,
    reloading,
    immobilized,
    roam,
    hunt,
    linked;
  ArrayList<PVector> currentPath;
  QuadTreeMemory memory;
  ViewArea viewArea;
  ArrayList<Sprite> enemyQueue = new ArrayList<>();
  Team team;
  Search solver;


  Tank(String _name, PVector _startpos, PImage sprite, QuadTreeMemory memory) {
    this.name           = _name;
    this.tankwidth      = sprite.width;
    this.tankheight     = sprite.height;
    this.img            = sprite;
    this.startpos       = new PVector(_startpos.x, _startpos.y);
    this.position       = new PVector(this.startpos.x, this.startpos.y);
    this.velocity       = new PVector(0, 0);
    this.angle          = 0;
    this.state          = 0;
    this.maxspeed       = 2;
    this.memory         = memory;
    this.viewArea       = new ViewArea(position.x, position.y, angle);
    this.boundry        = new Boundry(position.x - tankheight/2, position.y - tankheight/2, this.tankheight, this.tankheight);
    this.goHome         = false;
    this.reported       = false;
    this.reporting      = false;
    this.reloading      = false;
    this.lastFired      = 0;
    this.fireCooldown   = 3000;
    this.health         = 3;
    this.reportTimer    = 0L;
    this.reloadTimer    = 0L;
    this.movementTimer  = 0L;
    this.immobilized    = false;
    this.roam           = name.equals("enemy") ? false : true;
    this.hunt           = false;
    this.linked         = false;
    this.randomAction   = int(random(3));
    this.solver         = new Search(this.memory, this.boundry, this);
  }

  // =================================================
  // ===  MAIN METHODS
  // =================================================

  // MAIN TANK LOGIC ================================================================================== RADIO / VISION
  void update() {
    //Stopgap measure for making sure tanks can relink after killing assigned enemies, only for vision
    if(enemyQueue.isEmpty())
      linked = false;
    
    
    if(hunt && reported){
      if(team.radioComs)
        handleEnemyQueueRadio();
      else 
        handleEnemyQueueVision();
    }

    if (roam) {
      roam();
    }
    
    checkReloading();
    checkReporting();
    checkHeadingHomeLogic();

    switch (state) {
    case 0:
      action("stop");
      break;
    case 1:
      action("move");
      break;
    case 2:
      action("reverse");
      break;
    }

    updateCollision();

    viewArea.updateViewArea(this.position.x, this.position.y, this.angle);
  }

  // SWITCHING STATES OF TANK BASED ON ACTION ==========================================================
  void action(String _action) {
    switch (_action) {
    case "move":
      if (!immobilized) moveForward();
      break;
    case "reverse":
      if (!immobilized) moveBackward();
      break;
    case "rotateLeft":
      if (health > 0) rotateLeft();
      break;
    case "rotateRight":
      if (health > 0) rotateRight();
      break;
    case "stop":
      stopMoving();
      break;
    case "reporting":
      reporting = true;
      stopMoving();
      break;
    case "fire":
      fireCannon();
      break;
    }
  }

  // TANK VISION SENSOR ==================================================================================
  void detectObject() {
    for (Sprite obj : placedPositions) {
      if (viewArea.intersects(obj.boundry) && obj != this) {
        boolean unseenLandmineDetected = detectedNewLandmine(obj);
        boolean enemyDetected = detectedEnemy(obj);

        if (obj instanceof Tank && enemyDetected) {
          handleEnemyDetection((Tank) obj);
        }

        memory.insert(obj);

        if (unseenLandmineDetected) {
          if (currentPath != null && currentPath.size() > 0) {
            calculatePath(position, currentPath.get(currentPath.size() - 1)); //Found an unknown mine while following path so recalculate
          }
        }
      }
    }
    memory.updateExploredStatus(viewArea);
    memory.pruneChildren(viewArea);
  }
  
  // HANDLE ENEMY DETECTION ==============================================================================
  void handleEnemyDetection(Tank tank){
    if(tank.health == 0 || enemyQueue.contains(tank) || team.enemyQueue.contains(tank))
      return;
    
    // Vision only
    if(!enemyQueue.isEmpty() && !goHome){
      currentPath = null;
      enemyQueue.add(0, tank);
      return; //Add new enemy to vision queue and engage later.
    }
    
    if(team.radioComs){
      startReport();
      team.addEnemyToQueue(tank);
    }
    else{
      enemyQueue.add(tank);
      goHome();
    }

    //Helper logic for exploring the area around the enemytank when its found. Helps with calculating the ambush point
    memory.updateExploredStatus(tank.boundry);
    Boundry expandedBoundry = new Boundry(tank.position.x - 70, tank.position.y - 70, 140, 140);
    memory.updateExploredStatus(expandedBoundry);
    memory.pruneChildren(expandedBoundry);
    roam = false;
  }
  
  // =================================================
  // ===  START OF RADIO LOGIC
  // =================================================

  // RADIO IMPLEMENTATION OF KILLING ENEMIES ==========================================================
  void handleEnemyQueueRadio() {
    //If the queue is empty, stop hunting and start roaming, unlink from other tank.
    if(team.isQueueEmpty()){
      hunt = false;
      roam = true;
      goHome = false;
      currentPath = null;
      reported = false;
      return;
    }

    //Otherwise there is an enemy to kill
    Tank enemyTank = (Tank) team.enemyQueue.get(0);

    //Check if the enemy is still alive
    if (enemyTank.health == 0) {
      team.removeEnemy(enemyTank);
      currentPath = null;
      return; //Exit the method to process the next enemy in the next update
    }
    
    //Move towards the enemy
    checkPathToEnemy(enemyTank);

    //If not at enemy, move to enemy, else shoot at enemy
    if (currentPath != null && currentWaypointIndex < currentPath.size())
      moveTowardEnemy();
    else
      engageEnemyRadio(enemyTank);
  }

  // FIRE AT ENEMY ======================================================================================
  void engageEnemyRadio(Tank enemyTank) {
    if (hasLineOfSight(position, enemyTank) && repositionToAlignWithEnemy(enemyTank)) {
      action("stop");
      action("fire");
    } else 
      repositionToAlignWithEnemy(enemyTank);
  }
  
  // UPDATE PATH TO ENEMY =========================================================================== RADIO 
  void checkPathToEnemy(Tank enemy){
    if(currentPath != null)
      return;
      
    //Find way to enemy
    ArrayList<PVector> path = solver.solve(position, enemy.position);
    currentWaypointIndex = 0;
    currentPath = path;
    
    //Get clear LOS to enemy
    for(int i = 0; i < path.size(); i++){
      PVector pos = path.get(i);
      if(!hasLineOfSight(pos, enemy))
        continue;

      currentPath = new ArrayList<PVector>();
      
      for(int j = 0; j <= i; j++)
        currentPath.add(path.get(j));

      return;
    }
  }
  
  // CHECK IF ENEMY CAN BE SHOT AT FROM START ======================================================== RADIO
  public boolean hasLineOfSight(PVector start, Tank enemy) {
    Boundry tempBoundry = new Boundry(
      start.x - boundry.width / 2,
      start.y - boundry.height / 2,
      tankwidth,
      tankheight
      );

    float distance = start.dist(enemy.position);
    int steps = (int)(distance / 5) + 1; // Divide straight line into segments
    for (int i = 0; i <= steps; i++) {
      float t = i / (float) steps;
      PVector point = PVector.lerp(start, enemy.position, t); // New segment to check
      tempBoundry.x = point.x - tankwidth / 2;
      tempBoundry.y = point.y - tankheight / 2;

      // Check for obstacles
      ArrayList<Sprite> obstacles = memory.query(tempBoundry); // Will not detect objects that are not in memory
      
      for(Sprite s : obstacles){
        if(s == enemy || s == this)
          continue;

        return false;
      }
    }
    return true;
  }

  // =================================================
  // ===  END OF RADIO LOGIC
  // =================================================
  // ==================================================================================================



  // =================================================
  // ===  START OF VISION LOGIC
  // =================================================
  // ==================================================================================================

  //Main method for handling movemement to enemyTanks and removing them from the enemeyQueue if they die.
  void handleEnemyQueueVision() {
    //If the queue is empty, stop hunting and start roaming, unlink from other tank.
    if(enemyQueue.isEmpty()){
      hunt = false;
      roam = true;
      linked = false;
      currentPath = null;
      goHome = false;
      reported = false;
      return;
    }
    
    //Otherwise there is an enemy to kill
    Tank enemyTank = (Tank) enemyQueue.get(0);

    if (enemyTank.health == 0) {
      enemyQueue.remove(0);
      return; //Exit the method to process the next enemy in the next update
    }
    
    //Move towards the enemy
    if (currentPath != null && currentWaypointIndex < currentPath.size()) {
      moveTowardEnemy();
    }
    else{
      engageEnemy(enemyTank);
    }
  }

 
  //Helper function for gathering valid points around a enemy tank to path find to.
  //Uses trigonometri to get 4 evenly spaces points around a tank in a 50px radius
  PVector findAmbushSite(Sprite enemyTank) {
    println(enemyTank);
    PVector target = enemyTank.position;
    float radius = 50; 
    int slices = 4; 


    ArrayList<PVector> points = new ArrayList<>();

    for (int i = 0; i < slices; i++) {
      float angle = TWO_PI / slices * i; 
      float x = target.x + cos(angle) * radius; 
      float y = target.y + sin(angle) * radius; 
      points.add(new PVector(x, y));
    }

    //Checks all spots to see if they are clear excluding the enemyTank
    for (PVector vec : points) {
      if (!memory.isExplored(new Boundry(target.x, target.y, 1, 1))) 
        continue;

      Boundry temp = new Boundry(vec.x - tankwidth / 2, vec.y - tankheight, 70, 70);
      ArrayList<Sprite> obstacles = memory.query(temp);
      if (obstacles.isEmpty())
        continue;
      
      boolean allAreEnemyTank = true;
      for (Sprite obstacle : obstacles) {
        if (obstacle != enemyTank) {
          allAreEnemyTank = false;
          break;
        }
      }
      if (allAreEnemyTank) {
        return vec;
      }
    }

    return target;
  }

  //Helper method to collate information with a ally when going out to hunt a enemy.
  //Merges eachothers enemeyQueue lists and sorts them according to distance from base, least first.
  void collateWithAlly(Tank ally, PVector baseCenter) {
    for (Sprite enemy : ally.enemyQueue) {
      if (!enemyQueue.contains(enemy))
        enemyQueue.add(enemy);
    }

    //Sort the enemyQueue based on distance from the base center
    enemyQueue.sort((a, b) -> {
      float distA = a.position.dist(baseCenter);
      float distB = b.position.dist(baseCenter);
      return Float.compare(distA, distB);
    });

    this.goHome = false;
    this.roam = false;
    this.hunt = true;

    // Only proceed if there is at least one enemy
    if (enemyQueue.isEmpty()) {
      this.hunt = false;
      this.roam = true;
      this.linked = false;
      return;
    }

    //Create a ambush site that doesn't interfere with the other tanks pathfinding
    Sprite targetEnemy = enemyQueue.get(0);
    PVector ambush = findAmbushSite(targetEnemy);
    calculatePath(position, ambush);
    Target ambushTarget = new Target(ambush, this);
    placedPositions.add(ambushTarget);
    memory.insert(ambushTarget);

    //Add a Target at each waypoint to make sure other tanks don't plan routes that collide with this one.
    if (currentPath != null && !currentPath.isEmpty()) {
      for (int i = 0; i < currentPath.size() - 1; i++) {
        PVector p = currentPath.get(i);
        Target target = new Target(p, this);
        placedPositions.add(target);
        memory.insert(target);
      }
    }
  }


  //helper method for handleEnemyQueue that handles firing on the enemy if they can.
  void engageEnemy(Tank enemyTank) {
    if (enemyTank.boundry.isWithin(this.viewArea) && repositionToAlignWithEnemy(enemyTank)) {
      action("stop");
      action("fire");
    } else {
      repositionToAlignWithEnemy(enemyTank);
    }
  }

  // =================================================
  // ===  END OF VISION LOGIC
  // =================================================
  // ==================================================================================================



  // =================================================
  // ===  HELPER METHODS
  // =================================================
  
  
  //Helper method for engageEnemy. calculates the direction the tank needs to turn to face enemy and turns it accordingly
  //If they are already facing them we move forwards.
  boolean repositionToAlignWithEnemy(Tank enemyTank) {
    PVector directionToEnemy = PVector.sub(enemyTank.position, position).normalize();
    float angleToEnemy = atan2(directionToEnemy.y, directionToEnemy.x);
    float angleDifference = atan2(sin(angleToEnemy - angle), cos(angleToEnemy - angle));
    
    if (abs(angleDifference) > radians(3)) { // If not aligned, rotate towards the enemy
      if (angleDifference > 0) {
        action("rotateRight");
      } else {
        action("rotateLeft");
      }
      return false;
    } else {
      if(!team.radioComs)
        action("move");
      return true;
    }
  }
  
  // MOVE TOWARD ENEMY ==================================================================================
  void moveTowardEnemy(){
    PVector waypoint = currentPath.get(currentWaypointIndex);
    moveTowards(waypoint);

    //Check if the tank has reached the current waypoint
    if (position.dist(waypoint) < 10) {
      currentWaypointIndex++;
    }

    if(position.dist(currentPath.get(currentPath.size()-1)) < 10){  
      //THE HOLY PRINTLN, IDK WHY BUT THIS CODE SEGMENT LEGIT DOSENT WORK WITHOUT IT
      println("you should stop");
      currentWaypointIndex = Integer.MAX_VALUE;
      action("stop");
    }
  }
  
  // ==================================================================================================
  void goHome() {
    if (!goHome) {
      goHome = true;
      calculatePath(position, startpos);
    }
  }

  // RETURN BEST PATH ================================================================================= BFS / GBFS
  void calculatePath(PVector start, PVector goal) {
    // Switch between GBFS and BFS in Search class

    currentPath = solver.solve(start, goal);
    //Fallback in case no path was found. Revers to roaming.
    if(currentPath.size() <= 0){
      goHome = false;
      hunt = false;
      linked = false;
      roam = true;
      reported = false;
      enemyQueue = new ArrayList<Sprite>();
    }
    currentWaypointIndex = 0;
  }

  // OBSERVE IF ENEMY IS SPOTTED ===================================================================== RADIO / VISION
  boolean detectedEnemy(Sprite obj) {
    if (obj instanceof Tank) {
      Tank tank = (Tank) obj;

      if (tank.name.equals("enemy")) {
        return true;
      }
    }
    return false;
  }

  // DYNAMICALLY CHECK IF A LANDMINE APPEARED =========================================================
  boolean detectedNewLandmine(Sprite obj) {
    if (obj instanceof Landmine) {
      ArrayList<Sprite> foundObjects = memory.query(obj.boundry);
      boolean alreadyKnown = foundObjects.contains(obj);

      if (!alreadyKnown) {
        println("New landmine detected!");
        return true;
      }
    }
    return false;
  }

  // IS TANK GOING HOME / IS TANK AT HOME =============================================================
  void checkHeadingHomeLogic() {

    // Is tank going home?
    if (goHome && currentPath != null && currentWaypointIndex < currentPath.size()) {
      PVector waypoint = currentPath.get(currentWaypointIndex);
      moveTowards(waypoint);
    }

    // Is tank at home?
    if (goHome && currentPath != null && currentWaypointIndex < currentPath.size()) {
      PVector waypoint = currentPath.get(currentWaypointIndex);
      if (position.dist(waypoint) < 7) {
        currentWaypointIndex++;
        if (currentWaypointIndex >= currentPath.size()) {
          startReport();
        }
      }
    }
  }
  
  
  // IS REPORTING HELPER ===============================================================================
  void startReport(){
    reportTimer = System.currentTimeMillis();
    goHome = false;
    action("reporting");
  }

  // IS REPORTING LOGIC ================================================================================
  void checkReporting() {
  if (reportTimer == 0L)
    return;
  
    displayReportTimer();
    long now = System.currentTimeMillis();
    if (now - reportTimer >= 3000) {
      team.setReported();
      reportTimer = 0L;
      reporting = false;
    }
  }

  // IS RELOADING LOGIC ================================================================================
  void checkReloading() {
    if (reloadTimer == 0L)
      return;

    long now = System.currentTimeMillis();
    if (now - reloadTimer >= 3000) {
      reloading = false;
      reloadTimer = 0L;
    }
  }

  // PUT TEAM BASE INTO MEMORY AT THE START OF THE GAME ================================================
  void putBaseIntoMemory(Boundry base) {
    // Mark the base area as explored
    memory.updateExploredStatus(base);

    // Insert all objects within the base area into memory
    for (Sprite obj : placedPositions) {
      if (base.intersects(obj.boundry) && obj != this) {
        memory.insert(obj);
      }
    }

    // Prune unnecessary children in the memory tree for optimization
    memory.pruneChildren(base);
  }

  // UPDATE BOUNDRY TO MOVE WITH TANK ================================================================
  void updateBoundry() {
    boundry.x = position.x - tankheight / 2;
    boundry.y = position.y - tankheight / 2;
  }

  // CHECK IF TANK TOUCHES EDGE OF THE WORLD =========================================================
  void checkBorders() {
    float r = tankwidth / 2;
    position.x = constrain(position.x, r, width - r);
    position.y = constrain(position.y, r, height - r);
  }

  // COLLISION DETECTION =============================================================================
  void updateCollision() {
    float candidateX = position.x + velocity.x;
    float candidateY = position.y + velocity.y;

    if (!collisionAt(candidateX, position.y)) {
      position.x = candidateX;
    }
    if (!collisionAt(position.x, candidateY)) {
      position.y = candidateY;
    }
    checkBorders();
  }

  // ==================================================================================================
  boolean collisionAt(float x, float y) {
    PVector candidate = new PVector(x, y);
    PVector backup = position.copy();
    position.set(candidate);
    updateBoundry();
    for (Sprite s : placedPositions) {
      if (s instanceof Landmine || s instanceof Target)
        continue;
      if (s != this && boundry.intersects(s.boundry)) {
        position.set(backup);
        updateBoundry();
        return true;
      }
    }
    position.set(backup);
    updateBoundry();
    return false;
  }


  // =================================================
  // ===  PERFORM ACTIONS HELPER METHODS
  // =================================================
  // ==================================================================================================
  void moveForward() {
    state = 1;
    this.velocity.x = cos(this.angle) * this.maxspeed;
    this.velocity.y = sin(this.angle) * this.maxspeed;
  }

  // ==================================================================================================
  void moveBackward() {
    this.velocity.x = -cos(this.angle) * this.maxspeed;
    this.velocity.y = -sin(this.angle) * this.maxspeed;
  }

  // ==================================================================================================
  void rotateLeft() {
    this.angle -= radians(3);
  }

  // ==================================================================================================
  void rotateRight() {
    this.angle += radians(3);
  }

  // ==================================================================================================
  void stopMoving() {
    this.state = 0;
    this.velocity.x = 0;
    this.velocity.y = 0;
  }

  // ==================================================================================================
  void fireCannon() {
    if (!reloading) {
      CannonBall cannonBall = new CannonBall(position.copy(), this.angle, this);
      addCannonBall(cannonBall);
      reloading = true;
      reloadTimer = System.currentTimeMillis();
    }
  }

  // ==================================================================================================
  void reduceHealth() {
    if (health == 2) {
      immobilized = true;
    }

    if (health != 0) {
      health--;
    }
  }

  // AUTOMATIC MOVEMENT WHEN GOING HOME =================================================================
  void moveTowards(PVector target) {
    float targetAngle = atan2(target.y - position.y, target.x - position.x);
    float angleDifference = atan2(sin(targetAngle - angle), cos(targetAngle - angle));

    if (abs(angleDifference) > radians(3)) {
      if (angleDifference > 0)
        action("rotateRight");
      else
        action("rotateLeft");

      state = 0; // Stop Moving
    } else {
      state = 1; // Move forward
    }
  }

  // AUTOMATIC RANDOM MOVEMENT WHEN EXPLORING =================================================================
  void roam() {
    if (roam) {
      // Initialize prevPos dynamically if it's not set
      if (prevPos == null) {
        prevPos = position.copy();
      }

      long now = System.currentTimeMillis();
      if (now - movementTimer >= actionTime) {
        // Check if the tank is stuck
        if (position.dist(prevPos) < 1.0) {
          if (randomAction != 2) {
            randomAction = 2;
            actionTime = 1000;
          } else {
            randomAction = 0;
            actionTime = 500;
          }
        } else {
          randomAction = int(random(2));
          actionTime = randomAction != 0 ? 200 : 1000; // Shorter time for rotation
        }

        movementTimer = now; // Reset the timer
        prevPos = position.copy(); // Update the previous position
      }

      // Perform the action tied to the current randomAction
      switch (randomAction) {
      case 0:
        action("move");
        break;
      case 1:
        action("stop");
        action("rotateLeft");
        break;
      case 2:
        action("stop");
        action("rotateRight");
        break;
      }
    }
  }
  // =================================================
  // ===  DISPLAY METHODS
  // =================================================
  // DISPLAY SELF ======================================================================================
  void display() {
    pushMatrix();
    translate(this.position.x, this.position.y);
    drawTank(0, 0);
    if (true) { // Assuming debugMode is a global boolean
      fill(230);
      stroke(0);
      strokeWeight(1);
      // Adjust text box position relative to the tank's center
      float textBoxWidth = 100;
      float textBoxHeight = 50;
      float textBoxX = 40; // Offset from center
      float textBoxY = -40; // Offset from center
      rect(textBoxX, textBoxY, textBoxWidth, textBoxHeight);
      fill(30);
      textSize(12); // Smaller text size for info
      textAlign(LEFT, TOP); // Align text to top-left of the box
      // Display tank name, position, and current state(s)
      String stateText = "";
      if (roam) stateText = "Roaming";
      else if (goHome) stateText = "Going Home";
      else if (reporting) stateText = "Reporting";
      else if (hunt) stateText = "Hunting";
      else stateText = "Stopped";

      text(this.name + "\n(" + nf(this.position.x, 0, 1) + ", " + nf(this.position.y, 0, 1) + ")\nState: " + stateText, textBoxX + 5, textBoxY + 5);
      textAlign(CENTER, CENTER); // Reset text alignment
    }
    popMatrix();
    boundry.draw(); // Assuming Boundry class has a draw method
    displayHealth(); // Display health bar/image
    if (reloading) {
      displayReloadTimer(); // Display reload timer visual
    }
    if (reporting) {
      displayReportTimer(); // Display reporting timer visual
    }
    if (debugMode) {
      drawViewArea(); // Draw view area in debug mode
      // Draw path in debug mode (can be for any path, not just home)
    }
    displayPathHome();
  }

  // ==================================================================================================
  void drawTank(float x, float y) {
    pushMatrix();
    strokeWeight(0);
    translate(x, y);
    rotate(this.angle);
    imageMode(CENTER);
    image(img, x, y);
    imageMode(CORNER);
    popMatrix();
  }

  // ==================================================================================================
  void displayHealth() {
    float x = position.x - tankwidth / 2 - 10;
    float y = position.y - tankheight / 2 - 30;
    image(healthImages[health], x, y);
  }

  // ==================================================================================================
  void drawViewArea() {
    viewArea.drawArea(this);
  }

  // ==================================================================================================
  void displayReportTimer() {
    pushMatrix();
    translate(this.position.x, this.position.y);
    textSize(12);
    fill(0);
    text("Reporting!!", 25, 40);

    fill(255);
    rect(35, -25, 7, 50, 2);

    // Calculate the progress of the line (percentage of 3000ms elapsed)
    long now = System.currentTimeMillis();
    float progress = constrain((now - reportTimer) / 3000.0, 0, 1);

    // Draw the filling line inside the rectangle
    stroke(0);
    strokeWeight(2);
    float lineHeight = progress * 40;
    line(38, 20, 38, 20 - lineHeight);
    popMatrix();
  }

  // ==================================================================================================
  void displayReloadTimer() {
    pushMatrix();
    translate(this.position.x, this.position.y);
    textSize(12);
    fill(0);
    text("Reloading!!", 25, 40);

    fill(255);
    rect(35, -25, 7, 50, 2);

    // Calculate the progress of the line (percentage of 3000ms elapsed)
    long now = System.currentTimeMillis();
    float progress = constrain((now - reloadTimer) / 3000.0, 0, 1);

    // Draw the filling line inside the rectangle
    stroke(0);
    strokeWeight(2);
    float lineHeight = progress * 40;
    line(38, 20, 38, 20 - lineHeight);
    popMatrix();
  }

  // ==================================================================================================
  void displayPathHome() {
    if (currentPath == null || currentPath.isEmpty()) {
      return;
    }
    stroke(255, 255, 0);
    strokeWeight(5);
    noFill();
    beginShape();
    for (PVector waypoint : currentPath) {
      circle(waypoint.x, waypoint.y, 20);
      vertex(waypoint.x, waypoint.y);
    }
    endShape();
  }


  // =================================================
  // ===  INNER CLASS VIEW AREA
  // =================================================
  class ViewArea extends Boundry {
    float viewAngle;

    final float viewLength = 200;
    final float viewWidth = 100;

    public ViewArea(float agentStartX, float agentStartY, float agentStartAngle) {
      super(agentStartX, agentStartY, 100, 200);
      this.viewAngle = agentStartAngle;
      updateViewArea(agentStartX, agentStartY, agentStartAngle);
    }

    // ==================================================================================================
    public void updateViewArea(float agentX, float agentY, float agentAngle) {
      this.viewAngle = agentAngle; // Store the current angle

      float centerX = agentX + cos(this.viewAngle) * (this.viewLength / 2.0);
      float centerY = agentY + sin(this.viewAngle) * (this.viewLength / 2.0);

      PVector[] corners = new PVector[4];
      float angleRad = this.viewAngle;
      float cosA = cos(angleRad);
      float sinA = sin(angleRad);
      float halfL = this.viewLength / 2.0;
      float halfW = this.viewWidth / 2.0;


      float relX_TR = +halfL;
      float relY_TR = -halfW;
      corners[0] = new PVector(centerX + relX_TR * cosA - relY_TR * sinA,
        centerY + relX_TR * sinA + relY_TR * cosA);
      // Top-Left Corner
      float relX_TL = +halfL;
      float relY_TL = +halfW;
      corners[1] = new PVector(centerX + relX_TL * cosA - relY_TL * sinA,
        centerY + relX_TL * sinA + relY_TL * cosA);
      // Bottom-Left Corner
      float relX_BL = -halfL;
      float relY_BL = +halfW;
      corners[2] = new PVector(centerX + relX_BL * cosA - relY_BL * sinA,
        centerY + relX_BL * sinA + relY_BL * cosA);
      // Bottom-Right Corner
      float relX_BR = -halfL;
      float relY_BR = -halfW;
      corners[3] = new PVector(centerX + relX_BR * cosA - relY_BR * sinA,
        centerY + relX_BR * sinA + relY_BR * cosA);


      float minX = corners[0].x, maxX = corners[0].x;
      float minY = corners[0].y, maxY = corners[0].y;
      for (int i = 1; i < 4; i++) {
        minX = min(minX, corners[i].x);
        maxX = max(maxX, corners[i].x);
        minY = min(minY, corners[i].y);
        maxY = max(maxY, corners[i].y);
      }

      this.x = minX;
      this.y = minY;
      this.width = maxX - minX;
      this.height = maxY - minY;
    }


    // ==================================================================================================
    void drawArea(Tank t) {
      float agentX = position.x;
      float agentY = position.y;
      float centerX = agentX + cos(this.viewAngle) * (this.viewLength / 2.0);
      float centerY = agentY + sin(this.viewAngle) * (this.viewLength / 2.0);

      // Actual view area
      if (debugMode) {
        pushMatrix();
        translate(centerX, centerY);
        rotate(this.viewAngle);
        strokeWeight(1);
        fill(255, 255, 0, 100);
        rectMode(CENTER);
        rect(0, 0, this.viewLength, this.viewWidth);
        rectMode(CORNER);
        popMatrix();
      }

      // Visual view area
      pushMatrix();
      translate(agentX, agentY);
      rotate(this.viewAngle);
      strokeWeight(0.5);
      stroke(0);
      fill(15, 15, 15, 50);
      quad(0, 0 - t.tankwidth/4, 0, 0 + t.tankwidth/4, 0+viewLength, 0+viewWidth/2, 0+viewLength, 0-viewWidth/2);
      popMatrix();
    }
  }
}
