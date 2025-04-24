import java.util.ArrayList;
import java.util.HashSet;
import java.util.PriorityQueue;
import java.util.Comparator;

public class GBFSV3 {

    // Instance variables
    private PVector start;
    private PVector goal;
    private QuadTreeMemory memory;
    private Boundry tankBoundry;


    public GBFSV3(PVector start, PVector goal, QuadTreeMemory memory, Boundry tankBoundry) {
        this.start = start.copy();
        this.goal = goal.copy();
        this.memory = memory;
        this.tankBoundry = tankBoundry;
    }

    private class Node {
        PVector pos;
        Node parent;

        Node(PVector pos, Node parent) {
            this.pos = pos;
            this.parent = parent;
        }
    }


    public ArrayList<PVector> solve() {
      float stepSize = 20;
      float tolerance = 50;
        ArrayList<PVector> path = new ArrayList<PVector>();

        PriorityQueue<Node> openSet = new PriorityQueue<Node>(new Comparator<Node>() {
            public int compare(Node a, Node b) {
                float da = PVector.dist(a.pos, goal);
                float db = PVector.dist(b.pos, goal);
                return Float.compare(da, db);
            }
        });

        HashSet<String> closedSet = new HashSet<String>();

        openSet.add(new Node(start, null));

        while (!openSet.isEmpty()) {
            Node current = openSet.poll();

            // Check if current position is within tolerance of the goal.
            if (PVector.dist(current.pos, goal) <= tolerance) {
                Node tracker = current;
                while (tracker != null) {
                    path.add(0, tracker.pos.copy());
                    tracker = tracker.parent;
                }
                return path;
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
                    continue;
                }

                openSet.add(new Node(neighbor, current));
            }
        }

        println("No valid path");
        return path;
    }

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

    private boolean isSafe(PVector candidate) {
        float halfWidth = tankBoundry.width / 2;
        float halfHeight = tankBoundry.height / 2;
        
        Boundry candidateBoundary = new Boundry(candidate.x - halfWidth, candidate.y - halfHeight, tankBoundry.width, tankBoundry.height);

        ArrayList<Sprite> obstacles = memory.query(candidateBoundary);
        return obstacles.isEmpty();
    }
}
