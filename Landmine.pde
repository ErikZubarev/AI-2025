class Landmine extends Sprite{
  String  name; 
  PImage  img;
  float   diameter;
  
  //**************************************************
  Landmine(PImage _image, PVector pos) {
    
    this.img       = _image;
    position  = pos;
    
  }

  //**************************************************
  
  void checkCollision() {
    
  }

  //**************************************************  
  void display() {
      imageMode(CENTER);
      image(img, position.x, position.y);
      imageMode(CORNER);
  }
}
