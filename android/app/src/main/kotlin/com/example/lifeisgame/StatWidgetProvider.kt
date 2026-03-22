// ─────────────────────────────────────────────────────────────────────────────
//  StatWidgetProvider — Android Home-Screen Widget (2×2)
//  Reads top-3 stats from SharedPreferences (written by home_widget),
//  renders RemoteViews, handles + button taps via PendingIntent.
// ─────────────────────────────────────────────────────────────────────────────

package com.example.lifeisgame

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews

// ─── Constants ───────────────────────────────────────────────────────────────
private const val PREFS_NAME = "HomeWidgetPreferences"
private const val ACTION_INCREMENT = "com.example.lifeisgame.ACTION_INCREMENT"
private const val EXTRA_STAT_INDEX = "stat_index"

// ─── AppWidgetProvider ───────────────────────────────────────────────────────
class StatWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, widgetId)
        }
    }

    // ── Handle + button taps ──
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.action == ACTION_INCREMENT) {
            val index = intent.getIntExtra(EXTRA_STAT_INDEX, -1)
            if (index in 0..2) {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

                // ── Read current value & level ──
                var value = prefs.getInt("flutter.stat_value_$index", 0)
                var level = prefs.getInt("flutter.stat_level_$index", 0)

                // ── Leveling logic: increment ──
                value++
                if (value >= 10) {
                    value = 0
                    level++
                }

                // ── Write back ──
                prefs.edit()
                    .putInt("flutter.stat_value_$index", value)
                    .putInt("flutter.stat_level_$index", level)
                    .apply()

                // ── Refresh all widget instances ──
                val manager = AppWidgetManager.getInstance(context)
                val ids = manager.getAppWidgetIds(
                    ComponentName(context, StatWidgetProvider::class.java)
                )
                for (id in ids) {
                    updateAppWidget(context, manager, id)
                }

                // ── Broadcast to Flutter via home_widget ──
                val launchIntent = Intent(context, Class.forName("${context.packageName}.MainActivity")).apply {
                    action = "es.antonborri.home_widget.action.LAUNCH"
                    data = android.net.Uri.parse("homewidget://increment?index=$index")
                }
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(launchIntent)
            }
        }
    }

    companion object {
        // ── Build RemoteViews for one widget instance ──
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs: SharedPreferences =
                context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            val views = RemoteViews(context.packageName, R.layout.stat_widget)

            // ── Row IDs for name, level, progress, + button ──
            val nameIds  = intArrayOf(R.id.stat_name_0, R.id.stat_name_1, R.id.stat_name_2)
            val levelIds = intArrayOf(R.id.stat_level_0, R.id.stat_level_1, R.id.stat_level_2)
            val barIds   = intArrayOf(R.id.stat_bar_0, R.id.stat_bar_1, R.id.stat_bar_2)
            val btnIds   = intArrayOf(R.id.stat_btn_0, R.id.stat_btn_1, R.id.stat_btn_2)

            for (i in 0..2) {
                val name  = prefs.getString("flutter.stat_name_$i", "---") ?: "---"
                val value = prefs.getInt("flutter.stat_value_$i", 0)
                val level = prefs.getInt("flutter.stat_level_$i", 0)

                views.setTextViewText(nameIds[i], name.uppercase())
                views.setTextViewText(levelIds[i], "LVL $level")
                views.setProgressBar(barIds[i], 10, value, false)

                // ── PendingIntent for the + button ──
                val incrementIntent = Intent(context, StatWidgetProvider::class.java).apply {
                    action = ACTION_INCREMENT
                    putExtra(EXTRA_STAT_INDEX, i)
                }
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    i,
                    incrementIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(btnIds[i], pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
