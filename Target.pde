//Helper class for handling grouped movement when using Search with multiple tanks. Prevents collisions during movement.
class Target extends Sprite {
  Tank owner;

  Target(PVector position, Tank owner) {
    this.position = position.copy();
    this.boundry = new Boundry(position.x - 20 / 2, position.y - 20 / 2, 20, 20);
    this.owner = owner;
  }
}