import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:soft_player/presentation/controllers/main_controller.dart';

import '../widgets/neubox.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey[300],
        body: GetBuilder<MainController>(
          init: MainController(),
          builder: (controller) {
            return FutureBuilder<List<SongModel>>(
                future: controller.query.querySongs(
                    sortType: SongSortType.DURATION,
                    orderType: OrderType.DESC_OR_GREATER,
                    uriType: UriType.EXTERNAL,
                    ignoreCase: true),
                builder: (context, snapshot) {
                  if (snapshot.data == null) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No songs in query'),
                    );
                  }
                  controller.songs.value = snapshot.data!
                      .where((element) =>
                          element.duration! >= 50000 &&
                          element.fileExtension == 'mp3' &&
                          element.isMusic! &&
                          !element.isRingtone!)
                      .toList();
                  return ListView.builder(
                    physics: BouncingScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: controller.songs.length,
                      itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 10),
                            child: NeuBox(
                              child: InkWell(
                                onTap: () {
                                  playFromHome(controller, snapshot, index);
                                },
                                child: ListTile(
                                  title: Text(snapshot.data![index].title),
                                  subtitle:
                                      Text(snapshot.data![index].displayName),
                                  leading: QueryArtworkWidget(
                                      id: snapshot.data![index].id,
                                      type: ArtworkType.AUDIO),
                                ),
                              ),
                            ),
                          ));
                });
          },
        ),
      ),
    );
  }

  Future<void> playFromHome(MainController controller, AsyncSnapshot<List<SongModel>> snapshot, int index) async {
    controller.startPlaying(
        snapshot.data![index].uri!.toString());
    controller.currentSongId.value =
        snapshot.data![index].id;
    controller.currentIndex.value = index;
    controller.currentIndex.value == 0
        ? controller.songIsFirstInQueue.value = true
        : controller.songIsFirstInQueue.value = false;
    
    controller.currentIndex.value ==
        controller.songs.length - 1
        ? controller.songIsLastInQueue.value = true
        : controller.songIsLastInQueue.value = false;
    controller.isPlaying.value = true;
    controller.song.value = snapshot.data![index];
    controller.songPicture.value = await controller.query.queryArtwork(controller.song.value.id, ArtworkType.AUDIO) ?? Uint8List(0);
    print(controller.songPicture.value);
    Get.to(
        SongPage(), transition: Transition.downToUp);
  }
}

class SongPage extends StatefulWidget {
  MainController controller = Get.find<MainController>();

  SongPage({
    Key? key,
  }) : super(key: key);

  @override
  State<SongPage> createState() => _SongPageState();
}

class _SongPageState extends State<SongPage> {
  @override
  Widget build(BuildContext context) {
    print(widget.controller.song);
    return Scaffold(
      body: Container(
        color: Colors.grey.shade300,
        height: MediaQuery.of(context).size.height,
        child: Padding(
          padding: const EdgeInsets.only(top: 50.0, left: 30, right: 30),
          child: Column(
            children: [
              buildTopButtons(),
              const SizedBox(
                height: 20,
              ),
              buildSongPicture(),
              buildPositionAndDuration(),
              buildProgressBar(context),
              const SizedBox(
                height: 30,
              ),
               FutureBuilder<Obx>(
                 future: buildControlButtons(),
  builder: (context, widgetState) {
    return widgetState.data!;
  },
)
            ],
          ),
        ),
      ),
    );
  }

  Future<Obx> buildControlButtons() async {
    return Obx(() => SizedBox(
                  height: 80,
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            if(!widget.controller.songIsFirstInQueue.value){
                              widget.controller.nextOrPrevSong(nextSong: false);
                              setState(() {});
                            }
                          },
                          child: NeuBox(
                              child:  Icon(
                            Icons.skip_previous,
                            size: 32,
                                color: widget.controller.songIsFirstInQueue.value? Colors.grey : Colors.black,

                              )),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: InkWell(
                          onTap: () async {
                            if (widget.controller.isPlaying.value) {
                              await widget.controller.player.pause();
                              widget.controller.isPlaying.value = false;
                            } else {
                              await widget.controller.player.resume();
                              widget.controller.isPlaying.value = true;
                            }
                          },
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: NeuBox(
                                child: Icon(
                              widget.controller.isPlaying.value
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 32,
                            )),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            if(!widget.controller.songIsLastInQueue.value){
                              widget.controller.nextOrPrevSong(nextSong: true);
                              setState(() {});
                            }
                          },
                          child: NeuBox(
                              child:  Icon(
                            Icons.skip_next,
                            size: 32,
                                color: widget.controller.songIsLastInQueue.value? Colors.grey : Colors.black,
                          )),
                        ),
                      ),
                    ],
                  ),
                ));
  }

  Obx buildProgressBar(BuildContext context) {
    return Obx(() => SizedBox(
                width: MediaQuery.of(context).size.width,
                child: NeuBox(
                  child: LinearPercentIndicator(
                    percent: getPercentOfProgress(
                        widget.controller.duration.value.inSeconds,
                        widget.controller.position.value.inSeconds),
                    progressColor: Colors.green,
                    backgroundColor: Colors.transparent,
                    lineHeight: 10,
                    barRadius: const Radius.circular(10),
                  ),
                )));
  }

  Obx buildPositionAndDuration() {
    return Obx(
              () => Padding(
                padding: const EdgeInsets.all(30.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formatTime(widget.controller.position.value)),
                    Text(formatTime(widget.controller.duration.value))
                  ],
                ),
              ),
            );
  }

  SizedBox buildSongPicture() {
    print(widget.controller.songPicture.value.runtimeType);
    return SizedBox(
              height: 400,
              child: NeuBox(
                  child: Obx(
                    ()=> Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                         widget.controller.songPicture.value != null && widget.controller.songPicture.value.isNotEmpty?
                             SizedBox(
                              height: 315,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                widget.controller.songPicture.value,
                                  fit: BoxFit.fitHeight,
                                ),
                              ),
                            ):  Icon(
                              Icons.image_not_supported,
                              size: 330,
                            ),

                    Padding(
                      padding: const EdgeInsets.only(top: 5.0, left: 5),
                      child: Text(
                        widget.controller.song.value.artist!,
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey.shade700),
                      ),
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 5.0, left: 5),
                        child: Text(
                          widget.controller.song.value.title,
                          style: const TextStyle(
                              fontSize: 20, color: Colors.black),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
                  )),
            );
  }

  Row buildTopButtons() {
    return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => Get.back(),
                  child: SizedBox(
                    height: 60,
                    width: 60,
                    child: NeuBox(
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 60,
                  width: 60,
                  child: NeuBox(
                    child: const Icon(
                      Icons.menu_rounded,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            );
  }

  void nextOrPrevSong({required bool nextSong}) {
    widget.controller.currentIndex.value = nextSong
        ? widget.controller.currentIndex.value + 1
        : widget.controller.currentIndex.value - 1;

    widget.controller.currentIndex.value == 0
        ? widget.controller.songIsFirstInQueue.value = true
        : widget.controller.songIsFirstInQueue.value = false;

    widget.controller.currentIndex.value ==
        widget.controller.songs.length - 1
        ? widget.controller.songIsLastInQueue.value = true
        : widget.controller.songIsLastInQueue.value = false;


    widget.controller.startPlaying(widget
        .controller.songs[widget.controller.currentIndex.value].uri!
        .toString());

    widget.controller.currentSongId.value =
        widget.controller.songs[widget.controller.currentIndex.value].id;

    widget.controller.isPlaying.value = true;

    widget.controller.song.value = widget.controller.songs[widget.controller.currentIndex.value];
  }

  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }

  double getPercentOfProgress(int firstNumber, int secondNumber) {
    double firstAction = secondNumber / firstNumber;
    double secondAction = firstAction * 100;
    String intAction = int.parse(secondAction.round().toString()).toString();
    double result = int.parse(intAction) < 10
        ? double.parse('0.0' + intAction)
        : double.parse('0.' + intAction);
    return result;
  }
}
