//Anton Lundqvist
//Erik Zubarev
import java.util.HashSet;
import java.util.PriorityQueue;
import java.util.Comparator;

public class GBFS {
  private PVector start;
  private PVector goal;
  private QuadTreeMemory memory;
  private Boundry tankBoundry;
  private final float stepSize = 20; //Distance between PVectors
  private final float tolerance = 50; //Acceptable distance from goal

  public GBFS(PVector start, PVector goal, QuadTreeMemory memory, Boundry tankBoundry) {
    this.start = start.copy();
    this.goal = goal.copy();
    this.memory = memory;
    this.tankBoundry = tankBoundry;
  }

  //Simpler to handle class than QuadTreeMemory
  private class Node {
    PVector pos;
    Node parent;

    Node(PVector pos, Node parent) {
      this.pos = pos;
      this.parent = parent;
    }
  }

  // Solve problem ====================================================================================
  public ArrayList<PVector> solve() {
    //final path backwards
    ArrayList<PVector> path = new ArrayList<PVector>();

    //Very cool lambda class that uses the heuristic as input to the priority queue
    //Euclidean Heuristic - straight line distance
    PriorityQueue<Node> frontier = new PriorityQueue<Node>(new Comparator<Node>() {
      public int compare(Node a, Node b) {
        float da = PVector.dist(a.pos, goal);
        float db = PVector.dist(b.pos, goal);
        return Float.compare(da, db);
      }
    }
    );

    //Set of visited nodes x,y coordinates in String
    HashSet<String> closedSet = new HashSet<String>();

    //Add startnode to frontier
    frontier.add(new Node(start, null));
    int iterations = 0;
    Long startTime = System.nanoTime();

    while (!frontier.isEmpty()) {
      iterations++;
      Node current = frontier.poll();

      // Check if current position is within tolerance of the goal
      if (PVector.dist(current.pos, goal) <= tolerance) {
        Node tracker = current;
        while (tracker != null) {
          path.add(0, tracker.pos.copy());
          tracker = tracker.parent;
        }
        //println("Time in nanoseconds: " + (System.nanoTime() - startTime));
        //println("Iterations: " + iterations);
        //println("Path length: " + path.size());

        return smoothPath(path);
      }

      //Create position and add it to visited nodes
      String key = current.pos.x + "," + current.pos.y;
      if (closedSet.contains(key)) {
        continue;
      }
      closedSet.add(key);

      //Create neighbours and iterate through neighbors
      ArrayList<PVector> neighbors = generateNeighbors(current.pos, stepSize);
      for (PVector neighbor : neighbors) {
        String neighborKey = neighbor.x + "," + neighbor.y;
        if (closedSet.contains(neighborKey))
          continue;

        if (!isSafe(neighbor)) {
          continue; //Skip if there is an object in the way
        }
        //Add neigbour to frontier with current node as its parent
        frontier.add(new Node(neighbor, current));
      }
    }

    println("No valid path found");
    return path;
  }

  // Helper classes ===============================================================================
  //Creates neighbours via going out in the step in each cardinal direction in a 3x3 grid
  //Visualization N = neihbour X = current
  //  N N N
  //  N X N
  //  N N N
  private ArrayList<PVector> generateNeighbors(PVector pos, float step) {
    ArrayList<PVector> neighbors = new ArrayList<PVector>();
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        if (dx == 0 && dy == 0)
          continue;
        neighbors.add(new PVector(pos.x + dx * step, pos.y + dy * step));
      }
    }
    return neighbors;
  }

  // ==============================================================================================
  private boolean isSafe(PVector candidate) {
    float halfWidth = tankBoundry.width / 2;
    float halfHeight = tankBoundry.height / 2;
    float safetyMargin = 5.0f;

    if (candidate.x - halfWidth - safetyMargin < 0 ||
      candidate.y - halfHeight - safetyMargin < 0 ||
      candidate.x + halfWidth + safetyMargin > 800 ||
      candidate.y + halfHeight + safetyMargin > 800) {
      return false;
    }

    Boundry candidateBoundary = new Boundry(
      candidate.x - halfWidth - safetyMargin,
      candidate.y - halfHeight - safetyMargin,
      tankBoundry.width + 2 * safetyMargin,
      tankBoundry.height + 2 * safetyMargin
      );

    ArrayList<Sprite> obstacles = memory.query(candidateBoundary);

    if (!obstacles.isEmpty() ) {
      if (!(obstacles.get(0) instanceof Tank)) {
        return false;
      }
    }

    Boundry pos = new Boundry(candidate.x, candidate.y, 1, 1);
    if (!memory.isExplored(pos)) {
      return false;
    }

    return true;
  }


  // ================================================================================================
  private ArrayList<PVector> smoothPath(ArrayList<PVector> originalPath) {
    if (originalPath.size() <= 2) {
      return originalPath;
    }

    ArrayList<PVector> smoothedPath = new ArrayList<>();
    int currentIndex = 0;
    smoothedPath.add(originalPath.get(currentIndex)); // Starting point

    while (currentIndex < originalPath.size() - 1) {
      // Start by trying the farthest possible jump
      int nextIndex = currentIndex + 1; // Default to next point
      for (int j = originalPath.size() - 1; j > currentIndex; j--) {
        if (isSegmentClearAndExplored(originalPath.get(currentIndex), originalPath.get(j))) {
          nextIndex = j;
          break;
        }
      }
      smoothedPath.add(originalPath.get(nextIndex));
      currentIndex = nextIndex;
    }

    return smoothedPath;
  }

  // ==================================================================================================
  private boolean isSegmentClearAndExplored(PVector start, PVector end) {
    Boundry tempBoundry = new Boundry(
      start.x - tankBoundry.width / 2,
      start.y - tankBoundry.height / 2,
      tankBoundry.width,
      tankBoundry.height
      );

    float distance = start.dist(end);
    int steps = (int)(distance / 5) + 1; // Divide straight line into segments
    for (int i = 0; i <= steps; i++) {
      float t = i / (float) steps;
      PVector point = PVector.lerp(start, end, t); // New segment to check
      tempBoundry.x = point.x - tankBoundry.width / 2;
      tempBoundry.y = point.y - tankBoundry.height / 2;

      // Check for obstacles
      ArrayList<Sprite> obstacles = memory.query(tempBoundry);
      if (!obstacles.isEmpty()) {
        return false;
      }

      // Check if the point is explored
      Boundry pointBoundry = new Boundry(point.x, point.y, 1, 1);
      if (!memory.isExplored(pointBoundry)) {
        return false;
      }
    }
    return true;
  }
}
