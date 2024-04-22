import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_detector/product/map/viewModel/bloc/map_bloc.dart';

class MapView extends StatelessWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    final MapBloc mapBloc = BlocProvider.of<MapBloc>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Location Service'),
      ),
      body: BlocBuilder<MapBloc, MapState>(
        bloc: mapBloc,
        builder: (context, state) {
          switch (state.mapStateEnum) {
            case MapStateEnum.init:
              mapBloc.add(MapInitial());
              return _view(mapBloc, state);

            case MapStateEnum.update:
              return _view(mapBloc, state);
            case MapStateEnum.stop:
              return _view(mapBloc, state);
            case MapStateEnum.clear:
              return _view(mapBloc, state);
          }
        },
      ),
    );
  }

  Center _view(MapBloc mapBloc, MapState state) {
    return Center(
      child: Column(
        children: <Widget>[
          Expanded(
            child: GoogleMap(
              initialCameraPosition: mapBloc.kGooglePlex,
              onMapCreated: (GoogleMapController controller) {
                mapBloc.mapController.complete(controller);
              },
              markers: mapBloc.markers,
              polylines: mapBloc.polylines,
            ),
          ),
          const SizedBox(height: 20),
          Text('Latitude: ${mapBloc.latitude}'),
          Text('Longitude: ${mapBloc.longitude}'),
          Text('Altitude: ${mapBloc.altitude}'),
          Text('Accuracy: ${mapBloc.accuracy}'),
          Text('Bearing: ${mapBloc.bearing}'),
          Text('Speed: ${mapBloc.speed}'),
          Text('Time: ${mapBloc.time}'),
          ElevatedButton(
            onPressed: () async {
              mapBloc.add(MapUpdate());

              mapBloc.startLocation();
            },
            child: const Text('Start Location Service'),
          ),
          ElevatedButton(
            onPressed: () {
              mapBloc.add(MapStop());

              mapBloc.stop();
            },
            child: const Text('Stop Location Service'),
          ),
          ElevatedButton(
            onPressed: () {
              mapBloc.add(MapClear());

              // Rota çizgisini temizle
              mapBloc.clearRoute();
            },
            child: const Text('clear'),
          ),
        ],
      ),
    );
  }
}
/* @override
void dispose() {
  BackgroundLocation.stopLocationService();
  super.dispose();
} */
