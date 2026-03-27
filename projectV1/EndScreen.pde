class EndScreen {
  
  void drawEnd(String result, int packetsPassed, int virusesBurned, int packetsBurned, String continent, String difficulty){
    background(255);
    
    if (result == "win"){
      //Header
      textAlign(CENTER);
      
      textSize(80);
      fill(50,205,50);
      text("Game Won!", width/2, 100);
      
    }  
    if (result == "lose"){
      //Header
      textAlign(CENTER);
      
      textSize(80);
      fill(255,0,0);
      text("Game Lost!", width/2, 100);
    }
    
    //Stat Table
    fill(255);
    stroke(0);
    rectMode(CENTER);
    
    rect(300, 140, 200, 40);
    rect(300, 180, 200, 40);
    rect(300, 220, 200, 40);
    rect(300, 220, 200, 40);
    rect(300, 260, 200, 40);
    rect(300, 300, 200, 40);
    rect(300, 340, 200, 40);
    rect(300, 380, 200, 40);
    rect(300, 420, 200, 40);
    
    rect(500, 140, 200, 40);
    rect(500, 180, 200, 40);
    rect(500, 220, 200, 40);
    rect(500, 220, 200, 40);
    rect(500, 260, 200, 40);
    rect(500, 300, 200, 40);
    rect(500, 340, 200, 40);
    rect(500, 380, 200, 40);
    rect(500, 420, 200, 40);
    
    //Stats
    fill(0);
    textSize(20);
    text("Statistics", 300, 140);
    text("Packets Passed", 300, 180);
    text("Viruses Burned", 300, 220);
    text("Packets Burned", 300, 260);
    text("Continent", 300, 300);
    text("Difficulty", 300, 340);
    text("Stat7", 300, 380);
    text("Stat8", 300, 420);
    
    text("Results", 500, 140);
    text(packetsPassed, 500, 180);
    text(virusesBurned, 500, 220);
    text(packetsBurned, 500, 260);
    text(continent, 500, 300);
    text(difficulty, 500, 340);
    text("Result7", 500, 380);
    text("Result8", 500, 420);
      
    //Buttons
    stroke(0,76, 153);
    fill(0, 128, 255);
    rect(200, 500, 150, 75, 8);
    rect(600, 500, 150, 75, 8);
    fill(0);
    textSize(30);
    text("Play Again", 200, 505);
    text("Main Menu", 600, 505);
    
    textAlign(LEFT, BASELINE);
    rectMode(CORNER);
  }
  
  String handleMouse(float x, float y){
   if ((x>=125) && (x<275) && (y<= 535) && (y>=460)){
     return "mainGameplay";
   }else if ((x>=425) && (x<675) && (y<= 535) && (y>=460)){
     return "start";
   } else {
    return "end"; 
   }
  }
}
