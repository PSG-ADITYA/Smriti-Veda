package com.example.smriti_veda

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread
import kotlin.math.sin

class MainActivity : FlutterActivity() {
    private val CHANNEL = "smriti_veda/audio_tone"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "playTone") {
                val frequency = call.argument<Double>("frequency") ?: 440.0
                val durationMs = call.argument<Int>("durationMs") ?: 400
                val volume = call.argument<Double>("volume") ?: 0.9
                playSynthesizedTone(frequency, durationMs, volume)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun playSynthesizedTone(frequency: Double, durationMs: Int, volume: Double) {
        thread(start = true) {
            try {
                val sampleRate = 22050
                val numSamples = (sampleRate * (durationMs / 1000.0)).toInt()
                val generatedSnd = ShortArray(numSamples)

                val attackSamples = (sampleRate * 0.02).toInt().coerceAtMost(numSamples / 4)
                val releaseSamples = (sampleRate * 0.06).toInt().coerceAtMost(numSamples / 4)

                for (i in 0 until numSamples) {
                    val angle = 2.0 * Math.PI * i / (sampleRate / frequency)
                    var amp = volume
                    if (i < attackSamples) {
                        amp *= (i.toDouble() / attackSamples)
                    } else if (i > numSamples - releaseSamples) {
                        amp *= ((numSamples - i).toDouble() / releaseSamples)
                    }
                    val sample = (sin(angle) * amp * 32767.0).toInt().coerceIn(-32768, 32767)
                    generatedSnd[i] = sample.toShort()
                }

                val audioTrack = AudioTrack.Builder()
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_MEDIA)
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .build()
                    )
                    .setAudioFormat(
                        AudioFormat.Builder()
                            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                            .setSampleRate(sampleRate)
                            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                            .build()
                    )
                    .setBufferSizeInBytes(generatedSnd.size * 2)
                    .setTransferMode(AudioTrack.MODE_STATIC)
                    .build()

                audioTrack.setVolume(1.0f)
                audioTrack.write(generatedSnd, 0, generatedSnd.size)
                audioTrack.play()

                Thread.sleep(durationMs.toLong() + 30)
                audioTrack.stop()
                audioTrack.release()
            } catch (e: Exception) {
                // Ignore audio track exceptions gracefully
            }
        }
    }
}
