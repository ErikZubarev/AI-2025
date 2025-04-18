class QuadTreeMemory{  
  Sprite holding; 
  QuadTreeMemory[] children;
  boolean subdivided;
  boolean explored;
  Boundry boundry;
  int depth;
    
  // Constructor ======================================  
  QuadTreeMemory(Boundry boundry, int depth){
    this.boundry = boundry;
    subdivided = false;
    explored = false;
    this.depth = depth;
    children = new QuadTreeMemory[4];
    
  }
    
  // ==================================================  
  void subdivide(){
    if(depth <= 0){
      return;
    }
    
    float x = boundry.x;
    float y = boundry.y;
    float half_w = boundry.width /2;
    float half_h = boundry.height /2;
    int lowerDepth = depth-1;
    
    
    children[0] = new QuadTreeMemory(new Boundry(x, y, half_w, half_h), lowerDepth);
    children[1] = new QuadTreeMemory(new Boundry(x + half_w, y, half_w, half_h), lowerDepth);
    children[2] = new QuadTreeMemory(new Boundry(x, y + half_h, half_w, half_h), lowerDepth);
    children[3] = new QuadTreeMemory(new Boundry(x + half_w, y + half_h, half_w, half_h), lowerDepth);

    //printArray(children);
    subdivided = true;
  }
    
  // ==================================================  
  void updateExploredStatus(Boundry viewArea){
    
    if(explored){
      return;
    }
    
    if(!boundry.intersects(viewArea)){
      return;
    }
    
    if(depth <= 0){
      explored = true;
      return;
    }
    
    if(boundry.isWithin(viewArea)){
      this.explored = true;
      checkChildren();
      return;
    }
    
    if(!subdivided){
      subdivide();
    }
    
    for(int i = 0; i < children.length; i++){
      children[i].updateExploredStatus(viewArea);
    }
    
    checkChildren();
  }
  
  // ==================================================  
void checkChildren() {
    if (!subdivided) {
      return;
    }

    // Check if all children actually exist (safety check)
    for(QuadTreeMemory child : children) {
        if (child == null) {
            // This shouldn't happen with the current subdivide, but good practice
            println("Warning: Null child found during checkChildren at depth " + depth);
            return;
        }
    }


    // --- Check Explored Status ---
    boolean allExplored = true;
    boolean anyExplored = false; // Optional: To know if at least one is explored
    for (QuadTreeMemory child : children) {
      if (!child.explored) {
        allExplored = false;
      } else {
        anyExplored = true;
      }
    }


    // --- Decide whether to Prune ---
    // Only prune if ALL children are explored.
    if (allExplored) {
      println("Pruning node (all children explored) at depth " + depth + " - Coords: " + boundry.x + "," + boundry.y); // Add Debug Info
      this.explored = true; // The parent node is now considered fully explored
      this.holding = null;  // Clear parent holding if pruning explored children (or decide specific logic)
      removeChildren();     // Perform the prune, setting subdivided = false
    }

  }
  // ==================================================
  void removeChildren() {
    // Clear references to children for garbage collection
    for (int i = 0; i < children.length; i++) {
        children[i] = null;
    }
    // Setting children = new QuadTreeMemory[4] is also okay but less explicit about nulling references.

    subdivided = false; // Mark as no longer subdivided (correct for pruning)
    println("Children removed for node at depth " + depth); // Debug Info
  }
  
  // ==================================================
  void insert(Sprite obj){
    println("inserting " + obj);
    if(explored){
      return;
    }
    
    if(holding != null){
      return;
    }

    if(!boundry.intersects(obj.boundry)){
      return;
    }
    
    if(depth <= 0){
      holding = obj;
      return;
    }
    
    if(boundry.isWithin(obj.boundry)){
      holding = obj;
      return;
    }
    
    if(!subdivided){
      subdivide();
    }
    
    // Check which child object fits into
    for(int i = 0; i < children.length; i++){
      if (children[i].boundry.intersects(obj.boundry)){
        children[i].insert(obj);
        holding = null;
      }
    }
    
    checkChildren();
  }
  
  // ==================================================
  Sprite[] query(Boundry area){
    Sprite[] found = new Sprite[]{};
    
    if(!boundry.intersects(area)){
      return found;
    }
    
    if (area.intersects(holding.boundry)){
      append(found, holding);
    }
    
    for(int i = 0; i < children.length; i++){
      append(found, children[i].query(area));
    }
    
    return found;
  }

  // ==================================================
  // RECURSIVE DRAW METHOD (Replace your existing draw method with this)
  void draw() {
    // Style for the boundary rectangle
    noFill(); // See through the rectangles
    strokeWeight(1);

    // Color based on explored status
    if (explored) {
      // Maybe draw explored leaves differently?
      if (!subdivided) { // Only fill leaves fully explored
         fill(0, 0, 255, 20); // Light blue fill for explored leaf nodes
      }
      stroke(0, 0, 255, 150); // Blue border for explored nodes
    } else {
      stroke(100, 100, 100, 100); // Grey border for unexplored nodes
    }

    // Draw the boundary rectangle for THIS node
    // Use rect(x, y, width, height)
    rect(boundry.x, boundry.y, boundry.width, boundry.height);

    // If this node is subdivided, recursively call draw on its children
    if (subdivided) {
      for (QuadTreeMemory child : children) {
         if (child != null) { // Important check!
             child.draw(); // Recursive call
         }
      }
    }

    // Optional: Visualize the 'holding' object if it exists at this node level
    if (holding != null && holding.position != null) {
        fill(0, 255, 0, 150); // Green circle at object's position
        noStroke();
        ellipse(holding.position.x, holding.position.y, 5, 5);
    }
  }
}
