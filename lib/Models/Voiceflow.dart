import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String> sendToVoiceflow(String userText) async {
  const String apiKey = 'VF.DM.68063ca4821a36494d3ec6d6.tVAkPiV28sL9wLzj';

  final url = Uri.parse('https://general-runtime.voiceflow.com/state/user/$apiKey/interact?logs=off');

  final response = await http.post(
    url,
    headers: {'Authorization': apiKey, 'Content-Type': 'application/json'},
    body: jsonEncode({"request": {"type": "text", "payload": userText}}),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    for (var item in data) {
      if (item['type'] == 'text') {
        return item['payload']['message'].toString();
      }
    }
    return 'No text response from Voiceflow';
  } else {
    return 'Error ${response.statusCode} from Voiceflow';
  }
}