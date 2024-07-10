import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  File? _imageFile;

  final Stream<QuerySnapshot> _usersStream =
  FirebaseFirestore.instance.collection('users').snapshots();

  Future<File?> getImage() async {
    try {
      final pickerImage =
      await ImagePicker().getImage(source: ImageSource.gallery);
      if (pickerImage != null) {
        print('success');
        return File(pickerImage.path);

      } else {
        print('No image selected.');
        return null;
      }
    } catch (e) {
      print('Error selecting image: $e');
      return null;
    }
  }
  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(
                  height: 10,
                ),
                const Center(
                    child: Text(
                      'Add a new data',
                      style: TextStyle(fontSize: 20),
                    )),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      File? image = await getImage();
                      if (image != null) {
                        setState(() {
                          _imageFile = image;
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : null,
                      child: _imageFile == null
                          ? Image.asset('assets/images/user.png')
                          : null,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _addressController,
                    keyboardType: TextInputType.name,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: MaterialButton(
                      shape: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none),
                      color: Colors.lightBlue,
                      onPressed: () async {
                        String name = _nameController.text;
                        String phone = _phoneController.text;
                        String address = _addressController.text;

                        if (name.isEmpty ||
                            phone.isEmpty ||
                            address.isEmpty ||
                            _imageFile == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Please fill all fields'),
                            backgroundColor: Colors.red,
                          ));
                          return;
                        } else {
                          await insertData(name, phone, address, _imageFile);
                          _nameController.clear();
                          _phoneController.clear();
                          _addressController.clear();
                          _imageFile = null;

                          Navigator.pop(context);
                        }
                      },
                      child: const Center(
                        child: Text(
                          'Save',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      )),
                ),
                const SizedBox(
                  height: 10,
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> insertData(String name, String phone, String address, File? imageFile) async {
    try {
      String imageUrl = await _uploadImageToFirebaseStorage(imageFile!);
      await FirebaseFirestore.instance.collection('users').add({
        'name': name,
        'phone': phone,
        'address': address,
        'imageUrl': imageUrl,
      });
      print('Data added successfully!');
    } catch (ex) {
      print('Error adding data: $ex');
    }
  }

  void _showEditBottomSheet(BuildContext context, String documentId, String name, String phone, String imageUrl) {
    TextEditingController nameController = TextEditingController(text: name);
    TextEditingController phoneController = TextEditingController(text: phone);

    File? newImageFile;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Data'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      File? image = await getImage();
                      if (image != null) {
                        setState(() {
                          newImageFile = image;
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: newImageFile != null
                          ? FileImage(newImageFile!)
                          : imageUrl.isNotEmpty
                          ? NetworkImage(imageUrl)
                          : AssetImage('assets/images/user.png') as ImageProvider,
                    ),
                  ),
                ),
                TextField(
                  controller: nameController,
                  keyboardType: TextInputType.name,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                String newName = nameController.text;
                String newPhone = phoneController.text;
                updateData(
                    documentId, newName, newPhone, newImageFile, imageUrl);

                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> updateData(String documentId, String newName, String newPhone, File? newImageFile, String oldImageUrl) async {
    try {
      String newImageUrl = oldImageUrl;
      if (newImageFile != null) {
        newImageUrl = await _uploadImageToFirebaseStorage(newImageFile);
      }
      await FirebaseFirestore.instance.collection('users').doc(documentId).update({
        'name': newName,
        'phone': newPhone,
        'imageUrl': newImageUrl,
      });
      print('Data updated successfully!');
    } catch (ex) {
      print('Error updating data: $ex');
    }
  }

  void _showDeleteConfirmation(BuildContext context, String documentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this data?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                deleteData(documentId);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteData(String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(documentId)
          .delete();
      print('Data deleted successfully!');
    } catch (ex) {
      print('Error deleting data: $ex');
    }
  }

  Future<String> _uploadImageToFirebaseStorage(File imageFile) async {
    try {
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images/${DateTime.now().millisecondsSinceEpoch}');
      await storageRef.putFile(imageFile);
      final String imageUrl = await storageRef.getDownloadURL();
      print('Uploaded image to Firebase Storage: $imageUrl');
      return imageUrl;
    } catch (ex) {
      print('Error uploading image to Firebase Storage: $ex');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        title: const Text(
          'Firebase Firestore',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder(
        stream: _usersStream,
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: Text('no data'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
              document.data()! as Map<String, dynamic>;
              return GestureDetector(
                onLongPress: () {
                  _showDeleteConfirmation(context, document.id);
                },
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage("${data['imageUrl']}"),
                        ),
                        title: Text(data['name']),
                        subtitle: Text(data['phone']),
                        trailing: GestureDetector(
                            onTap: () {
                              _showEditBottomSheet(context, document.id,
                                  data['name'], data['phone'], data['imageUrl']);
                            },
                            child: const Icon(Icons.edit)),
                      )
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showBottomSheet(context);
        },
        backgroundColor: Colors.lightBlue,
        shape: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide.none,
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
