import processing.video.*;
import de.looksgood.ani.*;

import com.thomasdiewald.pixelflow.java.DwPixelFlow;
import com.thomasdiewald.pixelflow.java.imageprocessing.DwOpticalFlow;
import com.thomasdiewald.pixelflow.java.imageprocessing.filter.DwFilter;


static boolean useDemoVideo = true;

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
PGraphics2D imageBackground;
// PImage imageBlank;

Movie video;

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


  imageBackground=(PGraphics2D) createGraphics(camWidth, camHeight, P2D);
  imageBackground.beginDraw();
    imageBackground.image(cam, 0, 0);
  imageBackground.endDraw();

  pixelShader.set("u_background", imageBackground);


  loadImages();

  if(useDemoVideo){
    video = new Movie(this, "videos/1072317980-preview.mp4");
    video.loop();
    video.play();
  }

  initFlow();
}

void draw() {

  background(0);

  if(useDemoVideo){
    if(video.available()) {
      video.read();
      pg_cam.beginDraw();
        pg_cam.image(video, 0, 0);
      pg_cam.endDraw();

      opticalflow.update(pg_cam); 
    }
  }else{
    if(cam.available()) {
      cam.read();

      pg_cam.beginDraw();
        pg_cam.image(cam, 0, 0);
      pg_cam.endDraw();

      opticalflow.update(pg_cam); 
    }
  }
  DwFilter.get(context).luminance.apply(pg_cam, pg_cam);
  
  
  pushMatrix();
  shader(pixelShader);
  
  pixelShader.set("pixelSize", pixelSize);  // Try 5, 10, 20, etc.
  
  if(useDemoVideo){
    pixelShader.set("u_texture", video);
  }else{
    pixelShader.set("u_texture", cam); // Or use cam if using webcam
  }

  // pixelShader.set("time", millis()/(100+abs(sin(frameCount/20.0)*500)));
  pixelShader.set("time", millis()/1000.0);

  float ss= sin(strengthTimer.value*PI)+0.15;
  pixelShader.set("strength", ss);
  // pixelShader.set("strength", ss+map(mouseY, 0, height, 0.0, 1.0));
  
  float pp= state==State.CAPTURE? 1.0-progressTimer.value: progressTimer.value;  
  pixelShader.set("progress", pp);
  pixelShader.set("u_character", images[index]);
  switch(state){
    case IDLE:
      pixelShader.set("u_title", imageCover);
      pixelShader.set("text_progress", textTimer.value);
      // if(frameCount%120==0 && random(0, 1)<0.5){
      //   setNextIndex();
      // }
      break;
    case CAPTURE:
      pixelShader.set("u_title", imageEnd);
      pixelShader.set("text_progress", constrain(sin(textTimer.value*PI)*2.0, 0,1));
      break;    
    default :
      pixelShader.set("text_progress", 1.0-textTimer.value);
      break;
  }

  pixelShader.set("u_background", imageBackground);      

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
// image(imageBackground, 0, 0, width/4, height/4);
  


  // image(cam, 0, 0, width, height);
}

void setNextIndex(){
  
  if(useDemoVideo) index=(index+1)%numImage;
  else index=floor(random(0, numImage));

}

void setState(State set){
  switch(set){
    case IDLE:
      progressTimer.reset();
      textTimer.start(2,0);
      break;
    case PROCESSING:
      progressTimer.start(0.2, 0.5);
      strengthTimer.start(0.8, 0);
      textTimer.start(0.5,0);
      // index=floor(random(0, numImage));
      setNextIndex();
      break;
    case CAPTURE:
      progressTimer.start(1.5, 3);
      strengthTimer.start(0.8, 3.7);
      textTimer.start(4.5,0);
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
    case 'p':
      imageBackground.beginDraw();
        if(useDemoVideo) imageBackground.image(video, 0, 0);
        else imageBackground.image(cam, 0, 0);
      imageBackground.endDraw();
      break;
  } 
}
