
import 'dart:io';
import 'dart:typed_data';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Gemini gemini = Gemini.instance;
  List<ChatMessage> messages =[];
  final ChatUser currentUser = ChatUser(id: "0" , firstName: "Abir Bin Billal");
  final ChatUser geminiUser = ChatUser(id: "1" , firstName:  " Gemini " , profileImage: "https://c.files.bbci.co.uk/1A4D/production/_121033760_6ddb0ce4-b50f-4ef6-b9eb-8601540f6c0a.jpg" );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Gemini Chat"),
      ),
      body: _buildUI(),
    );
  }
  Widget _buildUI(){
    return DashChat(
        inputOptions: InputOptions(
          trailing: [
            IconButton(
                onPressed: sendMediaFile,
                icon: Icon(Icons.image))
          ]
        ),
        currentUser: currentUser,
        onSend: sendMessage,
        messages: messages);
  }
  void sendMessage(ChatMessage chatMessage){
setState(() {
  messages = [chatMessage, ...messages];
});
try{
  String question = chatMessage.text;
  List<Uint8List>? images;
  if(chatMessage.medias!.isNotEmpty ?? false){
    images = [
      File(chatMessage.medias!.first.url).readAsBytesSync()
    ];
  }
  gemini.streamGenerateContent(question , images: images).listen((event){
    ChatMessage? lastMessage = messages.firstOrNull;
    if(lastMessage != null && lastMessage.user == geminiUser){
      ChatMessage? lastmessage = messages.removeAt(0);
      String response =  event.content?.parts?.fold("", (previous , current) => "$previous ${current.text}")?? "";
      lastmessage.text += response;
      setState(() {
        messages = [lastmessage! , ...messages];
      });
    }else{
      String response =  event.content?.parts?.fold("", (previous , current) => "$previous ${current.text}")?? "";
      ChatMessage message = ChatMessage(user: geminiUser, createdAt: DateTime.now() , text: response);
      setState(() {
        messages = [message, ...messages];
      });
    }
  });
}catch(e){
  print(e);
}
  }
  void sendMediaFile() async{
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if(file != null){
      ChatMessage message = ChatMessage(user: currentUser, createdAt: DateTime.now() ,text: "Describe this Picture", medias:
      [
        ChatMedia(url: file!.path, fileName: file.name, type: MediaType.image)
      ]);
      sendMessage(message);
    }
  }
}
