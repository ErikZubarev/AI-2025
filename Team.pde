//Anton Lundqvist
//Erik Zubarev
class Team {
  ArrayList<Tank> members = new ArrayList<>();
  ArrayList<Tank> currentlyHome = new ArrayList<>();
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
  
  void removeEnemy(Tank t){
    enemyQueue.remove(t);  
    sortQueue();
  }
  
  boolean isQueueEmpty(){
     return enemyQueue.isEmpty();
  }
  
  void addEnemyToQueue(Tank enemy){
    if(!enemyQueue.contains(enemy)){
      enemyQueue.add(enemy);
      sortQueue();
    }
  }
  
  void sortQueue(){
    PVector baseCenter = new PVector(x + 75, y + 175); // Center of the base
    enemyQueue.sort((a, b) -> {
      float distA = a.position.dist(baseCenter);
      float distB = b.position.dist(baseCenter);
      return Float.compare(distA, distB);
    });
  }
  
  void setReported(){
    for(Tank t : members){
      t.reported = true;
    }
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
