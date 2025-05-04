//Anton Lundqvist
//Erik Zubarev
class Tank extends Sprite {
  PVector velocity;
  PVector startpos;
  String name;
  PImage img;
  int tankwidth, tankheight, state, currentWaypointIndex;
  float speed, maxspeed, angle;
  boolean isInTransition, goHome, reported, reloading;
  QuadTreeMemory memory;
  ViewArea viewArea;
  ArrayList<PVector> currentPath;
  int lastFired = 0;
  int fireCooldown = 3000;
  int health = 3;
  boolean immobilized = false;
  long reportTimer = 0L;
  long reloadTimer = 0L;
  

  //*****Uncomment and comment the below lines to change between GBFS and BFS
  GBFS solver;
  //BFS solver;

  Tank(String _name, PVector _startpos, PImage sprite) {
    this.name         = _name;
    this.tankwidth    = sprite.width;
    this.tankheight   = sprite.height;
    this.img          = sprite;
    this.startpos     = new PVector(_startpos.x, _startpos.y);
    this.position     = new PVector(this.startpos.x, this.startpos.y);
    this.velocity     = new PVector(0, 0);
    this.angle        = 0;
    this.state        = 0;
    this.maxspeed     = 2;
    this.isInTransition = false;
    this.memory       = new QuadTreeMemory(new Boundry(0, 0, 800, 800), 6);
    this.viewArea     = new ViewArea(position.x, position.y, angle);
    this.boundry      = new Boundry(position.x - tankheight/2, position.y - tankheight/2, this.tankheight, this.tankheight);
    this.goHome       = false;
    this.reported     = false;
    this.reloading    = false;
  }
  
  void putBaseIntoMemory(){
    Boundry base = new Boundry(0, 0, 150, 350);
    Boundry pos = new Boundry(startpos.x, startpos.y, 1, 1);
    
    if(!pos.isWithin(base)){
      base = new Boundry(width - 151, height - 351, 150, 350);
    }
    
    memory.updateExploredStatus(base);
    for (Sprite obj : placedPositions) {
      if (base.intersects(obj.boundry) && obj != this) {
        if(name=="player") println(base.intersects(obj.boundry));
        memory.insert(obj); 
      }
    }
    memory.pruneChildren(base);
  }

  void detectObject() {
    for (Sprite obj : placedPositions) {
      if (viewArea.intersects(obj.boundry)) {
        if (obj != this) {
          if (obj instanceof Landmine && goHome) { //Dynamically check if a landmine appeared
            ArrayList<Sprite> foundObjects = memory.query(obj.boundry);
            boolean alreadyKnown = foundObjects.contains(obj);
            //Its a unknown mine so we add it to memory and recalculate path
            if (!alreadyKnown) {
              println("New landmine detected!");
              memory.insert(obj);
              calculatePath();
              return;
            }
          }
          if (obj instanceof Tank && !goHome && !reported) {
            Tank tank = (Tank) obj;
            if (tank.name.equals("enemy")) {
              println("Enemy Found!!");
              goHome();
            }
          }
          memory.insert(obj);
        }
      }
    }
    memory.updateExploredStatus(viewArea);
    memory.pruneChildren(viewArea);

  }

  void goHome() {
    if (!goHome) {
      goHome = true;
      calculatePath();
    }
  }

  void calculatePath() {
    //*****Uncomment and comment the below lines to change between GBFS and BFS
    solver = new GBFS(position, startpos, memory, boundry);
    //solver = new BFS(position, startpos, memory, boundry);
    currentPath = solver.solve();
    currentWaypointIndex = 0;
  }

  //Helper method for calculating movement during pathing
  void moveTowards(PVector target) {
    float targetAngle = atan2(target.y - position.y, target.x - position.x);
    float angleDifference = atan2(sin(targetAngle - angle), cos(targetAngle - angle));
    if (abs(angleDifference) > radians(5)) {
      if (angleDifference > 0) {
        angle += radians(5);
      } else {
        angle -= radians(5);
      }
      velocity.set(0, 0);
    } else {
      velocity.set(cos(angle) * maxspeed, sin(angle) * maxspeed);
    }
  }

  void update() {

    if(reportTimer != 0L){
      displayReportTimer();
      long now = System.currentTimeMillis();
      if(now - reportTimer >= 3000){
        reported = true;
        reportTimer = 0L;
      }
    }

    if(reloadTimer != 0L){
      long now = System.currentTimeMillis();
      if(now - reloadTimer >= 3000){
        reloading = false;
        reloadTimer = 0L;
      }
    }

    if (goHome && currentPath != null && currentWaypointIndex < currentPath.size()) {
      PVector waypoint = currentPath.get(currentWaypointIndex);
      moveTowards(waypoint);
    } else {
      switch (state) {
      case 0:
        velocity.set(0, 0);
        break;
      case 1:
        velocity.set(cos(angle) * maxspeed, sin(angle) * maxspeed);
        break;
      case 2:
        velocity.set(-cos(angle) * maxspeed, -sin(angle) * maxspeed);
        break;
      }
    }

    updateCollision();
    
    if (goHome && currentPath != null && currentWaypointIndex < currentPath.size()) {
      PVector waypoint = currentPath.get(currentWaypointIndex);
      if (position.dist(waypoint) < 7) {
        currentWaypointIndex++;
        if (currentWaypointIndex >= currentPath.size()) {
          reportTimer = System.currentTimeMillis();
          goHome = false;
          velocity.set(0, 0);
        }
      }
    }
    
    viewArea.updateViewArea(this.position.x, this.position.y, this.angle);
    borgars();
  }

  void updateBoundry() {
    boundry.x = position.x - tankheight / 2;
    boundry.y = position.y - tankheight / 2;
  }

  void borgars() {
    float r = tankwidth / 2;
    position.x = constrain(position.x, r, width - r);
    position.y = constrain(position.y, r, height - r);
  }

  void updateCollision() {
    float candidateX = position.x + velocity.x;
    float candidateY = position.y + velocity.y;
    if (!collisionAt(candidateX, position.y)) {
      position.x = candidateX;
    }
    if (!collisionAt(position.x, candidateY)) {
      position.y = candidateY;
    }
  }

  boolean collisionAt(float x, float y) {
    PVector candidate = new PVector(x, y);
    PVector backup = position.copy();
    position.set(candidate);
    updateBoundry();
    for (Sprite s : placedPositions) {
      if(s instanceof Landmine)
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
  }

  void rotateRight() {
    this.angle += radians(3);
  }

  void stopMoving() {
    this.velocity.x = 0;
    this.velocity.y = 0;
  }

  //Fires cannon via creating cannoball refersnce and passing to Enviroment to keep track of
  //Only keeps track of timing for when it next can shoot via milis()
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

  //Recudes health. when tank is hit it reduces health. if its hit and has 2 hp i.e its about to take its second hit we immobalize it
  void reduceHealth() {
    if (health == 2) {
      immobilized = true;
    }
    
    if (health != 0){
      health--;
    }
  }

  //added some if statements for the movement so if the are immobalized the cant move but still rotate for shooting.
  //if health drops to zero it can rotate anymore.
  void action(String _action) {
    switch (_action) {
    case "move":
      if (!immobilized)
        moveForward();
      else
        println("Taken too much damage!");

      break;
    case "reverse":
      if (!immobilized)
        moveBackward();
      else
        println("Taken too much damage!");

      break;
    case "rotateLeft":
      if (health > 0)
        rotateLeft();
      else
        println("Dead!");

      break;
    case "rotateRight":
      if (health > 0)
        rotateRight();
      else
        println("Dead!");

      break;
    case "stop":
      stopMoving();
      break;
    }
  }
  
  // =================================================
  // ===  DISPLAY / DRAW METHODS                   ===
  // =================================================
  void displayReportTimer(){
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

  void displayReloadTimer(){
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
    if(reloading){
      displayReloadTimer();
    }
  }

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



  void displayHealth() {
    
    float x = position.x - tankwidth / 2 - 10;
    float y = position.y - tankheight / 2 - 30;
    image(healthImages[health], x, y);

  }

  void drawViewArea() {
    viewArea.drawArea(this);
  }


  // =================================================
  // ===  INNER CLASS                              ===
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


    void drawArea(Tank t) {
      float agentX = position.x;
      float agentY = position.y;
      float centerX = agentX + cos(this.viewAngle) * (this.viewLength / 2.0);
      float centerY = agentY + sin(this.viewAngle) * (this.viewLength / 2.0);

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
