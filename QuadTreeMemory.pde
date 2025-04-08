class QuadTreeMemory{  
  Sprite holding; 
  QuadTreeMemory[] children;
  boolean subdivided;
  Boundry boundry;
  
  QuadTreeMemory(Boundry boundry){
    this.boundry = boundry;
    children = new QuadTreeMemory[]{};
    subdivided = false;
  }
  
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
  }
  
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
