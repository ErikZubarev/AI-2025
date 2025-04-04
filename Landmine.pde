class Landmine extends Sprite{
  PVector position;
  String  name; 
  PImage  img;
  float   diameter;
  
  //**************************************************
  Landmine(PImage _image, PVector pos) {
    
    this.img       = _image;
    this.position  = pos;
    
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
