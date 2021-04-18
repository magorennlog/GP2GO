import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Run your app with 'flutter run --dart-define=OPENAI_KEY=YOUR_API_KEY_HERE
const OPENAI_KEY = String.fromEnvironment("OPENAI_KEY");

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    /// Global widget for our app
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,

      /// Our custom theme colors
      theme: ThemeData(
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
      ), 
      /// The main page
      home: MyHomePage(title: 'small STEPS'),
    );
  }
}

/// Dataclass to store a single message,
/// either from you or the AI
class Message {
  String text;
  bool byMe;

  Message(this.text, this.byMe);
}

/// Main page of our app, containing a scrollable chat history and a text field
class MyHomePage extends StatefulWidget {
  final String title;
  MyHomePage({Key key, this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();

  static _MyHomePageState of(BuildContext context) {
    return context.findAncestorStateOfType();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  var textEditingController = TextEditingController();

  /// The initial promt given to OpenAI
  String prompt =
      "John is an expert in nutrition, fitness and health. John is trustworthy and very polite. John askes two questions and than gives a short advice to the user. John finishes with a list of three recommendations to the user based on the users question.

###
User-data
The users name is Marvin. He lives in Germany. He is a single man. He works as a Consultant and sits in front of the computer a lot. His weight is 90kg and he is 185cm tall. Marvin jogs 5km per week and walks 5000 steps per day. His average heart rate is 70bpm. 

Marvin: I have a backpain. Do you have any recomendations for me?
John: Hi Marvin, gald you ask for help. Hopfully I can give you good advice. Are you doing exercises?
Marvin: No, not realy.
John: Do you stand up frequently while you work for a pause?
Marvin: yes, once in awhile.
John: Ok Marvin, here is my advice for you:
1. Stand up frequently while you work for a pause.
2. Do some exercises, like yoga.
3. Move on your chair every 30 minutes. To not forget set a timer.

Do you want to make one of it a habit?

###
User-data
The users name is Christin. She lives in Italy. She is a married. Christin is working at a supermarket with no light. She stands all day. Her weight is 56 kg and she is 172cm tall. Christin jogs 7km per week and walks 7000 steps per day. Her average heart rate is 65bpm. 
      
      The following is a conversation with an AI assistant. The assistant is helpful, creative, clever, and very friendly.\n"
      "Human: Hello, who are you?\n"
      "AI: I am an AI created by OpenAI. How can I help you today?" ; /// The history of chat messages sent
  List<Message> messages = [];

  /// Construct a prompt for OpenAI with the new message and store the response
  void sendMessage(String message) async {
    if (message == "") {
      return;
    }

    /// Store the message itself
    setState(() {
      messages.add(Message(message, true));
    });

    /// Reset the text input
    textEditingController.text = "";

    /// Continue the prompt template
    prompt += "\n"
        "$message\n";

    /// Make the api request to OpenAI
    /// See available api parameters here: https://beta.openai.com/docs/api-reference/completions/create
    print("here is prompt"+prompt);
    var result = await http.post(
      Uri.parse("https://api.openai.com/v1/engines/davinci/completions"),
      headers: {
        "Authorization": "Bearer $OPENAI_KEY",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "prompt": prompt,
        "max_tokens": 60,
        "temperature": 0.53,
        "top_p": 1,
        "stop": "\n",
      }),
    );

    /// Decode the body and select the first choice
    var body2 = jsonDecode(result.body);
    print(body2);
    var text = body2["choices"][0]["text"];
    print("here is response"+text);
    prompt += text;

    /// Store the response message
    setState(() {
      messages.add(Message(text.trim(), false));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// The top app bar with title
      appBar: AppBar(
        title: Text(widget.title, style: TextStyle(fontFamily: 'Sensei', color: Colors.lightBlue[200], fontWeight: FontWeight.bold, fontSize: 40)),
      ),
      body: Column(
        children: [
          /// The chat history
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              reverse: true, // makes it 'stick' to the bottom when sending new messages
              children: messages.reversed.map((message) {
                return Bubble(
                  child: Text(message.text, style: TextStyle(fontSize:18, color: Color(0xff33658a))), color: message.byMe ? Color(
                    0xffbadefc) : Color(0xffFF9585),
                  nip: message.byMe ? BubbleNip.rightBottom : BubbleNip.leftBottom,
                  alignment: message.byMe ? Alignment.topRight : Alignment.topLeft,
                  margin: BubbleEdges.symmetric(vertical: 5),
                );
              }).toList(),
            ),
          ),

          /// The bottom text field
          Container(
            color: Colors.lightGreen[200],
            padding: EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: TextStyle(fontSize:24.0, color: Color(0xffffffff)),
                    controller: textEditingController,
                    decoration: InputDecoration(
                      hintText: "Deine Frage",
                      hintStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 30),
                    ),
                    onSubmitted: (text) {
                      sendMessage(text);
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    size: 34.0,
                  ),
                  onPressed: () {
                    sendMessage(textEditingController.text);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
