package pl.ukaszapps.fairbid_flutter_example

import android.app.Application
import androidx.multidex.MultiDex

/**
 * Created by Lukasz Huculak.
 */
class MultiDexFlutterApplication : Application() {
	override fun onCreate() {
		MultiDex.install(this)
		super.onCreate()
	}
}