#ifndef HYPERGUARD_SANDBOX_CORE_H
#define HYPERGUARD_SANDBOX_CORE_H

#include <string>
#include <unordered_map>
#include <vector>
#include <mutex>
#include <functional>

namespace hyperguard {

enum class ThreatLevel {
    SAFE = 0,
    SUSPICIOUS = 1,
    DANGEROUS = 2,
    MALICIOUS = 3
};

enum class SandboxStatus {
    IDLE = 0,
    INITIALIZING = 1,
    RUNNING = 2,
    ANALYZING = 3,
    STOPPED = 4,
    ERROR = 5
};

struct PermissionRequest {
    std::string permission;
    bool granted;
    uint64_t timestamp;
    std::string risk_level;
};

struct NetworkRequest {
    std::string url;
    std::string method;
    int status_code;
    uint64_t timestamp;
    bool encrypted;
    std::string ip_address;
};

struct BehaviorEvent {
    std::string event_type;
    std::string description;
    std::string severity;
    uint64_t timestamp;
};

class SandboxSession {
public:
    std::string id;
    std::string package_name;
    std::string app_name;
    std::string apk_path;
    SandboxStatus status;
    ThreatLevel threat_level;
    uint64_t created_time;
    uint64_t completed_time;
    int permission_requests;
    int network_requests;
    int blocked_actions;
    std::vector<PermissionRequest> permissions;
    std::vector<NetworkRequest> networks;
    std::vector<BehaviorEvent> behaviors;
    std::unordered_map<std::string, std::string> fake_data_profile;
};

using BehaviorCallback = std::function<void(const std::string& app_id,
                                              const std::string& event_type,
                                              const std::string& description,
                                              const std::string& severity)>;

using NetworkCallback = std::function<void(const std::string& app_id,
                                             const std::string& url,
                                             const std::string& method,
                                             int status_code)>;

using PermissionCallback = std::function<void(const std::string& app_id,
                                                const std::string& permission,
                                                bool granted)>;

class SandboxCore {
public:
    static SandboxCore& instance();

    bool initialize(const std::string& sandbox_dir);
    bool create_session(const std::string& app_id,
                        const std::string& package_name,
                        const std::string& app_name,
                        const std::string& apk_path);
    bool start_analysis(const std::string& app_id);
    bool stop_session(const std::string& app_id);
    bool terminate_session(const std::string& app_id);
    SandboxSession* get_session(const std::string& app_id);
    std::vector<SandboxSession> get_active_sessions();

    void set_behavior_callback(BehaviorCallback callback);
    void set_network_callback(NetworkCallback callback);
    void set_permission_callback(PermissionCallback callback);

    int calculate_threat_score(const std::string& app_id);

    std::unordered_map<std::string, std::string> get_fake_data_profile(const std::string& app_id);
    bool inject_fake_environment(const std::string& app_id);

private:
    SandboxCore() = default;
    ~SandboxCore() = default;
    SandboxCore(const SandboxCore&) = delete;
    SandboxCore& operator=(const SandboxCore&) = delete;

    void report_behavior(const std::string& app_id,
                         const std::string& event_type,
                         const std::string& description,
                         const std::string& severity);

    void report_network(const std::string& app_id,
                        const std::string& url,
                        const std::string& method,
                        int status_code);

    void report_permission(const std::string& app_id,
                           const std::string& permission,
                           bool granted);

    std::string generate_fake_imei();
    std::string generate_fake_android_id();
    std::string generate_fake_serial();

    std::mutex mutex_;
    std::string sandbox_dir_;
    std::unordered_map<std::string, SandboxSession> sessions_;
    BehaviorCallback behavior_callback_;
    NetworkCallback network_callback_;
    PermissionCallback permission_callback_;
};

} // namespace hyperguard

#endif // HYPERGUARD_SANDBOX_CORE_H
