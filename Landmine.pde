class Landmine extends Sprite{
  String  name; 
  PImage  img;
  float   diameter;
  
  //**************************************************
  Landmine(PImage _image, PVector pos) {
    
    this.img       = _image;
    position       = pos;
    boundry       = new Boundry(position.x - _image.width/2, position.y - _image.height/2, img.width, img.height);
    
  }

  //**************************************************
  
  void checkCollision() {
    
  }

  //**************************************************  
  void display() {
    imageMode(CENTER);
    image(img, position.x, position.y);
    boundry.draw();
    imageMode(CORNER);
  }
}
