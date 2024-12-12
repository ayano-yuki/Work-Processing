import processing.sound.*;

FFT fft;
AudioIn in;
int bands = 256;
float[] spectrum = new float[bands];

// ターゲット情報
int targetCount = 5;
float[] targetX = new float[targetCount];
float[] targetY = new float[targetCount];
float[] targetFreq = new float[targetCount];
float targetSize = 50;
color[] targetColors = {color(255, 0, 0), color(0, 255, 0), color(0, 0, 255), color(255, 255, 0), color(255, 0, 255)};

// スコア
int score = 0;

// ターゲットのタイマー管理
float[] targetTimers = new float[targetCount];
float targetTimeout = 3.0;  // ターゲット消失までの時間（秒）
float previousMillis = 0;   // ミリ秒単位の経過時間を記録する変数

void setup() {
  size(800, 600);
  background(0);

  // FFTとAudioInの初期化
  fft = new FFT(this, bands);
  in = new AudioIn(this, 0);

  // 音声入力を開始
  in.start();
  fft.input(in);

  // 初期ターゲット生成
  spawnTargets();
}

void draw() {
  background(0);
  fill(255);
  textSize(24);
  text("Score: " + score, 10, 30);

  // FFTでスペクトラムを解析
  fft.analyze(spectrum);

  // 現在の経過時間を取得
  float currentMillis = millis() / 1000.0;  // 秒単位に変換

  // ターゲットの描画とタイマー更新
  for (int i = 0; i < targetCount; i++) {
    targetTimers[i] += currentMillis - previousMillis;  // タイマー更新（秒単位）

    if (targetTimers[i] >= targetTimeout) {
      // ターゲット消失
      targetX[i] = -100;  // 画面外にターゲットを移動
      targetY[i] = -100;
    } else {
      fill(targetColors[i % targetColors.length]);
      ellipse(targetX[i], targetY[i], targetSize, targetSize);
    }
  }

  // 周波数帯をバーとして描画
  float barWidth = width / (float)bands;
  for (int i = 0; i < bands; i++) {
    float amplitude = spectrum[i] * height * 1000; // 音声を大きくスケールアップ
    float x = i * barWidth;
    float y = height - amplitude;

    fill(100, 150, 255);
    rect(x, y, barWidth, amplitude);

    // 各ターゲットとの一致をチェック
    for (int j = 0; j < targetCount; j++) {
      if (i == (int)targetFreq[j] && amplitude > 150 && targetTimers[j] < targetTimeout) {
        hitTarget(j);
      }
    }
  }

  // ターゲットを新たにスポーン
  for (int i = 0; i < targetCount; i++) {
    if (targetTimers[i] >= targetTimeout) {
      spawnSingleTarget(i);  // 新しいターゲットを配置
      targetTimers[i] = 0;   // タイマーをリセット
    }
  }

  // previousMillisを現在の時刻に更新
  previousMillis = currentMillis;
}

// ターゲットの生成
void spawnTargets() {
  for (int i = 0; i < targetCount; i++) {
    spawnSingleTarget(i);
  }
}

// 単一ターゲットの生成
void spawnSingleTarget(int i) {
  targetX[i] = random(width);
  targetY[i] = random(height / 2); // 上半分に表示
  targetFreq[i] = int(random(bands));
}

// ターゲットに命中した場合の処理
void hitTarget(int index) {
  score += 10;
  targetX[index] = -100;  // ターゲットを消去
  targetY[index] = -100;
  targetTimers[index] = targetTimeout;  // 新しいターゲットがスポーンされるまでの時間を設定
}
