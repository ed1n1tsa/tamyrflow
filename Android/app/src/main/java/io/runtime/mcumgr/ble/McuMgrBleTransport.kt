package io.runtime.mcumgr.ble

import android.bluetooth.BluetoothDevice
import android.content.Context
import io.runtime.mcumgr.McuMgrCallback
import io.runtime.mcumgr.McuMgrScheme
import io.runtime.mcumgr.McuMgrTransport
import io.runtime.mcumgr.exception.McuMgrException
import io.runtime.mcumgr.response.McuMgrResponse

/**
 * Compatibility transport for Veepoo SDK runtime linkage.
 * Veepoo reflects legacy mcumgr BLE APIs (setInitialMtu/requestConnPriority),
 * but OTA is not used in TamyrFlow, so transport operations are intentionally no-op.
 */
class McuMgrBleTransport(
    @Suppress("UNUSED_PARAMETER") context: Context,
    @Suppress("UNUSED_PARAMETER") device: BluetoothDevice
) : McuMgrTransport {

    fun setInitialMtu(@Suppress("UNUSED_PARAMETER") mtu: Int) = Unit

    fun requestConnPriority(@Suppress("UNUSED_PARAMETER") priority: Int) = Unit

    override fun getScheme(): McuMgrScheme = McuMgrScheme.BLE

    override fun <T : McuMgrResponse> send(
        @Suppress("UNUSED_PARAMETER") data: ByteArray,
        @Suppress("UNUSED_PARAMETER") responseType: Class<T>
    ): T {
        throw McuMgrException("McuMgr BLE transport is disabled in this build")
    }

    override fun <T : McuMgrResponse> send(
        @Suppress("UNUSED_PARAMETER") data: ByteArray,
        @Suppress("UNUSED_PARAMETER") responseType: Class<T>,
        callback: McuMgrCallback<T>
    ) {
        callback.onError(McuMgrException("McuMgr BLE transport is disabled in this build"))
    }

    override fun connect(callback: McuMgrTransport.ConnectionCallback?) {
        callback?.onConnected()
    }

    override fun release() = Unit

    override fun addObserver(@Suppress("UNUSED_PARAMETER") observer: McuMgrTransport.ConnectionObserver) = Unit

    override fun removeObserver(@Suppress("UNUSED_PARAMETER") observer: McuMgrTransport.ConnectionObserver) = Unit
}
