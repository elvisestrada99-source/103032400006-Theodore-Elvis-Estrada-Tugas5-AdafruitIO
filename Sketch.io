#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>


const char* ssid = "Wokwi-GUEST";
const char* password = "";


#define DHTPIN 15
#define DHTTYPE DHT22
DHT dht(DHTPIN, DHTTYPE);


const char* mqtt_server = "io.adafruit.com";
const int mqtt_port = 1883;

const char* username = "ElvisEstrada";
const char* aio_key = "";

WiFiClient espClient;
PubSubClient client(espClient);

unsigned long previousMillis = 0;
const long interval = 20000;


void reconnect() {
  Serial.println("Mencoba koneksi Adafruit IO...");

  String clientId = "ESP32-" + String(random(0xffff), HEX);

  if (client.connect(clientId.c_str(), username, aio_key)) {
    Serial.println("MQTT TERHUBUNG!");
  } else {
    Serial.print("MQTT GAGAL. Status: ");
    Serial.println(client.state());
  }
}

void setup() {
  Serial.begin(115200);
  dht.begin();

  randomSeed(micros());

  Serial.print("Menghubungkan WiFi...");
  WiFi.begin(ssid, password, 6);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println();
  Serial.println("WiFi berhasil terhubung!");

  client.setServer(mqtt_server, mqtt_port);
  client.setKeepAlive(60);
  client.setSocketTimeout(15);
}

void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi terputus!");
    delay(1000);
    return;
  }

  if (!client.connected()) {
    reconnect();
  }

  client.loop();

  unsigned long currentMillis = millis();

  if (client.connected() &&
      currentMillis - previousMillis >= interval) {

    previousMillis = currentMillis;

    float suhu = dht.readTemperature();
    float kelembapan = dht.readHumidity();

    if (isnan(suhu) || isnan(kelembapan)) {
      Serial.println("Gagal membaca sensor DHT22!");
      return;
    }

    char temp[10];
    char hum[10];

    dtostrf(suhu, 1, 2, temp);
    dtostrf(kelembapan, 1, 2, hum);

    String topicSuhu = String(username) + "/feeds/suhu";
    String topicKelembapan = String(username) + "/feeds/kelembapan";

    bool kirimSuhu = client.publish(topicSuhu.c_str(), temp);
    bool kirimKelembapan = client.publish(topicKelembapan.c_str(), hum);

    Serial.println("-------------------------");
    Serial.print("Suhu: ");
    Serial.print(temp);
    Serial.println(" °C");

    Serial.print("Kelembapan: ");
    Serial.print(hum);
    Serial.println(" %");

    Serial.print("Pengiriman suhu: ");
    Serial.println(kirimSuhu ? "Berhasil" : "Gagal");

    Serial.print("Pengiriman kelembapan: ");
    Serial.println(kirimKelembapan ? "Berhasil" : "Gagal");

    Serial.println("-------------------------");
  }
}
