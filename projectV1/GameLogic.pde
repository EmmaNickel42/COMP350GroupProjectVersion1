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

  // If nothing is selected, return a default message
  if (selectedObj == null) {
    return "No object selected.";
  }

  // Mark object as scanned (if this field exists in NetworkObject)
  selectedObj.scanned = true;

  // Check object type and return appropriate scan result
  if (selectedObj.type.equals("virus")) {
    return "Threat detected: virus.";
  } 
  else if (selectedObj.type.equals("packet")) {
    return "Safe packet detected.";
  } 
  else if (selectedObj.type.equals("powerup")) {

    // Identify which type of powerup was scanned
    if (selectedObj.powerType.equals("slow")) {
      return "Powerup detected: slow.";
    } 
    else if (selectedObj.powerType.equals("blast")) {
      return "Powerup detected: blast.";
    }
  }

  // Fallback if object type is unknown
  return "Unknown object.";
}


// ================= BURN / INCINERATE LOGIC =================
// Handles what happens when the player burns a selected object
void burnSelectedObject() {

  // Do nothing if no object is selected
  if (selectedObj == null) return;

  // If it's a virus → reward player
  if (selectedObj.type.equals("virus")) {
    virusesBurned++;
    reputation += 4;
    threatMeter = max(0, threatMeter - 4);
  } 
  // If it's a safe packet → penalize player
  else if (selectedObj.type.equals("packet")) {
    packetsBurned++;
    reputation -= 5;
    serverHealth = max(0, serverHealth - 2);
  } 
  // If it's a powerup → activate it instead of destroying
  else if (selectedObj.type.equals("powerup")) {
    activatePowerup(selectedObj);
  }

  // Remove the object from the game after action
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
// Handles what happens when an object reaches the server
void handleObjectReachedServer(NetworkObject obj) {

  // Safe packet increases score/reputation
  if (obj.type.equals("packet")) {
    packetsPassed++;
    reputation += 2;
  } 
  // Virus damages server and increases threat
  else if (obj.type.equals("virus")) {
    serverHealth = max(0, serverHealth - 12);
    reputation -= 6;
    threatMeter += 8;
  } 
  // Powerup activates automatically when reaching server
  else if (obj.type.equals("powerup")) {
    activatePowerup(obj);
  }
}


// ================= POWERUP EFFECTS =================
// Applies the effect of a powerup
void activatePowerup(NetworkObject obj) {

  // Safety check
  if (!obj.type.equals("powerup")) return;

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

  // Prevent repeated state changes after game ends
  if (levelEnded) return;

  // Lose condition: server destroyed
  if (serverHealth <= 0) {
    levelEnded = true;
    currentScreen = "end";
    endTitle = "Server Compromised";
    endStory = "Too many threats got through.";
    return;
  }

  // Lose condition: reputation too low
  if (reputation <= 0) {
    levelEnded = true;
    currentScreen = "end";
    endTitle = "Trust Lost";
    endStory = "Too many mistakes were made.";
    return;
  }

  // Win condition: enough safe packets processed
  if (packetsPassed >= 15) {
    levelEnded = true;
    currentScreen = "end";
    endTitle = "Level Complete";
    endStory = "Enough safe traffic reached the server.";
  }
}


// ================= SEARCH FUNCTION =================
// Checks if there are any virus objects currently on screen
boolean hasVirusOnScreen() {

  for (int i = 0; i < objects.size(); i++) {
    if (objects.get(i).type.equals("virus")) {
      return true; // found at least one virus
    }
  }

  return false; // no viruses found
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
