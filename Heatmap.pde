class Heatmap {
    int gridSize = 10;  // Defines the resolution of the heatmap
    float[][] qValues;  // Stores Q-values in a matrix format
    int rows, cols;
    
    // Store sorted states separately for labeling
    List<Tank.State> sortedStates = new ArrayList<>();

    Heatmap(int rows, int cols) {
        this.rows = rows;
        this.cols = cols;
        qValues = new float[rows][cols];  // Initialize the Q-table
    }
    
    void updateHeatmap(HashMap<Tank.State, HashMap<String, Float>> qTable) {
        // **Extract & Sort States**
        sortedStates = new ArrayList<>(qTable.keySet());
        sortedStates.sort(
            Comparator.comparing((Tank.State s) -> s.facingWall)
                      .thenComparingInt(s -> s.nearestEnemyDistCategory)
        );
    
        // **Resize qValues[][] to match actual state-action space**
        rows = sortedStates.size();
        cols = qLearner.actions.length;
        qValues = new float[rows][cols];  // Ensure array matches actual dimensions
    
        int rowIdx = 0;
        for (Tank.State state : sortedStates) {
            if (rowIdx >= rows) break; // Bounds check
            int colIdx = 0;
            for (String action : qLearner.actions) {  // Use ordered actions instead of looping over qTable's keyset
                if (colIdx >= cols) break; // Bounds check
    
                // **Check if state exists in qTable to prevent null values**
                if (qTable.containsKey(state) && qTable.get(state).containsKey(action)) {
                    qValues[rowIdx][colIdx] = qTable.get(state).get(action);  // Fetch Q-value
                } else {
                    qValues[rowIdx][colIdx] = 0;  // Assign default 0 if state-action pair doesn't exist
                }
                colIdx++;
            }
            rowIdx++;
        }
    }


void display() {
    int centerX = width / 2;  // Center X of screen
    int centerY = height / 2; // Center Y of screen
    int heatmapWidth = 600;   // Fixed width for actions
    int heatmapHeight = 600;  // Fixed height area for states
    int borderSize = 20;      // Optional border for visibility

    // Update rows and cols based on our current sorted state list
    rows = sortedStates.size();
    cols = qLearner.actions.length;
    
    if (cols == 0 || rows == 0) {
        return;
    }
    
    gridSize = heatmapWidth / cols;  
    int stateHeight = heatmapHeight / rows;
    
    int startX = centerX - (heatmapWidth / 2);
    int startY = centerY - (heatmapHeight / 2);
    
    // **Draw Background Border**
    fill(50);
    rect(startX - borderSize, startY - borderSize, heatmapWidth + (borderSize * 2), heatmapHeight + (borderSize * 2));
    
    // **Draw Action Labels at the Top**
    textAlign(CENTER, CENTER);
    textSize(16);
    fill(0);
    for (int j = 0; j < cols; j++) {
        String actionName = qLearner.actions[j];
        text(actionName, startX + (j * gridSize) + (gridSize / 2), startY - 25);
    }
    
    // **Identify Group Start Indexes for enemy proximity labeling**
    int closeStart = -1, mediumStart = -1, farStart = -1;
    for (int i = 0; i < sortedStates.size(); i++) {
        Tank.State state = sortedStates.get(i);
        if (state.nearestEnemyDistCategory == 1 && closeStart == -1) closeStart = i;
        if (state.nearestEnemyDistCategory == 2 && mediumStart == -1) mediumStart = i;
        if (state.nearestEnemyDistCategory >= 3 && farStart == -1) farStart = i;
    }
    
    // **Label Enemy Proximity Groups**
    labelGroup("Close", closeStart, mediumStart, startX, startY, stateHeight);
    labelGroup("Medium", mediumStart, farStart, startX, startY, stateHeight);
    labelGroup("Far/\nNone", farStart, sortedStates.size(), startX, startY, stateHeight);
    
    // **Draw the Heatmap Cells**
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            if (i < qValues.length && j < qValues[i].length) { 
                float qVal = qValues[i][j];
                int colorVal = getColorForQValue(qVal);
                fill(colorVal);
                rect(startX + (j * gridSize), startY + (i * stateHeight), gridSize, stateHeight);
            }
        }
    }
    
    // **Determine the contiguous block of states where facingWall == true**
    int facingWallStart = -1;
    // Since we are sorted by the boolean first (false first, true second)
    // the true states will be at the bottom of the sortedStates list.
    for (int i = 0; i < sortedStates.size(); i++) {
        if (sortedStates.get(i).facingWall) {
            facingWallStart = i;
            break;
        }
    }
    
    // **If there are states with facingWall == true, compute the bounding rectangle**
    if (facingWallStart != -1) {
        // All subsequent states are facingWall == true due to our sorting
        int facingWallEnd = sortedStates.size();
        int rectX = startX;
        int rectY = startY + (facingWallStart * stateHeight);
        int rectWidth = heatmapWidth;
        int rectHeight = (facingWallEnd - facingWallStart) * stateHeight;
        
        // **Draw the green border to highlight the group**
        noFill();
        stroke(0, 255, 0); // Green
        strokeWeight(3);
        rect(rectX, rectY, rectWidth, rectHeight);
        // Reset stroke settings to defaults if necessary
        strokeWeight(1);
        stroke(0);
    }
}

    
    // **Helper Function to Label Each Group**
    void labelGroup(String label, int startIdx, int endIdx, int startX, int startY, int stateHeight) {
        if (startIdx == -1 || endIdx == -1) return; // Skip if no valid range
    
        int midPoint = startIdx + (endIdx - startIdx) / 2; // Center the label within the group
        float labelY = startY + (midPoint * stateHeight) + (stateHeight / 2);
        
        fill(0);
        textAlign(RIGHT, CENTER);
        text(label, startX - 50, labelY);
    }


    int getColorForQValue(float qVal) {
        float logQVal = (qVal >= 0) ? log(1 + qVal) : -log(1 - qVal);
        
        int red, blue;
        if (logQVal >= 0) {
            red = (int) map(logQVal, 0, log(2), 150, 255);
            blue = (int) map(logQVal, 0, log(2), 100, 50);
        } else {
            red = (int) map(logQVal, -log(2), 0, 50, 150);
            blue = (int) map(logQVal, -log(2), 0, 255, 200); // **Increase blue intensity for negative values**
        }
        return color(red, 0, blue);
    }

}
