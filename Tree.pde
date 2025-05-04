//Anton Lundqvist
//Erik Zubarev
class Tree extends Sprite {

  String  name;
  PImage  img;
  float   diameter;

  //**************************************************
  Tree(PImage _image, float _posx, float _posy) {

    this.img       = _image;
    boundry        = new Boundry(_posx - _image.width/2, _posy - _image.height/2, _image.width, _image.height);
    this.name      = "tree";
    position       = new PVector(_posx, _posy);
  }

  //**************************************************
  void display() {
    imageMode(CENTER);
    image(img, position.x, position.y);
    imageMode(CORNER);
    boundry.draw();
  }
}
