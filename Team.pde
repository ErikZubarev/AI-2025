class Team {
  color team0Color, team1Color;

  Team(color team0Color, color team1Color) {
    this.team0Color = team0Color;
    this.team1Color = team1Color;
  }

  void displayHomeBase() {
    strokeWeight(1);

    fill(team0Color, 15);    // Base Team 0 (red)
    rect(0, 0, 150, 350);

    fill(team1Color, 15);    // Base Team 1 (blue)
    rect(width - 151, height - 351, 150, 350);
  }
  
  void display() {
    displayHomeBase();
  }
}
