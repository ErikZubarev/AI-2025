//Anton Lundqvist
//Erik Zubarev
class Team {
  ArrayList<Tank> members = new ArrayList<>();
  ArrayList<Tank> currentlyHome = new ArrayList();
  ArrayList<Tank> enemyQueue = new ArrayList<>();
  color teamColor;
  int x, y;
  Boundry boundry;

  public Team(int x, int y, color teamColor) {
    this.x = x;
    this.y = y;
    this.teamColor = teamColor;
    this.boundry = new Boundry(x, y, 150, 350);
  }
  

  void display() {
    pushMatrix();
    strokeWeight(1);
    stroke(0);
    fill(teamColor, 100);
    rect(x, y, 150, 350);
    popMatrix();
  }
}
