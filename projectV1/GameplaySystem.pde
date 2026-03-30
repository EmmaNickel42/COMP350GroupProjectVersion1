// FSM states
final int STATE_SPAWNING = 0;
final int STATE_SCANNING = 1;
final int STATE_SLOWDOWN = 2;
final int STATE_GAMEOVER = 3;
int gameState = STATE_SPAWNING;

ArrayList<NetworkObject> objects;
NetworkObject selectedObj = null;

int serverHealth  = 100;
int reputation    = 50;
int threatMeter   = 0;
int slowTimer     = 0;

int packetsPassed = 0;
int virusesBurned = 0;
int packetsBurned = 0;
int powerupsUsed  = 0;

String endTitle   = "";
String endStory   = "";

boolean levelEnded = false;

// Static array[] — movement tracking
float[] trackedX = new float[10];
float[] trackedY = new float[10];
int trackIndex   = 0;

// Stack push/pop — scan history
ArrayList<NetworkObject> scanStack = new ArrayList<NetworkObject>();

void stackPush(NetworkObject obj) {
  scanStack.add(obj);
}
NetworkObject stackPop() {
  if (scanStack.size() == 0) return null;
  return scanStack.remove(scanStack.size() - 1);
}

PImage imgVirus1, imgVirus2, imgVirus3;
PImage imgStar, imgSlow, imgBlast;
PImage imgIncinerator, imgHealth, imgDial;

int lastSpawnTime     = 0;
int baseSpawnInterval = 2500;

// DRAG
float dragOffsetX = 0;
float dragOffsetY = 0;

// SCANNER
float   scannerX, scannerY, scannerW, scannerH;
boolean isScanning    = false;
int     scanStartTime = 0;
int     scanDuration  = 1500;

// INCINERATOR
float   incinX, incinY, incinW, incinH;
boolean showIncinEffect  = false;
int     incinEffectStart = 0;
int     incinEffectDur   = 800;

// SERVER ZONE
float serverZoneX, serverZoneY, serverZoneW, serverZoneH;

// File output
PrintWriter movementLog;

// Interfaces
interface Scannable {
  String getScanResult();
  boolean isSafeObject();
}

interface Displayable {
  void display();
  boolean isMouseOver();
}

// Abstract class (Grandparent) — uses noise() and random()
abstract class GameEntity implements Scannable, Displayable {
  float x, y, speed, w, h;
  String id;
  boolean scanned        = false;
  boolean showScanResult = false;
  String  scanResult     = "";

  GameEntity(float sx, float sy) {
    x = sx;
    y = sy;
    speed = random(0.8, 1.6);
  }

  void move(float speedMult) {
    x += speed * speedMult;
    if (frameCount % 10 == 0) {
      y += (noise(x * 0.01, y * 0.01) - 0.5) * 1.5; // noise()
    }
  }

  void trackPosition() {
    trackedX[trackIndex % 10] = x;
    trackedY[trackIndex % 10] = y;
    trackIndex++;
  }

  String getScanResult() {
    return scanResult;
  }
  boolean isSafeObject() {
    if (this instanceof NetworkObject) {
      NetworkObject obj = (NetworkObject)this;
      return obj.isSafe;
    }
    return false;
  }
  abstract void display();
  abstract boolean isMouseOver();
}

// Parent class (level 2 of 3)
class NetworkObject extends GameEntity {
  String type;
  String powerType;
  PImage img;

  boolean isSafe = true;

  NetworkObject(String t, String pt, float sx, float sy) {
    super(sx, sy);
    type = t;
    powerType = pt;

    if (type.equals("virus")) {
      int r = (int)random(3);
      img = (r==0) ? imgVirus1 : (r==1) ? imgVirus2 : imgVirus3;
      w=48;
      h=48;
      id = "VIR-" + (int)random(1000, 9999);
    } else if (type.equals("packet")) {
      img = null;
      w=72;
      h=36;
      id = "PKT-" + (int)random(1000, 9999);

      // 60% safe, 40% unsafe
      isSafe = random(1) < 0.6;
    } else {
      img = powerType.equals("slow") ? imgSlow : imgBlast;
      w=44;
      h=44;
      id = "PWR-" + powerType.toUpperCase();
    }
  }

  void display() {
    pushMatrix(); // pushMatrix/popMatrix for 2D transformation
    translate(x, y);

    if (type.equals("packet")) drawPacket();
    else if (img != null) image(img, -w/2, -h/2, w, h);

    if (this == selectedObj) {
      noFill();
      stroke(255, 255, 0);
      strokeWeight(2);
      rect(-w/2-3, -h/2-3, w+6, h+6, 4);
    }
    if (showScanResult) {
      fill(isSafeObject() ? color(0, 200, 80, 200) : color(220, 30, 30, 200));
      noStroke();
      ellipse(w/2, -h/2, 16, 16);
      fill(255);
      textSize(9);
      textAlign(CENTER, CENTER);
      text(isSafeObject() ? "+" : "X", w/2, -h/2);
    }

    popMatrix();
  }

  void drawPacket() {
    color bg = scanned
      ? (isSafeObject() ? color(0, 70, 35) : color(80, 0, 0))
      : color(20, 40, 80);
    fill(bg);
    stroke(0, 180, 255);
    strokeWeight(1);
    rect(-w/2, -h/2, w, h, 4);
    fill(180, 220, 255);
    textSize(11);
    textAlign(CENTER, CENTER);
    noStroke();
    text(id, 0, -5);
    fill(0, 140, 180, 130);
    textSize(7);
    text("ID: "+id.substring(4), 0, 7);
  }

  boolean isMouseOver() {
    return mouseX>x-w/2 && mouseX<x+w/2 &&
      mouseY>y-h/2 && mouseY<y+h/2;
  }
}

// Child class (level 3 of 3) — GameEntity -> NetworkObject -> VirusObject
class VirusObject extends NetworkObject {
  int threatMultiplier;

  VirusObject(float sx, float sy) {
    super("virus", "", sx, sy);
    int r = (int)random(3);
    img = (r==0) ? imgVirus1 : (r==1) ? imgVirus2 : imgVirus3;
    threatMultiplier = (int)random(1, 3);
    w=48;
    h=48;
    id = "VIR-" + (int)random(1000, 9999);
  }

  void display() {
    super.display();
    // Show threat multiplier badge for dangerous viruses
    if (threatMultiplier > 1) {
      pushMatrix();
      translate(x, y);
      fill(255, 50, 50, 200);
      noStroke();
      ellipse(-w/2, -h/2, 16, 16);
      fill(255);
      textSize(8);
      textAlign(CENTER, CENTER);
      text("x"+threatMultiplier, -w/2, -h/2);
      popMatrix();
    }
  }
}

// SETUP
void setupGameplaySystem() {
  objects   = new ArrayList<NetworkObject>();
  scanStack = new ArrayList<NetworkObject>();

  // Load images ONCE
  imgVirus1      = loadImage("virus1.png");
  imgVirus2      = loadImage("virus2.png");
  imgVirus3      = loadImage("virus3.png");
  imgStar        = loadImage("star.png");
  imgSlow        = loadImage("slow.png");
  imgBlast       = loadImage("blast.png");
  imgIncinerator = loadImage("incinerator.png");
  imgHealth      = loadImage("health.png");
  imgDial        = loadImage("dial.png");

  // Zones
  scannerX    = width*0.38;
  scannerY    = height*0.72;
  scannerW    = 160;
  scannerH    = 100;
  incinX      = width*0.62;
  incinY      = height*0.72;
  incinW      = 100;
  incinH      = 100;
  serverZoneX = width*0.84;
  serverZoneY = height*0.10;
  serverZoneW = 80;
  serverZoneH = height*0.70;

  // Open movement log file
  movementLog = createWriter("movement_log.txt");
  movementLog.println("ID,X,Y,Type,Time");

  lastSpawnTime = millis();
  gameState     = STATE_SPAWNING;
}

// RESET
void resetGameplaySystem() {
  objects.clear();
  scanStack.clear();
  selectedObj     = null;
  serverHealth    = 100;
  reputation      = 50;
  threatMeter     = 0;
  slowTimer       = 0;
  packetsPassed   = 0;
  virusesBurned   = 0;
  packetsBurned   = 0;
  powerupsUsed    = 0;
  levelEnded      = false;
  isScanning      = false;
  showIncinEffect = false;
  trackIndex      = 0;
  lastSpawnTime   = millis();
  gameState       = STATE_SPAWNING;
}

// Finite State Machine — 4 states using switch
void updateFSM() {
  switch (gameState) {
  case STATE_SPAWNING:
    if (isScanning)     gameState = STATE_SCANNING;
    if (slowTimer > 0)  gameState = STATE_SLOWDOWN;
    if (levelEnded)     gameState = STATE_GAMEOVER;
    break;
  case STATE_SCANNING:
    if (!isScanning)    gameState = (slowTimer>0) ? STATE_SLOWDOWN : STATE_SPAWNING;
    if (levelEnded)     gameState = STATE_GAMEOVER;
    break;
  case STATE_SLOWDOWN:
    if (slowTimer <= 0) gameState = STATE_SPAWNING;
    if (levelEnded)     gameState = STATE_GAMEOVER;
    break;
  case STATE_GAMEOVER:
    break;
  }
}

// MAIN DRAW
void drawGameplay() {
  background(10, 20, 40);

  updateFSM();

  // Spawn objects on timer
  if (millis() - lastSpawnTime > getSpawnInterval()) {
    spawnObject();
    lastSpawnTime = millis();
  }

  // Speed multiplier from slow powerup
  float speedMult = (slowTimer > 0) ? 0.4 : 1.0;

  // for loop
  for (int i = objects.size()-1; i >= 0; i--) {
    NetworkObject obj = objects.get(i);

    if (obj != selectedObj) {
      obj.move(speedMult); // noise() inside move()
      obj.trackPosition(); // track in static array
    }

    obj.display();

    // Log position every 60 frames
    if (frameCount % 60 == 0) logObjectPosition(obj);

    // Reached server on its own
    if (obj.x > serverZoneX && obj != selectedObj) {
      handleObjectReachedServer(obj);
      objects.remove(i);
    }
  }

  updatePowerupEffects();
  checkLevelState();

  drawServerZone();
  drawScannerAndIncinerator();
  if (showIncinEffect) drawIncinEffect();
  drawStatsPanel();
  drawFSMState();
}

// SPAWNING
void spawnObject() {
  float  roll   = random(1);
  String sType  = "packet";
  String sPower = "";

  if      (roll < 0.50) {
    sType = "packet";
  } else if (roll < 0.80) {
    sType = "virus";
  } else {
    sType  = "powerup";
    sPower = (random(1) < 0.5) ? "slow" : "blast";
  }

  float sy = random(height*0.12, height*0.65);

  // Use VirusObject child class for viruses
  if (sType.equals("virus")) {
    objects.add(new VirusObject(-50, sy));
  } else {
    objects.add(new NetworkObject(sType, sPower, -50, sy));
  }
}

// Spawn interval based on difficulty (Emma's variable) + threat
int getSpawnInterval() {
  int base = baseSpawnInterval;
  if (difficulty != null) {
    if (difficulty.equals("Easy"))   base = 3000;
    if (difficulty.equals("Medium")) base = 2200;
    if (difficulty.equals("Hard"))   base = 1400;
  }
  return max(600, base - threatMeter*12);
}

// External file output — writes to movement_log.txt
void logObjectPosition(NetworkObject obj) {
  if (movementLog != null) {
    movementLog.println(obj.id+","+nf(obj.x, 1, 1)+","+
      nf(obj.y, 1, 1)+","+obj.type+","+millis());
    movementLog.flush();
  }
}

// Sort algorithm + while loop — bubble sort on tracked positions
float[] getSortedTrackedX() {
  float[] sorted = trackedX.clone(); // static array
  int i = 0;
  while (i < sorted.length - 1) { // while loop
    int j = 0;
    while (j < sorted.length - 1 - i) {
      if (sorted[j] < sorted[j+1]) {
        float temp  = sorted[j];
        sorted[j]   = sorted[j+1];
        sorted[j+1] = temp;
      }
      j++;
    }
    i++;
  }
  return sorted;
}

// Mouse interaction
void gameMousePressed() {
  if (isScanning) {
    return;
  }

  for (int i = objects.size() - 1; i >= 0; i--) { // for loop
    NetworkObject obj = objects.get(i);
    if (obj.isMouseOver()) {
      if (obj.type.equals("powerup")) {
        selectedObj = obj;
        activatePowerup(obj);
        if (obj.powerType.equals("blast")) {
          showIncinEffect  = true;
          incinEffectStart = millis();
        }
        objects.remove(i);
        selectedObj = null;
        return;
      }

      selectedObj = obj;
      dragOffsetX = obj.x - mouseX;
      dragOffsetY = obj.y - mouseY;
      return;
    }
  }
}

void gameKeyPressed() {
}

void gameDragged() {
  if (isScanning) return;
  
  if (selectedObj != null) {
    selectedObj.x = mouseX + dragOffsetX;
    selectedObj.y = mouseY + dragOffsetY;
  }
}

void gameReleased() {
  if (selectedObj == null) return;

  if (isInZone(selectedObj.x, selectedObj.y, scannerX, scannerY, scannerW, scannerH)) {
    if (!isScanning) {
      isScanning    = true;
      scanStartTime = millis();
      selectedObj.x = scannerX + scannerW / 2;
      selectedObj.y = scannerY + scannerH / 2;
      stackPush(selectedObj); // stack push
      return;
    }
  } 
  else if (isInZone(selectedObj.x, selectedObj.y, incinX, incinY, incinW, incinH)) {
    if (selectedObj.type.equals("powerup") && selectedObj.powerType.equals("blast")) {
      showIncinEffect  = true;
      incinEffectStart = millis();
    }
    burnSelectedObject();
    isScanning  = false;
    selectedObj = null;
  } 
  else if (isInZone(selectedObj.x, selectedObj.y, serverZoneX, serverZoneY, serverZoneW, serverZoneH)) {
    handleObjectReachedServer(selectedObj);
    objects.remove(selectedObj);
    selectedObj = null;
    isScanning  = false;
  } 
  else {
    selectedObj = null;
  }
}

// SCAN COMPLETION
void checkScanComplete() {
  if (!isScanning || selectedObj == null) return;

  if (millis() - scanStartTime >= scanDuration) {
    String result = scanSelectedObject();
    selectedObj.scanned = true;
    selectedObj.scanResult = result;
    selectedObj.showScanResult = true;

    stackPop(); // stack pop
    isScanning = false;
    selectedObj = null;
  }
}

void drawFSMState() {
  String[] names  = {"SPAWNING", "SCANNING", "SLOWDOWN", "GAME OVER"};
  color[]  colors = {color(0, 200, 100), color(0, 200, 255),
    color(255, 200, 0), color(255, 50, 50)};
  fill(colors[gameState]);
  noStroke();
  textSize(10);
  textAlign(LEFT, TOP);
  text("STATE: "+names[gameState], 10, height*0.10);
}

// SERVER ZONE
void drawServerZone() {
  stroke(0, 200, 100);
  strokeWeight(2);
  noFill();
  rect(serverZoneX, serverZoneY, serverZoneW, serverZoneH, 6);
  fill(0, 200, 100);
  noStroke();
  textSize(11);
  textAlign(CENTER, TOP);
  text("SERVER", serverZoneX+serverZoneW/2, serverZoneY+4);
}

// SCANNER + INCINERATOR (V1 progress bar style)
void drawScannerAndIncinerator() {
  checkScanComplete();

  // Scanner box
  stroke(0, 200, 255);
  strokeWeight(2);
  noFill();
  rect(scannerX, scannerY, scannerW, scannerH, 8);
  fill(200, 230, 255);
  noStroke();
  textSize(11);
  textAlign(CENTER, TOP);
  text("SCANNER", scannerX+scannerW/2, scannerY+5);

  // Indicator lights
  fill(isScanning ? color(220, 220, 0) : color(60));
  ellipse(scannerX+scannerW*0.35, scannerY+30, 12, 12);
  fill((!isScanning&&selectedObj==null) ? color(0, 200, 0) : color(60));
  ellipse(scannerX+scannerW*0.65, scannerY+30, 12, 12);

  // Progress bar
  if (isScanning) {
    float p = constrain((float)(millis()-scanStartTime)/scanDuration, 0, 1);
    fill(40);
    rect(scannerX+10, scannerY+scannerH-20, scannerW-20, 12, 3);
    fill(lerpColor(color(255, 60, 60), color(60, 255, 60), p));
    rect(scannerX+10, scannerY+scannerH-20, (scannerW-20)*p, 12, 3);
  }

  // Incinerator box
  stroke(255, 100, 0);
  strokeWeight(2);
  noFill();
  rect(incinX, incinY, incinW, incinH, 8);
  image(imgIncinerator, incinX+incinW/2-22, incinY+6, 44, 44);
  fill(255, 140, 0);
  noStroke();
  textSize(10);
  textAlign(CENTER, BOTTOM);
  text("INCINERATOR", incinX+incinW/2, incinY+incinH-3);
}

// BLAST EFFECT
void drawIncinEffect() {
  int e = millis()-incinEffectStart;
  if (e>incinEffectDur) {
    showIncinEffect=false;
    return;
  }
  float alpha = map(e, 0, incinEffectDur, 220, 0);
  tint(255, alpha);
  image(imgIncinerator, width/2-80, height/2-80, 160, 160);
  noTint();
}

// STATS PANEL + LIVE THREAT DIAL (V1 bar graph style)
void drawStatsPanel() {
  float px=10, py=height*0.15, pw=160, ph=270;
  fill(15, 25, 45, 215);
  stroke(0, 140, 220);
  strokeWeight(1);
  rect(px, py, pw, ph, 6);

  image(imgHealth, px+8, py+6, 18, 18);
  fill(0, 200, 255);
  noStroke();
  textSize(12);
  textAlign(LEFT, TOP);
  text("SYSTEM STATS", px+30, py+8);

  drawStatBar("Server Health", serverHealth, 100, px+8, py+32, color(255, 80, 80));
  drawStatBar("Reputation", reputation, 100, px+8, py+80, color(80, 200, 255));
  drawStatBar("Threat", threatMeter, 100, px+8, py+128, color(255, 160, 0));

  // Live threat dial
  drawThreatDial(px+pw/2, py+205, 45);

  fill(180);
  noStroke();
  textSize(10);
  textAlign(LEFT, CENTER);
  text("Viruses:"+virusesBurned+" Passed:"+packetsPassed, px+8, py+255);
}

void drawStatBar(String label, float val, float maxVal,
  float x, float y, color c) {
  float bw=140, bh=16;
  fill(180);
  noStroke();
  textSize(10);
  textAlign(LEFT, TOP);
  text(label+": "+(int)val, x, y);
  fill(40);
  rect(x, y+14, bw, bh, 3);
  fill(c);
  rect(x, y+14, map(constrain(val, 0, maxVal), 0, maxVal, 0, bw), bh, 3);
}

// Live animated threat gauge
void drawThreatDial(float cx, float cy, float r) {
  fill(30);
  stroke(80);
  strokeWeight(1);
  ellipse(cx, cy, r*2, r*2);

  noFill();
  strokeWeight(r*0.3);
  stroke(0, 200, 80);
  arc(cx, cy, r*1.4, r*1.4, PI, PI+PI*0.4);
  stroke(255, 200, 0);
  arc(cx, cy, r*1.4, r*1.4, PI+PI*0.4, PI+PI*0.7);
  stroke(255, 50, 50);
  arc(cx, cy, r*1.4, r*1.4, PI+PI*0.7, TWO_PI);

  float angle = map(threatMeter, 0, 100, PI, TWO_PI);
  float nx = cx + cos(angle)*(r*0.7);
  float ny = cy + sin(angle)*(r*0.7);
  stroke(255);
  strokeWeight(2);
  line(cx, cy, nx, ny);

  fill(255);
  noStroke();
  ellipse(cx, cy, 6, 6);
  fill(180);
  textSize(8);
  textAlign(CENTER, TOP);
  text("THREAT", cx, cy+r+2);
}

// HELPER
boolean isInZone(float px, float py,
  float zx, float zy, float zw, float zh) {
  return px>zx && px<zx+zw && py>zy && py<zy+zh;
}
