part of 'map_bloc.dart';

@immutable
abstract class MapEvent {}

class MapInitial extends MapEvent {}

class MapUpdate extends MapEvent {}

class MapClear extends MapEvent {}

class MapStop extends MapEvent {}
