import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound/android_encoder.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

Uuid uuid = Uuid();
FlutterSound fs = FlutterSound();
void main() => runApp(App());
class App extends StatelessWidget {
  @override Widget build(BuildContext context) => MaterialApp(title: 'SOUNDBOARD', home: Board(),
    theme: ThemeData(primaryColor: Colors.black, primarySwatch: Colors.deepOrange, fontFamily: 'MajorMonoDisplay'),
  );
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
    fs.stopPlayer(); curPath = await fs.startRecorder('$dir${uuid.v4()}.mp4', androidEncoder: AndroidEncoder.HE_AAC, bitRate: 96000);
    recSub = fs.onRecorderStateChanged.listen((e) { if (e != null) { setState(() { isRec = true; }); if (e.currentPosition.toInt() >= 10000) stop(); rota += 0.017; }});
  }
  stop() async {
    fs.stopRecorder();
    if (recSub != null) { recSub.cancel(); recSub = null; }
    setState(() { isRec = false; paths.add(curPath); curPath = null; save(); rota = 0; });
  }
  save() async => (await SharedPreferences.getInstance()).setStringList('paths', paths);
  Future<List<String>> load() async => paths = (await SharedPreferences.getInstance()).getStringList('paths') ?? List();
  remove(ctx, path) {
    Scaffold.of(ctx)..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('SOUND deleted', style: TextStyle(fontFamily: 'MajorMonoDisplay')), duration: Duration(seconds: 2)));
    setState(() { paths.remove(path); save(); File(path).delete(); });
  }
  remAll() => setState(() { while (paths.isNotEmpty) { File(paths.removeLast()).delete(); } save(); });
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(elevation: 0, centerTitle: true,
      title: Text('SOUNDboard', textScaleFactor: 1.5), actions: [IconButton(icon: Icon(Icons.delete_sweep), onPressed: remAll, tooltip: 'delete all')],
    ),
    body: Center(child: _buildFuture()),
    floatingActionButton: FloatingActionButton.extended(label: Text(isRec ? 'stop' : 'record'),
      icon: isRec ? Transform.rotate(angle: rota, child: Icon(Icons.stop)) : Icon(Icons.mic), onPressed: isRec ? stop : record,
    ),
  );
  _buildFuture() => FutureBuilder(future: load(), initialData: paths,
    builder: (ctx, AsyncSnapshot<List<String>> snap) => snap.hasData && snap.data.isNotEmpty ? _buildGrid(snap.data) : Text('record a SOUND to start!', textScaleFactor: 1.5),
  );
  _buildGrid(List<String> list) => GridView.count(padding: EdgeInsets.all(16.0), crossAxisSpacing: 16.0, mainAxisSpacing: 16.0,
    crossAxisCount: MediaQuery.of(context).orientation == Orientation.portrait ? 3 : 5,
    children: list.map((p) => Sound(path: p, remove: remove, enable: !isRec)).toList(),
  );
}
class Sound extends StatefulWidget {
  Sound({Key key, this.path, this.remove, this.enable}) : super(key: key);
  final String path; final Function remove; final bool enable;
  @override _SoundState createState() => _SoundState();
}
class _SoundState extends State<Sound> {
  bool isPlaying = false;
  double progress = 0;
  int animDur = 1;
  StreamSubscription<PlayStatus> playSub;
  play() async {
    try { await fs.stopPlayer(); } catch(e) {}
    setState(() => animDur = 1);
    await fs.startPlayer(widget.path);
    playSub = fs.onPlayerStateChanged.listen((e) { if (e != null) setState(() { isPlaying = true; progress = (e.currentPosition/e.duration*100).ceilToDouble()/100; }); else stop(); });
  }
  stop() async {
    try { await fs.stopPlayer(); } catch(e) {}
    if (playSub != null) { playSub.cancel(); playSub = null; }
    setState(() { isPlaying = false; animDur = 1000; progress = 0; });
  }
  @override Widget build(BuildContext context) => AspectRatio(aspectRatio: 1, child: SizedBox.expand(child: _buildAC()));
  _buildAC() => AnimatedContainer(curve: isPlaying ? Curves.linear : Curves.bounceOut, duration: Duration(milliseconds: animDur),
    decoration: BoxDecoration(shape: BoxShape.circle,
      gradient: SweepGradient(colors: [Colors.deepOrangeAccent[100], Colors.deepOrangeAccent, Colors.transparent], stops: [0, progress, progress]),
    ),
    child: GestureDetector(onLongPress: () => widget.remove(context, widget.path), child: _buildButton()),
  );
  _buildButton() => OutlineButton(shape: CircleBorder(),
    onPressed: widget.enable ? (isPlaying ? stop : play) : null,
    child: Transform.scale(child: Icon(isPlaying ? Icons.stop : Icons.play_arrow), scale: 2),
  );
}
