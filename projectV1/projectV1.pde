//Version1===================================================================
//Global Variables-----------------------------------------------------------
String currentScreen;
String difficulty;

StartScreen start;
LevelScreen levels;
TutorialScreen tutorial;


void setup(){  
  size(800, 600);
  
  currentScreen = "start";
  start = new StartScreen();
  levels = new LevelScreen();
  tutorial = new TutorialScreen();
  setupGameplaySystem();
}

void draw(){
  if (currentScreen == "start"){
    start.startup();
  } else if (currentScreen == "levelSelect"){
    levels.drawLevels();
  } else if (currentScreen == "instructions"){
    tutorial.drawTut();
  } else if (currentScreen.equals("mainGameplay")) { 
    drawGameplay();
  }else {

  }
}

//Interactions---------------------------------------------------------------

void mousePressed(){
  // Utility mouse function -------------------------------------------------
 print("( "+ mouseX + ", "+ mouseY + ") ");
 //StartScreen controls
 if (currentScreen == "start"){
  currentScreen = start.handleMouse(mouseX, mouseY);
 } else if (currentScreen == "levelSelect"){
   difficulty = levels.chooseDifficulty();
   String next = levels.chooseScreen(mouseX, mouseY);
   if (next.equals("mainGameplay")) {
      resetGameplaySystem();     
    }
    currentScreen = next;
 } else if (currentScreen == "instructions"){
    currentScreen = tutorial.handleMouse(mouseX, mouseY);
 } else if (currentScreen.equals("mainGameplay")) {  
    gameMousePressed();
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
