import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:googleapis/vision/v1.dart' hide Color;
import 'package:googleapis/texttospeech/v1.dart';
import 'package:audiofileplayer/audiofileplayer.dart';

import 'credentials.dart';

Future<PictureAnalysis> analyzePicture(File path) async {
  // Create the object to store the analysis in
  PictureAnalysis analysis = new PictureAnalysis();
  // Create a string buffer to build up a sentence describing what is seen.
  StringBuffer sentence = new StringBuffer();
  try {
    // The minimum score before including the result in our description
    var minimumScore = 0.5;
    // Same thing but for likelihood
    var minimumLikelihood = ['POSSIBLE', 'LIKELY', 'VERY_LIKELY'];
    // Obtain client for credentials
    var client = await CredentialsProvider().client;
    // Initialize the Vision API client
    var vision = VisionApi(client);
    var text2Speech = TexttospeechApi(client);
    // Convert the image to a base64-encoded string
    var imageBytes = await path.readAsBytes();
    String base64Image = base64Encode(imageBytes);
    // Create the request for the Vision API, with the features we wish to extract
    var response = await vision.images.annotate(
        BatchAnnotateImagesRequest.fromJson({
          "requests": [
            {
              "image": {"content": base64Image},
              "features": [
                {"type": "WEB_DETECTION"},
                {"type": "LOGO_DETECTION"},
                {"type": "LANDMARK_DETECTION"},
                {"type": "FACE_DETECTION"},
                {"type": "LABEL_DETECTION"},
                {"type": "TEXT_DETECTION"},
                {"type": "DOCUMENT_TEXT_DETECTION"},
                {"type": "OBJECT_LOCALIZATION"},
                {"type": "PRODUCT_SEARCH"}
              ]
            }
          ]
        }));
    if (response?.responses?.isNotEmpty ?? false) {
      for (final a in response.responses) {
        if (a.faceAnnotations?.isNotEmpty ?? false) {
          List<String> faces = new List();
          for (final f in a.faceAnnotations) {
            if (f != null && (f.detectionConfidence == null || f.detectionConfidence >= minimumScore)) {
              List<String> emotions = new List();
              if (minimumLikelihood.contains(f.angerLikelihood)) emotions.add('an angry');
              if (minimumLikelihood.contains(f.blurredLikelihood)) emotions.add('${emotions.isNotEmpty ? "" : "a "}blurred');
              if (minimumLikelihood.contains(f.joyLikelihood)) emotions.add('${emotions.isNotEmpty ? "" : "a "}happy');
              if (minimumLikelihood.contains(f.surpriseLikelihood)) emotions.add('${emotions.isNotEmpty ? "" : "a "}surprised');
              if (minimumLikelihood.contains(f.sorrowLikelihood)) emotions.add('${emotions.isNotEmpty ? "" : "a "}sad');
              if (minimumLikelihood.contains(f.underExposedLikelihood)) emotions.add('${emotions.isNotEmpty ? "" : "an "}underexposed');
              var faceInfo;
              if (emotions.isNotEmpty) {
                faceInfo = emotions.join(" & ") + " one";
              } else faceInfo = "a neutral one";
              if (minimumLikelihood.contains(f.headwearLikelihood)) faceInfo += ' wearing headgear';
              faces.add(faceInfo);
            }
          }
          if (faces.isNotEmpty) {
            analysis.setFaces(faces.join(", "));
            sentence.write("I see ${faces.length} face${faces.length > 1 ? "s": ""}: ${analysis.faces}. ");
          }
        }
        if (a.localizedObjectAnnotations?.isNotEmpty ?? false) {
          List<String> loas = new List();
          for (final o in a.localizedObjectAnnotations) {
            if (o != null && (o.score == null || o.score >= minimumScore)) loas.add(o.name);
          }
          if (loas.isNotEmpty) {
            analysis.setObjects(loas.join(", "));
            sentence.write("${sentence.length > 0 ? "Additionally, " : ""} I can recognize ${loas.length} object${loas.length > 1 ? "s": ""} in front of me: ${analysis.objects}. ");
          }
        }
        if (a.labelAnnotations?.isNotEmpty ?? false) {
          List<String> labels = new List();
          for (final l in a.labelAnnotations) {
            if (l != null && (l.score == null || l.score >= minimumScore)) labels.add(l.description);
          }
          if (labels.isNotEmpty) {
            analysis.setLabels(labels.join(", "));
            sentence.write("I would associate what I see with the following ${labels.length} label${labels.length > 1 ? "s": ""}: ${analysis.labels}. ");
          }
        }
        if (a.productSearchResults?.results?.isNotEmpty ?? false) {
          List<String> products = new List();
          for (final p in a.productSearchResults.results) if (p.product.displayName != null) products.add(p.product.displayName);
          if (products.isNotEmpty) analysis.setProducts(products.join(", "));
          if (products.length > 0) sentence.write("I ${sentence.length > 0 ? "also" : ""} see ${products.length} product${products.length > 1 ? "s": ""}; ${products.join(", ")}. ");
        }
        if (a.logoAnnotations?.isNotEmpty ?? false) {
          List<String> logos = new List();
          for (final l in a.logoAnnotations) {
            if (l != null && (l.score == null || l.score >= minimumScore)) logos
                .add(l.description);
          }
          if (logos.isNotEmpty) {
            analysis.setLogos(logos.join(", "));
            sentence.write(
                "I was able to discern ${logos.length} logo${logos.length > 1
                    ? "s"
                    : ""} in the scene before me: ${analysis.logos}. ");
          }
        }
        if (a.landmarkAnnotations?.isNotEmpty ?? false) {
          List<String> landmarks = new List();
          for (final l in a.landmarkAnnotations) {
            if (l != null && (l.score == null || l.score >= minimumScore)) landmarks.add(l.description);
          }
          if (landmarks.isNotEmpty) {
            analysis.setLandmarks(landmarks.join(", "));
            sentence.write("I'm pretty sure I can ${sentence.length > 0 ? "also" : ""} recognize ${landmarks.length} landmark${landmarks.length > 1 ? "s": ""}: ${analysis.landmarks}");
            print(sentence);
          }
        }
        if (a.fullTextAnnotation?.text?.isNotEmpty ?? false) analysis.setText(a.fullTextAnnotation.text.replaceAll("\n", " "));
        if (a.webDetection != null && a.webDetection.bestGuessLabels != null && a.webDetection.bestGuessLabels.isNotEmpty) {
          List<String> webLabels = new List();
          for (final l in a.webDetection.bestGuessLabels) webLabels.add(l.label);
          if (webLabels.isNotEmpty) {
            analysis.setWebLabels(webLabels.join(", "));
            sentence.write("${analysis.text?.isNotEmpty ?? false ? "I" : "Finally, i"}n order to find more similar pictures, you could try an online search with the following ${webLabels.length} label${webLabels.length > 1 ? "s": ""}: ${analysis.webLabels}. ");
          }
        }
        if (analysis.text?.isNotEmpty ?? false) sentence.write("Finally, I was able to read the following text: ${analysis.text}");
      }
    }
    // If the sentence we've built isn't an empty string, let's convert it to audio
    if (sentence.length > 0) {
      analysis.setSentence(sentence.toString());
      var audio = await text2Speech.text.synthesize(SynthesizeSpeechRequest.fromJson({
        "audioConfig": {
          "audioEncoding": "OGG_OPUS",
          "effectsProfileId": [
            "handset-class-device"
          ],
          "pitch": 0,
          "speakingRate": 1
        },
        "input": {
          "text": analysis.sentence
        },
        "voice": {
          "languageCode": "en-GB",
          "name": "en-GB-Wavenet-A"
        }
      }));
      // Convert the audio to ByteData so we can play it with the audio component
      analysis.setAudio(ByteData.view(base64Decode(audio.audioContent).buffer));
    }
  } catch (e) {
    print(e);
    analysis.setError(e.toString());
  }
  return analysis;
}

class PictureAnalysis {
  String _products;
  String _webLabels;
  String _objects;
  String _logos;
  String _labels;
  String _text;
  String _faces;
  String _landmarks;
  String _sentence;
  String _error;
  ByteData _audio;

  void setProducts(String products) {
    this._products = products;
  }

  String get products {
    return this._products;
  }

  void setWebLabels(String webLabels) {
    this._webLabels = webLabels;
  }

  String get webLabels {
    return this._webLabels;
  }

  void setObjects(String objects) {
    this._objects = objects;
  }

  String get objects {
    return this._objects;
  }

  void setLogos(String logos) {
    this._logos = logos;
  }

  String get logos {
    return this._logos;
  }

  void setLabels(String labels) {
    this._labels = labels;
  }

  String get labels {
    return this._labels;
  }

  void setText(String text) {
    this._text = text;
  }

  String get text {
    return this._text;
  }

  void setFaces(String faces) {
    this._faces = faces;
  }

  String get faces {
    return this._faces;
  }

  void setLandmarks(String landmarks) {
    this._landmarks = landmarks;
  }

  String get landmarks {
    return this._landmarks;
  }

  void setSentence(String sentence) {
    this._sentence = sentence;
  }

  String get sentence {
    return this._sentence;
  }

  void setAudio(ByteData audio) {
    this._audio = audio;
  }

  ByteData get audio {
    return this._audio;
  }

  void setError(String error) {
    this._error = error;
  }

  String get error {
    return this._error;
  }
}

class AnalyzePictureScreen extends StatelessWidget {
  final File image;

  const AnalyzePictureScreen({Key key, this.image}) : super(key: key);

  List<RichText> convertToRichText(PictureAnalysis a) {
    TextStyle defaultStyle = TextStyle(fontSize: 12, color: Colors.indigo);
    TextStyle topicStyle = TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.bold);
    List<RichText> txts = new List();
    if (a.products != null) {
      txts.add(RichText(text: new TextSpan(
          style: defaultStyle,
          children: <TextSpan>[
            TextSpan(text: 'Products: ', style: topicStyle),
            TextSpan(text: a.products)
          ]
      )));
    }
    if (a.webLabels != null) {
      txts.add(RichText(text: new TextSpan(
          style: defaultStyle,
          children: <TextSpan>[
            TextSpan(text: 'Web Labels: ', style: topicStyle),
            TextSpan(text: a.webLabels)
          ]
      )));
    }
    if (a.objects != null) {
      txts.add(RichText(text: new TextSpan(
          style: defaultStyle,
          children: <TextSpan>[
            TextSpan(text: 'Objects: ', style: topicStyle),
            TextSpan(text: a.objects)
          ]
      )));
    }
    if (a.logos != null) {
      txts.add(RichText(text: new TextSpan(
          style: defaultStyle,
          children: <TextSpan>[
            TextSpan(text: 'Logos: ', style: topicStyle),
            TextSpan(text: a.logos)
          ]
      )));
    }
    if (a.labels != null) {
      txts.add(RichText(text: new TextSpan(
          style: defaultStyle,
          children: <TextSpan>[
            TextSpan(text: 'Labels: ', style: topicStyle),
            TextSpan(text: a.labels)
          ]
      )));
    }
    if (a.text != null) {
      txts.add(RichText(text: new TextSpan(
          style: defaultStyle,
          children: <TextSpan>[
            TextSpan(text: 'Text: ', style: topicStyle),
            TextSpan(text: a.text)
          ]
      )));
    }
    if (a.faces != null) {
      txts.add(RichText(text: new TextSpan(
          style: defaultStyle,
          children: <TextSpan>[
            TextSpan(text: 'Faces: ', style: topicStyle),
            TextSpan(text: a.faces)
          ]
      )));
    }
    if (a.landmarks != null) {
      txts.add(RichText(text: new TextSpan(
          style: defaultStyle,
          children: <TextSpan>[
            TextSpan(text: 'Landmarks: ', style: topicStyle),
            TextSpan(text: a.landmarks)
          ]
      )));
    }
    if (a.sentence != null) {
      txts.add(RichText(text: new TextSpan(
          style: defaultStyle,
          children: <TextSpan>[
            TextSpan(text: 'Description: ', style: topicStyle),
            TextSpan(text: a.sentence)
          ]
      )));
    }
    if (a.error != null) {
      txts.add(RichText(text: new TextSpan(
          style: defaultStyle,
          children: <TextSpan>[
            TextSpan(text: 'Error: ', style: topicStyle),
            TextSpan(text: a.error)
          ]
      )));
    }
    return txts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Analyzing the picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: FutureBuilder<PictureAnalysis>(
        future: analyzePicture(image),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.active:
            case ConnectionState.waiting:
              return Center(child: CircularProgressIndicator(
                  valueColor: new AlwaysStoppedAnimation<Color>(Colors.blue)));
            case ConnectionState.done:
              if (snapshot.hasError)
                return Center(child: Text(
                  'Error:\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ));
              // task is complete with some data
              // Convert the analysis data to a RichtText component
              var richTxt = convertToRichText(snapshot.data);
              // If the analysis data contains audio data, play it.
              if (snapshot.data.audio != null) {
                Audio.loadFromByteData(snapshot.data.audio)
                  ..play()
                  ..dispose();
              }
              return ListView.builder(
                  itemCount: richTxt.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: richTxt[index],
                    );
                  });

            case ConnectionState.none:
            default:
              return Text(
                'Press the back button to try again',
                textAlign: TextAlign.center,
              );
          }
        },
      ),
    );
  }
}
