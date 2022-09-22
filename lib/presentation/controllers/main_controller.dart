import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:uri_to_file/uri_to_file.dart';
import 'dart:io';

class MainController extends GetxController {
  final OnAudioQuery query = OnAudioQuery();
  RxBool isPlaying = false.obs;
  final player = AudioPlayer();
  Rx<Duration> duration = Duration(seconds: 100).obs;
  Rx<Duration> position = Duration(seconds: 0).obs;
  RxInt currentSongId = 0.obs;
  RxList<SongModel> songs = <SongModel>[].obs;
  RxInt currentIndex = 0.obs;
  RxBool songIsFirstInQueue = false.obs;
  RxBool songIsLastInQueue = false.obs;
  Rx<SongModel> song = SongModel({}).obs;
  Rx<Uint8List> songPicture = Uint8List(0).obs;

  @override
  Future<void> onInit() async {
    // TODO: implement onInit
    super.onInit();
    requestStoragePermission();
    player.onPlayerStateChanged.listen((state) {
      isPlaying.value = state == PlayerState.PLAYING;
      if (state == PlayerState.COMPLETED && !songIsLastInQueue.value) {
        nextOrPrevSong(nextSong: true);
        update();
      }
    });
    player.onDurationChanged.listen((state) {
      duration.value = state;
    });
    player.onAudioPositionChanged.listen((state) {
      position.value = state;
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> startPlaying(String localPath) async {
    File songFile = await toFile(localPath);
    await player.play(songFile.path, isLocal: true);
  }

  void requestStoragePermission() async {
    if (!kIsWeb) {
      bool permission = await query.permissionsStatus();
      if (!permission) {
        await query.permissionsRequest();
      }
    }
  }

  Future<void> nextOrPrevSong({required bool nextSong}) async {
    currentIndex.value =
        nextSong ? currentIndex.value + 1 : currentIndex.value - 1;

    currentIndex.value == 0
        ? songIsFirstInQueue.value = true
        : songIsFirstInQueue.value = false;

    currentIndex.value == songs.length - 1
        ? songIsLastInQueue.value = true
        : songIsLastInQueue.value = false;

    startPlaying(songs[currentIndex.value].uri!.toString());

    currentSongId.value = songs[currentIndex.value].id;

    isPlaying.value = true;

    song.value = songs[currentIndex.value];
    songPicture.value =
        await query.queryArtwork(song.value.id, ArtworkType.AUDIO) ??
            Uint8List(0);
  }
}
