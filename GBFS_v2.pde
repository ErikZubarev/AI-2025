import java.util.ArrayList;
import java.util.HashSet;
import java.util.PriorityQueue;
import java.util.Comparator;

public class GBFSv2 {
    private PVector start;
    private PVector goal;
    private QuadTreeMemory memory;
    private Boundry tankBoundry;
    private final float stepSize = 20; //Distance between PVectors
    private final float tolerance = 50; //Acceptable distance from goal

    public GBFSv2(PVector start, PVector goal, QuadTreeMemory memory, Boundry tankBoundry) {
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

        while (!frontier.isEmpty()) {
            Node current = frontier.poll();

            // Check if current position is within tolerance of the goal
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
        
        Boundry candidateBoundary = new Boundry(candidate.x - halfWidth, candidate.y - halfHeight, tankBoundry.width, tankBoundry.height);

        ArrayList<Sprite> obstacles = memory.query(candidateBoundary);
        return obstacles.isEmpty();
    }
}
