#include "behavior_monitor.h"
#include "fake_data_provider.h"
#include "sandbox_core.h"
#include <android/log.h>
#include <jni.h>
#include <string>
#include <unordered_map>

#define LOG_TAG "HyperGuardJNI"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

static JavaVM *g_jvm = nullptr;
static jobject g_flutter_callback = nullptr;

static std::string jstring_to_string(JNIEnv *env, jstring jstr) {
  if (!jstr)
    return "";
  const char *chars = env->GetStringUTFChars(jstr, nullptr);
  std::string result(chars);
  env->ReleaseStringUTFChars(jstr, chars);
  return result;
}

static jstring string_to_jstring(JNIEnv *env, const std::string &str) {
  return env->NewStringUTF(str.c_str());
}

extern "C" {

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
  g_jvm = vm;
  LOGD("HyperGuard native library loaded");
  return JNI_VERSION_1_6;
}

JNIEXPORT void JNICALL
Java_xin_ctkqiang_hyper_guard_HyperGuardNative_nativeSetFlutterCallback(
    JNIEnv *env, jobject thiz, jobject callback) {
  if (g_flutter_callback) {
    env->DeleteGlobalRef(g_flutter_callback);
  }
  g_flutter_callback = env->NewGlobalRef(callback);
  LOGD("Flutter callback registered");
}

JNIEXPORT jboolean JNICALL
Java_xin_ctkqiang_hyper_guard_HyperGuardNative_nativeInit(JNIEnv *env,
                                                          jobject thiz,
                                                          jstring sandbox_dir) {
  std::string dir = jstring_to_string(env, sandbox_dir);
  bool result = hyperguard::SandboxCore::instance().initialize(dir);
  LOGD("Native sandbox initialized: %s (success=%d)", dir.c_str(), result);
  return result ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT jboolean JNICALL
Java_xin_ctkqiang_hyper_guard_HyperGuardNative_nativeSessionCreate(
    JNIEnv *env, jobject thiz, jstring app_id, jstring package_name,
    jstring app_name, jstring apk_path) {
  std::string id = jstring_to_string(env, app_id);
  std::string pkg = jstring_to_string(env, package_name);
  std::string name = jstring_to_string(env, app_name);
  std::string path = jstring_to_string(env, apk_path);

  bool result =
      hyperguard::SandboxCore::instance().create_session(id, pkg, name, path);
  LOGD("Session created: %s (success=%d)", id.c_str(), result);
  return result ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT jboolean JNICALL
Java_xin_ctkqiang_hyper_guard_HyperGuardNative_nativeAnalysisStart(
    JNIEnv *env, jobject thiz, jstring app_id) {
  std::string id = jstring_to_string(env, app_id);
  bool result = hyperguard::SandboxCore::instance().start_analysis(id);

  hyperguard::BehaviorMonitor::instance().simulate_behavior_analysis(id);

  LOGD("Analysis started: %s (success=%d)", id.c_str(), result);
  return result ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT jboolean JNICALL
Java_xin_ctkqiang_hyper_guard_HyperGuardNative_nativeSessionStop(
    JNIEnv *env, jobject thiz, jstring app_id) {
  std::string id = jstring_to_string(env, app_id);
  bool result = hyperguard::SandboxCore::instance().stop_session(id);
  LOGD("Session stopped: %s", id.c_str());
  return result ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT jboolean JNICALL
Java_xin_ctkqiang_hyper_guard_HyperGuardNative_nativeSessionTerminate(
    JNIEnv *env, jobject thiz, jstring app_id) {
  std::string id = jstring_to_string(env, app_id);
  bool result = hyperguard::SandboxCore::instance().terminate_session(id);
  LOGD("Session terminated: %s", id.c_str());
  return result ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT jint JNICALL
Java_xin_ctkqiang_hyper_guard_HyperGuardNative_nativeThreatScore(
    JNIEnv *env, jobject thiz, jstring app_id) {
  std::string id = jstring_to_string(env, app_id);
  int score = hyperguard::SandboxCore::instance().calculate_threat_score(id);
  return static_cast<jint>(score);
}

JNIEXPORT jobject JNICALL
Java_xin_ctkqiang_hyper_guard_HyperGuardNative_nativeFakeProfile(JNIEnv *env,
                                                                 jobject thiz) {
  auto profile = hyperguard::FakeDataProvider::instance().get_full_profile();

  jclass map_class = env->FindClass("java/util/HashMap");
  jmethodID map_init = env->GetMethodID(map_class, "<init>", "()V");
  jmethodID map_put = env->GetMethodID(
      map_class, "put",
      "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;");

  jobject map = env->NewObject(map_class, map_init);
  for (const auto &pair : profile) {
    jstring key = string_to_jstring(env, pair.first);
    jstring value = string_to_jstring(env, pair.second);
    env->CallObjectMethod(map, map_put, key, value);
    env->DeleteLocalRef(key);
    env->DeleteLocalRef(value);
  }

  return map;
}

JNIEXPORT jstring JNICALL
Java_xin_ctkqiang_hyper_guard_HyperGuardNative_nativeFakeImei(JNIEnv *env,
                                                              jobject thiz) {
  return string_to_jstring(
      env, hyperguard::FakeDataProvider::instance().get_fake_imei());
}

JNIEXPORT jstring JNICALL
Java_xin_ctkqiang_hyper_guard_HyperGuardNative_nativeFakeAndroidId(
    JNIEnv *env, jobject thiz) {
  return string_to_jstring(
      env, hyperguard::FakeDataProvider::instance().get_fake_android_id());
}

} // extern "C"
