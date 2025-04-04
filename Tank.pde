class Tank extends Sprite {

  PVector velocity;
  PVector position;
  
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
    println("*** Tank.Tank()");
    this.name         = _name;
    this.tankwidth    = sprite.width;
    this.tankheight   = sprite.height;
    this.img          = sprite;

    this.startpos     = new PVector(_startpos.x, _startpos.y);
    this.position     = new PVector(this.startpos.x, this.startpos.y);
    this.velocity     = new PVector(0, 0);
    this.angle        = 0;

    this.state        = 0; //0(still), 1(moving)
    this.maxspeed     = 2;
    this.isInTransition = false;
    this.memory       = new QuadTreeMemory(0,0,800,800); // (0,0) start position to (800,800) px play area
    this.viewArea     = new ViewArea(position.x, position.y, angle);
  }
  
  //======================================
  

  
  void detectObject(){
    
  }
  
  void checkEnvironment() {
    println("*** Tank.checkEnvironment()");
    
    borgars();
  }
  
  void checkForCollisions(Sprite sprite) {
    
  }
  
  void checkForCollisions(PVector vec) {
    checkEnvironment();
  }
  
  // Följande är bara ett exempel
  void borgars() {
    //Code for wrap-around borders
    //float r = tankwidth;
    //if (position.x < -r) position.x = width+r;
    //if (position.y < -r) position.y = height+r;
    //if (position.x > width+r) position.x = -r;
    //if (position.y > height+r) position.y = -r;
    
    //Code for hard borders
    float r = tankwidth / 2;  // Half of tank width to keep it within bounds

    position.x = constrain(position.x, r, width - r);
    position.y = constrain(position.y, r, height - r);
  }
  
  
  //======================================
  void moveForward() {
      println("*** Tank.moveForward()");
      this.velocity.x = cos(this.angle) * this.maxspeed; 
      this.velocity.y = sin(this.angle) * this.maxspeed; 
      viewArea.updateViewArea(this.position.x, this.position.y, this.angle);
  }

  void moveBackward() {
      println("*** Tank.moveBackward()");
      this.velocity.x = -cos(this.angle) * this.maxspeed; 
      this.velocity.y = -sin(this.angle) * this.maxspeed;
      viewArea.updateViewArea(this.position.x, this.position.y, this.angle);
  }

    void rotateLeft() {
      println("*** Tank.rotateLeft()");
      this.angle -= radians(5); 
      viewArea.updateViewArea(this.position.x, this.position.y, this.angle);
  }

  void rotateRight() {
      println("*** Tank.rotateRight()");
      this.angle += radians(5); 
      viewArea.updateViewArea(this.position.x, this.position.y, this.angle);
  }
  
  void stopMoving() {
      println("*** Tank.stopMoving()");
      this.velocity.x = 0;
      this.velocity.y = 0;
  }

  //======================================
  void action(String _action) {
      println("*** Tank.action()");

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
  //Här är det tänkt att agenten har möjlighet till egna val. 
  
  void update() {
    println("*** Tank.update()");
    
    switch (state) {
      case 0:
        // still/idle
        action("stop");
        break;
      case 1:
        action("move");
        break;
      case 2:
        action("reverse");
        
        break;
    }
    
    this.position.add(velocity);
  }
  
  //====================================== 
  void drawTank(float x, float y) {
      //fill(this.col, 50); 

      pushMatrix();
      translate(x, y);
      rotate(this.angle); // Apply rotation
      
      imageMode(CENTER);
      image(img, x, y);

      //ellipse(0, 0, 50, 50);
      //strokeWeight(1);
      //line(0, 0, 25, 0); // Cannon direction

      //// Cannon turret
      //ellipse(0, 0, 25, 25);
      //strokeWeight(3);   
      //float cannon_length = this.diameter / 2;
      //line(0, 0, cannon_length, 0);

      popMatrix();
  }
  
  void display() {
    
    pushMatrix();
    
      translate(this.position.x, this.position.y);
      
      imageMode(CENTER);
      drawTank(0, 0);
      imageMode(CORNER);
      
      strokeWeight(1);
      fill(230);
      rect(0+40, 0-40, 100, 40);
      fill(30);
      textSize(15);
      text(this.name +"\n( " + this.position.x + ", " + this.position.y + " )", 40+5, -20-5);
      
      viewArea.drawArea();
    
    popMatrix();
  }
  
  class ViewArea {
    float x, y; 
    float width = 100; 
    float height = 200;
    float angle;

    public ViewArea(float x, float y, float angle) {
        this.x = x;
        this.y = y;
        this.angle = angle;
    }

    public void updateViewArea(float agentX, float agentY, float agentAngle) {
        this.x = agentX + cos(agentAngle) * (height / 2); 
        this.y = agentY + sin(agentAngle) * (height / 2);  
        this.angle = agentAngle; 
    }
    
    void drawArea() {
      pushMatrix();

        rotate(this.angle);
        rect(x,y, height,width);
        strokeWeight(1);
        
      popMatrix();
  }
}

}
