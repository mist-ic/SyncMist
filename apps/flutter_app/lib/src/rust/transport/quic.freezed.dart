// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quic.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TransportError {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) connection,
    required TResult Function(String field0) io,
    required TResult Function(String field0) tls,
    required TResult Function() notConnected,
    required TResult Function(String field0) peerNotFound,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? connection,
    TResult? Function(String field0)? io,
    TResult? Function(String field0)? tls,
    TResult? Function()? notConnected,
    TResult? Function(String field0)? peerNotFound,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? connection,
    TResult Function(String field0)? io,
    TResult Function(String field0)? tls,
    TResult Function()? notConnected,
    TResult Function(String field0)? peerNotFound,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TransportError_Connection value) connection,
    required TResult Function(TransportError_Io value) io,
    required TResult Function(TransportError_Tls value) tls,
    required TResult Function(TransportError_NotConnected value) notConnected,
    required TResult Function(TransportError_PeerNotFound value) peerNotFound,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TransportError_Connection value)? connection,
    TResult? Function(TransportError_Io value)? io,
    TResult? Function(TransportError_Tls value)? tls,
    TResult? Function(TransportError_NotConnected value)? notConnected,
    TResult? Function(TransportError_PeerNotFound value)? peerNotFound,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TransportError_Connection value)? connection,
    TResult Function(TransportError_Io value)? io,
    TResult Function(TransportError_Tls value)? tls,
    TResult Function(TransportError_NotConnected value)? notConnected,
    TResult Function(TransportError_PeerNotFound value)? peerNotFound,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransportErrorCopyWith<$Res> {
  factory $TransportErrorCopyWith(TransportError value, $Res Function(TransportError) then) =
      _$TransportErrorCopyWithImpl<$Res, TransportError>;
}

/// @nodoc
class _$TransportErrorCopyWithImpl<$Res, $Val extends TransportError> implements $TransportErrorCopyWith<$Res> {
  _$TransportErrorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TransportError
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$TransportError_ConnectionImplCopyWith<$Res> {
  factory _$$TransportError_ConnectionImplCopyWith(
          _$TransportError_ConnectionImpl value, $Res Function(_$TransportError_ConnectionImpl) then) =
      __$$TransportError_ConnectionImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$TransportError_ConnectionImplCopyWithImpl<$Res>
    extends _$TransportErrorCopyWithImpl<$Res, _$TransportError_ConnectionImpl>
    implements _$$TransportError_ConnectionImplCopyWith<$Res> {
  __$$TransportError_ConnectionImplCopyWithImpl(
      _$TransportError_ConnectionImpl _value, $Res Function(_$TransportError_ConnectionImpl) _then)
      : super(_value, _then);

  /// Create a copy of TransportError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$TransportError_ConnectionImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$TransportError_ConnectionImpl extends TransportError_Connection {
  const _$TransportError_ConnectionImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'TransportError.connection(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransportError_ConnectionImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of TransportError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransportError_ConnectionImplCopyWith<_$TransportError_ConnectionImpl> get copyWith =>
      __$$TransportError_ConnectionImplCopyWithImpl<_$TransportError_ConnectionImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) connection,
    required TResult Function(String field0) io,
    required TResult Function(String field0) tls,
    required TResult Function() notConnected,
    required TResult Function(String field0) peerNotFound,
  }) {
    return connection(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? connection,
    TResult? Function(String field0)? io,
    TResult? Function(String field0)? tls,
    TResult? Function()? notConnected,
    TResult? Function(String field0)? peerNotFound,
  }) {
    return connection?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? connection,
    TResult Function(String field0)? io,
    TResult Function(String field0)? tls,
    TResult Function()? notConnected,
    TResult Function(String field0)? peerNotFound,
    required TResult orElse(),
  }) {
    if (connection != null) {
      return connection(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TransportError_Connection value) connection,
    required TResult Function(TransportError_Io value) io,
    required TResult Function(TransportError_Tls value) tls,
    required TResult Function(TransportError_NotConnected value) notConnected,
    required TResult Function(TransportError_PeerNotFound value) peerNotFound,
  }) {
    return connection(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TransportError_Connection value)? connection,
    TResult? Function(TransportError_Io value)? io,
    TResult? Function(TransportError_Tls value)? tls,
    TResult? Function(TransportError_NotConnected value)? notConnected,
    TResult? Function(TransportError_PeerNotFound value)? peerNotFound,
  }) {
    return connection?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TransportError_Connection value)? connection,
    TResult Function(TransportError_Io value)? io,
    TResult Function(TransportError_Tls value)? tls,
    TResult Function(TransportError_NotConnected value)? notConnected,
    TResult Function(TransportError_PeerNotFound value)? peerNotFound,
    required TResult orElse(),
  }) {
    if (connection != null) {
      return connection(this);
    }
    return orElse();
  }
}

abstract class TransportError_Connection extends TransportError {
  const factory TransportError_Connection(final String field0) = _$TransportError_ConnectionImpl;
  const TransportError_Connection._() : super._();

  String get field0;

  /// Create a copy of TransportError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransportError_ConnectionImplCopyWith<_$TransportError_ConnectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TransportError_IoImplCopyWith<$Res> {
  factory _$$TransportError_IoImplCopyWith(_$TransportError_IoImpl value, $Res Function(_$TransportError_IoImpl) then) =
      __$$TransportError_IoImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$TransportError_IoImplCopyWithImpl<$Res> extends _$TransportErrorCopyWithImpl<$Res, _$TransportError_IoImpl>
    implements _$$TransportError_IoImplCopyWith<$Res> {
  __$$TransportError_IoImplCopyWithImpl(_$TransportError_IoImpl _value, $Res Function(_$TransportError_IoImpl) _then)
      : super(_value, _then);

  /// Create a copy of TransportError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$TransportError_IoImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$TransportError_IoImpl extends TransportError_Io {
  const _$TransportError_IoImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'TransportError.io(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransportError_IoImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of TransportError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransportError_IoImplCopyWith<_$TransportError_IoImpl> get copyWith =>
      __$$TransportError_IoImplCopyWithImpl<_$TransportError_IoImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) connection,
    required TResult Function(String field0) io,
    required TResult Function(String field0) tls,
    required TResult Function() notConnected,
    required TResult Function(String field0) peerNotFound,
  }) {
    return io(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? connection,
    TResult? Function(String field0)? io,
    TResult? Function(String field0)? tls,
    TResult? Function()? notConnected,
    TResult? Function(String field0)? peerNotFound,
  }) {
    return io?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? connection,
    TResult Function(String field0)? io,
    TResult Function(String field0)? tls,
    TResult Function()? notConnected,
    TResult Function(String field0)? peerNotFound,
    required TResult orElse(),
  }) {
    if (io != null) {
      return io(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TransportError_Connection value) connection,
    required TResult Function(TransportError_Io value) io,
    required TResult Function(TransportError_Tls value) tls,
    required TResult Function(TransportError_NotConnected value) notConnected,
    required TResult Function(TransportError_PeerNotFound value) peerNotFound,
  }) {
    return io(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TransportError_Connection value)? connection,
    TResult? Function(TransportError_Io value)? io,
    TResult? Function(TransportError_Tls value)? tls,
    TResult? Function(TransportError_NotConnected value)? notConnected,
    TResult? Function(TransportError_PeerNotFound value)? peerNotFound,
  }) {
    return io?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TransportError_Connection value)? connection,
    TResult Function(TransportError_Io value)? io,
    TResult Function(TransportError_Tls value)? tls,
    TResult Function(TransportError_NotConnected value)? notConnected,
    TResult Function(TransportError_PeerNotFound value)? peerNotFound,
    required TResult orElse(),
  }) {
    if (io != null) {
      return io(this);
    }
    return orElse();
  }
}

abstract class TransportError_Io extends TransportError {
  const factory TransportError_Io(final String field0) = _$TransportError_IoImpl;
  const TransportError_Io._() : super._();

  String get field0;

  /// Create a copy of TransportError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransportError_IoImplCopyWith<_$TransportError_IoImpl> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TransportError_TlsImplCopyWith<$Res> {
  factory _$$TransportError_TlsImplCopyWith(
          _$TransportError_TlsImpl value, $Res Function(_$TransportError_TlsImpl) then) =
      __$$TransportError_TlsImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$TransportError_TlsImplCopyWithImpl<$Res> extends _$TransportErrorCopyWithImpl<$Res, _$TransportError_TlsImpl>
    implements _$$TransportError_TlsImplCopyWith<$Res> {
  __$$TransportError_TlsImplCopyWithImpl(_$TransportError_TlsImpl _value, $Res Function(_$TransportError_TlsImpl) _then)
      : super(_value, _then);

  /// Create a copy of TransportError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$TransportError_TlsImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$TransportError_TlsImpl extends TransportError_Tls {
  const _$TransportError_TlsImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'TransportError.tls(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransportError_TlsImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of TransportError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransportError_TlsImplCopyWith<_$TransportError_TlsImpl> get copyWith =>
      __$$TransportError_TlsImplCopyWithImpl<_$TransportError_TlsImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) connection,
    required TResult Function(String field0) io,
    required TResult Function(String field0) tls,
    required TResult Function() notConnected,
    required TResult Function(String field0) peerNotFound,
  }) {
    return tls(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? connection,
    TResult? Function(String field0)? io,
    TResult? Function(String field0)? tls,
    TResult? Function()? notConnected,
    TResult? Function(String field0)? peerNotFound,
  }) {
    return tls?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? connection,
    TResult Function(String field0)? io,
    TResult Function(String field0)? tls,
    TResult Function()? notConnected,
    TResult Function(String field0)? peerNotFound,
    required TResult orElse(),
  }) {
    if (tls != null) {
      return tls(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TransportError_Connection value) connection,
    required TResult Function(TransportError_Io value) io,
    required TResult Function(TransportError_Tls value) tls,
    required TResult Function(TransportError_NotConnected value) notConnected,
    required TResult Function(TransportError_PeerNotFound value) peerNotFound,
  }) {
    return tls(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TransportError_Connection value)? connection,
    TResult? Function(TransportError_Io value)? io,
    TResult? Function(TransportError_Tls value)? tls,
    TResult? Function(TransportError_NotConnected value)? notConnected,
    TResult? Function(TransportError_PeerNotFound value)? peerNotFound,
  }) {
    return tls?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TransportError_Connection value)? connection,
    TResult Function(TransportError_Io value)? io,
    TResult Function(TransportError_Tls value)? tls,
    TResult Function(TransportError_NotConnected value)? notConnected,
    TResult Function(TransportError_PeerNotFound value)? peerNotFound,
    required TResult orElse(),
  }) {
    if (tls != null) {
      return tls(this);
    }
    return orElse();
  }
}

abstract class TransportError_Tls extends TransportError {
  const factory TransportError_Tls(final String field0) = _$TransportError_TlsImpl;
  const TransportError_Tls._() : super._();

  String get field0;

  /// Create a copy of TransportError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransportError_TlsImplCopyWith<_$TransportError_TlsImpl> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TransportError_NotConnectedImplCopyWith<$Res> {
  factory _$$TransportError_NotConnectedImplCopyWith(
          _$TransportError_NotConnectedImpl value, $Res Function(_$TransportError_NotConnectedImpl) then) =
      __$$TransportError_NotConnectedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$TransportError_NotConnectedImplCopyWithImpl<$Res>
    extends _$TransportErrorCopyWithImpl<$Res, _$TransportError_NotConnectedImpl>
    implements _$$TransportError_NotConnectedImplCopyWith<$Res> {
  __$$TransportError_NotConnectedImplCopyWithImpl(
      _$TransportError_NotConnectedImpl _value, $Res Function(_$TransportError_NotConnectedImpl) _then)
      : super(_value, _then);

  /// Create a copy of TransportError
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$TransportError_NotConnectedImpl extends TransportError_NotConnected {
  const _$TransportError_NotConnectedImpl() : super._();

  @override
  String toString() {
    return 'TransportError.notConnected()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType && other is _$TransportError_NotConnectedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) connection,
    required TResult Function(String field0) io,
    required TResult Function(String field0) tls,
    required TResult Function() notConnected,
    required TResult Function(String field0) peerNotFound,
  }) {
    return notConnected();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? connection,
    TResult? Function(String field0)? io,
    TResult? Function(String field0)? tls,
    TResult? Function()? notConnected,
    TResult? Function(String field0)? peerNotFound,
  }) {
    return notConnected?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? connection,
    TResult Function(String field0)? io,
    TResult Function(String field0)? tls,
    TResult Function()? notConnected,
    TResult Function(String field0)? peerNotFound,
    required TResult orElse(),
  }) {
    if (notConnected != null) {
      return notConnected();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TransportError_Connection value) connection,
    required TResult Function(TransportError_Io value) io,
    required TResult Function(TransportError_Tls value) tls,
    required TResult Function(TransportError_NotConnected value) notConnected,
    required TResult Function(TransportError_PeerNotFound value) peerNotFound,
  }) {
    return notConnected(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TransportError_Connection value)? connection,
    TResult? Function(TransportError_Io value)? io,
    TResult? Function(TransportError_Tls value)? tls,
    TResult? Function(TransportError_NotConnected value)? notConnected,
    TResult? Function(TransportError_PeerNotFound value)? peerNotFound,
  }) {
    return notConnected?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TransportError_Connection value)? connection,
    TResult Function(TransportError_Io value)? io,
    TResult Function(TransportError_Tls value)? tls,
    TResult Function(TransportError_NotConnected value)? notConnected,
    TResult Function(TransportError_PeerNotFound value)? peerNotFound,
    required TResult orElse(),
  }) {
    if (notConnected != null) {
      return notConnected(this);
    }
    return orElse();
  }
}

abstract class TransportError_NotConnected extends TransportError {
  const factory TransportError_NotConnected() = _$TransportError_NotConnectedImpl;
  const TransportError_NotConnected._() : super._();
}

/// @nodoc
abstract class _$$TransportError_PeerNotFoundImplCopyWith<$Res> {
  factory _$$TransportError_PeerNotFoundImplCopyWith(
          _$TransportError_PeerNotFoundImpl value, $Res Function(_$TransportError_PeerNotFoundImpl) then) =
      __$$TransportError_PeerNotFoundImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$TransportError_PeerNotFoundImplCopyWithImpl<$Res>
    extends _$TransportErrorCopyWithImpl<$Res, _$TransportError_PeerNotFoundImpl>
    implements _$$TransportError_PeerNotFoundImplCopyWith<$Res> {
  __$$TransportError_PeerNotFoundImplCopyWithImpl(
      _$TransportError_PeerNotFoundImpl _value, $Res Function(_$TransportError_PeerNotFoundImpl) _then)
      : super(_value, _then);

  /// Create a copy of TransportError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$TransportError_PeerNotFoundImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$TransportError_PeerNotFoundImpl extends TransportError_PeerNotFound {
  const _$TransportError_PeerNotFoundImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'TransportError.peerNotFound(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransportError_PeerNotFoundImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of TransportError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransportError_PeerNotFoundImplCopyWith<_$TransportError_PeerNotFoundImpl> get copyWith =>
      __$$TransportError_PeerNotFoundImplCopyWithImpl<_$TransportError_PeerNotFoundImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) connection,
    required TResult Function(String field0) io,
    required TResult Function(String field0) tls,
    required TResult Function() notConnected,
    required TResult Function(String field0) peerNotFound,
  }) {
    return peerNotFound(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? connection,
    TResult? Function(String field0)? io,
    TResult? Function(String field0)? tls,
    TResult? Function()? notConnected,
    TResult? Function(String field0)? peerNotFound,
  }) {
    return peerNotFound?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? connection,
    TResult Function(String field0)? io,
    TResult Function(String field0)? tls,
    TResult Function()? notConnected,
    TResult Function(String field0)? peerNotFound,
    required TResult orElse(),
  }) {
    if (peerNotFound != null) {
      return peerNotFound(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TransportError_Connection value) connection,
    required TResult Function(TransportError_Io value) io,
    required TResult Function(TransportError_Tls value) tls,
    required TResult Function(TransportError_NotConnected value) notConnected,
    required TResult Function(TransportError_PeerNotFound value) peerNotFound,
  }) {
    return peerNotFound(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TransportError_Connection value)? connection,
    TResult? Function(TransportError_Io value)? io,
    TResult? Function(TransportError_Tls value)? tls,
    TResult? Function(TransportError_NotConnected value)? notConnected,
    TResult? Function(TransportError_PeerNotFound value)? peerNotFound,
  }) {
    return peerNotFound?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TransportError_Connection value)? connection,
    TResult Function(TransportError_Io value)? io,
    TResult Function(TransportError_Tls value)? tls,
    TResult Function(TransportError_NotConnected value)? notConnected,
    TResult Function(TransportError_PeerNotFound value)? peerNotFound,
    required TResult orElse(),
  }) {
    if (peerNotFound != null) {
      return peerNotFound(this);
    }
    return orElse();
  }
}

abstract class TransportError_PeerNotFound extends TransportError {
  const factory TransportError_PeerNotFound(final String field0) = _$TransportError_PeerNotFoundImpl;
  const TransportError_PeerNotFound._() : super._();

  String get field0;

  /// Create a copy of TransportError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransportError_PeerNotFoundImplCopyWith<_$TransportError_PeerNotFoundImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
