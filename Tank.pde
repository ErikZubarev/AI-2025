class Tank extends Sprite {
  PVector velocity;
  PVector startpos;
  String name;
  PImage img;
  int tankwidth;
  int tankheight;
  float speed;
  float maxspeed;
  float angle;
  int state;
  boolean isInTransition;
  
  QuadTreeMemory memory;
  ViewArea viewArea;
  
  //======================================  
  Tank(String _name, PVector _startpos, PImage sprite ) {
    this.name         = _name;
    this.tankwidth    = sprite.width;
    this.tankheight   = sprite.height;
    this.img          = sprite;

    this.startpos     = new PVector(_startpos.x, _startpos.y);
    position          = new PVector(this.startpos.x, this.startpos.y);
    this.velocity     = new PVector(0, 0);
    this.angle        = 0;

    this.state        = 0; //0(still), 1(moving)
    this.maxspeed     = 2;
    this.isInTransition = false;
    this.memory       = new QuadTreeMemory(new Boundry(0,0,800,800), 6); // (0,0) start position to (800,800) px play area, depth of 5 -> minimum 25 x 25 px grid area
    this.viewArea     = new ViewArea(position.x, position.y, angle);
    boundry           = new Boundry(position.x - tankheight/2, position.y  - tankheight/2, this.tankheight, this.tankheight);
  }
  
  //======================================
  void detectObject(){
    for(Sprite obj : placedPositions){
      if(viewArea.intersects(obj.boundry)){
        if(obj != this){
          memory.insert(obj);
        }
      }
    }
    memory.updateExploredStatus(viewArea);
  }
    
  void updateBoundry() {
    boundry.x = position.x - tankheight / 2;
    boundry.y = position.y - tankheight / 2;
  }
  
  void borgars() {
    float r = tankwidth / 2;  // Half of tank width to keep it within bounds

    position.x = constrain(position.x, r, width - r);
    position.y = constrain(position.y, r, height - r);
  }
  
  void updateCollision(){
    float candidateX = position.x + velocity.x;
    float candidateY = position.y + velocity.y;
    
    if(!collisionAt(candidateX, position.y)){
      position.x = candidateX;
    }
    
    if(!collisionAt(position.x, candidateY)){
      position.y = candidateY; 
    }
  }
  
  boolean collisionAt(float x, float y){
    PVector candidate = new PVector(x,y);
    PVector backup = position.copy();
    position.set(candidate);
    updateBoundry();
    
    for (Sprite s : placedPositions) {
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
  
  
  //======================================
  void moveForward() {
      this.velocity.x = cos(this.angle) * this.maxspeed; 
      this.velocity.y = sin(this.angle) * this.maxspeed; 
      
  }

  void moveBackward() {
      this.velocity.x = -cos(this.angle) * this.maxspeed; 
      this.velocity.y = -sin(this.angle) * this.maxspeed;
      
  }

    void rotateLeft() {
      this.angle -= radians(5); 
      
  }

  void rotateRight() {
      this.angle += radians(5); 
      
  }
  
  void stopMoving() {
      this.velocity.x = 0;
      this.velocity.y = 0;
  }

  //======================================
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
      }
  }
  
  //======================================
  void update() {
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
    borgars();
  }

  //====================================== 
  void display() {
    pushMatrix();
      translate(this.position.x, this.position.y);
      drawTank(0, 0);
      if(debugMode){
        fill(230);
        stroke(0);
        strokeWeight(1);
        rect(0+40, 0-40, 100, 40);
        fill(30);
        textSize(15);
        text(this.name +"\n( " + this.position.x + ", " + this.position.y + " )", 40+5, -20-5);
      }
    popMatrix();
    boundry.draw();
  }
  
  void drawTank(float x, float y) {
    pushMatrix();
      strokeWeight(0);
      translate(x, y);
      rotate(this.angle); // Apply rotation
      imageMode(CENTER);
      image(img, x, y);
      imageMode(CORNER);
    popMatrix();
  }
  
  void drawViewArea(){
    viewArea.drawArea(this);
  }
  
  // INNER CLASS VIEWAREA =============================================================================
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
  
  
      float relX_TR = +halfL; float relY_TR = -halfW;
      corners[0] = new PVector(centerX + relX_TR * cosA - relY_TR * sinA,
                               centerY + relX_TR * sinA + relY_TR * cosA);
      // Top-Left Corner
      float relX_TL = +halfL; float relY_TL = +halfW;
      corners[1] = new PVector(centerX + relX_TL * cosA - relY_TL * sinA,
                               centerY + relX_TL * sinA + relY_TL * cosA);
      // Bottom-Left Corner
      float relX_BL = -halfL; float relY_BL = +halfW;
      corners[2] = new PVector(centerX + relX_BL * cosA - relY_BL * sinA,
                               centerY + relX_BL * sinA + relY_BL * cosA);
      // Bottom-Right Corner
      float relX_BR = -halfL; float relY_BR = -halfW;
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
  
      if(debugMode){
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
