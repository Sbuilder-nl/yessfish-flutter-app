package nl.sbuilder.yessfish

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

class YfWidgetProvider : HomeWidgetProvider() {

    private fun decodeSampled(path: String, target: Int = 320): Bitmap? {
        return try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            var sample = 1
            val largest = maxOf(bounds.outWidth, bounds.outHeight)
            while (largest / (sample * 2) >= target) sample *= 2
            val opts = BitmapFactory.Options().apply { inSampleSize = sample }
            BitmapFactory.decodeFile(path, opts)
        } catch (e: Exception) {
            null
        }
    }

    private fun launch(context: Context, uri: String) =
        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse(uri))

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.yf_widget).apply {
                val species = widgetData.getString("latest_species", null)
                val user = widgetData.getString("latest_user", null)
                val text = if (!species.isNullOrEmpty()) {
                    "\uD83C\uDFA3 " + species + (if (!user.isNullOrEmpty()) "  ·  " + user else "")
                } else {
                    "—"
                }
                setTextViewText(R.id.yf_latest, text)

                val weather = widgetData.getString("weather_text", null)
                setTextViewText(R.id.yf_weather, if (!weather.isNullOrEmpty()) weather else "")

                val photo = widgetData.getString("latest_photo", null)
                val bmp = if (!photo.isNullOrEmpty() && File(photo).exists()) decodeSampled(photo) else null
                if (bmp != null) {
                    setImageViewBitmap(R.id.yf_photo, bmp)
                    setViewVisibility(R.id.yf_photo, View.VISIBLE)
                } else {
                    setViewVisibility(R.id.yf_photo, View.GONE)
                }

                val catchId = widgetData.getString("latest_catch_id", null)
                if (!catchId.isNullOrEmpty()) {
                    setOnClickPendingIntent(R.id.yf_photo_area, launch(context, "yessfishwidget://view/" + catchId))
                }

                setOnClickPendingIntent(R.id.yf_btn_catch, launch(context, "yessfishwidget://catch"))
                setOnClickPendingIntent(R.id.yf_btn_spot, launch(context, "yessfishwidget://spot"))
                setOnClickPendingIntent(R.id.yf_btn_feed, launch(context, "yessfishwidget://feed"))
                setOnClickPendingIntent(R.id.yf_btn_map, launch(context, "yessfishwidget://map"))
                setOnClickPendingIntent(R.id.yf_btn_album, launch(context, "yessfishwidget://album"))
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
