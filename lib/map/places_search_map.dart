/*
 * Copyright (c) 2019 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
import 'dart:async';
import 'dart:convert';
import 'package:sign_in_flutter/map/data/location.dart';
import 'package:geolocator/geolocator.dart';

import 'data/error.dart';
import 'data/place_response.dart';
import 'data/result.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';


class PlacesSearchMapSample extends StatefulWidget {
  final String keyword;
  PlacesSearchMapSample(this.keyword);

  @override
  State<PlacesSearchMapSample> createState() {
    return _PlacesSearchMapSample();
  }
}

class _PlacesSearchMapSample extends State<PlacesSearchMapSample> {
  static const String _API_KEY = 'AIzaSyCQJLfyg7QvAUdOMvqhGop8-EQROX8QH3g';

  static LatLng _initialPosition;
  static  LatLng _lastMapPosition = _initialPosition;

  static double latitude = 40.7484405;
  static double longitude = -73.9878531;
  static const String baseUrl =
      "https://maps.googleapis.com/maps/api/place/nearbysearch/json";

  List<Marker> markers = <Marker>[];
  Error error;
  List<Result> places;
  bool searching = true;
  String keyword;

  Completer<GoogleMapController> _controller = Completer();


  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }
  void _getUserLocation() async {
   Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemark = await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);
    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
      print('${placemark[0].name}');
    });
  }


  void _setStyle(GoogleMapController controller) async {
    String value = await DefaultAssetBundle.of(context).loadString('assets/maps_style.json');
    await controller.setMapStyle(value);
  }

  void searchNearby(double latitude, double longitude) async {
    Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemark = await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);
    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
      print('${placemark[0].name}');
    });
    setState(() {
      markers.clear();
    });
   var LatpPosition = position.latitude;
   var LongPosition = position.longitude;
    String url =
        '$baseUrl?key=$_API_KEY&location=$LatpPosition,$LongPosition&radius=10000&keyword=${widget.keyword}';
    print(url);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _handleResponse(data);
    } else {
      throw Exception('An error occurred getting places nearby');
    }

    // make sure to hide searching
    setState(() {
      searching = false;
    });
  }

  void _handleResponse(data){
    // bad api key or otherwise
      if (data['status'] == "REQUEST_DENIED") {
        setState(() {
          error = Error.fromJson(data);
        });
        // success
      } else if (data['status'] == "OK") {
        setState(() {
          places = PlaceResponse.parseResults(data['results']);
          for (int i = 0; i < places.length; i++) {
            markers.add(
              Marker(
                markerId: MarkerId(places[i].placeId),
                position: LatLng(places[i].geometry.location.lat,
                    places[i].geometry.location.long),
                infoWindow: InfoWindow(
                    title: places[i].name, snippet: places[i].vicinity),
                onTap: () {},
              ),
            );
          }
        });
      } else {
        print(data);
      }
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _initialPosition == null ? Container(child: Center(child:Text('loading map..', style: TextStyle(fontFamily: 'Avenir-Medium', color: Colors.grey[400]),),),) : Container(
    child: Stack(children: <Widget>[
    GoogleMap(
        mapType: MapType.normal,
        myLocationEnabled: true,
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 12.4746,
        ),
        onMapCreated: (GoogleMapController controller) {
          _setStyle(controller);
          _controller.complete(controller);
        },
        markers: Set<Marker>.of(markers),
      )])),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          searchNearby(latitude, longitude);
        },
        label: Text('Places Nearby'),
        icon: Icon(Icons.place),
      ),
    );

  }
}

