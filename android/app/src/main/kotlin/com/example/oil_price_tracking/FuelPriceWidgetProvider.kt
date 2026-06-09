package com.example.oil_price_tracking

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class FuelPriceWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.fuel_price_widget).apply {
            setOnClickPendingIntent(
                R.id.widget_container,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )

            setTextViewText(R.id.widget_title, widgetData.getString("widget_title", "Petrolimex"))
            setTextViewText(
                R.id.widget_updated_at,
                widgetData.getString("widget_updated_at", "Dang cho cap nhat"),
            )

            val error = widgetData.getString("widget_error", "") ?: ""
            setTextViewText(R.id.widget_error, error)
            setViewVisibility(R.id.widget_error, if (error.isBlank()) View.GONE else View.VISIBLE)

            bindRow(this, widgetData, R.id.product_1, R.id.product_1_name, R.id.product_1_price, 1)
            bindRow(this, widgetData, R.id.product_2, R.id.product_2_name, R.id.product_2_price, 2)
            bindRow(this, widgetData, R.id.product_3, R.id.product_3_name, R.id.product_3_price, 3)
            bindRow(this, widgetData, R.id.product_4, R.id.product_4_name, R.id.product_4_price, 4)
          }
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  private fun bindRow(
      views: RemoteViews,
      widgetData: SharedPreferences,
      rowId: Int,
      nameId: Int,
      priceId: Int,
      index: Int,
  ) {
    val name = widgetData.getString("product_${index}_name", "") ?: ""
    val price = widgetData.getString("product_${index}_price", "") ?: ""
    views.setTextViewText(nameId, name)
    views.setTextViewText(priceId, price)
    views.setViewVisibility(rowId, if (name.isBlank()) View.GONE else View.VISIBLE)
  }
}
