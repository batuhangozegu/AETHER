package com.borsa.borsa_app

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth (biyometrik giriş) FragmentActivity gerektiriyor —
// AndroidX biyometrik dialog'u ancak bir FragmentActivity üzerinde açılabiliyor.
class MainActivity : FlutterFragmentActivity()
