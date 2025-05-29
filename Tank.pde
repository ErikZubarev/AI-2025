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
    reloading,
    immobilized,
    hunt;
  ViewArea viewArea;
  Team team;
  HashSet<Sprite> foundObjects;


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
    this.boundry        = new Boundry(position.x - tankheight/2, position.y - tankheight/2, this.tankheight, this.tankheight);
    this.reloading      = false;
    this.fireCooldown   = 3000;
    this.health         = 3;
    this.reloadTimer    = 0L;
    this.immobilized    = false;
    this.hunt           = false;
    this.foundObjects   = new HashSet<Sprite>();
  }

  // =================================================
  // ===  MAIN METHODS
  // =================================================

  // MAIN TANK LOGIC ==================================================================================
  void update() {
    if(team == null)
      return;
      
    checkReloading();
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
    case "fire":
      fireCannon();
      break;
    }
  }
  
  State getCurrentState(){
    return new State(
      position.copy(),
      angle,
      health,
      findNearest("enemy"),
      findNearest("tree"),
      findNearest("landmine")
    );
  }

  float findNearest(String type) {
    float minDist = Float.MAX_VALUE;
    for (Sprite obj : foundObjects) {
      if (type.equals("enemy") && obj instanceof Tank) {
        float d = PVector.dist(this.position, obj.position);
        if (d < minDist) minDist = d;
      } else if (type.equals("tree") && obj instanceof Tree) {
        float d = PVector.dist(this.position, obj.position);
        if (d < minDist) minDist = d;
      } else if (type.equals("landmine") && obj instanceof Landmine) {
        float d = PVector.dist(this.position, obj.position);
        if (d < minDist) minDist = d;
      }
    }
    return minDist;
  }
  

  // TANK VISION SENSOR ==================================================================================
  void detectObject() {
    for (Sprite obj : placedPositions) {
      if (viewArea.intersects(obj.boundry) && obj != this) {
        foundObjects.add(obj);
      }
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
      CannonBall fake = new CannonBall(position.copy(), this.angle, this);
      do{
        fake.moveForward();
        for(Sprite obs : placedPositions){
          if(obs instanceof Tank && (Tank)obs != this && obs.boundry.intersects(fake.boundry)){
            enemyHit = true;
          }
        }
      } while (!enemyHit && fake.position.x >= 0 && fake.position.x <= 800 && fake.position.y >= 0 && fake.position.y <= 800);
      CannonBall cannonBall = new CannonBall(position.copy(), this.angle, this);
      addCannonBall(cannonBall);
      reloading = true;
      reloadTimer = System.currentTimeMillis();
    }
  }

  // ==================================================================================================
  void reduceHealth() {

    if(this.name == "ally"){
      agentDamaged = true;
    }

    if (health == 2) {
      immobilized = true;
    }

    if (health != 0) {
      health--;
    }

    if(this.health == 0 && this.name.equals("enemy")){
      enemyIsDeadNotBigSuprise = true;  
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
      
      if (hunt) stateText = "Hunting";
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
    if (debugMode) {
      drawViewArea(); // Draw view area in debug mode
      // Draw path in debug mode (can be for any path, not just home)
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
  // =================================================
  // ===  INNER CLASS STATE
  // =================================================
  public class State {
    PVector tankPosition;
    float tankRotation,
          nearestEnemy, 
          nearestTree, 
          nearestLandmine;
    int tankHealth, 
        remainingEnemies, 
        timeRemaining;

    
    State(PVector pos, float rot, int hp, float nearestEnemy, float nearestTree, float nearestLandmine){
      tankPosition = pos;
      tankRotation = rot;
      tankHealth = hp;
      this.nearestEnemy  = nearestEnemy;
      this.nearestTree = nearestTree;
      this.nearestLandmine = nearestLandmine;
      timeRemaining = 180 - ((int) currentGameTimer); // 3 minutes - current time
      
      remainingEnemies = 0;
      for(Tank enemy : allTanks){
        if(enemy.name == "enemy")
          remainingEnemies++;
      }
      
    }
  
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
