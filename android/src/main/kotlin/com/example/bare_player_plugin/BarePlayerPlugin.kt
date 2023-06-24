package com.example.bare_player_plugin

import android.content.Context
import android.content.res.AssetFileDescriptor
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
import com.google.android.exoplayer2.source.MediaSource
import com.google.android.exoplayer2.source.TrackGroupArray
import com.google.android.exoplayer2.source.dash.DashMediaSource
import com.google.android.exoplayer2.source.dash.DashUtil
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource
import com.google.android.exoplayer2.upstream.cache.CacheDataSource
import com.google.common.util.concurrent.FutureCallback
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import wseemann.media.FFmpegMediaMetadataRetriever
import java.io.IOException
import java.util.concurrent.Executor
import java.util.concurrent.Executors


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
        val methodCall = call.method

        if (methodCall == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else if (methodCall == "play") {
            val url =
                 call.argument<String>("url")

            if (url == null) {
                result.error("URL_NOT_FOUND", "URL not found", null)
                return
            }

            playAudio(url)

        } else if (methodCall == "playDRMOnline") {

            val url = call.argument<String>("url")

            print("url is $url")

            val licenseUrl = call.argument<String>("licenseUrl")


            val licenseRequestHeader: Map<String, String>? =
                call.argument<Map<String, String>>("licenseRequestHeader")
            print("licenseRequestHeader is $licenseRequestHeader")

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
                licenseRequestHeader = licenseRequestHeader,
                player = player!!
            )


        } else if (methodCall == "playDRMOffline") {
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

        } else if (methodCall == "stop") {
            player!!.stop()
        } else if (methodCall == "seekToPosition") {
            val position = call.argument<Int>("seconds")

            print("seeking to $position")

            player!!.seekTo(1000 * position!!.toLong())

        } else if (methodCall == "pause"){
            print ("pausing")

            player!!.pause()

        } else if (methodCall == "resume") {
            player!!.play()
        } else {
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
            .setCache(downloadCache!!)
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
        val mediaSource = mediaSourceFactory.createMediaSource(mediaItem.build())

        preparePlayerAndPlay(player, mediaSource, url)

        channel.invokeMethod("onUrlChanged", url)

    }


    private fun playAudioDrmOnline(
        url: String,
        licenseUrl: String,
        licenseRequestHeader: Map<String, String>?,
        player: ExoPlayer
    ) {
        try {
            print("playAudioDrmOnline")
            val defaultHttpDataSourceFactory = DefaultHttpDataSource.Factory()

            var drmConfig: MediaItem.DrmConfiguration.Builder
            if (licenseRequestHeader != null) {
                drmConfig = MediaItem.DrmConfiguration.Builder(C.WIDEVINE_UUID)
                    .setLicenseUri(licenseUrl)
                    .setLicenseRequestHeaders(licenseRequestHeader)
            } else {
                drmConfig = MediaItem.DrmConfiguration.Builder(C.WIDEVINE_UUID)
                    .setLicenseUri(licenseUrl)
            }

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

                    val downloadRequest =
                        DownloadRequest.Builder(notificationChannelId, Uri.parse(url)).build()

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

            preparePlayerAndPlay(player, mediaSource, url)

            channel.invokeMethod("onUrlChanged", url)

        } catch (
            e: Exception
        ) {
            print("error is $e")
        }
    }

    private fun preparePlayerAndPlay(player: ExoPlayer, mediaSource: MediaSource, url: String) {
        player.run {
            setMediaSource(mediaSource)
            prepare()
            addListener(getListener(url))
            play()
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
        player!!.addListener(getListener(url))
        player!!.play()

        channel.invokeMethod("onUrlChanged", url)

    }


    fun print(@NonNull messageToPrint: String) {
        Log.i(tag, messageToPrint)

    }

    /// listener for player
    private fun getListener(url: String): Player.Listener {
        return object : Player.Listener {
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
                        extractMetadata(url)

                        val onDurationChangedMethod = "onDurationChanged"

                        val duration = player!!.duration

                        channel.invokeMethod(onDurationChangedMethod, duration)
                    }
                    Player.STATE_ENDED -> {
                        // The player has finished playing the media.
                        channel.invokeMethod(method, "Ended")
                    }
                }

                super.onPlaybackStateChanged(state)
            }

            override fun onIsPlayingChanged(isPlaying: Boolean) {
                val method = "onIsPlayingChanged"

                print("isPlaying: $isPlaying")
                if (isPlaying) {
                    channel.invokeMethod(method, "PLAYING")
                } else {
                    channel.invokeMethod(method, "PAUSED")
                }

                super.onIsPlayingChanged(isPlaying)
            }

            override fun onEvents(player: Player, events: Player.Events) {
                print(player.mediaMetadata)
            }

            override fun onMediaMetadataChanged(mediaMetadata: MediaMetadata) {
                print("metadata")
                mediaMetadata.title?.let(::handleTitle)
            }

            override fun onMetadata(metadata: Metadata) {
                print("metadata")
                print(metadata)
            }


        }
    }

    fun handleTitle(title: CharSequence) {
        print("metadata ")
        print(title);
    }

    fun tryFindingErrorSource(url: String) {
        GlobalScope.launch(Dispatchers.IO) {

            try {
                var fd: AssetFileDescriptor? = null
                val uri = Uri.parse(url)

                try {
                    val resolver = context.contentResolver
                    fd = try {
                        resolver.openAssetFileDescriptor(uri, "r")
                    } catch (e: Exception) {
                        print("***********\ntryFindingErrorSource | e: $e | uri: $uri")
                        throw IllegalArgumentException()
                    }
                    requireNotNull(fd)
                    print("***********\ntryFindingErrorSource | fd: $fd")
                    val descriptor = fd!!.fileDescriptor
                    print("***********\ntryFindingErrorSource | descriptor: $descriptor")
                    require(descriptor.valid())
                    if (fd!!.declaredLength < 0L) {
                        print("***********\ntryFindingErrorSource | fd!!.declaredLength < 0L")
                    } else {
                        print("***********\ntryFindingErrorSource | fd!!.declaredLength >= 0L")
                    }
                } catch (var18: SecurityException) {
                    Log.e("FMMR", "SecurityException: ", var18)

                } finally {
                    try {
                        if (fd != null) {
                            fd!!.close()
                        }
                    } catch (var16: IOException) {
                        Log.e("FMMR", "IOException: ", var16)
                    }
                }
            } catch (e: Exception) {
                print("***********\ntryFindingErrorSource | error: $e")
            }
        }
    }

    fun extractMetadata(url: String) {

        if (true) {
            print("***********\nextractMetadata | player: $player")

            player?.mediaMetadata?.let {
                print("***********\nextractMetadata | mediaMetadata: ${it}")
            }

            val mediaItem = player?.currentMediaItem
            val executor: Executor = Executors.newSingleThreadExecutor()


            val trackGroupsFuture: ListenableFuture<TrackGroupArray> =
                MetadataRetriever.retrieveMetadata(context, mediaItem!!)
            Futures.addCallback(
                trackGroupsFuture,
                object : FutureCallback<TrackGroupArray> {
                    override fun onSuccess(trackGroups: TrackGroupArray) {
                        for (i in 0 until trackGroups.length) {
                            val trackGroup = trackGroups.get(i)

                            for (j in 0 until trackGroup.length) {
                                val trackMetadata: Metadata? = trackGroup.getFormat(j)?.metadata
                                if (trackMetadata != null) {
                                    print(trackMetadata)
                                }
                            }

                        }


                    }

                    override fun onFailure(t: Throwable) {
                        print(t)
                    }
                },
                executor
            )

            /// get chapters from metadata


        }

        if (false) {
            tryFindingErrorSource(url)
        } else {
        }

        if (false) {
            try {
                val url =
                    "https://1cdb1f9f9b7a67ca92aaa815.blob.core.windows.net/video-output/8p4Fq8kD4smqzbExdQTPwt/cmaf/manifest.mpd"
                print("***********\nextractMetadata")
                val mmr = FFmpegMediaMetadataRetriever()
                mmr.setDataSource(url, HashMap<String, String>())
                print("***********\nextractMetadata setDataSource")

                val chapterCount =
                    mmr.extractMetadata(FFmpegMediaMetadataRetriever.METADATA_CHAPTER_COUNT).toInt()
                print("***********\nextractMetadata | chapterCount: $chapterCount")

                for (i in 0 until chapterCount) {
                    val title =
                        mmr.extractMetadataFromChapter(
                            FFmpegMediaMetadataRetriever.METADATA_KEY_TITLE,
                            i
                        )
                    if (title != null) {
                        print("***********\nextractMetadata | chapter title: $title")
                    }
                }
            } catch (e: Exception) {
                print("***********\nextractMetadata | error is: $e end")
            }
        }


    }
}
