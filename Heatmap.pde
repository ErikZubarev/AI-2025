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
        int centerX = width / 2;     // Center X of screen
        int centerY = height / 2;    // Center Y of screen
        int heatmapWidth = 600;      // Fixed width for actions
        int heatmapHeight = 600;     // Fixed height area for states
        int borderSize = 20;         // Optional border for visibility
    
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
    
        // Draw the background border for the heatmap
        fill(50);
        rect(startX - borderSize, startY - borderSize, heatmapWidth + (borderSize * 2), heatmapHeight + (borderSize * 2));
    
        // Draw Action Labels at the top
        textAlign(CENTER, CENTER);
        textSize(16);
        fill(0);
        for (int j = 0; j < cols; j++) {
            String actionName = qLearner.actions[j];
            text(actionName, startX + (j * gridSize) + (gridSize / 2), startY - 25);
        }
    
        // Draw Heatmap Cells
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
    
        // Identify boundary between the two facingWall groups:
        int facingWallBoundary = -1;
        for (int i = 0; i < sortedStates.size(); i++) {
            if (sortedStates.get(i).facingWall) {
                facingWallBoundary = i;
                break;
            }
        }
        
        // Label enemy proximity groups separately for states with facingWall==false
        if (facingWallBoundary == -1) {
            // All states have facingWall==false; label the entire heatmap.
            labelEnemyCategories(0, sortedStates.size(), startX, startY, stateHeight, false);
        } else {
            // Label the false block (top)
            labelEnemyCategories(0, facingWallBoundary, startX, startY, stateHeight, false);
            // Label the true block (bottom)
            labelEnemyCategories(facingWallBoundary, sortedStates.size(), startX, startY, stateHeight, true);
        }
    
        // Draw a green rectangle around the block with facingWall == true
        if (facingWallBoundary != -1) {
            int rectX = startX;
            int rectY = startY + (facingWallBoundary * stateHeight);
            int rectWidth = heatmapWidth;
            int rectHeight = (sortedStates.size() - facingWallBoundary) * stateHeight;
            noFill();
            stroke(0, 255, 0);  // Green border
            strokeWeight(3);
            rect(rectX, rectY, rectWidth, rectHeight);
            // Reset stroke to defaults if necessary
            strokeWeight(1);
            stroke(0);
        }
    }
    
    // Helper function to label enemy category groups within a block.
    // The parameter "blockIsWall" indicates if this block is for states where facingWall==true.
    void labelEnemyCategories(int blockStart, int blockEnd, int startX, int startY, int stateHeight, boolean blockIsWall) {
        int closeStart = -1, mediumStart = -1, farStart = -1;
        
        // Iterate only over states in this block.
        for (int i = blockStart; i < blockEnd; i++) {
            Tank.State state = sortedStates.get(i);
            if (state.nearestEnemyDistCategory == 1 && closeStart == -1) {
                closeStart = i;
            }
            if (state.nearestEnemyDistCategory == 2 && mediumStart == -1) {
                mediumStart = i;
            }
            if (state.nearestEnemyDistCategory >= 3 && farStart == -1) {
                farStart = i;
            }
        }
        
        // Determine end indexes for groups: if boundaries not found, consider blockEnd as the end.
        int closeEnd = (mediumStart != -1) ? mediumStart : blockEnd;
        int mediumEnd = (farStart != -1) ? farStart : blockEnd;
        
        // Optionally adjust the label text for states facing a wall.
        String closeLabel = "Close";
        String mediumLabel = "Medium";
        String farLabel = "Far/\nNone";
        
        if (closeStart != -1)
            labelGroup(closeLabel, closeStart, closeEnd, startX, startY, stateHeight);
        if (mediumStart != -1)
            labelGroup(mediumLabel, mediumStart, mediumEnd, startX, startY, stateHeight);
        if (farStart != -1)
            labelGroup(farLabel, farStart, blockEnd, startX, startY, stateHeight);
    }
    
    // This method draws a label for a group of enemy distance states
    void labelGroup(String label, int startIdx, int endIdx, int startX, int startY, int stateHeight) {
        if (startIdx == -1 || endIdx == -1) return;
        int midPoint = startIdx + (endIdx - startIdx) / 2;
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
