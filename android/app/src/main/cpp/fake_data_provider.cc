#include "fake_data_provider.h"
#include <android/log.h>
#include <cstring>
#include <fstream>
#include <random>
#include <sys/stat.h>
#include <unistd.h>

#define LOG_TAG "FakeDataProvider"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

namespace hyperguard {

FakeDataProvider &FakeDataProvider::instance() {
  static FakeDataProvider provider;
  return provider;
}

std::unordered_map<std::string, std::string>
FakeDataProvider::get_full_profile() {
  return {
      {"imei", get_fake_imei()},
      {"androidId", get_fake_android_id()},
      {"serial", get_fake_serial()},
      {"macAddress", get_fake_mac_address()},
      {"phoneNumber", get_fake_phone_number()},
      {"simSerial", get_fake_sim_serial()},
      {"latitude", "39.9042"},
      {"longitude", "116.4074"},
      {"deviceModel", "M2012K11AC"},
      {"manufacturer", "Xiaomi"},
      {"brand", "Redmi"},
      {"contactsCount", "0"},
      {"smsCount", "0"},
      {"callLogCount", "0"},
      {"photoCount", "0"},
      {"totalStorage", "0"},
      {"availableStorage", "0"},
      {"androidVersion", "14"},
      {"sdkVersion", "34"},
      {"isHyperOS", "true"},
      {"isRooted", "false"},
      {"isEmulator", "false"},
  };
}

std::string FakeDataProvider::get_fake_imei() {
  static std::random_device rd;
  static std::mt19937 gen(rd());
  static std::uniform_int_distribution<> dis(0, 9);
  std::string imei = "86626205";
  for (int i = 0; i < 7; i++) {
    imei += std::to_string(dis(gen));
  }
  return imei;
}

std::string FakeDataProvider::get_fake_android_id() {
  static std::random_device rd;
  static std::mt19937 gen(rd());
  static std::uniform_int_distribution<> dis(0, 15);
  const char *hex_chars = "0123456789abcdef";
  std::string android_id;
  for (int i = 0; i < 16; i++) {
    android_id += hex_chars[dis(gen)];
  }
  return android_id;
}

std::string FakeDataProvider::get_fake_serial() { return "0123456789ABCDEF"; }

std::string FakeDataProvider::get_fake_mac_address() {
  static std::random_device rd;
  static std::mt19937 gen(rd());
  static std::uniform_int_distribution<> dis(0, 255);
  char buffer[18];
  snprintf(buffer, sizeof(buffer), "02:%02x:%02x:%02x:%02x:%02x", dis(gen),
           dis(gen), dis(gen), dis(gen), dis(gen));
  return std::string(buffer);
}

std::string FakeDataProvider::get_fake_phone_number() {
  static std::random_device rd;
  static std::mt19937 gen(rd());
  static std::uniform_int_distribution<> dis(0, 9);
  std::string number = "+86138";
  for (int i = 0; i < 8; i++) {
    number += std::to_string(dis(gen));
  }
  return number;
}

std::string FakeDataProvider::get_fake_sim_serial() {
  static std::random_device rd;
  static std::mt19937 gen(rd());
  static std::uniform_int_distribution<> dis(0, 9);
  std::string sim = "898600";
  for (int i = 0; i < 14; i++) {
    sim += std::to_string(dis(gen));
  }
  return sim;
}

FakeLocation FakeDataProvider::get_fake_location() {
  return FakeLocation{39.9042, 116.4074, 0.0, 5.0f, 0};
}

std::vector<FakeContact> FakeDataProvider::get_fake_contacts() { return {}; }

std::vector<FakeSms> FakeDataProvider::get_fake_sms() { return {}; }

std::vector<FakeCallLog> FakeDataProvider::get_fake_call_logs() { return {}; }

bool FakeDataProvider::generate_fake_filesystem(const std::string &target_dir) {
  std::string dcim = target_dir + "/DCIM";
  std::string pictures = target_dir + "/Pictures";
  std::string downloads = target_dir + "/Download";
  std::string documents = target_dir + "/Documents";
  std::string music = target_dir + "/Music";

  mkdir(dcim.c_str(), 0755);
  mkdir(pictures.c_str(), 0755);
  mkdir(downloads.c_str(), 0755);
  mkdir(documents.c_str(), 0755);
  mkdir(music.c_str(), 0755);

  std::string motd_file = target_dir + "/.hyperguard_guard";
  std::ofstream motd(motd_file);
  if (motd.is_open()) {
    motd << "This is a HyperGuard sandbox environment.\n"
         << "All data is virtualized and no real device data is exposed.\n"
         << "Access time: " << time(nullptr) << "\n";
    motd.close();
  }

  LOGD("Fake filesystem generated at: %s", target_dir.c_str());
  return true;
}

} // namespace hyperguard
