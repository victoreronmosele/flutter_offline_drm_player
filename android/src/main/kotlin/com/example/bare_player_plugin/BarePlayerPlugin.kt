package com.example.bare_player_plugin

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import com.google.android.exoplayer2.*
import com.google.android.exoplayer2.drm.*
import com.google.android.exoplayer2.metadata.Metadata
import com.google.android.exoplayer2.offline.Download
import com.google.android.exoplayer2.offline.DownloadRequest
import com.google.android.exoplayer2.offline.DownloadService
import com.google.android.exoplayer2.source.DefaultMediaSourceFactory
import com.google.android.exoplayer2.source.dash.DashMediaSource
import com.google.android.exoplayer2.source.dash.DashUtil
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource
import com.google.android.exoplayer2.upstream.cache.CacheDataSource
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch

/** BarePlayerPlugin */
class BarePlayerPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val tag = "TAG: BarePlayerPlugin"
    private var license: Pair<ByteArray?, Long>? = null
    var player: ExoPlayer? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "bare_player_plugin")
        channel.setMethodCallHandler(this)
        player = ExoPlayer.Builder(context)
            .build()
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {

        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else if (call.method == "play") {
            val url = call.argument<String>("url")

            if (url == null) {
                result.error("URL_NOT_FOUND", "URL not found", null)
                return
            }

            playAudio(url)

        } else if (call.method == "playDRMOnline") {

            val url = call.argument<String>("url")

            print ("url is $url")

            val licenseUrl = call.argument<String>("licenseUrl")

            if (url == null) {
                result.error("URL_NOT_FOUND", "URL not found", null)
                return
            }

            if (licenseUrl == null) {
                result.error("LICENSE_URL_NOT_FOUND", "License URL not found", null)
                return
            }

            print("player is $player")

            playAudioDrmOnline(
                url = url,
                licenseUrl = licenseUrl,
                player = player!!
            )

        } else if (call.method == "playDRMOffline") {
            val url = call.argument<String>("url")
            val licenseUrl = call.argument<String>("licenseUrl")
            val licenseKey = call.argument<String>("licenseKey")


            if (url == null) {
                result.error("URL_NOT_FOUND", "URL not found", null)
                return
            }

            if (licenseUrl == null) {
                result.error("LICENSE_URL_NOT_FOUND", "License URL not found", null)
                return
            }

            if (licenseKey == null) {
                result.error("LICENSE_KEY_NOT_FOUND", "License key not found", null)
                return
            }

            print("stopping player")
            print("player is playing ${player!!.isPlaying}")
            player!!.playWhenReady = false;
            player!!.stop();
            player!!.seekTo(0);

            print(player!!.isPlaying)

            playAudioDrmOffline(
                url = url,
                licenseUrl = licenseUrl,
                licenseKey = licenseKey,
                player = player!!,
            )

        } else if ( call.method == "stop") {
            player!!.stop()
        } else  {
            result.notImplemented()
        }
    }

    private fun playAudioDrmOffline(
        url: String,
        licenseUrl: String,
        player: ExoPlayer,
        licenseKey: String
    ) {
        print("playAudioDrmOffline")

        val downloadCache = DemoUtil.getDownloadCache(context)

        val dataSourceFactory = DemoUtil.getFileDataSourceFactory( /* context= */context)

        val cacheDataSourceFactory = CacheDataSource.Factory()
                .setCache(downloadCache !!)
                .setUpstreamDataSourceFactory(dataSourceFactory)
                .setCacheWriteDataSinkFactory(null)

        val licenseByteArray = licenseKey.toByteArray()

        val drmConfig =
            MediaItem.DrmConfiguration.Builder(C.WIDEVINE_UUID).setKeySetId(licenseByteArray)

                .setLicenseUri(licenseUrl)
        val mediaItem = MediaItem.Builder()
            .setUri(Uri.parse(url))
            .setDrmConfiguration(drmConfig.build())
        val mediaSourceFactory = DefaultMediaSourceFactory(context)
            .setDataSourceFactory(cacheDataSourceFactory)

        player.setMediaSource(mediaSourceFactory.createMediaSource(mediaItem.build()))
        player.prepare()
        player.addListener(listener)
        player.play()

        channel.invokeMethod("onUrlChanged", url)

    }


    private fun playAudioDrmOnline(url: String, licenseUrl: String, player: ExoPlayer) {
        try {
            print("playAudioDrmOnline")
            val defaultHttpDataSourceFactory = DefaultHttpDataSource.Factory()
            val drmConfig = MediaItem.DrmConfiguration.Builder(C.WIDEVINE_UUID)
                .setLicenseUri(licenseUrl)
            val mediaItem = MediaItem.Builder()
                .setUri(url)
                .setDrmConfiguration(drmConfig.build())
            val mediaSource = DashMediaSource.Factory(defaultHttpDataSourceFactory)
                .createMediaSource(mediaItem.build())
            GlobalScope.launch(Dispatchers.IO) {
                try {

                val method = "onKeyAvailable"
                license = downloadLicense(licenseUrl, Uri.parse(url))

                val licenseUrlString = license!!.first?.let { String(it) }

                val handler = Handler(Looper.getMainLooper())
                handler.post {
                    // Code to be executed on the UI thread
                    channel.invokeMethod(method, licenseUrlString)
                }

                val notificationChannelId = "com.bare_player_plugin"

                val downloadRequest = DownloadRequest.Builder(notificationChannelId, Uri.parse(url)).build()

                DownloadService.sendAddDownload(
                        context,
                        DemoDownloadService::class.java,
                        downloadRequest,
                        Download.STOP_REASON_NONE,
                        /* foreground= */ false
                )

                } catch (e: Exception) {
                    print("Download error is \n$e")
                }

            }

            player.setMediaSource(mediaSource)
            player.prepare()
            player.addListener(listener)
            player.play()

            channel.invokeMethod("onUrlChanged", url)

        } catch (
            e: Exception
        ) {
            print("error is $e")
        }


    }



    private fun downloadLicense(drmLicenseUrl: String, videoPath: Uri): Pair<ByteArray?, Long>? {
        print("downloadLicense")
        val okHttpDataSourceFactory = DefaultHttpDataSource.Factory()

        val offlineLicenseHelper = OfflineLicenseHelper.newWidevineInstance(
            drmLicenseUrl,
            okHttpDataSourceFactory, DrmSessionEventListener.EventDispatcher()
        )

        val dataSource = okHttpDataSourceFactory.createDataSource()
        val dashManifest = DashUtil.loadManifest(dataSource, videoPath)
        val drmInitData = DashUtil.loadFormatWithDrmInitData(dataSource, dashManifest.getPeriod(0))
        val licenseData = drmInitData?.let {
            offlineLicenseHelper.downloadLicense(it)
        }
        val licenseExpiration = if (licenseData != null) {
            System.currentTimeMillis() + (offlineLicenseHelper.getLicenseDurationRemainingSec(
                licenseData
            ).first * 1000)
        } else {
            0
        }
        return Pair(licenseData, licenseExpiration)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    ///method for playing audio
    private fun playAudio(@NonNull url: String) {
        val mediaItem: MediaItem = MediaItem.fromUri(url)
        player!!.setMediaItem(mediaItem)
        player!!.prepare()
        player!!.addListener(listener)
        player!!.play()

        channel.invokeMethod("onUrlChanged", url)
        print("mediaItem.mediaMetadata.artworkUri ${mediaItem.mediaMetadata.artworkUri}")

    }


    fun print(@NonNull messageToPrint: String) {
        Log.i(tag, messageToPrint)

    }

    /// listener for player
    private val listener = object : Player.Listener {
        override fun onPlaybackStateChanged(state: Int) {
            val method = "onPlaybackStateChanged"
            when (state) {
                Player.STATE_IDLE -> {
                    // The player does not have any media to play yet.
                    channel.invokeMethod(method, "Idle")
                }
                Player.STATE_BUFFERING -> {
                    // The player is buffering (loading the content)
                    channel.invokeMethod(method, "Buffering")
                }
                Player.STATE_READY -> {
                    // The player is ready to play.
                    channel.invokeMethod(method, "Ready to play")
                }
                Player.STATE_ENDED -> {
                    // The player has finished playing the media.
                    channel.invokeMethod(method, "Ended")
                }
            }
        }

        override fun onIsPlayingChanged(isPlaying: Boolean) {
            val method = "onIsPlayingChanged"

            print("isPlaying: $isPlaying")
            if (isPlaying) {
                channel.invokeMethod(method, "PLAYING")
            } else {
                channel.invokeMethod(method, "PAUSED")
            }
        }



    }
}
