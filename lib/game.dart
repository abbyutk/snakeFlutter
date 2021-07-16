import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Game extends StatefulWidget {

  @override
  _GameState createState() => _GameState();
}

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

enum Movements{Up, Down, Left, Right}
 Movements currentMove = Movements.Right ;

void checkIfFoodConsumed(Size screenSize){
  if(foodX >= beatPositions[0].dx-10 && foodX <= beatPositions[0].dx+10 ){
    if(foodY >= beatPositions[0].dy-10 && foodY<= beatPositions[0].dy+10){
      speed+=0.1;
      length++;
      _scoreNotifier.value+=5;
      beatPositions.add(beatPositions[0]);
      getNewFoodLocation(screenSize);
    }
  }
}

List<Offset> beatPositions = [Offset(10,10)];

void getNewFoodLocation(Size screenSize){
  int xLimit = (screenSize.width * 0.98).round();
  int yLimit = (canvasHeight * 0.98).round();
  foodX = Random().nextInt(xLimit) * 1.0 ;
  foodY = Random().nextInt(yLimit) * 1.0;
  if(foodX <= screenSize.width * 0.01 || foodY < screenSize.width * 0.01 ) getNewFoodLocation(screenSize);
  print("Food location : x : $foodX and Y : $foodY");
}

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
      _canvasNotifier.value+=1;
}

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
    Timer.periodic(Duration(milliseconds: fps), (timer) {
      if(!_pauseNotifier.value && !gameOver)draw(screenSize);
     });
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          if(_pauseNotifier.value && gameOver){
            initBoard(screenSize);
          }else _pauseNotifier.value = !_pauseNotifier.value;
        },
        child: ValueListenableBuilder(
          valueListenable: _pauseNotifier,
          builder: (context, v , c){
            IconData icon = Icons.play_arrow;
            if(_pauseNotifier.value && gameOver) icon = Icons.repeat;
            else if(!_pauseNotifier.value) icon = Icons.pause;
            return Icon(icon,color: Colors.white, size:20);
          },
        ),
      ),
      body: Stack(
        children: [
          Container(
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
            // behavior: HitTestBehavior.translucent,
            onVerticalDragUpdate: (update){
              if(origin > update.delta.dy && currentMove != Movements.Down) currentMove = Movements.Up;
              else if(origin < update.delta.dy && currentMove != Movements.Up) currentMove = Movements.Down;
            },
            onHorizontalDragUpdate: (update){
              if(origin > update.delta.dx && currentMove != Movements.Right) currentMove = Movements.Left;
              else if(origin < update.delta.dx && currentMove != Movements.Left) currentMove = Movements.Right;
            },
            child:  ValueListenableBuilder(
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

  Rect snakeBeat(int snakeIndex){
    Offset o = beatPositions[snakeIndex-1];
    if(beatPositions.length > snakeIndex) beatPositions[snakeIndex] = beatPositions[snakeIndex-1];
     if(snakeIndex == 1)beatPositions[0] = Offset(x,y);
    return beatPositions[snakeIndex-1] & Size(rootSize.width * 0.02, rootSize.width * 0.02);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

}