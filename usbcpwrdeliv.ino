/*
  Writing New Settings to the STUSB4500 Power Delivery Board
  By: Alex Wende
  SparkFun Electronics
  Date: February 6th, 2020
  License: This code is public domain but you buy me a beer if you use this and we meet someday (Beerware license).
  Feel like supporting our work? Buy a board from SparkFun!
  https://www.sparkfun.com/products/15801

  This example demonstrates how to write new NVM settings to the STUSB4500

  Quick-start:
  - Use a SparkFun RedBoard Qwiic -or- attach the Qwiic Shield to your Arduino/Photon/ESP32 or other
  - Upload example sketch
  - Plug the Power Delivery Board onto the RedBoard/shield
  - Open the serial monitor and set the baud rate to 115200
  - The RedBoard will connect to the Power Delivery Board over I2C write the settings:
    * PDO Number: 3
    * PDO3 Voltage: 15.00V
    * PDO3 Current: 0.5A
    * PDO3 Under Voltage Lock Out: 20%
    * PDO3 Over Voltage Lock Out: 20%
  - After the settings are written, the old settings are printed out and then the new settings are printed  
*/
// Include the SparkFun STUSB4500 library.
// Click here to get the library: http://librarymanager/All#SparkFun_STUSB4500

#include <Wire.h>
#include <SparkFun_STUSB4500.h>

STUSB4500 usb;

void setup()
{
  Serial.begin(115200);
  Wire.begin(); //Join I2C Bus
  delay(500);

  /* The Power Delivery board uses the default settings with address 0x28 using Wire.

     Opionally, if the address jumpers are modified, or using a different I2C bus,
     these parameters can be changed here. E.g. usb.begin(0x29,Wire1)

     It will return true on success or false on failure to communicate. */
  if(!usb.begin())
  {
    Serial.println("Cannot connect to STUSB4500.");
    Serial.println("Is the board connected? Is the device ID correct?");
    while(1);
  }

  Serial.println("Connected to STUSB4500!");
  delay(100);

  float voltage, current;
  byte lowerTolerance, upperTolerance, pdoNumber;

  pdoNumber = usb.getPdoNumber();
  voltage = usb.getVoltage(3);
  current = usb.getCurrent(3);
  lowerTolerance = usb.getLowerVoltageLimit(3);
  upperTolerance = usb.getUpperVoltageLimit(3);

  /* Since we're going to change PDO3, we'll make sure that the
     STUSB4500 tries PDO3 by setting PDO3 to the highest priority. */
  usb.setPdoNumber(3);

  /* PDO3
   - Voltage 5-20V
   - Current value for PDO3 0-5A, if 0 used, FLEX_I value is used
   - Under Voltage Lock Out (setUnderVoltageLimit) 5-20%
   - Over Voltage Lock Out (setUpperVoltageLimit) 5-20%
  */
  usb.setVoltage(3,15.0);
  usb.setCurrent(3,0.5);
  usb.setLowerVoltageLimit(3,20);
  usb.setUpperVoltageLimit(3,20);

  /*Write and save settings to STUSB4500*/
  usb.write();

  /*Read settings saved to STUSB4500*/
  usb.read();

  Serial.println();

  /*Print old setting*/
  Serial.println("Original Values:");
  Serial.print("PDO Number: ");
  Serial.println(pdoNumber);
  Serial.print("Voltage3 (V): ");
  Serial.println(voltage);
  Serial.print("Current3 (A): ");
  Serial.println(current);
  Serial.print("Lower Voltage Tolerance3 (%): ");
  Serial.println(lowerTolerance);
  Serial.print("Upper Voltage Tolerance3 (%): ");
  Serial.println(upperTolerance);

  Serial.println();

  /*Print new settings*/
  Serial.println("New Values:");
  Serial.print("PDO Number: ");
  Serial.println(usb.getPdoNumber());
  Serial.print("Voltage3 (V): ");
  Serial.println(usb.getVoltage(3));
  Serial.print("Current3 (A): ");
  Serial.println(usb.getCurrent(3));
  Serial.print("Lower Voltage Tolerance3 (%): ");
  Serial.println(usb.getLowerVoltageLimit(3));
  Serial.print("Upper Voltage Tolerance3 (%): ");
  Serial.println(usb.getUpperVoltageLimit(3));
}

void loop()
{
}
