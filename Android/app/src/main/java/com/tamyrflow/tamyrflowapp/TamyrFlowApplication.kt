package com.tamyrflow.tamyrflowapp

import android.app.Application
import com.orhanobut.logger.AndroidLogAdapter
import com.orhanobut.logger.Logger
import com.orhanobut.logger.PrettyFormatStrategy
import com.tamyrflow.tamyrflowapp.ble.VeepooPlatformBootstrap
import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.util.VPLogger

class TamyrFlowApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        val formatStrategy = PrettyFormatStrategy.newBuilder()
            .methodCount(0)
            .showThreadInfo(false)
            .tag("TamyrFlow")
            .build()
        Logger.addLogAdapter(AndroidLogAdapter(formatStrategy))
        VPLogger.setDebug(BuildConfig.DEBUG)
        VPOperateManager.getInstance().init(applicationContext)
        VeepooPlatformBootstrap.applyAfterVpManagerInit(applicationContext)
    }
}

