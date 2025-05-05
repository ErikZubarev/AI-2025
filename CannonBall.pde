//Anton Lundqvist
//Erik Zubarev

class CannonBall extends Sprite {
  PVector velocity, startPos;
  PImage img;
  int width, height;
  float maxSpeed, angle;
  Tank shooter;
  long timer;

  // ==================================================================================================
  CannonBall(PVector startPos, float angle, Tank shooter) {
    this.startPos = startPos;
    this.angle = angle;
    this.maxSpeed = 10;
    this.position = startPos.copy();
    this.velocity = new PVector(
      cos(this.angle) * this.maxSpeed,
      sin(this.angle) * this.maxSpeed
      );
    //Use this one when we change to sprite instead of test ball
    //boundry        = new Boundry(startPos.x - _image.width/2, startPos.y - _image.height/2, _image.width, _image.height);
    boundry        = new Boundry(startPos.x - 20, startPos.y - 20, 20, 20);
    this.shooter = shooter;
    timer = System.currentTimeMillis();
  }

  // ==================================================================================================
  void moveForward() {
    this.position.add(this.velocity);
    //Update boundry, use image height and width instead of 20
    boundry.x = position.x - 20 / 2;
    boundry.y = position.y - 20 / 2;
  }

  // ==================================================================================================
  void display() {
    pushMatrix();
      translate(position.x, position.y);
      rotate(this.angle);
      imageMode(CENTER);
      image(bomb, 0, 0);
      imageMode(CORNER);
    popMatrix();
  }

  //This is a explostion for when the ball contacts something. currently its only show for like one frame lol
  void drawExplosion() {      
    Explosion e = new Explosion(position.x, position.y);
    allExplosions.add(e);
  }
}
