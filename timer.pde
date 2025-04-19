class Timer{
    float from;
    float to;
    float duration;
    float delay;
    float startTime;
    float value;

    boolean playing = false;

    Timer(float from, float to, float duration, float delay){
        this.from = from;
        this.to = to;
        this.duration = duration*1000;        
        this.delay = delay*1000;
    }

    void start(){
        reset();
        playing = true;
    }
    void start(float duration, float delay){
        this.duration = duration*1000;
        this.delay = delay*1000;
        start();
    }
    void update(){

        if(!playing){
            return;
        }

        float elapsed = millis() - startTime -delay;
        value = constrain(map(elapsed, 0, duration, from, to), from, to);
        // println("elapsed: "+elapsed+" value: "+value);
    }
    void reset(){
        startTime = millis();
        value = from;
        playing = false;
    }
    
}
