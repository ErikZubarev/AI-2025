class Explosion{
  float x,
        y;
  long iteration;
  int displayLength;
        
  Explosion(float x, float y){
    this.x = x;
    this.y = y;
    this.iteration = 1;
    this.displayLength = 100;
  }
  
  boolean isDone(){
    return !(iteration++ < displayLength);
  }
  
  void display(){
    int i = floor((iteration / displayLength) * explosionImages.length);

    PImage img = explosionImages[i];
    pushMatrix();
      translate(x,y);
      imageMode(CENTER);
      image(img, 0,0);
      imageMode(CORNER);
    popMatrix();

  }
}
