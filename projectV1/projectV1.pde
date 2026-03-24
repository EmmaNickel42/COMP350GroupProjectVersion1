//Version1===================================================================
//Global Variables-----------------------------------------------------------
String currentScreen;
String difficulty;

StartScreen start;
LevelScreen instructions;


void setup(){  
  size(800, 600);
  
  currentScreen = "start";
  start = new StartScreen();
  instructions = new LevelScreen();
}

void draw(){
  if (currentScreen == "start"){
    start.startup();
  } else if (currentScreen == "levelSelect"){
    instructions.drawLevels();
  } else {

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
   difficulty = instructions.chooseDifficulty();
   currentScreen = instructions.chooseScreen(mouseX, mouseY);
 }
}
