import processing.video.*;

int lineSize = 50;
Capture video;
float glitchStrength = 100;  // グリッチの強さ

void setup() {
  size(500, 375);
  //fullScreen();
  
  // カメラ映像を取得
  String[] cameras = Capture.list();
  if (cameras.length > 0) {
    video = new Capture(this, cameras[0]);
    video.start();
  }
  
  strokeWeight(2);
  noSmooth();
}

void draw() {
  if (video.available()) {
    video.read();  // カメラ映像を更新
  }
  
  background(0);  // 背景を黒に設定
  
  // ランダムで画像を歪ませる
  glitchEffect();

  // カメラ映像を表示
  image(video, 0, 0, width, height);
  
  // ランダムに線を描画
  for (int i = 0; i < 100000; i++) {
    drawOneLine();
  }
}

void glitchEffect() {
  // ランダムに画像を歪ませる
  loadPixels();
  for (int i = 0; i < pixels.length; i++) {
    if (random(1) < 0.05) {  // 5%の確率でグリッチを発生
      int offset = int(random(-glitchStrength, glitchStrength));
      int newIndex = i + offset;
      if (newIndex >= 0 && newIndex < pixels.length) {
        pixels[i] = pixels[newIndex];  // ピクセルをランダムに移動
      }
    }
  }
  updatePixels();
}

void drawOneLine() {
  int x = int(random(video.width));
  int y = int(random(video.height));

  color pixelColor = video.get(x, y);
  stroke(pixelColor);

  float r = random(1);

  // ランダムな方向に線を描く
  if (r < .25) {
    line(x - lineSize / 2, y, x + lineSize / 2, y);
  } else if (r < .5) {
    line(x, y - lineSize / 2, x, y + lineSize / 2);
  } else if (r < .75) {
    line(x - lineSize / 2, y - lineSize / 2,
      x + lineSize / 2,
      y + lineSize / 2);
  } else {
    line(x - lineSize / 2, y + lineSize / 2,
      x + lineSize / 2,
      y - lineSize / 2);
  }
}

void keyPressed() {
  // キー入力でグリッチの強さを変更
  if (key == 'w' || key == 'W') {
    glitchStrength += 5;
  } else if (key == 's' || key == 'S') {
    glitchStrength = max(1, glitchStrength - 5);
  }
}
