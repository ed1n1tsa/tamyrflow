package io.runtime.mcumgr.dfu.mcuboot

import io.runtime.mcumgr.McuMgrTransport
import io.runtime.mcumgr.dfu.FirmwareUpgradeCallback
import io.runtime.mcumgr.dfu.mcuboot.model.ImageSet

class FirmwareUpgradeManager(
    transport: McuMgrTransport,
    callback: FirmwareUpgradeCallback
) {
    private val delegate = io.runtime.mcumgr.dfu.FirmwareUpgradeManager(transport, callback)

    enum class Mode {
        TEST_ONLY,
        CONFIRM_ONLY,
        TEST_AND_CONFIRM,
        UPLOAD_ONLY
    }

    class Settings private constructor(
        val eraseAppSettings: Boolean,
        val estimatedSwapTime: Int,
        val windowCapacity: Int,
        val memoryAlignment: Int
    ) {
        class Builder {
            private var eraseAppSettings: Boolean = false
            private var estimatedSwapTime: Int = 0
            private var windowCapacity: Int = 0
            private var memoryAlignment: Int = 0

            fun setEraseAppSettings(value: Boolean): Builder {
                eraseAppSettings = value
                return this
            }

            fun setEstimatedSwapTime(value: Int): Builder {
                estimatedSwapTime = value
                return this
            }

            fun setWindowCapacity(value: Int): Builder {
                windowCapacity = value
                return this
            }

            fun setMemoryAlignment(value: Int): Builder {
                memoryAlignment = value
                return this
            }

            fun build(): Settings = Settings(
                eraseAppSettings = eraseAppSettings,
                estimatedSwapTime = estimatedSwapTime,
                windowCapacity = windowCapacity,
                memoryAlignment = memoryAlignment
            )
        }
    }

    fun setMode(mode: Mode) {
        delegate.setMode(
            when (mode) {
                Mode.TEST_ONLY -> io.runtime.mcumgr.dfu.FirmwareUpgradeManager.Mode.TEST_ONLY
                Mode.CONFIRM_ONLY -> io.runtime.mcumgr.dfu.FirmwareUpgradeManager.Mode.CONFIRM_ONLY
                Mode.TEST_AND_CONFIRM -> io.runtime.mcumgr.dfu.FirmwareUpgradeManager.Mode.TEST_AND_CONFIRM
                Mode.UPLOAD_ONLY -> io.runtime.mcumgr.dfu.FirmwareUpgradeManager.Mode.TEST_AND_CONFIRM
            }
        )
    }

    fun start(images: ImageSet, settings: Settings) {
        if (settings.estimatedSwapTime > 0) {
            delegate.setEstimatedSwapTime(settings.estimatedSwapTime)
        }
        if (settings.windowCapacity > 0) {
            delegate.setUploadMtu(settings.windowCapacity)
        }
        images.firstOrNull()?.let { delegate.start(it) }
    }
}
