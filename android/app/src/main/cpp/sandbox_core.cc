#include "sandbox_core.h"
#include "behavior_monitor.h"
#include "fake_data_provider.h"
#include <android/log.h>
#include <chrono>
#include <iomanip>
#include <random>
#include <sstream>
#include <sys/stat.h>
#include <unistd.h>

#define LOG_TAG "HyperGuardNative"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

namespace hyperguard {

SandboxCore &SandboxCore::instance() {
  static SandboxCore core;
  return core;
}

bool SandboxCore::initialize(const std::string &sandbox_dir) {
  std::lock_guard<std::mutex> lock(mutex_);
  sandbox_dir_ = sandbox_dir;

  if (mkdir(sandbox_dir_.c_str(), 0755) != 0 && errno != EEXIST) {
    LOGE("Failed to create sandbox directory: %s", strerror(errno));
    return false;
  }

  std::string fake_data_path = sandbox_dir_ + "/fake_data";
  if (mkdir(fake_data_path.c_str(), 0755) != 0 && errno != EEXIST) {
    LOGE("Failed to create fake data directory: %s", strerror(errno));
    return false;
  }

  LOGD("Sandbox initialized at: %s", sandbox_dir_.c_str());
  return true;
}

bool SandboxCore::create_session(const std::string &app_id,
                                 const std::string &package_name,
                                 const std::string &app_name,
                                 const std::string &apk_path) {
  std::lock_guard<std::mutex> lock(mutex_);

  SandboxSession session;
  session.id = app_id;
  session.package_name = package_name;
  session.app_name = app_name;
  session.apk_path = apk_path;
  session.status = SandboxStatus::INITIALIZING;
  session.threat_level = ThreatLevel::SAFE;
  session.created_time =
      std::chrono::duration_cast<std::chrono::milliseconds>(
          std::chrono::system_clock::now().time_since_epoch())
          .count();
  session.permission_requests = 0;
  session.network_requests = 0;
  session.blocked_actions = 0;

  session.fake_data_profile =
      inject_fake_environment(app_id)
          ? FakeDataProvider::instance().get_full_profile()
          : FakeDataProvider::instance().get_full_profile();

  std::string session_dir = sandbox_dir_ + "/" + app_id;
  if (mkdir(session_dir.c_str(), 0755) != 0 && errno != EEXIST) {
    LOGE("Failed to create session directory: %s", strerror(errno));
    return false;
  }

  sessions_[app_id] = session;
  LOGD("Sandbox session created: %s (%s)", app_name.c_str(),
       package_name.c_str());
  return true;
}

bool SandboxCore::start_analysis(const std::string &app_id) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = sessions_.find(app_id);
  if (it == sessions_.end())
    return false;

  it->second.status = SandboxStatus::ANALYZING;

  BehaviorMonitor::instance().start_monitoring(app_id);

  report_behavior(app_id, "privacy_access",
                  "Sandbox session started - all data sources are virtualized",
                  "info");

  LOGD("Analysis started for session: %s", app_id.c_str());
  return true;
}

bool SandboxCore::stop_session(const std::string &app_id) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = sessions_.find(app_id);
  if (it == sessions_.end())
    return false;

  it->second.status = SandboxStatus::STOPPED;
  BehaviorMonitor::instance().stop_monitoring(app_id);
  LOGD("Session stopped: %s", app_id.c_str());
  return true;
}

bool SandboxCore::terminate_session(const std::string &app_id) {
  std::lock_guard<std::mutex> lock(mutex_);
  BehaviorMonitor::instance().stop_monitoring(app_id);
  sessions_.erase(app_id);

  std::string session_dir = sandbox_dir_ + "/" + app_id;

  LOGD("Session terminated: %s", app_id.c_str());
  return true;
}

SandboxSession *SandboxCore::get_session(const std::string &app_id) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = sessions_.find(app_id);
  return it != sessions_.end() ? &it->second : nullptr;
}

std::vector<SandboxSession> SandboxCore::get_active_sessions() {
  std::lock_guard<std::mutex> lock(mutex_);
  std::vector<SandboxSession> active;
  for (const auto &pair : sessions_) {
    if (pair.second.status == SandboxStatus::RUNNING ||
        pair.second.status == SandboxStatus::ANALYZING ||
        pair.second.status == SandboxStatus::INITIALIZING) {
      active.push_back(pair.second);
    }
  }
  return active;
}

void SandboxCore::set_behavior_callback(BehaviorCallback callback) {
  std::lock_guard<std::mutex> lock(mutex_);
  behavior_callback_ = std::move(callback);
  BehaviorMonitor::instance().set_behavior_callback(callback);
}

void SandboxCore::set_network_callback(NetworkCallback callback) {
  std::lock_guard<std::mutex> lock(mutex_);
  network_callback_ = std::move(callback);
  BehaviorMonitor::instance().set_network_callback(callback);
}

void SandboxCore::set_permission_callback(PermissionCallback callback) {
  std::lock_guard<std::mutex> lock(mutex_);
  permission_callback_ = std::move(callback);
  BehaviorMonitor::instance().set_permission_callback(callback);
}

int SandboxCore::calculate_threat_score(const std::string &app_id) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = sessions_.find(app_id);
  if (it == sessions_.end())
    return 0;

  const auto &session = it->second;
  int score = 0;

  score += session.permission_requests * 10;
  score += session.network_requests * 5;
  score += session.blocked_actions * 15;

  for (const auto &perm : session.permissions) {
    if (perm.risk_level == "dangerous" || perm.risk_level == "high") {
      score += 10;
    }
  }

  for (const auto &net : session.networks) {
    if (!net.encrypted) {
      score += 8;
    }
  }

  return std::min(score, 100);
}

std::unordered_map<std::string, std::string>
SandboxCore::get_fake_data_profile(const std::string &app_id) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = sessions_.find(app_id);
  if (it != sessions_.end()) {
    return it->second.fake_data_profile;
  }
  return FakeDataProvider::instance().get_full_profile();
}

bool SandboxCore::inject_fake_environment(const std::string &app_id) {
  std::string session_dir = sandbox_dir_ + "/" + app_id;
  std::string fake_data_dir = session_dir + "/fake_env";

  if (mkdir(fake_data_dir.c_str(), 0755) != 0 && errno != EEXIST) {
    LOGE("Failed to create fake env directory: %s", strerror(errno));
    return false;
  }

  FakeDataProvider::instance().generate_fake_filesystem(fake_data_dir);
  LOGD("Fake environment injected for: %s", app_id.c_str());
  return true;
}

void SandboxCore::report_behavior(const std::string &app_id,
                                  const std::string &event_type,
                                  const std::string &description,
                                  const std::string &severity) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = sessions_.find(app_id);
  if (it != sessions_.end()) {
    BehaviorEvent event;
    event.event_type = event_type;
    event.description = description;
    event.severity = severity;
    event.timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(
                          std::chrono::system_clock::now().time_since_epoch())
                          .count();
    it->second.behaviors.push_back(event);
  }

  if (behavior_callback_) {
    behavior_callback_(app_id, event_type, description, severity);
  }
}

void SandboxCore::report_network(const std::string &app_id,
                                 const std::string &url,
                                 const std::string &method, int status_code) {
  if (network_callback_) {
    network_callback_(app_id, url, method, status_code);
  }
}

void SandboxCore::report_permission(const std::string &app_id,
                                    const std::string &permission,
                                    bool granted) {
  if (permission_callback_) {
    permission_callback_(app_id, permission, granted);
  }
}

std::string SandboxCore::generate_fake_imei() {
  static std::random_device rd;
  static std::mt19937 gen(rd());
  static std::uniform_int_distribution<> dis(0, 9);
  std::string imei = "86626205";
  for (int i = 0; i < 7; i++) {
    imei += std::to_string(dis(gen));
  }
  return imei;
}

std::string SandboxCore::generate_fake_android_id() {
  static std::random_device rd;
  static std::mt19937 gen(rd());
  static std::uniform_int_distribution<> dis(0, 15);
  std::string hex = "0123456789abcdef";
  std::string android_id;
  for (int i = 0; i < 16; i++) {
    android_id += hex[dis(gen)];
  }
  return android_id;
}

std::string SandboxCore::generate_fake_serial() { return "unknown_device"; }

} // namespace hyperguard
