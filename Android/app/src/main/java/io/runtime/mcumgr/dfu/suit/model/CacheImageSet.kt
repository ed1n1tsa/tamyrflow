package io.runtime.mcumgr.dfu.suit.model

class CacheImageSet(
    private val images: List<ByteArray> = emptyList()
) {
    fun getImages(): List<ByteArray> = images
}
