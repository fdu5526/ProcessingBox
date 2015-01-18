// Greater values increase disparity between split pieces
float MAX_CRACK_VARIATION = 1.4;

// Smaller values lead to more jagged edges, 
// larger values lead to better performance, simplified polygons
float MIN_CRACK_VERTEX_DISTANCE = 10;

/*
 The class inherit all the fields, constructors and functions 
 of the java.awt.Polygon class, including contains(), xpoint,ypoint,npoint
*/
 
 // Call .invalidate() any time the points change
class Poly extends java.awt.Polygon{
  public Poly(){
    super();
  }
  
  public Poly(int[] x,int[] y, int n){
    //call the java.awt.Polygon constructor
    super(x,y,n);
  }
 
  void drawMe(){
    beginShape();
    for(int i=0; i<npoints; i++){
      vertex(xpoints[i],ypoints[i]);
    }
    endShape(CLOSE);
  }
}

public Poly createPoly(ArrayList<Point>points){
  int n = points.size();
  
  int[] x = new int[n];
  int[] y = new int[n];
  
  for (int i = 0; i < n; ++i){
    Point p = points.get(i);
    
    x[i] = (int)p.x;
    y[i] = (int)p.y;
  }
  
  return new Poly(x,y,n);
}

public class Box {
  PApplet parent;
  Point center;
  float radius;
  color fillColor;
  
  boolean didStartDrag;
  boolean startInsideShape;
  boolean broken = false;
  Point startDragPoint;
  
  ArrayList<Point> coords;
  Poly poly;
  Point crackPoint;
  ArrayList<Point> endPoints;
  
  Poly shape1;
  Poly shape2;
  
  public void updatePoly(){
    int n = coords.size();
    
    int[] xs = new int[n];
    int[] ys = new int[n];
    
    for (int i = 0; i < n; ++i){
      Point p = coords.get(i);
      
      xs[i] = int(p.x);
      ys[i] = int(p.y);
    }
    
    poly = new Poly(xs, ys, n);
  }
  
  public void setupCoordinates(){
    coords.add(new Point(this.center.x - radius, 
                         this.center.y - radius));
                         
    coords.add(new Point(this.center.x + radius, 
                         this.center.y - radius));
                         
    coords.add(new Point(this.center.x + radius,
                         this.center.y + radius));
    
    coords.add(new Point(this.center.x - radius,
                         this.center.y + radius));
                         
    updatePoly();
  }
  
  public Box(PApplet parent, float x, float y, float size) {
    this.parent = parent;
    this.center = new Point(x, y);
    this.radius = size/2.0;
    
    coords = new ArrayList<Point>();
    
    setupCoordinates();
    
    didStartDrag = false;
    startInsideShape = false;
    broken = false;
    
    fillColor = color(255, 255, 255);
  }
  
  // based on psuedo-code from http://geomalgorithms.com/a13-_intersect-4.html
  ArrayList<Point> pointsOfIntersectionWithLineSegment(LineSegment seg, Point mouseP){
    Point p0 = seg.p1;
    Point p1 = seg.p2;
    
    int t_entering = 0; // max entering segment param
    int t_leaving = 1; // min leaving seg param
    
    LineSegment dS = new LineSegment(new Point (0, 0), p0.subtractFrom(p1)); // segment direction vector
    
    Point v0 = coords.get(coords.size() - 1);
    Point v1;
    
    ArrayList<Point> intersections = new ArrayList<Point>();
    
    seg.calculateSlopeAndIntercept();
    
    boolean shouldAddToShape1 = true;
    
    ArrayList<Point> shape1Points = new ArrayList<Point>();
    ArrayList<Point> shape2Points = new ArrayList<Point>();
    
    for (int i = 0; i < coords.size(); ++i){
      v1 = coords.get(i);
      LineSegment c_seg = new LineSegment(v0, v1);
      
      Point intercept = seg.intersection(c_seg);
      
      if (shouldAddToShape1){
        shape1Points.add(v0);
      } else {
        shape2Points.add(v0);
      }
      
      if (c_seg.isPointOnSegment(intercept)){
        intersections.add(intercept);
        
        // Add point to both shapes
        shape1Points.add(intercept);
        shape2Points.add(intercept);
        
        shouldAddToShape1 = !shouldAddToShape1;
      }
      
      // After everything is done
      v0 = v1;
    }
    
    shape1 = createPoly(shape1Points);
    
    // Ensures shape 2 is the one interacting with the mouse
    if (!shape1.contains(mouseP.x, mouseP.y)){
      shape2 = createPoly(shape2Points);
    } else {
      shape2 = shape1;
      shape1 = createPoly(shape2Points);
    }
    
    return intersections;
  }
  
  // BAD POINT HIT DETECTION, CONSIDER CONVEX HULL
  boolean isPointInsideShape(Point p){
    return poly.contains(p.x, p.y);
  }
  
  LineSegment generatePerpendicularLine(Point mouseP){
//    float x1 = center.x;
//    float y1 = center.y;
//    float x2 = mouseP.x;
//    float y2 = mouseP.y;
    
    LineSegment seg = new LineSegment(center, mouseP);
    
    if (abs(center.y - mouseP.y) < 0.001){
      return new LineSegment(3f/0, crackPoint);
    }
    
    seg.calculateSlopeAndIntercept();
    
    float slope = seg.slope;
    
    slope = - (1.0 / slope);
    
    float yIntercept = seg.yIntercept;
    
    return new LineSegment(slope, crackPoint);
  }
  
  void generateCrack(Point mouseP){
    /* 1) Generate a crack point at a random point between 
     * the center of the square and where the mouse is */
    float x1 = center.x;
    float y1 = center.y;
    float x2 = mouseP.x;
    float y2 = mouseP.y;
    
    float r = random(0.3, 0.65);
    
    crackPoint = new Point(x1+(x2-x1)*r, y1+(y2-y1)*r);
    
    /* 2) Find the line perpendicular to the line segment 
     * from crackPoint to the center of the polygon */
    LineSegment crackLine = this.generatePerpendicularLine(mouseP);
    
    /* 3) Generate the crack based on the given line, 
     * with variation on the crack for both pieces */
    //ArrayList<Point> 
    endPoints = this.pointsOfIntersectionWithLineSegment(crackLine, mouseP);
//    endPoints = new ArrayList<Point>();
//    endPoints.add(crackLine.p1);
//    endPoints.add(crackLine.p2);
    
    // Simplify crackPoint to nearest existing point within 
    // radius if possible to reduce polygon complexity
    
//    mouseP.
  }
  
  void mousePressed(){
    didStartDrag = true;
    
    Point p = new Point(mouseX, mouseY);
    startDragPoint = p;
    
    startInsideShape = isPointInsideShape(p);
    
    if (startInsideShape){
      generateCrack(p);
    }
  }
  
  void breakPieceOff(){
    broken = true;
    
    
  }
  
  void mouseDragged(){
    if (startInsideShape){
      // Dragging only works if the drag started inside the shape
      
      Point p = new Point(mouseX, mouseY);
      
      if (broken){ // Have box react to broken piece's movement
      
      } else if (p.squareDistanceTo(startDragPoint) > 400){
        breakPieceOff();
      }
    }
  }
  
  void mouseReleased(){
    didStartDrag = false;
    startInsideShape = false;
  }
  
  public void draw(){
    parent.fill(fillColor);
    parent.noStroke();
    
    poly.drawMe();
    
    if (crackPoint != null){
      parent.fill(255, 0, 0);
      ellipse(crackPoint.x, crackPoint.y, 3, 3);
      
      if (endPoints.size() > 1){
        parent.stroke(255, 0, 0);
        Point p1 = endPoints.get(0);
        Point p2 = endPoints.get(1);
        
        line(p1.x, p1.y, p2.x, p2.y);
      }
    }
    
    if (shape2 != null){
      fill(0, 255, 0);
      
      int n = shape2.npoints;
      int[] x = shape2.xpoints;
      int[] y = shape2.ypoints;
      
      beginShape();
      for(int i=0; i<n; i++){
        vertex(x[i], y[i]);
      }
      endShape(CLOSE);
    }
  }
}
