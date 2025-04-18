class Boundry{
  float x, y, width, height;
  
  Boundry(float x, float y, float w, float h){
    this.x = x;
    this.y = y;
    this.height = h;
    this.width = w;
  }
  
  boolean intersects(Boundry other){
    return !(
      this.x + this.width < other.x ||
      this.x > other.x + other.width ||
      this.y + this.height < other.y ||
      this.y > other.y + other.height);
  }
  
  boolean isWithin(Boundry other){
    return (
      this.x >= other.x &&
      this.x + this.width <= other.x + other.width &&
      this.y >= other.y &&
      this.y + this.height <= other.y + other.height 
    );
  }

  void draw(){
    pushMatrix();
    rectMode(CENTER);
    fill(255, 0, 255, 100);
    rect(x,y, height,width);
    strokeWeight(1);
    rectMode(CORNER);
    popMatrix();
  }
}
