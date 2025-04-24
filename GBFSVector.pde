import java.util.ArrayList;
import java.util.PriorityQueue;
import java.util.HashSet;
import java.util.HashMap;
import java.util.Comparator;

class GBFSVector {
  PVector start;
  PVector goal;
  QuadTreeMemory memory;
  Boundry tankBoundry;
  ArrayList<QuadTreeMemory> applicableNodes;

  GBFSVector(PVector start, PVector goal, QuadTreeMemory memory, Boundry tankBoundry) {
    this.start = start.copy();
    this.goal = goal.copy();
    this.memory = memory;
    this.tankBoundry = tankBoundry;
    this.applicableNodes = new ArrayList<QuadTreeMemory>();
    collectApplicableNodes(memory, applicableNodes);
  }

  public ArrayList<PVector> solve() {
    // First, try a straight-line path
    if (isSegmentClear(start, goal)) {
      ArrayList<PVector> path = new ArrayList<PVector>();
      path.add(start.copy());
      path.add(goal.copy());
      return path;
    }

    // If straight line is blocked, run GBFS with PVector waypoints
    PriorityQueue<Node> frontier = new PriorityQueue<Node>(new Comparator<Node>() {
      public int compare(Node a, Node b) {
        return Float.compare(a.fScore, b.fScore);
      }
    });

    HashMap<PVector, PVector> cameFrom = new HashMap<PVector, PVector>();
    HashSet<PVector> closedSet = new HashSet<PVector>();
    HashMap<PVector, Float> fScore = new HashMap<PVector, Float>();

    // Initialize with start position
    frontier.add(new Node(start, heuristic(start)));
    cameFrom.put(start, null);
    fScore.put(start, heuristic(start));

    while (!frontier.isEmpty()) {
      Node currentNode = frontier.poll();
      PVector current = currentNode.position;

      if (current.dist(goal) < 5) { // Close enough to goal
        return reconstructPath(cameFrom, current);
      }

      closedSet.add(current);

      // Get candidate waypoints (from quadtree nodes and neighbors)
      ArrayList<PVector> neighbors = getNeighborWaypoints(current);
      for (PVector neighbor : neighbors) {
        if (closedSet.contains(neighbor)) {
          continue;
        }

        // Check if the segment from current to neighbor is clear
        if (!isSegmentClear(current, neighbor)) {
          continue;
        }

        float tentativeFScore = heuristic(neighbor);

        if (!fScore.containsKey(neighbor) || tentativeFScore < fScore.get(neighbor)) {
          cameFrom.put(neighbor, current);
          fScore.put(neighbor, tentativeFScore);
          frontier.add(new Node(neighbor, tentativeFScore));
        }
      }
    }

    println("No path was found.");
    return new ArrayList<PVector>();
  }

  // Helper class for priority queue
  private class Node {
    PVector position;
    float fScore;

    Node(PVector position, float fScore) {
      this.position = position.copy();
      this.fScore = fScore;
    }
  }

  // Check if a segment between two points is clear
  private boolean isSegmentClear(PVector start, PVector end) {
    Boundry tempBoundry = new Boundry(
      start.x - tankBoundry.width / 2,
      start.y - tankBoundry.height / 2,
      tankBoundry.width,
      tankBoundry.height
    );

    float distance = start.dist(end);
    int steps = (int)(distance / 5) + 1;
    for (int i = 0; i <= steps; i++) {
      float t = i / (float)steps;
      PVector point = PVector.lerp(start, end, t);
      tempBoundry.x = point.x - tankBoundry.width / 2;
      tempBoundry.y = point.y - tankBoundry.height / 2;

      ArrayList<Sprite> obstacles = memory.query(tempBoundry);
      if (!obstacles.isEmpty()) {
        return false;
      }
    }
    return true;
  }

  // Collect free, explored nodes large enough for the tank
  private void collectApplicableNodes(QuadTreeMemory node, ArrayList<QuadTreeMemory> list) {
    if (node.subdivided) {
      for (QuadTreeMemory child : node.children) {
        if (child != null) {
          collectApplicableNodes(child, list);
        }
      }
    } else {
      if (node.explored && node.holding == null && isLargeEnough(node)) {
        list.add(node);
      }
    }
  }

  private boolean isLargeEnough(QuadTreeMemory node) {
    return node.boundry.width >= tankBoundry.width && node.boundry.height >= tankBoundry.height;
  }

  // Generate neighbor waypoints (e.g., corners of nearby nodes)
  private ArrayList<PVector> getNeighborWaypoints(PVector current) {
    ArrayList<PVector> neighbors = new ArrayList<PVector>();

    // Add goal as a candidate (allows direct path if clear)
    neighbors.add(goal.copy());

    // Find nodes near the current position
    Boundry queryBoundry = new Boundry(
      current.x - tankBoundry.width,
      current.y - tankBoundry.height,
      tankBoundry.width * 2,
      tankBoundry.height * 2
    );

    for (QuadTreeMemory node : applicableNodes) {
      if (node.boundry.intersects(queryBoundry)) {
        // Add corners of the node
        Boundry b = node.boundry;
        neighbors.add(new PVector(b.x, b.y)); // Top-left
        neighbors.add(new PVector(b.x + b.width, b.y)); // Top-right
        neighbors.add(new PVector(b.x, b.y + b.height)); // Bottom-left
        neighbors.add(new PVector(b.x + b.width, b.y + b.height)); // Bottom-right
        // Add closest point to goal within the node
        neighbors.add(getClosestPointInNode(node, goal));
      }
    }

    return neighbors;
  }

  private PVector getClosestPointInNode(QuadTreeMemory node, PVector goal) {
    Boundry b = node.boundry;
    float closestX = constrain(goal.x, b.x, b.x + b.width);
    float closestY = constrain(goal.y, b.y, b.y + b.height);
    return new PVector(closestX, closestY);
  }

  private float heuristic(PVector position) {
    return position.dist(goal);
  }

  private ArrayList<PVector> reconstructPath(HashMap<PVector, PVector> cameFrom, PVector current) {
    ArrayList<PVector> path = new ArrayList<PVector>();
    while (current != null) {
      path.add(0, current.copy());
      current = cameFrom.get(current);
    }
    return path;
  }
}
