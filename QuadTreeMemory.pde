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

    boolean allExplored = true;
    Sprite item = children[0].holding;

    for (QuadTreeMemory child : children) {
        if (!child.explored || child.holding != item) {
            allExplored = false;
            break; // Exit the loop immediately since the conditions are not satisfied
        }
    }

    if (allExplored) {
        println("Pruning node (all children explored) at depth " + depth + " - Coords: " + boundry.x + "," + boundry.y); // Debug info
        this.explored = true;
        removeChildren();     
    }
  }
  // ==================================================
  void removeChildren() {
    for (int i = 0; i < children.length; i++) {
        children[i] = null;
    }

    subdivided = false; 
  }
  
  // ==================================================
  void insert(Sprite obj, Boundry area){
    boolean bingBang = false;
     ArrayList<Sprite> found = query(area);
     
     if(found.size() != 0){
       for(Sprite bing : found){
         if(bing == obj){
           bingBang = true;
         }
       }
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
        children[i].insert(obj, area);
        holding = null;
      }
    }
    
    checkChildren();
  }
  
  // ==================================================
  ArrayList<Sprite> query(Boundry area){
    ArrayList<Sprite> found = new ArrayList<Sprite>();
    println("test");
    
    if(!boundry.intersects(area)){
      return found;
    }
    
    
    if (holding != null && area.intersects(holding.boundry)){
      found.add(holding);
    }
    
    for(QuadTreeMemory child : children){
      if(child != null){
        found.addAll(child.query(area));
      }
    }
    
    printArray(found);
    
    return found;
  }

  // ==================================================
  void draw() {
    noFill();
    strokeWeight(1);

    if (explored) {
      if (!subdivided) { 
         fill(0, 0, 255, 20); 
      }
      stroke(0, 0, 255, 150);
    } else {
      stroke(100, 100, 100, 100);
    }

    rect(boundry.x, boundry.y, boundry.width, boundry.height);

    if (subdivided) {
      for (QuadTreeMemory child : children) {
         if (child != null) { 
             child.draw(); 
         }
      }
    }

    if (holding != null && holding.position != null) {
        fill(0, 255, 0, 150);
        noStroke();
        ellipse(holding.position.x, holding.position.y, 5, 5);
    }
  }
}
