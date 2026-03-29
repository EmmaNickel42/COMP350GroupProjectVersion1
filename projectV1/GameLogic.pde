// ================= GAME LOGIC (Nicole) =================
// Responsible for:
// - Scan decision logic
// - Burn / incinerate logic
// - Pass-to-server outcomes
// - Powerup effects (slow, blast)
// - Level win / lose conditions
// - Outcome-related search and sort support


// ================= SCAN DECISION LOGIC =================
// Determines what kind of object is selected and returns a message
String scanSelectedObject() {

  if (selectedObj == null) {
    return "No object selected.";
  }

  selectedObj.scanned = true;

  if (selectedObj.type.equals("virus")) {
    return "Threat detected: virus.";
  } else if (selectedObj.type.equals("packet")) {
    if (selectedObj.isSafe) {
      return "Safe packet detected.";
    } else {
      return "Unsafe packet detected.";
    }
  } else if (selectedObj.type.equals("powerup")) {
    if (selectedObj.powerType.equals("slow")) {
      return "Powerup detected: slow.";
    } else if (selectedObj.powerType.equals("blast")) {
      return "Powerup detected: blast.";
    }
  }

  return "Unknown object.";
}


// ================= BURN / INCINERATE LOGIC =================
// Handles what happens when the player burns a selected object
void burnSelectedObject() {

  if (selectedObj == null) return;

  if (selectedObj.type.equals("virus")) {
    virusesBurned++;
    reputation = min(100, reputation + 4);
    threatMeter = max(0, threatMeter - 4);
  } else if (selectedObj.type.equals("packet")) {
    packetsBurned++;

    if (selectedObj.isSafe) {
      // bad mistake: burned a good packet
      reputation = max(0, reputation - 5);
      serverHealth = max(0, serverHealth - 2);
    } else {
      // good decision: burned an unsafe packet
      reputation = min(100, reputation + 3);
      threatMeter = max(0, threatMeter - 3);
    }
  } else if (selectedObj.type.equals("powerup")) {
    activatePowerup(selectedObj);
  }

  objects.remove(selectedObj);
  selectedObj = null;
}

// Removes all virus objects currently on screen (blast effect)
void incinerateAllNegativeObjects() {

  // Loop backwards to safely remove items from list
  for (int i = objects.size() - 1; i >= 0; i--) {
    NetworkObject obj = objects.get(i);

    // Remove all virus objects
    if (obj.type.equals("virus")) {
      virusesBurned++;
      objects.remove(i);
    }
  }

  // Reduce threat level after clearing viruses
  threatMeter = max(0, threatMeter - 10);
}


// ================= PASS-TO-SERVER LOGIC =================
void handleObjectReachedServer(NetworkObject obj) {

  if (obj.type.equals("packet")) {
    packetsPassed++;

    if (obj.isSafe) {
      reputation = min(100, reputation + 2);
    } else {
      serverHealth = max(0, serverHealth - 8);
      reputation = max(0, reputation - 4);
      threatMeter += 5;
    }
  } else if (obj.type.equals("virus")) {
    serverHealth = max(0, serverHealth - 12);
    reputation = max(0, reputation - 6);
    threatMeter += 8;
  } else if (obj.type.equals("powerup")) {
    // no effect
  }
}


// ================= POWERUP EFFECTS =================
// Applies the effect of a powerup
void activatePowerup(NetworkObject obj) {

  // Safety check
  if (!obj.type.equals("powerup")) return;

  powerupsUsed = powerupsUsed+1;

  // Slow powerup reduces object speed for a duration
  if (obj.powerType.equals("slow")) {
    slowTimer = 300; // duration in frames
  }
  // Blast powerup removes all viruses from screen
  else if (obj.powerType.equals("blast")) {
    incinerateAllNegativeObjects();
  }
}

// Updates ongoing powerup effects each frame
void updatePowerupEffects() {

  // Decrease slow timer over time
  if (slowTimer > 0) {
    slowTimer--;
  }
}

// ================= LEVEL WIN / LOSE CONDITIONS =================
// Checks whether the game should end (win or lose)
void checkLevelState() {

  if (levelEnded) return;

  if (serverHealth <= 0) {
    levelEnded = true;

    if (gameplayMusic.isPlaying()) {
      gameplayMusic.stop();
    }

    exportSortedStatsToFile();

    currentScreen = "end";
    endTitle = "lose";
    endStory = "Too many threats got through.";
    return;
  }

  if (reputation <= 0) {
    levelEnded = true;

    if (gameplayMusic.isPlaying()) {
      gameplayMusic.stop();
    }

    exportSortedStatsToFile();

    currentScreen = "end";
    endTitle = "lose";
    endStory = "Too many mistakes were made.";
    return;
  }

  if (reputation >= 100) {
    reputation = 100;
    levelEnded = true;

    if (gameplayMusic.isPlaying()) {
      gameplayMusic.stop();
    }

    exportSortedStatsToFile();

    currentScreen = "end";
    endTitle = "win";
    endStory = "Your reputation reached 100.";
    return;
  }
}


// ================= HELPER SEARCH FUNCTION =================
// Quickly checks if any virus exists on screen (used for gameplay logic)
boolean hasVirusOnScreen() {

  for (int i = 0; i < objects.size(); i++) {
    if (objects.get(i).type.equals("virus")) {
      return true; // found at least one virus
    }
  }

  return false; // no viruses found
}

// Stronger search helper: count how many viruses are currently on screen
int countVirusesOnScreen() {
  int count = 0;

  for (int i = 0; i < objects.size(); i++) {
    if (objects.get(i).type.equals("virus")) {
      count++;
    }
  }

  return count;
}

// ================= SORT FUNCTION =================
// Sorts key outcome stats from highest to lowest
float[] sortOutcomeStats() {

  float[] stats = {serverHealth, reputation, packetsPassed};

  // Simple bubble sort
  for (int i = 0; i < stats.length - 1; i++) {
    for (int j = 0; j < stats.length - 1 - i; j++) {

      // Swap if current value is smaller than next
      if (stats[j] < stats[j + 1]) {
        float temp = stats[j];
        stats[j] = stats[j + 1];
        stats[j + 1] = temp;
      }
    }
  }

  return stats;
}

// Creates labeled sorted output so the file is actually meaningful
String[] getSortedStatLines() {
  String[] labels = {"Server Health", "Reputation", "Packets Passed"};
  float[] stats = {serverHealth, reputation, packetsPassed};

  for (int i = 0; i < stats.length - 1; i++) {
    for (int j = 0; j < stats.length - 1 - i; j++) {
      if (stats[j] < stats[j + 1]) {

        float tempStat = stats[j];
        stats[j] = stats[j + 1];
        stats[j + 1] = tempStat;

        String tempLabel = labels[j];
        labels[j] = labels[j + 1];
        labels[j + 1] = tempLabel;
      }
    }
  }

  String[] lines = new String[6];

  lines[0] = "Sorted Gameplay Results (High to Low)";
  lines[1] = "1. " + labels[0] + ": " + nf(stats[0], 0, 0);
  lines[2] = "2. " + labels[1] + ": " + nf(stats[1], 0, 0);
  lines[3] = "3. " + labels[2] + ": " + nf(stats[2], 0, 0);
  lines[4] = "4. Packets Burned: " + packetsBurned;
  lines[5] = "5. Viruses Burned: " + virusesBurned;

  return lines;
}


// ================= EXTERNAL FILE OUTPUT =================
// Writes sorted results to an external text file
void exportSortedStatsToFile() {
  String[] lines = getSortedStatLines();
  saveStrings("sorted_stats.txt", lines);
}
