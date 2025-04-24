//Anton Lundqvist
//Erik Zubarev
class Dog extends Sprite {
  PImage[] runningFrames, laughingFrames;
  PVector pos, velocity;
  PVector target, exit;
  float speed = 4;
  int frameCounter = 0;
  int frameDelay = 5;
  int runningFrameIndex = 0;
  int laughingFrameIndex = 0;
  int laughTimer = 0;
  int LAUGH_DURATION = 50;
  boolean hasDroppedMine = false;
  boolean facingLeft = false;
  DogState state = DogState.ENTERING;

  Dog(PImage[] runningFrames, PImage[] laughingFrames) {
    this.runningFrames = runningFrames;
    this.laughingFrames = laughingFrames;
    this.pos = new PVector(-100, -100);
  }

  void startRun(PVector target) {
    int side = int(random(4));
    PVector dogStart = new PVector(0, 0);

    switch (side) {
    case 0:
      dogStart = new PVector(0, random(800));
      break;       // Left
    case 1:
      dogStart = new PVector(800, random(800));
      break;     // Right
    case 2:
      dogStart = new PVector(random(800), 0);
      break;       // Top
    case 3:
      dogStart = new PVector(random(800), 800);
      break;     // Bottom
    }

    this.exit = new PVector(dogStart.x * -1, dogStart.y * -1); // Opposite direction
    this.pos = dogStart.copy();
    this.target = target;
    this.velocity = PVector.sub(target, dogStart).normalize().mult(speed);
    this.facingLeft = velocity.x < 0;
    this.state = DogState.RUNNING_TO_TARGET;
    this.hasDroppedMine = false;
    this.laughTimer = 0;
  }

  void update() {
    // Animate frames
    frameCounter++;
    if (frameCounter >= frameDelay) {
      runningFrameIndex = (runningFrameIndex + 1) % runningFrames.length;
      laughingFrameIndex = (laughingFrameIndex + 1) % laughingFrames.length;
      frameCounter = 0;
    }

    switch (state) {
    case RUNNING_TO_TARGET:
      if (pos.dist(target) > 5) {
        pos.add(velocity);
      } else {
        state = DogState.LAUGHING;
      }
      break;

    case LAUGHING:
      if (laughTimer < LAUGH_DURATION) {
        laughTimer++;
      } else {
        if (!hasDroppedMine) {
          Landmine mine = new Landmine(landmineImg, target);
          allMines.add(mine);
          placedPositions.add(mine);
          hasDroppedMine = true;
        }
        state = DogState.EXITING;
        velocity = PVector.sub(exit, pos).normalize().mult(speed);
        facingLeft = velocity.x < 0;
      }
      break;

    case EXITING:
      pos.add(velocity);
      if (pos.x < -100 || pos.x > 900 || pos.y < -100 || pos.y > 900) {
        state = DogState.ENTERING;
      }
      break;

    case ENTERING:
      // Do nothing, waiting for next startRun
      break;
    }
  }

  void display() {
    imageMode(CENTER);
    pushMatrix();
    translate(pos.x, pos.y);

    if (!facingLeft) {
      scale(-1, 1); // Flip horizontally
    }

    if (state == DogState.LAUGHING) {
      image(laughingFrames[laughingFrameIndex], 0, 0);
    } else {
      image(runningFrames[runningFrameIndex], 0, 0);
    }

    popMatrix();
    imageMode(CORNER);
  }
}
