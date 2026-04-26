#include "behavior_monitor.h"
#include <android/log.h>
#include <ctime>

#define LOG_TAG "BehaviorMonitor"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

namespace hyperguard {

BehaviorMonitor &BehaviorMonitor::instance() {
  static BehaviorMonitor monitor;
  return monitor;
}

void BehaviorMonitor::set_behavior_callback(BehaviorCallback callback) {
  std::lock_guard<std::mutex> lock(mutex_);
  behavior_callback_ = std::move(callback);
}

void BehaviorMonitor::set_network_callback(NetworkCallback callback) {
  std::lock_guard<std::mutex> lock(mutex_);
  network_callback_ = std::move(callback);
}

void BehaviorMonitor::set_permission_callback(PermissionCallback callback) {
  std::lock_guard<std::mutex> lock(mutex_);
  permission_callback_ = std::move(callback);
}

void BehaviorMonitor::start_monitoring(const std::string &app_id) {
  LOGD("Started monitoring: %s", app_id.c_str());
}

void BehaviorMonitor::stop_monitoring(const std::string &app_id) {
  LOGD("Stopped monitoring: %s", app_id.c_str());
}

void BehaviorMonitor::record_permission_request(const std::string &app_id,
                                                const std::string &permission,
                                                bool granted) {
  if (permission_callback_) {
    permission_callback_(app_id, permission, granted);
  }

  if (behavior_callback_) {
    std::string desc = "Permission " +
                       std::string(granted ? "granted" : "denied") + ": " +
                       permission + " (fake data returned)";
    behavior_callback_(app_id, "permission_access", desc, "medium");
  }
}

void BehaviorMonitor::record_network_request(const std::string &app_id,
                                             const std::string &url,
                                             const std::string &method,
                                             int status_code, bool encrypted,
                                             const std::string &ip_address) {
  if (network_callback_) {
    network_callback_(app_id, url, method, status_code);
  }

  if (behavior_callback_) {
    std::string desc =
        "Network " + method + " " + url + " -> " + std::to_string(status_code);
    behavior_callback_(app_id, "network_request", desc, "low");
  }
}

void BehaviorMonitor::record_blocked_action(const std::string &app_id,
                                            const std::string &action) {
  if (behavior_callback_) {
    behavior_callback_(app_id, "blocked_action",
                       "Blocked sensitive action: " + action, "high");
  }
}

void BehaviorMonitor::simulate_behavior_analysis(const std::string &app_id) {
  uint64_t now = static_cast<uint64_t>(time(nullptr)) * 1000;

  record_permission_request(app_id, "android.permission.READ_CONTACTS", false);
  record_permission_request(app_id, "android.permission.READ_SMS", false);
  record_permission_request(app_id, "android.permission.ACCESS_FINE_LOCATION",
                            false);
  record_permission_request(app_id, "android.permission.READ_PHONE_STATE",
                            false);

  record_network_request(app_id, "https://unknown-server.com/api/data", "POST",
                         0, false, "192.168.1.100");
  record_network_request(app_id, "https://tracking.example.com/collect", "GET",
                         0, false, "10.0.2.2");

  record_blocked_action(app_id, "Attempt to read real contacts database");
  record_blocked_action(app_id, "Attempt to access real SMS inbox");
  record_blocked_action(app_id, "Attempt to get real GPS location");

  if (behavior_callback_) {
    behavior_callback_(
        app_id, "sandbox_summary",
        "Behavior analysis complete. All sensitive data requests "
        "were served with fake data. No real user data was exposed.",
        "info");
  }
}

} // namespace hyperguard
