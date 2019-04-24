package pl.ukaszapps.fairbid_flutter_example

import androidx.multidex.MultiDex

/**
 * Created by Lukasz Huculak.
 */
class MultiDexFlutterApplication : io.flutter.app.FlutterApplication() {
	override fun onCreate() {
		MultiDex.install(this)
		super.onCreate()
	}
}