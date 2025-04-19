class Tree extends Sprite {
  
  String  name; 
  PImage  img;
  float   diameter;
  
  //**************************************************
  Tree(PImage _image, float _posx, float _posy) {
    
    this.img       = _image;
    boundry       = new Boundry(_posx, _posy, _image.width,  _image.height);
    this.name      = "tree";
    position       = new PVector(_posx, _posy);
    
  }

  //**************************************************
  
  void checkCollision() {
    
  }

  //**************************************************  
  void display() {

      image(img, position.x, position.y);
      boundry.draw();
  }
}
