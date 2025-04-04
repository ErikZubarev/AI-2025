class Team {
  
  void displayHomeBase() {
    strokeWeight(1);

    fill(color(204, 50, 50), 15);    // Base Team 0 (red)
    rect(0, 0, 150, 350);

    fill(color(0, 150, 200), 15);    // Base Team 1 (blue)
    rect(width - 151, height - 351, 150, 350);
  }
  
  void display() {
    displayHomeBase();
  }
}
