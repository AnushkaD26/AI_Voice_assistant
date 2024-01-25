import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_ai/secrets.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  final List<Map<String, String>> messages = [];

  Future<String> isArtPromptAPI(String prompt) async {
    /* Future is object that represents a value is not available now but will
    be available in future.
    */
    try {
      // await keyword waits for the Future to complete and then return value
      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAIAPIKey'
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo-1106',
          'messages': [
            {
              'role': 'user',
              'content':
                  'Does this want to generate chat? $prompt. Simply tell yes or no',
            }
          ],
        }),
      );
      if (kDebugMode) {
        print(res.body);
      }
      if (res.statusCode == 200) {
        String content =
            jsonDecode(res.body)['choices'][0]['message']['content'];
        content = content.trim();
        switch (content) {
          /* case 'Yes':
          case 'yes':
          case 'Yes.':
          case 'yes.': */

          case 'No':
          case 'no':
          case 'No.':
          case 'no.':
            final res = await dallEAPI(prompt);
            return res;
          default:
            final res = await chatGPTAPI(prompt);
            return res;
        }
      }
      return 'An Internal error occured';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> chatGPTAPI(String prompt) async {
    messages.add({
      // users's response
      'role': 'user',
      'content': prompt,
    });
    try {
      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAIAPIKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo-1106',
          'messages': messages,
        }),
      );
      if (res.statusCode == 200) {
        String content =
            jsonDecode(res.body)['choices'][0]['message']['content'];
        content = content.trim();
        messages.add({
          // assistant's response
          'role': 'assistant',
          'content': content,
        });
        return content;
      }
      return "An Internal error occured";
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> dallEAPI(String prompt) async {
    messages.add({
      'role': 'user',
      'content': prompt,
    });
    try {
      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/images/generations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAIAPIKey',
        },
        body: jsonEncode({
          'model': 'dall-e-2',
          'prompt': prompt,
          'n': 1, // only one image to be generated each time
        }),
      );

      if (res.statusCode == 200) {
        String imageUrl = jsonDecode(res.body)['data'][0]['url'];
        imageUrl = imageUrl.trim();

        messages.add({
          'role': 'assistant',
          'content': imageUrl,
        });
        return imageUrl;
      }
      return 'An Internal error occured';
    } catch (e) {
      return e.toString();
    }
  }
}
