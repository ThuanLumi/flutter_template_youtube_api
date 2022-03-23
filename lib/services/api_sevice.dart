import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_template_youtube_api/models/channel_model.dart';
import 'package:flutter_template_youtube_api/models/video_model.dart';
import 'package:flutter_template_youtube_api/utilities/key.dart';

class APIService {
  APIService._instance();

  static final APIService instance = APIService._instance();

  final String _baseUrl = 'www.googleapis.com';

  String _nextPageToken = '';

  Future<Channel> fetchChannel({required String channelId}) async {
    Map<String, String> parameters = {
      'part': 'snippet, contentDetails, statistics',
      'id': channelId,
      'key': API_KEY,
    };

    Uri uri = Uri.https(_baseUrl, '/youtube/v3/channels', parameters);
    // print(uri);

    Map<String, String> headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
    };
    // print(headers);

    //Get channel
    var response = await http.get(uri, headers: headers);

    // Map data1 = jsonDecode(response.body);
    // print(data1);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body)['items'][0];
      // print(data);
      Channel channel = Channel.fromMap(data);

      //Fetch first batch of videos from uploads playlist
      channel.videos =
          await fetchVideosFromPlaylist(playlistId: channel.uploadPlaylistId);
      return channel;
    } else {
      throw json.decode(response.body)['error']['message'];
    }
  }

  Future<List<Video>> fetchVideosFromPlaylist(
      {required String playlistId}) async {
    Map<String, String> parameters = {
      'part': 'snippet',
      'playlistId': playlistId,
      'maxResults': '8',
      'pageToken': _nextPageToken,
      'key': API_KEY,
    };

    Uri uri = Uri.https(
      _baseUrl,
      '/youtube/v3/playlistItems',
      parameters,
    );
    // print(uri);

    Map<String, String> headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
    };

    // Get Playlist Videos
    var response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      // print(data);

      _nextPageToken = data['nextPageToken'] ?? '';
      List<dynamic> videosJson = data['items'];

      // Fetch first eight videos from uploads playlist
      List<Video> videos = [];
      for (var json in videosJson) {
        videos.add(
          Video.fromMap(json['snippet']),
        );
      }
      return videos;
    } else {
      throw json.decode(response.body)['error']['message'];
    }
  }
}
