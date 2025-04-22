import processing.video.*;
import de.looksgood.ani.*;

import com.thomasdiewald.pixelflow.java.DwPixelFlow;
import com.thomasdiewald.pixelflow.java.imageprocessing.DwOpticalFlow;
import com.thomasdiewald.pixelflow.java.imageprocessing.filter.DwFilter;


PShader pixelShader;  

Capture cam;
static float pixelSize=8;
static int camWidth = 1280;
static int camHeight = 720;
static String deviceID="FaceTime HD Camera (Built-in)";

static int numImage=3;
PImage images[] = new PImage[numImage];
PImage imageCover;
PImage imageEnd;
PImage imageNext;
// PImage imageBlank;

enum State {
  IDLE,
  PROCESSING,
  CAPTURE,
}

State state = State.IDLE;
Timer progressTimer;
Timer strengthTimer;
Timer textTimer;

int index=0;


  
public void settings() {
  size(1280, 720, P2D);
  smooth(4);
}


void setup() {
     
  pixelShader = loadShader("pixel.frag","pixel.vert");
  pixelShader.set("u_resolution", float(width), float(height));
  pixelShader.set("threshold", 0.5);
  pixelShader.set("texOffset", 1.0 / float(width), 1.0 / float(height));


  cam = new Capture(this, camWidth, camHeight, deviceID);
  cam.start();


  progressTimer=new Timer(0.0, 1.0, 3, 0);
  strengthTimer=new Timer(0.0, 1.0, 3, 0);
  textTimer=new Timer(0.0, 1.0, 2, 0);
  textTimer.start();

  loadImages();

  initFlow();
}

void draw() {

  if(cam.available()) {
    cam.read();

    pg_cam.beginDraw();
    pg_cam.image(cam, 0, 0);
    pg_cam.endDraw();

    opticalflow.update(pg_cam); 
  }
  DwFilter.get(context).luminance.apply(pg_cam, pg_cam);
  
  
  pushMatrix();
  shader(pixelShader);
  
  pixelShader.set("pixelSize", pixelSize);  // Try 5, 10, 20, etc.
  pixelShader.set("u_texture", cam); // Or use cam if using webcam
  // pixelShader.set("time", millis()/(100+abs(sin(frameCount/20.0)*500)));
  pixelShader.set("time", millis()/1000.0);

  float ss= sin(strengthTimer.value*PI)+0.15;
  // pixelShader.set("strength", ss);
  pixelShader.set("strength", map(mouseY, 0, height, 0.0, 1.0));
  
  float pp= state==State.CAPTURE? 1.0-progressTimer.value: progressTimer.value;  
  pixelShader.set("progress", pp);
  pixelShader.set("u_character", images[index]);
  switch(state){
    case IDLE:
      pixelShader.set("u_title", imageCover);
      pixelShader.set("text_progress", textTimer.value);
      break;
    case CAPTURE:
      pixelShader.set("u_title", imageEnd);
      pixelShader.set("text_progress", sin(textTimer.value*PI));
      break;    
    default :
      pixelShader.set("text_progress", 1.0-textTimer.value);
      break;
  }

  drawFlow();
  pixelShader.set("u_flow", pg_oflow);

  // rect(0, 0, width, height);
  beginShape();
  // texture(cam);
    vertex(0, 0,0,0); 
    vertex(width, 0,1,0);
    vertex(width, height,1,1);
    vertex(0, height,0,1);
  endShape();

  popMatrix();
  resetShader();

 String txt_fps = String.format("[%s] [%7.2f fps] [%s] [%2f]",  getClass().getSimpleName(), frameRate, state.toString(), progressTimer.value);
  surface.setTitle(txt_fps);

  progressTimer.update();
  strengthTimer.update();
  textTimer.update();

  if(progressTimer.value>=1){
    onProgressEnd();
  }

// drawFlow();
  


  // image(cam, 0, 0, width, height);
}

void setState(State set){
  switch(set){
    case IDLE:
      progressTimer.reset();
      textTimer.start(2,0);
      break;
    case PROCESSING:
      progressTimer.start(3, 2);
      strengthTimer.start(4, 0);
      textTimer.start(1,0);
      index=floor(random(0, numImage));
      break;
    case CAPTURE:
      progressTimer.start(2, 3);
      strengthTimer.start(2, 2);
      textTimer.start(5,0);
      break;
    
  }
  state=set;
  println("set State: "+state+" =>"+set);
}

void onProgressStart(){
  println("Processing Started");  
}

void onProgressEnd(){
  println("Processing Ended", state.toString());
    
  switch(state){
      case PROCESSING:
        setState(State.CAPTURE);
        break;
      case CAPTURE:
        setState(State.IDLE);
        break;
  }
}

void loadImages(){
  
  for (int i=0; i<numImage; i++){
    images[i] = loadImage("images/image-"+(i+1)+".png");
  }

  imageCover = loadImage("images/cover.png");
  imageEnd = loadImage("images/end.png");
  imageNext = loadImage("images/next.png");
  // imageBlank = loadImage("images/blank.png");

}

void keyPressed(){
  switch(key){
    case 'a':
      setState(State.PROCESSING);
      break;
  } 
}
