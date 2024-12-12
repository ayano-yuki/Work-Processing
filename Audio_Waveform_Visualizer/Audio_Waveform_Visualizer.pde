import processing.sound.*;

AudioIn in;
Amplitude amp;
Waveform waveform;

int samples = 1024;

void setup() {
  size(400, 300);
  strokeWeight(0);
  background(255);
  frameRate(90);
  
  in = new AudioIn(this);
  in.start();

  waveform = new Waveform(this, samples);
  waveform.input(in);
}

void draw() {
  background(255);
  stroke(0);
  strokeWeight(2);
  noFill();

  waveform.analyze();

  beginShape();
  for(int i = 0; i < samples; i++)
  {
    vertex(
      map(i, 0, samples, 0, width),
      map(waveform.data[i], -1, 1, 0, height)
    );
  }
  endShape();
}
