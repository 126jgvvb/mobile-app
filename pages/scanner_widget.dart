import 'package:flutter/material.dart';


class ImageScanner extends AnimatedWidget{
  late final bool stopped;
  late final double width;

// ignore: prefer_const_constructors_in_immutables
ImageScanner(this.stopped,this.width,{ super.key,required Animation<double> animation,}):super(listenable: animation);

@override
  Widget build(BuildContext context){
  final Animation<double> animation=listenable as Animation<double>;
  final scorePositon=(animation.value*440)+16;

  Color col1=const Color(0x5532CD32);
  Color col2=const Color(0x0032CD32);

  if(animation.status==AnimationStatus.reverse){
    col1=const Color(0x0032CD32);
    col2=const Color(0x5532CD32);
  }

  return Positioned(
    bottom: scorePositon,
    left: 16.0,
    child: Opacity(
opacity: (stopped)?0.0:0.3,
child: Container(
  height:50.0,
  width: width,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [col1,col2],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0.1,0.9]
      )
  ),
),
    )
    );
}

}