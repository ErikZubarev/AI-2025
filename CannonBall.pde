//Anton Lundqvist
//Erik Zubarev

class CannonBall extends Sprite {
  PVector velocity, startPos;
  PImage img;
  int width, height;
  float maxSpeed, angle;
  Tank shooter;

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
  }

  void moveForward() {
    // Update position by adding velocity
    this.position.add(this.velocity);
    //Update boundry, use image height and width instead of 20
    boundry.x = position.x - 20 / 2;
    boundry.y = position.y - 20 / 2;
  }

  void display() {
    fill(0);
    noStroke();
    ellipse(position.x, position.y, 20, 20);
  }

  //This is a explostion for when the ball contacts something. currently its only show for like one frame lol
  void drawExplosion() {
    noFill();
    stroke(255, 165, 0); // Orange color
    strokeWeight(2);
    ellipse(position.x, position.y, 30, 30); // Slightly larger than the ellipse
  }
}
