#ifndef HYPERGUARD_BEHAVIOR_MONITOR_H
#define HYPERGUARD_BEHAVIOR_MONITOR_H

#include "sandbox_core.h"
#include <functional>
#include <mutex>
#include <string>
#include <unordered_map>

namespace hyperguard {

class BehaviorMonitor {
public:
  static BehaviorMonitor &instance();

  void set_behavior_callback(BehaviorCallback callback);
  void set_network_callback(NetworkCallback callback);
  void set_permission_callback(PermissionCallback callback);

  void start_monitoring(const std::string &app_id);
  void stop_monitoring(const std::string &app_id);

  void record_permission_request(const std::string &app_id,
                                 const std::string &permission, bool granted);

  void record_network_request(const std::string &app_id, const std::string &url,
                              const std::string &method, int status_code,
                              bool encrypted, const std::string &ip_address);

  void record_blocked_action(const std::string &app_id,
                             const std::string &action);

  void simulate_behavior_analysis(const std::string &app_id);

private:
  BehaviorMonitor() = default;
  ~BehaviorMonitor() = default;
  BehaviorMonitor(const BehaviorMonitor &) = delete;
  BehaviorMonitor &operator=(const BehaviorMonitor &) = delete;

  BehaviorCallback behavior_callback_;
  NetworkCallback network_callback_;
  PermissionCallback permission_callback_;
  std::mutex mutex_;
};

} // namespace hyperguard

#endif // HYPERGUARD_BEHAVIOR_MONITOR_H
