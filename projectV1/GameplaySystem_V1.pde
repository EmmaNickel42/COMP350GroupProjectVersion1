// GameplaySystem.pde - Version 1 (Data-Driven Dashboard)
//
// WHAT THIS FILE DOES:
// - Spawns packets, viruses, and powerups
// - Moves them across the screen toward the server
// - Handles drag-and-drop to scanner / incinerator / server
// - Draws scanner (progress bar style), incinerator, stats panel, search bar
// - Calls Nicole's GameplayLogic functions for all game outcomes
ArrayList<NetworkObject> objects;
NetworkObject selectedObj = null;

int serverHealth  = 100;
int reputation    = 50;
int threatMeter   = 0;
int slowTimer     = 0;

int packetsPassed = 0;
int virusesBurned = 0;
int packetsBurned = 0;

boolean levelEnded = false;
String endTitle    = "";
String endStory    = "";

// IMAGES  — exact names from the data/ folder
PImage imgVirus1, imgVirus2, imgVirus3;
PImage imgStar, imgSlow, imgBlast;
PImage imgIncinerator, imgHealth, imgDial;

// SPAWNING
int lastSpawnTime     = 0;
int baseSpawnInterval = 2500;

// DRAG
float dragOffsetX = 0;
float dragOffsetY = 0;

// SCANNER
float   scannerX, scannerY, scannerW, scannerH;
boolean isScanning    = false;
int     scanStartTime = 0;
int     scanDuration  = 3000;

// INCINERATOR
float   incinX, incinY, incinW, incinH;
boolean showIncinEffect = false;
int     incinEffectStart = 0;
int     incinEffectDur   = 800;

// SERVER ZONE (right side of screen)
float serverZoneX, serverZoneY, serverZoneW, serverZoneH;

// SEARCH BAR  (V1 feature)
String searchInput  = "";
String searchResult = "";

void setupGameplaySystem() {
  objects = new ArrayList<NetworkObject>();

  imgVirus1      = loadImage("virus1.png");
  imgVirus2      = loadImage("virus2.png");
  imgVirus3      = loadImage("virus3.png");
  imgStar        = loadImage("star.png");
  imgSlow        = loadImage("slow.png");
  imgBlast       = loadImage("blast.png");
  imgIncinerator = loadImage("incinerator.png");
  imgHealth      = loadImage("health.png");
  imgDial        = loadImage("dial.png");

  // Interaction zones
  scannerX    = width * 0.38;  scannerY    = height * 0.72;
  scannerW    = 160;           scannerH    = 100;

  incinX      = width * 0.62;  incinY      = height * 0.72;
  incinW      = 100;           incinH      = 100;

  serverZoneX = width * 0.84;  serverZoneY = height * 0.10;
  serverZoneW = 80;            serverZoneH = height * 0.70;

  lastSpawnTime = millis();
}

void resetGameplaySystem() {
  objects.clear();
  selectedObj   = null;
  serverHealth  = 100;
  reputation    = 50;
  threatMeter   = 0;
  slowTimer     = 0;
  packetsPassed = 0;
  virusesBurned = 0;
  packetsBurned = 0;
  levelEnded    = false;
  isScanning    = false;
  showIncinEffect = false;
  searchInput   = "";
  searchResult  = "";
  lastSpawnTime = millis();
 }

//  MAIN DRAW 
void drawGameplay() {
  background(10, 20, 40);

  // Spawn objects on timer 
  if (millis() - lastSpawnTime > getSpawnInterval()) {
    spawnObject();
    lastSpawnTime = millis();
  }

  // Speed multiplier from slow powerup
  float speedMult = (slowTimer > 0) ? 0.4 : 1.0;

  //Move and draw every object 
  for (int i = objects.size() - 1; i >= 0; i--) {
    NetworkObject obj = objects.get(i);

    // Only move objects that are not being dragged
    if (obj != selectedObj) {
      obj.x += obj.speed * speedMult;
    }

    obj.display();

    // Object reached server on its own (not dragged)
    if (obj.x > serverZoneX && obj != selectedObj) {
      handleObjectReachedServer(obj);   
      objects.remove(i);
    }
  }

  updatePowerupEffects();   // counts down slowTimer
  checkLevelState();        // sets currentScreen = "end" when win/lose

  //Draw UI
  drawServerZone();
  drawScannerAndIncinerator();
  if (showIncinEffect) drawIncinEffect();
  drawStatsPanel();
  drawSearchBar();
}

//  SPAWNING
void spawnObject() {
  float  roll   = random(1);
  String sType  = "packet";
  String sPower = "";

  if      (roll < 0.50) { sType = "packet"; }
  else if (roll < 0.80) { sType = "virus";  }
  else {
    sType  = "powerup";
    sPower = (random(1) < 0.5) ? "slow" : "blast";
  }

  float sy = random(height * 0.12, height * 0.65);
  objects.add(new NetworkObject(sType, sPower, -50, sy));
}

// Spawn gets faster based on difficulty + threat level
int getSpawnInterval() {
  int base = baseSpawnInterval;
  if (difficulty != null) {
    if (difficulty.equals("Easy"))   base = 3000;
    if (difficulty.equals("Medium")) base = 2200;
    if (difficulty.equals("Hard"))   base = 1400;
  }
  return max(600, base - threatMeter * 12);
}

//  MOUSE INTERACTION
void gameMousePressed() {
  for (int i = objects.size() - 1; i >= 0; i--) {
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
      
      // Otherwise drag it
      selectedObj = obj;
      dragOffsetX = obj.x - mouseX;
      dragOffsetY = obj.y - mouseY;
      return;
    }
  }
}

void gameDragged() {
  if (selectedObj != null) {
    selectedObj.x = mouseX + dragOffsetX;
    selectedObj.y = mouseY + dragOffsetY;
  }
}

void gameReleased() {
  if (selectedObj == null) return;

  // Dropped on SCANNER
  if (isInZone(selectedObj.x, selectedObj.y, scannerX, scannerY, scannerW, scannerH)) {
    if (!isScanning) {
      isScanning    = true;
      scanStartTime = millis();
      // Freeze object in centre of scanner
      selectedObj.x = scannerX + scannerW / 2;
      selectedObj.y = scannerY + scannerH / 2;
    }

  //  Dropped on INCINERATOR 
  } else if (isInZone(selectedObj.x, selectedObj.y, incinX, incinY, incinW, incinH)) {
    // Show blast visual if it is a blast powerup
    if (selectedObj.type.equals("powerup") && selectedObj.powerType.equals("blast")) {
      showIncinEffect  = true;
      incinEffectStart = millis();
    }
    burnSelectedObject();   
    isScanning  = false;
    selectedObj = null;

  // Dropped on SERVER ZONE 
  } else if (isInZone(selectedObj.x, selectedObj.y, serverZoneX, serverZoneY, serverZoneW, serverZoneH)) {
    handleObjectReachedServer(selectedObj);  // Nicole's function
    objects.remove(selectedObj);
    selectedObj = null;
    isScanning  = false;

  //  Dropped elsewhere 
  } else {
    selectedObj = null;
  }
}

// Keyboard input for the search bar
void gameKeyPressed() {
  if (key == BACKSPACE && searchInput.length() > 0) {
    searchInput  = searchInput.substring(0, searchInput.length() - 1);
    searchResult = "";
  } else if (key == ENTER) {
    searchResult = searchByID(searchInput);
  } else if (key != CODED && searchInput.length() < 12) {
    searchInput += key;
  }
}

//  SCAN COMPLETION  —  checked every frame inside drawGameplay()
void checkScanComplete() {
  if (!isScanning || selectedObj == null) return;

  if (millis() - scanStartTime >= scanDuration) {
    String result              = scanSelectedObject();
    selectedObj.scanned        = true;
    selectedObj.scanResult     = result;
    selectedObj.showScanResult = true;
    isScanning  = false;
    selectedObj = null;   // player can now drag it to server or incinerator
  }
}

String searchByID(String query) {
  for (NetworkObject obj : objects) {
    if (obj.id.equalsIgnoreCase(query)) {
      if (obj.scanned) {
        boolean safe = obj.scanResult.contains("Safe") || obj.scanResult.contains("safe");
        return obj.id + (safe ? " → Safe ✓" : " → Unsafe ✗");
      } else {
        return obj.id + " → Not verified";
      }
    }
  }
  return "ID not found.";
}

//  DRAW: SERVER ZONE
void drawServerZone() {
  stroke(0, 200, 100);
  strokeWeight(2);
  noFill();
  rect(serverZoneX, serverZoneY, serverZoneW, serverZoneH, 6);
  fill(0, 200, 100);
  textSize(11);
  textAlign(CENTER, TOP);
  noStroke();
  text("SERVER", serverZoneX + serverZoneW / 2, serverZoneY + 4);
}

//  DRAW: SCANNER + INCINERATOR  (V1 — progress bar style)
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
  text("SCANNER", scannerX + scannerW / 2, scannerY + 5);

  // Indicator lights
  fill(isScanning ? color(220, 220, 0) : color(60));
  ellipse(scannerX + scannerW * 0.35, scannerY + 30, 12, 12);
  fill((!isScanning && selectedObj == null) ? color(0, 200, 0) : color(60));
  ellipse(scannerX + scannerW * 0.65, scannerY + 30, 12, 12);

  // Progress bar
  if (isScanning) {
    float p = constrain((float)(millis() - scanStartTime) / scanDuration, 0, 1);
    // Background
    fill(40);
    rect(scannerX + 10, scannerY + scannerH - 20, scannerW - 20, 12, 3);
    // Fill — red to green
    fill(lerpColor(color(255, 60, 60), color(60, 255, 60), p));
    rect(scannerX + 10, scannerY + scannerH - 20, (scannerW - 20) * p, 12, 3);
  }

  // Incinerator box 
  stroke(255, 100, 0);
  strokeWeight(2);
  noFill();
  rect(incinX, incinY, incinW, incinH, 8);
  image(imgIncinerator, incinX + incinW / 2 - 22, incinY + 6, 44, 44);
  fill(255, 140, 0);
  noStroke();
  textSize(10);
  textAlign(CENTER, BOTTOM);
  text("INCINERATOR", incinX + incinW / 2, incinY + incinH - 3);
}

//  DRAW: BLAST VISUAL EFFECT
void drawIncinEffect() {
  int elapsed = millis() - incinEffectStart;
  if (elapsed > incinEffectDur) {
    showIncinEffect = false;
    return;
  }
  float alpha = map(elapsed, 0, incinEffectDur, 220, 0);
  tint(255, alpha);
  image(imgIncinerator, width / 2 - 80, height / 2 - 80, 160, 160);
  noTint();
}

//  DRAW: STATS PANEL  (V1 — bar graph style, left side)
void drawStatsPanel() {
  float px = 10, py = height * 0.15;
  float pw = 160, ph = 230;

  // Panel background
  fill(15, 25, 45, 215);
  stroke(0, 140, 220);
  strokeWeight(1);
  rect(px, py, pw, ph, 6);

  // Title + health icon
  image(imgHealth, px + 8, py + 6, 18, 18);
  fill(0, 200, 255);
  noStroke();
  textSize(12);
  textAlign(LEFT, TOP);
  text("SYSTEM STATS", px + 30, py + 8);

  // Three bar graphs
  drawStatBar("Server Health", serverHealth, 100, px + 8, py + 34,  color(255, 80,  80));
  drawStatBar("Reputation",    reputation,   100, px + 8, py + 82,  color(80,  200, 255));
  drawStatBar("Threat",        threatMeter,  100, px + 8, py + 130, color(255, 160, 0));

  // Small counts at the bottom
  image(imgDial, px + 8, py + 178, 18, 18);
  fill(180);
  noStroke();
  textSize(10);
  textAlign(LEFT, CENTER);
  text("Viruses: " + virusesBurned + "   Passed: " + packetsPassed, px + 30, py + 187);
}

void drawStatBar(String label, float val, float maxVal,
                 float x, float y, color c) {
  float bw = 140, bh = 16;
  fill(180); noStroke(); textSize(10); textAlign(LEFT, TOP);
  text(label + ": " + (int)val, x, y);
  // Background track
  fill(40);
  rect(x, y + 14, bw, bh, 3);
  // Filled portion
  fill(c);
  rect(x, y + 14, map(constrain(val, 0, maxVal), 0, maxVal, 0, bw), bh, 3);
}

//  DRAW: SEARCH BAR  (V1 feature — bottom left of scanner)
void drawSearchBar() {
  float bx = scannerX - 165;
  float by = scannerY + 5;
  float bw = 150, bh = 24;

  // Input box
  fill(20, 30, 50);
  stroke(0, 160, 220);
  strokeWeight(1);
  rect(bx, by, bw, bh, 4);

  fill(200, 230, 255);
  noStroke();
  textSize(11);
  textAlign(LEFT, CENTER);
  text(searchInput.length() > 0 ? searchInput : "Search ID...", bx + 6, by + bh / 2);

  // Result line below box
  if (searchResult.length() > 0) {
    fill(160, 220, 255);
    textSize(10);
    textAlign(LEFT, TOP);
    text(searchResult, bx, by + bh + 5);
  }
}
//  HELPER
boolean isInZone(float px, float py,
                 float zx, float zy, float zw, float zh) {
  return px > zx && px < zx + zw &&
         py > zy && py < zy + zh;
}

//  NetworkObject CLASS
class NetworkObject {
  String type;       // "packet" / "virus" / "powerup"
  String powerType;  // "slow" / "blast"  (powerup only)
  String id;

  float x, y, speed, w, h;

  boolean scanned        = false;
  boolean showScanResult = false;
  String  scanResult     = "";

  PImage img;

  NetworkObject(String t, String pt, float sx, float sy) {
    type      = t;
    powerType = pt;
    x = sx;  y = sy;
    speed = random(0.8, 1.6);

    if (type.equals("virus")) {
      int r = (int)random(3);
      img = (r == 0) ? imgVirus1 : (r == 1) ? imgVirus2 : imgVirus3;
      w = 48;  h = 48;
      id = "VIR-" + (int)random(1000, 9999);

    } else if (type.equals("packet")) {
      img = null;
      w = 72;  h = 36;
      id = "PKT-" + (int)random(1000, 9999);

    } else {  // powerup
      img = powerType.equals("slow") ? imgSlow : imgBlast;
      w = 44;  h = 44;
      id = "PWR-" + powerType.toUpperCase();
    }
  }

  void display() {
    if (type.equals("packet")) {
      drawPacket();
    } else if (img != null) {
      image(img, x - w/2, y - h/2, w, h);
    }

    // Yellow highlight when selected/dragged
    if (this == selectedObj) {
      noFill();
      stroke(255, 255, 0);
      strokeWeight(2);
      rect(x - w/2 - 3, y - h/2 - 3, w + 6, h + 6, 4);
    }

    // Scan result badge (small circle with tick or cross)
    if (showScanResult) {
      boolean safe = scanResult.contains("Safe") || scanResult.contains("safe");
      fill(safe ? color(0, 200, 80, 200) : color(220, 30, 30, 200));
      noStroke();
      ellipse(x + w/2, y - h/2, 16, 16);
      fill(255);
      textSize(9);
      textAlign(CENTER, CENTER);
      text(safe ? "+" : "X", x + w/2, y - h/2);
    }
  }

  // V1 packet: dark rectangle with ID text and a tiny data line
  void drawPacket() {
    boolean safe = scanResult.contains("Safe") || scanResult.contains("safe");
    color bg = scanned
      ? (safe ? color(0, 70, 35) : color(80, 0, 0))
      : color(20, 40, 80);

    fill(bg);
    stroke(0, 180, 255);
    strokeWeight(1);
    rect(x - w/2, y - h/2, w, h, 4);

    fill(180, 220, 255);
    textSize(9);
    textAlign(CENTER, CENTER);
    noStroke();
    text(id, x, y - 5);

    // Small data detail line — V1 aesthetic
    fill(0, 140, 180, 130);
    textSize(7);
    text("ID: " + id.substring(4), x, y + 7);
  }

  boolean isMouseOver() {
    return mouseX > x - w/2 && mouseX < x + w/2 &&
           mouseY > y - h/2 && mouseY < y + h/2;
  }
}
