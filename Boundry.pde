//Anton Lundqvist
//Erik Zubarev
class Boundry {
  float x, y, width, height;

  Boundry(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.height = h;
    this.width = w;
  }

  // ==================================================================================================
  boolean intersects(Boundry other) {
    return !(
      this.x + this.width < other.x ||
      this.x > other.x + other.width ||
      this.y + this.height < other.y ||
      this.y > other.y + other.height);
  }

  // ==================================================================================================
  boolean isWithin(Boundry other) {
    return (
      this.x >= other.x &&
      this.x + this.width <= other.x + other.width &&
      this.y >= other.y &&
      this.y + this.height <= other.y + other.height
      );
  }

  boolean contains(float px, float py) {
  return (px >= this.x && px <= this.x + this.width &&
          py >= this.y && py <= this.y + this.height);
  }

  // ==================================================================================================
  void draw() {
    if (debugMode) {
      pushMatrix();
      strokeWeight(1);
      fill(255, 0, 255, 100);
      rect(x, y, width, height);
      popMatrix();
    }
  }
}
