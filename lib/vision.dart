import 'dart:async';
import 'dart:convert';
import 'dart:io';


import 'package:flutter/material.dart';
import 'package:googleapis/vision/v1.dart' hide Color;

import 'credentials.dart';

Future<PictureAnalysis> analyzePicture(File path) async {
  PictureAnalysis analysis = new PictureAnalysis();
  try {
    var minimumScore = 0.5;
    var minimumLikelihood = ['POSSIBLE', 'LIKELY', 'VERY_LIKELY'];
    var client = CredentialsProvider().client;
    var vision = VisionApi(await client);
    var imageBytes = await path.readAsBytes();
    String base64Image = base64Encode(imageBytes);
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
    if (response != null && response.responses != null) {
      for (final a in response.responses) {
        if (a.productSearchResults != null && a.productSearchResults.results != null) {
          List<String> products = new List();
          for (final p in a.productSearchResults.results) if (p.product.displayName != null) products.add(p.product.displayName);
          if (products.isNotEmpty) analysis.setProducts(products.join(", "));
        }
        if (a.webDetection != null && a.webDetection.bestGuessLabels != null) {
          List<String> webLabels = new List();
          for (final l in a.webDetection.bestGuessLabels) webLabels.add(l.label);
          if (webLabels.isNotEmpty) analysis.setWebLabels(webLabels.join(", "));
        }
        if (a.localizedObjectAnnotations != null) {
          List<String> loas = new List();
          for (final o in a.localizedObjectAnnotations) {
            if (o != null && (o.score == null || o.score >= minimumScore)) loas.add(o.name);
          }
          if (loas.isNotEmpty) analysis.setObjects(loas.join(", "));
        }
        if (a.logoAnnotations != null) {
          List<String> logos = new List();
          for (final l in a.logoAnnotations) {
            if (l != null && (l.score == null || l.score >= minimumScore)) logos.add(l.description);
          }
          if (logos.isNotEmpty) analysis.setLogos(logos.join(", "));
        }
        if (a.labelAnnotations != null) {
          List<String> labels = new List();
          for (final l in a.labelAnnotations) {
            if (l != null && (l.score == null || l.score >= minimumScore)) labels.add(l.description);
          }
          if (labels.isNotEmpty) analysis.setLabels(labels.join(", "));
        }
        /*if (a.textAnnotations != null) {
          List<String> tas = new List();
          for (final t in a.textAnnotations) {
            if (t != null && (t.score == null || t.score >= minimumScore)) tas.add(t.description.replaceAll("\n", " "));
          }
          analysis.setText(tas.join(", "));
        }*/
        if (a.fullTextAnnotation != null && a.fullTextAnnotation.text != null) analysis.setText(a.fullTextAnnotation.text.replaceAll("\n", " "));
        if (a.faceAnnotations != null) {
          List<String> faces = new List();
          for (final f in a.faceAnnotations) {
            if (f != null && (f.detectionConfidence == null || f.detectionConfidence >= minimumScore)) {
              List<String> emotions = new List();
              if (minimumLikelihood.contains(f.angerLikelihood)) emotions.add('angry');
              if (minimumLikelihood.contains(f.blurredLikelihood)) emotions.add('blurred');
              if (minimumLikelihood.contains(f.joyLikelihood)) emotions.add('happy');
              if (minimumLikelihood.contains(f.surpriseLikelihood)) emotions.add('surprised');
              if (minimumLikelihood.contains(f.sorrowLikelihood)) emotions.add('sad');
              if (minimumLikelihood.contains(f.underExposedLikelihood)) emotions.add('underexposed');
              var faceInfo = emotions.join(" & ") + " face";
              if (minimumLikelihood.contains(f.headwearLikelihood)) faceInfo += ' wearing headgear';
              faces.add(faceInfo);
            }
          }
          if (faces.isNotEmpty) analysis.setFaces(faces.join(", "));
        }
        if (a.landmarkAnnotations != null) {
          List<String> landmarks = new List();
          for (final l in a.landmarkAnnotations) {
            if (l != null && (l.score == null || l.score >= minimumScore)) landmarks.add(l.description);
          }
          if (landmarks.isNotEmpty) analysis.setLandmarks(landmarks.join(", "));
        }
      }
    }
  } catch (e) {
    print(e);
  }
  return analysis;
}

class PictureAnalysis {
  String prod;
  String wLabels;
  String objs;
  String lgs;
  String lbls;
  String txt;
  String fcs;
  String lndMarks;

  void setProducts(String products) {
    this.prod = products;
  }

  String get products {
    return this.prod;
  }

  void setWebLabels(String webLabels) {
    this.wLabels = webLabels;
  }

  String get webLabels {
    return this.wLabels;
  }

  void setObjects(String objects) {
    this.objs = objects;
  }

  String get objects {
    return this.objs;
  }

  void setLogos(String logos) {
    this.lgs = logos;
  }

  String get logos {
    return this.lgs;
  }

  void setLabels(String labels) {
    this.lbls = labels;
  }

  String get labels {
    return this.lbls;
  }

  void setText(String text) {
    this.txt = text;
  }

  String get text {
    return this.txt;
  }

  void setFaces(String faces) {
    this.fcs = faces;
  }

  String get faces {
    return this.fcs;
  }

  void setLandmarks(String landmarks) {
    this.lndMarks = landmarks;
  }

  String get landmarks {
    return this.lndMarks;
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
              ///task is complete with some data
              var richTxt = convertToRichText(snapshot.data);
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
