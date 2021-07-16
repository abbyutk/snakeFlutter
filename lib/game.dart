import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Game extends StatefulWidget {

  @override
  _GameState createState() => _GameState();
}


// ************************************************
// * Initial variables                            *
// * x, y is for tracking snake heads position.   *
// * beat position is a list for storing the posi-*
// * -tion of snake.                              *
// * origin is for tacking the swipe gestures.    *
// * else every variable name specifies well that *
// * what they are doing                          *
// * Every function name also specifies well what *
// * it is doing.                                 *
// ************************************************

double x = 0;
double y = 0;
double canvasHeight = 300;
double speed = 0.5;
ValueNotifier<int> _canvasNotifier = ValueNotifier<int>(0);
ValueNotifier<int> _scoreNotifier = ValueNotifier<int>(0);
ValueNotifier<bool> _pauseNotifier = ValueNotifier<bool>(false);
double foodX = 10;
double foodY = 20; 
double origin = 0;
int length = 1 ;
bool gameOver = false;
int frame = 40;
int fps = (1/frame * 1000).round();
List<Offset> beatPositions = [Offset(10,10)];

enum Movements{Up, Down, Left, Right}
 Movements currentMove = Movements.Right ;

// ************************************************
// * Each time player hit the range food gets con-*
// * -sumed.                                      *
// * Doubling speed each time food gets cosumed   *
// * This function also increase length by 1.     *
// * origin is for tacking the swipe gestures.    *
// * Add 5 points and update the ui               *
// * and get new food location                    *
// ************************************************

void checkIfFoodConsumed(Size screenSize){
  if(foodX >= beatPositions[0].dx-10 && foodX <= beatPositions[0].dx+10 ){
    if(foodY >= beatPositions[0].dy-10 && foodY<= beatPositions[0].dy+10){
      speed+=0.1;
      length++;
      _scoreNotifier.value+=5;
      beatPositions.add(beatPositions[0]); //adding new beat in the list.
      getNewFoodLocation(screenSize);
    }
  }
}

// ************************************************
// * Generating new food location by using random *
// * function.                                    *
// * It also check if the generated food postion  *
// * is out of the frame and regenarets new       *
// * location automatically.                      *
// * Add 5 points and update the ui               *
// * and get new food location                    *
// ************************************************
void getNewFoodLocation(Size screenSize){
  int xLimit = (screenSize.width * 0.98).round();
  int yLimit = (canvasHeight * 0.98).round();
  foodX = Random().nextInt(xLimit) * 1.0 ;
  foodY = Random().nextInt(yLimit) * 1.0;
  if(foodX <= screenSize.width * 0.01 || foodY < screenSize.width * 0.01 ) getNewFoodLocation(screenSize);
}


// ************************************************
// * Movement Functions wil increase or decrease  *
// * x, y positions as appropriate to move.       *
// ************************************************

void moveUp({move = false}){
  if(move)y-=speed;
}
void moveDown({move = false}){
  if(move)y+=speed;
}
void moveLeft({move = false}){
  if(move)x-=speed;
}
void moveRight({move = false}){
  if(move)x+=speed;
}
// ************************************************
// * Draw() function draws the frames.            *
// * It also make sure if tehre is gameover or fo-*
// * -od consumed.                                *
// * Also calls movement function according to    *
// * current movement variable.                   *
// ************************************************
void draw(Size screenSize){
  checkIfFoodConsumed(screenSize);
      if( x > screenSize.width * 0.97 || x< screenSize.width * 0.01){
        _pauseNotifier.value = true;
        gameOver = true;
      }
      if(y > canvasHeight * 0.98 || y < screenSize.width * 0.01){
         _pauseNotifier.value = true;
         gameOver = true;
      }
        switch (currentMove) {
          case Movements.Up: moveUp(move:true);
            break;
          case Movements.Down: moveDown(move:true);
            break;
          case Movements.Left: moveLeft(move:true);
            break;
          case Movements.Right: moveRight(move:true);
            break;
          default:
      }
      _canvasNotifier.value+=1; //Updating frames using notifier.
}

// ************************************************
// * Initialises initial variables.               *
// ************************************************
void initBoard(screenSize){
    canvasHeight = screenSize.height * 0.8;
    currentMove = Movements.Right;
    x=screenSize.width * 0.05;
    y=screenSize.width * 0.05;
    length = 1;
    speed = 0.5;
    getNewFoodLocation(screenSize);
    gameOver = false;
    _scoreNotifier.value = 0;
    _pauseNotifier.value = false;
    beatPositions = [Offset(x,y)];
}

class _GameState extends State<Game> {
  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    initBoard(screenSize);
    Timer.periodic(Duration(milliseconds: fps), (timer) { //call function/sec accoring to fps.
      if(!_pauseNotifier.value && !gameOver)draw(screenSize); //dont draw if the gameover or paused.
     });
    return Scaffold(
      floatingActionButton: FloatingActionButton(//pauses the game and restrats too.
        onPressed: (){
          if(_pauseNotifier.value && gameOver){
            initBoard(screenSize);
          }else _pauseNotifier.value = !_pauseNotifier.value;
        },
        child: ValueListenableBuilder(
          valueListenable: _pauseNotifier,
          builder: (context, v , c){
            IconData icon = Icons.play_arrow;
            if(_pauseNotifier.value && gameOver) icon = Icons.replay;
            else if(!_pauseNotifier.value) icon = Icons.pause;
            return Icon(icon,color: Colors.white, size:20);
          },
        ),
      ),
      body: Stack(
        children: [
          Container(
            //score widget
            child: ValueListenableBuilder(
              valueListenable: _scoreNotifier,
              builder: (context, v, c) => Text(
              'Score : ${_scoreNotifier.value}',
              style: GoogleFonts.lobster(
                fontSize: 20,
              ),
            ),
            ),
          ),
          ValueListenableBuilder(
            //gameover widget
            valueListenable: _pauseNotifier,
            builder: (context, v, c)=>Visibility(
            visible: gameOver,
            child: Center(
            child: Container(
              child: Text(
                'Game Over !!',
                style: GoogleFonts.waitingForTheSunrise(
                  fontSize:50,
                ),
              ),
            ),
          ),
          ),
          ),
          Container(
            margin: EdgeInsets.only(top: screenSize.height * 0.05),
            child: GestureDetector(
            onVerticalDragUpdate: (update){
              //check if swipe up or down and updates the currentmovement to the specific move.
              if(origin > update.delta.dy && currentMove != Movements.Down) currentMove = Movements.Up;
              else if(origin < update.delta.dy && currentMove != Movements.Up) currentMove = Movements.Down;
            },
            onHorizontalDragUpdate: (update){
              //check if swipe left or right and updates the currentmovement to the specific move.
              if(origin > update.delta.dx && currentMove != Movements.Right) currentMove = Movements.Left;
              else if(origin < update.delta.dx && currentMove != Movements.Left) currentMove = Movements.Right;
            },
            child:  ValueListenableBuilder(

              //canvas widget
               valueListenable: _canvasNotifier,
               builder: (context, value, child) => CustomPaint(
                 size: screenSize,
               painter: CanvasPainter(
                 offset: Offset(x,y),
                 rootSize:screenSize,
                 foodOffset: Offset(foodX, foodY),
                 length: length,
               ),
             ),
            ),
          ),
          ),
        ],
      ),
    );
  }
}
class CanvasPainter extends CustomPainter{
  final offset ;
  final rootSize ;
  final foodOffset;
  final length ;

  CanvasPainter({
    @required this.offset, 
    @required this.rootSize, 
    @required this.foodOffset,
    this.length,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var p = Paint()..color = Colors.blue
                   ..style = PaintingStyle.stroke
                   ..strokeWidth = size.width * 0.03;
     final Rect border = Offset(0,0) & Size(rootSize.width, canvasHeight);
    canvas.drawRect(border, p);
    int snakeLength = length ;
    if(length == 0 || length == null) snakeLength = 1;
    while(snakeLength != 0){
      canvas.drawRect(snakeBeat(snakeLength),Paint()..color = Colors.red);
      snakeLength--;
    }
    canvas.drawCircle(foodOffset, 5,Paint()..color = Colors.green);
  }
// ************************************************
// * This function draw the current snake beat    *
// * and pass the positon to its previous beats   *
// * for appropriate moving effect.               *
// ************************************************
  Rect snakeBeat(int snakeIndex){
    if(beatPositions.length > snakeIndex) beatPositions[snakeIndex] = beatPositions[snakeIndex-1];
     if(snakeIndex == 1)beatPositions[0] = Offset(x,y);
    return beatPositions[snakeIndex-1] & Size(rootSize.width * 0.02, rootSize.width * 0.02);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

}