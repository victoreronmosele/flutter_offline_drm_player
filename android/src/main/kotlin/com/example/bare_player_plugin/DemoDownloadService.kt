package com.example.bare_player_plugin


/*
 * Copyright (C) 2017 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.graphics.Color
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.android.exoplayer2.offline.Download
import com.google.android.exoplayer2.offline.DownloadManager
import com.google.android.exoplayer2.offline.DownloadService
import com.google.android.exoplayer2.scheduler.PlatformScheduler
import com.google.android.exoplayer2.scheduler.Scheduler
import com.google.android.exoplayer2.ui.DownloadNotificationHelper
import java.lang.Exception

class DemoDownloadService : DownloadService(
    R.string.exo_download_notification_channel_name,  /* channelDescriptionResourceId= */
    FOREGROUND_NOTIFICATION_ID_NONE.toLong()
) {
    private val tag = "TAG: DemoDownloadService"
    private val notificationChannelId = "com.bare_player_plugin"
    var notificationManager: NotificationManagerCompat? = null
    var isDownloadComplete = false

    override fun onCreate() {
        super.onCreate()
        notificationManager = NotificationManagerCompat.from(this)

        val importance = NotificationManagerCompat.IMPORTANCE_HIGH
        val mChannel = NotificationChannelCompat.Builder(notificationChannelId, importance).apply {
            setName("Downloads For Bare Player Plugin") // Must set! Don't remove
            setDescription("To show notifications for downloads")
            setLightsEnabled(true)
            setLightColor(Color.RED)
        }.build()

        notificationManager!!.createNotificationChannel(mChannel)
    }


    @SuppressLint("LongLogTag")
    fun print(@NonNull messageToPrint: String) {
        Log.i(tag, messageToPrint)

    }

    override fun getDownloadManager(): DownloadManager {
        print ("getDownloadManager")
        val downloadManager = DemoUtil.getDownloadManager( /* context= */this)!!

        downloadManager.addListener(object : DownloadManager.Listener {
            override fun onDownloadChanged(
                downloadManager: DownloadManager,
                download: Download,
                finalException: Exception?
            ) {
                print ("getDownloadManager onDownloadChanged with download.state == ${download.state}")
                print ("getDownloadManager download.state == Download.STATE_COMPLETED ${download.bytesDownloaded == download.contentLength}")
                if (download.state == Download.STATE_COMPLETED) {
                   print ("download.state == Download.STATE_COMPLETED")

                    isDownloadComplete = true
                }
            }

            override fun onDownloadRemoved(
                downloadManager: DownloadManager,
                download: Download
            ) {

            }
        })

        return downloadManager
    }

    override fun getScheduler(): Scheduler? {
        return null
    }

    override fun getForegroundNotification(
        downloads: MutableList<Download>,
        notMetRequirements: Int
    ): Notification {
        print ("getForegroundNotification")

        // Create a notification builder with progress
        val notificationBuilder = NotificationCompat.Builder(this, notificationChannelId)
            .setSmallIcon(R.drawable.ic_stat_name)
            .setContentTitle("Online Audio With DRM Protection")
            .setContentText("Downloading...")
            .setProgress(100, 0, !isDownloadComplete)
            .setOngoing(false) // Make the notification ongoing


        val notification = notificationBuilder.build()
        notificationManager!!.notify(1, notification)

        return notificationBuilder.build()
    }
}



