// シューティングゲーム (STG) in Processing

import processing.sound.*; // サウンドライブラリをインポート

// プレイヤー、自機の設定
Player player;
ArrayList<Bullet> bullets;
ArrayList<Enemy> enemies;

AudioIn input;
Amplitude amp;

int enemySpawnInterval = 60; // 敵を生成する間隔 (フレーム数)
int frameCounter = 0;
boolean gameStarted = false;
float threshold = 0.2; // 音量の閾値

void setup() {
  size(400, 600);
  resetGame();

  // 音声入力の設定
  input = new AudioIn(this, 0);
  input.start(); // マイク入力を有効化
  amp = new Amplitude(this);
  amp.input(input);
}

void draw() {
  background(0);

  if (!gameStarted) {
    fill(255);
    textAlign(CENTER);
    textSize(20);
    text("Press ENTER to Start", width / 2, height / 2);
    return;
  }

  // プレイヤーを更新・表示
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
    enemies.add(new Enemy(random(width), 0));
  }

  // 敵の更新・表示
  for (int i = enemies.size() - 1; i >= 0; i--) {
    Enemy e = enemies.get(i);
    e.update();
    e.display();
    if (e.isOffScreen()) {
      enemies.remove(i);
    } else if (e.hitsPlayer(player)) {
      enemies.remove(i);
      player.decreaseLife();
      if (player.isGameOver()) {
        gameStarted = false;
      }
    } else if (e.isHit(bullets)) {
      enemies.remove(i);
    }
  }

  // ライフ表示
  fill(255);
  textAlign(LEFT);
  textSize(16);
  text("Life: " + player.life, 10, 20);

  // 音量チェックで弾を発射
  float vol = amp.analyze();
  if (vol > threshold) {
    bullets.add(new Bullet(player.x, player.y));
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
}

// プレイヤークラス
class Player {
  float x, y;
  float speed = 5;
  int life = 3;

  Player(float x, float y) {
    this.x = x;
    this.y = y;
  }

  void update() {
    if (keyPressed) {
      if (keyCode == LEFT) {
        x -= speed;
      } else if (keyCode == RIGHT) {
        x += speed;
      }
    }
    x = constrain(x, 0, width);
  }

  void display() {
    fill(0, 255, 0);
    noStroke();
    rect(x - 15, y - 15, 30, 30);
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
  float speed = 2;

  Enemy(float x, float y) {
    this.x = x;
    this.y = y;
  }

  void update() {
    y += speed;
  }

  void display() {
    fill(255, 0, 0);
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
        return true;
      }
    }
    return false;
  }

  boolean hitsPlayer(Player player) {
    return dist(x, y, player.x, player.y) < 30;
  }
}
