import 'dart:convert';
import 'dart:io';
import 'package:dartx/dartx.dart';
import 'package:dio/dio.dart';

import 'constants/app_languages.dart';

// Enter your API Keys here
const String geminiApiKey = "AIzaSyCiVXNMt-5mV9bIrZbjCmaACoriR5dET9g";
const String openAiApiKey = "";
const String anthropicApiKey = "";

enum AiAgent { gemini, chatgpt, claude }

void main() async {
  final dir = Directory('assets/lang');
  final dio = Dio();

  // Identify available agents
  List<AiAgent> availableAgents = [];
  if (geminiApiKey.isNotEmpty) availableAgents.add(AiAgent.gemini);
  if (openAiApiKey.isNotEmpty) availableAgents.add(AiAgent.chatgpt);
  if (anthropicApiKey.isNotEmpty) availableAgents.add(AiAgent.claude);

  if (availableAgents.isEmpty) {
    print(
      "Error: No API keys provided. Please set at least one API key in lib/ai_translator.dart",
    );
    exit(1);
  }

  print("Available Agents: ${availableAgents.map((e) => e.name).join(', ')}");

  //
  final List<FileSystemEntity> entities = await dir.list().toList();
  //get the new-lang values
  print("Loading New Lang Strings");
  final fullLanguageStringsEntity = entities.firstWhere(
    (e) => e.path.endsWith("full-lang.txt"),
  );
  final newLanguageStringsEntity = entities.firstWhere(
    (e) => e.path.endsWith("new-lang.txt"),
  );

  //
  print("Loading New Lang Strings");
  File file = File(newLanguageStringsEntity.path);
  // Filter out comments and internal notes, take only actual strings
  List<String> newLangStrings = (await file.readAsString()).split("\n");

  // Clean up empty strings if any
  newLangStrings = newLangStrings.where((s) => s.trim().isNotEmpty).toList();

  int agentIndex = 0;
  int chunkSize = 50;

  //
  for (var code in AppLanguages.codes) {
    //loop through new-lang and use ai agents to translate it
    print(
      "Translating ==> ${code} (${AppLanguages.names[AppLanguages.codes.indexOf(code)]})",
    );
    try {
      Map<String, String> newTranslatedData = new Map<String, String>();
      int processedCount = 0;

      // Process in chunks
      for (var i = 0; i < newLangStrings.length; i += chunkSize) {
        var end =
            (i + chunkSize < newLangStrings.length)
                ? i + chunkSize
                : newLangStrings.length;
        List<String> batch = newLangStrings.sublist(i, end);

        if (code != "en") {
          Map<String, String>? batchTranslations;
          int attempts = 0;

          // Retry logic
          while (batchTranslations == null &&
              attempts < availableAgents.length) {
            int availableAgentIndex =
                (agentIndex + attempts) % availableAgents.length;
            AiAgent currentAgent = availableAgents[availableAgentIndex];

            try {
              if (currentAgent == AiAgent.gemini) {
                batchTranslations = await translateBatchWithGemini(
                  dio,
                  batch,
                  code,
                );
                print(
                  "Translated batch ${i ~/ chunkSize + 1} with Gemini (${batch.length} items)",
                );
              } else if (currentAgent == AiAgent.chatgpt) {
                batchTranslations = await translateBatchWithChatGPT(
                  dio,
                  batch,
                  code,
                );
                print(
                  "Translated batch ${i ~/ chunkSize + 1} with ChatGPT (${batch.length} items)",
                );
              } else if (currentAgent == AiAgent.claude) {
                batchTranslations = await translateBatchWithClaude(
                  dio,
                  batch,
                  code,
                );
                print(
                  "Translated batch ${i ~/ chunkSize + 1} with Claude (${batch.length} items)",
                );
              }
            } catch (e) {
              print(
                "Agent ${currentAgent.name} failed batch ${i ~/ chunkSize + 1}: $e. Retrying with next agent...",
              );
              attempts++;
            }
          }

          if (batchTranslations != null) {
            newTranslatedData.addAll(batchTranslations);
          } else {
            print("Failed to translate batch ${i ~/ chunkSize + 1} to $code.");
            // Fallback
            for (var s in batch) {
              newTranslatedData[s] = s;
            }
          }

          // Rotate agent for next batch
          agentIndex++;
        } else {
          // English just maps to itself
          for (var s in batch) {
            newTranslatedData[s] = s;
          }
        }

        processedCount += batch.length;
        print("Done:: $processedCount/${newLangStrings.length}");

        // Delay between batches
        await Future.delayed(Duration(milliseconds: 1000));
      }

      //
      final langFileEntity = entities.firstOrNullWhere(
        (e) => e.path.toLowerCase().contains(code.toLowerCase()),
      );

      //
      File langFile;

      //if the code file doest exist the create one
      if (langFileEntity == null) {
        langFile = await File("assets/lang/$code.json").create();
        await langFile.writeAsString("{}");
      } else {
        langFile = File(langFileEntity.path);
      }

      //
      final oldLangJson = jsonDecode(await langFile.readAsString());
      final newMergedLangJson = {...newTranslatedData, ...oldLangJson};
      await langFile.writeAsString(jsonEncode(newMergedLangJson));
    } catch (error) {
      print("Error with:: $error");
    }
    print("-----------------------");
  }

  // Only append if we actually processed something
  if (newLangStrings.isNotEmpty) {
    final newLangString = newLangStrings.join("\n");
    final oldLangFile = File(fullLanguageStringsEntity.path);
    String oldLangString = await oldLangFile.readAsString();
    await oldLangFile.writeAsString("$oldLangString\n$newLangString");
    //when all is done without error, clear the content of the
    await File(newLanguageStringsEntity.path).writeAsString("");
  }
}

// ---------------------------------------------------------------------------
// AI Agent Translation Functions (Batch)
// ---------------------------------------------------------------------------

Future<Map<String, String>> translateBatchWithGemini(
  Dio dio,
  List<String> texts,
  String targetLang,
) async {
  if (geminiApiKey.isEmpty) throw Exception("Gemini API Key is missing");

  // Create mappings of original -> placeholder or index if needed to be robust,
  // but sending JSON list and asking for JSON list is usually fine for these models.
  final prompt =
      "Translate the following list of texts to language code '$targetLang'. "
      "Return ONLY a JSON array of strings, maintaining the exact same order. "
      "Do not include markdown formatting or explanations.\n\nInput:\n${jsonEncode(texts)}";

  final response = await dio.post(
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiApiKey',
    data: {
      "contents": [
        {
          "parts": [
            {"text": prompt},
          ],
        },
      ],
      'generationConfig': {'response_mime_type': 'application/json'},
    },
  );

  if (response.statusCode == 200) {
    try {
      final candidates = response.data['candidates'] as List;
      if (candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List;
        if (parts.isNotEmpty) {
          final jsonText = parts[0]['text'].toString().trim();
          List<dynamic> decoded = jsonDecode(jsonText);

          Map<String, String> results = {};
          for (int i = 0; i < texts.length; i++) {
            if (i < decoded.length) {
              results[texts[i]] = decoded[i].toString();
            } else {
              results[texts[i]] = texts[i]; // Fallback
            }
          }
          return results;
        }
      }
    } catch (e) {
      throw Exception("Failed to parse Gemini response: $e");
    }
  }
  throw Exception(
    "Gemini API Error: ${response.statusCode} ${response.statusMessage}",
  );
}

Future<Map<String, String>> translateBatchWithChatGPT(
  Dio dio,
  List<String> texts,
  String targetLang,
) async {
  if (openAiApiKey.isEmpty) throw Exception("OpenAI API Key is missing");

  final prompt =
      "Translate the following list of texts to language code '$targetLang'. "
      "Return ONLY a JSON array of strings, maintaining the exact same order. "
      "Do not include markdown formatting or explanations.";

  final response = await dio.post(
    'https://api.openai.com/v1/chat/completions',
    options: Options(
      headers: {
        'Authorization': 'Bearer $openAiApiKey',
        'Content-Type': 'application/json',
      },
    ),
    data: {
      "model": "gpt-3.5-turbo",
      "messages": [
        {"role": "system", "content": prompt},
        {"role": "user", "content": jsonEncode(texts)},
      ],
      "temperature": 0.3,
    },
  );

  if (response.statusCode == 200) {
    final choices = response.data['choices'] as List;
    if (choices.isNotEmpty) {
      final content = choices[0]['message']['content'].toString().trim();
      List<dynamic> decoded = jsonDecode(content);

      Map<String, String> results = {};
      for (int i = 0; i < texts.length; i++) {
        if (i < decoded.length) {
          results[texts[i]] = decoded[i].toString();
        } else {
          results[texts[i]] = texts[i];
        }
      }
      return results;
    }
  }
  throw Exception("ChatGPT API Error: ${response.statusCode}");
}

Future<Map<String, String>> translateBatchWithClaude(
  Dio dio,
  List<String> texts,
  String targetLang,
) async {
  if (anthropicApiKey.isEmpty) throw Exception("Claude API Key is missing");

  final prompt =
      "Translate the following list of texts to language code '$targetLang'. "
      "Return ONLY a JSON array of strings, maintaining the exact same order. "
      "Do not include markdown formatting or explanations.\n\nInput:\n${jsonEncode(texts)}";

  final response = await dio.post(
    'https://api.anthropic.com/v1/messages',
    options: Options(
      headers: {
        'x-api-key': anthropicApiKey,
        'anthropic-version': '2023-06-01',
        'Content-Type': 'application/json',
      },
    ),
    data: {
      "model": "claude-3-haiku-20240307",
      "max_tokens": 4096, // Increased for batch
      "messages": [
        {"role": "user", "content": prompt},
      ],
    },
  );

  if (response.statusCode == 200) {
    final content = response.data['content'] as List;
    if (content.isNotEmpty) {
      final jsonText = content[0]['text'].toString().trim();
      List<dynamic> decoded = jsonDecode(jsonText);

      Map<String, String> results = {};
      for (int i = 0; i < texts.length; i++) {
        if (i < decoded.length) {
          results[texts[i]] = decoded[i].toString();
        } else {
          results[texts[i]] = texts[i];
        }
      }
      return results;
    }
  }
  throw Exception("Claude API Error: ${response.statusCode}");
}
