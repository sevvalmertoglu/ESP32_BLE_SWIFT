#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

#define SERVICE_UUID        "0000ffe0-0000-1000-8000-00805f9b34fb"
#define CHARACTERISTIC_UUID "0000ffe1-0000-1000-8000-00805f9b34fb"

// I2C adresi 0x27 olan 16x2 LCD ekran
LiquidCrystal_I2C lcd(0x27, 16, 2);

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;
bool prevDeviceConnected = false;

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
    }
};

class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string rxValue = pCharacteristic->getValue();

      if (rxValue.length() > 0) {
        Serial.println("*********");
        Serial.print("Received Value: ");
        for (int i = 0; i < rxValue.length(); i++) {
          Serial.print(rxValue[i]);
        }
        Serial.println();

        // Komutu işleyip LCD'ye yazdırır
        if (rxValue == "ON") {
          Serial.println("ON Command Received");
          lcd.clear();
          lcd.print("ON");
        } else if (rxValue == "OFF") {
          Serial.println("OFF Command Received");
          lcd.clear();
          lcd.print("OFF");
        }
      }
    }
};

void setup() {
  Serial.begin(115200);

  // LCD başlatma
  lcd.init();
  lcd.backlight();
  lcd.print("Waiting for a");
  lcd.setCursor(0, 1);
  lcd.print("client conn...");

  BLEDevice::init("ESP32 BLE Sevval");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ |
                      BLECharacteristic::PROPERTY_WRITE |
                      BLECharacteristic::PROPERTY_NOTIFY |
                      BLECharacteristic::PROPERTY_INDICATE
                    );

  pCharacteristic->setCallbacks(new MyCallbacks());
  pCharacteristic->addDescriptor(new BLE2902());

  pService->start();

  pServer->getAdvertising()->start();
  Serial.println("Waiting for a client connection to notify...");
}

void loop() {
  if (deviceConnected && !prevDeviceConnected) {
    // Bağlantı başarılı 
    Serial.println("Connection successful");
    lcd.clear();
    lcd.print("Connection");
    lcd.setCursor(0, 1);
    lcd.print("successful");
    prevDeviceConnected = deviceConnected;
  } else if (!deviceConnected && prevDeviceConnected) {
    // Bağlantı kesildiğinde
    Serial.println("Waiting for a client connection to notify...");
    lcd.clear();
    lcd.print("Waiting for a");
    lcd.setCursor(0, 1);
    lcd.print("client conn...");
    prevDeviceConnected = deviceConnected;
  }

  delay(1000);
}
