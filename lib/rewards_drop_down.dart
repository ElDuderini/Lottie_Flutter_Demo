import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class RewardsProgress extends StatefulWidget {
  const RewardsProgress({super.key});

  //Manage the logic of the positioned elements

  @override
  State createState() => _RewardsProgressState();
}

class _RewardsProgressState extends State<RewardsProgress> with TickerProviderStateMixin {
  List<AnimationController> animationControllers = [];

  ScrollController scrollController = ScrollController();

  late final int rewardSteps;

  late final int completedSteps;

  @override
  void initState() {
    completedSteps = 10;
    rewardSteps = 10;
    for (int i = 0; i <= rewardSteps; i++) {
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

  void startAnimation(int animationIndex) {
    if (animationIndex < rewardSteps && animationIndex <= completedSteps) {
      animationControllers[animationIndex].forward().whenComplete(() => startAnimation(animationIndex + 1));
    }
    //Every 5 steps, animate the scroll controller, unless it is at the end
    if (animationIndex % 4 == 0 && animationIndex < rewardSteps && animationIndex <= completedSteps) {
      scrollController.animateTo(animationIndex * 80, duration: const Duration(seconds: 1), curve: Curves.easeIn);
    }
  }

  String currentLottiePath(int index) {
    String returnedString = "assets/check.json";
    if (index == rewardSteps - 1) {
      returnedString = "assets/finish.json";
    } else if (index >= completedSteps) {
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
          for (int i = 0; i < rewardSteps; i++) ...[
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
            ValueDelegate.opacity(
              const ['**', 'man Outlines', '**'],
              value: hideMan ? 0 : 100,
            ),
          ],
        ), onLoaded: (composition) {
      controller.duration = composition.duration;
      if (widget.isFirst) {
        controller.forward().whenComplete(() {
          widget.nextControllerCallback?.call(widget.controllerIndex);
        });
      }
    });
  }
}
