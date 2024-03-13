import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class RewardsProgress extends StatefulWidget {
  const RewardsProgress({
    super.key,
    required this.rewardSteps,
    required this.completedSteps,
  });

  //Manage the logic of the positioned elements

  final int rewardSteps;
  final int completedSteps;

  @override
  State createState() => _RewardsProgressState();
}

class _RewardsProgressState extends State<RewardsProgress> with TickerProviderStateMixin {
  List<AnimationController> animationControllers = [];

  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    for (int i = 0; i <= widget.rewardSteps; i++) {
      animationControllers.add(AnimationController(vsync: this));
    }

    super.initState();
  }

  @override
  void dispose() {
    for (AnimationController controller in animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  //This function will be called after each animation completes, passing an higher index value each time
  void startAnimation(int animationIndex) {
    if (animationIndex < widget.rewardSteps && animationIndex <= widget.completedSteps) {
      animationControllers[animationIndex].forward().whenComplete(() => startAnimation(animationIndex + 1));
    }
    //Every 5 steps, animate the scroll controller, unless it is at the end
    if (animationIndex % 4 == 0 && animationIndex < widget.rewardSteps && animationIndex <= widget.completedSteps) {
      //Scroll the controller based on what the current animation index is
      scrollController.animateTo(animationIndex * 80, duration: const Duration(seconds: 1), curve: Curves.easeIn);
    }
  }

  //Determines which animation should be used in the reward step
  //It can be 3 different animations, where a step is checked, where a step is halfway done and where all the steps are completed
  String currentLottiePath(int index) {
    String returnedString = "assets/check.json";
    if (index == widget.rewardSteps - 1) {
      returnedString = "assets/finish.json";
    } else if (index >= widget.completedSteps) {
      returnedString = "assets/halfway.json";
    }
    return returnedString;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(parent: NeverScrollableScrollPhysics()),
      child: Stack(
        fit: StackFit.passthrough,
        alignment: Alignment.centerLeft,
        children: [
          for (int i = 0; i < widget.rewardSteps; i++) ...[
            Container(
              height: 75,
              margin: EdgeInsets.only(left: i * 75),
              child: RewardStepLottie(
                controller: animationControllers[i],
                lottiePath: currentLottiePath(i),
                nextControllerCallback: (index) => startAnimation(index + 1),
                controllerIndex: i,
                //Is first will determine which lottie widget will start the animation chain
                isFirst: i == 0,
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class RewardStepLottie extends StatefulWidget {
  final AnimationController controller;
  final bool isFirst;
  final Function(int)? nextControllerCallback;
  final String lottiePath;
  final int controllerIndex;

  const RewardStepLottie(
      {super.key,
      required this.controller,
      required this.lottiePath,
      this.isFirst = false,
      this.nextControllerCallback,
      required this.controllerIndex});

  @override
  State createState() => _RewardStepLottieState();
}

class _RewardStepLottieState extends State<RewardStepLottie> {
  late final AnimationController controller;
  bool hideMan = true;

  @override
  void initState() {
    controller = widget.controller;
    //When the animation starts, make the person visible
    //The person will then become invisible after the animation is completed
    controller.addStatusListener((status) {
      if (status == AnimationStatus.forward) {
        setState(() => hideMan = false);
      }
      if (status == AnimationStatus.completed) {
        setState(() => hideMan = true);
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(widget.lottiePath,
        controller: controller,
        delegates: LottieDelegates(
          values: [
            //When the animation ends, the person outline will become transparent to keep them from being seen at the end of each step
            ValueDelegate.opacity(
              const ['**', 'man Outlines', '**'],
              value: hideMan ? 0 : 100,
            ),
          ],
        ), onLoaded: (composition) {
      controller.duration = composition.duration;
      //If the widget is the first in the sequence, then start the animation which will create the chain reaction of the animations playing after eachother
      if (widget.isFirst) {
        controller.forward().whenComplete(() {
          widget.nextControllerCallback?.call(widget.controllerIndex);
        });
      }
    });
  }
}
