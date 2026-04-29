import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ListUserDataPage(),
    );
  }
}

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    String path = p.join(await getDatabasesPath(), "user_db.db");
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, nama TEXT, umur INTEGER)",
        );
      },
    );
  }

  // CREATE
  static Future<int> insertData(UserModel userModel) async {
    final db = await database;
    final Map<String, dynamic> user = userModel.toJson()..remove("id"); // ✅ remove id
    return await db.insert("users", user, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // READ
  static Future<List<UserModel>> getData() async {
    final db = await database;
    List<Map<String, Object?>> result = await db.query("users");
    return result.map((userMap) => UserModel.fromJson(userMap)).toList();
  }

  // UPDATE
  static Future<int> updateData(int id, UserModel userModel) async {
    final db = await database;
    var user = userModel.toJson()..remove("id"); //
    return await db.update("users", user, where: "id = ?", whereArgs: [id]);
  }

  // DELETE
  static Future<int> deleteData(int id) async {
    final db = await database;
    return await db.delete("users", where: "id = ?", whereArgs: [id]);
  }
}

class UserModel {
  int? id;
  String nama = "";
  int umur = 0;

  UserModel(this.id, {required this.nama, required this.umur});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(json["id"], nama: json["nama"], umur: json["umur"]);
  }

  Map<String, dynamic> toJson() {
    return {"id": id, "nama": nama, "umur": umur};
  }
}

class ListUserDataPage extends StatefulWidget {
  const ListUserDataPage({super.key});

  @override
  State<ListUserDataPage> createState() => _ListUserDataPageState();
}

class _ListUserDataPageState extends State<ListUserDataPage> {
  final TextEditingController _namaCtrl = TextEditingController();
  final TextEditingController _umurCtrl = TextEditingController();
  List<UserModel> userList = [];

  @override
  void initState() {
    super.initState();
    _reloadData();
  }

  void _reloadData() async {
    var users = await DatabaseHelper.getData();
    setState(() {
      userList = users;
    });
  }

  void _form(int? id) {
    if (id != null) {
      var user = userList.firstWhere((data) => data.id == id);
      _namaCtrl.text = user.nama;
      _umurCtrl.text = user.umur.toString();
    } else {
      _namaCtrl.clear();
      _umurCtrl.clear();
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 50),
        child: Column(
          children: [
            TextField(
              controller: _namaCtrl,
              decoration: InputDecoration(hintText: "Nama"),
            ),
            TextField(
              controller: _umurCtrl,
              decoration: InputDecoration(hintText: "Umur"),
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(
              onPressed: () => _save(id, _namaCtrl.text, int.parse(_umurCtrl.text)),
              child: Text(id == null ? "Tambah" : "Perbaharui"),
            ),
          ],
        ),
      ),
    );
  }

  void _save(int? id, String nama, int umur) async {
    var newUser = UserModel(id, nama: nama, umur: umur);
    if (id != null) {
      await DatabaseHelper.updateData(id, newUser);
    } else {
      await DatabaseHelper.insertData(newUser);
    }
    Navigator.pop(context);
    _reloadData();
  }

  void _delete(int? id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Konfirmasi Hapus"),
        content: Text("Apakah anda yakin ingin menghapus ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.deleteData(id!); // ✅ null assertion
              Navigator.pop(context);               // ✅ tutup dialog dulu
              _reloadData();
            },
            child: Text("Hapus"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User List")),
      body: ListView.builder(
        itemCount: userList.length,
        itemBuilder: (cxt, i) => ListTile(
          title: Text(userList[i].nama),
          subtitle: Text("umur: ${userList[i].umur} tahun"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => _form(userList[i].id),
                child: Icon(Icons.edit),
              ),
              TextButton(
                onPressed: () => _delete(userList[i].id),
                child: Icon(Icons.delete),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _form(null),
        child: Icon(Icons.add),
      ),
    );
  }
}