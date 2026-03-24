class StartScreen {
  PImage backArt;
  
  StartScreen(){
    backArt = loadImage("startBackV1.png");
  }
 
  void startup(){
    image(backArt, 0, 0);
    
    rectMode(CENTER);
    fill(255, 255, 255, 220);
    stroke(255);
    strokeWeight(2);
    rect(width/2, height/2, 300, 550, 28);
    
    textSize(80);
    fill(255,0,0);
    text("Firewall", 265, 90);
    
    textSize(20);
    fill(0);
    text("Developed by:", 275, 470);
    text("Emma, Nicole, and Karanpreet", 275, 500);
    
    //Buttons-------------------------------------
    fill(149, 240, 58);
    stroke(126, 201, 50);
    //Play Button
    rect(width/2, 200, 250,100, 20); 
    //Instructions Button
    rect(width/2, 350, 250,100, 20);
    //ButtonText
    textSize(30);
    fill(0);
    text("Let's Go!", 350, 210);
    text("Instructions", 330, 360); 
  }
  
  String handleMouse(float x, float y){
    if ((x>=275) && (x<= 525) && (y>= 150) && (y<=245)){
      return "levelSelect";
    } else if ((x>=275) && (x<= 525) && (y>= 300) && (y<=400)) {
      return "instructions";
    } else {
     return "start"; 
    }
  }
  
}
