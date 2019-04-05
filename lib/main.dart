import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

Uuid uuid = Uuid();
FlutterSound fs = FlutterSound();
void main() => runApp(App());

class App extends StatelessWidget {
  @override Widget build(BuildContext context) {
    return MaterialApp(title: 'SOUNDBOARD', home: Board(),
      theme: ThemeData(primaryColor: Colors.black, primarySwatch: Colors.deepOrange, fontFamily: 'MajorMonoDisplay'),
    );
  }
}
class Board extends StatefulWidget {
  Board({Key key}) : super(key: key);
  @override _BoardState createState() => _BoardState();
}
class _BoardState extends State<Board> {
  List<String> paths = List();
  bool isRec = false;
  String curPath;
  StreamSubscription<RecordStatus> recSub;
  double rota = 0;
  record() async {
    var dir = '${(await getExternalStorageDirectory()).path}/fsb/'; Directory(dir).create();
    fs.stopPlayer(); curPath = await fs.startRecorder('$dir${uuid.v4()}.mp4');
    recSub = fs.onRecorderStateChanged.listen((e) {
      if (e != null) { setState(() { isRec = true; }); if (e.currentPosition.toInt() >= 10000) stop(); rota += 0.017; }
    });
  }
  stop() async {
    fs.stopRecorder();
    if (recSub != null) { recSub.cancel(); recSub = null; }
    setState(() { isRec = false; paths.add(curPath); curPath = null; save(); rota = 0; });
  }
  save() async => (await SharedPreferences.getInstance()).setStringList('paths', paths);
  Future<List<String>> load() async => paths = (await SharedPreferences.getInstance()).getStringList('paths') ?? List();
  void remove(ctx, path) {
    Scaffold.of(ctx).showSnackBar(SnackBar(content: Text('SOUND removed', style: TextStyle(fontFamily: 'MajorMonoDisplay')), duration: Duration(seconds: 1)));
    setState(() { paths.remove(path); save(); File(path).delete(); });
  }
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0, centerTitle: true,
        title: Text('SOUNDboard', textScaleFactor: 1.5),
      ),
      body: Center(child: _buildFuture()),
      floatingActionButton: FloatingActionButton.extended(label: Text(isRec ? 'stop' : 'record'),
        icon: isRec ? Transform.rotate(angle: rota, child: Icon(Icons.stop)) : Icon(Icons.mic),
        onPressed: isRec ? stop : record,
      ),
    );
  }
  _buildFuture() {
    return FutureBuilder(future: load(), initialData: paths,
      builder: (ctx, AsyncSnapshot<List<String>> snap) => snap.hasData && snap.data.isNotEmpty ? _buildGrid(snap.data) : Text('record a SOUND to start!', textScaleFactor: 1.5),
    );
  }
  _buildGrid(List<String> list) {
    return GridView.count(padding: EdgeInsets.all(16.0), crossAxisCount: 3, crossAxisSpacing: 16.0, mainAxisSpacing: 16.0,
      children: list.map((p) => Sound(path: p, remove: remove, enable: !isRec)).toList());
  }
}
class Sound extends StatefulWidget {
  Sound({Key key, this.path, this.remove, this.enable}) : super(key: key);
  final String path;
  final Function remove;
  final bool enable;
  @override _SoundState createState() => _SoundState();
}
class _SoundState extends State<Sound> {
  bool isPlaying = false;
  double progress = 0;
  int animDur = 1000;
  StreamSubscription<PlayStatus> playSub;
  play() async {
    try { await fs.stopPlayer(); } catch(e) {}
    setState(() { animDur = 1; });
    await fs.startPlayer(widget.path);
    playSub = fs.onPlayerStateChanged.listen((e) {
      if (e != null) setState(() { isPlaying = true; progress = (e.currentPosition/e.duration*100).ceilToDouble()/100; });
      else stop();
    });
  }
  stop() async {
    try { await fs.stopPlayer(); } catch(e) {}
    if (playSub != null) { playSub.cancel(); playSub = null; }
    setState(() { isPlaying = false; animDur = 1000; progress = 0; });
  }
  @override Widget build(BuildContext context) => AspectRatio(aspectRatio: 1, child: SizedBox.expand(child: _buildAC()));
  _buildAC() {
    return AnimatedContainer(
      curve: isPlaying ? Curves.linear : Curves.bounceOut,
      duration: Duration(milliseconds: animDur),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(colors: [Colors.deepOrangeAccent[100], Colors.deepOrangeAccent, Colors.transparent], stops: [0, progress, progress]),
      ),
      child: GestureDetector(onLongPress: () => widget.remove(context, widget.path), child: _buildButton()),
    );
  }
  _buildButton() {
    return OutlineButton(shape: CircleBorder(),
      onPressed: widget.enable ? (isPlaying ? stop : play) : null,
      child: Transform.scale(child: Icon(isPlaying ? Icons.stop : Icons.play_arrow), scale: 2),
    );
  }
}
