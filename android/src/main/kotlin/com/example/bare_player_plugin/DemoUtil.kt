package com.example.bare_player_plugin

/*
 * Copyright (C) 2016 The Android Open Source Project
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

import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import com.google.android.exoplayer2.database.DatabaseProvider
import com.google.android.exoplayer2.database.StandaloneDatabaseProvider
import com.google.android.exoplayer2.offline.DownloadManager
import com.google.android.exoplayer2.ui.DownloadNotificationHelper
import com.google.android.exoplayer2.upstream.DataSource
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource
import com.google.android.exoplayer2.upstream.FileDataSource
import com.google.android.exoplayer2.upstream.cache.Cache
import com.google.android.exoplayer2.upstream.cache.NoOpCacheEvictor
import com.google.android.exoplayer2.upstream.cache.SimpleCache
import java.io.File
import java.net.CookieHandler
import java.net.CookieManager
import java.net.CookiePolicy
import java.util.concurrent.Executors


/** Utility methods for the demo app.  */
object DemoUtil {
    const val DOWNLOAD_NOTIFICATION_CHANNEL_ID = "download_channel"

    /**
     * Whether the demo application uses Cronet for networking. Note that Cronet does not provide
     * automatic support for cookies (https://github.com/google/ExoPlayer/issues/5975).
     *
     *
     * If set to false, the platform's default network stack is used with a [CookieManager]
     * configured in [.getHttpDataSourceFactory].
     */
    private const val USE_CRONET_FOR_NETWORKING = true
    private const val TAG = "DemoUtil"
    private const val DOWNLOAD_CONTENT_DIRECTORY = "downloads"
    private var dataSourceFactory:  DataSource.Factory? = null
    private var httpDataSourceFactory:DataSource.Factory? = null

    private var databaseProvider: DatabaseProvider? = null

    private var downloadDirectory: File? = null

    private var downloadCache: Cache? = null

    private var downloadManager: DownloadManager? = null

    private var downloadNotificationHelper: DownloadNotificationHelper? = null

    private val tag = "TAG: DemoUtil"

    fun print(@NonNull messageToPrint: String) {
        Log.i(tag, messageToPrint)

    }

    @Synchronized
    fun getHttpDataSourceFactory(context: Context): DataSource.Factory? {
        print ("getHttpDataSourceFactory")
            var context = context
            if (httpDataSourceFactory == null) {
                val cookieManager = CookieManager()
                cookieManager.setCookiePolicy(CookiePolicy.ACCEPT_ORIGINAL_SERVER)
                CookieHandler.setDefault(cookieManager)
                httpDataSourceFactory = DefaultHttpDataSource.Factory()
            }
        return httpDataSourceFactory
    }

    @Synchronized
    fun getDownloadNotificationHelper(
        context: Context?
    ): DownloadNotificationHelper? {
        print ("getDownloadNotificationHelper")
        if (downloadNotificationHelper == null) {
            downloadNotificationHelper = DownloadNotificationHelper(
                context!!, DOWNLOAD_NOTIFICATION_CHANNEL_ID
            )
        }
        return downloadNotificationHelper
    }

    @Synchronized
    fun getDownloadManager(context: Context): DownloadManager? {
        print ("getDownloadManager")
        ensureDownloadManagerInitialized(context)
        return downloadManager
    }

    @Synchronized
    fun getDownloadCache(context: Context): Cache? {
        print ("getDownloadCache")
        if (downloadCache == null) {
            val downloadContentDirectory =
                File(getDownloadDirectory(context), DOWNLOAD_CONTENT_DIRECTORY)
            downloadCache = SimpleCache(
                downloadContentDirectory, NoOpCacheEvictor(), getDatabaseProvider(context)!!
            )
        }
        return downloadCache
    }

    @Synchronized
    private fun ensureDownloadManagerInitialized(context: Context) {
        print ("ensureDownloadManagerInitialized")
        if (downloadManager == null) {
            downloadManager = DownloadManager(
                context,
                getDatabaseProvider(context)!!,
                getDownloadCache(context)!!,
                getHttpDataSourceFactory(context)!!,
                Executors.newFixedThreadPool( /* nThreads= */6)
            )
        }
    }

     fun getFileDataSourceFactory(context: Context): DataSource.Factory? {
        print ("getFileDataSourceFactory")
        if (dataSourceFactory == null) {
            dataSourceFactory = FileDataSource.Factory()
        }
        return dataSourceFactory
    }

    @Synchronized
    private fun getDatabaseProvider(context: Context): DatabaseProvider? {
        print ("getDatabaseProvider")
        if (databaseProvider == null) {
            databaseProvider = StandaloneDatabaseProvider(context)
        }
        return databaseProvider
    }

    @Synchronized
    private fun getDownloadDirectory(context: Context): File? {
        print ("getDownloadDirectory")
        if (downloadDirectory == null) {
            downloadDirectory = context.getExternalFilesDir( /* type= */null)
            if (downloadDirectory == null) {
                downloadDirectory = context.filesDir
            }
        }

        print ("downloadDirectory: $downloadDirectory")
        return downloadDirectory
    }

}