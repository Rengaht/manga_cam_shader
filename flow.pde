// optical flow
DwPixelFlow context;
DwOpticalFlow opticalflow;
PGraphics2D pg_cam;
PGraphics2D pg_oflow;

void initFlow(){

    context = new DwPixelFlow(this);
    context.print();
    context.printGL();

    opticalflow = new DwOpticalFlow(context, camWidth, camHeight);

    pg_cam = (PGraphics2D) createGraphics(camWidth, camHeight, P2D);
    pg_cam.noSmooth();
        
    pg_oflow = (PGraphics2D) createGraphics(camWidth, camHeight, P2D);
    pg_oflow.smooth(4);

}

void drawFlow(){
    // render Optical Flow
    pg_oflow.beginDraw();
        pg_oflow.clear();
    // pg_oflow.image(pg_cam, 0, 0, width, height);
    pg_oflow.endDraw();
    
    // flow visualizations
    opticalflow.param.display_mode = 0;
    opticalflow.renderVelocityShading(pg_oflow);
    // opticalflow.renderVelocityStreams(pg_oflow, 5);
    
    // display result
    // background(0);
    // image(pg_oflow, 0, 0, width, height);
    pg_oflow.loadPixels();
}