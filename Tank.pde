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
    lastFired, 
    fireCooldown,
    health;
  long
    reloadTimer;
  float speed, 
  maxspeed,
    angle;
  boolean
    reloading; 
  ViewArea viewArea;
  Team team;

  Tank(String _name, PVector _startpos, PImage sprite) {
    this.name           = _name;
    this.tankwidth      = sprite.width;
    this.tankheight     = sprite.height;
    this.img            = sprite;
    this.startpos       = new PVector(_startpos.x, _startpos.y);
    this.position       = new PVector(this.startpos.x, this.startpos.y);
    this.velocity       = new PVector(0, 0);
    this.angle          = 0; 
    this.maxspeed       = 2;
    this.viewArea       = new ViewArea(position.x, position.y, angle);
    this.boundry        = new Boundry(position.x - tankwidth/2.0f, position.y - tankheight/2.0f, this.tankwidth, this.tankheight);
    this.reloading      = false;
    this.fireCooldown   = 3000; 
    this.health         = 3;    
    this.reloadTimer    = 0L;
  }

  // =================================================
  // ===  STATE CLASS
  // =================================================
  public class State {
    int nearestEnemyDistCategory; // 1=Close, 2=Medium, 3=Far/None
    int relativeEnemyDirection;   // 0=Far/None, 1=Front, 2=Right, 3=Left, 4=Back
    int agentOrientation;         // 0=East, 1=North, 2=West, 3=South
    boolean facingWall;
    boolean isReloading;
    boolean enemyInLOS;           // True if direct line of sight to an enemy


    State(int nearestEnemyDistCat, int relEnemyDirVal, int agentOrientVal, boolean facingWallVal, boolean isReloadingVal, boolean enemyInLOSVal) {
      this.nearestEnemyDistCategory = nearestEnemyDistCat;
      this.relativeEnemyDirection = relEnemyDirVal;
      this.agentOrientation = agentOrientVal;
      this.facingWall = facingWallVal;
      this.isReloading = isReloadingVal;
      this.enemyInLOS = enemyInLOSVal;
    }

    @Override
      public boolean equals(Object obj) {
      if (this == obj) return true;
      if (obj == null || getClass() != obj.getClass()) return false;
      State otherState = (State) obj;
      return
        nearestEnemyDistCategory == otherState.nearestEnemyDistCategory &&
        relativeEnemyDirection == otherState.relativeEnemyDirection &&
        agentOrientation == otherState.agentOrientation &&
        facingWall == otherState.facingWall &&
        isReloading == otherState.isReloading &&
        enemyInLOS == otherState.enemyInLOS;
    }

    @Override
      public int hashCode() {
      int result = 17;
      result = 31 * result + nearestEnemyDistCategory;
      result = 31 * result + relativeEnemyDirection;
      result = 31 * result + agentOrientation;
      result = 31 * result + (facingWall ? 1 : 0);
      result = 31 * result + (isReloading ? 1 : 0);
      result = 31 * result + (enemyInLOS ? 1 : 0);
      return result;
    }

    @Override
      public String toString() {
      String[] enOr = {"None", "Front", "Left", "Right", "Back"};
      String[] agOr = {"East", "South", "West", "North"};
      return "State{" +
        "facingWall=" + facingWall +
        ", isReloading=" + isReloading +
        ", enemyInLOS=" + enemyInLOS +
        ", nearestEnemyDistCategory=" + nearestEnemyDistCategory +
        ", relativeEnemyDirection=" + (relativeEnemyDirection >= 0 && relativeEnemyDirection < enOr.length ? enOr[relativeEnemyDirection] : "Invalid") +
        ", agentOrientation=" + (agentOrientation >= 0 && agentOrientation < agOr.length ? agOr[agentOrientation] : "Invalid") +
        '}';
    }
  }

  // =================================================
  // ===  END OF STATE CLASS
  // =================================================

  // =================================================
  // ===  MAIN METHODS
  // =================================================

  // MAIN TANK LOGIC
  void update() {
    if (team == null && !this.name.equals("ally")) 
      return;
    checkReloading();
    updateCollision(); 
    viewArea.updateViewArea(this.position.x, this.position.y, this.angle);
  }

  void action(String _action) {
    switch (_action) {
    case "move":
      moveForward();
      break;
    case "reverse": 
      moveBackward();
      break;
    case "rotateLeft":
      rotateLeft();
      break;
    case "rotateRight":
      rotateRight();
      break;
    case "stop":
      stopMoving();
      break;
    case "fire":
      fireCannon();
      break;
    }
  }

  // =================================================
  // ===  STATE COLLECTION AND HELPER METHODS
  // =================================================

  // Main method that collects the tanks state in the instance its called.
  State getCurrentState() {
    int nearestEnemyDistCat = findNearest("enemy");
    int relativeEnemyDir = 0;

    Tank nearestEnemyObj = getNearestEnemyObject(); 
    if (nearestEnemyObj != null && nearestEnemyObj.health > 0) {
        if (nearestEnemyDistCat < 3) {
            relativeEnemyDir = calculateDiscretizedRelativeAngle(nearestEnemyObj);
        }
    }

    int currentAgentOrientation = discretizeAgentAngle();
    boolean amIFacingWall = checkIfFacingWall(); 
    boolean doISeeEnemyInLOS = checkLineOfSightToNearestEnemy(); 

    State newState = new State(
      nearestEnemyDistCat,
      relativeEnemyDir,
      currentAgentOrientation,
      amIFacingWall,    
      this.reloading,
      doISeeEnemyInLOS  
    );
    //println(newState.toString()); 
    return newState;
  }


  // Helper to get the actual nearest enemy Tank object using placedPositions
  Tank getNearestEnemyObject() {
    float minDist = Float.MAX_VALUE;
    Tank closestEnemy = null;
    for (Sprite obj : placedPositions) {
      if (obj instanceof Tank && obj != this) {
        Tank enemyTank = (Tank) obj;
        float d = PVector.dist(this.position, enemyTank.position);
        if (d < minDist) {
          minDist = d;
          closestEnemy = enemyTank;
        }
      }
    }
    // Consider an enemy "found" if it's within a reasonable range, e.g., viewArea.viewLength * 1.5
    // Prevents LOS checks on extremely distant enemies.
    if (closestEnemy != null && minDist < viewArea.viewLength * 1.5) {
      return closestEnemy;
    }
    return null;
  }


  // Calculate discretized relative angle to an enemy
  // Returns: 0 = Enemy Far/None, 1 = Front, 2 = Right, 3 = Left, 4 = Back
  int calculateDiscretizedRelativeAngle(Tank enemyTank) {
    if (enemyTank == null) {
      return 0; // No enemy or enemy too far
    }

    PVector vectorToEnemy = PVector.sub(enemyTank.position, this.position);
    float angleToEnemy = vectorToEnemy.heading();

    float relativeAngle = angleToEnemy - this.angle;

    while (relativeAngle <= -PI) relativeAngle += TWO_PI;
    while (relativeAngle > PI) relativeAngle -= TWO_PI;

    float PI_4 = PI / 4.0f;
    float THREE_PI_4 = 3.0f * PI / 4.0f;

    if (abs(relativeAngle) <= PI_4) return 1; 
    else if (relativeAngle > PI_4 && relativeAngle <= THREE_PI_4) return 2; 
    else if (relativeAngle < -PI_4 && relativeAngle >= -THREE_PI_4) return 3; 
    else return 4;
  }


  // Calculate discretized relative agent angel in the world
  int discretizeAgentAngle() {
    float currentAngle = this.angle;

    while (currentAngle < 0) currentAngle += TWO_PI;
    while (currentAngle >= TWO_PI) currentAngle -= TWO_PI;

    float PI_4 = PI / 4.0f;
    float THREE_PI_4 = 3.0f * PI / 4.0f;
    float FIVE_PI_4 = 5.0f * PI / 4.0f;
    float SEVEN_PI_4 = 7.0f * PI / 4.0f;

    if (currentAngle >= SEVEN_PI_4 || currentAngle < PI_4) return 0; 
    else if (currentAngle >= PI_4 && currentAngle < THREE_PI_4) return 1; 
    else if (currentAngle >= THREE_PI_4 && currentAngle < FIVE_PI_4) return 2; 
    else return 3; 
  }


  // Finds nearest enemy and discretize it.
  // Returns: 3 = Far/Further away than 300, 2 = Middle/Closer than 300, 1 = Near/Closer than 150 
  int findNearest(String type) {
    float minDist = Float.MAX_VALUE;
    if (type.equals("enemy")) {
      for (Sprite obj : placedPositions) {
        if (obj instanceof Tank && obj != this) {
          Tank enemyTank = (Tank) obj;
          if (enemyTank.health > 0) {
            float d = PVector.dist(this.position, obj.position);
            if (d < minDist) minDist = d;
          }
        }
      }
    }

    if (minDist == Float.MAX_VALUE) return 3; 
    if (minDist < 150) return 1; 
    else if (minDist < 300) return 2; 
    else return 3; 
  }

  //Checks if the tank would move into a object or wall if it moved forward
  boolean checkIfFacingWall() {
    float stepDistance = maxspeed * 1.5f;
    float futureX = position.x + cos(angle) * stepDistance;
    float futureY = position.y + sin(angle) * stepDistance;

    
    float rX = tankwidth / 2.0f;
    float rY = tankheight / 2.0f;
    if (futureX <= rX || futureX >= width - rX || futureY <= rY || futureY >= height - rY) {
      return true;
    }

    
    Boundry futureBoundry = new Boundry(futureX - tankwidth / 2.0f, futureY - tankheight / 2.0f, tankwidth, tankheight);

    for (Sprite s : placedPositions) {
      if (s == this || s instanceof CannonBall) {
        continue;
      }
      if (futureBoundry.intersects(s.boundry)) {
        if (s instanceof Tree || (s instanceof Tank && s != this)) {
          return true;
        }
      }
    }
    return false;
  }

  // Checks if the tank has a straight line of sight to enemy within its viewArea and no other objects are infront of it.
  boolean checkLineOfSightToNearestEnemy() {
    Tank enemy = getNearestEnemyObject();
    if (enemy == null || enemy.health <= 0) {
      return false;
    }

    float rayStep = 5;
    float maxRayLength = viewArea.viewLength; 

    PVector rayOrigin = this.position.copy();
    float rayAngle = this.angle;

    for (float currentLength = 0; currentLength < maxRayLength; currentLength += rayStep) {
      float x = rayOrigin.x + cos(rayAngle) * currentLength;
      float y = rayOrigin.y + sin(rayAngle) * currentLength;
      PVector rayPoint = new PVector(x, y);

      if (x < 0 || x > width || y < 0 || y > height) {
        return false; // Ray went off screen
      }

      if (enemy.boundry.contains(rayPoint.x, rayPoint.y)) {
        return true; // Clear line of sight to this enemy
      }

      for (Sprite s : placedPositions) {
        if (s == this || s == enemy || s instanceof Landmine || s instanceof CannonBall) {
          continue;
        }
        if ((s instanceof Tree || (s instanceof Tank && s != enemy)) && s.boundry.contains(rayPoint.x, rayPoint.y)) {
          return false; // LOS is blocked by another object
        }
      }
    }
    return false; 
  }

  // =================================================
  // === END OF STATE COLLECTION AND HELPER METHODS
  // =================================================

  // IS RELOADING LOGIC
  void checkReloading() {
    if (reloadTimer == 0L) return;

    long now = System.currentTimeMillis();
    if (now - reloadTimer >= fireCooldown) { 
      reloading = false;
      reloadTimer = 0L;
    }
  }

  // UPDATE BOUNDRY TO MOVE WITH TANK
  void updateBoundry() {
    boundry.x = position.x - tankwidth / 2.0f;
    boundry.y = position.y - tankheight / 2.0f;
  }

  // CHECK IF TANK TOUCHES EDGE OF THE WORLD
  void checkBorders() {
    float rX = tankwidth / 2.0f;
    float rY = tankheight / 2.0f; 
    position.x = constrain(position.x, rX, width - rX);
    position.y = constrain(position.y, rY, height - rY);
    updateBoundry(); 
  }

  // COLLISION DETECTION
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

  boolean collisionAt(float x, float y) {
    
    Boundry candidateBoundry = new Boundry(x - tankwidth / 2.0f, y - tankheight / 2.0f, tankwidth, tankheight);

    for (Sprite s : placedPositions) {
      if (s == this || s instanceof Landmine || s instanceof CannonBall) {
        continue;
      }
      if ((s instanceof Tree || (s instanceof Tank && s != this)) && candidateBoundry.intersects(s.boundry)) {
        return true; 
      }
    }
    return false; 
  }


  // =================================================
  // ===  PERFORM ACTIONS HELPER METHODS
  // =================================================
  void moveForward() {
    this.velocity.x = cos(this.angle) * this.maxspeed;
    this.velocity.y = sin(this.angle) * this.maxspeed;
  }

  void moveBackward() {
    this.velocity.x = -cos(this.angle) * this.maxspeed;
    this.velocity.y = -sin(this.angle) * this.maxspeed;
  }

  void rotateLeft() {
    this.angle -= radians(3);
    while (this.angle < 0) this.angle += TWO_PI; // Normalize angle
  }

  void rotateRight() {
    this.angle += radians(3);
    while (this.angle >= TWO_PI) this.angle -= TWO_PI; // Normalize angle
  }

  void stopMoving() {
    this.velocity.x = 0;
    this.velocity.y = 0;
  }

  void fireCannon() {
    if (!reloading) {
      // "Fake" cannonball logic for immediate enemyHit check (global flag)
      CannonBall fake = new CannonBall(position.copy(), this.angle, this);
      boolean directHitPredicted = false;
      // Simulate steps up to view range or a bit beyond
      for(int i=0; i < viewArea.viewLength / fake.maxSpeed + 10; i++){ 
        fake.moveForward();
        for(Sprite obs : placedPositions){
          if(obs instanceof Tank && obs != this && ((Tank)obs).health > 0){
            if (obs.boundry.intersects(fake.boundry)){
              enemyHit = true; // Global flag from ENV_variables.pde
              directHitPredicted = true;
              break;
            }
          }
        }
        if(directHitPredicted || fake.position.x < 0 || fake.position.x > width || fake.position.y < 0 || fake.position.y > height) break;
      }
      
      CannonBall cannonBall = new CannonBall(position.copy(), this.angle, this);
      addCannonBall(cannonBall); 
      reloading = true;
      reloadTimer = System.currentTimeMillis();
    }
  }

  void reduceHealth() {

    if (health > 0) {
      health--;
      if(this.health == 0 && this.name.equals("enemy")){
        enemyDead = true; // Global flag from ENV_variables.pde
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
      
      
      float textBoxWidth = 100;
      float textBoxHeight = 50;
      float textBoxX = 40; 
      float textBoxY = -40; 
      rect(textBoxX, textBoxY, textBoxWidth, textBoxHeight);
      fill(30);
      textSize(12); 
      textAlign(LEFT, TOP); 
      String stateText = "";

      stateText = "RL";

      text(this.name + "\n(" + nf(this.position.x, 0, 1) + ", " + nf(this.position.y, 0, 1) + ")\nState: " + stateText, textBoxX + 5, textBoxY + 5);
      textAlign(CENTER, CENTER); 
    }
    popMatrix();
    boundry.draw(); 
    displayHealth();
    if (reloading) {
      displayReloadTimer(); 
    }
    if (debugMode) {
      drawViewArea(); 
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

  // ==================================================================================================
  void displayReloadTimer() {
    pushMatrix();
    translate(this.position.x, this.position.y);
    textSize(12);
    fill(0);
    text("Reloading!!", 25, 40);

    fill(255);
    rect(35, -25, 7, 50, 2);

    
    long now = System.currentTimeMillis();
    float progress = constrain((now - reloadTimer) / 3000.0, 0, 1);

    stroke(0);
    strokeWeight(2);
    float lineHeight = progress * 40;
    line(38, 20, 38, 20 - lineHeight);
    popMatrix();
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
