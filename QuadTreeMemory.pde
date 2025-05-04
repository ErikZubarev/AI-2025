//Anton Lundqvist
//Erik Zubarev
class QuadTreeMemory {
  public Sprite holding;
  public QuadTreeMemory[] children;
  public boolean explored;
  public Boundry boundry;
  
  private int depth;
  private boolean subdivided;

  public QuadTreeMemory(Boundry boundry, int depth) {
    this.boundry = boundry;
    subdivided = false;
    explored = false;
    this.depth = depth;
    children = new QuadTreeMemory[4];
  }

  // =================================================
  // ===  MAIN METHODS
  // =================================================
  // ==================================================================================================
  public void updateExploredStatus(Boundry viewArea) {
    // Remove items from memory if they are no longer there
    if (holding != null) {
      if (!placedPositions.contains(holding) || !holding.boundry.intersects(boundry)) {
          holding = null; 
      }
    }

    if (explored || !boundry.intersects(viewArea))
      return;

    if (depth <= 0) {
      explored = true;
      return;
    }

    if (!subdivided) {
      subdivide();
    }

    for (QuadTreeMemory child : children) {
      child.updateExploredStatus(viewArea);
    }    
  }

  // ==================================================================================================
  public void insert(Sprite obj) {
    if(holding == obj)
      return;
    
    if (!boundry.intersects(obj.boundry))
      return;

    if (depth <= 0 || boundry.isWithin(obj.boundry)) {
      holding = obj;
      return;
    }

    if (!subdivided && explored) {
      subdivide();
      for (QuadTreeMemory child : children) {
        child.explored = true; //Make sure children are safe 
      }
    }

    boolean passedDown = false;
    if (subdivided) {
      for (int i = 0; i < children.length; i++) {
        children[i].insert(obj);
        passedDown = true;
      }
    }

    if (passedDown) {
      explored = false;
      holding = null;
    }  
  }

  // ==================================================================================================
  public ArrayList<Sprite> query(Boundry area) {
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
  
  // ==================================================================================================
  public void pruneChildren(Boundry view) {
      if(!boundry.intersects(view) || !subdivided)
        return;

      // First, recursively call pruneChildren on each child (bottom-up processing).
      for (QuadTreeMemory child : children) {
        if (child != null) {
          child.pruneChildren(view); 
        }
      }
      
      // Now check if all children are uniform:
      boolean canPrune = true;
      Sprite commonHolding = children[0].holding;   

      for (QuadTreeMemory child : children) {
        if (!child.explored) {
          canPrune = false;
          break;
        }
        
        if (child.holding != commonHolding) {
          canPrune = false;
          break;
        }
      }
      
      // If pruning conditions are met, merge children upward.
      if (canPrune) {
        holding = commonHolding;
        explored = true;
        subdivided = false;
        children = new QuadTreeMemory[4];
      }
    }
 
  // =================================================
  // ===  HELPER METHODS
  // =================================================

  // ==================================================================================================
  public boolean isExplored(Boundry pos) {
    if (!boundry.intersects(pos)) {
        return false;
    }

    // If this node is explored and the position is within its boundary, return true
    if (explored && pos.isWithin(boundry)) {
        return true;
    }

    // If the node is subdivided, recursively check all children
    if (subdivided) {
        for (QuadTreeMemory child : children) {
            if (child != null && child.isExplored(pos)) {
                return true; 
            }
        }
    }

    return false;
  }
   
  // ==================================================================================================
  private void subdivide() {
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

  // =================================================
  // ===  DISPLAY METHODS
  // =================================================
  // ==================================================================================================
  public void display() {
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
