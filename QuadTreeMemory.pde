  class QuadTreeMemory{  
  Sprite holding; 
  QuadTreeMemory[] children = {};
  boolean subdivided;
  boolean explored;
  Boundry boundry;
    
  // Constructor ======================================  
  QuadTreeMemory(Boundry boundry){
    this.boundry = boundry;
    subdivided = false;
    explored = false;
  }
    
  // ==================================================  
  void subdivide(){
    float x = boundry.x;
    float y = boundry.y;
    float half_w = boundry.width /2;
    float half_h = boundry.height /2;
    
    append(children, new QuadTreeMemory(new Boundry(x, y, half_w, half_h))); 
    append(children, new QuadTreeMemory(new Boundry(x + half_w, y, half_w, half_h))); 
    append(children, new QuadTreeMemory(new Boundry(x, y + half_h, half_w, half_h)));
    append(children, new QuadTreeMemory(new Boundry(x + half_w, y + half_h, half_w, half_h)));
    
    subdivided = true;
  }
    
  // ==================================================  
  void updateExploredStatus(Boundry viewArea){
    if(!boundry.intersects(viewArea)){
      return;
    }
    
    if(boundry.isWithin(viewArea)){
      this.explored = true;
      removeChildren(); //Potential issue with children holding items
      return;
    }
    
    if(!subdivided){
      subdivide();
    }
    
    for(int i = 0; i < children.length; i++){
      children[i].updateExploredStatus(viewArea);
    }
    
    checkChildren(); // potential issue with children that are supposed to hold items, but haven't yet
  }
  
  // ==================================================  
  void checkChildren(){
    if (!subdivided){
       return; 
    }
    
    // Reverse XOR for each explored child 
    // All false will return true, all true will return true
    // while a mix of false and true will return false -> children are not identical
    boolean identicalChildren = 
                  !(children[0].explored ^
                  children[1].explored ^
                  children[2].explored ^
                  children[3].explored);
    
    Sprite firstChildHolding = children[0].holding;
    for(int i = 0; i < children.length; i++){
      if(firstChildHolding != children[i].holding){
        identicalChildren = false;
      }
    }
    
    if(identicalChildren){
       holding = firstChildHolding;
       removeChildren();
    }
  }
  
  // ==================================================
  void removeChildren(){
       QuadTreeMemory[] empty = {};
       children = empty;
  }
  
  // ==================================================
  void insert(Sprite obj){
    if(!boundry.intersects(obj.boundry)){
      return;
    }
    
    if(holding == null){
      holding = obj;
      return;
    }
    
    if(!subdivided){
      subdivide();
    }
    
    // Check which child object fits into
    for(int i = 0; i < 4; i++){ // 4 because max 4 children per node.
      if (children[i].boundry.intersects(obj.boundry)){
        children[i].insert(obj);
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
}
