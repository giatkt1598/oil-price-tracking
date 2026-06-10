package com.example.oil_price_tracking

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT
import android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH
import android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT
import android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.os.Bundle
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

class FuelPriceWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      updateWidget(context, appWidgetManager, widgetId, widgetData)
    }
  }

  override fun onAppWidgetOptionsChanged(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetId: Int,
      newOptions: Bundle,
  ) {
    super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    updateWidget(context, appWidgetManager, appWidgetId, HomeWidgetPlugin.getData(context))
  }

  private fun updateWidget(
      context: Context,
      appWidgetManager: AppWidgetManager,
      widgetId: Int,
      widgetData: SharedPreferences,
  ) {
    val options = appWidgetManager.getAppWidgetOptions(widgetId)
    val minHeight = options.getInt(OPTION_APPWIDGET_MIN_HEIGHT, 40)
    val maxHeight = options.getInt(OPTION_APPWIDGET_MAX_HEIGHT, minHeight)
    val minWidth = options.getInt(OPTION_APPWIDGET_MIN_WIDTH, 110)
    val maxWidth = options.getInt(OPTION_APPWIDGET_MAX_WIDTH, minWidth)
    val effectiveHeight = maxOf(minHeight, maxHeight)
    val effectiveWidth = maxOf(minWidth, maxWidth)
    val isSingleRow = effectiveHeight < 110
    val isTwoColumns = effectiveWidth < 180
    val maxRows = if (isSingleRow) 2 else 6
    val showTitle = effectiveWidth >= 180

    val views =
        if (isSingleRow) {
          buildCompactView(context, widgetData, removeGasolinePrefix = isTwoColumns)
        } else {
          buildFullView(
              context,
              widgetData,
              maxRows,
              showTitle,
              effectiveHeight,
              removeGasolinePrefix = isTwoColumns,
          )
        }
    appWidgetManager.updateAppWidget(widgetId, views)
  }

  private fun buildFullView(
      context: Context,
      widgetData: SharedPreferences,
      maxRows: Int,
      showTitle: Boolean,
      effectiveHeight: Int,
      removeGasolinePrefix: Boolean,
  ): RemoteViews {
    return RemoteViews(context.packageName, R.layout.fuel_price_widget).apply {
      setOnClickPendingIntent(
          R.id.widget_container,
          HomeWidgetBackgroundIntent.getBroadcast(
              context,
              Uri.parse("oilPriceTracking://refresh"),
          ),
      )

      setTextViewText(R.id.widget_title, "Petrolimex")
      setViewVisibility(R.id.widget_title, if (showTitle) View.VISIBLE else View.GONE)
      setViewVisibility(R.id.widget_header, View.VISIBLE)
      setTextViewText(
          R.id.widget_updated_at,
          widgetData.getString("widget_updated_at", "Đang chờ cập nhật"),
      )

      val error = widgetData.getString("widget_error", "") ?: ""
      val productTextSize = productTextSize(11f, countVisibleProducts(widgetData, maxRows))
      setTextViewText(R.id.widget_error, error)
      setViewVisibility(
          R.id.widget_error,
          if (error.isBlank() || effectiveHeight < 145) View.GONE else View.VISIBLE,
      )

      bindRow(
          this,
          widgetData,
          R.id.product_1,
          R.id.product_1_name,
          R.id.product_1_price,
          1,
          maxRows,
          productTextSize,
          removeGasolinePrefix,
      )
      bindRow(
          this,
          widgetData,
          R.id.product_2,
          R.id.product_2_name,
          R.id.product_2_price,
          2,
          maxRows,
          productTextSize,
          removeGasolinePrefix,
      )
      bindRow(
          this,
          widgetData,
          R.id.product_3,
          R.id.product_3_name,
          R.id.product_3_price,
          3,
          maxRows,
          productTextSize,
          removeGasolinePrefix,
      )
      bindRow(
          this,
          widgetData,
          R.id.product_4,
          R.id.product_4_name,
          R.id.product_4_price,
          4,
          maxRows,
          productTextSize,
          removeGasolinePrefix,
      )
      bindRow(
          this,
          widgetData,
          R.id.product_5,
          R.id.product_5_name,
          R.id.product_5_price,
          5,
          maxRows,
          productTextSize,
          removeGasolinePrefix,
      )
      bindRow(
          this,
          widgetData,
          R.id.product_6,
          R.id.product_6_name,
          R.id.product_6_price,
          6,
          maxRows,
          productTextSize,
          removeGasolinePrefix,
      )
    }
  }

  private fun buildCompactView(
      context: Context,
      widgetData: SharedPreferences,
      removeGasolinePrefix: Boolean,
  ): RemoteViews {
    return RemoteViews(context.packageName, R.layout.fuel_price_widget_compact).apply {
      val visibleProductCount = countVisibleProducts(widgetData, 2)
      val productTextSize = productTextSize(14f, maxOf(visibleProductCount, 2))
      setOnClickPendingIntent(
          R.id.widget_container,
          HomeWidgetBackgroundIntent.getBroadcast(
              context,
              Uri.parse("oilPriceTracking://refresh"),
          ),
      )
      if (visibleProductCount < 2) {
        bindCompactUpdatedAt(this, widgetData)
        bindCompactRow(
            this,
            widgetData,
            R.id.product_2,
            R.id.product_2_name,
            R.id.product_2_price,
            1,
            productTextSize,
            removeGasolinePrefix,
        )
      } else {
        bindCompactRow(
            this,
            widgetData,
            R.id.product_1,
            R.id.product_1_name,
            R.id.product_1_price,
            1,
            productTextSize,
            removeGasolinePrefix,
        )
        bindCompactRow(
            this,
            widgetData,
            R.id.product_2,
            R.id.product_2_name,
            R.id.product_2_price,
            2,
            productTextSize,
            removeGasolinePrefix,
        )
      }
    }
  }

  private fun bindCompactRow(
      views: RemoteViews,
      widgetData: SharedPreferences,
      rowId: Int,
      nameId: Int,
      priceId: Int,
      index: Int,
      productTextSize: Float,
      removeGasolinePrefix: Boolean,
  ) {
    val rawName = widgetData.getString("product_${index}_name", "") ?: ""
    val name = if (removeGasolinePrefix) compactTwoByOneName(rawName) else rawName
    val price = widgetData.getString("product_${index}_price", "") ?: ""
    views.setTextViewText(nameId, name)
    views.setTextViewText(priceId, price)
    setProductTextSize(views, nameId, priceId, productTextSize)
    views.setViewVisibility(rowId, if (rawName.isBlank()) View.GONE else View.VISIBLE)
  }

  private fun bindCompactUpdatedAt(
      views: RemoteViews,
      widgetData: SharedPreferences,
  ) {
    views.setTextViewText(
        R.id.product_1_name,
        widgetData.getString("widget_updated_at", "Đang chờ cập nhật"),
    )
    views.setTextViewText(R.id.product_1_price, "")
    views.setTextViewTextSize(R.id.product_1_name, TypedValue.COMPLEX_UNIT_SP, 11f)
    views.setTextViewTextSize(R.id.product_1_price, TypedValue.COMPLEX_UNIT_SP, 11f)
    views.setViewVisibility(R.id.product_1, View.VISIBLE)
  }

  private fun bindRow(
      views: RemoteViews,
      widgetData: SharedPreferences,
      rowId: Int,
      nameId: Int,
      priceId: Int,
      index: Int,
      maxRows: Int,
      productTextSize: Float,
      removeGasolinePrefix: Boolean,
  ) {
    val rawName = widgetData.getString("product_${index}_name", "") ?: ""
    val name = if (removeGasolinePrefix) compactTwoByOneName(rawName) else rawName
    val price = widgetData.getString("product_${index}_price", "") ?: ""
    views.setTextViewText(nameId, name)
    views.setTextViewText(priceId, price)
    setProductTextSize(views, nameId, priceId, productTextSize)
    views.setViewVisibility(rowId, if (rawName.isBlank() || index > maxRows) View.GONE else View.VISIBLE)
  }

  private fun countVisibleProducts(widgetData: SharedPreferences, maxRows: Int): Int {
    var count = 0
    for (index in 1..maxRows) {
      val name = widgetData.getString("product_${index}_name", "") ?: ""
      if (name.isNotBlank()) {
        count++
      }
    }
    return count
  }

  private fun productTextSize(baseSizeSp: Float, visibleProductCount: Int): Float {
    val multiplier =
        when {
          visibleProductCount < 2 -> 2f
          visibleProductCount <= 5 -> 1.5f
          else -> 1.25f
        }
    return baseSizeSp * multiplier
  }

  private fun setProductTextSize(
      views: RemoteViews,
      nameId: Int,
      priceId: Int,
      sizeSp: Float,
  ) {
    views.setTextViewTextSize(nameId, TypedValue.COMPLEX_UNIT_SP, sizeSp)
    views.setTextViewTextSize(priceId, TypedValue.COMPLEX_UNIT_SP, sizeSp)
  }

  private fun compactTwoByOneName(name: String): String {
    return name.replace(Regex("^\\s*Xăng\\s+", RegexOption.IGNORE_CASE), "").trim()
  }
}
