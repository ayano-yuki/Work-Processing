import processing.sound.*;

AudioIn in;
Amplitude amp;

void setup() {
  size(800, 600);
  strokeWeight(0);
  background(255);
  frameRate(90);
  
  in = new AudioIn(this);
  in.start();

  amp = new Amplitude(this);
  amp.input(in);
}

void draw() {
  background(255);

  float a = amp.analyze() * 10;
  fill(#ff6347);
  circle(width/2, height/2, 1000*a);

}
