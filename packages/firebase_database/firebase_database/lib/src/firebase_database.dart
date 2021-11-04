// ignore_for_file: require_trailing_commas
// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_database;

/// The entry point for accessing a Firebase Database. You can get an instance
/// by calling `FirebaseDatabase.instance` or `FirebaseDatabase.instanceFor()`.
class FirebaseDatabase extends FirebasePluginPlatform {
  FirebaseDatabase._({required this.app, this.databaseURL})
      : super(app.name, 'plugins.flutter.io/firebase_database');

  /// The [FirebaseApp] for this current [FirebaseDatabase] instance.
  FirebaseApp app;

  /// A custom Database URL for this instance.
  String? databaseURL;

  static final Map<String, FirebaseDatabase> _cachedInstances = {};

  /// Returns an instance using the default [FirebaseApp].
  static FirebaseDatabase get instance {
    return FirebaseDatabase.instanceFor(
      app: Firebase.app(),
    );
  }

  /// Returns an instance using a specified [FirebaseApp].
  static FirebaseDatabase instanceFor(
      {required FirebaseApp app, String? databaseURL}) {
    if (_cachedInstances.containsKey(app.name)) {
      return _cachedInstances[app.name]!;
    }

    FirebaseDatabase newInstance =
        FirebaseDatabase._(app: app, databaseURL: databaseURL);
    _cachedInstances[app.name] = newInstance;

    return newInstance;
  }

  /// Gets an instance of [FirebaseDatabase].
  ///
  /// If [app] is specified, its options should include a [databaseURL].
  DatabasePlatform? _delegatePackingProperty;

  DatabasePlatform get _delegate {
    _delegatePackingProperty ??= DatabasePlatform.instance;
    return _delegatePackingProperty!;
  }

  @visibleForTesting
  static MethodChannel get channel => MethodChannelDatabase.channel;

  /// Returns a [DatabaseReference] representing the location in the Database
  /// corresponding to the provided path.
  /// If no path is provided, the Reference will point to the root of the Database.
  DatabaseReference ref([String? path]) {
    return DatabaseReference._(_delegate.ref(path));
  }

  /// Attempts to sets the database persistence to [enabled].
  ///
  /// This property must be set before calling methods on database references
  /// and only needs to be called once per application. The returned [Future]
  /// will complete with `true` if the operation was successful or `false` if
  /// the persistence could not be set (because database references have
  /// already been created).
  ///
  /// The Firebase Database client will cache synchronized data and keep track
  /// of all writes you’ve initiated while your application is running. It
  /// seamlessly handles intermittent network connections and re-sends write
  /// operations when the network connection is restored.
  ///
  /// However by default your write operations and cached data are only stored
  /// in-memory and will be lost when your app restarts. By setting [enabled]
  /// to `true`, the data will be persisted to on-device (disk) storage and will
  /// thus be available again when the app is restarted (even when there is no
  /// network connectivity at that time).
  Future<void> setPersistenceEnabled(bool enabled) async {
    return _delegate.setPersistenceEnabled(enabled);
  }

  /// Attempts to set the size of the persistence cache.
  ///
  /// By default the Firebase Database client will use up to 10MB of disk space
  /// to cache data. If the cache grows beyond this size, the client will start
  /// removing data that hasn’t been recently used. If you find that your
  /// application caches too little or too much data, call this method to change
  /// the cache size.
  ///
  /// This property must be set before calling methods on database references
  /// and only needs to be called once per application. The returned [Future]
  /// will complete with `true` if the operation was successful or `false` if
  /// the value could not be set (because database references have already been
  /// created).
  ///
  /// Note that the specified cache size is only an approximation and the size
  /// on disk may temporarily exceed it at times. Cache sizes smaller than 1 MB
  /// or greater than 100 MB are not supported.
  Future<void> setPersistenceCacheSizeBytes(int cacheSize) async {
    return _delegate.setPersistenceCacheSizeBytes(cacheSize);
  }

  /// Enables verbose diagnostic logging for debugging your application.
  /// This must be called before any other usage of FirebaseDatabase instance.
  /// By default, diagnostic logging is disabled.
  Future<void> setLoggingEnabled(bool enabled) {
    return _delegate.setLoggingEnabled(enabled);
  }

  /// Resumes our connection to the Firebase Database backend after a previous
  /// [goOffline] call.
  Future<void> goOnline() {
    return _delegate.goOnline();
  }

  /// Shuts down our connection to the Firebase Database backend until
  /// [goOnline] is called.
  Future<void> goOffline() {
    return _delegate.goOffline();
  }

  /// The Firebase Database client automatically queues writes and sends them to
  /// the server at the earliest opportunity, depending on network connectivity.
  /// In some cases (e.g. offline usage) there may be a large number of writes
  /// waiting to be sent. Calling this method will purge all outstanding writes
  /// so they are abandoned.
  ///
  /// All writes will be purged, including transactions and onDisconnect writes.
  /// The writes will be rolled back locally, perhaps triggering events for
  /// affected event listeners, and the client will not (re-)send them to the
  /// Firebase Database backend.
  Future<void> purgeOutstandingWrites() {
    return _delegate.purgeOutstandingWrites();
  }
}
