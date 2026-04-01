class TutorialScreen{
  
  void drawTut(){
    background(0);
    
    rectMode(CENTER);
    fill(255, 255, 255, 220);
    stroke(255);
    strokeWeight(2);
    rect(width/2, height/2 - 25, 750, 500, 35);
    
    textAlign(CENTER, CENTER);
    textSize(80);
    fill(255,0,0);
    text("Instructions", width/2, 80);
    
    textSize(15);
    fill(0);
    text("You are defending a server. Packets and viruses will attempt to enter your server. \n"
    + "All viruses are malicious and will harm your reputation and your server's health.\n"
    + "Packets can be malicious or just fine. Packets must be scanned to determine if they are bad or not. \n"
    + "If a scanned packet is safe, all packets with the same ID are also safe. \n"
    + "If a scanned packet is unsafe, all packets with that ID are also unsafe.\n"
    + "If safe packets enter your server, your reputation increases. If an unsafe packet enters, your server will lose health \n"
    + "and you will lose reputation. There are power ups you can click on in order to help you out.\n"
    + "Be warned, the server traffic will increase over time.\n"
    + "If your server has no health left, you lose. If your reputation reaches 100, you win!"
    , width/2, height/2);
    
    //Buttons-------------------------------------
    fill(0, 255, 255);
    stroke(60, 207, 207);
    //Back Button
    rect(110, 560, 150, 50, 35); 
    //ButtonText
    textSize(20);
    fill(0);
    text("Back", 110, 563);
    
    textAlign(LEFT, BASELINE);
  }
  
  String handleMouse(float x, float y){
    if ((x>=35) && (x<= 185) && (y>= 540) && (y<=590)){
      return "start";
    } else { 
     return "instructions"; 
    }
  }
}
