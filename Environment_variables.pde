//Anton Lundqvist
//Erik Zubarev

// GLOBAL VARIABLES =================================================================================
boolean left,
  right,
  up,
  down,
  mouse_pressed,

  debugMode,
  gameOver,
  pause;

PImage tree_img,
  blue_tank_img,
  red_tank_img,
  bomb,
  landmineImg;

PImage[] healthImages,
  runningFrames,
  laughingFrames,
  explosionImages;

PVector tree1_pos,
  tree2_pos,
  tree3_pos,

  team0_tank0_startpos,
  team0_tank1_startpos,
  team0_tank2_startpos,

  team1_tank0_startpos,
  team1_tank1_startpos,
  team1_tank2_startpos,

  newLandMinePos,
  dogExit;

int landmineCounter;

long startGameTimer,
  currentGameTimer,
  startPauseTimer,
  currentPauseTime,
  totalPauseTime;


ArrayList<Landmine> allMines;
ArrayList<CannonBall> allCannonBalls;
ArrayList<Sprite> placedPositions;
ArrayList<Explosion> allExplosions;

Random random;

Tree tree0,
  tree1,
  tree2;

Tree[] allTrees;

// Team0
Tank tank0,
  tank1,
  tank2;

// Team1
Tank tank3,
  tank4,
  tank5;

Team team0,
  team1;

Tank[] allTanks;

//Landmine assets
enum DogState {
  ENTERING, RUNNING_TO_TARGET, LAUGHING, EXITING
}

DogState dogState;

Dog dog;
