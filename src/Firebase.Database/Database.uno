using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse;
using Fuse.Triggers;
using Fuse.Controls;
using Fuse.Controls.Native;
using Fuse.Controls.Native.Android;
using Uno.Threading;

namespace Firebase.Database
{
    [ForeignInclude(Language.Java,
        "com.google.firebase.database.DatabaseReference",
        "com.google.firebase.database.DatabaseError",
        "com.google.firebase.database.DatabaseReference",
        "com.google.firebase.database.DataSnapshot",
        "com.google.firebase.database.FirebaseDatabase",
        "com.google.firebase.database.ValueEventListener",
        "com.google.firebase.database.ChildEventListener",
        "com.google.firebase.database.Query",
        "com.google.firebase.database.ServerValue",
        "android.util.Log",
        "org.json.JSONObject",
        "java.util.Map",
        "java.util.HashMap")]
    [Require("Cocoapods.Podfile.Target", "pod 'Firebase/Database'")]
    [Require("Gradle.Dependency.Compile", "com.google.firebase:firebase-database:11.8.0")]
    [extern(iOS) Require("Source.Import","FirebaseDatabase/FIRDatabase.h")]
    extern(mobile)
    static class DatabaseService
    {
        static bool _initialized;
        extern(android) static Java.Object _handle;
        extern(ios) public static ObjC.Object _handle;

        public static void Init()
        {
            if (!_initialized)
            {
                Firebase.Core.Init();
                if defined(android) AndroidInit();
                if defined(ios) iOSInit();
                _initialized = true;
            }
        }

        [Foreign(Language.ObjC)]
        extern(iOS)
        public static void iOSInit()
        @{
            // XXX: Should be a compile-time option
            [FIRDatabase database].persistenceEnabled = YES;
            @{_handle:Set([[FIRDatabase database] reference])};
        @}

        [Foreign(Language.Java)]
        extern(android)
        public static void AndroidInit()
        @{
            @{_handle:Set(FirebaseDatabase.getInstance().getReference())};
        @}

        [Foreign(Language.ObjC)]
        extern(iOS)
        public static void ListenForChildAdded(string path, int count, Action<string,string> f)
        @{
            NSUInteger end = (NSUInteger) count;
            FIRDatabaseReference *ref = @{DatabaseService._handle:Get()};
            [[[ref child:path] queryLimitedToLast:count] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
              if([snapshot.value isEqual:[NSNull null]]) {
                f(path, nil);
                return;
              }

              NSError *error;
              NSData *jsonData = [NSJSONSerialization dataWithJSONObject:snapshot.value
                                                            options:(NSJSONWritingOptions)0
                                                              error:&error];
              NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
              f(path, json);
            } withCancelBlock:^(NSError * _Nonnull error) {
                NSString *erstr = [NSString stringWithFormat:@"Firebase Read Error: %@", error.localizedDescription];
                f(path, erstr);
            }];
        @}

        [Foreign(Language.Java)]
        extern(Android)
        public static void ListenForChildAdded(string path, int count, Action<string,string> f)
        @{
            ChildEventListener childEventListener = new ChildEventListener() {
                @Override
                public void onChildAdded(DataSnapshot dataSnapshot, String previousChildName) {
                    if (dataSnapshot.getValue() == null) {
                        return;
                    }
                    JSONObject json = new JSONObject((Map)dataSnapshot.getValue());
                    f.run(path,json.toString());
                }

                @Override
                public void onChildChanged(DataSnapshot dataSnapshot, String s) {

                }

                @Override
                public void onChildRemoved(DataSnapshot dataSnapshot) {

                }

                @Override
                public void onChildMoved(DataSnapshot dataSnapshot, String s) {

                }

                @Override
                public void onCancelled(DatabaseError databaseError) {
                    f.run(path,databaseError.toString());
                }
            };
            DatabaseReference ref = (DatabaseReference)@{DatabaseService._handle:Get()};
            Query lastAddedQuery = ref.child(path).limitToLast(count);
            lastAddedQuery.addChildEventListener(childEventListener);
        @}

        [Foreign(Language.ObjC)]
        extern(iOS)
        public static void ReadByQueryEndingAtValue(string path, string keyName, string lastValue, int count, Action<string,string> f)
        @{
            long longLastValue = [lastValue longLongValue];
            NSNumber * lastChildValue = [NSNumber numberWithLong:longLastValue];
            FIRDatabaseReference *ref = @{DatabaseService._handle:Get()};
            [[[[[ref child:path] queryOrderedByChild:keyName] queryEndingAtValue:lastChildValue] queryLimitedToLast:count] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                if([snapshot.value isEqual:[NSNull null]]) {
                    f(path, nil);
                    return;
                }

                NSError *error;
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:snapshot.value
                                                                   options:(NSJSONWritingOptions)0
                                                                     error:&error];
                NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                f(path, json);
            } withCancelBlock:^(NSError * _Nonnull error) {
                NSString *erstr = [NSString stringWithFormat:@"Firebase Read Error: %@", error.localizedDescription];
                f(path, erstr);
            }];
        @}

        [Foreign(Language.Java)]
        extern(Android)
        public static void ReadByQueryEndingAtValue(string path, string keyName, string lastValue, int count, Action<string,string> f)
        @{
            ValueEventListener dataListener = new ValueEventListener() {
                @Override
                public void onDataChange(DataSnapshot dataSnapshot)
                {
                    if (dataSnapshot.getValue() == null) {
                        return;
                    }
                    JSONObject json = new JSONObject((Map)dataSnapshot.getValue());
                    f.run(path,json.toString());
                }

                @Override
                public void onCancelled(DatabaseError databaseError)
                {
                    f.run(path,databaseError.toString());
                }
            };

            long longLastValue = Long.parseLong(lastValue);
            DatabaseReference ref = (DatabaseReference)@{DatabaseService._handle:Get()};
            Query readQuery = ref.child(path).orderByChild(keyName).endAt(longLastValue).limitToLast(count);
            readQuery.addValueEventListener(dataListener);
        @}

        [Foreign(Language.ObjC)]
        extern(iOS)
        public static void ListenForChildChanged(string path, Action<string,string> f)
        @{
            FIRDatabaseReference *ref = @{DatabaseService._handle:Get()};
            [[ref child:path] observeEventType:FIRDataEventTypeChildChanged withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
              if([snapshot.value isEqual:[NSNull null]]) {
                f(path, nil);
                return;
              }

              NSError *error;
              NSData *jsonData = [NSJSONSerialization dataWithJSONObject:snapshot.value
                                                            options:(NSJSONWritingOptions)0
                                                              error:&error];
              NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
              f(path, json);
            } withCancelBlock:^(NSError * _Nonnull error) {
                NSString *erstr = [NSString stringWithFormat:@"Firebase Read Error: %@", error.localizedDescription];
                f(path, erstr);
            }];
        @}

        [Foreign(Language.Java)]
        extern(Android)
        public static void ListenForChildChanged(string path, Action<string,string> f)
        @{
            ChildEventListener childEventListener = new ChildEventListener() {
                @Override
                public void onChildAdded(DataSnapshot dataSnapshot, String previousChildName) {

                }

                @Override
                public void onChildChanged(DataSnapshot dataSnapshot, String s) {
                    if (dataSnapshot.getValue() == null) {
                        return;
                    }
                    JSONObject json = new JSONObject((Map)dataSnapshot.getValue());
                    f.run(path,json.toString());
                }

                @Override
                public void onChildRemoved(DataSnapshot dataSnapshot) {

                }

                @Override
                public void onChildMoved(DataSnapshot dataSnapshot, String s) {

                }

                @Override
                public void onCancelled(DatabaseError databaseError) {
                    f.run(path,databaseError.toString());
                }
            };
            DatabaseReference ref = (DatabaseReference)@{DatabaseService._handle:Get()};
            ref.child(path).addChildEventListener(childEventListener);
        @}

        [Foreign(Language.ObjC)]
        extern(iOS)
        public static void ListenForChildRemoved(string path, Action<string,string> f)
        @{
            FIRDatabaseReference *ref = @{DatabaseService._handle:Get()};
            [[ref child:path] observeEventType:FIRDataEventTypeChildRemoved withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
              if([snapshot.value isEqual:[NSNull null]]) {
                f(path, nil);
                return;
              }

              NSError *error;
              NSData *jsonData = [NSJSONSerialization dataWithJSONObject:snapshot.value
                                                            options:(NSJSONWritingOptions)0
                                                              error:&error];
              NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
              f(path, json);
            } withCancelBlock:^(NSError * _Nonnull error) {
                NSString *erstr = [NSString stringWithFormat:@"Firebase Read Error: %@", error.localizedDescription];
                f(path, erstr);
            }];
        @}

        [Foreign(Language.Java)]
        extern(Android)
        public static void ListenForChildRemoved(string path, Action<string,string> f)
        @{
            ChildEventListener childEventListener = new ChildEventListener() {
                @Override
                public void onChildAdded(DataSnapshot dataSnapshot, String previousChildName) {

                }

                @Override
                public void onChildChanged(DataSnapshot dataSnapshot, String s) {

                }

                @Override
                public void onChildRemoved(DataSnapshot dataSnapshot) {
                    if (dataSnapshot.getValue() == null) {
                        return;
                    }
                    JSONObject json = new JSONObject((Map)dataSnapshot.getValue());
                    f.run(path,json.toString());
                }

                @Override
                public void onChildMoved(DataSnapshot dataSnapshot, String s) {

                }

                @Override
                public void onCancelled(DatabaseError databaseError) {
                    f.run(path,databaseError.toString());
                }
            };
            DatabaseReference ref = (DatabaseReference)@{DatabaseService._handle:Get()};
            ref.child(path).addChildEventListener(childEventListener);
        @}

        [Foreign(Language.ObjC)]
        extern(iOS)
        public static void ListenForChildMoved(string path, Action<string,string> f)
        @{
            FIRDatabaseReference *ref = @{DatabaseService._handle:Get()};
            [[ref child:path] observeEventType:FIRDataEventTypeChildMoved withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
              if([snapshot.value isEqual:[NSNull null]]) {
                f(path, nil);
                return;
              }

              NSError *error;
              NSData *jsonData = [NSJSONSerialization dataWithJSONObject:snapshot.value
                                                            options:(NSJSONWritingOptions)0
                                                              error:&error];
              NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
              f(path, json);
            } withCancelBlock:^(NSError * _Nonnull error) {
                NSString *erstr = [NSString stringWithFormat:@"Firebase Read Error: %@", error.localizedDescription];
                f(path, erstr);
            }];
        @}

        [Foreign(Language.Java)]
        extern(Android)
        public static void ListenForChildMoved(string path, Action<string,string> f)
        @{
            ChildEventListener childEventListener = new ChildEventListener() {
                @Override
                public void onChildAdded(DataSnapshot dataSnapshot, String previousChildName) {

                }

                @Override
                public void onChildChanged(DataSnapshot dataSnapshot, String s) {

                }

                @Override
                public void onChildRemoved(DataSnapshot dataSnapshot) {

                }

                @Override
                public void onChildMoved(DataSnapshot dataSnapshot, String s) {
                    if (dataSnapshot.getValue() == null) {
                        return;
                    }
                    JSONObject json = new JSONObject((Map)dataSnapshot.getValue());
                    f.run(path,json.toString());
                }

                @Override
                public void onCancelled(DatabaseError databaseError) {
                    f.run(path,databaseError.toString());
                }
            };
            DatabaseReference ref = (DatabaseReference)@{DatabaseService._handle:Get()};
            ref.child(path).addChildEventListener(childEventListener);
        @}

        [Foreign(Language.ObjC)]
        extern(iOS)
        public static void DetachListeners(string path)
        @{
            FIRDatabaseReference *ref = @{DatabaseService._handle:Get()};
            [[ref child:path] removeAllObservers];
        @}

        [Foreign(Language.Java)]
        extern(Android)
        public static void DetachListeners(string path)
        @{

        @}

        [Foreign(Language.ObjC)]
        extern(iOS)
        public static void Listen(string path, Action<string, string> f)
        @{
            FIRDatabaseReference *ref = @{DatabaseService._handle:Get()};
            [[ref child:path] observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
              if([snapshot.value isEqual:[NSNull null]]) {
                f(path, nil);
                return;
              }

              NSError *error;
              NSData *jsonData = [NSJSONSerialization dataWithJSONObject:snapshot.value
                                                            options:(NSJSONWritingOptions)0
                                                              error:&error];
              NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
              f(path, json);
            } withCancelBlock:^(NSError * _Nonnull error) {
                NSString *erstr = [NSString stringWithFormat:@"Firebase Read Error: %@", error.localizedDescription];
                f(path, erstr);
            }];
        @}

        [Foreign(Language.Java)]
        extern(Android)
        public static void Listen(string path, Action<string, string> f)
        @{
            ValueEventListener dataListener = new ValueEventListener() {
                @Override
                public void onDataChange(DataSnapshot dataSnapshot)
                {
                    JSONObject json = new JSONObject((Map)dataSnapshot.getValue());
                    f.run(path,json.toString());
                }

                @Override
                public void onCancelled(DatabaseError databaseError)
                {
                    f.run(path,databaseError.toString());
                }
            };
            DatabaseReference ref = (DatabaseReference)@{DatabaseService._handle:Get()};
            ref.child(path).addValueEventListener(dataListener);
        @}


        [Foreign(Language.ObjC)]
        extern(iOS)
        public static string NewChildId(string path)
        @{
            FIRDatabaseReference *ref = @{DatabaseService._handle:Get()};
            FIRDatabaseReference *_path = [[ref child:path] childByAutoId];
            return _path.key;
        @}

        [Foreign(Language.Java)]
        extern(Android)
        public static string NewChildId(string path)
        @{
            DatabaseReference ref = (DatabaseReference)@{DatabaseService._handle:Get()};
            return ref.child(path).push().getKey();
        @}

        [Foreign(Language.ObjC)]
        extern(iOS)
        public static void Save(string path, string[] keys, string[] vals, int len)
        @{
            FIRDatabaseReference *ref = @{DatabaseService._handle:Get()};
            NSDictionary *param = [NSDictionary dictionaryWithObjects:[vals copyArray] forKeys:[keys copyArray]];

            [[ref child:path] setValue:param];
        @}

        [Foreign(Language.Java)]
        extern(Android)
        public static void Save(string path, string[] keys, string[] vals, int len)
        @{
            DatabaseReference ref = (DatabaseReference)@{DatabaseService._handle:Get()};
            Map<String, String> values = new HashMap<String, String>();
            for (int i = 0; i < len; i++)
            {
                values.put(keys.get(i), vals.get(i));
            }
            ref.child(path).setValue(values);
        @}

        [Foreign(Language.ObjC)]
        extern(iOS)
        public static void SaveWithTimestamp(string path, ObjC.Object value)
        @{
            FIRDatabaseReference *ref = @{DatabaseService._handle:Get()};
            NSMutableDictionary *messageDic = [[NSMutableDictionary alloc] initWithDictionary:value];
            [messageDic setValue:[FIRServerValue timestamp] forKey:@"timestamp"];
            [[ref child:path] setValue:messageDic];
        @}

        [Foreign(Language.Java)]
        extern(Android)
        public static void SaveWithTimestamp(string path, Java.Object value)
        @{
            DatabaseReference ref = (DatabaseReference)@{DatabaseService._handle:Get()};
            try {
                Map<String, Object> obj = (Map<String, Object>) value;
                if (obj != null) {
                    obj.put("timestamp", ServerValue.TIMESTAMP);
                    ref.child(path).setValue(obj);
                }
                else {
                    ref.child(path).setValue(value);
                }
            } catch (Throwable t) {
                Log.e("Error ", "Could not Save message: \"" + value.toString() + "\"");
            }
        @}

        [Foreign(Language.ObjC)]
        extern(iOS)
        public static void Save(string path, ObjC.Object value)
        @{
            FIRDatabaseReference *ref = @{DatabaseService._handle:Get()};
            [[ref child:path] setValue:value];
        @}

        [Foreign(Language.Java)]
        extern(Android)
        public static void Save(string path, Java.Object value)
        @{
            DatabaseReference ref = (DatabaseReference)@{DatabaseService._handle:Get()};
            ref.child(path).setValue(value);
        @}

        [Foreign(Language.ObjC)]
        extern(iOS)
        public static void Save(string path, string[] array)
        @{
            FIRDatabaseReference *ref = @{DatabaseService._handle:Get()};
            [[ref child:path] setValue:[array copyArray]];
        @}

        [Foreign(Language.Java)]
        extern(Android)
        public static void Save(string path, string[] array)
        @{
            DatabaseReference ref = (DatabaseReference)@{DatabaseService._handle:Get()};
            ref.child(path).setValue(array);
        @}

        [Foreign(Language.ObjC)]
        extern(iOS)
        public static void Save(string path, string val)
        @{
            FIRDatabaseReference *ref = @{DatabaseService._handle:Get()};
            [[ref child:path] setValue:val];
        @}

        [Foreign(Language.Java)]
        extern(Android)
        public static void Save(string path, string val)
        @{
            DatabaseReference ref = (DatabaseReference)@{DatabaseService._handle:Get()};
            ref.child(path).setValue(val);
        @}

        [Foreign(Language.ObjC)]
        extern(iOS)
        public static void Save(string path, double val)
        @{
            FIRDatabaseReference *ref = @{DatabaseService._handle:Get()};
            [[ref child:path] setValue:[NSNumber numberWithDouble:val]];
        @}

        [Foreign(Language.Java)]
        extern(Android)
        public static void Save(string path, double val)
        @{
            DatabaseReference ref = (DatabaseReference)@{DatabaseService._handle:Get()};
            ref.child(path).setValue(val);
        @}

        [Foreign(Language.ObjC)]
        extern(iOS)
        public static void SaveNull(string path)
        @{
            FIRDatabaseReference *ref = @{DatabaseService._handle:Get()};
            [[ref child:path] setValue:nil];
        @}

        [Foreign(Language.Java)]
        extern(Android)
        public static void SaveNull(string path)
        @{
            DatabaseReference ref = (DatabaseReference)@{DatabaseService._handle:Get()};
            ref.child(path).setValue(null);
        @}

    }

    extern(!mobile)
    static class DatabaseService
    {
        public static void Init() {}
        public static string NewChildId(string path)
        {
            debug_log "NewChildId not implemented for desktop";
            return "unknown";
        }
        public static void Save() {
            debug_log "Save not implemented for desktop";
        }
        public static void Save(string path, string[] keys, string[] vals, int len)
        {
            Save();
        }
        public static void Save(string path, string[] array)
        {
            Save();
        }
        public static void Save(string path, string val)
        {
            Save();
        }
        public static void Save(string path, double val)
        {
            Save();
        }
        public static void SaveNull(string path)
        {
            Save();
        }

        public static void SaveWithTimestamp(string path, Object value)
        {
            Save();
        }

        public static void Listen(string path, Action<string,string> f)
        {
            debug_log "Listen not implemented for desktop";
        }

        public static void ReadByQueryEndingAtValue(string path, string keyName, string lastValue, int count, Action<string,string> f)
        {
            debug_log "ReadByQueryEndingAtValue not implemented for desktop";
        }

        public static void ListenForChildAdded(string path, int count, Action<string,string> f)
        {
            debug_log "ListenForChildAdded not implemented for desktop";
        }

        public static void ListenForChildChanged(string path, Action<string,string> f)
        {
            debug_log "ListenForChildChanged not implemented for desktop";
        }

        public static void ListenForChildRemoved(string path, Action<string,string> f)
        {
            debug_log "ListenForChildRemoved not implemented for desktop";
        }

        public static void ListenForChildMoved(string path, Action<string,string> f)
        {
            debug_log "ListenForChildMoved not implemented for desktop";
        }

        public static void DetachListeners(string path)
        {
            debug_log "DetachListeners not implemented for desktop";
        }
    }

    extern(!mobile)
    internal class Read : Promise<string>
    {
        public Read(string path)
        {
            Reject(new Exception("Not implemented on desktop"));
        }
    }

    extern(!mobile)
    internal class ReadByQueryEqualToValue : Promise<string>
    {
        public ReadByQueryEqualToValue(string path, string key, object val)
        {
            Reject(new Exception("Not implemented on desktop"));
        }
    }

    [Require("Entity", "DatabaseService")]
    [Require("Source.Import","FirebaseDatabase/FIRDatabase.h")]
    [Require("Source.Include","@{DatabaseService:Include}")]
    extern(iOS)
    internal class Read : Promise<string>
    {
        [Foreign(Language.ObjC)]
        public Read(string path)
        @{
            FIRDatabaseReference *ref = @{DatabaseService._handle:Get()};
            [[ref child:path] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                NSError *error;

                @{Read:Of(_this).Resolve(string):Call((
                    ([snapshot.value isEqual:[NSNull null]])
                        ? nil
                        : ([snapshot.value isKindOfClass:[NSString class]])
                            ? [NSString stringWithFormat:@"\"%@\"", snapshot.value]
                            : ([snapshot.value isKindOfClass:[NSNumber class]])
                                ? [NSString stringWithFormat:@"%@", snapshot.value]
                                : [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:snapshot.value options:(NSJSONWritingOptions)0 error:&error] encoding:NSUTF8StringEncoding]
                ))};

              } withCancelBlock:^(NSError * _Nonnull error) {
                  NSString *erstr = [NSString stringWithFormat:@"Firebase Read Error: %@", error.localizedDescription];
                  @{Read:Of(_this).Reject(string):Call(erstr)};
              }];
        @}
        void Reject(string reason) { Reject(new Exception(reason)); }
    }

    [Require("Entity", "DatabaseService")]
    [Require("Source.Import","FirebaseDatabase/FIRDatabase.h")]
    [Require("Source.Include","@{DatabaseService:Include}")]
    extern(iOS)
    internal class ReadByQueryEqualToValue : Promise<string>
    {
        [Foreign(Language.ObjC)]
        public ReadByQueryEqualToValue(string path, string key, ObjC.Object val)
        @{
            FIRDatabaseReference *ref = @{DatabaseService._handle:Get()};

            [[[[ref child:path] queryOrderedByChild:key] queryEqualToValue:val] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                NSError *error;

                @{ReadByQueryEqualToValue:Of(_this).Resolve(string):Call((
                    ([snapshot.value isEqual:[NSNull null]])
                        ? nil
                        : ([snapshot.value isKindOfClass:[NSString class]])
                            ? [NSString stringWithFormat:@"\"%@\"", snapshot.value]
                            : ([snapshot.value isKindOfClass:[NSNumber class]])
                                ? [NSString stringWithFormat:@"%@", snapshot.value]
                                : [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:snapshot.value options:(NSJSONWritingOptions)0 error:&error] encoding:NSUTF8StringEncoding]
                ))};

              } withCancelBlock:^(NSError * _Nonnull error) {
                  NSString *erstr = [NSString stringWithFormat:@"Firebase Read Error: %@", error.localizedDescription];
                  @{ReadByQueryEqualToValue:Of(_this).Reject(string):Call(erstr)};
              }];
        @}
        void Reject(string reason) { Reject(new Exception(reason)); }
    }

    [ForeignInclude(Language.Java,
        "com.google.firebase.database.DatabaseReference",
        "com.google.firebase.database.DatabaseError",
        "com.google.firebase.database.DatabaseReference",
        "com.google.firebase.database.DataSnapshot",
        "com.google.firebase.database.ValueEventListener",
        "org.json.JSONObject",
        "org.json.JSONArray",
        "java.util.Map",
        "java.util.List")]
    extern(Android)
    internal class Read : Promise<string>
    {
        [Foreign(Language.Java)]
        public Read(string path)
        @{
            ValueEventListener dataListener = new ValueEventListener() {
                @Override
                public void onDataChange(DataSnapshot dataSnapshot)
                {
                    Object snapshotValue = dataSnapshot.getValue();
                    @{Read:Of(_this).Resolve(string):Call((
                        (snapshotValue == null)
                            ? null
                            : (snapshotValue instanceof Map)
                                ? new JSONObject((Map) snapshotValue).toString()
                                : (snapshotValue instanceof List)
                                    ? new JSONArray((List) snapshotValue).toString()
                                    : (snapshotValue instanceof String)
                                        ? "\"" + snapshotValue.toString() + "\""
                                        : snapshotValue.toString()
                    ))};
                }

                @Override
                public void onCancelled(DatabaseError databaseError)
                {
                    @{Read:Of(_this).Reject(string):Call(databaseError.toString())};
                }
            };
            DatabaseReference ref = (DatabaseReference)@{DatabaseService._handle:Get()};
            ref.child(path).addListenerForSingleValueEvent(dataListener);
        @}
        void Reject(string reason) { Reject(new Exception(reason)); }
    }

    [ForeignInclude(Language.Java,
        "com.google.firebase.database.DatabaseReference",
        "com.google.firebase.database.DatabaseError",
        "com.google.firebase.database.DatabaseReference",
        "com.google.firebase.database.DataSnapshot",
        "com.google.firebase.database.ValueEventListener",
        "org.json.JSONObject",
        "org.json.JSONArray",
        "java.util.Map",
        "java.util.List")]
    extern(Android)
    internal class ReadByQueryEqualToValue : Promise<string>
    {
        [Foreign(Language.Java)]
        public ReadByQueryEqualToValue(string path, string key, Java.Object val)
        @{
            ValueEventListener dataListener = new ValueEventListener() {
                @Override
                public void onDataChange(DataSnapshot dataSnapshot)
                {
                    Object snapshotValue = dataSnapshot.getValue();
                    @{ReadByQueryEqualToValue:Of(_this).Resolve(string):Call((
                        (snapshotValue == null)
                            ? null
                            : (snapshotValue instanceof Map)
                                ? new JSONObject((Map) snapshotValue).toString()
                                : (snapshotValue instanceof List)
                                    ? new JSONArray((List) snapshotValue).toString()
                                    : (snapshotValue instanceof String)
                                        ? "\"" + snapshotValue.toString() + "\""
                                        : snapshotValue.toString()
                    ))};
                }

                @Override
                public void onCancelled(DatabaseError databaseError)
                {
                    @{ReadByQueryEqualToValue:Of(_this).Reject(string):Call(databaseError.toString())};
                }
            };
            DatabaseReference ref = (DatabaseReference)@{DatabaseService._handle:Get()};
            if(val instanceof String){
                String obj = (String) val;
                ref.child(path).orderByChild(key).equalTo(obj).addListenerForSingleValueEvent(dataListener);
            } else if (val instanceof Double){
                Double obj = (Double) val;
                ref.child(path).orderByChild(key).equalTo(obj).addListenerForSingleValueEvent(dataListener);
            } else if( val instanceof Boolean  ){
                Boolean obj = (Boolean) val;
                ref.child(path).orderByChild(key).equalTo(obj).addListenerForSingleValueEvent(dataListener);
            }
        @}
        void Reject(string reason) { Reject(new Exception(reason)); }
    }
}
