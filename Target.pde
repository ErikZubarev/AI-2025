//Helper class for handling grouped movement when using Search with multiple tanks. Prevents collisions during movement.
class Target extends Sprite {
  Tank owner;

  Target(PVector position, Tank owner) {
    this.position = position.copy();
    this.boundry = new Boundry(position.x - owner.tankwidth / 2, position.y - owner.tankheight / 2, owner.tankwidth, owner.tankheight);
    this.owner = owner;
  }
}