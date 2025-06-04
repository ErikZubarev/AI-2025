class Heatmap {
  int gridSize = 10;  // Defines the resolution of the heatmap
  float[][] qValues;  // Stores Q-values in a matrix format
  int rows, cols;
  
  Heatmap(int rows, int cols) {
    this.rows = rows;
    this.cols = cols;
    qValues = new float[rows][cols];  // Initialize the Q-table
  }
  
  void updateHeatmap(HashMap<Tank.State, HashMap<String, Float>> qTable) {
      int rowIdx = 0;
      for (Tank.State state : qTable.keySet()) {
        if (rowIdx >= rows) break; // Avoid exceeding array bounds
        int colIdx = 0;
        for (String action : qTable.get(state).keySet()) {
          if (colIdx >= cols) break; // Avoid exceeding bounds
          qValues[rowIdx][colIdx] = qTable.get(state).get(action);  // Fetch Q-value
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
  
    if(cols == 0 || rows == 0){
      return;
    }
    // **Calculate dynamic height per state**
    gridSize = heatmapWidth / cols;  // Actions fill full width
    int stateHeight = heatmapHeight / rows;  // States resize dynamically
  
    // **Position heatmap in center**
    int startX = centerX - (heatmapWidth / 2);
    int startY = centerY - (heatmapHeight / 2);
  
    // **Draw background border**
    fill(50);
    rect(startX - borderSize, startY - borderSize, heatmapWidth + (borderSize * 2), heatmapHeight + (borderSize * 2));
  
    // **Draw Action Labels at the Top**
    textAlign(CENTER, CENTER);
    textSize(16);
    fill(0); // Black text for readability
    for (int j = 0; j < cols; j++) {
      String actionName = qLearner.actions[j]; // Fetch action name
      text(actionName, startX + (j * gridSize) + (gridSize / 2), startY - 25); // Position above columns
    }
  
    // **Draw heatmap**
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        float qVal = qValues[i][j];
        int colorVal = getColorForQValue(qVal);
  
        fill(colorVal);
        rect(startX + (j * gridSize), startY + (i * stateHeight), gridSize, stateHeight);
      }
    }
  }

  
int getColorForQValue(float qVal) {
    int red = (int) map(qVal, -1, 0, 255, 128);   // Red fades toward gray at 0
    int green = (int) map(qVal, 0, 1, 128, 255);  // Green intensifies beyond gray at 0
    int blue = (int) map(qVal, -1, 1, 128, 128);  // Keep blue balanced for gray effect

    return color(red, green, blue);
}

}
