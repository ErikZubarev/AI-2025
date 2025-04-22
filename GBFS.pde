import java.util.ArrayList;
import java.util.PriorityQueue;
import java.util.HashSet;
import java.util.HashMap;
import java.util.Comparator;

// GBFS class that takes in a start, goal and QuadTreeMemory structure.
class GBFS {
  PVector start;
  PVector goal;
  QuadTreeMemory memory;

  // List to hold all applicable nodes from the QuadTreeMemory.
  ArrayList<QuadTreeMemory> applicableNodes;

  GBFS(PVector start, PVector goal, QuadTreeMemory memory) {
    this.start = start;
    this.goal = goal;
    this.memory = memory;
    this.applicableNodes = new ArrayList<QuadTreeMemory>();

    // Pre-collect all leaf nodes that are both explored and free (holding == null).
    collectApplicableNodes(memory, applicableNodes);
  }

  // The method which runs the Greedy Best First Search and returns
  // an ArrayList of PVectors corresponding to the center points
  // of the nodes along the solution path.
  public ArrayList<PVector> solve() {
    // Find the leaf (applicable) node that contains the start and goal points.
    QuadTreeMemory startNode = findContainingNode(applicableNodes, start);
    QuadTreeMemory goalNode = findContainingNode(applicableNodes, goal);

    // If either start or goal aren't found among the applicable nodes, return an empty path.
    if(startNode == null || goalNode == null) {
      println("Start or goal not in an applicable node.");
      return new ArrayList<PVector>();
    }

    // PriorityQueue orders nodes by the heuristic distance from their center to the goal.
    PriorityQueue<QuadTreeMemory> openList = new PriorityQueue<QuadTreeMemory>(new Comparator<QuadTreeMemory>() {
      public int compare(QuadTreeMemory a, QuadTreeMemory b) {
        float hA = heuristic(a);
        float hB = heuristic(b);
        return Float.compare(hA, hB);
      }
    });

    // For reconstructing the path: map each node to its parent.
    HashMap<QuadTreeMemory, QuadTreeMemory> cameFrom
= new HashMap<QuadTreeMemory, QuadTreeMemory>();

    // For keeping track of visited nodes.
    HashSet<QuadTreeMemory> closedSet = new HashSet<QuadTreeMemory>();

    openList.add(startNode);
    cameFrom.put(startNode, null);

    QuadTreeMemory current = null;

    while(!openList.isEmpty()){
      current = openList.poll();

      // If we reached the node that contains the goal, we found our path.
      if(current == goalNode) {
        return reconstructPath(cameFrom, current);
      }

      closedSet.add(current);

      // Get the neighbors: here we simply iterate over all applicable nodes and 
      // check if they touch the current node.
      for(QuadTreeMemory neighbor : applicableNodes) {
        // Skip if the candidate is the same node or has been processed.
        if(neighbor == current || closedSet.contains(neighbor)) {
          continue;
        }

        // Check if neighbor is adjacent to current.
        if(isNeighbor(current, neighbor)) {
          // If neighbor not yet in the open list, add it.
          // (It’s okay if we add it multiple times; our closedSet ensures we don’t revisit.)
          if(!cameFrom.containsKey(neighbor)) {
            cameFrom.put(neighbor, current);
            openList.add(neighbor);
          }
        }
      }
    }

    // If the loop finishes without finding the goal,
    // return an empty path.
    println("No path was found.");
    return new ArrayList<PVector>();
  }

  // Helper: Recursively collect leaf nodes from the QuadTreeMemory that are both explored and free.
  private void collectApplicableNodes(QuadTreeMemory node, ArrayList<QuadTreeMemory> list) {
    if(node.subdivided) {
      for(QuadTreeMemory child : node.children) {
        if(child != null) {
          collectApplicableNodes(child, list);
        }
      }
    } else {
      if(node.explored && node.holding == null) {
list.add(node);
      }
    }
  }

  // Helper: Find the applicable node that contains the given point.
  private QuadTreeMemory findContainingNode(ArrayList<QuadTreeMemory> nodes, PVector point) {
    for(QuadTreeMemory node : nodes) {
      if(containsPoint(node.boundry, point)) {
        return node;
      }
    }
    return null;
  }

  // Helper: Check if a Boundry contains a given point.
  private boolean containsPoint(Boundry b, PVector point) {
    return (point.x >= b.x && point.x <= b.x + b.width &&
            point.y >= b.y && point.y <= b.y + b.height);
  }

  // Helper: Compute the heuristic value for a node (Euclidean distance from its center to the goal).
  private float heuristic(QuadTreeMemory node) {
    PVector center = new PVector(node.boundry.x + node.boundry.width/2,
                                 node.boundry.y + node.boundry.height/2);
    return PVector.dist(center, goal);
  }

  // Helper: Determine if two QuadTreeMemory nodes are neighbors.
  // We consider two nodes neighbors if the distance between their centers is 
  // less than or equal to the sum of half their widths (in x) and half their heights (in y).
  private boolean isNeighbor(QuadTreeMemory a, QuadTreeMemory b) {
    PVector centerA = new PVector(a.boundry.x + a.boundry.width/2, a.boundry.y + a.boundry.height/2);
    PVector centerB = new PVector(b.boundry.x + b.boundry.width/2, b.boundry.y + b.boundry.height/2);

    // Compute the allowed difference along x and y
    float allowedDX = (a.boundry.width + b.boundry.width) / 2;
    float allowedDY = (a.boundry.height + b.boundry.height) / 2;

    return (abs(centerA.x - centerB.x) <= allowedDX &&
            abs(centerA.y - centerB.y) <= allowedDY);
  }

  // Helper: Reconstruct the path from start to current (goal) node using the parent map.
  private ArrayList<PVector> reconstructPath(HashMap<QuadTreeMemory, QuadTreeMemory> cameFrom, QuadTreeMemory current)
{
    ArrayList<PVector> path = new ArrayList<PVector>();
    while(current != null) {
      // Add the center of the node to the path.
      PVector center = new PVector(current.boundry.x + current.boundry.width/2,
                                   current.boundry.y + current.boundry.height/2);
      path.add(0, center);  // add in front to reverse the order on the fly
      current = cameFrom.get(current);
    }
    return path;
  }
}
