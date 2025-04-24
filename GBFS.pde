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
        ArrayList<PVector> path = new ArrayList<PVector>();

        //Very cool lambda class that uses the heuristic as input to the priority queue
        //Euclidean Heuristic - straight line distance
        PriorityQueue<Node> frontier = new PriorityQueue<Node>(new Comparator<Node>() {
            public int compare(Node a, Node b) {
                float da = PVector.dist(a.pos, goal); 
                float db = PVector.dist(b.pos, goal);
                return Float.compare(da, db);
            }
        });

        //Set of visited nodes x,y coordinates in String
        HashSet<String> closedSet = new HashSet<String>();

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
                println("Time in nanoseconds: " + (System.nanoTime() - startTime));
                println("Iterations: " + iterations);
                return smoothPath(path);
            }

            String key = current.pos.x + "," + current.pos.y;
            if (closedSet.contains(key)) {
                continue;
            }
            closedSet.add(key);

            ArrayList<PVector> neighbors = generateNeighbors(current.pos, stepSize);
            for (PVector neighbor : neighbors) {
                String neighborKey = neighbor.x + "," + neighbor.y;
                if (closedSet.contains(neighborKey))
                    continue;

                if (!isSafe(neighbor)) {
                    continue; //Skip if there is an object in the way
                }

                frontier.add(new Node(neighbor, current));
            }
        }

        println("No valid path found");
        return path;
    }

    // Helper classes ===============================================================================
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
        
        // Check if tank boundary is entirely within the play area size(800,800)
        if (candidate.x - halfWidth < 0 || candidate.y - halfHeight < 0 ||
            candidate.x + halfWidth > 800 || candidate.y + halfHeight > 800) {
            return false;
        }
        
        Boundry candidateBoundary = new Boundry(candidate.x - halfWidth, candidate.y - halfHeight, tankBoundry.width, tankBoundry.height);
        ArrayList<Sprite> obstacles = memory.query(candidateBoundary);
        return obstacles.isEmpty();
    }
    
    // ================================================================================================
    private ArrayList<PVector> smoothPath(ArrayList<PVector> originalPath) {
        if (originalPath.size() <= 2) {
            return originalPath;
        }
        
        ArrayList<PVector> smoothedPath = new ArrayList<>();
        int currentIndex = 0;
        smoothedPath.add(originalPath.get(currentIndex));  // Starting point
    
        while (currentIndex < originalPath.size() - 1) {
            // Start by trying the farthest possible jump
            int nextIndex = originalPath.size() - 1;
            for (int j = originalPath.size() - 1; j > currentIndex; j--) {
                if (isSegmentClear(originalPath.get(currentIndex), originalPath.get(j))) {
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
    private boolean isSegmentClear(PVector start, PVector end) {
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
        PVector point = PVector.lerp(start, end, t); // new segment to check
        tempBoundry.x = point.x - tankBoundry.width / 2;
        tempBoundry.y = point.y - tankBoundry.height / 2;
  
        ArrayList<Sprite> obstacles = memory.query(tempBoundry); // Check for obstacles on the segment
        if (!obstacles.isEmpty()) {
          return false;
        }
      }
      return true;
    }
}
