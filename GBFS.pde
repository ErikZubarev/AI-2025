import java.util.ArrayList;
import java.util.PriorityQueue;
import java.util.HashSet;
import java.util.HashMap;
import java.util.Comparator;

class GBFS {
  PVector start;
  PVector goal;
  QuadTreeMemory memory;
  Boundry tankBoundry; 

  ArrayList<QuadTreeMemory> applicableNodes;

  GBFS(PVector start, PVector goal, QuadTreeMemory memory, Boundry tankBoundry) {
    this.start = start;
    this.goal = goal;
    this.memory = memory;
    this.tankBoundry = tankBoundry;
    this.applicableNodes = new ArrayList<QuadTreeMemory>();

    collectApplicableNodes(memory, applicableNodes);
  }

  public ArrayList<PVector> solve() {
    QuadTreeMemory startNode = findContainingNode(applicableNodes, start);
    QuadTreeMemory goalNode = findContainingNode(applicableNodes, goal);

    if (startNode == null || goalNode == null) {
      println("Start or goal not in an applicable node.");
      return new ArrayList<PVector>();
    }

    PriorityQueue<QuadTreeMemory> frontier = new PriorityQueue<QuadTreeMemory>(new Comparator<QuadTreeMemory>() {
      public int compare(QuadTreeMemory a, QuadTreeMemory b) {
        float hA = heuristic(a);
        float hB = heuristic(b);
        return Float.compare(hA, hB);
      }
     });

    HashMap<QuadTreeMemory, QuadTreeMemory> cameFrom = new HashMap<QuadTreeMemory, QuadTreeMemory>();
    HashSet<QuadTreeMemory> closedSet = new HashSet<QuadTreeMemory>();

    frontier.add(startNode);
    cameFrom.put(startNode, null);

    QuadTreeMemory current = null;

    while (!frontier.isEmpty()) {
      current = frontier.poll();

      if (current == goalNode) {
        return reconstructPath(cameFrom, current);
      }

      closedSet.add(current);

      for (QuadTreeMemory neighbor : applicableNodes) {
        if (neighbor == current || closedSet.contains(neighbor)) {
          continue;
        }

        if (isNeighbor(current, neighbor)) {
          if (!cameFrom.containsKey(neighbor)) {
            cameFrom.put(neighbor, current);
            frontier.add(neighbor);
          }
        }
      }
    }

    println("No path was found.");
    return new ArrayList<PVector>();
  }

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

  private QuadTreeMemory findContainingNode(ArrayList<QuadTreeMemory> nodes, PVector point) {
    for (QuadTreeMemory node : nodes) {
      if (containsPoint(node.boundry, point)) {
        return node;
      }
    }
    return null;
  }

  private boolean containsPoint(Boundry b, PVector point) {
    return (point.x >= b.x && point.x <= b.x + b.width &&
      point.y >= b.y && point.y <= b.y + b.height);
  }

  private float heuristic(QuadTreeMemory node) {
    PVector center = new PVector(node.boundry.x + node.boundry.width / 2,
      node.boundry.y + node.boundry.height / 2);
    return PVector.dist(center, goal);
  }

  private boolean isNeighbor(QuadTreeMemory a, QuadTreeMemory b) {
    PVector centerA = new PVector(a.boundry.x + a.boundry.width / 2, a.boundry.y + a.boundry.height / 2);
    PVector centerB = new PVector(b.boundry.x + b.boundry.width / 2, b.boundry.y + b.boundry.height / 2);

    float dx = abs(centerA.x - centerB.x);
    float dy = abs(centerA.y - centerB.y);

    // Check if nodes are adjacent (touching or overlapping)
    float allowedDX = (a.boundry.width + b.boundry.width) / 2;
    float allowedDY = (a.boundry.height + b.boundry.height) / 2;
    boolean areAdjacent = dx <= allowedDX && dy <= allowedDY;

    if (!areAdjacent) {
      return false;
    }

    if (dx > 0 && dy == 0) { // Horizontal movement
      float minHeight = min(a.boundry.height, b.boundry.height);
      return minHeight >= tankBoundry.height;
    } else if (dy > 0 && dx == 0) { // Vertical movement
      float minWidth = min(a.boundry.width, b.boundry.width);
      return minWidth >= tankBoundry.width;
    } else if (dx > 0 && dy > 0) { // Diagonal movement
      float minWidth = min(a.boundry.width, b.boundry.width);
      float minHeight = min(a.boundry.height, b.boundry.height);
      return minWidth >= tankBoundry.width && minHeight >= tankBoundry.height;
    }

    return true;
  }

  private ArrayList<PVector> reconstructPath(HashMap<QuadTreeMemory, QuadTreeMemory> cameFrom, QuadTreeMemory current) {
    ArrayList<PVector> path = new ArrayList<PVector>();
    while (current != null) {
      PVector center = new PVector(current.boundry.x + current.boundry.width / 2,
        current.boundry.y + current.boundry.height / 2);
      path.add(0, center);
      current = cameFrom.get(current);
    }
    return path;
  }
}
