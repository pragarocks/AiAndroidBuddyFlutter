package com.pocketpet.services

import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import androidx.annotation.RequiresApi

@RequiresApi(Build.VERSION_CODES.N)
class QuickSummaryTileService : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        qsTile?.let { tile ->
            tile.state = Tile.STATE_INACTIVE
            tile.label = "PocketPet"
            tile.updateTile()
        }
    }

    override fun onClick() {
        super.onClick()
        // Sends a broadcast that the Flutter layer listens to,
        // triggering the nudge/summary speech bubble overlay.
        sendBroadcast(
            android.content.Intent("com.pocketpet.ACTION_QUICK_SUMMARY").apply {
                setPackage(packageName)
            }
        )
    }
}
