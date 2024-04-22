part of 'map_bloc.dart';

enum MapStateEnum { init, update, stop, clear }

class MapState {
  MapStateEnum mapStateEnum;
  Set<Marker>? markers;
  Set<Polyline>? polylines;

  MapState({this.mapStateEnum = MapStateEnum.init, this.markers, this.polylines});

  MapState copyWith({
    MapStateEnum? mapStateEnum,
    Set<Marker>? markers,
    Set<Polyline>? polylines,
  }) {
    return MapState(
      mapStateEnum: mapStateEnum ?? this.mapStateEnum,
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
    );
  }
}
