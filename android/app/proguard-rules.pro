# TensorFlow Lite
-keep class org.tensorflow.** { *; }
-keep interface org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# TensorFlow Lite GPU Delegate
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options

# Keep TFLite native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
