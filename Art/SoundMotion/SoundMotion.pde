import processing.video.*;
import processing.sound.*;

Capture video;
SoundFile sound;  // MP3ファイル
Amplitude amp;    // 音量（Amplitude）
AudioIn mic;      // マイク入力のためのオブジェクト
FFT fft;          // FFT（音の周波数解析）
PImage prevFrame;
int colorChangeSpeed;
int cellSize;
int bands;
float[] spectrum;

int motionThreshold;
int minCellSize;
int maxCellSize;
int[] colors;
float volumeMin, volumeMax;
float speedNormal, speedFast, speedSlow;

float movementThresholdHigh, movementThresholdLow;  // 閾値変数追加
float totalBlockDiff, movementCount;

void setup() {
  // 設定値の初期化（マジックナンバーを変数に置き換え）
  colorChangeSpeed = 5;
  cellSize = 10; // 初期cellSize
  bands = 128;   // FFTのバンド数
  spectrum = new float[bands];  // 周波数データを格納する配列

  motionThreshold = 350;  // 動きの検出閾値
  minCellSize = 10;       // cellSizeの最小値
  maxCellSize = 50;      // cellSizeの最大値

  // 色の配列
  colors = new int[]{
    color(155, 227, 204),
    color(251, 121, 137),
    color(253, 213, 133)
  };

  // 音量の最小・最大値
  volumeMin = 2.0;
  volumeMax = 10.0;

  // 再生速度の設定
  speedNormal = 1.0;
  speedFast = 1.3;
  speedSlow = 0.7;

  // 動きの閾値設定（可視化用）
  movementThresholdHigh = 2000.0;   // 高い動きの閾値
  movementThresholdLow  = 1000.0;   // 低い動きの閾値
  
  //size(800, 600);
  fullScreen();
  
  // カメラの設定
  video = new Capture(this, width, height);
  video.start();
  
  // 音ファイルのロード（MP3ファイル）
  sound = new SoundFile(this, "sound.mp3"); // sound.mp3は実際の音ファイルに置き換えてください
  sound.loop(); // MP3ファイルをループ再生
  
  // マイクの設定（AudioInを使用）
  mic = new AudioIn(this, 0);  // デフォルトのマイク（インデックス0）を使用
  mic.start(); // マイクの入力開始
  
  // Amplitudeオブジェクトの設定
  amp = new Amplitude(this);
  amp.input(mic); // マイクの音量データを取得
  
  // FFTオブジェクトの設定（音の周波数解析）
  fft = new FFT(this, bands);  // FFT設定、バンド数指定
  fft.input(mic);  // マイク入力に基づいてFFT設定
  
  // 最初のフレームを保存
  prevFrame = createImage(width, height, RGB);
  
  println("Setup complete.");
}

void draw() {
  try {
    background(255);
    
    // カメラの映像が利用可能かチェック
    if (video.available()) {
      video.read();
      println("Video frame available: " + video.available());
    } else {
      println("Waiting for video frame...");
      return;  // ビデオフレームが利用できない場合、処理を中断
    }
    
    // 動きの検出（前のフレームと比較）
    loadPixels();
    video.loadPixels();

    // 音の音量（マイク入力も含む）
    float amplitude = amp.analyze(); // 音の大きさ（音量）
    println("Current amplitude: " + amplitude);
    
    // FFTを更新して周波数データを取得
    fft.analyze(spectrum);  // 周波数解析の実行
    println("FFT spectrum analyzed.");

    // 音の大きさに基づいてcellSizeを調整（1〜40の範囲）
    cellSize = int(map(amplitude * 20, 0, 1, minCellSize, maxCellSize));
    println("Cell size based on amplitude: " + cellSize);

    // 動きの検出
    totalBlockDiff = 0;
    movementCount = 0;
    for (int y = 0; y < height; y += cellSize) {
      for (int x = 0; x < width; x += cellSize) {
        // ブロック内のピクセルの色の差を計算
        int blockDiff = 0;
        for (int i = x; i < x + cellSize && i < width; i++) {
          for (int j = y; j < y + cellSize && j < height; j++) {
            int currentPixel = pixels[i + j * width];
            int videoPixel = video.pixels[i + j * video.width];
            blockDiff += int(dist(red(currentPixel), green(currentPixel), blue(currentPixel),
                                  red(videoPixel), green(videoPixel), blue(videoPixel)));
          }
        }

        // 動きが大きければ色を変化
        int colorIndex = int(map(blockDiff, 0, 255 * cellSize * cellSize, 0, colors.length - 1));
        colorIndex = min(colorIndex, colors.length - 1);  // colors.length - 1より大きくならないように制限
        
        // もしブロック内で動きが検出された場合、色を変化
        if (blockDiff > motionThreshold * cellSize * cellSize) {
          fill(colors[colorIndex]);
          noStroke();
          rect(x, y, cellSize, cellSize); // 動きのあるブロックを色で描画
          totalBlockDiff += blockDiff; // 動きの差を加算
          movementCount++;
        } else {
          fill(255); // 動きがないブロックは白
          noStroke();
          rect(x, y, cellSize, cellSize);
        }
      }
    }

    // 音の変化（動きに応じて音量を変更）
    float volume = map(amplitude, 0, 1, volumeMin, volumeMax); // 音量はマイク入力の音量に比例
    sound.amp(volume); // MP3音源の音量を変更
    println("Sound volume adjusted to: " + volume);

    // 動きの平均を計算し、倍速/遅速を変更
    if (movementCount > 0) {
      float averageMovement = totalBlockDiff / movementCount;
      println("Average movement: " + averageMovement);  // 画面上に表示

      if (averageMovement > movementThresholdHigh) {
        sound.rate(speedFast);  // 動きが大きい場合、倍速
        println("Speed: Fast (2x)");
      } else if (averageMovement < movementThresholdLow) {
        sound.rate(speedSlow);  // 動きが小さい場合、遅速
        println("Speed: Slow (0.5x)");
      } else {
        sound.rate(speedNormal);  // 通常速度
        println("Speed: Normal (1x)");
      }
    }

    // 前回のフレームを保存
    prevFrame.copy(video, 0, 0, video.width, video.height, 0, 0, prevFrame.width, prevFrame.height);

  } catch (Exception e) {
    println("Error: " + e.getMessage());
    e.printStackTrace();  // エラーのスタックトレースを表示
  }
}

// 動きが検出されたブロックの数を数える関数
int countMovement() {
  int movementDetected = 0;
  loadPixels();
  for (int i = 0; i < pixels.length; i++) {
    if (pixels[i] != color(255)) {
      movementDetected++;
    }
  }
  return movementDetected;
}
