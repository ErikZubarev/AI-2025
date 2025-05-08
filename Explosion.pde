//Anton Lundqvist
//Erik Zubarev
class Explosion {
  float x,
    y;
  long iteration;
  int displayLength;

  Explosion(float x, float y) {
    this.x = x;
    this.y = y;
    this.iteration = 1;
    this.displayLength = 25;
  }

  boolean isDone() {
    return !(++iteration < displayLength);
  }

  void display() {
    int i = floor((iteration * (explosionImages.length)) /  displayLength);
    PImage img = explosionImages[i];
    pushMatrix();
    translate(x, y);
    imageMode(CENTER);
    image(img, 0, 0);
    imageMode(CORNER);
    popMatrix();
  }
}
