package com.tamyrflow.tamyrflowapp.ble

import android.content.Context
import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.base.IBleNotifyResponse
import java.util.UUID

/**
 * Veepoo demo ([com.timaimee.vpdemo.activity.OperaterActivity]) calls these right after connect flow
 * so that measurements and JL devices behave like the official app. Tamyr keeps only Compose UI;
 * this object mirrors that non-UI setup 1:1.
 */
object VeepooPlatformBootstrap {

    fun applyAfterVpManagerInit(@Suppress("UNUSED_PARAMETER") context: Context) {
        val mgr = VPOperateManager.getInstance()
        mgr.setAutoConnectBTBySdk(false)
        mgr.listenDeviceCallbackData(
            object : IBleNotifyResponse() {
                override fun onNotify(service: UUID?, character: UUID?, value: ByteArray?) {
                    super.onNotify(service, character, value)
                }
            }
        )
    }
}
