import processing.sound.*;

FFT fft;
AudioIn in;
int bands = 128;
float[] spectrum = new float[bands];

void setup() {
  size(400, 300);
  background(255);

  // FFTとAudioInの初期化
  fft = new FFT(this, bands);
  in = new AudioIn(this, 0);

  // 音声入力を開始
  in.start();

  // FFTの入力ソースを設定
  fft.input(in);
}      

void draw() { 
  background(255);
  noStroke();
  fill(100, 150, 255); // バーの色

  // FFTでスペクトラムを解析
  fft.analyze(spectrum);

  float barWidth = width / (float)bands; // 各バーの幅

  // 各周波数帯域の振幅を描画
  for (int i = 0; i < bands; i++) {
    float amplitude = spectrum[i] * height; // 振幅を画面の高さに合わせてスケール
    float x = i * barWidth; // 横軸に音程（周波数帯）
    float y = height - amplitude; // 縦軸に音量（振幅）

    rect(x, y, barWidth, amplitude); // バーを描画
  }
}
