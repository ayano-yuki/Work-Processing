import processing.sound.*;
import processing.video.*;
import gab.opencv.*;
import java.awt.Rectangle;

Player player;
ArrayList<Bullet> bullets;
ArrayList<Enemy> enemies;

Capture cam;
OpenCV opencv;
AudioIn input;
Amplitude amp;

int enemySpawnInterval = 60;
int frameCounter = 0;
boolean gameStarted = false;
float threshold = 0.1;
int laneCount = 5;
float laneWidth;
int score = 0;

int initialEnemyCount = 2;
int initialEnemySpeed = 2;
float redEnemySpawnRate = 0.4;  // 赤色敵の出現率
float whiteEnemySpawnRate = 0.3; // 白色敵の出現率

void setup() {
  fullScreen();
  laneWidth = width / laneCount;
  resetGame();

  // 使用可能なカメラを取得
  String[] cameras = Capture.list();
  if (cameras.length == 0) {
    println("No cameras available.");
    exit();
  }

  // カメラの設定（ここでは2番目のカメラを使用）
  cam = new Capture(this, cameras[1]);
  cam.start();
  opencv = new OpenCV(this, cam.width, cam.height);
  opencv.startBackgroundSubtraction(15, 9, 0.5);

  // 音声入力の設定
  input = new AudioIn(this, 0);
  input.start();
  amp = new Amplitude(this);
  amp.input(input);

  // 顔認識用にOpenCVを設定
  opencv.loadCascade("haarcascade_frontalface_default.xml");
}

void draw() {
  background(0);

  if (!gameStarted) {
    fill(255);
    textAlign(CENTER);
    textSize(40);
    text("Press ENTER to Start", width / 2, height / 2);
    return;
  }

  // カメラ映像の更新
  if (cam.available()) {
    cam.read();
    opencv.loadImage(cam);
  }

  // プレイヤーの更新・表示
  player.update();
  player.display();

  // 弾の更新・表示
  for (int i = bullets.size() - 1; i >= 0; i--) {
    Bullet b = bullets.get(i);
    b.update();
    b.display();
    if (b.isOffScreen()) {
      bullets.remove(i);
    }
  }

  // 敵の生成
  frameCounter++;
  if (frameCounter % enemySpawnInterval == 0) {
    int lane = (int) random(laneCount);
    float x = lane * laneWidth + laneWidth / 2;

    if (random(1) < redEnemySpawnRate) {
      enemies.add(new Enemy(x, 0, color(255, 0, 0), 2));  // 赤色の敵、ライフ2
    } else if (random(1) < whiteEnemySpawnRate) {
      enemies.add(new Enemy(x, 0, color(255), 1));  // 白色の敵、ライフ1
    }
  }

  // 敵の更新・表示
  for (int i = enemies.size() - 1; i >= 0; i--) {
    Enemy e = enemies.get(i);
    e.update();
    e.display();

    if (e.isOffScreen()) {
      enemies.remove(i);
      player.decreaseLife();
      if (player.isGameOver()) {
        gameStarted = false;
      }
    } else if (e.hitsPlayer(player)) {
      enemies.remove(i);
      player.decreaseLife();
      if (player.isGameOver()) {
        gameStarted = false;
      }
    } else if (e.isHit(bullets)) {
      enemies.remove(i);
      score += 10;
    }
  }

  // スコアとライフの表示
  fill(255);
  textAlign(LEFT);
  textSize(32);
  text("Life: " + player.life + "  Score: " + score, 10, 40);

  // スコアが100増えるごとに敵の出現率を調整
  if (score >= 100) {
    redEnemySpawnRate = min(1, redEnemySpawnRate + 0.05);  // 赤色敵の出現率を0.05増加（最大1）
    whiteEnemySpawnRate = min(1, whiteEnemySpawnRate + 0.05); // 白色敵の出現率を0.05増加（最大1）
    score = 0;  // スコアが100を越えたらリセット
  }

  // 音量チェックで弾を発射
  float vol = amp.analyze();  // 音量の測定
  if (vol > threshold) {
    bullets.add(new Bullet(player.x, player.y));  // 音量が閾値を越えたら弾を発射
  }

  // 顔検出を行い、レーンを決定
  detectFaces();

  // レーン境界線の描画
  stroke(255);
  for (int i = 1; i < laneCount; i++) {
    line(i * laneWidth, 0, i * laneWidth, height);
  }

  // カメラ映像を画面上部中央に表示
  int camX = (width - cam.width) / 2;
  image(cam, camX, 0, cam.width, cam.height);

  // 顔に緑の●を描く
  drawFaces();
}

void drawFaces() {
  // 顔を検出
  Rectangle[] faces = opencv.detect();

  // 顔が検出されていれば、その位置に緑の●を描画
  fill(0, 255, 0);
  noStroke();
  for (Rectangle face : faces) {
    int camX = (width - cam.width) / 2;
    ellipse(camX + face.x + face.width / 2, face.y + face.height / 2, 20, 20);
  }
}

void detectFaces() {
  Rectangle[] faces = opencv.detect();
  int numFaces = faces.length;

  // 顔が検出されない場合、レーン0に移動
  if (numFaces == 0) {
    player.moveToLane(0);  // 顔がない場合、レーン0に移動
  } else {
    // 顔が検出されている場合、顔の数に基づいてレーンを決定
    int laneIndex = numFaces % laneCount;  // 顔の数÷レーン数のあまり
    player.moveToLane(laneIndex);
  }
}

void keyPressed() {
  if (key == ' ' && gameStarted) {
    bullets.add(new Bullet(player.x, player.y));
  } else if (keyCode == ENTER && !gameStarted) {
    resetGame();
    gameStarted = true;
  }
}

void resetGame() {
  player = new Player(width / 2, height - 50);
  bullets = new ArrayList<Bullet>();
  enemies = new ArrayList<Enemy>();
  frameCounter = 0;
  score = 0;
}

// プレイヤークラス
class Player {
  float x, y;
  float speed = 5;
  int life = 3;
  int lane = 0;

  Player(float x, float y) {
    this.x = x;
    this.y = y;
    this.lane = 0;
  }

  void update() {
    x = lane * laneWidth + laneWidth / 2;
  }

  void display() {
    fill(0, 255, 0);
    noStroke();
    rect(x - 15, y - 15, 30, 30);
  }

  void moveToLane(int laneIndex) {
    lane = laneIndex;
  }

  void decreaseLife() {
    life--;
  }

  boolean isGameOver() {
    return life <= 0;
  }
}

// 弾クラス
class Bullet {
  float x, y;
  float speed = 7;

  Bullet(float x, float y) {
    this.x = x;
    this.y = y;
  }

  void update() {
    y -= speed;
  }

  void display() {
    fill(255);
    noStroke();
    ellipse(x, y, 5, 10);
  }

  boolean isOffScreen() {
    return y < 0;
  }
}

// 敵クラス
class Enemy {
  float x, y;
  float speed;
  int life;
  color enemyColor;

  Enemy(float x, float y, color enemyColor, int life) {
    this.x = x;
    this.y = y;
    this.enemyColor = enemyColor;
    this.life = life;
    this.speed = initialEnemySpeed;
  }

  void update() {
    y += speed;
  }

  void display() {
    fill(enemyColor);
    noStroke();
    ellipse(x, y, 30, 30);
  }

  boolean isOffScreen() {
    return y > height;
  }

  boolean isHit(ArrayList<Bullet> bullets) {
    for (int i = bullets.size() - 1; i >= 0; i--) {
      Bullet b = bullets.get(i);
      if (dist(x, y, b.x, b.y) < 15) {
        bullets.remove(i);
        life--;
        return true;
      }
    }
    return false;
  }

  boolean hitsPlayer(Player player) {
    return dist(x, y, player.x, player.y) < 30;
  }
}
