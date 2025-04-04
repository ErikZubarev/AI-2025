class QuadTreeMemory{
  float x,y,h,w;
  Sprite[] objects; 
  QuadTreeMemory[] children;
  boolean isEmpty;
  
  QuadTreeMemory(float x, float y, float w, float h){
    this.x = x;
    this.y = y;
    this.h = h;
    this.w = w;
    
    children = new QuadTreeMemory[]{};
    objects = new Sprite[]{}; // Ally, Enemy, Tree, Landmine
    isEmpty = true;
  }
  
  void subdivide(){
    float half_w = this.w /2;
    float half_h = this.h /2;
    append(children, new QuadTreeMemory(this.x, this.y, half_w, half_h)); //NW
    append(children, new QuadTreeMemory(this.x + half_w, this.y, half_w, half_h)); //NE
    append(children, new QuadTreeMemory(this.x, this.y + half_h, half_w, half_h)); //SW
    append(children, new QuadTreeMemory(this.x + half_w, this.y + half_h, half_w, half_h)); //SE
  }
  
  void insert(Sprite obj){
    isEmpty = false;
    if(children.length == 0){
      append(objects, obj);
      return;
    }
    
    // Check which child object fits into
    for(int i = 0; i < 4; i++){ // 4 because max 4 children per node.
      if (children[i].contains(obj.position.x, obj.position.y)){
        children[i].insert(obj);
      }
    }
  }
  
  // Check if coordinates are fit inside this node
  boolean contains(float x, float y){
    return 
      this.x <= x && 
      x < this.x + this.w && 
      this.y <= y && 
      y < this.y + this.h;
  }
  
  boolean isEmpty(){
    return this.isEmpty;
  }
}
