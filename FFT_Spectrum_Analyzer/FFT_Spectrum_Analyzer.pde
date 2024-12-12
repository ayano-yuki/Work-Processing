import processing.sound.*;

FFT fft;
AudioIn in;
int bands = 128;
float[] spectrum = new float[bands];

void setup() {
  size(400, 300);
  background(255);
    
  fft = new FFT(this, bands);
  in = new AudioIn(this, 0);
  
  in.start();
  
  fft.input(in);
}      

void draw() { 
  background(255);
  noStroke();
  fill(208, 208, 208);

  fft.analyze(spectrum);
  float bar_w = width / bands;
  float margin = 10;
  float start_h = height - margin;
  
  for(int i = 0; i < bands; i++){
    float bar_h = height * spectrum[i] * 100;
    rect(bar_w*i + margin, start_h, bar_w, -bar_h);
  } 
}
