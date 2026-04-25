#ifndef HYPERGUARD_FAKE_DATA_PROVIDER_H
#define HYPERGUARD_FAKE_DATA_PROVIDER_H

#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

namespace hyperguard {

struct FakeContact {
  std::string name;
  std::string phone_number;
  std::string email;
};

struct FakeSms {
  std::string address;
  std::string body;
  uint64_t timestamp;
  int type;
};

struct FakeCallLog {
  std::string number;
  uint64_t timestamp;
  int type;
  int duration;
};

struct FakeLocation {
  double latitude;
  double longitude;
  double altitude;
  float accuracy;
  uint64_t timestamp;
};

class FakeDataProvider {
public:
  static FakeDataProvider &instance();

  std::unordered_map<std::string, std::string> get_full_profile();

  std::string get_fake_imei();
  std::string get_fake_android_id();
  std::string get_fake_serial();
  std::string get_fake_mac_address();
  std::string get_fake_phone_number();
  std::string get_fake_sim_serial();

  FakeLocation get_fake_location();

  std::vector<FakeContact> get_fake_contacts();
  std::vector<FakeSms> get_fake_sms();
  std::vector<FakeCallLog> get_fake_call_logs();

  bool generate_fake_filesystem(const std::string &target_dir);

private:
  FakeDataProvider() = default;
  ~FakeDataProvider() = default;
  FakeDataProvider(const FakeDataProvider &) = delete;
  FakeDataProvider &operator=(const FakeDataProvider &) = delete;

  std::mutex mutex_;
};

} // namespace hyperguard

#endif // HYPERGUARD_FAKE_DATA_PROVIDER_H
