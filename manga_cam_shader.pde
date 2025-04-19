import processing.video.*;

PShader pixelShader;  

Capture cam;
static int camWidth = 1280;
static int camHeight = 720;
static String deviceID="FaceTime HD Camera (Built-in)";

void setup() {
  size(1280, 720, P2D);
     
  pixelShader = loadShader("pixel.frag");
  pixelShader.set("u_resolution", float(width), float(height));
  pixelShader.set("threshold", 0.5);
  pixelShader.set("texOffset", 1.0 / float(width), 1.0 / float(height));


  cam = new Capture(this, camWidth, camHeight, deviceID);
  cam.start();

}

void draw() {

  if(cam.available()) {
    cam.read();
  }
  
  
  shader(pixelShader);
  
  pixelShader.set("pixelSize", 8.0);  // Try 5, 10, 20, etc.
  pixelShader.set("u_texture", cam); // Or use cam if using webcam
  pixelShader.set("time", millis()/(100+abs(sin(frameCount/20.0)*500)));
  pixelShader.set("strength", mouseY/float(height));
  
  // rect(0, 0, width, height);
  beginShape();
  // texture(cam);
    vertex(0, 0,0,0); 
    vertex(width, 0,1,0);
    vertex(width, height,1,1);
    vertex(0, height,0,1);
  endShape();

  // image(cam, 0, 0, width, height);
}
  