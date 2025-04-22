class QuadTreeMemory {
  Sprite holding;
  QuadTreeMemory[] children;
  boolean subdivided;
  boolean explored;
  Boundry boundry;
  int depth;

  // Constructor ======================================
  QuadTreeMemory(Boundry boundry, int depth) {
    this.boundry = boundry;
    subdivided = false;
    explored = false;
    this.depth = depth;
    children = new QuadTreeMemory[4];
  }

  // ==================================================
  void subdivide() {
    if (depth <= 0) {
      return;
    }

    float x = boundry.x;
    float y = boundry.y;
    float half_w = boundry.width /2;
    float half_h = boundry.height /2;
    int lowerDepth = depth-1;


    children[0] = new QuadTreeMemory(new Boundry(x, y, half_w, half_h), lowerDepth);
    children[1] = new QuadTreeMemory(new Boundry(x + half_w, y, half_w, half_h), lowerDepth);
    children[2] = new QuadTreeMemory(new Boundry(x, y + half_h, half_w, half_h), lowerDepth);
    children[3] = new QuadTreeMemory(new Boundry(x + half_w, y + half_h, half_w, half_h), lowerDepth);

    subdivided = true;
  }

  // ==================================================
  void updateExploredStatus(Boundry viewArea) {
    if (explored) {
      return;
    }

    if (!boundry.intersects(viewArea)) {
      if (subdivided) {
        for (QuadTreeMemory child : children) {
          if (child != null) {
            child.updateExploredStatus(viewArea);
          }
        }
        checkChildren();
      }
      return;
    }

    if (depth <= 0) {
      explored = true;
      return;
    }

    if (!subdivided) {
      subdivide();
    }

    // Update all children
    for (int i = 0; i < children.length; i++) {
      children[i].updateExploredStatus(viewArea);
    }

    checkChildren();
  }


  // ==================================================
  void checkChildren() {
    if (!subdivided) {
      return;
    }

    boolean allExplored = true;
    Sprite item = children[0].holding;

    for (QuadTreeMemory child : children) {
      if (!child.explored || child.holding != item) {
        allExplored = false;
        break;
      }
    }

    if (allExplored) {
      this.explored = true;
      this.holding = item;
      removeChildren();
    }
  }
  // ==================================================
  void removeChildren() {
    for (int i = 0; i < children.length; i++) {
      children[i] = null;
    }

    subdivided = false;
  }

  // ==================================================
  void insert(Sprite obj) {




    if (!boundry.intersects(obj.boundry)) {
      return;
    }

    if (depth <= 0 || boundry.isWithin(obj.boundry)) {
      holding = obj;
      return;
    }

    //La till så den kollar om den är subvidied och explored så subdividar vi och tvingar barnen vara explored
    if (!subdivided && explored) {
      subdivide();
      for (QuadTreeMemory child : children) {
        child.explored = true;
      }
    }

    boolean insertedIntoChild = false;
    if (subdivided) {
      for (int i = 0; i < children.length; i++) {
        if (children[i].boundry.intersects(obj.boundry)) {
          children[i].insert(obj);
          insertedIntoChild = true;
        }
      }
    }

    if (insertedIntoChild) {
      holding = null;
    }

    //tror detta fuckar upp det??
    //checkChildren();
  }

  // ==================================================
  ArrayList<Sprite> query(Boundry area) {
    ArrayList<Sprite> found = new ArrayList<Sprite>();

    if (!boundry.intersects(area)) {
      return found;
    }


    if (holding != null && area.intersects(holding.boundry)) {
      found.add(holding);
    }

    for (QuadTreeMemory child : children) {
      if (child != null) {
        found.addAll(child.query(area));
      }
    }


    return found;
  }

  // ==================================================
  void display() {
    if (debugMode) {
      pushMatrix();
      noFill();
      strokeWeight(1);

      if (explored) {
        if (!subdivided) {
          fill(0, 0, 255, 20);
        }
        stroke(0, 0, 255, 150);
      } else {
        stroke(100, 100, 100, 100);
      }

      rect(boundry.x, boundry.y, boundry.width, boundry.height);

      if (subdivided) {
        for (QuadTreeMemory child : children) {
          if (child != null) {
            child.display();
          }
        }
      }

      if (holding != null) {
        fill(0, 255, 0, 255);
        ellipse(boundry.x + boundry.width/2, boundry.y + boundry.height/2, 5, 5);
      }
      popMatrix();
    }
  }
}
