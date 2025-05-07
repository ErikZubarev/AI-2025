//Anton Lundqvist
//Erik Zubarev

// ==================================================================================================
void displayExplosions(){
  if(allExplosions.isEmpty()) 
    return;
  
  Iterator<Explosion> explIterator = allExplosions.iterator();

  while ( explIterator.hasNext()){
    Explosion e = explIterator.next();
    if(!e.isDone())
      e.display();
    else explIterator.remove();
  }
}

// ==================================================================================================
void displayCannonBalls() {
  for (CannonBall cannonBall : allCannonBalls) {
    cannonBall.display();
  }
}

// ==================================================================================================
void displayHomeBase() {
  team0.display();
  team1.display();
}

// ==================================================================================================
void displayTrees() {
  for (Tree tree : allTrees) {
    tree.display();
  }
}

// ==================================================================================================
void displayTanks() {
  for (Tank tank : allTanks) {
    tank.display();
    tank.drawViewArea();
  }
  //tank0.drawViewArea();
}

// ==================================================================================================
void displayMines() {
  for (Landmine mine : allMines) {
    mine.display();
  }
}

// ==================================================================================================
void displayGUI() {
  displayTimer();

  if (pause) {
    textSize(36);
    fill(30);
    text("...Paused! (\'p\'-continues)\n(up/down/left/right to move)\n('d' for debug)", width/1.7-150, height/2.5);
  }

  if (currentGameTimer >= 180) {
    textSize(36);
    fill(30);
    text("Time ran out!", width/2-150, height/3);
    gameOver = true;
  }

  if (gameOver) {
    textSize(36);
    fill(30);
    text("Game Over!", width/2-150, height/2);
  }
}

// ==================================================================================================
void displayTimer() {
  long min = floor(currentGameTimer/60);
  long sec = currentGameTimer % 60;
  String time = min + ":" + (sec < 10? "0"+sec : ""+sec);

  textSize(36);
  fill(30);
  text(time, width/2, 50);
}
