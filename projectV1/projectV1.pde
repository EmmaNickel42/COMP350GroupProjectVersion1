import processing.sound.*;

//Version1===================================================================
//Global Variables-----------------------------------------------------------
String currentScreen;
String difficulty;

StartScreen start;
LevelScreen levels;
TutorialScreen tutorial;
EndScreen end;

// sound
SoundFile whooshSfx;
SoundFile gameplayMusic;

void setup() {
  size(800, 600);

  currentScreen = "start";
  start = new StartScreen();
  levels = new LevelScreen();
  tutorial = new TutorialScreen();
  end = new EndScreen();
  setupGameplaySystem();

  // load sounds from data folder
  whooshSfx = new SoundFile(this, "whoosh.mp3");
  gameplayMusic = new SoundFile(this, "gameplaymusic.mp3");
}

void draw() {
  if (currentScreen.equals("start")) {
    start.startup();
  } else if (currentScreen.equals("levelSelect")) {
    levels.drawLevels();
  } else if (currentScreen.equals("instructions")) {
    tutorial.drawTut();
  } else if (currentScreen.equals("mainGameplay")) {
    drawGameplay();
  } else if (currentScreen.equals("end")) {
    end.drawEnd(endTitle, packetsPassed, virusesBurned, packetsBurned, levels.getContinent(), difficulty);
  } else {
  }
}

//Interactions---------------------------------------------------------------

void mousePressed() {
  print("( "+ mouseX + ", "+ mouseY + ") ");

  if (currentScreen.equals("start")) {
    String next = start.handleMouse(mouseX, mouseY);

    // play whoosh only when leaving start screen for level select
    if (next.equals("levelSelect")) {
      whooshSfx.play();
    }

    currentScreen = next;
  } else if (currentScreen.equals("levelSelect")) {
    difficulty = levels.chooseDifficulty();
    String next = levels.chooseScreen(mouseX, mouseY);

    if (next.equals("mainGameplay")) {
      resetGameplaySystem();

      if (!gameplayMusic.isPlaying()) {
        gameplayMusic.loop();
      }
    }

    currentScreen = next;
  } else if (currentScreen.equals("instructions")) {
    currentScreen = tutorial.handleMouse(mouseX, mouseY);
  } else if (currentScreen.equals("mainGameplay")) {
    gameMousePressed();
  } else if (currentScreen.equals("end")) {
    currentScreen = end.handleMouse(mouseX, mouseY);
  }
}

void mouseDragged() {
  if (currentScreen.equals("mainGameplay")) {
    gameDragged();
  }
}

void mouseReleased() {
  if (currentScreen.equals("mainGameplay")) {
    gameReleased();
  }
}

void keyPressed() {
  if (currentScreen.equals("mainGameplay")) {
    gameKeyPressed();
  }
}
