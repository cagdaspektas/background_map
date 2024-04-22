import 'dart:async';
import 'dart:math';

import 'package:background_location/background_location.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  bool isStop = false;
  String latitude = 'waiting...';
  String longitude = 'waiting...';
  String altitude = 'waiting...';
  String accuracy = 'waiting...';
  String bearing = 'waiting...';
  String speed = 'waiting...';
  String time = 'waiting...';
  bool? serviceRunning;
  Set<Marker> markers = {}; // Markerları tutacak set
  Set<Polyline> polylines = {}; // Rota çizgileri tutacak set
  List<Placemark> placemarks = [];

  final Completer<GoogleMapController> mapController = Completer<GoogleMapController>();

  CameraPosition kGooglePlex = const CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  LatLng? lastMarkerPosition;
  List<LatLng> routeCoordinates = []; // Rota koordinatlarını tutacak liste

  MapBloc() : super(MapState()) {
    on<MapInitial>((event, emit) => startLocation());
    on<MapUpdate>((event, emit) => startLocation());
    on<MapClear>((event, emit) => clearRoute());
    on<MapStop>((event, emit) => stop());
  }

  void updateMarker(LatLng position) {
    markers.add(Marker(
      markerId: const MarkerId("current_location"),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
    ));
    emit(state.copyWith(mapStateEnum: MapStateEnum.update, markers: markers));
  }

  void updateRoute() {
    if (routeCoordinates.length >= 2) {
      polylines.clear();
      polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: routeCoordinates,
        color: Colors.blue,
        width: 5,
      ));
    }
    emit(state.copyWith(mapStateEnum: MapStateEnum.update, markers: markers, polylines: polylines));
  }

  void updateTexts(location) {
    latitude = location.latitude.toString();
    longitude = location.longitude.toString();
    accuracy = location.accuracy.toString();
    altitude = location.altitude.toString();
    bearing = location.bearing.toString();
    speed = location.speed.toString();
    time = DateTime.fromMillisecondsSinceEpoch(
      location.time!.toInt(),
    ).toString();
  }

  Future<void> startLocation() async {
    await BackgroundLocation.startLocationService(
      distanceFilter: 20,
    );
    isStop = false;

    if (isStop) {
      return;
    }
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    lastMarkerPosition = LatLng(position.latitude, position.longitude);
    getLocationUpdates();
  }

  Future<void> getAdress(location) async {
    var data = await placemarkFromCoordinates(location.latitude, location.longitude);

    placemarks.add(data[0]);
    emit(state.copyWith(mapStateEnum: MapStateEnum.update, markers: markers, polylines: polylines));
  }

//marker,route ve koordinatları güncelleyen kodun fonksiyonu
  void getLocationUpdates() {
    BackgroundLocation.getLocationUpdates((location) async {
      if (isStop) {
        return;
      }
      updateTexts(location);

      final GoogleMapController controller = await mapController.future;
      await controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(
          location.latitude ?? 0,
          location.longitude ?? 0,
        ),
        bearing: 0,
        zoom: 15,
      )));

      updateMarker(LatLng(location.latitude!, location.longitude!));
      // Rota koordinatlarına ekle
      routeCoordinates.add(LatLng(location.latitude!, location.longitude!));
      updateRoute(); // Rota çizgisini güncelle
      getAdress(location);
      // Her 100 metrede bir marker oluştur
      if (markers.isEmpty ||
          distanceBetweenMarkers(
                lastMarkerPosition?.latitude ?? 0,
                lastMarkerPosition?.longitude ?? 0,
                location.latitude ?? 0,
                location.longitude ?? 0,
              ) >=
              0.1) {
        // 100 metre için 0.1 değeri kullanıldı

        for (final place in placemarks) {
          final marker = Marker(
            markerId: MarkerId(location.latitude.toString()),
            position: LatLng(location.latitude!, location.longitude!),
            infoWindow: InfoWindow(
              title: place.name,
              snippet: place.street,
            ),
          );
          markers.add(marker);
        }
        /*  markers.add(
          Marker(
                  markerId: MarkerId(location.time.toString()),
                  position: LatLng(
                    location.latitude ?? 0,
                    location.longitude ?? 0,
                  ),
                  onTap: () {
                    getAdress(location);
                  },
                  infoWindow: InfoWindow(
                      title: placemarks[0].street ?? location.latitude.toString(),
                      snippet: placemarks[0].name ?? location.longitude.toString()),
                  icon: BitmapDescriptor.defaultMarker,
                )
       ); */

        lastMarkerPosition = LatLng(
          location.latitude ?? 0,
          location.longitude ?? 0,
        );
      }
    });
  }

  void stop() {
    BackgroundLocation.stopLocationService();
    isStop = true;
    emit(state.copyWith(mapStateEnum: MapStateEnum.stop, markers: markers, polylines: polylines));
  }

  // Rota çizgisini temizle
  Future<void> clearRoute() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    markers.clear();
    routeCoordinates.clear();
    polylines.clear();
    placemarks.clear();

    lastMarkerPosition = LatLng(position.latitude, position.longitude);

    markers.add(Marker(
      markerId: const MarkerId("current_location"),
      position: lastMarkerPosition ?? const LatLng(0, 0),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
    ));
    emit(state.copyWith(mapStateEnum: MapStateEnum.clear, markers: markers, polylines: polylines));
  }

  // İki koordinat arasındaki mesafeyi hesaplar
  double distanceBetweenMarkers(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 + c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}
