//Version1===================================================================
//Global Variables-----------------------------------------------------------
String currentScreen;
StartScreen start;


void setup(){  
  size(800, 600);
  
  currentScreen = "start";
  start = new StartScreen();
}

void draw(){
  if (currentScreen == "start"){
    start.startup();
  } else {
    print(currentScreen);
  }
}

//Interactions---------------------------------------------------------------

void mousePressed(){
  // Utility mouse function -------------------------------------------------
 print("( "+ mouseX + ", "+ mouseY + ") ");
 //StartScreen controls
 if (currentScreen == "start"){
  currentScreen = start.handleMouse(mouseX, mouseY);
 }
  
}
