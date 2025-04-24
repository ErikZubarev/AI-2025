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

    while (!frontier.isEmpty()) {
      QuadTreeMemory current = frontier.poll();
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
    PVector closestPoint = getClosestPointInNode(node, goal);
    return PVector.dist(closestPoint, goal);
  }

  private PVector getClosestPointInNode(QuadTreeMemory node, PVector goal) {
    Boundry b = node.boundry;
    float closestX = constrain(goal.x, b.x, b.x + b.width);
    float closestY = constrain(goal.y, b.y, b.y + b.height);
    return new PVector(closestX, closestY);
  }

  private boolean isNeighbor(QuadTreeMemory a, QuadTreeMemory b) {
    Boundry ba = a.boundry;
    Boundry bb = b.boundry;

    // Horizontal adjacency
    if (Math.abs(ba.x + ba.width - bb.x) < 1e-5 || Math.abs(bb.x + bb.width - ba.x) < 1e-5) {
      float yOverlapMin = Math.max(ba.y, bb.y);
      float yOverlapMax = Math.min(ba.y + ba.height, bb.y + bb.height);
      float overlapHeight = yOverlapMax - yOverlapMin;
      if (overlapHeight >= tankBoundry.height) {
        return true;
      }
    }

    // Vertical adjacency
    if (Math.abs(ba.y + ba.height - bb.y) < 1e-5 || Math.abs(bb.y + bb.height - ba.y) < 1e-5) {
      float xOverlapMin = Math.max(ba.x, bb.x);
      float xOverlapMax = Math.min(ba.x + ba.width, bb.x + bb.width);
      float overlapWidth = xOverlapMax - xOverlapMin;
      if (overlapWidth >= tankBoundry.width) {
        return true;
      }
    }

    return false;
  }

  private ArrayList<PVector> reconstructPath(HashMap<QuadTreeMemory, QuadTreeMemory> cameFrom, QuadTreeMemory current) {
    ArrayList<PVector> path = new ArrayList<PVector>();
    while (current != null) {
      PVector waypoint = getClosestPointInNode(current, goal);
      path.add(0, waypoint); // Add to start of list to reverse the path
      current = cameFrom.get(current);
    }
    return path;
  }
}
