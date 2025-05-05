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
  boolean isInTransition,
    goHome,
    reporting,
    reported,
    reloading,
    immobilized,
    roam;
  ArrayList<PVector> currentPath;
  QuadTreeMemory memory;
  ViewArea viewArea;

  //*****Uncomment and comment the below lines to change between Radio and Vision sensor mode
  Radio radio;

  //*****Uncomment and comment the below lines to change between GBFS and BFS
  GBFS solver;
  //BFS solver;

  Tank(String _name, PVector _startpos, PImage sprite) {
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
    this.isInTransition = false;
    this.memory         = new QuadTreeMemory(new Boundry(0, 0, 800, 800), 6);
    this.viewArea       = new ViewArea(position.x, position.y, angle);
    this.boundry        = new Boundry(position.x - tankheight/2, position.y - tankheight/2, this.tankheight, this.tankheight);
    this.goHome         = false;
    this.reported       = false;
    this.reporting      = false;
    this.reloading      = false;
    this.radio          = new Radio();
    this.lastFired      = 0;
    this.fireCooldown   = 3000;
    this.health         = 3;
    this.reportTimer    = 0L;
    this.reloadTimer    = 0L;
    this.movementTimer  = 0L;
    this.immobilized    = false;
    this.roam           = true;
    this.randomAction   = int(random(3));
  }

  // =================================================
  // ===  MAIN METHODS
  // =================================================

  // MAIN TANK LOGIC ================================================================================== RADIO / VISION
  void update() {
    if (reported) {
      //radio.commandAllies(this, allTanks);
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
    if(!goHome) {roam();}

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

  // TANK VISION LOGIC ==================================================================================
  void detectObject() {
    for (Sprite obj : placedPositions) {
      if (viewArea.intersects(obj.boundry) && obj != this) { //Ignore self
        boolean unseenLandmineDetected = detectedNewLandmine(obj);
        boolean enemyDetected = detectedEnemy(obj);

        if (unseenLandmineDetected && goHome)
          calculatePath(position, startpos); //Found an unknown mine on the way back home so we recalculate path

        if (enemyDetected && !reported) {
          action("stop");
          roam = false;
          goHome();
        }


        memory.insert(obj);
      }
    }
    memory.updateExploredStatus(viewArea);
    memory.pruneChildren(viewArea);
  }



  // =================================================
  // ===  HELPER METHODS
  // =================================================
  // ==================================================================================================
  void goHome() {
    if (!goHome) {
      goHome = true;
      calculatePath(position, startpos);
    }
  }

  // RETURN BEST PATH ================================================================================= BFS / GBFS
  void calculatePath(PVector start, PVector goal) {

    //*****Uncomment and comment the below lines to change between GBFS and BFS
    solver = new GBFS(start, goal, memory, boundry);
    //solver = new BFS(position, startpos, memory, boundry);

    currentPath = solver.solve();
    currentWaypointIndex = 0;
  }

  // OBSERVE IF ENEMY IS SPOTTED ===================================================================== RADIO / VISION
  boolean detectedEnemy(Sprite obj) {
    if (obj instanceof Tank) {
      Tank tank = (Tank) obj;

      if (tank.name.equals("enemy")) {
        println("Enemy Spotted!!");
        radio.reportEnemy(tank.position);
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
          reportTimer = System.currentTimeMillis();
          goHome = false;
          action("reporting");
        }
      }
    }
  }

  // IS REPORTING LOGIC ================================================================================ TODO: UPDATE THIS SO TANK CANT MOVE WHEN REPORTING
  void checkReporting() {
    if (reportTimer == 0L)
      return;

    displayReportTimer();
    long now = System.currentTimeMillis();
    if (now - reportTimer >= 3000) {
      reported = true;
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
  void putBaseIntoMemory() {
    Boundry base = new Boundry(0, 0, 150, 350); //Ally base
    Boundry pos = new Boundry(startpos.x, startpos.y, 1, 1);

    if (!pos.isWithin(base)) {
      base = new Boundry(width - 151, height - 351, 150, 350); //Enemy base
    }

    memory.updateExploredStatus(base);

    for (Sprite obj : placedPositions) {
      if (base.intersects(obj.boundry) && obj != this) {
        memory.insert(obj);
      }
    }

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
      if (s instanceof Landmine)
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
    this.velocity.x = 0;
    this.velocity.y = 0;
  }

  // ==================================================================================================
  void fireCannon() {
    if (!reloading) {
      println("fired");
      CannonBall cannonBall = new CannonBall(position.copy(), angle, this);
      addCannonBall(cannonBall);
      reloading = true;
      reloadTimer = System.currentTimeMillis();
    } else {
      println("Cannon is on cooldown!");
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
                randomAction = int(random(3)); 
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
    if (debugMode) {
      fill(230);
      stroke(0);
      strokeWeight(1);
      rect(0 + 40, 0 - 40, 100, 40);
      fill(30);
      textSize(15);
      text(this.name + "\n( " + this.position.x + ", " + this.position.y + " )", 40 + 5, -20 - 5);
    }
    popMatrix();
    boundry.draw();
    displayHealth();
    if (reloading) {
      displayReloadTimer();
    }
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
      fill(15, 15, 15, 50);
      quad(0, 0 - t.tankwidth/4, 0, 0 + t.tankwidth/4, 0+viewLength, 0+viewWidth/2, 0+viewLength, 0-viewWidth/2);
      popMatrix();
    }
  }
}
