int numParticles = 0;
float[] mass = new float[100];
float[] positionX = new float[100];
float[] positionY = new float[100];
float[] velocityX = new float[100];
float[] velocityY = new float[100];

void setup() {
  // fullScreen()を使用して画面全体を使用
  fullScreen();
  noStroke();
  fill(64, 255, 255, 192);
}

void draw() {
  background(32);
  
  for (int particleA = 0; particleA < numParticles; particleA++) {
    float accelerationX = 0;
    float accelerationY = 0;
    
    for (int particleB = 0; particleB < numParticles; particleB++) {
      if (particleA != particleB) {
        float distanceX = positionX[particleB] - positionX[particleA];
        float distanceY = positionY[particleB] - positionY[particleA];
        
        float distance = sqrt(distanceX * distanceX + distanceY * distanceY);
        if (distance < 1) distance = 1;
        
        float force = (distance - 320) * mass[particleB] / distance;
        accelerationX += force * distanceX;
        accelerationY += force * distanceY;
      }
    }
    
    velocityX[particleA] = velocityX[particleA] * 0.99 + accelerationX * mass[particleA];
    velocityY[particleA] = velocityY[particleA] * 0.99 + accelerationY * mass[particleA];
  }
  
  for (int particle = 0; particle < numParticles; particle++) {
    positionX[particle] += velocityX[particle];
    positionY[particle] += velocityY[particle];
    
    ellipse(positionX[particle], positionY[particle], mass[particle] * 1000, mass[particle] * 1000);
  }
}

void addNewParticle() {
  if (numParticles < mass.length) {
    mass[numParticles] = random(0.003, 0.03);
    positionX[numParticles] = mouseX;
    positionY[numParticles] = mouseY;
    velocityX[numParticles] = 0;
    velocityY[numParticles] = 0;
    numParticles++;
  }
}

void mousePressed() {
  addNewParticle();
}

void mouseDragged() {
  addNewParticle();
}
