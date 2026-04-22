package io.runtime.mcumgr.dfu.mcuboot.model

class ImageSet {
    private val images: MutableList<ByteArray> = mutableListOf()

    fun add(image: ByteArray): ImageSet {
        images.add(image)
        return this
    }

    @Suppress("UNCHECKED_CAST")
    fun set(items: List<*>): ImageSet {
        images.clear()
        items.forEach { item ->
            when (item) {
                is ByteArray -> images.add(item)
                is List<*> -> {
                    val bytes = item.filterIsInstance<Number>().map { it.toByte() }.toByteArray()
                    if (bytes.isNotEmpty()) images.add(bytes)
                }
            }
        }
        return this
    }

    internal fun firstOrNull(): ByteArray? = images.firstOrNull()
}
