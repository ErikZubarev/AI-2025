//Anton Lundqvist
//Erik Zubarev
import java.util.HashSet;
import java.util.PriorityQueue;
import java.util.Comparator;
import java.util.List;
import java.util.Random;
import java.util.Iterator;

// GLOBAL VARIABLES =================================================================================
boolean left,
  right,
  up,
  down,
  mouse_pressed,

  debugMode,
  gameOver,
  pause,
  gameWon,
  enemyHit,
  enemyDead;

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
  dogExit,
  previousPosition;

int landmineCounter;

long startGameTimer,
  currentGameTimer,
  startPauseTimer,
  currentPauseTime,
  totalPauseTime,
  previousTime;

float alpha, 
      gamma, 
      eps;

String previousAction;
Tank.State previousState;

ArrayList<Landmine> allMines;
ArrayList<CannonBall> allCannonBalls;
ArrayList<Sprite> placedPositions;
ArrayList<Explosion> allExplosions;

HashMap<String, Float> eventsRewards;
HashMap<Integer, String> stats = new HashMap<>();

int statsEpochCounter = -1;
int stuckCounter;

QLearner qLearner;

Random random;

Tree tree0,
  tree1,
  tree2;

Tree[] allTrees;

// Team0
Tank tank0;

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

Heatmap qHeatmap;
